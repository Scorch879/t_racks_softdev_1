import 'package:flutter/material.dart';
import 'package:t_racks_softdev_1/screens/student/student_shell_camvoice_screen.dart';
import 'package:t_racks_softdev_1/screens/student/student_camera_content.dart';

class StudentCameraScreen extends StatefulWidget {
  const StudentCameraScreen({super.key});

  @override
  State<StudentCameraScreen> createState() => _StudentCameraScreenState();
}

class _StudentCameraScreenState extends State<StudentCameraScreen> {
  @override
  Widget build(BuildContext context) {
    return const StudentShellCamvoiceScreen(
      child: StudentCameraContent(),
    );
  }
}
