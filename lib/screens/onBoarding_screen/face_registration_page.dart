import 'dart:io';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:t_racks_softdev_1/services/tflite_service.dart' as tflite;

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
    ),
  );

  bool _isCameraInitialized = false;
  bool _isScanning = true;

  // Data Collection
  List<List<double>> _collectedVectors = [];
  final int _requiredSamples = 20;

  // Processing Throttling
  DateTime _lastFrameTime = DateTime.now();
  final int _processingIntervalMs = 50;

  // UI State
  String _feedbackText = "Align Face";
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
      if (!_isScanning) return;

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

        // --- 1. RESET LOGIC (Face Lost) ---
        if (faces.isEmpty) {
          // If we had progress, wipe it because the stream was broken
          if (_collectedVectors.isNotEmpty) {
            _collectedVectors.clear();
          }

          _updateFeedback("Face Lost - Resetting...", Colors.redAccent, 0.0);
          return;
        }

        final Face face = faces.first;

        // --- 2. DISTANCE CHECK ---
        final double imageWidth = inputImage.metadata!.size.width;
        final double faceWidth = face.boundingBox.width;
        final double ratio = faceWidth / imageWidth;

        if (ratio < 0.20) {
          _collectedVectors.clear(); // Reset if they move too far
          _isTooFar = true;
          _isTooClose = false;
          _updateFeedback("Move Closer", Colors.orangeAccent, 0.0);
          return;
        } else if (ratio > 0.70) {
          _collectedVectors.clear(); // Reset if too close
          _isTooFar = false;
          _isTooClose = true;
          _updateFeedback("Move Back", Colors.orangeAccent, 0.0);
          return;
        }

        _isTooFar = false;
        _isTooClose = false;

        // --- 3. ANGLE CHECK ---
        if ((face.headEulerAngleY ?? 0).abs() > 12 ||
            (face.headEulerAngleZ ?? 0).abs() > 12) {
          _collectedVectors.clear(); // Reset if they turn away
          _updateFeedback("Look Straight", Colors.yellowAccent, 0.0);
          return;
        }

        // --- 4. CAPTURE & ACCUMULATE ---
        List<double> vector = List<double>.from(
          await _modelManager.generateFaceEmbedding(
            image,
            faceBox: face.boundingBox,
          ),
        );

        if (vector.isNotEmpty) {
          _collectedVectors.add(vector);

          double newProgress = _collectedVectors.length / _requiredSamples;
          _updateFeedback("Hold still...", Colors.greenAccent, newProgress);

          if (_collectedVectors.length >= _requiredSamples) {
            _finishRegistration();
          }
        }
      } catch (e) {
        debugPrint("Error: $e");
      }
    });
  }

  void _updateFeedback(String text, Color color, double progress) {
    if (!mounted) return;
    // Only rebuild if something changed to save UI resources
    if (_feedbackText != text || _ringColor != color || _progress != progress) {
      setState(() {
        _feedbackText = text;
        _ringColor = color;
        _progress = progress.clamp(0.0, 1.0);
      });
    }
  }

  void _finishRegistration() async {
    setState(() => _isScanning = false);
    await _controller!.stopImageStream();

    _updateFeedback("Processing...", Colors.green, 1.0);

    // Calculate Average Vector
    List<double> finalVector = List.filled(512, 0.0);
    if (_collectedVectors.isNotEmpty) {
      for (var vec in _collectedVectors) {
        for (int i = 0; i < 512; i++) {
          finalVector[i] += vec[i];
        }
      }
      finalVector = finalVector
          .map((e) => e / _collectedVectors.length)
          .toList();
      finalVector = _l2Normalize(finalVector);
    }

    try {
      await Future.delayed(const Duration(milliseconds: 500));
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
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  _feedbackText.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _ringColor,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.8),
                        blurRadius: 8,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Align face within circle",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),

          // --- BACK BUTTON (Commented out based on your request) ---
          /*
          Positioned(
            top: 50, left: 20,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          */
        ],
      ),
    );
  }
}

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
    final path = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    double effectiveRadius = holeRadius + (isError ? (pulse * 10) : 0);
    final holePath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: effectiveRadius));
    final overlayPath = Path.combine(PathOperation.difference, path, holePath);

    canvas.drawPath(
      overlayPath,
      Paint()
        ..color = Colors.black.withOpacity(0.65)
        ..style = PaintingStyle.fill,
    );

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..color = ringColor;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: effectiveRadius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      ringPaint,
    );
  }

  @override
  bool shouldRepaint(covariant FaceOverlayPainter oldDelegate) => true;
}
