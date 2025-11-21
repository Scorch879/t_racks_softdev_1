import 'package:flutter/material.dart';
import 'package:t_racks_softdev_1/screens/educator/educator_shell.dart';
import 'package:t_racks_softdev_1/services/educator_service.dart';
import 'package:t_racks_softdev_1/services/educator_notification_service.dart';

class EducatorViewModel {
  // Navigation Logic
  static void navigateToHomeScreen(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const EducatorShell(initialIndex: 0),
      ),
    );
  }

  static void navigateToClassesScreen(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const EducatorShell(initialIndex: 1),
      ),
    );
  }

  static Future<void> onNotificationsPressed(BuildContext context) async {
    final notifications = await getNotifications();
    if (context.mounted) {
      EducatorNotificationService.show(context, notifications);
    }
  }

  static void handleNavigationTap(BuildContext context, int index) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => EducatorShell(initialIndex: index),
      ),
    );
  }

  // Data Fetching Logic
  static Future<List<Map<String, dynamic>>> getClasses() async {
    return await EducatorService.getClasses();
  }

  static Future<List<Map<String, dynamic>>> getNotifications() async {
    return await EducatorService.getNotifications();
  }

  static Future<Map<String, String>> getAttendanceSummary() async {
    return await EducatorService.getAttendanceSummary();
  }

  // Business Logic
  static List<Map<String, String>> filterStudents(
      List<Map<String, String>> students, String query) {
    if (query.isEmpty) {
      return students;
    }
    return students
        .where((student) =>
            (student['name'] ?? '').toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
}
