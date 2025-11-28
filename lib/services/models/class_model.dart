class StudentClass {
  final String id;
  final String? name;
  final String? subject;
  final String? schedule;
  final String? day;
  final String? time;
  final String? status;

  StudentClass({
    required this.id,
    this.name,
    this.subject,
    this.day,
    this.time,
    this.schedule,
    this.status,
  });

  factory StudentClass.fromJson(Map<String, dynamic> json) {
    final day = json['day'] as String?;
    final time = json['time'] as String?;
    String? scheduleString;

    if (day != null && time != null) {
      scheduleString = '$day $time';
    }

    // Determine status from Attendance_Record
    String derivedStatus;
    // The RPC returns a single JSON object for today's attendance, or null.
    final todaysRecord = json['Attendance_Record'] as Map<String, dynamic>?;

    if (todaysRecord != null) {
      derivedStatus = (todaysRecord['isPresent'] as bool? ?? false) ? 'Present' : 'Absent';
    } else {
      derivedStatus = 'Upcoming'; // If no record for today, it's upcoming.
    }

    return StudentClass(
      id: json['id'] as String,
      name: json['class_name'] as String?,
      subject: json['subject'] as String?,
      day: day,
      time: time,
      schedule: scheduleString,
      status: derivedStatus,
    );
  }
}