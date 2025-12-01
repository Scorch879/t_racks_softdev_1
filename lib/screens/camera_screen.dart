import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:t_racks_softdev_1/services/tflite_service.dart';
import 'package:t_racks_softdev_1/services/camera_service.dart'; // Ensure this path is correct

class AttendanceCameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const AttendanceCameraScreen({super.key, required this.cameras});

  @override
  State<AttendanceCameraScreen> createState() => _AttendanceCameraScreenState();
}

class _AttendanceCameraScreenState extends State<AttendanceCameraScreen> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  bool _isDetecting = false;

  // Performance: Throttle AI to run only 2 times per second
  int _lastRunTime = 0;
  final int _throttleDuration = 500;

  final ModelManager _modelManager = ModelManager();

  String _detectionStatus = 'Initializing...';
  double _realFaceConfidence = 0.0;

  @override
  void initState() {
    super.initState();
    _modelManager
        .loadModel()
        .then((_) {
          if (mounted) {
            setState(
              () => _detectionStatus = 'Model Loaded. Starting Camera...',
            );
            _initializeCamera();
          }
        })
        .catchError((e) {
          if (mounted) setState(() => _detectionStatus = 'Model Error: $e');
        });
  }

  void _initializeCamera() {
    if (widget.cameras.isEmpty) return;

    // Use front camera if available
    final frontCamera = widget.cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => widget.cameras[0],
    );

    _controller = CameraController(
      frontCamera,
      ResolutionPreset
          .medium, // Medium is a good balance for preview quality vs AI speed
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    _initializeControllerFuture = _controller!.initialize().then((_) {
      if (mounted) {
        setState(() {});
        if (_modelManager.isModelLoaded) {
          _startImageStream();
        }
      }
    });
  }

  void _startImageStream() {
    if (_controller == null || !_controller!.value.isInitialized) return;

    _controller!.startImageStream((CameraImage image) async {
      // Throttle (500ms)
      final int currentTime = DateTime.now().millisecondsSinceEpoch;
      if (currentTime - _lastRunTime < _throttleDuration) return;

      if (!_isDetecting && _modelManager.isModelLoaded) {
        _isDetecting = true;
        _lastRunTime = currentTime;

        try {
          final results = await _modelManager.runInferenceOnCameraImage(image);

          if (results.isEmpty) {
            throw Exception("Model returned empty results");
          }

          // --- LOGIC TO DISPLAY RESULTS ---
          // Assuming 3 classes. Adjust indices [0,1,2] to match your labels.txt
          // Example: 0=Real, 1=Background, 2=Fake
          double realScore = results.length > 0 ? results[0] : 0;
          double fakeScore = results.length > 2 ? results[2] : 0;

          String statusText = "Scanning...";

          if (realScore > 0.8) {
            statusText = "✅ REAL FACE (${(realScore * 100).toInt()}%)";
          } else if (fakeScore > 0.8) {
            statusText = "⚠️ FAKE DETECTED (${(fakeScore * 100).toInt()}%)";
          } else {
            statusText = "Analyzing... ($results)";
          }

          if (mounted) {
            setState(() {
              _detectionStatus = statusText;
              _realFaceConfidence = realScore;
            });
          }
        } catch (e) {
          // SHOW ERROR ON SCREEN so we know why it's stuck
          if (mounted) {
            setState(() {
              _detectionStatus = "Error: $e";
            });
          }
          print("Inference Error: $e");
        } finally {
          _isDetecting = false;
        }
      }
    });
  }

  @override
  void dispose() {
    _modelManager.close();
    _controller?.stopImageStream();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Colors.black, // Dark background looks better for camera apps
      appBar: AppBar(title: const Text('Face Attendance')),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              _controller != null &&
              _controller!.value.isInitialized) {
            // --- FIX START: Aspect Ratio & Scaling Logic ---
            final size = MediaQuery.of(context).size;
            final deviceRatio = size.width / size.height;

            // Calculate scale to ensure the camera covers the screen (BoxFit.cover equivalent)
            // This math fixes the "squished" look on emulators and tall phones
            double scale = 1.0;
            if (deviceRatio < _controller!.value.aspectRatio) {
              // Screen is taller than camera (Portrait phone vs Landscape sensor)
              scale = 1 / _controller!.value.aspectRatio * deviceRatio;
              // Invert logic if needed depending on exact sensor rotation
              if (scale < 1) scale = 1 / scale;
            } else {
              scale = _controller!.value.aspectRatio / deviceRatio;
            }

            return Stack(
              children: [
                // 1. The Camera Preview (Scaled & Centered)
                Center(
                  child: Transform.scale(
                    scale: scale,
                    alignment: Alignment.center,
                    child: CameraPreview(_controller!),
                  ),
                ),

                // 2. Dark Overlay for text legibility
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: double.infinity,
                    color: Colors.black54,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _detectionStatus,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          'Confidence: ${(_realFaceConfidence * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
            // --- FIX END ---
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
