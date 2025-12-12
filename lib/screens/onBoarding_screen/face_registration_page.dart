import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:t_racks_softdev_1/services/tflite_service.dart' as tflite;

class FaceRegistrationPage extends StatefulWidget {
  final Function(File image, List<double> vector) onFaceCaptured;

  const FaceRegistrationPage({super.key, required this.onFaceCaptured});

  @override
  State<FaceRegistrationPage> createState() => _FaceRegistrationPageState();
}

enum _RegistrationState { scanning, processing, done }

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
  _RegistrationState _state = _RegistrationState.scanning;
  List<List<double>> _collectedVectors = [];
  final int _requiredSamples = 10;

  DateTime _lastFrameTime = DateTime.now();
  bool _isProcessingFrame = false;
  bool _isCapturing = false;

  // UI State
  String _feedbackText = "Align Face";
  Color _statusColor = Colors.white;
  double _progress = 0.0;

  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _initializeCameraAndModels();
  }

  Future<void> _initializeCameraAndModels() async {
    await _modelManager.loadModels();

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) throw Exception("No cameras found");

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
    } catch (e) {
      if (mounted) _updateFeedback("Camera Error", Colors.red, 0.0);
    }
  }

  void _startImageStream() {
    if (_controller == null) return;

    _controller!.startImageStream((CameraImage image) async {
      // 1. CAPTURE LOGIC
      if (_state == _RegistrationState.processing && !_isCapturing) {
        _isCapturing = true;
        try {
          // Deep copy immediately to safe memory
          final rawData = _RawImageData(
            planes: image.planes
                .map((p) => Uint8List.fromList(p.bytes))
                .toList(),
            width: image.width,
            height: image.height,
            yRowStride: image.planes[0].bytesPerRow,
            uvRowStride: image.planes.length > 1
                ? image.planes[1].bytesPerRow
                : 0,
            uvPixelStride: image.planes.length > 1
                ? (image.planes[1].bytesPerPixel ?? 1)
                : 0,
          );

          // Run save in background
          Future.microtask(() => _handleFinalSave(rawData));
        } catch (e) {
          print("Copy Error: $e");
          _isCapturing = false;
        }
        return;
      }

      // 2. SCANNING LOGIC
      if (_state != _RegistrationState.scanning ||
          _isProcessingFrame ||
          _isCapturing)
        return;

      final now = DateTime.now();
      if (now.difference(_lastFrameTime).inMilliseconds < 100) return;
      _lastFrameTime = now;

      _isProcessingFrame = true;

      try {
        final inputImage = _inputImageFromCameraImage(image);
        if (inputImage == null) return;

        final faces = await _faceDetector.processImage(inputImage);
        if (!mounted) return;

        if (faces.isEmpty) {
          _updateFeedback("Position Face in Circle", Colors.white, 0.0);
          return;
        }

        final Face face = faces.first;
        final double imageWidth = inputImage.metadata!.size.width;
        final double faceWidth = face.boundingBox.width;
        final double ratio = faceWidth / imageWidth;

        if (ratio < 0.20) {
          _updateFeedback("Move Closer", Colors.orangeAccent, 0.0);
          return;
        }
        if (ratio > 0.80) {
          _updateFeedback("Move Back", Colors.orangeAccent, 0.0);
          return;
        }
        if ((face.headEulerAngleY ?? 0).abs() > 25 ||
            (face.headEulerAngleZ ?? 0).abs() > 25) {
          _updateFeedback("Look Straight", Colors.yellowAccent, 0.0);
          return;
        }

        List<double> vector = await _modelManager.generateFaceEmbedding(
          image,
          faceBox: face.boundingBox,
        );

        if (vector.isNotEmpty) {
          if (_state == _RegistrationState.scanning) {
            _collectedVectors.add(vector);
            double newProgress = _collectedVectors.length / _requiredSamples;
            _updateFeedback(
              "Scanning...",
              const Color(0xFF4DBD88),
              newProgress,
            );

            if (_collectedVectors.length % 2 == 0)
              HapticFeedback.selectionClick();

            if (_collectedVectors.length >= _requiredSamples) {
              _triggerProcessingState();
            }
          }
        }
      } catch (e) {
        debugPrint("Stream Error: $e");
      } finally {
        _isProcessingFrame = false;
      }
    });
  }

  void _triggerProcessingState() {
    if (!mounted) return;
    setState(() {
      _state = _RegistrationState.processing;
      _feedbackText = "Saving...";
    });
  }

  Future<void> _handleFinalSave(_RawImageData rawData) async {
    try {
      HapticFeedback.mediumImpact();

      // Average Vectors
      List<double> finalVector = List.filled(512, 0.0);
      if (_collectedVectors.isEmpty) throw Exception("No face data collected");

      for (var vec in _collectedVectors) {
        for (int i = 0; i < 512; i++) {
          finalVector[i] += vec[i];
        }
      }
      finalVector = finalVector
          .map((e) => e / _collectedVectors.length)
          .toList();
      finalVector = _l2Normalize(finalVector);

      // Encode Image
      final directory = await getTemporaryDirectory();
      final String savePath =
          '${directory.path}/profile_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final File profileImage = await compute(
        _encodeImageFromCamera,
        _IsolateImageReq(data: rawData, savePath: savePath),
      );

      if (mounted) {
        setState(() {
          _state = _RegistrationState.done;
          _feedbackText = "Face Captured!";
          _statusColor = Colors.green;
        });
        widget.onFaceCaptured(profileImage, finalVector);
      }
    } catch (e) {
      print("Save Failed: $e");
      if (mounted) {
        _updateFeedback("Error Saving. Retrying...", Colors.red, 0.0);
        await Future.delayed(const Duration(seconds: 2));
        _collectedVectors.clear();
        _isCapturing = false;
        setState(() => _state = _RegistrationState.scanning);
      }
    }
  }

  void _updateFeedback(String text, Color color, double progress) {
    if (!mounted) return;
    if (_feedbackText != text || (_progress - progress).abs() > 0.01) {
      setState(() {
        _feedbackText = text;
        _statusColor = color;
        _progress = progress.clamp(0.0, 1.0);
      });
      _progressController.animateTo(progress);
    }
  }

  static Future<File> _encodeImageFromCamera(_IsolateImageReq req) async {
    try {
      img.Image image;
      final data = req.data;
      final int w = data.width;
      final int h = data.height;

      // Smart Detection: BGRA vs YUV
      // BGRA requires 4 bytes per pixel.
      // If buffer is too small, it MUST be YUV (1.5 bytes per pixel)
      bool isYUV = false;
      if (data.planes.length == 1) {
        if (data.planes[0].lengthInBytes < (w * h * 4)) {
          isYUV = true;
        }
      } else {
        isYUV = true; // Multiple planes is always YUV
      }

      if (!isYUV && data.planes.length == 1) {
        // Standard BGRA (iOS/Simulators)
        image = img.Image.fromBytes(
          width: w,
          height: h,
          bytes: data.planes[0].buffer,
          order: img.ChannelOrder.bgra,
        );
      } else {
        // YUV (Android Real Device)
        image = img.Image(width: w, height: h);
        final yBuffer = data.planes[0];
        // Handle single-plane YUV (NV21) where UV follows Y
        final Uint8List uBuffer;
        final Uint8List vBuffer;

        if (data.planes.length > 1) {
          uBuffer = data.planes[1];
          vBuffer = data.planes[2];
        } else {
          // Single plane YUV: UV starts after Y (w*h)
          uBuffer = yBuffer;
          vBuffer = yBuffer;
        }

        final int yStride = data.yRowStride;
        final int uvStride = data.uvRowStride > 0
            ? data.uvRowStride
            : data.yRowStride;
        final int uvPixelStride = data.uvPixelStride > 0
            ? data.uvPixelStride
            : 2;

        // Safe loop with Bounds Checking
        for (int y = 0; y < h; y++) {
          for (int x = 0; x < w; x++) {
            final int yIndex = y * yStride + x;
            final int uvRow = (y ~/ 2);
            final int uvCol = (x ~/ 2);
            final int uvIndexRaw = uvRow * uvStride + uvCol * uvPixelStride;

            // Adjust offset for single-plane NV21
            final int uvBase = (data.planes.length == 1) ? (yStride * h) : 0;
            final int uvIndex = uvBase + uvIndexRaw;

            if (yIndex >= yBuffer.length) continue;

            final int yVal = yBuffer[yIndex];

            // Default gray if UV out of bounds
            int uVal = 128;
            int vVal = 128;

            // NV21 is V then U. NV12 is U then V. Android often uses NV21.
            // We check both bounds to be safe.
            if (uvIndex < uBuffer.length - 1) {
              // -1 because we need 2 bytes
              vVal = vBuffer[uvIndex];
              uVal = uBuffer[uvIndex + 1];
            }

            int r = (yVal + 1.370705 * (vVal - 128)).toInt();
            int g = (yVal - 0.337633 * (uVal - 128) - 0.698001 * (vVal - 128))
                .toInt();
            int b = (yVal + 1.732446 * (uVal - 128)).toInt();

            image.setPixelRgb(
              x,
              y,
              r.clamp(0, 255),
              g.clamp(0, 255),
              b.clamp(0, 255),
            );
          }
        }
      }

      final img.Image rotated = img.copyRotate(image, angle: -90);
      final file = File(req.savePath);
      await file.writeAsBytes(img.encodeJpg(rotated, quality: 85));
      return file;
    } catch (e) {
      print("Encode Error: $e");
      rethrow;
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
    if (_controller == null) return null;

    final camera = _controller!.description;
    final sensorOrientation = camera.sensorOrientation;
    final rotation = InputImageRotationValue.fromRawValue(
      Platform.isAndroid ? (sensorOrientation + 0) % 360 : sensorOrientation,
    );
    if (rotation == null) return null;
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;

    if (image.planes.isEmpty) return null;

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
    _faceDetector.close();
    _controller?.dispose();
    _progressController.dispose();
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
    final double holeRadius = size.width * 0.38;

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

          CustomPaint(
            painter: HolePunchPainter(holeRadius: holeRadius),
            child: Container(),
          ),

          Center(
            child: SizedBox(
              width: holeRadius * 2 + 20,
              height: holeRadius * 2 + 20,
              child: AnimatedBuilder(
                animation: _progressController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: ProgressRingPainter(
                      progress: _progressController.value,
                      color: _statusColor,
                    ),
                  );
                },
              ),
            ),
          ),

          Positioned(
            bottom: 120,
            left: 0,
            right: 0,
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: _statusColor == Colors.white
                      ? Colors.black54
                      : _statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: _statusColor == Colors.white
                        ? Colors.white30
                        : _statusColor,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  _feedbackText,
                  style: TextStyle(
                    color: _statusColor == Colors.white
                        ? Colors.white
                        : _statusColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  "Face Registration",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Hold camera eye level & look straight",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RawImageData {
  final List<Uint8List> planes;
  final int width;
  final int height;
  final int yRowStride;
  final int uvRowStride;
  final int uvPixelStride;

  _RawImageData({
    required this.planes,
    required this.width,
    required this.height,
    required this.yRowStride,
    required this.uvRowStride,
    required this.uvPixelStride,
  });
}

class _IsolateImageReq {
  final _RawImageData data;
  final String savePath;

  _IsolateImageReq({required this.data, required this.savePath});
}

class HolePunchPainter extends CustomPainter {
  final double holeRadius;
  HolePunchPainter({required this.holeRadius});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final bgPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final holePath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: holeRadius));
    final path = Path.combine(PathOperation.difference, bgPath, holePath);
    canvas.drawPath(path, Paint()..color = Colors.black.withOpacity(0.85));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color color;

  ProgressRingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = Colors.white.withOpacity(0.1);
    canvas.drawArc(rect, 0, math.pi * 2, false, trackPaint);

    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..color = color;

    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(ProgressRingPainter old) =>
      old.progress != progress || old.color != color;
}
