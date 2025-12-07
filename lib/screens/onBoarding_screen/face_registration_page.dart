import 'dart:io';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:t_racks_softdev_1/services/tflite_service.dart' as tflite;

enum RegistrationStep { center, left, right, done }

class FaceRegistrationPage extends StatefulWidget {
  final Function(File image, List<double> vector) onFaceCaptured;

  const FaceRegistrationPage({super.key, required this.onFaceCaptured});

  @override
  State<FaceRegistrationPage> createState() => _FaceRegistrationPageState();
}

class _FaceRegistrationPageState extends State<FaceRegistrationPage>
    with TickerProviderStateMixin {
  CameraController? _controller;
  final tflite.ModelManager _modelManager = tflite.ModelManager();

  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableLandmarks: true,
      performanceMode: FaceDetectorMode.fast,
      enableClassification: true,
    ),
  );

  bool _isCameraInitialized = false;
  RegistrationStep _currentStep = RegistrationStep.center;

  // Data Collection
  List<List<double>> _collectedVectors = [];
  int _samplesForCurrentStep = 0;
  final int _samplesPerStep = 10;

  // Processing
  DateTime _lastFrameTime = DateTime.now();
  final int _processingIntervalMs = 150;

  // UI State
  String _mainInstruction = "Look Straight";
  String _subInstruction = "Align your face in the circle";
  Color _ringColor = Colors.white;
  double _progress = 0.0;
  bool _isTooFar = false;
  bool _isTooClose = false;

  // Animations
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _modelManager.loadModels();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _controller = CameraController(
      frontCamera,
      ResolutionPreset.high, // Better quality for full screen
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

        if (!mounted) return;

        if (faces.isEmpty) {
          _updateUI(
            "No Face Detected",
            "Please show your face",
            Colors.redAccent,
            0.0,
          );
          return;
        }

        final Face face = faces.first;

        // --- 1. DISTANCE CHECK ---
        final double imageWidth = inputImage.metadata!.size.width;
        final double faceWidth = face.boundingBox.width;
        final double ratio = faceWidth / imageWidth;

        // Adjusted thresholds for comfort
        const double minRatio = 0.15; // Move Closer
        const double maxRatio = 0.75; // Move Back

        if (ratio < minRatio) {
          _isTooFar = true;
          _isTooClose = false;
          _updateUI(
            "Move Closer",
            "Your face is too far away",
            Colors.orangeAccent,
            _progress,
          );
          return;
        } else if (ratio > maxRatio) {
          _isTooFar = false;
          _isTooClose = true;
          _updateUI(
            "Move Back",
            "You are too close to the camera",
            Colors.orangeAccent,
            _progress,
          );
          return;
        }

        _isTooFar = false;
        _isTooClose = false;

        // --- 2. ANGLE & LOGIC ---
        bool isAngleCorrect = _checkHeadAngle(face);

        if (isAngleCorrect) {
          // Valid frame! Generate embedding
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

            // Calculate Progress
            int totalSamples = _samplesPerStep * 3;
            int currentTotal = 0;
            if (_currentStep == RegistrationStep.center) {
              currentTotal = _samplesForCurrentStep;
            }
            if (_currentStep == RegistrationStep.left) {
              currentTotal = _samplesPerStep + _samplesForCurrentStep;
            }
            if (_currentStep == RegistrationStep.right) {
              currentTotal = (_samplesPerStep * 2) + _samplesForCurrentStep;
            }

            double newProgress = (currentTotal / totalSamples).clamp(0.0, 1.0);

            _updateUI(
              "Scanning...",
              "Hold still",
              Colors.greenAccent,
              newProgress,
            );

            if (_samplesForCurrentStep >= _samplesPerStep) {
              _advanceStep();
            }
          }
        }
      } catch (e) {
        debugPrint("Error: $e");
      }
    });
  }

  void _updateUI(
    String mainText,
    String subText,
    Color color,
    double progress,
  ) {
    if (!mounted) return;
    if (_mainInstruction != mainText ||
        _subInstruction != subText ||
        _ringColor != color ||
        _progress != progress) {
      setState(() {
        _mainInstruction = mainText;
        _subInstruction = subText;
        _ringColor = color;
        _progress = progress;
      });
    }
  }

  bool _checkHeadAngle(Face face) {
    double yRotation = face.headEulerAngleY ?? 0;
    const double centerBound = 10.0;
    const double turnThreshold = 20.0;

    switch (_currentStep) {
      case RegistrationStep.center:
        if (yRotation.abs() < centerBound) return true;
        _updateUI(
          "Look Straight",
          "Align face to center",
          Colors.white,
          _progress,
        );
        return false;
      case RegistrationStep.left:
        if (yRotation > turnThreshold) return true;
        _updateUI(
          "Turn Left ⬅️",
          "Turn your head slowly to the left",
          Colors.blueAccent,
          _progress,
        );
        return false;
      case RegistrationStep.right:
        if (yRotation < -turnThreshold) return true;
        _updateUI(
          "Turn Right ➡️",
          "Turn your head slowly to the right",
          Colors.blueAccent,
          _progress,
        );
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
          // Prompt immediately for next step
          _updateUI(
            "Turn Left ⬅️",
            "Turn your head slowly to the left",
            Colors.blueAccent,
            _progress,
          );
        } else if (_currentStep == RegistrationStep.left) {
          _currentStep = RegistrationStep.right;
          // Prompt immediately for next step
          _updateUI(
            "Turn Right ➡️",
            "Turn your head slowly to the right",
            Colors.blueAccent,
            _progress,
          );
        } else if (_currentStep == RegistrationStep.right) {
          _currentStep = RegistrationStep.done;
          _finishRegistration();
        }
      });
    }
  }

  void _finishRegistration() async {
    await _controller!.stopImageStream();

    // 1. Show Success UI immediately
    if (mounted) {
      setState(() {
        _mainInstruction = "Success!";
        _subInstruction = "Face successfully scanned.";
        _ringColor = Colors.green;
        _progress = 1.0;
      });
    }

    // 2. Process final vector
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
      // Delay slightly so user sees the "Success" green ring
      await Future.delayed(const Duration(milliseconds: 800));
      final XFile file = await _controller!.takePicture();
      if (mounted) {
        widget.onFaceCaptured(File(file.path), finalVector);
      }
    } catch (e) {
      debugPrint("Error capturing final image: $e");
    }
  }

  List<double> _l2Normalize(List<double> vector) {
    double sum = 0;
    for (var x in vector) sum += x * x;
    double norm = math.sqrt(sum);
    if (norm == 0) return vector;
    return vector.map((x) => x / norm).toList();
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
    _pulseController.dispose();
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
          // 1. CAMERA LAYER
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

          // 2. OVERLAY LAYER (Darkness + Hole)
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return CustomPaint(
                painter: FaceOverlayPainter(
                  holeRadius: size.width * 0.35,
                  progress: _progress,
                  ringColor: _ringColor,
                  pulse: _pulseController.value,
                  isError: _isTooFar || _isTooClose,
                ),
                child: Container(),
              );
            },
          ),

          // 3. UI TEXT LAYER
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 30),

                // TOP: Main Instruction
                Text(
                  _mainInstruction.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _ringColor, // Color matches the status ring
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    shadows: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.8),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // Sub Instruction
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Text(
                    _subInstruction,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                    ),
                  ),
                ),

                const Spacer(), // Pushes content to top/bottom
                // BOTTOM: Hint or Progress
                if (_currentStep == RegistrationStep.done)
                  Container(
                    margin: const EdgeInsets.only(bottom: 50),
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.green, width: 2),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 30),
                        SizedBox(width: 10),
                        Text(
                          "Face Scanned!",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 50), // Bottom padding
              ],
            ),
          ),

          // 4. BACK BUTTON (Top Left)
          Positioned(
            top: 40,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}

