import 'dart:async';
import 'dart:typed_data';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class ModelManager {
  Interpreter? _livenessInterpreter;
  Interpreter? _recognitionInterpreter;
  bool _areModelsLoaded = false;

  bool get areModelsLoaded => _areModelsLoaded;

  Future<void> loadModels() async {
    try {
      if (_areModelsLoaded) return;

      final options = InterpreterOptions();

      // 1. Load Liveness Model (Spoof Detection)
      _livenessInterpreter = await Interpreter.fromAsset(
        'assets/models/model.tflite',
        options: options,
      );

      // 2. Load FaceNet 512 (Recognition)
      _recognitionInterpreter = await Interpreter.fromAsset(
        'assets/models/facenet_512.tflite',
        options: options,
      );

      _areModelsLoaded = true;
      print('✅ FaceNet-512 & Liveness Models Loaded.');
    } catch (e) {
      print('❌ Error loading models: $e');
      _areModelsLoaded = false;
    }
  }

  void close() {
    _livenessInterpreter?.close();
    _recognitionInterpreter?.close();
  }

  /// Compares two face vectors. Lower distance = better match.
  double compareVectors(List<double> v1, List<double> v2) {
    if (v1.length != v2.length) return 10.0;
    double sum = 0.0;
    for (int i = 0; i < v1.length; i++) {
      sum += math.pow(v1[i] - v2[i], 2);
    }
    return math.sqrt(sum);
  }

  /// Returns True if face is REAL, False if FAKE (Spoof)
  Future<bool> checkLiveness(CameraImage image, {Rect? faceBox}) async {
    // Safety check: if model isn't loaded, default to allowing it (or fail secure)
    if (!_areModelsLoaded || _livenessInterpreter == null) {
      await loadModels(); // Try one last time
      if (_livenessInterpreter == null) return true; // Fail open if missing
    }

    try {
      // Auto-detect input size from the model (usually 128x128 or 224x224)
      final inputShape = _livenessInterpreter!.getInputTensors().first.shape;
      final int inputSize = inputShape[1];

      // Extract Rect values safely
      final Map<String, int>? boxData = faceBox != null
          ? {
              'left': faceBox.left.toInt(),
              'top': faceBox.top.toInt(),
              'width': faceBox.width.toInt(),
              'height': faceBox.height.toInt(),
            }
          : null;

      // Process image specifically for Liveness (often needs wider crop)
      final flatInput = await compute(
        _processImageForLiveness,
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
          targetSize: inputSize,
        ),
      );

      // Prepare Inputs/Outputs
      final input = flatInput.reshape([1, inputSize, inputSize, 3]);

      // Get Output Shape
      final outputTensor = _livenessInterpreter!.getOutputTensors().first;
      final outputShape = outputTensor.shape;
      final outputSize = outputShape.last; // e.g., 2 or 3 classes
      var output = List.filled(outputSize, 0.0).reshape([1, outputSize]);

      // Run Inference
      _livenessInterpreter!.run(input, output);

      final List<double> scores = (output[0] as List)
          .map((e) => (e as num).toDouble())
          .toList();

      // LOGIC: Interpreting the results
      // If 2 Classes: [0] = Fake, [1] = Real (usually)
      // If 3 Classes (MiniFASNet): [0]=Spoof, [1]=Real, [2]=Spoof

      int maxIndex = 0;
      double maxScore = scores[0];
      for (int i = 1; i < scores.length; i++) {
        if (scores[i] > maxScore) {
          maxScore = scores[i];
          maxIndex = i;
        }
      }

      // Standard assumption: Class 1 is "Real Face"
      bool isReal = (maxIndex == 1);

      print("👻 Liveness Check: $scores -> ${isReal ? "REAL" : "FAKE"}");
      return isReal;
    } catch (e) {
      print("❌ Liveness Check Error: $e");
      return true; // Default to true on error to prevent blocking users
    }
  }

  Future<List<double>> generateFaceEmbedding(
    CameraImage image, {
    Rect? faceBox,
  }) async {
    if (!_areModelsLoaded || _recognitionInterpreter == null) {
      await loadModels();
      if (!_areModelsLoaded || _recognitionInterpreter == null) return [];
    }

    try {
      const int targetInputSize = 160;

      final Map<String, int>? boxData = faceBox != null
          ? {
              'left': faceBox.left.toInt(),
              'top': faceBox.top.toInt(),
              'width': faceBox.width.toInt(),
              'height': faceBox.height.toInt(),
            }
          : null;

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

  // --- PROCESSING LOGIC (Isolate) ---

  static Float32List _processImageForLiveness(_IsolateData data) {
    // For Liveness, we often just normalize 0-1 or -1 to 1
    // And we usually take a slightly larger crop (scale 1.5x or 2.0x)
    // Here we reuse the standard crop for simplicity, but normalize to [0,1]
    return _extractPixels(data, (pixel) => pixel / 255.0, cropScale: 1.5);
  }

  static Float32List _processImageForFaceNet(_IsolateData data) {
    // FaceNet expects standardized data (pixel - mean) / std
    return _extractPixels(
      data,
      (pixel) => pixel.toDouble(),
      cropScale: 1.0,
      standardize: true,
    );
  }

  static Float32List _extractPixels(
    _IsolateData data,
    double Function(int) transform, {
    double cropScale = 1.0,
    bool standardize = false,
  }) {
    img.Image? originalImage;

    // 1. Convert Image
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
      return Float32List(data.targetSize * data.targetSize * 3);
    }

    // 2. Crop
    img.Image faceImage;
    if (data.faceBoxData != null) {
      int left = data.faceBoxData!['left']!;
      int top = data.faceBoxData!['top']!;
      int width = data.faceBoxData!['width']!;
      int height = data.faceBoxData!['height']!;

      // Expand crop for liveness (needs context) or keep normal for FaceNet
      if (cropScale > 1.0) {
        final cx = left + width / 2;
        final cy = top + height / 2;
        final newSize = math.max(width, height) * cropScale;
        left = (cx - newSize / 2).toInt();
        top = (cy - newSize / 2).toInt();
        width = newSize.toInt();
        height = newSize.toInt();
      }

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
      // Center crop fallback
      int size = math.min(originalImage.width, originalImage.height);
      faceImage = img.copyCrop(
        originalImage,
        x: (originalImage.width - size) ~/ 2,
        y: (originalImage.height - size) ~/ 2,
        width: size,
        height: size,
      );
    }

    // 3. Resize
    img.Image resizedImage = img.copyResize(
      faceImage,
      width: data.targetSize,
      height: data.targetSize,
      interpolation: img.Interpolation.linear,
    );

    // 4. Extract & Normalize
    final Float32List floatInput = Float32List(
      data.targetSize * data.targetSize * 3,
    );
    int pixelIndex = 0;

    if (standardize) {
      // Calculate mean/std for FaceNet
      double sum = 0;
      double sqSum = 0;
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

      for (int y = 0; y < data.targetSize; y++) {
        for (int x = 0; x < data.targetSize; x++) {
          final pixel = resizedImage.getPixel(x, y);
          floatInput[pixelIndex++] = (pixel.r - mean) / std;
          floatInput[pixelIndex++] = (pixel.g - mean) / std;
          floatInput[pixelIndex++] = (pixel.b - mean) / std;
        }
      }
    } else {
      // Standard 0-1 Normalization for Liveness
      for (int y = 0; y < data.targetSize; y++) {
        for (int x = 0; x < data.targetSize; x++) {
          final pixel = resizedImage.getPixel(x, y);
          floatInput[pixelIndex++] = transform(pixel.r.toInt());
          floatInput[pixelIndex++] = transform(pixel.g.toInt());
          floatInput[pixelIndex++] = transform(pixel.b.toInt());
        }
      }
    }

    return floatInput;
  }

  static img.Image _convertYUV420ToImage(_IsolateData data) {
    final width = data.width;
    final height = data.height;
    final uvRowStride = data.uvRowStride;
    final uvPixelStride = data.uvPixelStride;
    final yRowStride = data.yRowStride;

    final img.Image image = img.Image(width: width, height: height);
    final yBuffer = data.planes[0];
    final uBuffer = data.planes.length > 1 ? data.planes[1] : Uint8List(0);
    final vBuffer = data.planes.length > 2 ? data.planes[2] : Uint8List(0);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int yIndex = y * yRowStride + x;
        final int uvIndex = (y ~/ 2) * uvRowStride + (x ~/ 2) * uvPixelStride;

        if (yIndex >= yBuffer.length) continue;

        final int yVal = yBuffer[yIndex];
        int uVal = 128, vVal = 128;

        if (uBuffer.isNotEmpty &&
            vBuffer.isNotEmpty &&
            uvIndex < uBuffer.length &&
            uvIndex < vBuffer.length) {
          uVal = uBuffer[uvIndex];
          vVal = vBuffer[uvIndex];
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
