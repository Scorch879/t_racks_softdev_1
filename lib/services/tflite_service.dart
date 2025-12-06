import 'dart:async';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:ui'; // Required for Rect

class ModelManager {
  Interpreter? _livenessInterpreter;
  Interpreter? _recognitionInterpreter;
  bool _areModelsLoaded = false;

  bool get areModelsLoaded => _areModelsLoaded;

  double compareVectors(List<double> v1, List<double> v2) {
    if (v1.length != v2.length) return 10.0;
    double sum = 0.0;
    for (int i = 0; i < v1.length; i++) {
      sum += math.pow(v1[i] - v2[i], 2);
    }
    return math.sqrt(sum);
  }

  Future<void> loadModels() async {
    try {
      final options = InterpreterOptions();

      // 1. Load Liveness Model (Keep existing one)
      _livenessInterpreter = await Interpreter.fromAsset(
        'assets/models/model.tflite',
        options: options,
      );

      // 2. Load FaceNet 512 (New Model)
      // Ensure 'facenet_512.tflite' is in your assets/models/ folder
      _recognitionInterpreter = await Interpreter.fromAsset(
        'assets/models/facenet_512.tflite',
        options: options,
      );

      _areModelsLoaded = true;
      print('✅ FaceNet-512 & Liveness Models Loaded.');
    } catch (e) {
      print('❌ Error loading models: $e');
    }
  }

  void close() {
    _livenessInterpreter?.close();
    _recognitionInterpreter?.close();
  }

  /// Returns True if face is Real, False if Spoof
  Future<bool> checkLiveness(CameraImage image) async {
    if (!_areModelsLoaded || _livenessInterpreter == null) return false;
    const int inputSize = 224; // Liveness model uses 224

    // Liveness checks typically don't need precise cropping, center is usually fine
    // or you can pass faceBox if you want to be precise, but keeping it simple here.
    final flatInput = await compute(
      _processImageForLiveness,
      _IsolateData(
        planes: image.planes.map((p) => p.bytes).toList(),
        width: image.width,
        height: image.height,
        yRowStride: image.planes[0].bytesPerRow,
        uvRowStride: image.planes.length > 1 ? image.planes[1].bytesPerRow : 0,
        uvPixelStride: image.planes.length > 1
            ? (image.planes[1].bytesPerPixel ?? 1)
            : 0,
        isYUV: image.planes.length >= 3,
        targetSize: inputSize,
        // Default center crop for liveness
        cropX: (image.width - math.min(image.width, image.height)) ~/ 2,
        cropY: (image.height - math.min(image.width, image.height)) ~/ 2,
        cropWidth: math.min(image.width, image.height),
        cropHeight: math.min(image.width, image.height),
      ),
    );

    final input = flatInput.reshape([1, inputSize, inputSize, 3]);
    var output = List.filled(3, 0.0).reshape([1, 3]);
    _livenessInterpreter!.run(input, output);

    List<double> scores = (output[0] as List)
        .map((e) => (e as num).toDouble())
        .toList();
    // Index 1 is usually "Real"
    print("Liveness Score: ${scores[1]} (Threshold: 0.4)");
    return scores.length > 1 && scores[1] > 0.40;
  }

  /// Generates the Normalized 512-D Identity Vector (FaceNet)
  /// Now accepts [faceBox] to crop the specific face area.
  Future<List<double>> generateFaceEmbedding(
    CameraImage image, {
    Rect? faceBox,
  }) async {
    if (!_areModelsLoaded || _recognitionInterpreter == null) return [];

    // FaceNet 512 uses 160x160 input
    const int inputSize = 160;

    // Calculate crop area
    int cropX, cropY, cropWidth, cropHeight;

    if (faceBox != null) {
      // Add a little padding (margin) around the face so we don't cut off chin/forehead
      double margin = 0.10; // 10% margin
      double width = faceBox.width * (1 + margin);
      double height = faceBox.height * (1 + margin);
      double centerX = faceBox.center.dx;
      double centerY = faceBox.center.dy;

      // Make it a square
      double side = math.max(width, height);

      cropX = (centerX - side / 2).toInt();
      cropY = (centerY - side / 2).toInt();
      cropWidth = side.toInt();
      cropHeight = side.toInt();
    } else {
      // Fallback to center crop
      int minSide = math.min(image.width, image.height);
      cropX = (image.width - minSide) ~/ 2;
      cropY = (image.height - minSide) ~/ 2;
      cropWidth = minSide;
      cropHeight = minSide;
    }

    // Safety checks to ensure we don't crop outside image bounds
    // (Note: CameraImage coordinates might need rotation handling if not already done,
    // but typically MLKit faceBox matches the preview stream orientation on Android NV21)
    cropX = cropX.clamp(0, image.width - 1);
    cropY = cropY.clamp(0, image.height - 1);
    if (cropX + cropWidth > image.width) cropWidth = image.width - cropX;
    if (cropY + cropHeight > image.height) cropHeight = image.height - cropY;

    // 1. Preprocess with Whitening (Standardization)
    final flatInput = await compute(
      _processImageForFaceNet,
      _IsolateData(
        planes: image.planes.map((p) => p.bytes).toList(),
        width: image.width,
        height: image.height,
        yRowStride: image.planes[0].bytesPerRow,
        uvRowStride: image.planes.length > 1 ? image.planes[1].bytesPerRow : 0,
        uvPixelStride: image.planes.length > 1
            ? (image.planes[1].bytesPerPixel ?? 1)
            : 0,
        isYUV: image.planes.length >= 3,
        targetSize: inputSize,
        cropX: cropX,
        cropY: cropY,
        cropWidth: cropWidth,
        cropHeight: cropHeight,
      ),
    );

    final input = flatInput.reshape([1, inputSize, inputSize, 3]);

    // 2. Output is now 512 float values
    final outputTensor = _recognitionInterpreter!.getOutputTensors().first;
    int vectorLen = outputTensor.shape.last; // Should be 512
    var output = List.filled(vectorLen, 0.0).reshape([1, vectorLen]);

    _recognitionInterpreter!.run(input, output);

    List<double> rawVector = (output[0] as List)
        .map((e) => (e as num).toDouble())
        .toList();

    // 3. L2 Normalize
    return _l2Normalize(rawVector);
  }

