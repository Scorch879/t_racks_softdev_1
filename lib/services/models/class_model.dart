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

    return StudentClass(
      id: json['id'] as String,
      name: json['class_name'] as String?,
      subject: json['subject'] as String?,
      day: day,
      time: time,
      schedule: scheduleString,
      status: json['status'] as String?,
    );
  }
}