import 'package:flutter/material.dart';
import 'package:t_racks_softdev_1/screens/student/student_settings_screen.dart';
import 'package:t_racks_softdev_1/screens/student/student_class_screen.dart';

// Holds the currently registered page context
BuildContext? _ctx;

class StudentService {
  static DateTime? _lastNavTime;
  static const _navDebounceMs = 300;

  // Register MAIN student pages (home, schedule, etc.)
  static void registerStudentPageContext(BuildContext context) {
    _ctx = context;
  }

  // Register JUST the classes/schedule page
  static void registerClassesPageContext(BuildContext context) {
    _ctx = context;
  }

  // -----------------------------------------
  // NOTIFICATIONS BUTTON
  // -----------------------------------------
  static void onNotificationsPressed() => _showNotifications(full: false);

  // -----------------------------------------
  // BUTTON ACTIONS
  // -----------------------------------------
  static void onOngoingClassStatusPressed() {
    if (_ctx == null) return;
    if (_isNavigating()) return;

    try {
      Navigator.of(_ctx!).push(
        MaterialPageRoute(
          builder: (_) => const Placeholder(),
          settings: const RouteSettings(name: '/ongoing-class'),
        ),
      );
    } catch (e) {}
  }

  static void onFilterAllClasses() {
    debugPrint("Filter All Classes tapped!");
  }

  static void onClassPressed() {
    if (_ctx == null) return;
    if (_isNavigating()) return;

    try {
      Navigator.of(_ctx!).push(
        MaterialPageRoute(
          builder: (_) => const Placeholder(),
          settings: const RouteSettings(name: '/class-details'),
        ),
      );
    } catch (e) {}
  }

  // -----------------------------------------
  // BOTTOM NAVIGATION
  // -----------------------------------------

  static void onNavHome() {
    if (_ctx == null) return;
    if (_isNavigating()) return;

    try {
      final navigator = Navigator.of(_ctx!);
      final currentRoute = ModalRoute.of(_ctx!);
      final routeName = currentRoute?.settings.name;

      // Already at home
      if (routeName == '/home' || (routeName == null && !navigator.canPop())) {
        return;
      }

      // Pop to home
      if (navigator.canPop()) {
        navigator.popUntil((route) {
          return route.isFirst || route.settings.name == '/home';
        });
      }
    } catch (e) {}
  }

  static void onNavSchedule() {
    if (_ctx == null) return;
    if (_isNavigating()) return;

    try {
      final currentRoute = ModalRoute.of(_ctx!);
      if (currentRoute?.settings.name == '/schedule') return;

      Navigator.of(_ctx!).push(
        MaterialPageRoute(
          builder: (_) => const StudentClassScreen(),
          settings: const RouteSettings(name: '/schedule'),
        ),
      );
    } catch (e) {}
  }

  static void onNavSettings() {
    if (_ctx == null) return;
    if (_isNavigating()) return;

    try {
      final currentRoute = ModalRoute.of(_ctx!);
      if (currentRoute?.settings.name == '/settings') {
        return;
      }

      Navigator.of(_ctx!).push(
        MaterialPageRoute(
          builder: (context) => const StudentSettingsScreen(),
          settings: const RouteSettings(name: '/settings'),
        ),
      );
    } catch (e) {}
  }

  static bool _isNavigating() {
    final now = DateTime.now();
    if (_lastNavTime != null) {
      final diff = now.difference(_lastNavTime!);
      if (diff.inMilliseconds < _navDebounceMs) return true;
    }
    _lastNavTime = now;
    return false;
  }

  // -----------------------------------------
  // SETTINGS PAGE BUTTONS
  // -----------------------------------------
  static void onProfileSettingsPressed() {}
  static void onAccountSettingsPressed() {}
  static void onDeleteAccountPressed() {}

  // -----------------------------------------
  // NOTIFICATIONS DIALOG
  // -----------------------------------------
  static void _showNotifications({required bool full}) {
    if (_ctx == null) return;
    final notifications = full
        ? _notifications
        : _notifications.take(3).toList(growable: false);

    showDialog<void>(
      context: _ctx!,
      barrierDismissible: true,
      barrierColor: Colors.black45,
      builder: (dialogContext) {
        return _NotificationDialog(
          notifications: notifications,
          isFull: full,
          onClose: () => Navigator.of(dialogContext).pop(),
          onToggle: () {
            Navigator.of(dialogContext).pop();
            _showNotifications(full: !full);
          },
        );
      },
    );
  }
}

// --------------------------------------------------
// NOTIFICATIONS DATA
// --------------------------------------------------

enum _NotificationType { success, warning, info }

