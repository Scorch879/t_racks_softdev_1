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
import 'package:t_racks_softdev_1/services/face_service.dart';
import 'package:t_racks_softdev_1/services/database_service.dart';

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
  final tflite.ModelManager _tfliteManager = tflite.ModelManager();
  final AttendanceService _attendanceService = AttendanceService();

  // Liveness Variables
  List<ChallengeType> _challenges = [];
  int _currentChallengeIndex = 0;
  bool _isSessionActive = false;
  String _statusMessage = "Initializing...";
  Color _statusColor = Colors.white;
  bool _isVerified = false;
  bool _hasFailed = false; // New flag for failure state

  // TFLite Variables
  bool _isTfliteLoaded = false;
  int _consecutiveFakeFrames = 0; // Buffer to prevent instant fail

  @override
  void initState() {
    super.initState();
    final options = FaceDetectorOptions(
      enableClassification: true,
      enableLandmarks: true,
      performanceMode: FaceDetectorMode.fast,
    );
    _faceDetector = FaceDetector(options: options);

    // FIX 1: Updated method name from loadModel to loadModels
    _tfliteManager.loadModels().then((_) {
      if (mounted) {
        setState(() => _isTfliteLoaded = true);
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
      _updateStatusMessage();
    });
  }

  void _updateStatusMessage() {
    if (_isVerified || _hasFailed) return;

    if (_currentChallengeIndex >= _challenges.length) {
      _statusMessage = "Verifying Texture...";
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
      if (_isProcessing || !_isSessionActive || _isVerified || _hasFailed)
        return;
      _isProcessing = true;

      try {
        await _processMLKit(image);

        // Run TFLite less frequently (every 10th frame)
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

  Future<void> _processMLKit(CameraImage image) async {
    final inputImage = _inputImageFromCameraImage(image);
    if (inputImage == null) return;

    final List<Face> faces = await _faceDetector.processImage(inputImage);
    if (faces.isNotEmpty) {
      final Face face = faces.first;
      _checkChallenge(face, image);
    }
  }

  void _checkChallenge(Face face, CameraImage image) {
    if (_currentChallengeIndex >= _challenges.length && !_isVerified) {
      _finalizeVerification(image);
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

  Future<void> _processTFLite(CameraImage image) async {
    try {
      // FIX 2: Use checkLiveness instead of runInferenceOnCameraImage
      // This returns TRUE if it's a real face, FALSE if it's a spoof.
      bool isReal = await _tfliteManager.checkLiveness(image);

      if (!isReal) {
        // If it's NOT real (i.e., a spoof), increment the counter
        _consecutiveFakeFrames++;
      } else {
        _consecutiveFakeFrames = 0; // Reset if we see a good frame
      }

      if (_consecutiveFakeFrames >= 3) {
        if (mounted) {
          setState(() {
            _hasFailed = true;
            _statusMessage = "⚠️ SPOOF DETECTED";
            _statusColor = Colors.red;
          });
        }
      }
    } catch (e) {
      print("TFLite Error: $e");
    }
  }

  Future<void> _finalizeVerification(CameraImage image) async {
    // If we made it here without TFLite flagging us, we are good.
    if (_hasFailed == false) {
      // 1. Generate the face embedding from the final verified image.
      final faceEmbedding = await _tfliteManager.generateFaceEmbedding(image);

      if (faceEmbedding.isEmpty) {
        // Handle case where embedding failed
        setState(() {
          _hasFailed = true;
          _statusMessage = "⚠️ Could not read face. Try again.";
          _statusColor = Colors.red;
        });
        return;
      }

      // 2. Call the service to find a match in the database.
      final matchingService = FaceRecognitionService();
      final matchResult = await matchingService.findMatchingStudent(
        faceEmbedding,
      );

      // 3. Update UI based on the result.
      setState(() {
        _isVerified = true; // Stop processing
        if (matchResult != null) {
          _statusMessage = "Verifying class & marking attendance...";
          _statusColor = Colors.blueAccent;

          // Mark Attendance Here for matchResult.studentId
          _attendanceService
              .markAttendance(matchResult.studentId)
              .then((className) {
                if (mounted) {
                  setState(() {
                    _statusMessage = className != null
                        ? "✅ Welcome, ${matchResult.fullName}!\nAttendance marked for $className."
                        : "❌ Welcome, ${matchResult.fullName}!\nCould not find an ongoing class.";
                    _statusColor = className != null
                        ? Colors.green
                        : Colors.orange;
                  });
                }
              })
              .catchError((e) {
                // ADD THIS CATCH BLOCK
                if (mounted) {
                  setState(() {
                    _statusMessage =
                        "❌ Error: ${e.toString().replaceAll('Exception:', '').trim()}";
                    _statusColor = Colors.red;
                    _hasFailed = true; // Optionally allow them to retry
                  });
                }
              });
        } else {
          _statusMessage = "❌ Student Not Recognized";
          _statusColor = Colors.orange;
        }
      });
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

                // Dim the screen if failed or verified
                if (_hasFailed || _isVerified) Container(color: Colors.black54),

                // Main UI Overlay
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

                        // TRY AGAIN BUTTON (Only shows on failure)
                        if (_hasFailed) ...[
                          const SizedBox(height: 20),
                          const Text(
                            "Security Check Failed.\nMake sure you are in good lighting.",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: _startLivenessSession, // Restart Logic
                            icon: const Icon(Icons.refresh),
                            label: const Text("TRY AGAIN"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 30,
                                vertical: 15,
                              ),
                            ),
                          ),
                        ],
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
