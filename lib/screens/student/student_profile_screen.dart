import 'package:flutter/material.dart';
import 'package:t_racks_softdev_1/screens/student/student_profile_content.dart';
import 'package:t_racks_softdev_1/services/database_service.dart';
import 'package:t_racks_softdev_1/services/models/student_model.dart';

// const _bgTeal = Color(0xFF167C94); // This constant is not used

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  late final Future<Student?> _studentDataFuture;
  final _databaseService = DatabaseService();

  @override
  void initState() {
    super.initState();
    // Fetch the student data when the screen is first initialized.
    _studentDataFuture = _databaseService.getStudentData();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? const Color(0xFF071E29) : Colors.white;
    final primaryTextColor = isDarkMode
        ? Colors.white
        : const Color(0xFF1A2B3C);
    final accentColor = isDarkMode
        ? const Color(0xFF93C0D3)
        : const Color(0xFF167C94);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: FutureBuilder<Student?>(
        future: _studentDataFuture,
        builder: (context, snapshot) {
          // 1. While data is loading, show a spinner.
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: accentColor));
          }

          // 2. If an error occurred during fetching.
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: TextStyle(color: primaryTextColor),
              ),
            );
          }

          // 3. If no data was returned (profile not found or not a student).
          if (!snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Text(
                'No student profile data found.',
                style: TextStyle(color: primaryTextColor),
              ),
            );
          }

          // 4. If data is available, build the profile content.
          final student = snapshot.data!;
          return LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final scale = (width / 430).clamp(0.8, 1.6);
              return StudentProfileContent(student: student, scale: scale);
            },
          );
        },
      ),
    );
  }
}
