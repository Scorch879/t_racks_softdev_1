import 'package:flutter/material.dart';
import 'package:t_racks_softdev_1/screens/student/student_profile_content.dart';

const _bgTeal = Color(0xFF167C94);

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final scale = (width / 430).clamp(0.8, 1.6);

        return Scaffold(
          backgroundColor: Colors.white,
          body: StudentProfileContent(scale: scale),
        );
      },
    );
  }
}
