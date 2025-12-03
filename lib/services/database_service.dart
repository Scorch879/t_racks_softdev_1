import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:t_racks_softdev_1/services/models/educator_model.dart';
import 'package:t_racks_softdev_1/services/models/profile_model.dart';
import 'package:t_racks_softdev_1/services/models/attendance_model.dart';
import 'package:t_racks_softdev_1/services/models/class_model.dart';
import 'package:t_racks_softdev_1/services/models/student_model.dart';
import 'package:collection/collection.dart';
import 'dart:math';

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

      // 1. Fetch all classes the student is enrolled in.
      final classData = await _supabase
          .from('Enrollments_Table')
          .select('*, class:Classes_Table!inner(*, student_count:Enrollments_Table(count))')
          .eq('student_id', userId);

      if (classData.isEmpty) return [];

      // 2. Get today's attendance records for this student for all their classes.
      final today = DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD
      final classIds = classData.map((c) => c['class']['id']).toList();

      final attendanceData = await _supabase
          .from('Attendance_Record')
          .select('class_id, isPresent')
          .eq('student_id', userId)
          .eq('date', today)
          .inFilter('class_id', classIds);

      // 3. Combine the data.
      final classesWithAttendance = (classData as List).map((enrollmentJson) {
        // The class data is now nested under the 'class' key.
        final classJson = enrollmentJson['class'];
        if (classJson == null) return null; // Skip if class data is missing

        final attendanceRecord = attendanceData.firstWhereOrNull(
          (att) => att['class_id'] == classJson['id'],
        );
        // Add the attendance status to the JSON before parsing.
        classJson['todays_attendance'] = attendanceRecord?['isPresent']; // will be true, false, or null
        
        // The student count is now nested inside the class data.
        final countList = classJson['student_count'] as List?;
        classJson['student_count'] = countList?.firstOrNull?['count'] ?? 0;
        return StudentClass.fromJson(classJson);
      }).whereType<StudentClass>().toList(); // Filter out any nulls

      return classesWithAttendance;
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

      // 1. Updated Select Query: Added 'day' and 'time'
      final response = await _supabase
          .from('Classes_Table')
          .select('id, class_name, subject, status, day, time')
          .eq('educator_id', userId);

      List<EducatorClassSummary> classes = [];

      for (var row in response) {
        final countResponse = await _supabase
            .from('Enrollments_Table')
            .select('student_id')
            .eq('class_id', row['id']);

        // 2. Combine Day and Time into one string
        String day = row['day'] ?? '';
        String time = row['time'] ?? '';
        String fullSchedule = "$day $time".trim();

        classes.add(
          EducatorClassSummary(
            id: row['id'],
            className: row['class_name'] ?? 'Unnamed Class',
            subject: row['subject'] ?? '',
            status: row['status'] ?? 'Active',
            schedule: fullSchedule, // Use the combined string
            studentCount: countResponse.length,
            rawDay: day,
            rawTime: time,
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

  ///Classes related functions especially class code
  String _generateClassCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(
        6,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  Future<void> createClass({
    required String className,
    required String subject,
    required String day,
    required String time,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw 'User not logged in';
      String classCode = _generateClassCode();
      final newClass = {
        'educator_id': userId,
        'class_name': className,
        'subject': subject,
        'day': day,
        'time': time,
        'status': 'Active', // Default status
        'class_code': classCode,
      };

      await _supabase.from('Classes_Table').insert(newClass);
    } catch (e) {
      print('Error creating class: $e');
      rethrow;
    }
  }

  Future<List<Map<String, String>>> getAvailableStudents(String classId) async {
  try {
    // 1. Get IDs of students ALREADY in the class
    final enrolledRes = await _supabase
        .from('Enrollments_Table')
        .select('student_id')
        .eq('class_id', classId);
    
    final enrolledIds = (enrolledRes as List).map((e) => e['student_id']).toList();

    // 2. Fetch profiles using an INNER JOIN on Student_Table
    // The '!inner' keyword ensures we ONLY get users who exist in Student_Table
    var query = _supabase
        .from('profiles')
        .select('id, firstName, lastName, Student_Table!inner(id)'); // <--- CHANGED THIS LINE

    if (enrolledIds.isNotEmpty) {
      query = query.not('id', 'in', enrolledIds);
    }

    final res = await query;

    return (res as List).map((profile) {
      return {
        'id': profile['id'].toString(), 
        'name': "${profile['firstName']} ${profile['lastName']}",
        'subtitle': 'Student', 
      };
    }).toList();
  } catch (e) {
    print('Error fetching available students: $e');
    return [];
  }
}

Future<void> enrollStudent({
  required String classId,
  required String studentId,
}) async {
  try {
    await _supabase.from('Enrollments_Table').insert({
      'class_id': classId,
      'student_id': studentId,
      'enrollment_date': DateTime.now().toIso8601String(),
    });
  } catch (e) {
    print('Error enrolling student: $e');
    rethrow;
  }
}

  Future<List<AttendanceRecord>> getStudentAttendanceForClass(
      String classId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw 'User not logged in';

      final data = await _supabase
          .from('Attendance_Record')
          .select('id, student_id, class_id, date, isPresent, time')
          .eq('class_id', classId)
          .eq('student_id', userId)
          .order('date', ascending: false); // Show most recent first

      return (data as List)
          .map((item) => AttendanceRecord.fromJson(item))
          .toList();
    } catch (e) {
      print('Error fetching student attendance: $e');
      return [];
    }
  }

  /// Fetches the number of absences for the current student for the current week.
  Future<int> getAbsencesThisWeek() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw 'User not logged in';

      // Calculate the start and end of the current week (assuming Monday is the first day)
      final now = DateTime.now();
      final daysToSubtract = now.weekday - 1; // Monday is 1, so subtract 0. Sunday is 7, so subtract 6.
      final startOfWeek = now.subtract(Duration(days: daysToSubtract));
      final endOfWeek = startOfWeek.add(const Duration(days: 6)); // Monday + 6 days = Sunday

      // Format dates to 'YYYY-MM-DD' for the query
      final startDateString = startOfWeek.toIso8601String().split('T')[0];
      final endDateString = endOfWeek.toIso8601String().split('T')[0];

      // Query for absences within the date range
      final count = await _supabase
          .from('Attendance_Record')
          .count(CountOption.exact)
          .eq('student_id', userId)
          .eq('isPresent', false)
          .gte('date', startDateString)
          .lte('date', endDateString);

      return count;
    } catch (e) {
      print('Error fetching absences this week: $e');
      return 0; // Return 0 on error to prevent UI from breaking
    }
  }

  /// Checks for classes that have ended today where attendance was not marked,
  /// and marks the student as absent.
  Future<void> markMissedClassesAsAbsent() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final now = DateTime.now();
      final today = now.toIso8601String().split('T')[0];

      // 1. Get all of today's attendance records for the user.
      final attendanceData = await _supabase
          .from('Attendance_Record')
          .select('class_id')
          .eq('student_id', userId)
          .eq('date', today);

      final attendedClassIds =
          (attendanceData as List).map((e) => e['class_id']).toList();

      // 2. Get all classes the user is enrolled in.
      final enrolledClassesData = await _supabase
          .from('Enrollments_Table')
          .select('class:Classes_Table!inner(id, day, time)')
          .eq('student_id', userId);

      final classesToInsert = <Map<String, dynamic>>[];

      for (final enrollment in enrolledClassesData) {
        final sClass = enrollment['class'];
        if (sClass == null) continue;

        final classId = sClass['id'];
        final scheduleDay = sClass['day']?.toString().toLowerCase();
        final timeRangeStr = sClass['time']?.toString();

        // Skip if already attended or if schedule is invalid
        if (attendedClassIds.contains(classId) ||
            scheduleDay == null ||
            timeRangeStr == null) {
          continue;
        }

        // Check if the class was scheduled for today and has ended
        if (_isClassDoneForToday(scheduleDay, timeRangeStr, now)) {
          classesToInsert.add({
            'student_id': userId,
            'class_id': classId,
            'date': today,
            'isPresent': false,
            'time': DateFormat.Hms().format(now), // Record time of auto-marking
          });
        }
      }

      // 3. Batch insert all absence records.
      if (classesToInsert.isNotEmpty) {
        print('Auto-marking ${classesToInsert.length} classes as absent.');
        await _supabase.from('Attendance_Record').insert(classesToInsert);
      }
    } catch (e) {
      // We don't rethrow here to avoid crashing the UI.
      // The main data fetch will proceed, and this can try again next time.
      print('Error during auto-marking absences: $e');
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

// Helper function to parse time strings (e.g., "10:00 AM") into DateTime objects.
DateTime? _parseTimeHelper(String timeStr, DateTime now) {
  try {
    final isPM = timeStr.toLowerCase().contains('pm');
    final timeOnly =
        timeStr.replaceAll(RegExp(r'(am|pm)', caseSensitive: false), '').trim();
    final parts = timeOnly.split(':');
    if (parts.length < 2) return null;

    var hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);

    if (hour == null || minute == null) return null;

    if (isPM && hour < 12) {
      hour += 12;
    } else if (!isPM && hour == 12) {
      // Handle 12 AM (midnight)
      hour = 0;
    }

    return DateTime(now.year, now.month, now.day, hour, minute);
  } catch (e) {
    return null;
  }
}

/// Helper function to determine if a class has finished for today.
bool _isClassDoneForToday(String scheduleDay, String timeRangeStr, DateTime now) {
  const dayMappings = {'m': 1, 't': 2, 'w': 3, 'th': 4, 'f': 5, 's': 6, 'su': 7};
  final todayWeekday = now.weekday;

  // Check if the class is scheduled for today
  bool isToday = scheduleDay.split('').any((char) => dayMappings[char] == todayWeekday);
  if (!isToday) return false;

  // Check if the class time has passed
  final timeParts = timeRangeStr.split('-');
  if (timeParts.length < 2) return false;
  final classEndTime = _parseTimeHelper(timeParts[1].trim(), now);

  return classEndTime != null && now.isAfter(classEndTime);
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

class AiServices {
  Future<void> saveFace() async {
    try {
      final userId = _supabase.auth.currentUser?.id;

      if (userId == null) {
        throw 'User is not logged in';
      }

      // AI content generation logic goes here
    } catch (e) {
      throw 'Error generating content: $e';
    }
  }
}