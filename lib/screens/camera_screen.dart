import 'dart:async';
import 'dart:io';
import 'dart:math' as math; // FIX: Alias math to avoid conflicts
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:t_racks_softdev_1/services/tflite_service.dart' as tflite;
import 'package:t_racks_softdev_1/services/face_service.dart';

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
  int _recognitionFailCounter = 0;

  // Liveness Variables
  List<ChallengeType> _challenges = [];
  int _currentChallengeIndex = 0;
  bool _isSessionActive = false;
  String _statusMessage = "Initializing...";
  Color _statusColor = Colors.white;
  bool _isVerified = false;
  bool _hasFailed = false;

  // TFLite Variables
  bool _isTfliteLoaded = false;
  int _consecutiveFakeFrames = 0;

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
    final random = math.Random(); // FIX: Explicitly use math.Random
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
      _recognitionFailCounter = 0;
    });
  }

  void _updateStatusMessage() {
    if (_isVerified || _hasFailed) return;

    if (_currentChallengeIndex >= _challenges.length) {
      _statusMessage = "Verifying Identity...";
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
      bool isReal = await _tfliteManager.checkLiveness(image);

      if (!isReal) {
        _consecutiveFakeFrames++;
      } else {
        _consecutiveFakeFrames = 0;
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
    if (_hasFailed == false) {
      final faceEmbedding = await _tfliteManager.generateFaceEmbedding(image);

      if (faceEmbedding.isEmpty) return; // Skip bad frames silently

      final matchingService = FaceRecognitionService();
      final matchResult = await matchingService.findMatchingStudent(
        faceEmbedding,
      );

      if (mounted) {
        if (matchResult != null) {
          // SUCCESS!
          setState(() {
            _isVerified = true;
            _statusMessage = "✅ Welcome, ${matchResult.fullName}!";
            _statusColor = Colors.green;
            _recognitionFailCounter = 0; // Reset
          });
        } else {
          // FAILURE - BUT WAIT!
          // Don't fail immediately. Give it 5 chances (approx 2 seconds)
          _recognitionFailCounter++;

          if (_recognitionFailCounter > 5) {
            setState(() {
              _hasFailed = true;
              _statusMessage = "❌ Student Not Recognized";
              _statusColor = Colors.redAccent;
            });
          } else {
            // Just print to console, don't scare the user yet
            print(
              "Attempt $_recognitionFailCounter: No match found. Retrying...",
            );
          }
        }
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
      appBar: AppBar(title: const Text('Secure Attendance')),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              _controller != null &&
              _controller!.value.isInitialized) {
            // FIX: Robust aspect ratio scaling to prevent squishing
            final size = MediaQuery.of(context).size;
            final scale =
                1 / (_controller!.value.aspectRatio * size.aspectRatio);

            return Stack(
              children: [
                Center(
                  child: Transform.scale(
                    scale: scale,
                    alignment: Alignment.topCenter,
                    child: CameraPreview(_controller!),
                  ),
                ),

                if (_hasFailed || _isVerified) Container(color: Colors.black54),

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

                        if (_hasFailed) ...[
                          const SizedBox(height: 20),
                          const Text(
                            "Security Check Failed.",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: _startLivenessSession,
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
