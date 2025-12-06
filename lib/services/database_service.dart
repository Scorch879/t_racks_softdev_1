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

class DatabaseService {
  //Profile Checker Service
  Future<bool> checkProfileExists() async {
    try {
      final userId = _supabase.auth.currentUser?.id;

      if (userId == null) {
        throw 'User is not logged in';
      }

      await _supabase.from('profiles').select('id').eq('id', userId).single();
      return true;
    } catch (e) {
      return false;
    }
  }

  // --- Fetch functions ---

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
      print("Error getting profile: $e");
      return null;
    }
  }

  Future<Student?> getStudentData() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw 'User not logged in';

      final data = await _supabase
          .from('profiles')
          .select('*, student_data:Student_Table(*)')
          .eq('id', userId)
          .single();

      final userEmail = _supabase.auth.currentUser?.email;
      if (userEmail != null) {
        data['email'] = userEmail;
      }

      return Student.fromJson(data);
    } catch (e) {
      print('Error fetching student data: $e');
      return null;
    }
  }

  Future<List<StudentClass>> getStudentClasses() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw 'User not logged in';

      final response = await _supabase.rpc(
        'get_student_classes_with_details',
        params: {'p_student_id': userId},
      );

      if (response == null || response.isEmpty) {
        return [];
      }

      final classesWithAttendance = (response as List)
          .map((classJson) => StudentClass.fromJson(classJson))
          .toList();

      return classesWithAttendance;
    } catch (e) {
      print('Error fetching student classes: $e');
      rethrow;
    }
  }

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

  // --- Update functions ---

  Future<void> updateStudentData({
    required String firstName,
    required String lastName,
    required String? institution,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw 'User not logged in';

      final profileUpdate = {'firstName': firstName, 'lastName': lastName};
      await _supabase.from('profiles').update(profileUpdate).eq('id', userId);

      final studentUpdate = {'institution': institution};
      await _supabase
          .from('Student_Table')
          .update(studentUpdate)
          .eq('id', userId);
    } catch (e) {
      print('Error updating student data: $e');
      rethrow;
    }
  }

  Future<Educator?> getEducatorData() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw 'User not logged in';

      final data = await _supabase
          .from('profiles')
          .select('*, educator_data:Educator_Table(*)')
          .eq('id', userId)
          .single();

      return Educator.fromJson(data);
    } catch (e) {
      print('Error fetching educator data: $e');
      return null;
    }
  }

  Future<List<EducatorClassSummary>> getEducatorClasses() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw 'User not logged in';

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

        String day = row['day'] ?? '';
        String time = row['time'] ?? '';
        String fullSchedule = "$day $time".trim();

        classes.add(
          EducatorClassSummary(
            id: row['id'],
            className: row['class_name'] ?? 'Unnamed Class',
            subject: row['subject'] ?? '',
            status: row['status'] ?? 'Active',
            schedule: fullSchedule,
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

  Future<List<StudentAttendanceItem>> getClassStudents(String classId) async {
    try {
      final enrollmentRes = await _supabase
          .from('Enrollments_Table')
          .select('student_id')
          .eq('class_id', classId);

      if (enrollmentRes.isEmpty) return [];

      final studentIds = (enrollmentRes as List)
          .map((e) => e['student_id'])
          .toList();

      final profilesRes = await _supabase
          .from('profiles')
          .select('id, firstName, lastName')
          .inFilter('id', studentIds);

      final today = DateTime.now().toIso8601String().split('T')[0];
      final attendanceRes = await _supabase
          .from('Attendance_Record')
          .select('student_id, isPresent')
          .eq('class_id', classId)
          .eq('date', today);

      List<StudentAttendanceItem> students = [];

      for (var profile in profilesRes) {
        final sId = profile['id'];
        final fullName = "${profile['firstName']} ${profile['lastName']}";

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

  // --- Classes related functions ---

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
        'status': 'Active',
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
      final enrolledRes = await _supabase
          .from('Enrollments_Table')
          .select('student_id')
          .eq('class_id', classId);

      final enrolledIds = (enrolledRes as List)
          .map((e) => e['student_id'])
          .toList();

      var query = _supabase
          .from('profiles')
          .select('id, firstName, lastName, Student_Table!inner(id)');

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

    return _supabase
        .from('Enrollments_Table')
        .stream(primaryKey: ['id'])
        .eq('student_id', userId)
        .asyncMap((enrollments) async {
          if (enrollments.isEmpty) return [];

          final classIds = enrollments.map((e) => e['class_id']).toList();

          final response = await _supabase
              .from('Classes_Table')
              .select()
              .inFilter('id', classIds);

          return (response as List)
              .map((data) => StudentClass.fromJson(data))
              .toList();
        });
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

  Future<void> enrollInClassWithCode(String classCode) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw 'You must be logged in to join a class.';

      final classResponse = await _supabase
          .from('Classes_Table')
          .select('id, educator_id, class_name')
          .eq('class_code', classCode.trim().toUpperCase())
          .single();

      final classId = classResponse['id'];
      final educatorId = classResponse['educator_id'];
      final className = classResponse['class_name'];

      final enrollmentCheck = await _supabase
          .from('Enrollments_Table')
          .select()
          .eq('student_id', userId)
          .eq('class_id', classId)
          .maybeSingle();

      if (enrollmentCheck != null) {
        throw 'You are already enrolled in this class.';
      }

      await enrollStudent(classId: classId, studentId: userId);

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

  Future<void> _sendJoinNotification({
    required String studentId,
    required String educatorId,
    required String className,
  }) async {
    try {
      final profile = await _supabase
          .from('profiles')
          .select('firstName, lastName')
          .eq('id', studentId)
          .single();

      final name = "${profile['firstName']} ${profile['lastName']}";

      await _supabase.from('Notification_Table').insert({
        'user_id': educatorId,
        'title': 'New Student Enrolled',
        'subtitle': '$name has joined $className.',
        'timestamp': DateTime.now().toIso8601String(),
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
          .order('date', ascending: false);

      return (data as List)
          .map((item) => AttendanceRecord.fromJson(item))
          .toList();
    } catch (e) {
      print('Error fetching student attendance: $e');
      return [];
    }
  }

  Future<int> getAbsencesThisWeek() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw 'User not logged in';

      final now = DateTime.now();
      final daysToSubtract = now.weekday - 1;
      final startOfWeek = now.subtract(Duration(days: daysToSubtract));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));

      final startDateString = startOfWeek.toIso8601String().split('T')[0];
      final endDateString = endOfWeek.toIso8601String().split('T')[0];

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
      return 0;
    }
  }

  Future<void> markMissedClassesAsAbsent() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final now = DateTime.now();
      final today = now.toIso8601String().split('T')[0];

      final attendanceData = await _supabase
          .from('Attendance_Record')
          .select('class_id')
          .eq('student_id', userId)
          .eq('date', today);

      final attendedClassIds = (attendanceData as List)
          .map((e) => e['class_id'])
          .toList();

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

        if (attendedClassIds.contains(classId) ||
            scheduleDay == null ||
            timeRangeStr == null) {
          continue;
        }

        if (_isClassDoneForToday(scheduleDay, timeRangeStr, now)) {
          classesToInsert.add({
            'student_id': userId,
            'class_id': classId,
            'date': today,
            'isPresent': false,
            'time': DateFormat.Hms().format(now),
          });
        }
      }

      if (classesToInsert.isNotEmpty) {
        print('Auto-marking ${classesToInsert.length} classes as absent.');
        await _supabase.from('Attendance_Record').insert(classesToInsert);
      }
    } catch (e) {
      print('Error during auto-marking absences: $e');
    }
  }

  Future<List<AppNotification>> getPersistentNotifications() async {
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
          classMetrics: [],
          alerts: [],
          trendData: [],
        );
      }

      final enrollmentsResponse = await _supabase
          .from('Enrollments_Table')
          .select('class_id')
          .inFilter('class_id', classIds);

      final todayAttendanceResponse = await _supabase
          .from('Attendance_Record')
          .select('class_id, isPresent')
          .inFilter('class_id', classIds)
          .eq('date', todayStr);

      final thirtyDaysAgo = DateFormat(
        'yyyy-MM-dd',
      ).format(DateTime.now().subtract(const Duration(days: 30)));

      final recentHistoryResponse = await _supabase
          .from('Attendance_Record')
          .select('date, isPresent')
          .inFilter('class_id', classIds)
          .gte('date', thirtyDaysAgo)
          .order('date', ascending: true);

      Map<String, List<bool>> dailyStats = {};

      for (var record in recentHistoryResponse) {
        final dateKey = record['date'].toString();
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

      trendData.sort((a, b) => a.date.compareTo(b.date));

      final historyList = recentHistoryResponse as List;
      final totalHistoryPresent = historyList
          .where((r) => r['isPresent'] == true)
          .length;
      final overallPercentage = historyList.isEmpty
          ? 0.0
          : (totalHistoryPresent / historyList.length) * 100;

      final presentTodayCount = (todayAttendanceResponse as List)
          .where((r) => r['isPresent'] == true)
          .length;

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
        classMetrics: classMetrics,
        alerts: alerts,
        trendData: trendData,
      );
    } catch (e) {
      print('Error fetching dashboard data: $e');
      rethrow;
    }
  }

  Future<void> updateEducatorProfile({
    required String firstName,
    required String lastName,
    required String bio,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw 'User not logged in';

      await _supabase
          .from('profiles')
          .update({'firstName': firstName, 'lastName': lastName})
          .eq('id', userId);

      final existingEducator = await _supabase
          .from('Educator_Table')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (existingEducator != null) {
        await _supabase
            .from('Educator_Table')
            .update({'bio': bio})
            .eq('id', userId);
      } else {
        await _supabase.from('Educator_Table').insert({
          'id': userId,
          'bio': bio,
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
    }
  }

  Future<void> markManualAttendance({
    required String classId,
    required String studentId,
    required String status,
  }) async {
    try {
      final date = DateTime.now().toIso8601String().split('T')[0];
      final time = DateFormat.Hms().format(DateTime.now());

      bool isPresent = status != 'Absent';
      bool isLate = status == 'Late';

      final existing = await _supabase
          .from('Attendance_Record')
          .select('id')
          .eq('student_id', studentId)
          .eq('class_id', classId)
          .eq('date', date)
          .maybeSingle();

      if (existing != null) {
        await _supabase
            .from('Attendance_Record')
            .update({'isPresent': isPresent, 'isLate': isLate, 'time': time})
            .eq('id', existing['id']);
      } else {
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
      await _supabase.from('Classes_Table').delete().eq('id', classId);
    } catch (e) {
      print("Error deleting class: $e");
      throw e;
    }
  }

  // --- ATTENDANCE VERIFICATION LOGIC ---

  /// Marks attendance for the student if they have an ongoing class right now.
  /// Returns the className if successful, or null if no class is ongoing.
  Future<String?> markAttendance(String studentId) async {
    try {
      // 1. Find the class currently happening
      final sClass = await _findOngoingClass(studentId);

      if (sClass == null) {
        throw "No class is currently ongoing for your schedule.";
      }

      // 2. Prepare Data
      final now = DateTime.now();
      final date = now.toIso8601String().split('T')[0];
      final time = DateFormat.Hms().format(now);

      // 3. Insert/Update Attendance Record
      await _supabase.from('Attendance_Record').upsert({
        'student_id': studentId,
        'class_id': sClass.id,
        'date': date,
        'time': time,
        'isPresent': true,
      });

      // FIX: Changed className to name (matches StudentClass model)
      return sClass.name;
    } catch (e) {
      print("Error marking attendance: $e");
      rethrow;
    }
  }

  /// Helper to find the first class that is currently 'Ongoing'.
  Future<StudentClass?> _findOngoingClass(String studentId) async {
    final response = await _supabase.rpc(
      'get_student_classes_with_details',
      params: {'p_student_id': studentId},
    );

    final classes = (response as List)
        .map((json) => StudentClass.fromJson(json))
        .toList();

    final now = DateTime.now();
    final todayWeekday = now.weekday;

    return classes.firstWhereOrNull((sClass) {
      final scheduleDay = sClass.day?.toLowerCase().replaceAll(' ', '');
      if (scheduleDay == null || scheduleDay.isEmpty) return false;

      // 1. Check Day
      if (!_isClassScheduledForToday(scheduleDay, todayWeekday)) return false;

      // 2. Check Time
      if (sClass.time == null || !sClass.time!.contains('-')) return false;

      try {
        final timeRange = sClass.time!.split('-');
        final classStartTime = _parseTimeHelper(timeRange[0].trim(), now);
        final classEndTime = _parseTimeHelper(timeRange[1].trim(), now);

        if (classStartTime == null || classEndTime == null) return false;

        // Allow marking attendance 15 mins before start until end time
        final earlyStart = classStartTime.subtract(const Duration(minutes: 15));

        return now.isAfter(earlyStart) && now.isBefore(classEndTime);
      } catch (e) {
        return false;
      }
    });
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

// --- Helper Functions ---

class DynamicStatus {
  final String text;
  final Color color;
  DynamicStatus(this.text, this.color);
}

DynamicStatus getDynamicStatus(
  StudentClass sClass,
  Color green,
  Color red,
  Color orange,
  Color darkBlue,
  Color grey,
) {
  if (sClass.todaysAttendance != null) {
    return sClass.todaysAttendance == true || sClass.todaysAttendance == 'true'
        ? DynamicStatus('Present', green)
        : DynamicStatus('Absent', red);
  }

  final now = DateTime.now();
  final todayWeekday = now.weekday;

  final scheduleDay = sClass.day?.toLowerCase().replaceAll(' ', '');
  if (scheduleDay == null || scheduleDay.isEmpty) {
    return DynamicStatus('No Schedule', grey);
  }

  bool isToday = _isClassScheduledForToday(scheduleDay, todayWeekday);

  if (!isToday) {
    return DynamicStatus('Upcoming', darkBlue);
  }

  if (sClass.time == null || !sClass.time!.contains('-')) {
    return DynamicStatus('Invalid Time', grey);
  }

  try {
    final timeRange = sClass.time!.split('-');
    final classStartTime = _parseTimeHelper(timeRange[0].trim(), now);
    final classEndTime = _parseTimeHelper(timeRange[1].trim(), now);

    if (classStartTime == null || classEndTime == null)
      return DynamicStatus('Invalid Time', grey);
    if (now.isBefore(classStartTime))
      return DynamicStatus('Upcoming', darkBlue);
    if (now.isAfter(classEndTime)) return DynamicStatus('Done', grey);
    if (now.difference(classStartTime).inMinutes > 15)
      return DynamicStatus('Late', orange);
    return DynamicStatus('Ongoing', green);
  } catch (e) {
    return DynamicStatus('Upcoming', darkBlue);
  }
}

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
      hour = 0;
    }

    return DateTime(now.year, now.month, now.day, hour, minute);
  } catch (e) {
    return null;
  }
}

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

  if (fullDayMappings.containsKey(scheduleDay)) {
    return fullDayMappings[scheduleDay] == todayWeekday;
  }

  if (scheduleDay.contains('th') && todayWeekday == 4) return true;
  if (scheduleDay.contains('su') && todayWeekday == 7) return true;

  return scheduleDay
      .split('')
      .any(
        (char) =>
            dayMappings[char] == todayWeekday && char != 'h' && char != 'u',
      );
}

bool _isClassDoneForToday(
  String scheduleDay,
  String timeRangeStr,
  DateTime now,
) {
  final todayWeekday = now.weekday;

  bool isToday = _isClassScheduledForToday(scheduleDay, todayWeekday);
  if (!isToday) return false;

  final timeParts = timeRangeStr.split('-');
  if (timeParts.length < 2) return false;
  final classEndTime = _parseTimeHelper(timeParts[1].trim(), now);

  return classEndTime != null && now.isAfter(classEndTime);
}
