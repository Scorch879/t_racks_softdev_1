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

  bool get isModelLoaded => _isModelLoaded;

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/models/model.tflite');
      print('Model loaded successfully');
    } catch (e) {
      print('Error loading model: $e');
      _isModelLoaded = false;
    }
  }

  void close() {
    _interpreter?.close();
    _isModelLoaded = false;
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

    var output = List.filled(1 * 2, 0).reshape([1, 2]);

    _interpreter!.run(inputTensor, output);

    return output[0].cast<double>();
  }

  List<List<List<double>>> _preprocessImage(img.Image image) {
    // huh
    final img.Image resizedImage = img.copyResize(
      image,
      width: INPUT_SIZE,
      height: INPUT_SIZE,
    );

    List<List<List<double>>> inputTensor = [[]];
    List<List<double>> imageMatrix = [];
    final pixelBytes = resizedImage.getBytes();
    int pixelIndex = 0;

    for (int y = 0; y < INPUT_SIZE; y++) {
      List<double> row = [];
      for (int x = 0; x < INPUT_SIZE; x++) {
        double r = pixelBytes[pixelIndex] / NORM_FACTOR;
        double g = pixelBytes[pixelIndex + 1] / NORM_FACTOR;
        double b = pixelBytes[pixelIndex + 2] / NORM_FACTOR;

        row.add(r);
        row.add(g);
        row.add(b);
        pixelIndex += 4;
      }
      imageMatrix.add(row);
    }

    inputTensor[0] = imageMatrix;
    return inputTensor;
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
        //ipone

        final Uint8List bgraBytes = image.planes[0].bytes;
        final Uint8List rgbBytes = _convertBGRAtoRGB(bgraBytes);

        return img.Image.fromBytes(
          width: image.width,
          height: image.height,
          bytes: image.planes[0].bytes.buffer,
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
