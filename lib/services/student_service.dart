import 'package:flutter/material.dart';
import 'package:t_racks_softdev_1/screens/student/student_home_screen.dart';
import 'package:t_racks_softdev_1/screens/student/student_settings_screen.dart';

class StudentService {
  static DateTime? _lastNavTime;
  static const _navDebounceMs = 300;

  static void onNotificationsPressed() => _showNotifications(full: false);

  static void onOngoingClassStatusPressed() {}

  static void onFilterAllClasses() {}
  static void onClassPressed() {}

  static void onNavHome() {
    if (_ctx == null) return;
    if (_isNavigating()) return;
    
    try {
      final navigator = Navigator.of(_ctx!);
      final currentRoute = ModalRoute.of(_ctx!);
      final routeName = currentRoute?.settings.name;
      
      if (routeName == '/home' || (routeName == null && !navigator.canPop())) {
        return;
      }
      
      if (navigator.canPop()) {
        navigator.popUntil((route) {
          return route.isFirst || route.settings.name == '/home';
        });
      }
    } catch (e) {}
  }
  
  static void onNavSchedule() {}
  
  static void onNavSettings() {
    if (_ctx == null) return;
    if (_isNavigating()) return;
    
    try {
      final navigator = Navigator.of(_ctx!);
      final currentRoute = ModalRoute.of(_ctx!);
      final routeName = currentRoute?.settings.name;
      
      if (routeName == '/settings') {
        return;
      }
      
      navigator.push(
        MaterialPageRoute(
          builder: (context) {
            return const StudentSettingsScreen();
          },
          settings: const RouteSettings(name: '/settings'),
        ),
      );
    } catch (e) {}
  }
  
  static bool _isNavigating() {
    final now = DateTime.now();
    if (_lastNavTime != null) {
      final diff = now.difference(_lastNavTime!);
      if (diff.inMilliseconds < _navDebounceMs) {
        return true;
      }
    }
    _lastNavTime = now;
    return false;
  }

  static void onProfileSettingsPressed() {}
  static void onAccountSettingsPressed() {}
  static void onDeleteAccountPressed() {}

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

BuildContext? _ctx;
void registerStudentPageContext(BuildContext context) {
  _ctx = context;
}

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
    subtitle: 'Physics 138 - 18 students have submitted their report',
    timestamp: '5 hours ago',
    type: _NotificationType.success,
  ),
  _StudentNotification(
    title: 'Parent Meeting Scheduled',
    subtitle: "Meeting with Mama Merto's parents tomorrow at 3 PM",
    timestamp: '5 hours ago',
    type: _NotificationType.info,
  ),
  _StudentNotification(
    title: 'Parent Meeting Scheduled',
    subtitle: "Meeting with Papa Merto's parents tomorrow at 3 PM",
    timestamp: '5 hours ago',
    type: _NotificationType.warning,
  ),
];

class _NotificationDialog extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final double maxHeight = isFull ? 520 : 360;
    final String toggleLabel = isFull ? 'See Less' : 'View All Notifications';

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
                  onPressed: onClose,
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
                physics: isFull
                    ? const BouncingScrollPhysics()
                    : const NeverScrollableScrollPhysics(),
                itemCount: notifications.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = notifications[index];
                  return _NotificationTile(item: item);
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: onToggle,
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