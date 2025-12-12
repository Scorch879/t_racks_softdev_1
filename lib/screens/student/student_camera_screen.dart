import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:camera/camera.dart';
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

class _AttendanceCameraScreenState extends State<AttendanceCameraScreen>
    with SingleTickerProviderStateMixin {
  CameraController? _controller;
  late FaceDetector _faceDetector;
  final tflite.ModelManager _tfliteManager = tflite.ModelManager();
  final AttendanceService _attendanceService = AttendanceService();

  bool _isProcessing = false;

  // UI State
  String _topStatus = "Scanning for students...";
  Color _scannerColor = const Color(0xFF2A7FA3); // Default Blue
  bool _isVerified = false;
  Face? _detectedFace;

  late AnimationController _scanLineController;

  @override
  void initState() {
    super.initState();
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    final options = FaceDetectorOptions(
      enableClassification: false,
      enableLandmarks: true,
      performanceMode: FaceDetectorMode.fast,
    );
    _faceDetector = FaceDetector(options: options);

    _tfliteManager.loadModels();
    _initializeCamera();
  }

  void _initializeCamera() async {
    if (widget.cameras.isEmpty) return;

    // Use back camera for scanning students
    final camera = widget.cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => widget.cameras[0],
    );

    _controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );

    await _controller!.initialize();
    if (mounted) {
      setState(() {});
      _startImageStream();
    }
  }

  void _startImageStream() {
    int frameCount = 0;
    _controller!.startImageStream((CameraImage image) async {
      if (_isProcessing || _isVerified) return;
      frameCount++;
      if (frameCount % 3 != 0) return; // Process every 3rd frame

      _isProcessing = true;
      try {
        final inputImage = _inputImageFromCameraImage(image);
        if (inputImage != null) {
          final faces = await _faceDetector.processImage(inputImage);

          if (faces.isNotEmpty) {
            final mainFace = faces.first;

            // --- 1. PROXIMITY CHECK ---
            final double faceWidth = mainFace.boundingBox.width;
            final double minImageDim =
                (image.width < image.height ? image.width : image.height)
                    .toDouble();

            // Too Close (> 65%)
            if (faceWidth > minImageDim * 0.65) {
              if (mounted)
                _updateStatus("Too Close! Zoom Out", Colors.orangeAccent);
              return;
            }

            // Too Far (< 20%) - Optional but recommended for accuracy
            if (faceWidth < minImageDim * 0.20) {
              // if (mounted) _updateStatus("Move Closer", Colors.blueAccent);
              // return;
            }

            // --- 2. HEAD POSE CHECK (Fix for Accuracy) ---
            // If the face is rotated (looking left/right) or tilted, vectors get distorted.
            final double rotY =
                mainFace.headEulerAngleY ?? 0; // Head turn (Yaw)
            final double rotZ =
                mainFace.headEulerAngleZ ?? 0; // Head tilt (Roll)

            // Strict limit: +/- 12 degrees
            if (rotY.abs() > 12 || rotZ.abs() > 12) {
              if (mounted) _updateStatus("Look Straight", Colors.yellowAccent);
              return;
            }

            // --- 3. PROCEED TO VERIFY ---
            setState(() {
              _detectedFace = mainFace;
              _scannerColor = Colors.yellowAccent;
              if (_topStatus == "Too Close! Zoom Out" ||
                  _topStatus == "Look Straight") {
                _topStatus = "Scanning for students...";
              }
            });
            await _verifyStudent(image, mainFace);
          } else {
            // No face found
            if (mounted) {
              setState(() {
                _detectedFace = null;
                _scannerColor = const Color(0xFF2A7FA3);
                _topStatus = "Scanning for students...";
              });
            }
          }
        }
      } catch (e) {
        debugPrint("Scan error: $e");
      } finally {
        _isProcessing = false;
      }
    });
  }

  void _updateStatus(String text, Color color) {
    setState(() {
      _topStatus = text;
      _scannerColor = color;
    });
  }

  Future<void> _verifyStudent(CameraImage image, Face face) async {
    final vector = await _tfliteManager.generateFaceEmbedding(
      image,
      faceBox: face.boundingBox,
    );
    if (vector.isEmpty) return;

    final service = FaceRecognitionService();
    final match = await service.findMatchingStudent(vector);

    if (!mounted) return;

    if (match != null) {
      HapticFeedback.heavyImpact();
      setState(() {
        _isVerified = true;
        _scannerColor = const Color(0xFF7FE26B); // Green
        _topStatus = "Identified: ${match.fullName}";
      });

      try {
        final className = await _attendanceService.markAttendance(
          match.studentId,
        );
        _showSuccessSheet(
          name: match.fullName,
          status: "Present: $className",
          isSuccess: true,
        );
      } catch (e) {
        _showSuccessSheet(
          name: match.fullName,
          status: "Not in any class right now.",
          isSuccess: false,
        );
      }
    } else {
      if (mounted)
        setState(() {
          _scannerColor = const Color(0xFFDA6A6A); // Red
          _topStatus = "Unknown Face";
        });
    }
  }

  void _showSuccessSheet({
    required String name,
    required String status,
    required bool isSuccess,
  }) {
    final Color mainColor = isSuccess
        ? const Color(0xFF7FE26B)
        : Colors.orangeAccent;
    final IconData icon = isSuccess
        ? Icons.check_circle
        : Icons.warning_amber_rounded;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF133A53),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: mainColor, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: mainColor, size: 50),
            const SizedBox(height: 16),
            Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              status,
              style: TextStyle(
                color: isSuccess ? Colors.white70 : Colors.orange[200],
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: mainColor,
                  foregroundColor: Colors.black,
                ),
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    _isVerified = false;
                    _topStatus = "Scanning for students...";
                    _scannerColor = const Color(0xFF2A7FA3);
                  });
                },
                child: const Text("Next Student"),
              ),
            ),
          ],
        ),
      ),
    );
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
    return InputImage.fromBytes(
      bytes: Uint8List.fromList(
        image.planes.fold(<int>[], (p, e) => p..addAll(e.bytes)),
      ),
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }

  @override
  void dispose() {
    _faceDetector.close();
    _controller?.dispose();
    _scanLineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
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
          CustomPaint(
            painter: ScannerOverlayPainter(
              color: _scannerColor,
              scanLineY: _scanLineController.value,
            ),
            child: Container(),
          ),
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: _scannerColor.withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _scannerColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: _scannerColor, blurRadius: 5),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        _topStatus,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 50,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}

