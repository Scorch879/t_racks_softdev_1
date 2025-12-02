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

enum ChallengeType { smile, blink, turnLeft, turnRight }

class StudentCameraContent extends StatefulWidget {
  final List<CameraDescription> cameras;

  const StudentCameraContent({super.key, required this.cameras});

  @override
  State<StudentCameraContent> createState() => _StudentCameraContentState();
}

class _StudentCameraContentState extends State<StudentCameraContent> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  bool _isProcessing = false;
  late FaceDetector _faceDetector;
  final tflite.ModelManager _tfliteManager = tflite.ModelManager();

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

    _tfliteManager.loadModel().then((_) {
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
    final random = Random();
    List<ChallengeType> allTypes = ChallengeType.values.toList();
    _challenges = [];
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
    });
  }

  void _updateStatusMessage() {
    if (_isVerified || _hasFailed) return;

    if (_currentChallengeIndex >= _challenges.length) {
      _statusMessage = "Verifying Texture...";
      _statusColor = const Color(0xFF93C0D3);
      return;
    }

    ChallengeType current = _challenges[_currentChallengeIndex];
    switch (current) {
      case ChallengeType.smile:
        _statusMessage = "Please SMILE 😀";
        break;
      case ChallengeType.blink:
        _statusMessage = "Please BLINK 😉";
        break;
      case ChallengeType.turnLeft:
        _statusMessage = "Turn Head LEFT ⬅️";
        break;
      case ChallengeType.turnRight:
        _statusMessage = "Turn Head RIGHT ➡️";
        break;
    }
    _statusColor = Colors.white;
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
    if (faces.isEmpty) return;

    final Face face = faces.first;
    _checkChallenge(face);
  }

  void _checkChallenge(Face face) {
    if (_currentChallengeIndex >= _challenges.length) {
      _finalizeVerification();
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
      final results = await _tfliteManager.runInferenceOnCameraImage(image);
      if (results.isEmpty) return;

      double fakeScore = results.length > 2 ? results[2] : 0.0;

      if (fakeScore > 0.85) {
        _consecutiveFakeFrames++;
      } else {
        _consecutiveFakeFrames = 0;
      }

      if (_consecutiveFakeFrames >= 3) {
        if (mounted) {
          setState(() {
            _hasFailed = true;
            _statusMessage = "⚠️ SPOOF DETECTED";
            _statusColor = const Color(0xFFDA6A6A);
          });
        }
      }
    } catch (e) {
      print("TFLite Error: $e");
    }
  }

  void _finalizeVerification() {
    if (!_hasFailed && !_isVerified) {
      if (mounted) {
        setState(() {
          _isVerified = true;
          _statusMessage = "✅ VERIFIED";
          _statusColor = const Color(0xFF4DBD88);
        });

        // 2-Second Delay before closing
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.of(context).pop();
          }
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
    _tfliteManager.close();
    _controller?.stopImageStream();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_controller != null && _controller!.value.isInitialized)
            LayoutBuilder(
              builder: (context, constraints) {
                final size = constraints.biggest;
                var scale = size.aspectRatio * _controller!.value.aspectRatio;
                if (scale < 1) scale = 1 / scale;
                return Transform.scale(
                  scale: scale,
                  child: Center(child: CameraPreview(_controller!)),
                );
              },
            )
          else
            const Center(child: CircularProgressIndicator()),

          if (_hasFailed || _isVerified)
            Container(color: Colors.black.withOpacity(0.7)),

          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withOpacity(0.5),
                ],
                stops: const [0.0, 0.2, 0.8, 1.0],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: Color(0xFF93C0D3),
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Text(
                            'You have not taken your attendance for Physics 138',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Center(
            child: SizedBox(
              width: 300,
              height: 450,
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    child: _CornerBracket(isTop: true, isLeft: true),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: _CornerBracket(isTop: true, isLeft: false),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: _CornerBracket(isTop: false, isLeft: true),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: _CornerBracket(isTop: false, isLeft: false),
                  ),

                  const Positioned(
                    top: 20,
                    right: 20,
                    child: Column(
                      children: [
                        Icon(Icons.circle, color: Colors.red, size: 12),
                        SizedBox(height: 4),
                        RotatedBox(
                          quarterTurns: 1,
                          child: Text(
                            'REC',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 10,
                              letterSpacing: 2,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Positioned(
                    top: 100,
                    left: 10,
                    child: RotatedBox(
                      quarterTurns: 1,
                      child: Text(
                        '1920 x 1080',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 10,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),
                  const Positioned(
                    top: 200,
                    left: 10,
                    child: RotatedBox(
                      quarterTurns: 1,
                      child: Text(
                        'FULL-HD 60FPS',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 10,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),
                  const Positioned(
                    top: 200,
                    right: 10,
                    child: RotatedBox(
                      quarterTurns: 1,
                      child: Text(
                        '00:00:00:00',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 10,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),

                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white30, width: 1),
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (!_hasFailed && !_isVerified)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _statusMessage,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _statusColor,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  if (_hasFailed)
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: Color(0xFFDA6A6A),
                            size: 60,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Verification Failed",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Spoof detected or face not clear.\nEnsure good lighting.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _startLivenessSession,
                            icon: const Icon(Icons.refresh),
                            label: const Text("TRY AGAIN"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (_isVerified)
                    const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF4DBD88),
                            size: 80,
                          ),
                          SizedBox(height: 16),
                          Text(
                            "Verified!",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _CircleButton(
                  icon: Icons.cameraswitch_outlined,
                  color: const Color(0xFF173C45),
                  iconColor: Colors.white,
                  onTap: () {},
                ),
                const SizedBox(width: 24),
                _CircleButton(
                  icon: Icons.close,
                  color: const Color(0xFFDA6A6A),
                  iconColor: Colors.white,
                  size: 64,
                  onTap: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 24),
                _CircleButton(
                  icon: Icons.mic_none_rounded,
                  color: const Color(0xFF167C94),
                  iconColor: Colors.white,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CornerBracket extends StatelessWidget {
  final bool isTop;
  final bool isLeft;

  const _CornerBracket({required this.isTop, required this.isLeft});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        border: Border(
          top: isTop
              ? const BorderSide(color: Colors.black87, width: 2)
              : BorderSide.none,
          bottom: !isTop
              ? const BorderSide(color: Colors.black87, width: 2)
              : BorderSide.none,
          left: isLeft
              ? const BorderSide(color: Colors.black87, width: 2)
              : BorderSide.none,
          right: !isLeft
              ? const BorderSide(color: Colors.black87, width: 2)
              : BorderSide.none,
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color iconColor;
  final double size;
  final VoidCallback onTap;

  const _CircleButton({
    required this.icon,
    required this.color,
    required this.iconColor,
    this.size = 48,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: iconColor, size: size * 0.5),
      ),
    );
  }
}
