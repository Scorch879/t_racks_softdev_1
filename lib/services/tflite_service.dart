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

      // 1. Load Liveness Model (Your existing model)
      _livenessInterpreter = await Interpreter.fromAsset(
        'assets/models/model.tflite',
        options: options,
      );

      // 2. Load Recognition Model (You need to add this file to assets!)
      // Common name: mobilefacenet.tflite
      _recognitionInterpreter = await Interpreter.fromAsset(
        'assets/models/mobilefacenet.tflite',
        options: options,
      );

      _areModelsLoaded = true;
      print('Both Models Loaded Successfully.');
    } catch (e) {
      print('Error loading models: $e');
      print(
        'Make sure you have both model.tflite and mobilefacenet.tflite in assets!',
      );
    }
  }

  void close() {
    _livenessInterpreter?.close();
    _recognitionInterpreter?.close();
  }

  /// Returns true if the face is "Real", false if "Spoof"
  Future<bool> checkLiveness(CameraImage image) async {
    if (!_areModelsLoaded || _livenessInterpreter == null) return false;

    // Liveness models usually expect 224x224
    const int livenessInputSize = 224;

    // 1. Preprocess
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
        targetSize: livenessInputSize,
      ),
    );

    // 2. Reshape for Liveness Model [1, 224, 224, 3]
    final input = flatInput.reshape([
      1,
      livenessInputSize,
      livenessInputSize,
      3,
    ]);

    // 3. Output (Assuming [1, 2] or [1, 3] depending on your labels)
    // Adjust logic based on your specific liveness model labels
    // Usually: Index 0 = Fake, Index 1 = Real (or vice versa)
    var output = List.filled(3, 0.0).reshape([1, 3]);
    _livenessInterpreter!.run(input, output);

    List<double> scores = (output[0] as List)
        .map((e) => (e as num).toDouble())
        .toList();

    // Example Logic: If index 1 (Real) > 0.5 (Adjust based on your specific model)
    // You might need to check your labels.txt to know which index is "Real"
    // Assuming Index 1 is Real:
    double realScore = scores.length > 1 ? scores[1] : 0.0;
    return realScore > 0.7;
  }

  /// Generates the 192-d (or 128-d) Identity Vector
  Future<List<double>> generateFaceEmbedding(CameraImage image) async {
    if (!_areModelsLoaded || _recognitionInterpreter == null) return [];

    // MobileFaceNet usually expects 112x112
    const int recogInputSize = 112;

    // 1. Preprocess
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
        targetSize: recogInputSize,
      ),
    );

    // 2. Reshape for MobileFaceNet [1, 112, 112, 3]
    final input = flatInput.reshape([1, recogInputSize, recogInputSize, 3]);

    // 3. Output (Vector size depends on model, usually 192 for MobileFaceNet, 128 for FaceNet)
    // We try to catch the output shape dynamically
    final outputTensor = _recognitionInterpreter!.getOutputTensors().first;
    final outputShape = outputTensor.shape; // e.g., [1, 192]
    int vectorSize = outputShape.last;

    var output = List.filled(vectorSize, 0.0).reshape([1, vectorSize]);

    _recognitionInterpreter!.run(input, output);

    return (output[0] as List).map((e) => (e as num).toDouble()).toList();
  }

  static Float32List _processImageInIsolate(_IsolateData data) {
    final int width = data.width;
    final int height = data.height;
    final int targetSize = data.targetSize; // Use dynamic target size

    final int cropSize = math.min(width, height);
    final int cropX = (width - cropSize) ~/ 2;
    final int cropY = (height - cropSize) ~/ 2;

    final floatInput = Float32List(1 * targetSize * targetSize * 3);
    int pixelIndex = 0;

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

          floatInput[pixelIndex++] =
              (r.clamp(0, 255) - 128) / 128.0; // Normalized -1 to 1 for Recog
          floatInput[pixelIndex++] = (g.clamp(0, 255) - 128) / 128.0;
          floatInput[pixelIndex++] = (b.clamp(0, 255) - 128) / 128.0;
        }
      }
    } else {
      // BGRA logic (iOS/Emulator)
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

          floatInput[pixelIndex++] = (r - 128) / 128.0;
          floatInput[pixelIndex++] = (g - 128) / 128.0;
          floatInput[pixelIndex++] = (b - 128) / 128.0;
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
  final int targetSize; // Added targetSize

  _IsolateData({
    required this.planes,
    required this.width,
    required this.height,
    required this.yRowStride,
    required this.uvRowStride,
    required this.uvPixelStride,
    required this.isYUV,
    required this.targetSize,
  });
}
