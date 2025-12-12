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

      // 1. Load Liveness Model (Anti-Spoofing)
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

  /// Returns True if face is REAL, False if FAKE (Spoof)
  Future<bool> checkLiveness(CameraImage image, {Rect? faceBox}) async {
    if (!_areModelsLoaded || _livenessInterpreter == null) {
      await loadModels();
      if (_livenessInterpreter == null) return true; // Fail open if model missing
    }

    try {
      // Auto-detect input size (usually 128 or 224)
      final inputShape = _livenessInterpreter!.getInputTensors().first.shape;
      final int inputSize = inputShape[1];

      // Prepare image (Crop & Resize)
      final flatInput = await compute(
        _processImageForLiveness,
        _IsolateData(
          planes: image.planes.map((p) => p.bytes).toList(),
          width: image.width,
          height: image.height,
          yRowStride: image.planes[0].bytesPerRow,
          uvRowStride: image.planes.length > 1 ? image.planes[1].bytesPerRow : 0,
          uvPixelStride: image.planes.length > 1 ? (image.planes[1].bytesPerPixel ?? 1) : 0,
          isYUV: image.format.group == ImageFormatGroup.yuv420,
          faceBoxData: _rectToMap(faceBox),
          targetSize: inputSize,
        ),
      );

      // Run Inference
      final input = flatInput.reshape([1, inputSize, inputSize, 3]);
      final outputTensor = _livenessInterpreter!.getOutputTensors().first;
      final outputSize = outputTensor.shape.last;
      var output = List.filled(outputSize, 0.0).reshape([1, outputSize]);

      _livenessInterpreter!.run(input, output);

      final List<double> scores = (output[0] as List).map((e) => (e as num).toDouble()).toList();

      // Simple Logic: Index 1 is usually "Real", Index 0 is "Fake"
      // You may need to swap this based on your specific model training
      int maxIndex = 0;
      double maxScore = scores[0];
      for (int i = 1; i < scores.length; i++) {
        if (scores[i] > maxScore) {
          maxScore = scores[i];
          maxIndex = i;
        }
      }

      bool isReal = (maxIndex == 1);
      print("👻 Liveness Score: $scores -> ${isReal ? "REAL" : "FAKE"}");
      return isReal;

    } catch (e) {
      print("❌ Liveness Error: $e");
      return true;
    }
  }

  Future<List<double>> generateFaceEmbedding(CameraImage image, {Rect? faceBox}) async {
    if (!_areModelsLoaded || _recognitionInterpreter == null) {
      await loadModels();
      if (!_areModelsLoaded) return [];
    }

    try {
      const int targetSize = 160;
      
      final flatInput = await compute(
        _processImageForFaceNet,
        _IsolateData(
          planes: image.planes.map((p) => p.bytes).toList(),
          width: image.width,
          height: image.height,
          yRowStride: image.planes[0].bytesPerRow,
          uvRowStride: image.planes.length > 1 ? image.planes[1].bytesPerRow : 0,
          uvPixelStride: image.planes.length > 1 ? (image.planes[1].bytesPerPixel ?? 1) : 0,
          isYUV: image.format.group == ImageFormatGroup.yuv420,
          faceBoxData: _rectToMap(faceBox),
          targetSize: targetSize,
        ),
      );

      final input = flatInput.reshape([1, targetSize, targetSize, 3]);
      final outputTensor = _recognitionInterpreter!.getOutputTensors().first;
      int vectorLen = outputTensor.shape.last;
      var output = List.filled(vectorLen, 0.0).reshape([1, vectorLen]);

      _recognitionInterpreter!.run(input, output);
      
      List<double> vector = (output[0] as List).map((e) => (e as num).toDouble()).toList();
      return _l2Normalize(vector);
    } catch (e) {
      print("❌ Embedding Error: $e");
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

  Map<String, int>? _rectToMap(Rect? rect) {
    if (rect == null) return null;
    return {
      'left': rect.left.toInt(),
      'top': rect.top.toInt(),
      'width': rect.width.toInt(),
      'height': rect.height.toInt(),
    };
  }

  // --- ISOLATE HELPERS ---

  static Float32List _processImageForLiveness(_IsolateData data) {
    // Liveness usually expects 0.0-1.0 normalization and a wider crop
    return _extractPixels(data, (p) => p / 255.0, cropScale: 1.4);
  }

  static Float32List _processImageForFaceNet(_IsolateData data) {
    // FaceNet expects standardization
    return _extractPixels(data, (p) => p.toDouble(), cropScale: 1.0, standardize: true);
  }

  static Float32List _extractPixels(_IsolateData data, double Function(int) transform, {double cropScale = 1.0, bool standardize = false}) {
    img.Image? originalImage = _convertYUV420ToImage(data);
    if (originalImage == null) return Float32List(0);

    // Crop Logic
    int x = 0, y = 0, w = originalImage.width, h = originalImage.height;
    if (data.faceBoxData != null) {
      double cx = data.faceBoxData!['left']! + data.faceBoxData!['width']! / 2;
      double cy = data.faceBoxData!['top']! + data.faceBoxData!['height']! / 2;
      double size = math.max(data.faceBoxData!['width']!, data.faceBoxData!['height']!) * cropScale;
      
      x = (cx - size / 2).toInt();
      y = (cy - size / 2).toInt();
      w = size.toInt();
      h = size.toInt();
    }

    img.Image face = img.copyCrop(originalImage, x: x, y: y, width: w, height: h);
    img.Image resized = img.copyResize(face, width: data.targetSize, height: data.targetSize);

    // Extract Bytes
    final Float32List floatInput = Float32List(data.targetSize * data.targetSize * 3);
    int pIndex = 0;

    if (standardize) {
        // Mean/Std Calculation
        double sum = 0, sqSum = 0;
        for (int i = 0; i < data.targetSize; i++) {
           for (int j = 0; j < data.targetSize; j++) {
              var p = resized.getPixel(j, i);
              sum += p.r + p.g + p.b;
              sqSum += (p.r*p.r) + (p.g*p.g) + (p.b*p.b);
           }
        }
        double mean = sum / (data.targetSize * data.targetSize * 3);
        double std = math.sqrt((sqSum / (data.targetSize * data.targetSize * 3)) - (mean * mean));
        std = math.max(std, 1.0 / math.sqrt(data.targetSize * data.targetSize * 3));

        for (int i = 0; i < data.targetSize; i++) {
           for (int j = 0; j < data.targetSize; j++) {
              var p = resized.getPixel(j, i);
              floatInput[pIndex++] = (p.r - mean) / std;
              floatInput[pIndex++] = (p.g - mean) / std;
              floatInput[pIndex++] = (p.b - mean) / std;
           }
        }
    } else {
        for (int i = 0; i < data.targetSize; i++) {
           for (int j = 0; j < data.targetSize; j++) {
              var p = resized.getPixel(j, i);
              floatInput[pIndex++] = transform(p.r.toInt());
              floatInput[pIndex++] = transform(p.g.toInt());
              floatInput[pIndex++] = transform(p.b.toInt());
           }
        }
    }
    return floatInput;
  }

  static img.Image? _convertYUV420ToImage(_IsolateData data) {
    try {
      final width = data.width;
      final height = data.height;
      final yBuffer = data.planes[0];
      
      // Single Plane Check (NV21)
      bool isSinglePlane = data.planes.length == 1;
      if (isSinglePlane && yBuffer.length < width * height * 1.5) {
         // Fallback to BGRA if buffer size is huge
         if (yBuffer.length >= width * height * 4) {
           return img.Image.fromBytes(width: width, height: height, bytes: yBuffer.buffer, order: img.ChannelOrder.bgra);
         }
      }

      final img.Image image = img.Image(width: width, height: height);
      final int uvRowStride = data.uvRowStride > 0 ? data.uvRowStride : width;
      final int uvPixelStride = data.uvPixelStride > 0 ? data.uvPixelStride : 2;
      
      int uvOffset = isSinglePlane ? (width * height) : 0;
      final uBuffer = isSinglePlane ? yBuffer : (data.planes.length > 1 ? data.planes[1] : Uint8List(0));
      final vBuffer = isSinglePlane ? yBuffer : (data.planes.length > 2 ? data.planes[2] : Uint8List(0));

      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final int yIndex = y * data.yRowStride + x;
          if (yIndex >= yBuffer.length) continue;
          
          final int yVal = yBuffer[yIndex];
          int uVal = 128, vVal = 128;

          final int uvIndex = uvOffset + (y >> 1) * uvRowStride + (x >> 1) * uvPixelStride;

          if (isSinglePlane) {
             if (uvIndex + 1 < yBuffer.length) {
               vVal = yBuffer[uvIndex];
               uVal = yBuffer[uvIndex + 1];
             }