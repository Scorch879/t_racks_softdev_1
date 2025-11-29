import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:t_racks_softdev_1/services/tflite_service.dart';
import 'package:t_racks_softdev_1/services/camera_service.dart';

class AttendanceCameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const AttendanceCameraScreen({super.key, required this.cameras});

  @override
  State<AttendanceCameraScreen> createState() => _AttendanceCameraScreenState();
}

class _AttendanceCameraScreenState extends State<AttendanceCameraScreen> {
  // Variables for Camera Control and Initialization Status
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;

  // Flag to prevent processing frames before the previous one is done
  bool _isDetecting = false;

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
            setState(() {
              _detectionStatus = 'Model Loaded. Initializing Camera...';
            });
            _initializeCamera();
          }
        })
        .catchError((e) {
          if (mounted) {
            setState(() {
              _detectionStatus = 'Model Load Failed: $e';
            });
          }
        });

    if (widget.cameras.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: No camera available.')),
        );
        Navigator.of(context).pop();
      });
    }
  }

  // Function to initialize camera and start stream
  void _initializeCamera() {
    // Attempt to find the front camera, otherwise use the first one available
    final frontCamera = widget.cameras.firstWhere(
      (description) => description.lensDirection == CameraLensDirection.front,
      orElse: () => widget.cameras[0],
    );

    // ResolutionPreset.low is best for ML inference speed
    _controller = CameraController(
      frontCamera,
      ResolutionPreset.low, // Lower resolution is faster for ML inference
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    _initializeControllerFuture = _controller!
        .initialize()
        .then((_) {
          if (mounted) {
            setState(() {
              _detectionStatus = 'Camera Ready. Waiting for face...';
            });
            if (_modelManager.isModelLoaded) {
              _startImageStream();
            }
          }
        })
        .catchError((error) {
          print('Camera initialization error: $error');
          if (mounted) {
            setState(() {
              _detectionStatus = 'Camera Error. Check permissions.';
            });
          }
        });
  }

  // Method to start listening for continuous image frames
  void _startImageStream() {
    if (_controller == null || !_controller!.value.isInitialized) return;

    _controller!.startImageStream((CameraImage image) async {
      // Prevents frame processing overlap (CRITICAL for performance)
      if (!_isDetecting && _modelManager.isModelLoaded) {
        _isDetecting = true;

        try {
          // ACTUAL ML INFERENCE CALL
          final results = await _modelManager.runInferenceOnCameraImage(image);

          // Interpretation based on labels.txt:
          // results[0] = Face (Real Face)
          // results[1] = Background (No face)
          // results[2] = Face (Fake)
          double realFaceScore = results[0];
          double backgroundScore = results[1];
          double fakeImageScore = results[2];

          String newStatus = 'Analyzing...';

          // Find the highest confidence class
          final maxScore = [
            realFaceScore,
            backgroundScore,
            fakeImageScore,
          ].reduce((a, b) => a > b ? a : b);
          final predictedClass = maxScore == realFaceScore
              ? 0
              : (maxScore == backgroundScore ? 1 : 2);

          if (predictedClass == 0 && realFaceScore > 0.95) {
            newStatus = 'Status: REAL FACE detected';
            // Stop the stream and potentially navigate/save attendance
            //_controller!.stopImageStream();

            // TODO: Add Firestore/Supabase logic to mark attendance here
          } else if (predictedClass == 2 && fakeImageScore > 0.8) {
            newStatus = 'Status: FAKE IMAGE detected!';
          } else if (predictedClass == 1) {
            newStatus = 'Status: No face detected (Background)';
          } else {
            newStatus =
                'Status: Analyzing... (Real: ${realFaceScore.toStringAsFixed(2)}, Fake: ${fakeImageScore.toStringAsFixed(2)})';
          }

          // Update UI with status and confidence
          if (mounted) {
            setState(() {
              _detectionStatus = newStatus;
              _realFaceConfidence = realFaceScore;
            });
          }
        } catch (e) {
          // Only log error, don't update UI to avoid spam
          if (mounted) {
            // Optionally show error status, but don't spam
            setState(() {
              _detectionStatus = 'Error: Inference failed';
            });
          }
        } finally {
          // Once processing is complete, reset the flag
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
      appBar: AppBar(title: const Text('Face Attendance')),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (_controller != null && _controller!.value.isInitialized) {
              return Stack(
                children: [
                  // 7. Display the live camera feed
                  Positioned.fill(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                      child: SizedBox(
                        // Use previewSize when available, fallback to screen size
                        width:
                            _controller!.value.previewSize?.width ??
                            MediaQuery.of(context).size.width,
                        height:
                            _controller!.value.previewSize?.height ??
                            MediaQuery.of(context).size.height,
                        child: CameraPreview(_controller!),
                      ),
                    ),
                  ),
                  // 8. Overlay the detection status at the bottom
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      color: Colors.black54,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _detectionStatus,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Confidence: ${_realFaceConfidence.toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            } else {
              return Center(
                child: Text(
                  'Failed to initialize camera. Status: $_detectionStatus',
                ),
              );
            }
          } else {
            // Display a loading spinner while waiting for initialization
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(_detectionStatus),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}
