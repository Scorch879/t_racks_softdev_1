import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraDetectionScreen extends StatefulWidget {
  const CameraDetectionScreen({super.key});

  @override
  State<CameraDetectionScreen> createState() => _CameraDetectionScreenState();
}

class _CameraDetectionScreenState extends State<CameraDetectionScreen> {
  CameraController? _cameraController;
  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isModelLoaded = false;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  String _currentPrediction = 'Initializing...';
  double _currentConfidence = 0.0;
  int _frameCount = 0;
  double _fps = 0.0;
  DateTime? _lastFpsUpdate;
  bool _showDebugWidget = true;
  bool _performanceMode = false; // Performance mode: faster, less logging
  DateTime? _lastProcessTime;
  static const _minProcessIntervalDebug = Duration(milliseconds: 100); // Debug: 10 FPS
  static const _minProcessIntervalPerformance = Duration(milliseconds: 50); // Performance: 20 FPS

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _loadModel();
  }

  Future<void> _initializeCamera() async {
    // Request camera permission
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Camera permission is required'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      // Get available cameras
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No cameras available'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Use the first available camera (usually back camera)
      final camera = cameras.first;

      _cameraController = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.yuv420
            : ImageFormatGroup.bgra8888,
      );

      await _cameraController!.initialize();

      // Start image stream for continuous processing
      _cameraController!.startImageStream(_processCameraImage);

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error initializing camera: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadModel() async {
    try {
      // Load labels
      final labelData = await rootBundle.loadString('assets/models/labels.txt');
      _labels = labelData.split('\n').where((line) => line.isNotEmpty).toList();

      // Load TensorFlow Lite model
      final interpreterOptions = InterpreterOptions();
      _interpreter = await Interpreter.fromAsset(
        'assets/models/model.tflite',
        options: interpreterOptions,
      );

      // Get input and output shapes
      final inputShape = _interpreter!.getInputTensor(0).shape;
      final outputShape = _interpreter!.getOutputTensor(0).shape;

      if (mounted) {
        setState(() {
          _isModelLoaded = true;
          _currentPrediction = 'Model loaded. Ready for detection.';
        });
      }

      debugPrint('Model loaded successfully');
      debugPrint('Input shape: $inputShape');
      debugPrint('Output shape: $outputShape');
      debugPrint('Labels: $_labels');
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentPrediction = 'Error loading model: $e';
        });
      }
      debugPrint('Error loading model: $e');
    }
  }

  Future<void> _processCameraImage(CameraImage cameraImage) async {
    if (!_isModelLoaded || _isProcessing || _interpreter == null) {
      return;
    }

    // Throttle processing to avoid buffer overflow
    final now = DateTime.now();
    if (_lastProcessTime != null) {
      final timeSinceLastProcess = now.difference(_lastProcessTime!);
      final minInterval = _performanceMode 
          ? _minProcessIntervalPerformance 
          : _minProcessIntervalDebug;
      if (timeSinceLastProcess < minInterval) {
        return; // Skip this frame
      }
    }
    _lastProcessTime = now;

    _isProcessing = true;
    _frameCount++;

    // Update FPS every second
    if (_lastFpsUpdate == null) {
      _lastFpsUpdate = now;
    } else {
      final diff = now.difference(_lastFpsUpdate!);
      if (diff.inMilliseconds >= 1000) {
        setState(() {
          _fps = _frameCount / diff.inSeconds;
          _frameCount = 0;
          _lastFpsUpdate = now;
        });
      }
    }

    try {
      // Convert camera image to the format expected by the model
      final inputImage = _preprocessImage(cameraImage);
      
      if (inputImage == null || inputImage.isEmpty) {
        _isProcessing = false;
        return;
      }

      // Get input and output tensor information
      final inputTensor = _interpreter!.getInputTensor(0);
      final outputTensor = _interpreter!.getOutputTensor(0);
      final inputShape = inputTensor.shape;
      final outputShape = outputTensor.shape;
      
      if (!_performanceMode) {
        debugPrint('Input shape: $inputShape, Output shape: $outputShape');
        debugPrint('Input image size: ${inputImage.length}');
      }

      // Calculate expected input size based on model shape
      // Handle different input shapes: [150528], [1, 224, 224, 3], [224, 224, 3], etc.
      final inputSize = inputShape.reduce((a, b) => a * b);
      final expectedSize = inputSize; // Total number of elements needed
      
      if (!_performanceMode) {
        debugPrint('Expected input size: $expectedSize, Got: ${inputImage.length}');
      }

      if (inputImage.length < expectedSize) {
        if (!_performanceMode) {
          debugPrint('Input image size mismatch: got ${inputImage.length}, expected $expectedSize');
        }
        _isProcessing = false;
        return;
      }

      // Create typed input array (Float32List for better performance)
      final input = Float32List(inputSize);

      // Normalize and copy image data to input buffer
      // TensorFlow Lite expects values in range [0, 1] for float models
      for (int i = 0; i < expectedSize && i < inputImage.length; i++) {
        input[i] = (inputImage[i] / 255.0).toDouble();
      }

      // Create typed output array
      final outputSize = outputShape.reduce((a, b) => a * b);
      final output = Float32List(outputSize);

      // Run inference
      _interpreter!.run(input, output);

      // Process output - handle different output shapes
      List<double> predictions;
      if (outputShape.length == 1) {
        // Shape: [num_classes]
        predictions = output.toList();
      } else if (outputShape.length == 2) {
        // Shape: [batch, num_classes] or [1, num_classes]
        if (outputShape[0] == 1) {
          // Extract first batch: [1, 3] -> take first 3 elements
          predictions = output.sublist(0, outputShape[1]).toList();
        } else {
          predictions = output.toList();
        }
      } else {
        predictions = output.toList();
      }

      if (predictions.isEmpty) {
        if (!_performanceMode) {
          debugPrint('Empty predictions from model');
        }
        _isProcessing = false;
        return;
      }

      if (!_performanceMode) {
        debugPrint('Raw predictions: $predictions');
      }

      // Find the class with highest confidence
      double maxConfidence = predictions[0];
      int maxIndex = 0;
      for (int i = 1; i < predictions.length; i++) {
        if (predictions[i] > maxConfidence) {
          maxConfidence = predictions[i];
          maxIndex = i;
        }
      }

      // If predictions are logits (not probabilities), apply softmax
      // Check if values are negative or sum is not ~1.0
      final sum = predictions.fold(0.0, (a, b) => a + b);
      if (sum < 0.9 || sum > 1.1 || predictions.any((p) => p < 0)) {
        // Likely logits, apply softmax
        final expValues = predictions.map((p) => p > 20 ? 20.0 : (p < -20 ? -20.0 : p)).map((p) => math.exp(p)).toList();
        final expSum = expValues.fold(0.0, (a, b) => a + b);
        predictions = expValues.map((e) => e / expSum).toList();
        
        // Recalculate max after softmax
        maxConfidence = predictions[0];
        maxIndex = 0;
        for (int i = 1; i < predictions.length; i++) {
          if (predictions[i] > maxConfidence) {
            maxConfidence = predictions[i];
            maxIndex = i;
          }
        }
        if (!_performanceMode) {
          debugPrint('Applied softmax. Probabilities: $predictions');
        }
      }

      // Update UI with prediction
      if (mounted) {
        setState(() {
          if (maxIndex < _labels.length) {
            _currentPrediction = _labels[maxIndex];
          } else {
            _currentPrediction = 'Class $maxIndex';
          }
          _currentConfidence = maxConfidence;
        });
      }

      if (!_performanceMode) {
        debugPrint('Prediction: ${_currentPrediction}, Confidence: ${(_currentConfidence * 100).toStringAsFixed(1)}%');
      }
    } catch (e, stackTrace) {
      debugPrint('Error processing image: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _currentPrediction = 'Error: ${e.toString()}';
        });
      }
    } finally {
      _isProcessing = false;
    }
  }

  List<double>? _preprocessImage(CameraImage cameraImage) {
    try {
      img.Image? image;
      
      if (Platform.isAndroid) {
        // android uses YUV420 format
        image = _convertYUV420ToImage(cameraImage);
      } else {
        // ios uses BGRA8888 format
        image = _convertBGRA8888ToImage(cameraImage);
      }

      if (image == null) return null;

      // resize image to model input size
      final resized = img.copyResize(
        image,
        width: 224,
        height: 224,
        interpolation: img.Interpolation.linear,
      );

      final rgbList = <double>[];
      for (int y = 0; y < resized.height; y++) {
        for (int x = 0; x < resized.width; x++) {
          final pixel = resized.getPixel(x, y);
          rgbList.add(pixel.r.toDouble());
          rgbList.add(pixel.g.toDouble());
          rgbList.add(pixel.b.toDouble());
        }
      }

      return rgbList;
    } catch (e) {
      debugPrint('Error preprocessing image: $e');
      return null;
    }
  }

  img.Image _convertYUV420ToImage(CameraImage cameraImage) {
    final width = cameraImage.width;
    final height = cameraImage.height;
    final yBuffer = cameraImage.planes[0].bytes;
    final uBuffer = cameraImage.planes[1].bytes;
    final vBuffer = cameraImage.planes[2].bytes;

    final yuvImage = img.Image(width: width, height: height);
    final yRowStride = cameraImage.planes[0].bytesPerRow;
    final yPixelStride = cameraImage.planes[0].bytesPerPixel ?? 1;
    final uvRowStride = cameraImage.planes[1].bytesPerRow;
    final uvPixelStride = cameraImage.planes[1].bytesPerPixel ?? 1;

    for (int y = 0; y < height; y++) {
      final yIndex = y * yRowStride;
      final uvIndex = (y ~/ 2) * uvRowStride;

      for (int x = 0; x < width; x++) {
        final yIdx = yIndex + x * yPixelStride;
        final uvIdx = uvIndex + (x ~/ 2) * uvPixelStride;

        // Bounds checking
        if (yIdx >= yBuffer.length || uvIdx >= uBuffer.length || uvIdx >= vBuffer.length) {
          continue;
        }

        final yVal = yBuffer[yIdx];
        final uVal = uBuffer[uvIdx];
        final vVal = vBuffer[uvIdx];

        // Convert YUV to RGB
        final r = (yVal + 1.402 * (vVal - 128)).clamp(0, 255).toInt();
        final g = (yVal - 0.344 * (uVal - 128) - 0.714 * (vVal - 128))
            .clamp(0, 255)
            .toInt();
        final b = (yVal + 1.772 * (uVal - 128)).clamp(0, 255).toInt();

        yuvImage.setPixel(x, y, img.ColorRgb8(r, g, b));
      }
    }

    return yuvImage;
  }

  img.Image _convertBGRA8888ToImage(CameraImage cameraImage) {
    final width = cameraImage.width;
    final height = cameraImage.height;
    final buffer = cameraImage.planes[0].bytes;

    final image = img.Image(width: width, height: height);
    final rowStride = cameraImage.planes[0].bytesPerRow;
    final pixelStride = cameraImage.planes[0].bytesPerPixel ?? 4;

    for (int y = 0; y < height; y++) {
      final rowIndex = y * rowStride;
      for (int x = 0; x < width; x++) {
        final pixelIndex = rowIndex + x * pixelStride;
        
        if (pixelIndex + 2 >= buffer.length) {
          continue;
        }
        
        final b = buffer[pixelIndex];
        final g = buffer[pixelIndex + 1];
        final r = buffer[pixelIndex + 2];

        image.setPixel(x, y, img.ColorRgb8(r, g, b));
      }
    }

    return image;
  }

  @override
  void dispose() {
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    _interpreter?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_isCameraInitialized && _cameraController != null)
            Positioned.fill(
              child: CameraPreview(_cameraController!),
            )
          else
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),

          if (_showDebugWidget)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: _DebugWidget(
                prediction: _currentPrediction,
                confidence: _currentConfidence,
                fps: _fps,
                isModelLoaded: _isModelLoaded,
                isCameraInitialized: _isCameraInitialized,
                performanceMode: _performanceMode,
                onToggle: () {
                  setState(() {
                    _showDebugWidget = !_showDebugWidget;
                  });
                },
              ),
            ),

          // Close button
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 32),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),

          // Performance mode toggle
          Positioned(
            bottom: 80,
            right: 16,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: _performanceMode 
                  ? Colors.green.withOpacity(0.8)
                  : Colors.orange.withOpacity(0.8),
              onPressed: () {
                setState(() {
                  _performanceMode = !_performanceMode;
                });
              },
              child: Icon(
                _performanceMode ? Icons.speed : Icons.bug_report,
                color: Colors.white,
              ),
              tooltip: _performanceMode 
                  ? 'Performance Mode: ON (Tap for Debug Mode)'
                  : 'Debug Mode: ON (Tap for Performance Mode)',
            ),
          ),
        ],
      ),
    );
  }
}

