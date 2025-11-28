import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:t_racks_softdev_1/services/models/educator_model.dart';
import 'package:t_racks_softdev_1/services/models/profile_model.dart';
import 'package:t_racks_softdev_1/services/models/attendance_record_model.dart';
import 'package:t_racks_softdev_1/services/models/class_model.dart';
import 'package:t_racks_softdev_1/services/models/student_model.dart';
import 'package:collection/collection.dart';

final _supabase = Supabase.instance.client;

///This service handles all database related operations except for onboarding.
///Onboarding related database operations are handled in onboarding_service.dart

class DatabaseService {
  //Profile Checker Service
  Future<bool> checkProfileExists() async {
    try {
      final userId = _supabase.auth.currentUser?.id;

      if (userId == null) {
        throw 'User is not logged in';
      }

      await _supabase.from('profiles').select('id').eq('id', userId).single();

      //if single() returns with no random ahh errors. Naay profile woohoo
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Fetches the attendance history for a student in a specific class.
  Future<List<AttendanceRecord>> getAttendanceHistory(String classId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw 'User not logged in';

      final data = await _supabase
          .from('Attendance_Record')
          .select()
          .eq('student_id', userId)
          .eq('class_id', classId)
          .order('date', ascending: false); // Show most recent first

      final history = (data as List)
          .map((item) => AttendanceRecord.fromJson(item))
          .toList();

      return history;
    } catch (e) {
      print('Error fetching attendance history: $e');
      rethrow;
    }
  }

  ///
  ///
  ///
  ///Fetch functions right here
  ///
  ///
  ///
  Future<Profile?> getProfile() async {
    try {
      final userId = _supabase.auth.currentUser?.id;

      if (userId == null) {
        throw 'User is not logged in';
      }
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      return Profile.fromJson(data);
    } catch (e) {
      // Return null if profile not found or an error occurs
      print("Error getting profile: $e");
      return null;
    }
  }

  /// Fetches the complete data for a student user.
  Future<Student?> getStudentData() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw 'User not logged in';

      // This query joins 'profiles' with 'Student_Table'.
      // 'student_data:Student_Table(*)' creates a nested object with the alias 'student_data'.
      final data = await _supabase
          .from('profiles')
          .select('*, student_data:Student_Table(*)')
          .eq('id', userId)
          .single();

      // The email is in the auth session, not the profiles table.
      // We add it to the map before parsing the JSON.
      final userEmail = _supabase.auth.currentUser?.email;
      if (userEmail != null) {
        data['email'] = userEmail;
      }

      return Student.fromJson(data);
    } catch (e) {
      // Handle errors, e.g., user is not a student or data is missing.
      print('Error fetching student data: $e');
      return null;
    }
  }

  /// Fetches the classes for the current student.
  Future<List<StudentClass>> getStudentClasses() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw 'User not logged in';

      // Call the RPC function to get classes with today's attendance status.
      final data = await _supabase
          .rpc('get_student_classes_with_attendance', params: {
        'p_student_id': userId,
      });

      final classes = (data as List)
          .map((item) => StudentClass.fromJson(item))
          .toList();
      return classes;
    } catch (e) {
      print('Error fetching student classes: $e');
      rethrow;
    }
  }

  /// Fetches the details for a single class by its ID.
  Future<StudentClass> getClassDetails(String classId) async {
    try {
      final data = await _supabase
          .from('Classes_Table')
          .select()
          .eq('id', classId)
          .single();

      return StudentClass.fromJson(data);
    } catch (e) {
      print('Error fetching class details: $e');
      rethrow;
    }
  }

  ///
  ///
  ///
  ///Update functions right here
  ///
  ///
  ///
  /// Updates the data for a student user in the database.
  Future<void> updateStudentData({
    required String firstName,
    required String lastName,
    required String? institution,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw 'User not logged in';

      // 1. Update the 'profiles' table
      final profileUpdate = {'firstName': firstName, 'lastName': lastName};
      await _supabase.from('profiles').update(profileUpdate).eq('id', userId);

      // 2. Update the 'Student_Table'
      final studentUpdate = {'institution': institution};
      await _supabase
          .from('Student_Table')
          .update(studentUpdate)
          .eq('id', userId);
    } catch (e) {
      // Rethrow the error to be handled by the UI
      print('Error updating student data: $e');
      rethrow;
    }
  }

  /// Marks or updates a student's attendance for a specific class on the current date.
  ///
  /// This uses `upsert` to prevent creating duplicate records for the same student,
  /// in the same class, on the same day.
  ///
  /// Note: For this to work correctly, you should have a UNIQUE constraint
  /// on the combination of (student_id, class_id, date) in your `Attendance_Record` table.
  Future<void> markAttendance({
    required String studentId,
    required String classId,
    required bool isPresent,
  }) async {
    try {
      final attendanceRecord = {
        'student_id': studentId,
        'class_id': classId,
        'date': DateTime.now().toIso8601String(),
        'isPresent': isPresent,
      };

      await _supabase.from('Attendance_Record').upsert(
            attendanceRecord,
            onConflict: 'student_id,class_id,date',
          );
    } catch (e) {
      print('Error marking attendance: $e');
      rethrow;
    }
  }

  /// Fetches the student's attendance status for the current day.
  /// Returns 'Present', 'Absent', or 'Not Recorded'.
  Future<String> getTodaysAttendanceStatus() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return 'Unknown';

      final now = DateTime.now();
      // Set up date range for today
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));

      final data = await _supabase
          .from('Attendance_Record')
          .select('isPresent')
          .eq('student_id', userId)
          .gte('date', today.toIso8601String())
          .lt('date', tomorrow.toIso8601String())
          .order('date', ascending: false) // Get the latest record for the day
          .limit(1)
          .maybeSingle();

      if (data == null) {
        return 'Not Recorded';
      }

      final isPresent = data['isPresent'] as bool?;
      return isPresent == true ? 'Present' : 'Absent';
    } catch (e) {
      print('Error fetching today\'s attendance: $e');
      return 'Error';
    }
  }

  /// Fetches the complete data for an educator user.
  Future<Educator?> getEducatorData() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw 'User not logged in';

      // This query joins 'profiles' with 'Educator_Table'.
      // 'educator_data:Educator_Table(*)' creates a nested object with the alias 'educator_data'.
      final data = await _supabase
          .from('profiles')
          .select('*, educator_data:Educator_Table(*)')
          .eq('id', userId)
          .single();

      return Educator.fromJson(data);
    } catch (e) {
      // Handle errors, e.g., user is not an educator or data is missing.
      print('Error fetching educator data: $e');
      return null;
    }
  }

  Future<List<EducatorClassSummary>> getEducatorClasses() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw 'User not logged in';

      // Fetch classes owned by this educator
      final response = await _supabase
          .from('Classes_Table')
          .select('id, class_name')
          .eq('educator_id', userId);

      List<EducatorClassSummary> classes = [];

      for (var row in response) {
        // Count students in this class using Enrollments_Table
        final countResponse = await _supabase
            .from('Enrollments_Table')
            .select('student_id')
            .eq('class_id', row['id']);

        classes.add(
          EducatorClassSummary(
            id: row['id'],
            className: row['class_name'] ?? 'Unnamed Class',
            studentCount: countResponse.length,
          ),
        );
      }
      return classes;
    } catch (e) {
      print('Error fetching educator classes: $e');
      return [];
    }
  }

  /// 2. Fetch Students for a Class + Today's Attendance Status
  Future<List<StudentAttendanceItem>> getClassStudents(String classId) async {
    try {
      // A. Get IDs of enrolled students
      final enrollmentRes = await _supabase
          .from('Enrollments_Table')
          .select('student_id')
          .eq('class_id', classId);

      if (enrollmentRes.isEmpty) return [];
      print(" Enrollment Count: ${enrollmentRes.length}"); // Is this > 0?
      final studentIds = (enrollmentRes as List)
          .map((e) => e['student_id'])
          .toList();
      print(" Student IDs: $studentIds");
      // B. Get Names from Profiles
      // Note: Make sure 'firstname' and 'lastname' match your DB columns exactly
      final profilesRes = await _supabase
          .from('profiles')
          .select('id, firstName, lastName')
          .inFilter('id', studentIds);
      print(" Profiles Found: ${profilesRes.length}");
      // C. Get Today's Attendance Records
      final today = DateTime.now().toIso8601String().split(
        'T',
      )[0]; // YYYY-MM-DD
      final attendanceRes = await _supabase
          .from('Attendance_Record')
          .select('student_id, isPresent')
          .eq('class_id', classId)
          .eq('date', today);

      // D. Combine Data
      List<StudentAttendanceItem> students = [];

      for (var profile in profilesRes) {
        final sId = profile['id'];
        final fullName = "${profile['firstName']} ${profile['lastName']}";

        // Check if there is an attendance record
        final record = attendanceRes.firstWhereOrNull(
          (r) => r['student_id'] == sId,
        );

        String status = 'Mark Attendance';
        if (record != null) {
          status = record['isPresent'] ? 'Present' : 'Absent';
        }

        students.add(
          StudentAttendanceItem(id: sId, name: fullName, status: status),
        );
      }
      return students;
    } catch (e) {
      print('Error fetching class students: $e');
      return [];
    }
  }
}

class AccountServices {
  Future<void> deleteProfile() async {
    try {
      final userId = _supabase.auth.currentUser?.id;

      if (userId == null) {
        throw 'User is not logged in';
      }

      await _supabase.from('profiles').delete().eq('id', userId);
    } catch (e) {
      throw 'Error deleting profile: $e';
    }
  }
}

class ClassesServices {
  Future<void> createClass() async {
    try {
      final userId = _supabase.auth.currentUser?.id;

      if (userId == null) {
        throw 'User is not logged in';
      }

      // Class creation logic goes here
    } catch (e) {
      throw 'Error creating class: $e';
    }
  }
}

//helper models
class EducatorClassSummary {
  final String id;
  final String className;
  final int studentCount;

  EducatorClassSummary({
    required this.id,
    required this.className,
    required this.studentCount,
  });
}

class StudentAttendanceItem {
  final String id;
  final String name;
  final String status; // 'Present', 'Absent', or 'Mark Attendance'

  StudentAttendanceItem({
    required this.id,
    required this.name,
    required this.status,
  });
}
