import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

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

  // Liveness Logic Variables
  List<ChallengeType> _challenges = [];
  int _currentChallengeIndex = 0;
  bool _isSessionActive = false;
  String _statusMessage = "Initializing...";
  Color _statusColor = Colors.white;
  bool _isVerified = false;

  @override
  void initState() {
    super.initState();
    final options = FaceDetectorOptions(
      enableClassification: true, // Needed for Smile/Eyes
      enableLandmarks: true, // Needed for Head Rotation
      performanceMode: FaceDetectorMode.fast,
    );
    _faceDetector = FaceDetector(options: options);
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
        _startLivenessSession(); // Start the challenge immediately
        _startImageStream();
      }
    });
  }

  // Generate a random list of 2 challenges
  void _startLivenessSession() {
    final random = Random();
    // Possible challenges
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
      _updateStatusMessage();
    });
  }

  void _updateStatusMessage() {
    if (_isVerified) {
      _statusMessage = "✅ VERIFIED: REAL HUMAN";
      _statusColor = Colors.greenAccent;
      return;
    }

    if (_currentChallengeIndex >= _challenges.length) {
      // All done!
      _isVerified = true;
      _statusMessage = "✅ VERIFIED!";
      // TODO: Save Attendance Here
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
    _controller!.startImageStream((CameraImage image) async {
      if (_isProcessing || !_isSessionActive || _isVerified) return;
      _isProcessing = true;
      try {
        await _processCameraImage(image);
      } catch (e) {
        print("Error processing image: $e");
      } finally {
        _isProcessing = false;
      }
    });
  }

  Future<void> _processCameraImage(CameraImage image) async {
    final inputImage = _inputImageFromCameraImage(image);
    if (inputImage == null) return;

    final List<Face> faces = await _faceDetector.processImage(inputImage);
    if (faces.isEmpty) return;

    final Face face = faces.first;
    _checkChallenge(face);
  }

  void _checkChallenge(Face face) {
    if (_isVerified) return;

    ChallengeType current = _challenges[_currentChallengeIndex];
    bool passed = false;

    // Thresholds
    double smileThreshold = 0.8;
    double blinkThreshold =
        0.1; // Probability of eyes being OPEN (low = closed)
    double headRotationThreshold = 15.0; // Degrees

    switch (current) {
      case ChallengeType.smile:
        if ((face.smilingProbability ?? 0) > smileThreshold) passed = true;
        break;
      case ChallengeType.blink:
        // Check if either eye is closed
        if ((face.leftEyeOpenProbability ?? 1) < blinkThreshold ||
            (face.rightEyeOpenProbability ?? 1) < blinkThreshold) {
          passed = true;
        }
        break;
      case ChallengeType.turnLeft:
        // HeadEulerAngleY: Negative is right, Positive is left (depending on camera mirror)
        // Adjust logic based on your specific camera (front cameras are often mirrored)
        if ((face.headEulerAngleY ?? 0) > headRotationThreshold) passed = true;
        break;
      case ChallengeType.turnRight:
        if ((face.headEulerAngleY ?? 0) < -headRotationThreshold) passed = true;
        break;
    }

    if (passed) {
      // Delay slightly so the user sees the success
      if (mounted) {
        setState(() {
          _currentChallengeIndex++;
          _updateStatusMessage();
        });

        // If finished
        if (_currentChallengeIndex >= _challenges.length) {
          setState(() {
            _isVerified = true;
            _statusMessage = "✅ IDENTITY CONFIRMED";
            _statusColor = Colors.green;
          });
          // TODO: Navigate away or save data
        }
      }
    }
  }

  // ... (Keep the exact same _inputImageFromCameraImage helper method from previous response)
  InputImage? _inputImageFromCameraImage(CameraImage image) {
    // Paste the helper function from my previous reply here
    // (Omitted for brevity, but it is required!)
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

    final planeData = image.planes.map((Plane plane) {
      return InputImagePlaneMetadata(
        bytesPerRow: plane.bytesPerRow,
        height: plane.height,
        width: plane.width,
      );
    }).toList();

    final inputImageData = InputImageData(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      imageRotation: rotation,
      inputImageFormat: format ?? InputImageFormat.nv21,
      planeData: planeData,
    );

    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    return InputImage.fromBytes(bytes: bytes, inputImageData: inputImageData);
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
    _controller?.stopImageStream();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('Active Liveness Check')),
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
                        Text(
                          "Challenge ${_currentChallengeIndex + 1} of ${_challenges.length}",
                          style: const TextStyle(color: Colors.white54),
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