// Floating debug widget for debugging
class _DebugWidget extends StatelessWidget {
  final String prediction;
  final double confidence;
  final double fps;
  final bool isModelLoaded;
  final bool isCameraInitialized;
  final bool performanceMode;
  final VoidCallback onToggle;

  const _DebugWidget({
    required this.prediction,
    required this.confidence,
    required this.fps,
    required this.isModelLoaded,
    required this.isCameraInitialized,
    required this.performanceMode,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Debug Info',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 20),
                onPressed: onToggle,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _DebugRow(
            label: 'Mode',
            value: performanceMode ? 'Performance' : 'Debug',
            valueColor: performanceMode ? Colors.green : Colors.orange,
          ),
          const SizedBox(height: 8),
          _DebugRow(
            label: 'Status',
            value: isModelLoaded && isCameraInitialized
                ? 'Running'
                : 'Initializing',
            valueColor: isModelLoaded && isCameraInitialized
                ? Colors.green
                : Colors.orange,
          ),
          const SizedBox(height: 8),
          _DebugRow(
            label: 'Prediction',
            value: prediction,
            valueColor: Colors.cyan,
          ),
          const SizedBox(height: 8),
          _DebugRow(
            label: 'Confidence',
            value: '${(confidence * 100).toStringAsFixed(1)}%',
            valueColor: confidence > 0.7
                ? Colors.green
                : confidence > 0.4
                    ? Colors.orange
                    : Colors.red,
          ),
          const SizedBox(height: 8),
          _DebugRow(
            label: 'FPS',
            value: fps.toStringAsFixed(1),
            valueColor: Colors.yellow,
          ),
          const SizedBox(height: 8),
          _DebugRow(
            label: 'Model',
            value: isModelLoaded ? 'Loaded' : 'Loading...',
            valueColor: isModelLoaded ? Colors.green : Colors.orange,
          ),
          const SizedBox(height: 8),
          _DebugRow(
            label: 'Camera',
            value: isCameraInitialized ? 'Active' : 'Initializing...',
            valueColor: isCameraInitialized ? Colors.green : Colors.orange,
          ),
        ],
      ),
    );
  }
}

class _DebugRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _DebugRow({
    required this.label,
    required this.value,
    this.valueColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$label:',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

