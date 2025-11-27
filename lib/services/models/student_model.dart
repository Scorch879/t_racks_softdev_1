import 'package:t_racks_softdev_1/services/models/profile_model.dart';

class Student {
  final Profile? profile;
  final String? birthDate;
  final int age;
  final String? gender;
  final String? institution;
  final String? program;
  final String? educationalLevel;
  final String? gradeYearLevel;

  Student({
    required this.profile,
    this.birthDate,
    required this.age,
    this.gender,
    this.institution,
    this.program,
    this.educationalLevel,
    this.gradeYearLevel,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    // The 'student_data' key comes from our Supabase query alias
    final studentMap = json['student_data'] as Map<String, dynamic>?;
    if (studentMap == null) {
      throw Exception('Student data not found in JSON');
    }

    return Student(
      // The base profile is at the root of the JSON
      profile: Profile.fromJson(json),
      // The student-specific data is nested
      birthDate: studentMap['birthData'] as String?,
      age: studentMap['age'] as int,
      gender: studentMap['gender'] as String?,
      institution: studentMap['institution'] as String?,
      program: studentMap['program'] as String?,
      educationalLevel: studentMap['educationalLevel'] as String?,
      gradeYearLevel: studentMap['gradeYearLevel'] as String?,
    );
  }

  // Helper to get full name
  String get fullName {
    return '${profile?.firstName} ${profile?.lastName}';
  }
}