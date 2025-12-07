import 'dart:async';
import 'dart:math';
import 'dart:io';
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
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  bool _isProcessing = false;
  late FaceDetector _faceDetector;
  final tflite.ModelManager _tfliteManager = tflite.ModelManager();

  List<ChallengeType> _challenges = [];
  int _currentChallengeIndex = 0;
  bool _isSessionActive = false;
  String _statusMessage = "Initializing...";
  Color _statusColor = Colors.white;

  bool _isVerified = false;
  bool _hasFailed = false;
  int _consecutiveFakeFrames = 0;

  // Storage for multi-frame averaging
  final List<List<double>> _recognitionSamples = [];

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
    // Pick 2 random challenges
    for (int i = 0; i < 2; i++) {
      _challenges.add(allTypes[random.nextInt(allTypes.length)]);
    }

    setState(() {
      _isSessionActive = true;
      _currentChallengeIndex = 0;
      _isVerified = false;
      _hasFailed = false;
      _consecutiveFakeFrames = 0;
      _recognitionSamples.clear();
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
        // 1. Convert Image for ML Kit
        final inputImage = _inputImageFromCameraImage(image);
        if (inputImage != null) {
          // 2. Detect Faces
          final List<Face> faces = await _faceDetector.processImage(inputImage);

          if (faces.isNotEmpty) {
            final Face face = faces.first;

            // 3. Check Challenges (Smile/Blink/Turn)
            _checkChallenge(face);

            // 4. Run Identity/Liveness Check (Throttled)
            if (frameCount % 5 == 0 && _tfliteManager.areModelsLoaded) {
              await _processTFLite(image, face);
            }
          }
        }
        frameCount++;
      } catch (e) {
        print("Error processing: $e");
      } finally {
        _isProcessing = false;
      }
    });
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

  Future<void> _processTFLite(CameraImage image, Face face) async {
    try {
      // 1. Check Liveness (Spoof Detection)
      bool isReal = await _tfliteManager.checkLiveness(image);
      if (!isReal) {
        _recognitionSamples.clear(); // Reset progress if spoof detected
        _consecutiveFakeFrames++;
        if (_consecutiveFakeFrames >= 3) {
          _triggerFailure("⚠️ SPOOF DETECTED");
        }
        return;
      }
      _consecutiveFakeFrames = 0;

      // 2. Check Identity (Only if challenges are done)
      if (_currentChallengeIndex >= _challenges.length) {
        // FIX: Pass 'faceBox' for accurate cropping
        List<double> liveVector = await _tfliteManager.generateFaceEmbedding(
          image,
          faceBox: face.boundingBox,
        );

        // FIX: Ensure vector isn't empty before using
        if (liveVector.isNotEmpty) {
          _recognitionSamples.add(liveVector);

          // Wait for 3 consistent frames to average (Speed vs Accuracy balance)
          if (_recognitionSamples.length >= 3) {
            // A. Calculate Average
            List<double> averageVector = List.filled(
              512,
              0.0,
            ); // 512 for FaceNet
            // Safety check for vector length
            if (averageVector.length == liveVector.length) {
              for (var vec in _recognitionSamples) {
                for (int i = 0; i < vec.length; i++) {
                  averageVector[i] += vec[i];
                }
              }
              averageVector = averageVector
                  .map((e) => e / _recognitionSamples.length)
                  .toList();

              // B. Compare with Stored Vector
              // FIX: Use the 'compareVectors' method you just added
              double distance = _tfliteManager.compareVectors(
                widget.studentSavedVector,
                averageVector,
              );

              print("Avg Distance: $distance");

              // Threshold (0.25 is strict, 0.40 is looser)
              if (distance < 0.25) {
                _finalizeVerification();
              } else {
                // If match failed, clear samples and try again
                _recognitionSamples.clear();
              }
            } else {
              // Vector size mismatch (Old profile vs New Model)
              _triggerFailure("Profile Outdated.\nPlease Re-register Face.");
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

  void _finalizeVerification() {
    if (!_hasFailed && !_isVerified) {
      if (mounted) {
        setState(() {
          _isVerified = true;
          _statusMessage = "✅ IDENTITY VERIFIED";
          _statusColor = const Color(0xFF4DBD88);
        });

        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.of(context).pop(); // Return success
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
    _tfliteManager.close();
    _controller?.stopImageStream();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Basic Layout same as before
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_controller != null && _controller!.value.isInitialized)
            LayoutBuilder(
              builder: (context, constraints) {
                final size = constraints.biggest;
                var scale = 1.0;
                if (_controller!.value.aspectRatio < size.aspectRatio) {
                  scale = 1 / _controller!.value.aspectRatio * size.aspectRatio;
                } else {
                  scale = _controller!.value.aspectRatio / size.aspectRatio;
                }
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

          // Top Bar
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

          // Center Status Box
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!_hasFailed && !_isVerified)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
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
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                if (_hasFailed)
                  Column(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xFFDA6A6A),
                        size: 60,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _statusMessage,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _startLivenessSession,
                        child: const Text("TRY AGAIN"),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
