// 1. The main model for Students viewing their classes
class StudentClass {
  final String id;
  final String? name;
  final String? subject;
  final String? schedule;
  final String? day;
  final String? time;
  final String? status;
  final String? classCode;
  final String? todaysAttendance;
  final int studentCount;

  StudentClass({
    required this.id,
    this.name,
    this.subject,
    this.day,
    this.time,
    this.schedule,
    this.status,
    this.classCode,
    this.todaysAttendance,
    this.studentCount = 0,
  });

  factory StudentClass.fromJson(Map<String, dynamic> json) {
    final day = json['day'] as String?;
    final time = json['time'] as String?;
    String? scheduleString;

    if (day != null && time != null) {
      scheduleString = '$day $time';
    }

    return StudentClass(
      id: json['id'] as String,
      name: json['class_name'] as String?,
      subject: json['subject'] as String?,
      day: day,
      time: time,
      schedule: scheduleString,
      status: json['status'] as String?,
      classCode: json['class_code'] as String?,
      todaysAttendance: json['todays_attendance']?.toString(),
      studentCount: json['student_count'] as int? ?? 0,
    );
  }
}

// 2. The summary model for Educators viewing their list of classes
class EducatorClassSummary {
  final String id;
  final String className;
  final String subject;
  final String schedule;
  final String status;
  final int studentCount;
  final String rawDay;
  final String rawTime;

  EducatorClassSummary({
    required this.id,
    required this.className,
    required this.subject,
    required this.schedule,
    required this.status,
    required this.studentCount,
    required this.rawDay,
    required this.rawTime,
  });
}

// 3. The model for a student inside a specific class (for Attendance)
class StudentAttendanceItem {
  final String id;
  final String name;
  final String status; // 'Present', 'Absent', or 'Mark Attendance'
  final bool isLate;

  StudentAttendanceItem({
    required this.id,
    required this.name,
    required this.status,
    this.isLate = false,
  });
}