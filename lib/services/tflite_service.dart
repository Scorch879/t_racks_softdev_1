import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'dart:typed_data';
import 'dart:math';

const int INPUT_SIZE = 224;
const double NORM_FACTOR = 255.0;

class ModelManager {
  Interpreter? _interpreter; //no clue what this is but it holds the model
  bool _isModelLoaded = false;
  List<String> _labels = [];

  bool get isModelLoaded => _isModelLoaded;
  List<String> get labels => List.unmodifiable(_labels);

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/models/model.tflite');
      
      // Print input/output tensor shapes and types for debugging
      if (_interpreter != null) {
        final inputTensors = _interpreter!.getInputTensors();
        final outputTensors = _interpreter!.getOutputTensors();
        print('Input tensor shape: ${inputTensors[0].shape}, type: ${inputTensors[0].type}');
        print('Output tensor shape: ${outputTensors[0].shape}, type: ${outputTensors[0].type}');
      }
      
      await _loadLabels();
      _isModelLoaded = true;
      print('Model loaded successfully with ${_labels.length} labels');
    } catch (e) {
      print('Error loading model: $e');
      _isModelLoaded = false;
      _labels = [];
    }
  }

  Future<void> _loadLabels() async {
    try {
      final String labelsString =
          await rootBundle.loadString('assets/models/labels.txt');
      _labels = labelsString
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .map((line) {
        // Extract label name from format "0 Face (Real Face)" or "0 Label"
        final parts = line.trim().split(' ');
        if (parts.length > 1) {
          return parts.sublist(1).join(' ').trim();
        }
        return line.trim();
      }).toList();
      print('Labels loaded: $_labels');
    } catch (e) {
      print('Error loading labels: $e');
      _labels = [];
    }
  }

  void close() {
    _interpreter?.close();
    _isModelLoaded = false;
    _labels = [];
  }

  Future<List<double>> runInferenceOnCameraImage(
    CameraImage cameraImage,
  ) async {
    if (!_isModelLoaded || _interpreter == null) {
      throw Exception('Model is not loaded');
    }

    final img.Image? rgbImage = _convertCameraImageToImage(cameraImage);
    if (rgbImage == null) {
      throw Exception('Failed to convert CameraImage to Image');
    }

    final inputTensor = _preprocessImage(rgbImage);

    // Model outputs 3 classes based on labels.txt:
    // 0 = Face (Real Face)
    // 1 = Background (No face)
    // 2 = Face (Fake)
    // Use float32 for output (most common for classification models)
    var output = List.filled(1 * 3, 0.0).reshape([1, 3]);

    _interpreter!.run(inputTensor, output);

    // Safely convert output to List<double>
    // Handle both int and double types from the model output
    final outputList = output[0] as List;
    return outputList.map((e) {
      if (e is int) {
        return e.toDouble();
      } else if (e is double) {
        return e;
      } else {
        // Fallback: try to parse as double
        return (e as num).toDouble();
      }
    }).toList();
  }

  List _preprocessImage(img.Image image) {
    final img.Image resizedImage = img.copyResize(
      image,
      width: INPUT_SIZE,
      height: INPUT_SIZE,
    );

    // Create flattened array: [batch*height*width*channels]
    // Format: RGBRGBRGB... for all pixels
    // Shape will be [1, 224, 224, 3] when reshaped
    // Model expects uint8 (0-255), not normalized doubles
    final int totalSize = 1 * INPUT_SIZE * INPUT_SIZE * 3;
    final Uint8List flattened = Uint8List(totalSize);

    int index = 0;
    for (int y = 0; y < INPUT_SIZE; y++) {
      for (int x = 0; x < INPUT_SIZE; x++) {
        // Get pixel and extract RGB components from Pixel object
        final pixel = resizedImage.getPixel(x, y);
        // Use raw uint8 values (0-255), not normalized doubles
        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();

        // Flatten in order: R, G, B for each pixel
        flattened[index++] = r;
        flattened[index++] = g;
        flattened[index++] = b;
      }
    }

    // Reshape to [1, 224, 224, 3] - 4D tensor
    return flattened.reshape([1, INPUT_SIZE, INPUT_SIZE, 3]);
  }

  Uint8List _convertBGRAtoRGB(Uint8List bgraBytes) {
    // BGRA is 4 bytes per pixel, RGB is 3 bytes per pixel
    final int numPixels = bgraBytes.length ~/ 4;
    final Uint8List rgbBytes = Uint8List(numPixels * 3);

    int rgbIndex = 0;
    for (int i = 0; i < bgraBytes.length; i += 4) {
      // BGRA order: [B, G, R, A]
      // Target RGB order: [R, G, B]
      rgbBytes[rgbIndex] = bgraBytes[i + 2]; // R
      rgbBytes[rgbIndex + 1] = bgraBytes[i + 1]; // G
      rgbBytes[rgbIndex + 2] = bgraBytes[i]; // B
      rgbIndex += 3;
    }
    return rgbBytes;
  }

  img.Image? _convertCameraImageToImage(CameraImage image) {
    try {
      if (image.format.group == ImageFormatGroup.yuv420) {
        //andoird
        return _convertYUV420ToImage(image);
      } else if (image.format.group == ImageFormatGroup.bgra8888) {
        // iPhone
        final Uint8List bgraBytes = image.planes[0].bytes;
        final Uint8List rgbBytes = _convertBGRAtoRGB(bgraBytes);

        return img.Image.fromBytes(
          width: image.width,
          height: image.height,
          bytes: rgbBytes.buffer,
          format: img.Format.uint8,
        );
      }
      return null;
    } catch (e) {
      print("Conversion failed: $e");
      return null;
    }
  }

  img.Image? _convertYUV420ToImage(CameraImage cameraImage) {
    final int width = cameraImage.width;
    final int height = cameraImage.height;

    final plane = cameraImage.planes[0]; // Y-Plane
    final uvPlaneU = cameraImage.planes[1]; // U-Plane (or Cr)
    final uvPlaneV = cameraImage.planes[2]; // V-Plane (or Cb)

    // Create an image object for the final RGB data
    final img.Image image = img.Image(width: width, height: height);

    // YUV to RGB conversion loop
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int uvX = x ~/ 2;
        final int uvY = y ~/ 2;

        final int yIndex = y * plane.bytesPerRow + x;

        // This indexing is specific to the YUV_420_888 format layout
        final int uIndex = uvY * uvPlaneU.bytesPerRow + uvX;
        final int vIndex = uvY * uvPlaneV.bytesPerRow + uvX;

        // Ensure indices are within bounds
        if (yIndex >= plane.bytes.length ||
            uIndex >= uvPlaneU.bytes.length ||
            vIndex >= uvPlaneV.bytes.length) {
          continue; // Skip out of bounds pixels
        }

        final int Y = plane.bytes[yIndex];
        final int U = uvPlaneU.bytes[uIndex];
        final int V = uvPlaneV.bytes[vIndex];

        int r = (Y + 1.402 * (V - 128)).toInt();
        int g = (Y - 0.344136 * (U - 128) - 0.714136 * (V - 128)).toInt();
        int b = (Y + 1.772 * (U - 128)).toInt();

        // Clamp values to 0-255 range
        r = r.clamp(0, 255);
        g = g.clamp(0, 255);
        b = b.clamp(0, 255);

        // Set the RGB pixel color
        image.setPixelRgb(x, y, r, g, b);
      }
    }
    return image;
  }
}
