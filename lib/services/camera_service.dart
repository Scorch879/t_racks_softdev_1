import 'package:camera/camera.dart';

class CameraService {
  static final CameraService instance = CameraService._internal();

  factory CameraService() => instance;
  CameraService._internal();

  List<CameraDescription> _cameras = [];

  List<CameraDescription> get cameras => _cameras;

  bool get isInitialized => _cameras.isNotEmpty;

  Future<void> initialize() async {
    if (_cameras.isNotEmpty) return;

    try {
      _cameras = await availableCameras();
      print('CameraService initialized with ${_cameras.length} cameras.');
    } on CameraException catch (e) {
      print('Error initializing cameras: $e');
      _cameras = [];
    }
  }
}