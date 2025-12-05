import 'dart:async'; // Required for StreamSubscription
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:t_racks_softdev_1/services/database_service.dart';
import 'package:t_racks_softdev_1/services/models/class_model.dart';
import 'package:t_racks_softdev_1/services/models/notification_model.dart';

class InAppNotificationService extends ChangeNotifier {
  static final InAppNotificationService _instance =
      InAppNotificationService._internal();
  factory InAppNotificationService() => _instance;
  InAppNotificationService._internal();

  final List<AppNotification> _notifications = [];
  List<AppNotification> get notifications => List.unmodifiable(_notifications);

  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  final Set<String> _generatedAlerts = {};

  // --- VARIABLES FOR REALTIME LISTENER ---
  Set<String> _knownClassIds = {};
  bool _isFirstLoad = true;
  StreamSubscription? _classSubscription;
  Timer? _scheduleTimer;

  Future<void> loadAllNotifications() async {
    // 1. Get DB Notifications (History)
    final dbNotifications = await DatabaseService()
        .getPersistentNotifications();

    // 2. Clear current list and add DB items
    _notifications.clear();
    _notifications.addAll(dbNotifications);

    // 3. Run the local Schedule Check (adds "Class starting soon" on top)
    await checkClassesForAlerts();

    notifyListeners();
  }

  void startListeningToEnrollments() {
    // Cancel existing subscription to avoid duplicates
    _classSubscription?.cancel();
    print("🎧 Listening for new class enrollments...");

    // This calls the function you just added to DatabaseService
    _classSubscription = DatabaseService().getStudentClassesStream().listen((
      classes,
    ) {
      final currentIds = classes.map((c) => c.id).toSet();

      // If it's NOT the first load, check for newly added classes
      if (!_isFirstLoad) {
        for (var sClass in classes) {
          // If we didn't know about this class ID before, it's NEW!
          if (!_knownClassIds.contains(sClass.id)) {
            _generateEnrollmentNotification(sClass);
          }
        }
      } else {
        print("✅ Initial class list loaded. Count: ${classes.length}");
      }

      // Update our cache and mark first load as done
      _knownClassIds = currentIds;
      _isFirstLoad = false;
    });
  }

  void _generateEnrollmentNotification(StudentClass sClass) {
    print("🎉 New Enrollment Detected: ${sClass.name}");

    final newNotification = AppNotification(
      id: "enroll_${DateTime.now().millisecondsSinceEpoch}",
      title: "New Class Added!",
      message: "You have been added to ${sClass.name} (${sClass.subject}).",
      timestamp: DateTime.now(),
      isRead: false,
    );

    _notifications.insert(0, newNotification);
    notifyListeners();
  }

  void startScheduleChecker() {
    // 1. Run immediately once
    checkClassesForAlerts();

    // 2. Cancel existing timer if any
    _scheduleTimer?.cancel();

    // 3. Set up a timer to run every minute
    print("⏰ Schedule Checker Started (Runs every 60s)");
    _scheduleTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      checkClassesForAlerts();
    });
  }

  void stopScheduleChecker() {
    _scheduleTimer?.cancel();
  }

  Future<void> checkClassesForAlerts() async {
    print("🔍 Checking for upcoming classes...");

    // We use a simple fetch here because we only need to check ONCE when app opens
    final classes = await DatabaseService().getStudentClasses();
    final now = DateTime.now();
    final todayName = DateFormat('EEE').format(now);

    for (var sClass in classes) {
      if (!_isClassToday(sClass.day, todayName)) continue;

      final startTime = _parseStartTime(sClass.time);
      if (startTime == null) continue;

      final classDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        startTime.hour,
        startTime.minute,
      );

      final difference = classDateTime.difference(now).inMinutes;

      // Notify if class starts in 0-60 mins OR if it started less than 15 mins ago
      if (difference > -15 && difference <= 60) {
        _addNotificationIfNotExists(sClass, difference);
      }
    }
  }

  // --- HELPERS ---

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

  void dismissNotification(String id) {
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  void markAsRead() {
    for (var n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();
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

  TimeOfDay? _parseStartTime(String? timeStr) {
    if (timeStr == null) return null;
    try {
      final parts = timeStr.split(RegExp(r'\s*-\s*'));
      String startPart = parts[0].trim();
      startPart = startPart
          .replaceAll('\u00A0', ' ')
          .replaceAll('.', '')
          .toUpperCase();

      DateTime date;
      try {
        date = DateFormat("h:mm a").parse(startPart);
      } catch (e) {
        try {
          date = DateFormat("h:mma").parse(startPart);
        } catch (e2) {
          date = DateFormat("HH:mm").parse(startPart);
        }
      }
      return TimeOfDay.fromDateTime(date);
    } catch (e) {
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
    }
  }

  @override
  void dispose() {
    _classSubscription?.cancel();
    super.dispose();
  }
}
