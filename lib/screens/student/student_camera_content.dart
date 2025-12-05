import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:t_racks_softdev_1/services/tflite_service.dart' as tflite;

enum ChallengeType { smile, blink, turnLeft, turnRight }

class StudentCameraContent extends StatefulWidget {
  final List<CameraDescription> cameras;
  final List<double> studentSavedVector; // <--- NEW: Accepts the saved face ID

  const StudentCameraContent({
    super.key,
    required this.cameras,
    required this.studentSavedVector, // <--- Required
  });

  @override
  State<StudentCameraContent> createState() => _StudentCameraContentState();
}

class _StudentCameraContentState extends State<StudentCameraContent> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  bool _isProcessing = false;
  late FaceDetector _faceDetector;
  final tflite.ModelManager _tfliteManager = tflite.ModelManager();

  // Liveness Variables
  List<ChallengeType> _challenges = [];
  int _currentChallengeIndex = 0;
  bool _isSessionActive = false;
  String _statusMessage = "Initializing...";
  Color _statusColor = Colors.white;

  // Verification State
  bool _isVerified = false;
  bool _hasFailed = false;
  int _consecutiveFakeFrames = 0;
  int _consecutiveMatchFrames = 0; // <--- NEW: To confirm identity match

  @override
  void initState() {
    super.initState();
    final options = FaceDetectorOptions(
      enableClassification: true,
      enableLandmarks: true,
      performanceMode: FaceDetectorMode.fast,
    );
    _faceDetector = FaceDetector(options: options);

    _tfliteManager.loadModels().then((_) {
      if (mounted) setState(() {});
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
          ? ImageFormatGroup.nv21
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
    for (int i = 0; i < 2; i++) {
      _challenges.add(allTypes[random.nextInt(allTypes.length)]);
    }

    setState(() {
      _isSessionActive = true;
      _currentChallengeIndex = 0;
      _isVerified = false;
      _hasFailed = false;
      _consecutiveFakeFrames = 0;
      _consecutiveMatchFrames = 0;
      _updateStatusMessage();
    });
  }

  void _updateStatusMessage() {
    if (_isVerified || _hasFailed) return;

    if (_currentChallengeIndex >= _challenges.length) {
      _statusMessage = "Verifying Identity...";
      _statusColor = const Color(0xFF93C0D3);
      return;
    }

    ChallengeType current = _challenges[_currentChallengeIndex];
    switch (current) {
      case ChallengeType.smile:
        _statusMessage = "Please SMILE 😀";
        break;
      case ChallengeType.blink:
        _statusMessage = "Please BLINK 😉";
        break;
      case ChallengeType.turnLeft:
        _statusMessage = "Turn Head LEFT ⬅️";
        break;
      case ChallengeType.turnRight:
        _statusMessage = "Turn Head RIGHT ➡️";
        break;
    }
    _statusColor = Colors.white;
  }

  void _startImageStream() {
    if (_controller == null) return;
    int frameCount = 0;

    _controller!.startImageStream((CameraImage image) async {
      if (_isProcessing || !_isSessionActive || _isVerified || _hasFailed)
        return;
      _isProcessing = true;

      try {
        await _processMLKit(image);

        // Run heavy AI checks every 5th frame
        if (frameCount % 5 == 0 && _tfliteManager.areModelsLoaded) {
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
      // Challenges done, waiting for Identity Verification in _processTFLite
      return;
    }

    ChallengeType current = _challenges[_currentChallengeIndex];
    bool passed = false;
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

  Future<void> _processTFLite(CameraImage image) async {
    try {
      // 1. Check Liveness (Real vs Spoof)
      bool isReal = await _tfliteManager.checkLiveness(image);

      if (!isReal) {
        _consecutiveFakeFrames++;
        if (_consecutiveFakeFrames >= 3) {
          _triggerFailure("⚠️ SPOOF DETECTED");
        }
        return; // Don't check identity if it's fake
      } else {
        _consecutiveFakeFrames = 0;
      }

      // 2. Check Identity (Only if challenges are done)
      if (_currentChallengeIndex >= _challenges.length) {
        // Generate live vector
        List<double> liveVector = await _tfliteManager.generateFaceEmbedding(
          image,
        );

        if (liveVector.isNotEmpty && widget.studentSavedVector.isNotEmpty) {
          // Compare!
          double distance = _tfliteManager.compareVectors(
            widget.studentSavedVector,
            liveVector,
          );

          // MobileFaceNet Threshold: < 0.80 or 0.85 is a match
          if (distance < 0.85) {
            _consecutiveMatchFrames++;
          } else {
            _consecutiveMatchFrames = 0;
          }

          if (_consecutiveMatchFrames >= 2) {
            _finalizeVerification();
          }
        }
      }
    } catch (e) {
      print("TFLite Error: $e");
    }
  }

  void _triggerFailure(String message) {
    if (mounted) {
      setState(() {
        _hasFailed = true;
        _statusMessage = message;
        _statusColor = const Color(0xFFDA6A6A);
      });
    }
  }

  void _finalizeVerification() {
    if (!_hasFailed && !_isVerified) {
      if (mounted) {
        setState(() {
          _isVerified = true;
          _statusMessage = "✅ IDENTITY VERIFIED";
          _statusColor = const Color(0xFF4DBD88);
        });

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.of(context).pop(); // Or navigate to success screen
          }
        });
      }
    }
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
    _tfliteManager
        .close(); // Careful if you share this instance, might verify where it's created
    _controller?.stopImageStream();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_controller != null && _controller!.value.isInitialized)
            LayoutBuilder(
              builder: (context, constraints) {
                final size = constraints.biggest;

                // --- FIX: CALCULATE SCALE TO PREVENT SQUISHING ---
                // Camera aspect ratio is usually landscape (e.g. 4:3)
                // Screen aspect ratio is portrait (e.g. 9:16)
                // We calculate how much to scale the width to cover the height.
                var scale = 1.0;
                if (_controller!.value.aspectRatio < size.aspectRatio) {
                  // If camera is "wider" than screen (relative to portrait), scale height
                  scale = 1 / _controller!.value.aspectRatio * size.aspectRatio;
                } else {
                  // If camera is "taller", scale width
                  scale = _controller!.value.aspectRatio / size.aspectRatio;
                }

                // Just use the simple logic from the registration page if this feels off
                // The most reliable "Cover" mode for portrait front cam:
                final double finalScale =
                    1 / (_controller!.value.aspectRatio * size.aspectRatio);

                return Transform.scale(
                  scale: finalScale,
                  alignment: Alignment.topCenter,
                  child: Center(child: CameraPreview(_controller!)),
                );
              },
            )
          else
            const Center(child: CircularProgressIndicator()),

          if (_hasFailed || _isVerified)
            Container(color: Colors.black.withOpacity(0.7)),

          // Overlay Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withOpacity(0.5),
                ],
                stops: const [0.0, 0.2, 0.8, 1.0],
              ),
            ),
          ),

          // Header
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: Color(0xFF93C0D3),
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Text(
                            'Attendance Verification',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main HUD
          Center(
            child: SizedBox(
              width: 300,
              height: 450,
              child: Stack(
                children: [
                  // Corner Brackets
                  Positioned(
                    top: 0,
                    left: 0,
                    child: _CornerBracket(isTop: true, isLeft: true),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: _CornerBracket(isTop: true, isLeft: false),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: _CornerBracket(isTop: false, isLeft: true),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: _CornerBracket(isTop: false, isLeft: false),
                  ),

                  // Status Text
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!_hasFailed && !_isVerified)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _statusMessage,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _statusColor,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Failure State
                  if (_hasFailed)
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: Color(0xFFDA6A6A),
                            size: 60,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Verification Failed",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Face does not match profile\nor spoof detected.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _startLivenessSession,
                            icon: const Icon(Icons.refresh),
                            label: const Text("TRY AGAIN"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Success State
                  if (_isVerified)
                    const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF4DBD88),
                            size: 80,
                          ),
                          SizedBox(height: 16),
                          Text(
                            "Verified!",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CornerBracket extends StatelessWidget {
  final bool isTop;
  final bool isLeft;

  const _CornerBracket({required this.isTop, required this.isLeft});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        border: Border(
          top: isTop
              ? const BorderSide(color: Colors.white, width: 2)
              : BorderSide.none,
          bottom: !isTop
              ? const BorderSide(color: Colors.white, width: 2)
              : BorderSide.none,
          left: isLeft
              ? const BorderSide(color: Colors.white, width: 2)
              : BorderSide.none,
          right: !isLeft
              ? const BorderSide(color: Colors.white, width: 2)
              : BorderSide.none,
        ),
      ),
    );
  }
}
