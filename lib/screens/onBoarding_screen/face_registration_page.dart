import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:t_racks_softdev_1/services/tflite_service.dart' as tflite;

class FaceRegistrationPage extends StatefulWidget {
  final Function(File image, List<double> vector) onFaceCaptured;

  const FaceRegistrationPage({super.key, required this.onFaceCaptured});

  @override
  State<FaceRegistrationPage> createState() => _FaceRegistrationPageState();
}

class _FaceRegistrationPageState extends State<FaceRegistrationPage> {
  CameraController? _controller;
  final tflite.ModelManager _modelManager = tflite.ModelManager();

  // ... (ML Kit FaceDetector setup remains same) ...
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: false,
      enableClassification: false,
      performanceMode: FaceDetectorMode.fast,
    ),
  );

  bool _isCameraInitialized = false;
  bool _isProcessing = false;

  // Status
  String _statusMessage = "Initializing...";
  Color _statusColor = Colors.orange;
  bool _isFaceDetected = false;
  bool _isLightingGood = false;
  bool _isRealFace = false; // New flag for liveness
  bool _isCaptured = false;

  List<double> _currentEmbedding = [];

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _modelManager.loadModels(); // Changed from loadModel to loadModels
  }

  // ... (_initializeCamera remains the same) ...
  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _controller = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );

    await _controller!.initialize();
    if (mounted) {
      setState(() => _isCameraInitialized = true);
      _startImageStream();
    }
  }

  void _startImageStream() {
    int frameCount = 0;
    _controller!.startImageStream((CameraImage image) async {
      if (_isProcessing || _isCaptured) return;
      _isProcessing = true;
      frameCount++;

      try {
        // 1. Basic Checks (Lighting & Detection)
        _isLightingGood = _checkLighting(image);
        final inputImage = _inputImageFromCameraImage(image);

        bool faceFound = false;
        if (inputImage != null) {
          final faces = await _faceDetector.processImage(inputImage);
          faceFound = faces.isNotEmpty;
        }

        bool isReal = false;
        List<double> vector = [];

        // 2. Deep Learning Checks (Only run every 10 frames to save battery/FPS)
        if (faceFound && _modelManager.areModelsLoaded && frameCount % 5 == 0) {
          // A. Check Liveness (Anti-Spoofing)
          isReal = await _modelManager.checkLiveness(image);

          // B. If Real, Generate Identity Vector
          if (isReal) {
            vector = await _modelManager.generateFaceEmbedding(image);
          }
        } else {
          // Keep previous states if we didn't run inference this frame
          isReal = _isRealFace;
          vector = _currentEmbedding;
        }

        if (mounted) {
          setState(() {
            _isFaceDetected = faceFound;
            _isRealFace = isReal;
            if (vector.isNotEmpty) _currentEmbedding = vector;
            _updateStatus();
          });
        }
      } catch (e) {
        print("Error: $e");
      } finally {
        _isProcessing = false;
      }
    });
  }

  // ... (_checkLighting and _inputImageFromCameraImage remain the same) ...
  bool _checkLighting(CameraImage image) {
    if (image.planes.isEmpty) return false;
    final bytes = image.planes[0].bytes;
    int totalBrightness = 0;
    for (int i = 0; i < bytes.length; i += 100) {
      totalBrightness += bytes[i];
    }
    final averageBrightness = totalBrightness / (bytes.length / 100);
    return averageBrightness > 80;
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_controller == null) return null;
    final camera = _controller!.description;
    final sensorOrientation = camera.sensorOrientation;
    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      var rotationCompensation =
          _orientations[_controller!.value.deviceOrientation];
      if (rotationCompensation == null) return null;
      if (camera.lensDirection == CameraLensDirection.front) {
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        rotationCompensation =
            (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (image.planes.isEmpty) return null;

    final metadata = InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: rotation,
      format: format ?? InputImageFormat.nv21,
      bytesPerRow: image.planes[0].bytesPerRow,
    );

    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    if (format == null) return null;
    return InputImage.fromBytes(
      bytes: bytes,
      metadata: metadata,
    );
  }

  void _updateStatus() {
    if (!_isLightingGood) {
      _statusMessage = "Too Dark!";
      _statusColor = Colors.red;
    } else if (!_isFaceDetected) {
      _statusMessage = "Position face in frame";
      _statusColor = Colors.orange;
    } else if (!_isRealFace) {
      _statusMessage =
          "Keep still..."; // Or "Spoof Detected" if you want to be explicit
      _statusColor = Colors.orangeAccent;
    } else {
      _statusMessage = "Ready to Capture";
      _statusColor = Colors.green;
    }
  }

  Future<void> captureFace() async {
    if (!_isFaceDetected || !_isRealFace || _currentEmbedding.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Face not verified or not real. Cannot capture."),
        ),
      );
      return;
    }

    try {
      await _controller!.stopImageStream();
      final XFile file = await _controller!.takePicture();
      final File imageFile = File(file.path);

      setState(() {
        _isCaptured = true;
        _statusMessage = "Face Registered!";
      });

      // Pass the REAL identity vector back
      widget.onFaceCaptured(imageFile, _currentEmbedding);
    } catch (e) {
      print("Error: $e");
      _startImageStream();
    }
  }

  final _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  @override
  void dispose() {
    _controller?.dispose();
    _faceDetector.close();
    _modelManager.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ... UI Code remains mostly the same, just ensure onPressed checks _isRealFace ...
    if (!_isCameraInitialized || _controller == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // ... (Header) ...
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _statusColor, width: 4),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CameraPreview(_controller!),
                  // ... (Status Text) ...
                  Positioned(
                    bottom: 10,
                    left: 0,
                    right: 0,
                    child: Text(
                      _statusMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _statusColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        backgroundColor: Colors.black45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          // Ensure we only allow capture if it is a REAL face
          onPressed: (_isFaceDetected && _isRealFace) ? captureFace : null,
          icon: const Icon(Icons.camera_alt),
          label: const Text("Capture Face"),
          // ...
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
