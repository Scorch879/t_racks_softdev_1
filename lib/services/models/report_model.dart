class DashboardData {
  final String overallAttendance;
  final String presentToday;
  final List<ClassMetric> classMetrics;
  final List<AttendanceAlert> alerts;
  final List<GraphPoint> trendData;

  DashboardData({
    required this.overallAttendance,
    required this.presentToday,
    required this.classMetrics,
    required this.alerts,
    required this.trendData,
  });
}

class ClassMetric {
  final String className;
  final int totalStudents;
  final int presentCount;
  final double percentage;

  ClassMetric({
    required this.className,
    required this.totalStudents,
    required this.presentCount,
    required this.percentage,
  });
}

class AttendanceAlert {
  final String title;
  final String message;
  final bool isCritical;

  AttendanceAlert({
    required this.title,
    required this.message,
    required this.isCritical,
  });
}

class GraphPoint {
  final DateTime date;
  final double percentage;

  GraphPoint(this.date, this.percentage);
}
