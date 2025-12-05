import 'package:flutter/material.dart';
import 'package:t_racks_softdev_1/services/models/class_model.dart';
import 'package:t_racks_softdev_1/services/models/notification_model.dart';
import 'package:t_racks_softdev_1/services/database_service.dart';
import 'package:intl/intl.dart';

class InAppNotificationService extends ChangeNotifier {
  static final InAppNotificationService _instance =
      InAppNotificationService._internal();
  factory InAppNotificationService() => _instance;
  InAppNotificationService._internal();

  final List<AppNotification> _notifications = [];
  List<AppNotification> get notifications => List.unmodifiable(_notifications);

  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  final Set<String> _generatedAlerts = {};

  // DEBUG: Generates a fake alert to test the UI and if it works
  void generateTestNotification() {
    final testNote = AppNotification(
      id: "test_${DateTime.now().millisecondsSinceEpoch}",
      title: "Test Notification",
      message: "This is a test to verify the bell icon works.",
      timestamp: DateTime.now(),
    );
    _notifications.insert(0, testNote);
    notifyListeners();
  }

  Future<void> checkClassesForAlerts() async {
    print("🔍 Checking for upcoming classes...");

    final classes = await DatabaseService().getStudentClasses();
    final now = DateTime.now();
    final todayName = DateFormat('EEE').format(now);

    print(
      "📅 Today is: $todayName, Time: ${DateFormat.jm().format(now)}",
    ); //for debugging

    for (var sClass in classes) {
      if (!_isClassToday(sClass.day, todayName)) {
        continue;
      }

      final startTime = _parseStartTime(sClass.time);

      if (startTime == null) {
        print("   ⚠️ Could not parse time: ${sClass.time}"); // for debug
        continue;
      }

      final classDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        startTime.hour,
        startTime.minute,
      );

      final difference = classDateTime.difference(now).inMinutes;
      print(
        " - Found Today: ${sClass.name} starts in $difference mins",
      ); //for debugging

      // Notify if class starts in 0-60 mins OR if it started less than 15 mins ago
      if (difference > -15 && difference <= 60) {
        _addNotificationIfNotExists(sClass, difference);
      }
    }
  }

  bool _isClassToday(String? classDays, String todayName) {
    if (classDays == null) return false;
    String code = "";
    switch (todayName) {
      case "Mon":
        code = "M";
        break;
      case "Tue":
        code = "T";
        break;
      case "Wed":
        code = "W";
        break;
      case "Thu":
        code = "Th";
        break;
      case "Fri":
        code = "F";
        break;
      case "Sat":
        code = "S";
        break;
      case "Sun":
        code = "Su";
        break;
    }
    return classDays.contains(code);
  }

  // --- UPDATED PARSER ---
  TimeOfDay? _parseStartTime(String? timeStr) {
    if (timeStr == null) return null;
    try {
      // 1. Split range "6:10 am-10:05 AM" -> "6:10 am"
      // Using regex to handle "-" with or without spaces
      final parts = timeStr.split(RegExp(r'\s*-\s*'));
      String startPart = parts[0].trim();

      // 2. Clean & Normalize
      startPart = startPart.replaceAll(
        '\u00A0',
        ' ',
      ); // Remove non-breaking space
      startPart = startPart.replaceAll('.', ''); // Remove dots (a.m. -> am)
      startPart = startPart.toUpperCase(); // "6:10 am" -> "6:10 AM"

      DateTime date;
      try {
        // Try Standard Format "6:10 AM"
        date = DateFormat("h:mm a").parse(startPart);
      } catch (e) {
        try {
          // Try Compact Format "6:10AM"
          date = DateFormat("h:mma").parse(startPart);
        } catch (e2) {
          // Try 24-Hour Format "18:10"
          date = DateFormat("HH:mm").parse(startPart);
        }
      }

      return TimeOfDay.fromDateTime(date);
    } catch (e) {
      print("   ❌ Parse Error for '$timeStr': $e"); //debugging
      return null;
    }
  }

  void _addNotificationIfNotExists(StudentClass sClass, int minutesLeft) {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final alertKey = "${sClass.id}_$todayStr";

    if (!_generatedAlerts.contains(alertKey)) {
      String msg = minutesLeft > 0
          ? "Starts in $minutesLeft minutes."
          : "Started ${minutesLeft.abs()} minutes ago.";

      final newNotification = AppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: "${sClass.name} is Upcoming",
        message: msg,
        timestamp: DateTime.now(),
      );

      _notifications.insert(0, newNotification);
      _generatedAlerts.add(alertKey);
      notifyListeners();
      print("   ✅ Notification Added for ${sClass.name}!");
    }
  }

  void markAsRead() {
    for (var n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();
  }

  void dismissNotification(String id) {
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();
  }
}