// --- PAINTER CLASS ---
class FaceOverlayPainter extends CustomPainter {
  final double holeRadius;
  final double progress;
  final Color ringColor;
  final double pulse;
  final bool isError;

  FaceOverlayPainter({
    required this.holeRadius,
    required this.progress,
    required this.ringColor,
    required this.pulse,
    required this.isError,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // 1. Draw Semi-Transparent Overlay
    // I reduced opacity from 0.8 to 0.5 so the camera feels "full screen"
    final path = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    double effectiveRadius = holeRadius;
    if (isError) {
      effectiveRadius += (pulse * 5);
    }

    final holePath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: effectiveRadius));

    final overlayPath = Path.combine(PathOperation.difference, path, holePath);

    final overlayPaint = Paint()
      ..color = Colors.black
          .withOpacity(0.55) // Lighter mask
      ..style = PaintingStyle.fill;

    canvas.drawPath(overlayPath, overlayPaint);

    // 2. Draw Ring
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;

    // Dim background ring
    ringPaint.color = Colors.white.withOpacity(0.2);
    canvas.drawCircle(center, effectiveRadius, ringPaint);

    // Active progress ring
    ringPaint.color = ringColor;
    double sweepAngle = 2 * math.pi * progress;

    // Rotate -90 degrees so it starts at top
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: effectiveRadius),
      -math.pi / 2,
      sweepAngle,
      false,
      ringPaint,
    );
  }

  @override
  bool shouldRepaint(covariant FaceOverlayPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.ringColor != ringColor ||
        oldDelegate.pulse != pulse;
  }
}