  List<double> _l2Normalize(List<double> vector) {
    double sum = 0;
    for (var x in vector) sum += x * x;
    double norm = math.sqrt(sum);
    if (norm == 0) return vector;
    return vector.map((x) => x / norm).toList();
  }

  // ===========================================================================
  //  ISOLATE FUNCTIONS
  // ===========================================================================

  static Float32List _processImageForLiveness(_IsolateData data) {
    // Basic 0-1 normalization for liveness
    return _extractPixels(data, (pixel) => pixel / 255.0);
  }

  // WHITENING for FaceNet: (pixel - mean) / std_dev
  static Float32List _processImageForFaceNet(_IsolateData data) {
    // 1. Extract Raw Pixels
    Float32List rawPixels = _extractPixels(data, (pixel) => pixel.toDouble());

    // 2. Calculate Mean and Std Dev
    double sum = 0;
    double sqSum = 0;
    for (double p in rawPixels) {
      sum += p;
      sqSum += p * p;
    }
    double mean = sum / rawPixels.length;
    double variance = (sqSum / rawPixels.length) - (mean * mean);
    double std = math.sqrt(variance);

    // Avoid division by zero
    std = math.max(std, 1.0 / math.sqrt(rawPixels.length));

    // 3. Standardize
    for (int i = 0; i < rawPixels.length; i++) {
      rawPixels[i] = (rawPixels[i] - mean) / std;
    }

    return rawPixels;
  }

  static Float32List _extractPixels(
    _IsolateData data,
    double Function(int) transform,
  ) {
    final int targetSize = data.targetSize;
    final int cropX = data.cropX;
    final int cropY = data.cropY;
    final int cropW = data.cropWidth;
    final int cropH = data.cropHeight;

    final floatInput = Float32List(1 * targetSize * targetSize * 3);
    int pixelIndex = 0;

    if (data.isYUV) {
      final yBytes = data.planes[0];
      final uBytes = data.planes[1];
      final vBytes = data.planes[2];

      for (int y = 0; y < targetSize; y++) {
        // Map target pixel to source crop pixel
        final int srcY = cropY + (y * cropH ~/ targetSize);

        for (int x = 0; x < targetSize; x++) {
          final int srcX = cropX + (x * cropW ~/ targetSize);

          if (srcX < 0 ||
              srcX >= data.width ||
              srcY < 0 ||
              srcY >= data.height) {
            // Padding (Black) if out of bounds
            floatInput[pixelIndex++] = transform(0);
            floatInput[pixelIndex++] = transform(0);
            floatInput[pixelIndex++] = transform(0);
            continue;
          }

          final int uvX = srcX ~/ 2;
          final int uvY = srcY ~/ 2;
          final int indexY = srcY * data.yRowStride + srcX;
          final int indexUV =
              uvY * data.uvRowStride + (uvX * data.uvPixelStride);

          if (indexY >= yBytes.length || indexUV >= uBytes.length) {
            pixelIndex += 3;
            continue;
          }

          final int yVal = yBytes[indexY];
          final int uVal = uBytes[indexUV];
          final int vVal = vBytes[indexUV];

          int r = (yVal + 1.402 * (vVal - 128)).toInt().clamp(0, 255);
          int g = (yVal - 0.344136 * (uVal - 128) - 0.714136 * (vVal - 128))
              .toInt()
              .clamp(0, 255);
          int b = (yVal + 1.772 * (uVal - 128)).toInt().clamp(0, 255);

          floatInput[pixelIndex++] = transform(r);
          floatInput[pixelIndex++] = transform(g);
          floatInput[pixelIndex++] = transform(b);
        }
      }
    } else {
      // BGRA (iOS)
      final bytes = data.planes[0];
      for (int y = 0; y < targetSize; y++) {
        final int srcY = cropY + (y * cropH ~/ targetSize);
        for (int x = 0; x < targetSize; x++) {
          final int srcX = cropX + (x * cropW ~/ targetSize);

          if (srcX < 0 ||
              srcX >= data.width ||
              srcY < 0 ||
              srcY >= data.height) {
            pixelIndex += 3;
            continue;
          }

          final int index = (srcY * data.yRowStride) + (srcX * 4);
          if (index + 2 >= bytes.length) {
            pixelIndex += 3;
            continue;
          }

          final b = bytes[index];
          final g = bytes[index + 1];
          final r = bytes[index + 2];

          floatInput[pixelIndex++] = transform(r);
          floatInput[pixelIndex++] = transform(g);
          floatInput[pixelIndex++] = transform(b);
        }
      }
    }
    return floatInput;
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
  final int targetSize;
  final int cropX;
  final int cropY;
  final int cropWidth;
  final int cropHeight;

  _IsolateData({
    required this.planes,
    required this.width,
    required this.height,
    required this.yRowStride,
    required this.uvRowStride,
    required this.uvPixelStride,
    required this.isYUV,
    required this.targetSize,
    required this.cropX,
    required this.cropY,
    required this.cropWidth,
    required this.cropHeight,
  });
}
