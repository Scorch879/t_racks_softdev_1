import 'dart:async';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

const int INPUT_SIZE = 224;

class ModelManager {
  Interpreter? _interpreter;
  bool _isModelLoaded = false;
  List<String> _labels = [];

  bool get isModelLoaded => _isModelLoaded;
  List<String> get labels => _labels;

  Future<void> loadModel() async {
    try {
      final options = InterpreterOptions();
      // options.addDelegate(GpuDelegateV2()); // Uncomment for extra speed on Android

      _interpreter = await Interpreter.fromAsset(
        'assets/models/model.tflite',
        options: options,
      );

      await _loadLabels();
      _isModelLoaded = true;
      print('Model Loaded Successfully.');
    } catch (e) {
      print('Error loading model: $e');
    }
  }

  Future<void> _loadLabels() async {
    try {
      final String labelsString = await rootBundle.loadString(
        'assets/models/labels.txt',
      );
      _labels = labelsString
          .split('\n')
          .where((l) => l.trim().isNotEmpty)
          .toList();
    } catch (e) {
      print('Warning: Labels failed to load.');
    }
  }

  void close() {
    _interpreter?.close();
  }

  Future<List<double>> runInferenceOnCameraImage(CameraImage image) async {
    if (!_isModelLoaded || _interpreter == null) return [];

    // 1. Prepare data for Isolate
    final planes = image.planes.map((p) => p.bytes).toList();

    // Safety check for format
    // YUV420 has 3 planes, BGRA8888 has 1 plane
    final isYUV = image.planes.length >= 3;

    // 2. Run Heavy Image Processing in Background Thread
    final inputTensor = await compute(
      _processImageInIsolate,
      _IsolateData(
        planes: planes,
        width: image.width,
        height: image.height,
        yRowStride: image.planes[0].bytesPerRow,
        uvRowStride: isYUV ? image.planes[1].bytesPerRow : 0,
        uvPixelStride: isYUV ? (image.planes[1].bytesPerPixel ?? 1) : 0,
        isYUV: isYUV,
      ),
    );

    // 3. Prepare Output
    int classCount = _labels.isNotEmpty ? _labels.length : 3;
    var output = List.filled(classCount, 0.0).reshape([1, classCount]);

    // 4. Run Inference
    _interpreter!.run(inputTensor, output);

    // 5. Return results
    return (output[0] as List).map((e) => (e as num).toDouble()).toList();
  }

  /// STATIC FUNCTION: Runs in background
  static Float32List _processImageInIsolate(_IsolateData data) {
    final int width = data.width;
    final int height = data.height;
    final int cropSize = math.min(width, height);
    final int cropX = (width - cropSize) ~/ 2;
    final int cropY = (height - cropSize) ~/ 2;

    final floatInput = Float32List(1 * INPUT_SIZE * INPUT_SIZE * 3);
    int pixelIndex = 0;

    if (data.isYUV) {
      // --- ANDROID / YUV Processing ---
      final yBytes = data.planes[0];
      final uBytes = data.planes[1];
      final vBytes = data.planes[2];

      for (int y = 0; y < INPUT_SIZE; y++) {
        final int srcY = cropY + (y * cropSize ~/ INPUT_SIZE);
        for (int x = 0; x < INPUT_SIZE; x++) {
          final int srcX = cropX + (x * cropSize ~/ INPUT_SIZE);

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

          floatInput[pixelIndex++] = r.clamp(0, 255) / 255.0;
          floatInput[pixelIndex++] = g.clamp(0, 255) / 255.0;
          floatInput[pixelIndex++] = b.clamp(0, 255) / 255.0;
        }
      }
    } else {
      // --- EMULATOR / iOS / BGRA Processing ---
      // BGRA8888 typically has 1 plane with all data
      final bytes = data.planes[0];
      // 4 bytes per pixel: B, G, R, A

      for (int y = 0; y < INPUT_SIZE; y++) {
        final int srcY = cropY + (y * cropSize ~/ INPUT_SIZE);
        for (int x = 0; x < INPUT_SIZE; x++) {
          final int srcX = cropX + (x * cropSize ~/ INPUT_SIZE);

          final int index = (srcY * data.yRowStride) + (srcX * 4);

          if (index + 2 >= bytes.length) {
            pixelIndex += 3;
            continue;
          }

          final b = bytes[index];
          final g = bytes[index + 1];
          final r = bytes[index + 2];
          // A is at index+3, usually ignored for models

          floatInput[pixelIndex++] = r / 255.0;
          floatInput[pixelIndex++] = g / 255.0;
          floatInput[pixelIndex++] = b / 255.0;
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
  final bool isYUV; // Flag to tell isolate which format to use

  _IsolateData({
    required this.planes,
    required this.width,
    required this.height,
    required this.yRowStride,
    required this.uvRowStride,
    required this.uvPixelStride,
    required this.isYUV,
  });
}
