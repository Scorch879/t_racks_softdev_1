class AttendanceRecord {
  final String id;
  final String studentId;
  final String classId;
  final DateTime date;
  final bool isPresent;
  final String? time;
  final bool isLate;

  AttendanceRecord({
    required this.id,
    required this.studentId,
    required this.classId,
    required this.date,
    required this.isPresent,
    this.isLate = false,
    this.time,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      classId: json['class_id'] as String,
      date: DateTime.parse(json['date'] as String),
      isPresent: json['isPresent'] as bool,
      time: json['time'] as String?,
      isLate: json['isLate'] as bool? ?? false,
    );
  }
}