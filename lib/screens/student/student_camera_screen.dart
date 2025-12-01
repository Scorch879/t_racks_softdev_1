import 'package:flutter/material.dart';
import 'package:t_racks_softdev_1/screens/student/student_shell_camvoice_screen.dart';
import 'package:t_racks_softdev_1/screens/student/student_camera_content.dart';

class StudentCameraScreen extends StatelessWidget {
  const StudentCameraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const StudentShellCamvoiceScreen(
      child: StudentCameraContent(),
    );
  }
}
