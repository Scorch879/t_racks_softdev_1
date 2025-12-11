import 'package:camera/camera.dart';

class CameraService {
  // Singleton pattern
  static final CameraService instance = CameraService._internal();

  factory CameraService() {
    return instance;
  }

  CameraService._internal();

  List<CameraDescription> _cameras = [];

  List<CameraDescription> get cameras => _cameras;

  Future<void> initialize() async {
    try {
      _cameras = await availableCameras();
      print("CameraService initialized with ${_cameras.length} cameras");
    } on CameraException catch (e) {
      print('Error in fetching the cameras: $e');
    }
  }
}