class ScannerOverlayPainter extends CustomPainter {
  final Color color;
  final double scanLineY;
  ScannerOverlayPainter({required this.color, required this.scanLineY})
    : super(repaint: null);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final double w = size.width;
    final double h = size.height;
    final double cornerLen = 40.0;
    final double margin = 50.0;
    final rect = Rect.fromLTRB(margin, h / 4, w - margin, h / 1.5);

    canvas.drawLine(rect.topLeft, rect.topLeft + Offset(cornerLen, 0), paint);
    canvas.drawLine(rect.topLeft, rect.topLeft + Offset(0, cornerLen), paint);
    canvas.drawLine(rect.topRight, rect.topRight - Offset(cornerLen, 0), paint);
    canvas.drawLine(rect.topRight, rect.topRight + Offset(0, cornerLen), paint);
    canvas.drawLine(
      rect.bottomLeft,
      rect.bottomLeft + Offset(cornerLen, 0),
      paint,
    );
    canvas.drawLine(
      rect.bottomLeft,
      rect.bottomLeft - Offset(0, cornerLen),
      paint,
    );
    canvas.drawLine(
      rect.bottomRight,
      rect.bottomRight - Offset(cornerLen, 0),
      paint,
    );
    canvas.drawLine(
      rect.bottomRight,
      rect.bottomRight - Offset(0, cornerLen),
      paint,
    );

    final linePaint = Paint()
      ..color = color.withOpacity(0.5)
      ..strokeWidth = 2
      ..shader = LinearGradient(
        colors: [Colors.transparent, color, Colors.transparent],
      ).createShader(Rect.fromLTWH(rect.left, 0, rect.width, 10));

    double currentY = rect.top + (rect.height * scanLineY);
    canvas.drawLine(
      Offset(rect.left + 10, currentY),
      Offset(rect.right - 10, currentY),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(ScannerOverlayPainter old) =>
      old.scanLineY != scanLineY || old.color != color;
}
