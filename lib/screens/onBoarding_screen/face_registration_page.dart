import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:t_racks_softdev_1/services/tflite_service.dart' as tflite;
import 'dart:math' as math;

enum RegistrationStep { center, left, right, done }

class FaceRegistrationPage extends StatefulWidget {
  final Function(File image, List<double> vector) onFaceCaptured;

  const FaceRegistrationPage({super.key, required this.onFaceCaptured});

  @override
  State<FaceRegistrationPage> createState() => _FaceRegistrationPageState();
}

class _FaceRegistrationPageState extends State<FaceRegistrationPage> {
  CameraController? _controller;
  final tflite.ModelManager _modelManager = tflite.ModelManager();
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableLandmarks: true,
      performanceMode: FaceDetectorMode.fast,
    ),
  );

  bool _isCameraInitialized = false;
  RegistrationStep _currentStep = RegistrationStep.center;

  List<List<double>> _collectedVectors = [];
  int _samplesForCurrentStep = 0;
  final int _samplesPerStep = 10;

  DateTime _lastFrameTime = DateTime.now();
  int _processingIntervalMs = 250;

  String _statusMessage = "Initializing...";
  Color _statusColor = Colors.white;

  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _modelManager.loadModels();
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
      if (_currentStep == RegistrationStep.done) return;

      if (DateTime.now().difference(_lastFrameTime).inMilliseconds <
          _processingIntervalMs) {
        return;
      }
      _lastFrameTime = DateTime.now();

      try {
        final inputImage = _inputImageFromCameraImage(image);
        if (inputImage == null) return;

        final faces = await _faceDetector.processImage(inputImage);
        if (faces.isEmpty) {
          _updateStatus("No Face Detected", Colors.red);
          _setScanning(false);
          return;
        }

        final Face face = faces.first;

        // Distance Check
        double faceWidthRatio =
            face.boundingBox.width / inputImage.metadata!.size.width;
        if (faceWidthRatio < 0.20) {
          _updateStatus("Too Far! Move Closer", Colors.orange);
          _setScanning(false);
          return;
        }
        if (faceWidthRatio > 0.70) {
          _updateStatus("Too Close! Move Back", Colors.orange);
          _setScanning(false);
          return;
        }

        // 1. Check Angle
        bool isAngleCorrect = _checkHeadAngle(face);

        if (isAngleCorrect) {
          _setScanning(true);

          // 2. Liveness Check (Disabled for Reg, relying on gestures)
          bool performLiveness = false;
          bool isReal = true;

          if (performLiveness) {
            isReal = await _modelManager.checkLiveness(image);
          }

          if (isReal) {
            // 3. Generate Vector
            List<double> vector = List<double>.from(
              await _modelManager.generateFaceEmbedding(
                image,
                faceBox: face.boundingBox,
              ),
            );

            if (vector.isNotEmpty) {
              if (_currentStep == RegistrationStep.center) {
                _collectedVectors.add(vector);
              }

              _samplesForCurrentStep++;
              if (_samplesForCurrentStep >= _samplesPerStep) {
                _advanceStep();
              }
            }
          }
        } else {
          _setScanning(false);
        }
      } catch (e) {
        print("Error: $e");
      }
    });
  }

  void _setScanning(bool isScanning) {
    if (_isScanning != isScanning && mounted) {
      setState(() {
        _isScanning = isScanning;
      });
    }
  }

  bool _checkHeadAngle(Face face) {
    double yRotation = face.headEulerAngleY ?? 0;
    const double centerBound = 12.0;
    const double turnThreshold = 18.0;

    switch (_currentStep) {
      case RegistrationStep.center:
        if (yRotation.abs() < centerBound) {
          _updateStatus("Scanning...", Colors.green);
          return true;
        }
        _updateStatus("Look Straight", Colors.white);
        return false;

      case RegistrationStep.left:
        if (yRotation > turnThreshold) {
          _updateStatus("Scanning Left...", Colors.green);
          return true;
        }
        _updateStatus("Turn Head Left ⬅️", Colors.blueAccent);
        return false;

      case RegistrationStep.right:
        if (yRotation < -turnThreshold) {
          _updateStatus("Scanning Right...", Colors.green);
          return true;
        }
        _updateStatus("Turn Head Right ➡️", Colors.blueAccent);
        return false;

      default:
        return false;
    }
  }

  void _advanceStep() {
    _samplesForCurrentStep = 0;
    if (mounted) {
      setState(() {
        if (_currentStep == RegistrationStep.center) {
          _currentStep = RegistrationStep.left;
        } else if (_currentStep == RegistrationStep.left) {
          _currentStep = RegistrationStep.right;
        } else if (_currentStep == RegistrationStep.right) {
          _currentStep = RegistrationStep.done;
          _finishRegistration();
        }
      });
    }
  }

  void _finishRegistration() async {
    await _controller!.stopImageStream();

    List<double> finalVector = List.filled(512, 0.0);

    if (_collectedVectors.isNotEmpty) {
      for (var vec in _collectedVectors) {
        if (vec.length == 512) {
          for (int i = 0; i < 512; i++) {
            finalVector[i] += vec[i];
          }
        }
      }
      finalVector = finalVector
          .map((e) => e / _collectedVectors.length)
          .toList();

      finalVector = _l2Normalize(finalVector);
    }

    try {
      await Future.delayed(const Duration(milliseconds: 200));
      final XFile file = await _controller!.takePicture();

      if (mounted) {
        _updateStatus("Done!", Colors.green);
        widget.onFaceCaptured(File(file.path), finalVector);
      }
    } catch (e) {
      print("Error capturing: $e");
    }
  }

  List<double> _l2Normalize(List<double> vector) {
    double sum = 0;
    for (var x in vector) sum += x * x;
    double norm = math.sqrt(sum);
    if (norm == 0) return vector;
    return vector.map((x) => x / norm).toList();
  }

  void _updateStatus(String msg, Color color) {
    if (mounted && _statusMessage != msg) {
      setState(() {
        _statusMessage = msg;
        _statusColor = color;
      });
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
        image.planes.fold(<int>[], (p, e) => p..addAll(e.bytes)),
      ),
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
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
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Camera Preview
          SizedBox(
            width: size.width,
            height: size.height,
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller!.value.previewSize!.height,
                height: _controller!.value.previewSize!.width,
                child: CameraPreview(_controller!),
              ),
            ),
          ),

          // 2. Header (Top)
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Face Registration",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [Shadow(blurRadius: 10, color: Colors.black)],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        "Remove glasses/masks",
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. Scanner Guide (Center)
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Glow Effect
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: size.width * 0.72,
                  height: size.width * 0.72, // Square box for face
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _isScanning
                          ? Colors.green.withOpacity(0.8)
                          : Colors.transparent,
                      width: 6,
                    ),
                    boxShadow: _isScanning
                        ? [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.4),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ]
                        : [],
                  ),
                ),

                // Main Guide Box
                Container(
                  width: size.width * 0.7,
                  height: size.width * 0.7,
                  decoration: BoxDecoration(
                    border: Border.all(color: _statusColor, width: 4),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: _currentStep == RegistrationStep.done
                        ? const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 80,
                          )
                        : Icon(
                            Icons.face_retouching_natural,
                            color: Colors.white.withOpacity(0.3),
                            size: 60,
                          ),
                  ),
                ),
              ],
            ),
          ),

          // 4. Status Panel (Bottom)
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black87.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _statusMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _statusColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Progress Bar
                    Stack(
                      children: [
                        Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: 8,
                          width:
                              ((size.width - 80) *
                              ((_collectedVectors.length) /
                                  (_samplesPerStep * 3))),
                          decoration: BoxDecoration(
                            color: _isScanning
                                ? Colors.greenAccent
                                : const Color(0xFF26A69A),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "${((_collectedVectors.length / (_samplesPerStep * 3)) * 100).clamp(0, 100).toInt()}%",
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
