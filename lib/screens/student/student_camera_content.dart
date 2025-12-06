import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Needed for auth
import 'package:t_racks_softdev_1/services/tflite_service.dart' as tflite;
import 'package:t_racks_softdev_1/services/database_service.dart'; // Needed for attendance

enum ChallengeType { smile, blink, turnLeft, turnRight }

class StudentCameraContent extends StatefulWidget {
  final List<CameraDescription> cameras;
  final List<double> studentSavedVector;

  const StudentCameraContent({
    super.key,
    required this.cameras,
    required this.studentSavedVector,
  });

  @override
  State<StudentCameraContent> createState() => _StudentCameraContentState();
}

class _StudentCameraContentState extends State<StudentCameraContent> {
  // Services
  final tflite.ModelManager _tfliteManager = tflite.ModelManager();
  final DatabaseService _databaseService =
      DatabaseService(); // FIX: Define this

  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  bool _isProcessing = false;
  late FaceDetector _faceDetector;

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

  // Averaging logic for Recognition
  List<List<double>> _recognitionSamples = [];

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
      _recognitionSamples.clear(); // Clear old samples
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

        // Run AI checks every 5th frame
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
      // 1. Check Liveness
      bool isReal = await _tfliteManager.checkLiveness(image);

      if (!isReal) {
        _recognitionSamples.clear(); // Reset on spoof
        _consecutiveFakeFrames++;
        if (_consecutiveFakeFrames >= 3) {
          _triggerFailure("⚠️ SPOOF DETECTED");
        }
        return;
      } else {
        _consecutiveFakeFrames = 0;
      }

      // 2. Check Identity
      if (_currentChallengeIndex >= _challenges.length) {
        List<double> liveVector = await _tfliteManager.generateFaceEmbedding(
          image,
        );

        if (liveVector.isNotEmpty && widget.studentSavedVector.isNotEmpty) {
          _recognitionSamples.add(liveVector);

          // Wait for 5 samples to average
          if (_recognitionSamples.length >= 5) {
            // Calculate Average
            List<double> averageVector = List.filled(192, 0.0);
            for (var vec in _recognitionSamples) {
              for (int i = 0; i < vec.length; i++) {
                averageVector[i] += vec[i];
              }
            }
            averageVector = averageVector
                .map((e) => e / _recognitionSamples.length)
                .toList();

            double distance = _tfliteManager.compareVectors(
              widget.studentSavedVector,
              averageVector,
            );

            // 0.25 Threshold
            if (distance < 0.25) {
              _finalizeVerification();
            } else {
              _recognitionSamples.clear(); // Retry
              // Optionally warn user
            }
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

  void _finalizeVerification() async {
    if (_hasFailed || _isVerified) return;

    if (mounted) {
      setState(() {
        _isVerified = true;
        _statusMessage = "Verifying Class...";
        _statusColor = const Color(0xFF93C0D3);
      });
    }

    try {
      // FIX: Use Current User ID
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw "User not logged in";

      // FIX: Call DatabaseService directly
      final className = await _databaseService.markAttendance(userId);

      if (mounted) {
        setState(() {
          _statusMessage = className != null
              ? "✅ Marked Present: $className"
              : "⚠️ Identity Verified, but no ongoing class found.";
          _statusColor = className != null
              ? const Color(0xFF4DBD88)
              : Colors.orange;
        });

        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage =
              "Error: ${e.toString().replaceAll('Exception:', '')}";
          _statusColor = Colors.red;
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
    _tfliteManager.close();
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

                // Robust Fit logic
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

          // Overlay
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

          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Row(
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
                      const Text(
                        'Attendance Verification',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Center(
            child: SizedBox(
              width: 300,
              height: 450,
              child: Stack(
                children: [
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

                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
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
                          const Text(
                            "Failed",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _startLivenessSession,
                            icon: const Icon(Icons.refresh),
                            label: const Text("TRY AGAIN"),
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
