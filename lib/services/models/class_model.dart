class StudentClass {
  final String id;
  final String? name;
  final String? subject;
  final String? schedule; // e.g., "MWF 10:00 AM - 11:00 AM"
  final String? status;

  StudentClass({
    required this.id,
    this.name,
    this.subject,
    this.schedule,
    this.status,
  });

  factory StudentClass.fromJson(Map<String, dynamic> json) {
    return StudentClass(
      id: json['id'] as String,
      // Use the column names from your database schema
      name: json['class_name'] as String?,
      subject: json['subject'] as String?,
      schedule: json['schedule'] as String?,
      status: json['status'] as String?,
    );
  }
}