class _StudentNotification {
  const _StudentNotification({
    required this.title,
    required this.subtitle,
    required this.timestamp,
    required this.type,
  });

  final String title;
  final String subtitle;
  final String timestamp;
  final _NotificationType type;
}

const List<_StudentNotification> _notifications = [
  _StudentNotification(
    title: 'Assignment Graded',
    subtitle: 'Calculus 137 - Quiz #3 has been graded',
    timestamp: '2 minutes ago',
    type: _NotificationType.success,
  ),
  _StudentNotification(
    title: 'Low Attendance Alert',
    subtitle: 'Physics 138 attendance below 80%',
    timestamp: '1 hour ago',
    type: _NotificationType.warning,
  ),
  _StudentNotification(
    title: 'New Student Enrolled',
    subtitle: 'Zonrox D. Color joined Calculus 237',
    timestamp: '2 hours ago',
    type: _NotificationType.info,
  ),
  _StudentNotification(
    title: 'Lab Report Submitted',
    subtitle: 'Physics 138 - 18 students submitted their report',
    timestamp: '5 hours ago',
    type: _NotificationType.success,
  ),
  _StudentNotification(
    title: 'Parent Meeting Scheduled',
    subtitle: "Mama Merto's parents tomorrow 3 PM",
    timestamp: '5 hours ago',
    type: _NotificationType.info,
  ),
  _StudentNotification(
    title: 'Parent Meeting Scheduled',
    subtitle: "Papa Merto's parents tomorrow 3 PM",
    timestamp: '5 hours ago',
    type: _NotificationType.warning,
  ),
];

// --------------------------------------------------
// NOTIFICATION DIALOG UI
// --------------------------------------------------

class _NotificationDialog extends StatefulWidget {
  const _NotificationDialog({
    required this.notifications,
    required this.isFull,
    required this.onClose,
    required this.onToggle,
  });

  final List<_StudentNotification> notifications;
  final bool isFull;
  final VoidCallback onClose;
  final VoidCallback onToggle;

  @override
  State<_NotificationDialog> createState() => _NotificationDialogState();
}

class _NotificationDialogState extends State<_NotificationDialog> {
  @override
  Widget build(BuildContext context) {
    final double maxHeight = widget.isFull ? 520 : 360;
    final String toggleLabel = widget.isFull ? 'See Less' : 'View All Notifications';

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Notifications',
                    style: TextStyle(
                      color: Color(0xFF1A2B3C),
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: widget.onClose,
                  icon: const Icon(Icons.close_rounded),
                  color: const Color(0xFF1A2B3C),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight),
              child: ListView.separated(
                shrinkWrap: true,
                physics: widget.isFull
                    ? const BouncingScrollPhysics()
                    : const NeverScrollableScrollPhysics(),
                itemCount: widget.notifications.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = widget.notifications[index];
                  return _NotificationTile(item: item);
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: widget.onToggle,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: const Color(0xFFEFF5F9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: const BorderSide(color: Color(0xFFBFD5E3)),
                  ),
                ),
                child: Text(
                  toggleLabel,
                  style: const TextStyle(
                    color: Color(0xFF1A2B3C),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item});

  final _StudentNotification item;

  @override
  Widget build(BuildContext context) {
    final _Indicator indicator = _indicatorFor(item.type);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: indicator.borderColor),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A2B3C).withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 32,
            width: 32,
            decoration: BoxDecoration(
              color: indicator.backgroundColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              indicator.icon,
              color: indicator.iconColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    color: Color(0xFF1A2B3C),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.subtitle,
                  style: const TextStyle(
                    color: Color(0xFF2A5F84),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.timestamp,
                  style: const TextStyle(
                    color: Color(0xFF7C8CA0),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

_Indicator _indicatorFor(_NotificationType type) {
  switch (type) {
    case _NotificationType.success:
      return const _Indicator(
        icon: Icons.check_circle_rounded,
        iconColor: Color(0xFF2DAA66),
        backgroundColor: Color(0xFFE6F7EF),
        borderColor: Color(0xFFBFE9D1),
      );
    case _NotificationType.warning:
      return const _Indicator(
        icon: Icons.report_problem_rounded,
        iconColor: Color(0xFFF0A92C),
        backgroundColor: Color(0xFFFFF4E3),
        borderColor: Color(0xFFF7DCAC),
      );
    case _NotificationType.info:
      return const _Indicator(
        icon: Icons.info_rounded,
        iconColor: Color(0xFF3A7BD5),
        backgroundColor: Color(0xFFE6F0FF),
        borderColor: Color(0xFFBDD6FF),
      );
  }
}

class _Indicator {
  const _Indicator({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.borderColor,
  });

  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final Color borderColor;
}
