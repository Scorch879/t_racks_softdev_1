import 'dart:async';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'dart:ui';

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

      // 2. Load FaceNet 512 (Current Active Model)
      // NOTE: mobilefacenet.tflite is available in assets but UNUSED here.
      // To use it, change the string below to 'assets/models/mobilefacenet.tflite'
      // and ensure the output shape matches (192 for mobilefacenet vs 512 for facenet).
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

  Future<bool> checkLiveness(CameraImage image) async {
    return true; // Keep true for now to isolate the vector issue
  }

  Future<List<double>> generateFaceEmbedding(
    CameraImage image, {
    Rect? faceBox,
  }) async {
    if (!_areModelsLoaded || _recognitionInterpreter == null) return [];

    // FaceNet-512 expects 160x160
    const int inputSize = 160;

    // Calculate Crop Coordinates
    int cropX = 0,
        cropY = 0,
        cropWidth = image.width,
        cropHeight = image.height;

    if (faceBox != null) {
      double margin = 0.10; // 10% margin
      double width = faceBox.width * (1 + margin);
      double height = faceBox.height * (1 + margin);
      double centerX = faceBox.center.dx;
      double centerY = faceBox.center.dy;
      double side = math.max(width, height);

      cropX = (centerX - side / 2).toInt();
      cropY = (centerY - side / 2).toInt();
      cropWidth = side.toInt();
      cropHeight = side.toInt();
    }

    // Clamp to image bounds
    cropX = cropX.clamp(0, image.width - 1);
    cropY = cropY.clamp(0, image.height - 1);
    if (cropX + cropWidth > image.width) cropWidth = image.width - cropX;
    if (cropY + cropHeight > image.height) cropHeight = image.height - cropY;

    // --- STEP 1: PROCESSING ---
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
        isYUV: image.format.group == ImageFormatGroup.yuv420,
        targetSize: inputSize,
        cropX: cropX,
        cropY: cropY,
        cropWidth: cropWidth,
        cropHeight: cropHeight,
      ),
    );

    // --- STEP 2: INFERENCE ---
    if (flatInput.length == 0) return []; // Check for conversion failure

    final input = flatInput.reshape([1, inputSize, inputSize, 3]);
    final outputTensor = _recognitionInterpreter!.getOutputTensors().first;
    int vectorLen = outputTensor.shape.last; // 512
    var output = List.filled(vectorLen, 0.0).reshape([1, vectorLen]);

    _recognitionInterpreter!.run(input, output);

    List<double> rawVector = (output[0] as List)
        .map((e) => (e as num).toDouble())
        .toList();

    return _l2Normalize(rawVector);
  }

  List<double> _l2Normalize(List<double> vector) {
    double sum = 0;
    for (var x in vector) sum += x * x;
    double norm = math.sqrt(sum);
    if (norm == 0) return vector;
    return vector.map((x) => x / norm).toList();
  }

  double compareVectors(List<double> v1, List<double> v2) {
    if (v1.length != v2.length) return 10.0;
    double sum = 0.0;
    for (int i = 0; i < v1.length; i++) {
      sum += math.pow(v1[i] - v2[i], 2);
    }
    return math.sqrt(sum);
  }

  // --- ISOLATE LOGIC ---

  static Float32List _processImageForFaceNet(_IsolateData data) {
    // 1. Convert Camera Data to a standard RGB Image
    img.Image? originalImage = _convertYUV420ToImage(data);

    if (originalImage == null) return Float32List(0);

    // 2. Crop & Resize
    img.Image faceImage = img.copyCrop(
      originalImage,
      x: data.cropX,
      y: data.cropY,
      width: data.cropWidth,
      height: data.cropHeight,
    );

    img.Image resizedImage = img.copyResize(
      faceImage,
      width: data.targetSize,
      height: data.targetSize,
      interpolation: img.Interpolation.linear,
    );

    // 3. Standardize (Pixel - Mean / Std)
    final Float32List floatInput = Float32List(
      data.targetSize * data.targetSize * 3,
    );
    int pixelIndex = 0;

    // Convert to Float & Standardize
    // Iterate pixels
    double sum = 0;
    double sqSum = 0;
    int numPixels = data.targetSize * data.targetSize * 3;

    // Pass 1: Calc Mean/Std
    for (int y = 0; y < data.targetSize; y++) {
      for (int x = 0; x < data.targetSize; x++) {
        final pixel = resizedImage.getPixel(x, y);
        sum += pixel.r + pixel.g + pixel.b;
        sqSum +=
            (pixel.r * pixel.r) + (pixel.g * pixel.g) + (pixel.b * pixel.b);
      }
    }

    double mean = sum / numPixels;
    double variance = (sqSum / numPixels) - (mean * mean);
    double std = math.sqrt(variance);
    std = math.max(std, 1.0 / math.sqrt(numPixels.toDouble()));

    // Pass 2: Normalize
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

  static img.Image? _convertYUV420ToImage(_IsolateData data) {
    try {
      final width = data.width;
      final height = data.height;
      final yBuffer = data.planes[0];

      // Determine format: Multi-plane (Normal) or Single-plane (NV21 packed)
      bool isSinglePlane = data.planes.length == 1;

      // Safety Check: If single plane, ensure it's large enough for YUV420
      // YUV420 needs 1.5 bytes per pixel. BGRA needs 4 bytes.
      if (isSinglePlane) {
        if (yBuffer.length < width * height * 1.5) {
          // Buffer too small for YUV? Might be corrupted or odd format.
          // Attempt to read as BGRA if size matches, else return null.
          if (yBuffer.length >= width * height * 4) {
            return img.Image.fromBytes(
              width: width,
              height: height,
              bytes: yBuffer.buffer,
              order: img.ChannelOrder.bgra,
            );
          }
        }
      }

      final img.Image image = img.Image(width: width, height: height);
      final int uvRowStride = data.uvRowStride > 0 ? data.uvRowStride : width;
      final int uvPixelStride = data.uvPixelStride > 0 ? data.uvPixelStride : 2;

      // Offsets for Single Plane NV21
      // Y ends at width*height. UV starts immediately after.
      final int uvOffset = isSinglePlane ? (width * height) : 0;
      final Uint8List uBuffer = isSinglePlane
          ? yBuffer
          : (data.planes.length > 1 ? data.planes[1] : Uint8List(0));
      final Uint8List vBuffer = isSinglePlane
          ? yBuffer
          : (data.planes.length > 2 ? data.planes[2] : Uint8List(0));

      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final int yIndex = y * data.yRowStride + x;

          if (yIndex >= yBuffer.length) continue;
          final int yVal = yBuffer[yIndex];

          // Calculate UV Index
          final int uvRow = y >> 1;
          final int uvCol = x >> 1;
          final int uvBaseIndex = uvRow * uvRowStride + uvCol * uvPixelStride;

          int uVal = 128, vVal = 128;

          if (isSinglePlane) {
            // NV21 (Android default) -> V then U
            int index = uvOffset + uvBaseIndex;
            if (index + 1 < yBuffer.length) {
              vVal = yBuffer[index];
              uVal = yBuffer[index + 1];
            }
          } else if (uBuffer.isNotEmpty && vBuffer.isNotEmpty) {
            if (uvBaseIndex < uBuffer.length && uvBaseIndex < vBuffer.length) {
              uVal = uBuffer[uvBaseIndex];
              vVal = vBuffer[uvBaseIndex];
            }
          }

          // YUV to RGB Conversion
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

      // Rotate if needed (usually front camera is rotated)
      return img.copyRotate(image, angle: -90);
    } catch (e) {
      print("Convert Error: $e");
      return null;
    }
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
