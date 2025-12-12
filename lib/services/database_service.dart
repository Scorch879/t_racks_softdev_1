import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:t_racks_softdev_1/services/models/educator_model.dart';
import 'package:t_racks_softdev_1/services/models/profile_model.dart';
import 'package:t_racks_softdev_1/services/models/attendance_model.dart';
import 'package:t_racks_softdev_1/services/models/class_model.dart';
import 'package:t_racks_softdev_1/services/models/student_model.dart';
import 'package:collection/collection.dart';
import 'dart:math';
import 'package:t_racks_softdev_1/services/models/notification_model.dart';
import 'package:t_racks_softdev_1/services/models/report_model.dart';

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

      // Call the RPC function to get all class data, student counts,
      // and today's attendance in a single, efficient database call.
      final response = await _supabase.rpc(
        'get_student_classes_with_details',
        params: {'p_student_id': userId},
      );

      if (response == null || response.isEmpty) {
        return [];
      }

      // The RPC returns a list of flat JSON objects, ready for parsing.
      final classesWithAttendance = (response as List)
          .map((classJson) => StudentClass.fromJson(classJson))
          .toList();

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
    String? institution,
    String? profilePictureUrl,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw 'User not logged in';

      // Add profilePictureUrl to the update map if it's not null
      if (profilePictureUrl != null) {
        await _supabase
            .from('profiles')
            .update({'profile_picture_url': profilePictureUrl})
            .eq('id', userId);
      }

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

  Future<void> updateProfilePicture(String url) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw 'User not logged in';

    await _supabase
        .from('profiles')
        .update({'profile_picture_url': url})
        .eq('id', userId);
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

      final userEmail = _supabase.auth.currentUser?.email;
      if (userEmail != null) {
        data['email'] = userEmail;
      }

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
          .select('student_id, isPresent, isLate') // <-- MODIFIED: Added isLate
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
        bool isLate = false; // Default to not late

        if (record != null) {
          status = record['isPresent'] ? 'Present' : 'Absent';
          // Check for isLate, defaulting to false if null
          isLate = record['isLate'] ?? false;
        }

        students.add(
          StudentAttendanceItem(
            id: sId,
            name: fullName,
            status: status,
            isLate: isLate, // <-- MODIFIED: Pass isLate status
          ),
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

      final enrolledIds = (enrolledRes as List)
          .map((e) => e['student_id'])
          .toList();

      // 2. Fetch profiles using an INNER JOIN on Student_Table
      // The '!inner' keyword ensures we ONLY get users who exist in Student_Table
      var query = _supabase
          .from('profiles')
          .select(
            'id, firstName, lastName, Student_Table!inner(id)',
          ); // <--- CHANGED THIS LINE

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

  Stream<List<StudentClass>> getStudentClassesStream() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return Stream.value([]);

    // 1. Listen to the Enrollments table for this specific student
    return _supabase
        .from('Enrollments_Table')
        .stream(
          primaryKey: ['id'],
        ) // Ensure your Enrollments_Table has a primary key
        .eq('student_id', userId)
        .asyncMap((enrollments) async {
          // 2. When enrollment changes, fetch the actual class details
          if (enrollments.isEmpty) return [];

          final classIds = enrollments.map((e) => e['class_id']).toList();

          // 3. Fetch details from Classes_Table
          final response = await _supabase
              .from('Classes_Table')
              .select()
              .inFilter('id', classIds);

          return (response as List)
              .map((data) => StudentClass.fromJson(data))
              .toList();
        });
  }

  /// Helper to check for schedule conflicts before enrolling a student.
  Future<bool> _hasScheduleConflict(String studentId, String newClassId) async {
    // 1. Get the schedule for the new class.
    final newClassData = await _supabase
        .from('Classes_Table')
        .select('day, time')
        .eq('id', newClassId)
        .single();

    final newClassDay = newClassData['day'] as String?;
    final newClassTime = newClassData['time'] as String?;

    if (newClassDay == null || newClassTime == null) {
      // If the new class has no schedule, it can't conflict.
      return false;
    }

    // 2. Get the schedules for all classes the student is currently enrolled in.
    final enrolledClassesData = await _supabase
        .from('Enrollments_Table')
        .select('class:Classes_Table!inner(day, time)')
        .eq('student_id', studentId);

    // 3. Check for any overlap.
    for (final enrollment in enrolledClassesData) {
      final existingClass = enrollment['class'];
      if (existingClass == null) continue;

      final existingClassDay = existingClass['day'] as String?;
      final existingClassTime = existingClass['time'] as String?;

      if (existingClassDay == null || existingClassTime == null) {
        continue;
      }

      if (_checkOverlap(
        newClassDay,
        newClassTime,
        existingClassDay,
        existingClassTime,
      )) {
        return true; // Conflict found
      }
    }

    return false; // No conflicts
  }

  /// Checks if two class schedules (day and time) overlap.
  bool _checkOverlap(String day1, String time1, String day2, String time2) {
    bool dayConflict = false;
    // Check for any common day of the week.
    for (int i = 1; i <= 7; i++) {
      if (_isClassScheduledForToday(day1, i) &&
          _isClassScheduledForToday(day2, i)) {
        dayConflict = true;
        break;
      }
    }

    if (!dayConflict) {
      return false;
    }

    // Time Overlap Check
    final now = DateTime.now();
    final timeRange1 = time1.split('-');
    final timeRange2 = time2.split('-');

    if (timeRange1.length < 2 || timeRange2.length < 2) {
      return false; // Invalid time format
    }

    final start1 = _parseTimeHelper(timeRange1[0].trim(), now);
    final end1 = _parseTimeHelper(timeRange1[1].trim(), now);
    final start2 = _parseTimeHelper(timeRange2[0].trim(), now);
    final end2 = _parseTimeHelper(timeRange2[1].trim(), now);

    if (start1 == null || end1 == null || start2 == null || end2 == null) {
      return false; // Could not parse times
    }

    // Overlap exists if one class starts before the other ends, AND ends after the other starts.
    return start1.isBefore(end2) && end1.isAfter(start2);
  }

  Future<void> enrollStudent({
    required String classId,
    required String studentId,
  }) async {
    try {
      // SCHEDULE CONFLICT CHECK
      if (await _hasScheduleConflict(studentId, classId)) {
        throw 'Schedule conflict: This student is already busy at this time.';
      }
      // 1. Perform the Enrollment
      await _supabase.from('Enrollments_Table').insert({
        'class_id': classId,
        'student_id': studentId,
        'enrollment_date': DateTime.now().toIso8601String(),
      });

      final classData = await _supabase
          .from('Classes_Table')
          .select('class_name')
          .eq('id', classId)
          .single();

      final className = classData['class_name'];
      await _supabase.from('Notification_Table').insert({
        'user_id': studentId,
        'title': 'You have been enrolled',
        'subtitle': 'An educator has added you to $className.',
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error enrolling student: $e');
      rethrow;
    }
  }

  /// Enrolls the current student in a class using a unique class code.
  ///
  /// Throws an error if the code is invalid or if the student is already enrolled.
  Future<void> enrollInClassWithCode(String classCode) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw 'You must be logged in to join a class.';

      // 1. Find the class ID AND Educator ID from the code [UPDATED]
      final classResponse = await _supabase
          .from('Classes_Table')
          .select('id, educator_id, class_name') // Fetch educator_id too
          .eq('class_code', classCode.trim().toUpperCase())
          .single();

      final classId = classResponse['id'];
      final educatorId = classResponse['educator_id'];
      final className = classResponse['class_name'];

      // SCHEDULE CONFLICT CHECK
      if (await _hasScheduleConflict(userId, classId)) {
        throw 'Schedule conflict: This class overlaps with your existing schedule.';
      }

      // 2. Check if the student is already enrolled.
      final enrollmentCheck = await _supabase
          .from('Enrollments_Table')
          .select()
          .eq('student_id', userId)
          .eq('class_id', classId)
          .maybeSingle();

      if (enrollmentCheck != null) {
        throw 'You are already enrolled in this class.';
      }

      // 3. If not enrolled, create the new enrollment record.
      await enrollStudent(classId: classId, studentId: userId);

      // 4. Send Notification to Educator [NEW]
      // We don't await this so it doesn't block the UI
      _sendJoinNotification(
        studentId: userId,
        educatorId: educatorId,
        className: className,
      );
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        throw 'Invalid class code. Please check the code and try again.';
      }
      rethrow;
    }
  }

  /// Helper to insert notification
  Future<void> _sendJoinNotification({
    required String studentId,
    required String educatorId,
    required String className,
  }) async {
    try {
      // Get student name
      final profile = await _supabase
          .from('profiles')
          .select('firstName, lastName')
          .eq('id', studentId)
          .single();

      final name = "${profile['firstName']} ${profile['lastName']}";

      // Insert notification
      await _supabase.from('Notification_Table').insert({
        'user_id': educatorId,
        'title': 'New Student Enrolled',
        'subtitle': '$name has joined $className.',
        'timestamp': DateTime.now().toIso8601String(),
        // 'isRead': false, // Uncomment if your table has this column
      });
    } catch (e) {
      print("Error sending notification: $e");
    }
  }

  Future<List<AttendanceRecord>> getStudentAttendanceForClass(
    String classId,
  ) async {
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
      final daysToSubtract =
          now.weekday -
          1; // Monday is 1, so subtract 0. Sunday is 7, so subtract 6.
      final startOfWeek = now.subtract(Duration(days: daysToSubtract));
      final endOfWeek = startOfWeek.add(
        const Duration(days: 6),
      ); // Monday + 6 days = Sunday

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

      final attendedClassIds = (attendanceData as List)
          .map((e) => e['class_id'])
          .toList();

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

  // In database_service.dart
  Future<List<AppNotification>> getPersistentNotifications() async {
    // FIX: Use _supabase.auth instead of _auth
    final userId = _supabase.auth.currentUser?.id;

    if (userId == null) return [];

    try {
      final response = await _supabase
          .from('Notification_Table')
          .select()
          .eq('user_id', userId)
          .order('timestamp', ascending: false)
          .limit(20);

      return (response as List).map((row) {
        return AppNotification(
          id: row['id'].toString(),
          title: row['title'] ?? 'Notification',
          message: row['subtitle'] ?? '',
          timestamp: DateTime.parse(row['timestamp']),
          isRead: false,
        );
      }).toList();
    } catch (e) {
      print('Error fetching notifications: $e');
      return [];
    }
  }

  Future<DashboardData> getEducatorDashboardData() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw 'User not logged in';

      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

      // 1. Fetch Classes
      final classesResponse = await _supabase
          .from('Classes_Table')
          .select('id, class_name')
          .eq('educator_id', userId);

      final classes = List<Map<String, dynamic>>.from(classesResponse);
      final classIds = classes.map((c) => c['id']).toList();

      if (classIds.isEmpty) {
        return DashboardData(
          overallAttendance: '0%',
          presentToday: '0',
          absentToday: '0',
          lateToday: '0',
          classMetrics: [],
          alerts: [],
          trendData: [], // Return empty list
        );
      }

      // 2. Fetch Enrollments
      final enrollmentsResponse = await _supabase
          .from('Enrollments_Table')
          .select('class_id')
          .inFilter('class_id', classIds);

      // 3. Fetch Today's Attendance
      final todayAttendanceResponse = await _supabase
          .from('Attendance_Record')
          .select('class_id, isPresent, isLate')
          .inFilter('class_id', classIds)
          .eq('date', todayStr);

      // 4. Fetch History (Last 30 days) - MODIFIED QUERY
      final thirtyDaysAgo = DateFormat(
        'yyyy-MM-dd',
      ).format(DateTime.now().subtract(const Duration(days: 30)));

      final recentHistoryResponse = await _supabase
          .from('Attendance_Record')
          .select('date, isPresent') // <--- NOW FETCHING DATE TOO
          .inFilter('class_id', classIds)
          .gte('date', thirtyDaysAgo)
          .order('date', ascending: true); // Sort by date for the graph

      // --- PROCESSING DATA ---

      // A. Process Graph Data (Group by Date)
      Map<String, List<bool>> dailyStats = {};

      for (var record in recentHistoryResponse) {
        final dateKey = record['date'].toString(); // "2023-10-27"
        final isPresent = record['isPresent'] as bool;

        if (!dailyStats.containsKey(dateKey)) {
          dailyStats[dateKey] = [];
        }
        dailyStats[dateKey]!.add(isPresent);
      }

      List<GraphPoint> trendData = [];
      dailyStats.forEach((dateStr, statusList) {
        final total = statusList.length;
        final present = statusList.where((b) => b).length;
        final percentage = total == 0 ? 0.0 : (present / total) * 100;
        trendData.add(GraphPoint(DateTime.parse(dateStr), percentage));
      });

      // Sort again just to be safe
      trendData.sort((a, b) => a.date.compareTo(b.date));

      // B. Overall Attendance Calculation
      final historyList = recentHistoryResponse as List;
      final totalHistoryPresent = historyList
          .where((r) => r['isPresent'] == true)
          .length;
      final overallPercentage = historyList.isEmpty
          ? 0.0
          : (totalHistoryPresent / historyList.length) * 100;

      // C. Present, Absent, Late Today
      final todayAttendanceList = todayAttendanceResponse as List;
      final presentTodayCount =
          todayAttendanceList.where((r) => r['isPresent'] == true).length;
      final absentTodayCount =
          todayAttendanceList.where((r) => r['isPresent'] == false).length;
      final lateTodayCount =
          todayAttendanceList.where((r) => r['isLate'] == true).length;

      // D. Class Metrics & Alerts (Same as before)
      List<ClassMetric> classMetrics = [];
      List<AttendanceAlert> alerts = [];

      for (var cls in classes) {
        final classId = cls['id'];
        final totalStudents = (enrollmentsResponse as List)
            .where((e) => e['class_id'] == classId)
            .length;
        final presentCount = (todayAttendanceResponse as List)
            .where((r) => r['class_id'] == classId && r['isPresent'] == true)
            .length;

        double percentage = totalStudents == 0
            ? 0
            : (presentCount / totalStudents) * 100;

        classMetrics.add(
          ClassMetric(
            className: cls['class_name'] ?? 'Unknown',
            totalStudents: totalStudents,
            presentCount: presentCount,
            percentage: percentage,
          ),
        );

        if (totalStudents > 0 && percentage < 50) {
          alerts.add(
            AttendanceAlert(
              title: 'Low Attendance Warning',
              message:
                  '${cls['class_name']} attendance is at ${percentage.toStringAsFixed(1)}%',
              isCritical: true,
            ),
          );
        }
      }

      return DashboardData(
        overallAttendance: '${overallPercentage.toStringAsFixed(1)}%',
        presentToday: presentTodayCount.toString(),
        absentToday: absentTodayCount.toString(),
        lateToday: lateTodayCount.toString(),
        classMetrics: classMetrics,
        alerts: alerts,
        trendData: trendData, // <--- Pass the graph data
      );
    } catch (e) {
      print('Error fetching dashboard data: $e');
      rethrow;
    }
  }

  // Replace the entire updateEducatorProfile function with this:
  Future<void> updateEducatorProfile({
    required String firstName,
    required String lastName,
    String? bio,
    String? profilePictureUrl,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw 'User not logged in';

      // Update profile picture URL if provided
      if (profilePictureUrl != null) {
        await _supabase
            .from('profiles')
            .update({'profile_picture_url': profilePictureUrl})
            .eq('id', userId);
      }

      // 1. Update the 'profiles' table (Always safe to update)
      await _supabase
          .from('profiles')
          .update({'firstName': firstName, 'lastName': lastName})
          .eq('id', userId);

      // 2. Check if the Educator row already exists
      final existingEducator = await _supabase
          .from('Educator_Table')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (existingEducator != null) {
        // CASE A: Profile exists -> UPDATE ONLY
        if (bio != null) {
          // We only send 'bio' so we don't accidentally overwrite their real age with a default.
          await _supabase
              .from('Educator_Table')
              .update({'bio': bio})
              .eq('id', userId);
        }
      } else {
        // CASE B: Profile is missing -> INSERT WITH DEFAULTS
        // We MUST provide 'age', 'institution', etc. to satisfy the "Not Null" database rules.
        await _supabase.from('Educator_Table').insert({
          'id': userId,
          'bio': bio,
          // Dummy values to satisfy database constraints:
          'age': 0,
          'institution': 'Not Specified',
          'gender': 'Not Specified',
          'birthDate': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      print('Error updating educator profile: $e');
      rethrow;
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _supabase
          .from('Notification_Table')
          .delete()
          .eq('id', notificationId);
    } catch (e) {
      print('Error deleting notification: $e');
      // We don't rethrow here so the UI doesn't crash on a background sync
    }
  }

  Future<void> markManualAttendance({
    required String classId,
    required String studentId,
    required String status, // 'Present', 'Late', 'Absent'
  }) async {
    try {
      final date = DateTime.now().toIso8601String().split('T')[0];
      final time = DateFormat.Hms().format(DateTime.now());

      bool isPresent = status != 'Absent';
      bool isLate = status == 'Late';

      // Check if record exists for today
      final existing = await _supabase
          .from('Attendance_Record')
          .select('id')
          .eq('student_id', studentId)
          .eq('class_id', classId)
          .eq('date', date)
          .maybeSingle();

      if (existing != null) {
        // Update existing record
        await _supabase
            .from('Attendance_Record')
            .update({'isPresent': isPresent, 'isLate': isLate, 'time': time})
            .eq('id', existing['id']);
      } else {
        // Create new record
        await _supabase.from('Attendance_Record').insert({
          'student_id': studentId,
          'class_id': classId,
          'date': date,
          'isPresent': isPresent,
          'isLate': isLate,
          'time': time,
        });
      }
    } catch (e) {
      print("Error marking manual attendance: $e");
      rethrow;
    }
  }

  Future<void> deleteClass(String classId) async {
    try {
      // Assuming you are using Supabase based on the table screenshot
      await _supabase
          .from('Classes_Table') // Matches your table name
          .delete()
          .eq('id', classId); // Matches your 'id' column

      // Note: If you are not using Supabase, replace the above
      // with your specific delete query (e.g., Firebase or SQL).
    } catch (e) {
      print("Error deleting class: $e");
      throw e;
    }
  }

  Future<Map<String, dynamic>> getAttendanceForReport(String classId) async {
    // 1. Get all student IDs and names for the class by joining through Student_Table
    final studentProfiles = await _supabase
        .from('Enrollments_Table')
        .select('Student_Table!inner(profiles!inner(id, firstName, lastName))')
        .eq('class_id', classId);

    final students = studentProfiles.map((e) {
      // Adjust parsing for the nested structure
      final profile = e['Student_Table']['profiles'];
      return {
        'id': profile['id'],
        'name': '${profile['firstName']} ${profile['lastName']}',
      };
    }).toList();

    if (students.isEmpty) {
      return {
        'students': [],
        'dates': [],
        'attendanceMatrix': {},
      };
    }

    final studentIds = students.map((s) => s['id'] as String).toList();

    // 2. Get all attendance records for these students in this class
    final attendanceRecords = await _supabase
        .from('Attendance_Record')
        .select('student_id, date, isPresent, isLate')
        .eq('class_id', classId)
        .inFilter('student_id', studentIds)
        .order('date', ascending: true);

    // 3. Get a unique, sorted list of all dates
    final dates =
        attendanceRecords.map((r) => r['date'] as String).toSet().toList();
    dates.sort();

    // 4. Create a matrix for easy lookup: Map<studentId, Map<date, status>>
    final attendanceMatrix = <String, Map<String, String>>{};
    for (final student in students) {
      final studentId = student['id'] as String;
      attendanceMatrix[studentId] = {};
    }

    for (final record in attendanceRecords) {
      final studentId = record['student_id'] as String;
      final date = record['date'] as String;
      final isPresent = record['isPresent'] as bool;
      final isLate = record['isLate'] as bool? ?? false;

      String status = 'Absent';
      if (isPresent) {
        status = isLate ? 'Late' : 'Present';
      }
      attendanceMatrix[studentId]![date] = status;
    }

    return {
      'students': students,
      'dates': dates,
      'attendanceMatrix': attendanceMatrix,
    };
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

/// A helper class to hold the calculated status and its corresponding color.
class DynamicStatus {
  final String text;
  final Color color;
  DynamicStatus(this.text, this.color);
}

/// This function is now the single source of truth for determining class status.
DynamicStatus getDynamicStatus(
  StudentClass sClass,
  Color green,
  Color red,
  Color orange,
  Color darkBlue,
  Color grey,
) {
  final now = DateTime.now();
  final todayWeekday = now.weekday; // Monday=1, Sunday=7

  final scheduleDay = sClass.day?.toLowerCase().replaceAll(' ', '');
  if (scheduleDay == null || scheduleDay.isEmpty) {
    return DynamicStatus('No Schedule', grey);
  }

  // Use the robust day checking logic
  bool isToday = _isClassScheduledForToday(scheduleDay, todayWeekday);

  if (!isToday) {
    return DynamicStatus('Upcoming', darkBlue);
  }

  // It is today, let's check the time
  if (sClass.time == null || !sClass.time!.contains('-')) {
    return DynamicStatus('Invalid Time', grey);
  }

  try {
    final timeRange = sClass.time!.split('-');
    final classStartTime = _parseTimeHelper(timeRange[0].trim(), now);
    final classEndTime = _parseTimeHelper(timeRange[1].trim(), now);

    if (classStartTime == null || classEndTime == null)
      return DynamicStatus('Invalid Time', grey);

    // --- CORRECTED LOGIC FOR LIST VIEW ---
    // 1. If attendance has been marked, that is the definitive status.
    if (sClass.todaysAttendance != null) {
      return (sClass.todaysAttendance == true ||
              sClass.todaysAttendance == 'true')
          ? DynamicStatus('Present', green)
          : DynamicStatus('Absent', red);
    }

    // 2. If no attendance is marked yet, determine the live status based on time.
    if (now.isAfter(classStartTime) && now.isBefore(classEndTime)) {
      // Check if the current time is past the late window.
      if (now.difference(classStartTime).inMinutes > 15) {
        return DynamicStatus('Late', orange);
      }
      return DynamicStatus('Ongoing', green);
    }

    // 3. If the class is in the future.
    if (now.isBefore(classStartTime)) {
      return DynamicStatus('Upcoming', darkBlue);
    }

    // 4. If class is over and no attendance was ever marked, it's an absence.
    return DynamicStatus('Absent', red);
  } catch (e) {
    return DynamicStatus('Upcoming', darkBlue);
  }
}

// Helper function to parse time strings (e.g., "10:00 AM") into DateTime objects.
DateTime? _parseTimeHelper(String timeStr, DateTime now) {
  try {
    final isPM = timeStr.toLowerCase().contains('pm');
    final timeOnly = timeStr
        .replaceAll(RegExp(r'(am|pm)', caseSensitive: false), '')
        .trim();
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

/// Helper function to robustly check if a class is scheduled for a given weekday.
bool _isClassScheduledForToday(String scheduleDay, int todayWeekday) {
  const dayMappings = {
    'm': 1,
    't': 2,
    'w': 3,
    'th': 4,
    'f': 5,
    's': 6,
    'su': 7,
  };
  const fullDayMappings = {
    'monday': 1,
    'tuesday': 2,
    'wednesday': 3,
    'thursday': 4,
    'friday': 5,
    'saturday': 6,
    'sunday': 7,
  };

  final lowerScheduleDay = scheduleDay.toLowerCase();

  if (fullDayMappings.containsKey(lowerScheduleDay)) {
    return fullDayMappings[lowerScheduleDay] == todayWeekday;
  }

  // Handle abbreviations like "th" and "su" first to avoid ambiguity
  if (lowerScheduleDay.contains('th') && todayWeekday == 4) return true;
  if (lowerScheduleDay.contains('su') && todayWeekday == 7) return true;

  // Handle single-letter abbreviations, ignoring 'h' and 'u' from 'th'/'su'
  return lowerScheduleDay
      .split('')
      .any(
        (char) =>
            dayMappings[char] == todayWeekday && char != 'h' && char != 'u',
      );
}

/// Helper function to determine if a class has finished for today.
bool _isClassDoneForToday(
  String scheduleDay,
  String timeRangeStr,
  DateTime now,
) {
  final todayWeekday = now.weekday;

  // Check if the class is scheduled for today
  bool isToday = _isClassScheduledForToday(scheduleDay, todayWeekday);
  if (!isToday) return false;

  // Check if the class time has passed
  final timeParts = timeRangeStr.split('-');
  if (timeParts.length < 2) return false;
  final classEndTime = _parseTimeHelper(timeParts[1].trim(), now);

  return classEndTime != null && now.isAfter(classEndTime);
}

class AttendanceService {
  /// Marks attendance for a student for their currently ongoing class.
  ///
  /// Returns the name of the class if successful, otherwise null.
  Future<String?> markAttendance(String studentId) async {
    try {
      // 1. Find the ongoing class for the student.
      final ongoingClass = await _findOngoingClass(studentId);
      if (ongoingClass == null) {
        throw 'No ongoing class found to mark attendance for.';
      }

      // 2. Check if attendance has already been marked for this class today.
      final today = DateTime.now().toIso8601String().split('T')[0];
      final existingRecord = await _supabase
          .from('Attendance_Record')
          .select('id')
          .eq('student_id', studentId)
          .eq('class_id', ongoingClass.id)
          .eq('date', today)
          .maybeSingle();

      if (existingRecord != null) {
        print('Attendance already marked for ${ongoingClass.name} today.');
        return ongoingClass.name; // Already marked, treat as success.
      }

      // 3. Determine if the student is late.
      final status = getDynamicStatus(
        ongoingClass,
        Colors.green, // Dummy color
        Colors.red, // Dummy color
        Colors.orange, // Dummy color
        Colors.blue, // Dummy color
        Colors.grey, // Dummy color
      );
      final bool isLate = status.text == 'Late';

      // 4. Create the new attendance record.
      final attendanceData = {
        'student_id': studentId,
        'class_id': ongoingClass.id,
        'date': today,
        'isPresent': true,
        'time': DateFormat.Hms().format(DateTime.now()),
        'isLate': isLate,
      };

      await _supabase.from('Attendance_Record').insert(attendanceData);
      print(
        'Successfully marked attendance for $studentId in class ${ongoingClass.id}',
      );

      return ongoingClass.name;
    } catch (e) {
      print('Error marking attendance: $e');
      rethrow; // Rethrow to be handled by the UI.
    }
  }

  /// Helper to find the first class that is currently 'Ongoing' or 'Late'.
  Future<StudentClass?> _findOngoingClass(String studentId) async {
    final response = await _supabase.rpc(
      'get_student_classes_with_details',
      params: {'p_student_id': studentId},
    );

    final classes = (response as List)
        .map((json) => StudentClass.fromJson(json))
        .toList();

    return classes.firstWhereOrNull((sClass) {
      final status = getDynamicStatus(
        sClass,
        Colors.green,
        Colors.red,
        Colors.orange,
        Colors.blue,
        Colors.grey,
      );
      // OLD CODE:
      // return status.text == 'Ongoing' || status.text == 'Late';

      // NEW CODE: Allow Present and Absent statuses so the app finds the class
      // A class is only "ongoing" if its status is currently 'Ongoing' or 'Late'.
      // Including 'Present' or 'Absent' causes inconsistencies with the home screen display.
      return status.text == 'Ongoing' || status.text == 'Late';
    });
  }
}
