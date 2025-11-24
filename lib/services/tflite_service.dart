import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

class ModelManager {
  Interpreter?
  _interpreter; //no clue what this is but hypothetically it holds the model

  bool get isModelLoaded => _interpreter != null;

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/models/model.tflite');
      print('Model loaded successfully');
    } catch (e) {
      print('Error loading model: $e');
    }
  }

  void close() {
    _interpreter?.close();
  }

  Future<ByteData> loadAssetBytes(String path) async {
    return await rootBundle.load(path);
  }

  Future<List<List<List<double>>>> preprocessImage(String assetPath) async {
    // raw
    final ByteData byteData = await loadAssetBytes(assetPath);
    final Uint8List rawBytes = byteData.buffer.asUint8List();

    //this will decode the image bytes into image object
    final img.Image? decodedImage = img.decodeImage(rawBytes);

    if (decodedImage == null) {
      throw Exception('Failed to decode image');
    }

    return [];
  }
}
