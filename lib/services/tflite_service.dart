import 'dart:async';
import 'dart:typed_data';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class ModelManager {
  Interpreter? _recognitionInterpreter;
  bool _areModelsLoaded = false;

  bool get areModelsLoaded => _areModelsLoaded;

  Future<void> loadModels() async {
    try {
      if (_areModelsLoaded) return;

      final options = InterpreterOptions();

      // Load FaceNet 512
      _recognitionInterpreter = await Interpreter.fromAsset(
        'assets/models/facenet_512.tflite',
        options: options,
      );

      _areModelsLoaded = true;
      print('✅ FaceNet-512 Loaded Successfully.');
    } catch (e) {
      print('❌ Error loading models: $e');
      _areModelsLoaded = false;
    }
  }

  void close() {
    _recognitionInterpreter?.close();
  }

  /// Compares two face vectors (Euclidean Distance).
  double compareVectors(List<double> v1, List<double> v2) {
    if (v1.length != v2.length) return 10.0;
    double sum = 0.0;
    for (int i = 0; i < v1.length; i++) {
      sum += math.pow(v1[i] - v2[i], 2);
    }
    return math.sqrt(sum);
  }

  Future<bool> checkLiveness(CameraImage image) async {
    return true;
  }

  Future<List<double>> generateFaceEmbedding(
    CameraImage image, {
    Rect? faceBox,
  }) async {
    // 1. Auto-Retry Loading
    if (!_areModelsLoaded || _recognitionInterpreter == null) {
      await loadModels();
      if (!_areModelsLoaded || _recognitionInterpreter == null) {
        return [];
      }
    }

    try {
      const int targetInputSize = 160;

      // Extract Rect values for Isolate
      final Map<String, int>? boxData = faceBox != null
          ? {
              'left': faceBox.left.toInt(),
              'top': faceBox.top.toInt(),
              'width': faceBox.width.toInt(),
              'height': faceBox.height.toInt(),
            }
          : null;

      // 2. Process Image in Background
      final flatInput = await compute(
        _processImageForFaceNet,
        _IsolateData(
          planes: image.planes.map((p) => p.bytes).toList(),
          width: image.width,
          height: image.height,
          yRowStride: image.planes[0].bytesPerRow,
          uvRowStride: image.planes.length > 1
              ? image.planes[1].bytesPerRow
              : 0,
          uvPixelStride: image.planes.length > 1
              ? (image.planes[1].bytesPerPixel ?? 1)
              : 0,
          isYUV: image.planes.length >= 3,
          faceBoxData: boxData,
          targetSize: targetInputSize,
        ),
      );

      // 3. Run Inference
      final input = flatInput.reshape([1, targetInputSize, targetInputSize, 3]);
      final outputTensor = _recognitionInterpreter!.getOutputTensors().first;
      int vectorLen = outputTensor.shape.last;
      var output = List.filled(vectorLen, 0.0).reshape([1, vectorLen]);

      _recognitionInterpreter!.run(input, output);

      List<double> rawVector = (output[0] as List)
          .map((e) => (e as num).toDouble())
          .toList();

      return _l2Normalize(rawVector);
    } catch (e) {
      print("❌ Error generating embedding: $e");
      return [];
    }
  }

  List<double> _l2Normalize(List<double> vector) {
    double sum = 0;
    for (var x in vector) sum += x * x;
    double norm = math.sqrt(sum);
    if (norm == 0) return vector;
    return vector.map((x) => x / norm).toList();
  }

  /// Runs in Background Isolate
  static Float32List _processImageForFaceNet(_IsolateData data) {
    // A. Convert YUV/BGRA to RGB Image
    img.Image? originalImage;

    try {
      if (data.isYUV) {
        originalImage = _convertYUV420ToImage(data);
      } else {
        originalImage = img.Image.fromBytes(
          width: data.width,
          height: data.height,
          bytes: data.planes[0].buffer,
          order: img.ChannelOrder.bgra,
        );
      }
    } catch (e) {
      // Return empty list if conversion crashes
      return Float32List(data.targetSize * data.targetSize * 3);
    }

    // B. Crop Face
    img.Image faceImage;
    if (data.faceBoxData != null) {
      int left = data.faceBoxData!['left']!;
      int top = data.faceBoxData!['top']!;
      int width = data.faceBoxData!['width']!;
      int height = data.faceBoxData!['height']!;

      left = left.clamp(0, originalImage.width - 1);
      top = top.clamp(0, originalImage.height - 1);
      if (left + width > originalImage.width)
        width = originalImage.width - left;
      if (top + height > originalImage.height)
        height = originalImage.height - top;

      faceImage = img.copyCrop(
        originalImage,
        x: left,
        y: top,
        width: width,
        height: height,
      );
    } else {
      int size = math.min(originalImage.width, originalImage.height);
      faceImage = img.copyCrop(
        originalImage,
        x: (originalImage.width - size) ~/ 2,
        y: (originalImage.height - size) ~/ 2,
        width: size,
        height: size,
      );
    }

    // C. Resize
    img.Image resizedImage = img.copyResize(
      faceImage,
      width: data.targetSize,
      height: data.targetSize,
      interpolation: img.Interpolation.linear,
    );

    // D. Standardize
    final Float32List floatInput = Float32List(
      data.targetSize * data.targetSize * 3,
    );
    int pixelIndex = 0;

    double sum = 0;
    double sqSum = 0;
    // Calculate mean/std loop...
    for (int y = 0; y < data.targetSize; y++) {
      for (int x = 0; x < data.targetSize; x++) {
        final pixel = resizedImage.getPixel(x, y);
        sum += pixel.r;
        sum += pixel.g;
        sum += pixel.b;
        sqSum += pixel.r * pixel.r;
        sqSum += pixel.g * pixel.g;
        sqSum += pixel.b * pixel.b;
      }
    }

    int numPixels = data.targetSize * data.targetSize * 3;
    double mean = sum / numPixels;
    double variance = (sqSum / numPixels) - (mean * mean);
    double std = math.sqrt(variance);
    std = math.max(std, 1.0 / math.sqrt(numPixels));

    // Normalize loop
    for (int y = 0; y < data.targetSize; y++) {
      for (int x = 0; x < data.targetSize; x++) {
        final pixel = resizedImage.getPixel(x, y);
        floatInput[pixelIndex++] = (pixel.r - mean) / std;
        floatInput[pixelIndex++] = (pixel.g - mean) / std;
        floatInput[pixelIndex++] = (pixel.b - mean) / std;
      }
    }

    return floatInput;
  }

  // FIXED: Crash-proof YUV Converter
  static img.Image _convertYUV420ToImage(_IsolateData data) {
    final width = data.width;
    final height = data.height;
    final uvRowStride = data.uvRowStride;
    final uvPixelStride = data.uvPixelStride;
    final yRowStride = data.yRowStride;

    final img.Image image = img.Image(width: width, height: height);

    final yBuffer = data.planes[0];
    final uBuffer = data.planes[1];
    final vBuffer = data.planes[2];

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int yIndex = y * yRowStride + x;
        final int uvIndex = (y ~/ 2) * uvRowStride + (x ~/ 2) * uvPixelStride;

        // SAFEGUARD: If index is out of bounds, skip pixel (prevents crash)
        if (yIndex >= yBuffer.length ||
            uvIndex >= uBuffer.length ||
            uvIndex >= vBuffer.length) {
          continue;
        }

        final int yValue = yBuffer[yIndex];
        final int uValue = uBuffer[uvIndex];
        final int vValue = vBuffer[uvIndex];

        int r = (yValue + 1.370705 * (vValue - 128)).toInt();
        int g = (yValue - 0.337633 * (uValue - 128) - 0.698001 * (vValue - 128))
            .toInt();
        int b = (yValue + 1.732446 * (uValue - 128)).toInt();

        image.setPixelRgb(
          x,
          y,
          r.clamp(0, 255),
          g.clamp(0, 255),
          b.clamp(0, 255),
        );
      }
    }
    return image;
  }
}

class _IsolateData {
  final List<Uint8List> planes;
  final int width;
  final int height;
  final int yRowStride;
  final int uvRowStride;
  final int uvPixelStride;
  final bool isYUV;
  final Map<String, int>? faceBoxData;
  final int targetSize;

  _IsolateData({
    required this.planes,
    required this.width,
    required this.height,
    required this.yRowStride,
    required this.uvRowStride,
    required this.uvPixelStride,
    required this.isYUV,
    required this.faceBoxData,
    required this.targetSize,
  });
}
