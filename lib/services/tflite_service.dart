import 'dart:async';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class ModelManager {
  Interpreter? _livenessInterpreter;
  Interpreter? _recognitionInterpreter;
  bool _areModelsLoaded = false;

  bool get areModelsLoaded => _areModelsLoaded;

  Future<void> loadModels() async {
    try {
      final options = InterpreterOptions();

      // 1. Load Liveness Model
      _livenessInterpreter = await Interpreter.fromAsset(
        'assets/models/model.tflite',
        options: options,
      );

      // 2. Load Recognition Model
      _recognitionInterpreter = await Interpreter.fromAsset(
        'assets/models/mobilefacenet.tflite',
        options: options,
      );

      _areModelsLoaded = true;
      print('✅ Both Models Loaded Successfully.');
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
    const int inputSize = 224;

    final flatInput = await compute(
      _processImageInIsolate,
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
      ),
    );

    final input = flatInput.reshape([1, inputSize, inputSize, 3]);
    var output = List.filled(3, 0.0).reshape([1, 3]);
    _livenessInterpreter!.run(input, output);

    List<double> scores = (output[0] as List)
        .map((e) => (e as num).toDouble())
        .toList();
    // Index 1 is usually "Real" for typical Anti-Spoofing models
    return scores.length > 1 && scores[1] > 0.75;
  }

  /// Generates the Normalized 192-D Identity Vector
  Future<List<double>> generateFaceEmbedding(CameraImage image) async {
    if (!_areModelsLoaded || _recognitionInterpreter == null) return [];
    const int inputSize = 112;

    final flatInput = await compute(
      _processImageInIsolate,
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
        normalizeMinusOneToOne: true,
      ),
    );

    final input = flatInput.reshape([1, inputSize, inputSize, 3]);

    // Get output shape dynamically
    final outputTensor = _recognitionInterpreter!.getOutputTensors().first;
    int vectorLen = outputTensor.shape.last;
    var output = List.filled(vectorLen, 0.0).reshape([1, vectorLen]);

    _recognitionInterpreter!.run(input, output);

    List<double> rawVector = (output[0] as List)
        .map((e) => (e as num).toDouble())
        .toList();

    // --- CRITICAL FIX: L2 Normalization ---
    // This scales the vector so comparing distance works correctly
    return _l2Normalize(rawVector);
  }

  /// Helper: L2 Normalization
  List<double> _l2Normalize(List<double> vector) {
    double sum = 0;
    for (var x in vector) {
      sum += x * x;
    }
    double norm = math.sqrt(sum);
    if (norm == 0) return vector;
    return vector.map((x) => x / norm).toList();
  }

  /// Calculates Euclidean Distance between two vectors
  double compareVectors(List<double> v1, List<double> v2) {
    if (v1.length != v2.length) return 10.0;
    double sum = 0.0;
    for (int i = 0; i < v1.length; i++) {
      sum += math.pow(v1[i] - v2[i], 2);
    }
    return math.sqrt(sum);
  }

  static Float32List _processImageInIsolate(_IsolateData data) {
    final int width = data.width;
    final int height = data.height;
    final int targetSize = data.targetSize;
    final int cropSize = math.min(width, height);
    final int cropX = (width - cropSize) ~/ 2;
    final int cropY = (height - cropSize) ~/ 2;

    final floatInput = Float32List(1 * targetSize * targetSize * 3);
    int pixelIndex = 0;

    final double mean = data.normalizeMinusOneToOne ? 128.0 : 0.0;
    final double std = data.normalizeMinusOneToOne ? 128.0 : 255.0;

    if (data.isYUV) {
      final yBytes = data.planes[0];
      final uBytes = data.planes[1];
      final vBytes = data.planes[2];

      for (int y = 0; y < targetSize; y++) {
        final int srcY = cropY + (y * cropSize ~/ targetSize);
        for (int x = 0; x < targetSize; x++) {
          final int srcX = cropX + (x * cropSize ~/ targetSize);
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

          int r = (yVal + 1.402 * (vVal - 128)).toInt();
          int g = (yVal - 0.344136 * (uVal - 128) - 0.714136 * (vVal - 128))
              .toInt();
          int b = (yVal + 1.772 * (uVal - 128)).toInt();

          floatInput[pixelIndex++] = (r.clamp(0, 255) - mean) / std;
          floatInput[pixelIndex++] = (g.clamp(0, 255) - mean) / std;
          floatInput[pixelIndex++] = (b.clamp(0, 255) - mean) / std;
        }
      }
    } else {
      final bytes = data.planes[0];
      for (int y = 0; y < targetSize; y++) {
        final int srcY = cropY + (y * cropSize ~/ targetSize);
        for (int x = 0; x < targetSize; x++) {
          final int srcX = cropX + (x * cropSize ~/ targetSize);
          final int index = (srcY * data.yRowStride) + (srcX * 4);
          if (index + 2 >= bytes.length) {
            pixelIndex += 3;
            continue;
          }

          final b = bytes[index];
          final g = bytes[index + 1];
          final r = bytes[index + 2];

          floatInput[pixelIndex++] = (r - mean) / std;
          floatInput[pixelIndex++] = (g - mean) / std;
          floatInput[pixelIndex++] = (b - mean) / std;
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
  final bool normalizeMinusOneToOne;

  _IsolateData({
    required this.planes,
    required this.width,
    required this.height,
    required this.yRowStride,
    required this.uvRowStride,
    required this.uvPixelStride,
    required this.isYUV,
    required this.targetSize,
    this.normalizeMinusOneToOne = false,
  });
}
