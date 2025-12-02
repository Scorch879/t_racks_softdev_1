import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:t_racks_softdev_1/screens/student/student_shell_camvoice_screen.dart';
import 'package:t_racks_softdev_1/screens/student/student_camera_content.dart';

class StudentCameraScreen extends StatelessWidget {
  final List<CameraDescription> cameras;

  const StudentCameraScreen({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    return StudentShellCamvoiceScreen(
      child: StudentCameraContent(cameras: cameras),
    );
  }
}
