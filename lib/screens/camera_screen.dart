import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
// FIX 1: Add 'as tflite' to avoid name conflict with Google's ModelManager
import 'package:t_racks_softdev_1/services/tflite_service.dart' as tflite;

// Enum for different challenges
enum ChallengeType { smile, blink, turnLeft, turnRight }

class AttendanceCameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const AttendanceCameraScreen({super.key, required this.cameras});

  @override
  State<AttendanceCameraScreen> createState() => _AttendanceCameraScreenState();
}

class _AttendanceCameraScreenState extends State<AttendanceCameraScreen> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  bool _isProcessing = false;
  late FaceDetector _faceDetector;

  // FIX 2: Use 'tflite.ModelManager' to specify your custom class
  final tflite.ModelManager _tfliteManager = tflite.ModelManager();

  // Liveness Logic Variables
  List<ChallengeType> _challenges = [];
  int _currentChallengeIndex = 0;
  bool _isSessionActive = false;
  String _statusMessage = "Initializing...";
  Color _statusColor = Colors.white;
  bool _isVerified = false;

  // TFLite Variables
  bool _isTfliteLoaded = false;
  double _fakeProbability = 0.0;

  @override
  void initState() {
    super.initState();
    // 1. Setup ML Kit
    final options = FaceDetectorOptions(
      enableClassification: true,
      enableLandmarks: true,
      performanceMode: FaceDetectorMode.fast,
    );
    _faceDetector = FaceDetector(options: options);

    // 2. Setup TFLite (Your Custom Model)
    _tfliteManager.loadModel().then((_) {
      if (mounted) {
        setState(() {
          _isTfliteLoaded = true;
        });
      }
    });

    _initializeCamera();
  }

  void _initializeCamera() {
    if (widget.cameras.isEmpty) return;

    final frontCamera = widget.cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => widget.cameras[0],
    );

    _controller = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup
                .nv21 // ML Kit prefers NV21
          : ImageFormatGroup.bgra8888,
    );

    _initializeControllerFuture = _controller!.initialize().then((_) {
      if (mounted) {
        setState(() {});
        _startLivenessSession();
        _startImageStream();
      }
    });
  }

  void _startLivenessSession() {
    final random = Random();
    List<ChallengeType> allTypes = ChallengeType.values.toList();
    _challenges = [];

    // Pick 2 random challenges
    for (int i = 0; i < 2; i++) {
      _challenges.add(allTypes[random.nextInt(allTypes.length)]);
    }

    setState(() {
      _isSessionActive = true;
      _currentChallengeIndex = 0;
      _isVerified = false;
      _fakeProbability = 0.0;
      _updateStatusMessage();
    });
  }

  void _updateStatusMessage() {
    if (_isVerified) return;

    if (_currentChallengeIndex >= _challenges.length) {
      // User passed challenges, now waiting for TFLite check...
      _statusMessage = "Analyzing Texture...";
      _statusColor = Colors.blueAccent;
      return;
    }

    ChallengeType current = _challenges[_currentChallengeIndex];
    switch (current) {
      case ChallengeType.smile:
        _statusMessage = "Step ${_currentChallengeIndex + 1}: Please SMILE 😀";
        break;
      case ChallengeType.blink:
        _statusMessage = "Step ${_currentChallengeIndex + 1}: Please BLINK 😉";
        break;
      case ChallengeType.turnLeft:
        _statusMessage =
            "Step ${_currentChallengeIndex + 1}: Turn Head LEFT ⬅️";
        break;
      case ChallengeType.turnRight:
        _statusMessage =
            "Step ${_currentChallengeIndex + 1}: Turn Head RIGHT ➡️";
        break;
    }
    _statusColor = Colors.yellowAccent;
  }

  void _startImageStream() {
    if (_controller == null) return;
    int frameCount = 0;

    _controller!.startImageStream((CameraImage image) async {
      if (_isProcessing || !_isSessionActive || _isVerified) return;
      _isProcessing = true;

      try {
        // Run ML Kit every frame for smoothness
        await _processMLKit(image);

        // Run TFLite only every 10th frame (to save battery/lag)
        // And ONLY if we haven't failed the fake check yet
        if (frameCount % 10 == 0 && _isTfliteLoaded) {
          await _processTFLite(image);
        }
        frameCount++;
      } catch (e) {
        print("Error processing: $e");
      } finally {
        _isProcessing = false;
      }
    });
  }

  // --- STEP 1: ML KIT LIVENESS (Actions) ---
  Future<void> _processMLKit(CameraImage image) async {
    final inputImage = _inputImageFromCameraImage(image);
    if (inputImage == null) return;

    final List<Face> faces = await _faceDetector.processImage(inputImage);
    if (faces.isEmpty) return;

    final Face face = faces.first;
    _checkChallenge(face);
  }

  void _checkChallenge(Face face) {
    if (_currentChallengeIndex >= _challenges.length) {
      _finalizeVerification();
      return;
    }

    ChallengeType current = _challenges[_currentChallengeIndex];
    bool passed = false;

    // Thresholds
    double smileThreshold = 0.8;
    double blinkThreshold = 0.1;
    double headRotationThreshold = 15.0;

    switch (current) {
      case ChallengeType.smile:
        if ((face.smilingProbability ?? 0) > smileThreshold) passed = true;
        break;
      case ChallengeType.blink:
        if ((face.leftEyeOpenProbability ?? 1) < blinkThreshold ||
            (face.rightEyeOpenProbability ?? 1) < blinkThreshold) {
          passed = true;
        }
        break;
      case ChallengeType.turnLeft:
        if ((face.headEulerAngleY ?? 0) > headRotationThreshold) passed = true;
        break;
      case ChallengeType.turnRight:
        if ((face.headEulerAngleY ?? 0) < -headRotationThreshold) passed = true;
        break;
    }

    if (passed) {
      if (mounted) {
        setState(() {
          _currentChallengeIndex++;
          _updateStatusMessage();
        });
      }
    }
  }

  // --- STEP 2: TFLITE TEXTURE CHECK (Deepfake Detection) ---
  Future<void> _processTFLite(CameraImage image) async {
    try {
      final results = await _tfliteManager.runInferenceOnCameraImage(image);
      if (results.isEmpty) return;

      // YOUR LABELS ORDER: [0: Real, 1: No Face, 2: Fake]

      double realScore = results.length > 0 ? results[0] : 0.0;
      double noFaceScore = results.length > 1 ? results[1] : 0.0;
      double fakeScore = results.length > 2 ? results[2] : 0.0;

      _fakeProbability = fakeScore;

      // DEBUG: Print scores to console
      // print("TFLite Scores -> Real: ${(realScore*100).toInt()}% | Fake: ${(fakeScore*100).toInt()}% | NoFace: ${(noFaceScore*100).toInt()}%");

      if (fakeScore > 0.8) {
        if (mounted) {
          setState(() {
            _statusMessage = "⚠️ SPOOF DETECTED";
            _statusColor = Colors.red;
          });
        }
      }
    } catch (e) {
      print("TFLite Error: $e");
    }
  }

  void _finalizeVerification() {
    // Both Steps Must Pass:
    // 1. All challenges passed (ML Kit)
    // 2. Fake Probability low (TFLite)
    if (_fakeProbability < 0.5) {
      if (mounted) {
        setState(() {
          _isVerified = true;
          _statusMessage = "✅ IDENTITY CONFIRMED";
          _statusColor = Colors.green;
          // TODO: Mark Attendance Here
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _statusMessage = "❌ Verification Failed (Fake)";
          _statusColor = Colors.redAccent;
        });
      }
    }
  }

  // --- HELPER METHODS ---
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

    // NEW API METADATA
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

    return InputImage.fromBytes(bytes: bytes, metadata: metadata);
  }

  final _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  @override
  void dispose() {
    _faceDetector.close();
    _tfliteManager.close();
    _controller?.stopImageStream();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('Secure Attendance')),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              _controller != null &&
              _controller!.value.isInitialized) {
            final size = MediaQuery.of(context).size;
            var scale = _controller!.value.aspectRatio * size.aspectRatio;
            if (scale < 1) scale = 1 / scale;

            return Stack(
              children: [
                Center(
                  child: Transform.scale(
                    scale: scale,
                    child: CameraPreview(_controller!),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: double.infinity,
                    color: Colors.black87,
                    padding: const EdgeInsets.all(30),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _statusMessage,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _statusColor,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (_isSessionActive && !_isVerified)
                          Text(
                            "Security Level: ${_fakeProbability > 0.5 ? '⚠️ Risk' : '🛡️ Safe'}",
                            style: TextStyle(
                              color: _fakeProbability > 0.5
                                  ? Colors.red
                                  : Colors.green,
                              fontSize: 16,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
