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

  // UI State
  String _statusMessage = "Align face to scan";
  Color _statusColor = Colors.white;
  bool _isVerified = false;
  bool _canScan = true;

  // --- STABILITY CHECK ---
  int _stableFrames = 0;
  final int _requiredStableFrames = 3; // Face must be stable for ~3 checks

  @override
  void initState() {
    super.initState();
    final options = FaceDetectorOptions(
      enableClassification: false,
      enableLandmarks: true,
      performanceMode: FaceDetectorMode.fast,
    );
    _faceDetector = FaceDetector(options: options);

    _tfliteManager.loadModels();
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
        _startImageStream();
      }
    });
  }

  void _startImageStream() {
    if (_controller == null) return;
    int frameCount = 0;

    _controller!.startImageStream((CameraImage image) async {
      if (_isProcessing || !_canScan || _isVerified) return;

      // Process every 5th frame to save CPU
      frameCount++;
      if (frameCount % 5 != 0) return;

      _isProcessing = true;
      try {
        await _processFrame(image);
      } catch (e) {
        print("Error processing: $e");
      } finally {
        _isProcessing = false;
      }
    });
  }

  Future<void> _processFrame(CameraImage image) async {
    final inputImage = _inputImageFromCameraImage(image);
    if (inputImage == null) return;

    final List<Face> faces = await _faceDetector.processImage(inputImage);

    // If no face found, reset stability
    if (faces.isEmpty) {
      _stableFrames = 0;
      if (mounted && _statusMessage != "Align face to scan") {
        setState(() {
          _statusMessage = "Align face to scan";
          _statusColor = Colors.white;
        });
      }
      return;
    }

    Face mainFace = faces.first;
    double maxArea = 0;
    for (var face in faces) {
      double area = face.boundingBox.width * face.boundingBox.height;
      if (area > maxArea) {
        maxArea = area;
        mainFace = face;
      }
    }

    // Distance Check
    double faceRatio =
        mainFace.boundingBox.width / inputImage.metadata!.size.width;
    if (faceRatio < 0.15) {
      _stableFrames = 0; // Reset if too far
      if (mounted)
        setState(() {
          _statusMessage = "Move Closer";
          _statusColor = Colors.orange;
        });
      return;
    }

    // --- STABILITY LOGIC ---
    // Instead of checking for Spoof, we check for Stability.
    // This forces the user to "Hold Still" which fixes the blurry/wrong face issue.
    if (_stableFrames < _requiredStableFrames) {
      _stableFrames++;
      if (mounted) {
        setState(() {
          _statusMessage =
              "Hold still... (${_stableFrames}/${_requiredStableFrames})";
          _statusColor = Colors.yellowAccent;
        });
      }
      return; // Not stable yet, skip verification
    }

    // If we reach here, face is stable. Proceed to Verify.
    await _verifyStudent(image, mainFace);
  }

  Future<void> _verifyStudent(CameraImage image, Face face) async {
    final faceEmbedding = await _tfliteManager.generateFaceEmbedding(
      image,
      faceBox: face.boundingBox,
    );

    if (faceEmbedding.isEmpty) return;

    final matchingService = FaceRecognitionService();
    final matchResult = await matchingService.findMatchingStudent(
      faceEmbedding,
    );

    if (!mounted) return;

    if (matchResult != null) {
      setState(() {
        _isVerified = true;
        _statusMessage = "Hi ${matchResult.fullName}!\nMarking attendance...";
        _statusColor = Colors.blueAccent;
      });

      _attendanceService
          .markAttendance(matchResult.studentId)
          .then((className) {
            if (mounted) {
              setState(() {
                if (className != null) {
                  _statusMessage = "✅ Success!\nAttended: $className";
                  _statusColor = Colors.green;
                } else {
                  _statusMessage = "✅ Logged in (No Class Now)";
                  _statusColor = Colors.green;
                }
              });

              // Reset after 3 seconds
              Future.delayed(const Duration(seconds: 3), () {
                if (mounted) {
                  setState(() {
                    _isVerified = false;
                    _stableFrames = 0;
                    _statusMessage = "Align face to scan";
                    _statusColor = Colors.white;
                  });
                }
              });
            }
          })
          .catchError((e) {
            if (mounted) {
              setState(() {
                _statusMessage =
                    "❌ Hi ${matchResult.fullName}.\nNo active class found.";
                _statusColor = Colors.orange;
              });
              Future.delayed(const Duration(seconds: 4), () {
                if (mounted)
                  setState(() {
                    _isVerified = false;
                    _stableFrames = 0;
                  });
              });
            }
          });
    } else {
      // NO MATCH FOUND
      // Reset stability so it retries from scratch (prevents locking onto a wrong match)
      _stableFrames = 0;
      if (mounted) {
        setState(() {
          _statusMessage = "Face not recognized. Try again.";
          _statusColor = Colors.redAccent;
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
    _controller?.stopImageStream();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('Attendance Scanner')),
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
                    child: Text(
                      _statusMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _statusColor,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
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
