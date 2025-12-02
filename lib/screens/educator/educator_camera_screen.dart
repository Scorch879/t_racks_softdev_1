import 'package:flutter/material.dart';
import 'package:t_racks_softdev_1/screens/student/student_camera_content.dart';

class EducatorCameraScreen extends StatelessWidget {
  final String? classId;
  final String? className;

  const EducatorCameraScreen({
    super.key,
    this.classId,
    this.className,
  });

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: StudentCameraContent(),
    );
  }
}
