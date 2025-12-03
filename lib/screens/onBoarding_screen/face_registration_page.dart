import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
// FIX: Added 'as tflite' to resolve the name conflict
import 'package:t_racks_softdev_1/services/tflite_service.dart' as tflite;

class FaceRegistrationPage extends StatefulWidget {
  final Function(File image, List<double> vector) onFaceCaptured;

  const FaceRegistrationPage({super.key, required this.onFaceCaptured});

  @override
  State<FaceRegistrationPage> createState() => _FaceRegistrationPageState();
}

class _FaceRegistrationPageState extends State<FaceRegistrationPage> {
  CameraController? _controller;

  // FIX: Explicitly use the prefixed class name
  final tflite.ModelManager _modelManager = tflite.ModelManager();

  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: false,
      enableClassification: false,
      performanceMode: FaceDetectorMode.fast,
    ),
  );

  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  String _statusMessage = "Initializing...";
  Color _statusColor = Colors.orange;

  // Verification flags
  bool _isFaceDetected = false;
  bool _isLightingGood = false;
  bool _isCaptured = false;

  List<double> _lastVector = [];

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _modelManager.loadModel();
  }

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
    _controller!.startImageStream((CameraImage image) async {
      if (_isProcessing || _isCaptured) return;
      _isProcessing = true;

      try {
        // 1. Check Lighting
        final isLightingGood = _checkLighting(image);

        // 2. Detect Face (ML Kit)
        final inputImage = _inputImageFromCameraImage(image);
        bool isFaceDetected = false;
        if (inputImage != null) {
          final faces = await _faceDetector.processImage(inputImage);
          isFaceDetected = faces.isNotEmpty;
        }

        // 3. TFLite Inference (Get Vector)
        List<double> vector = [];
        if (isFaceDetected && _modelManager.isModelLoaded) {
          vector = await _modelManager.runInferenceOnCameraImage(image);
        }

        if (mounted) {
          setState(() {
            _isLightingGood = isLightingGood;
            _isFaceDetected = isFaceDetected;
            _lastVector = vector;
            _updateStatus();
          });
        }
      } catch (e) {
        print("Error processing frame: $e");
      } finally {
        _isProcessing = false;
      }
    });
  }

  bool _checkLighting(CameraImage image) {
    // Simple brightness check using the Y plane (luminance)
    if (image.planes.isEmpty) return false;
    final bytes = image.planes[0].bytes;
    int totalBrightness = 0;
    // Sample every 100th pixel for performance
    for (int i = 0; i < bytes.length; i += 100) {
      totalBrightness += bytes[i];
    }
    final averageBrightness = totalBrightness / (bytes.length / 100);
    return averageBrightness > 80; // Threshold (0-255), adjust as needed
  }

  void _updateStatus() {
    if (!_isLightingGood) {
      _statusMessage = "Too Dark! Move to better light.";
      _statusColor = Colors.red;
    } else if (!_isFaceDetected) {
      _statusMessage = "No Face Detected.";
      _statusColor = Colors.orange;
    } else {
      _statusMessage = "Ready to Capture";
      _statusColor = Colors.green;
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    final camera = _controller!.description;
    final sensorOrientation = camera.sensorOrientation;
    final rotation = InputImageRotationValue.fromRawValue(
      Platform.isAndroid ? (sensorOrientation + 0) % 360 : sensorOrientation,
    );
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;

    final plane = image.planes.first;
    return InputImage.fromBytes(
      bytes: Uint8List.fromList(
        image.planes.fold(
          <int>[],
          (previous, element) => previous..addAll(element.bytes),
        ),
      ),
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  Future<void> captureFace() async {
    if (!_isFaceDetected || !_isLightingGood || _controller == null) return;

    try {
      await _controller!.stopImageStream(); // Stop stream to take picture
      final XFile file = await _controller!.takePicture();
      final File imageFile = File(file.path);

      setState(() {
        _isCaptured = true;
        _statusMessage = "Face Captured Successfully!";
      });

      // Pass data back to parent
      widget.onFaceCaptured(imageFile, _lastVector);
    } catch (e) {
      print("Error capturing face: $e");
      _startImageStream(); // Restart stream if failed
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized || _controller == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            "Register Face ID",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF194B61),
            ),
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _statusColor, width: 4),
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CameraPreview(_controller!),
                  if (_isCaptured)
                    Container(
                      color: Colors.black54,
                      child: const Center(
                        child: Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 80,
                        ),
                      ),
                    ),
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
        if (!_isCaptured)
          ElevatedButton.icon(
            onPressed: (_isFaceDetected && _isLightingGood)
                ? captureFace
                : null,
            icon: const Icon(Icons.camera_alt),
            label: const Text("Capture Face"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF26A69A),
              foregroundColor: Colors.white,
            ),
          ),
        const SizedBox(height: 20),
      ],
    );
  }
}
