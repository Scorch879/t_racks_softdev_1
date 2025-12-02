import 'package:flutter/material.dart';
import 'package:t_racks_softdev_1/screens/student/student_class_content.dart';

const _bgTeal = Color(0xFF167C94);
const _accentCyan = Color(0xFF93C0D3);

enum ClassNavTab { classes, schedule, settings }

class StudentClassScreen extends StatefulWidget {
  const StudentClassScreen({super.key});

  @override
  State<StudentClassScreen> createState() => _StudentClassScreenState();
}

class _StudentClassScreenState extends State<StudentClassScreen> {
  // State: Tracks which tab is active
  ClassNavTab _currentTab = ClassNavTab.classes;

  void _onTabChanged(ClassNavTab tab) {
    if (tab == ClassNavTab.classes) {
      Navigator.of(context).pop();
      return;
    }
    if (_currentTab != tab) {
      setState(() {
        _currentTab = tab;
      });
    }
  }

  void _onNotificationsPressed() => _showNotifications(full: false);

  void _showNotifications({required bool full}) {
    final notifications = full
        ? _notifications
        : _notifications.take(3).toList(growable: false);

    showDialog<void>(
      context: context,
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

  Widget _buildContent() {
    // Switches between the stateful content widgets based on the tab
    switch (_currentTab) {
      case ClassNavTab.classes:
        return const StudentClassClassesContent();
      case ClassNavTab.schedule:
        return const StudentClassScheduleContent();
      case ClassNavTab.settings:
        return const StudentClassSettingsContent();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final scale = (width / 430).clamp(0.8, 1.6);

        return Scaffold(
          backgroundColor: _bgTeal,
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(64 * scale),
            child: _TopBar(
              scale: scale,
              onNotificationsPressed: _onNotificationsPressed,
            ),
          ),
          body: _buildContent(),
          bottomNavigationBar: _BottomNav(
            scale: scale,
            currentTab: _currentTab,
            onTabChanged: _onTabChanged,
          ),
        );
      },
    );
  }
}

class _TopBar extends StatefulWidget {
  const _TopBar({
    required this.scale,
    required this.onNotificationsPressed,
  });
  final double scale;
  final VoidCallback onNotificationsPressed;

  @override
  State<_TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<_TopBar> {
  @override
  Widget build(BuildContext context) {
    final scale = widget.scale;
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleSpacing: 0,
      title: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16 * scale),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20 * scale,
              backgroundColor: const Color(0xFFB7C5C9),
            ),
            SizedBox(width: 12 * scale),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Student',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 16 * scale,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Student',
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 12 * scale,
                    ),
                  ),
                ],
              ),
            ),
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  iconSize: 22 * scale + 1,
                  onPressed: widget.onNotificationsPressed,
                  icon: const Icon(Icons.notifications_none_rounded),
                  color: Colors.black87,
                ),
                Positioned(
                  right: 8 * scale,
                  top: 8 * scale,
                  child: Container(
                    padding: EdgeInsets.all(2.5 * scale),
                    decoration: BoxDecoration(
                      color: _bgTeal,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Text(
                      '1',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10 * scale,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNav extends StatefulWidget {
  const _BottomNav({
    required this.scale,
    required this.currentTab,
    required this.onTabChanged,
  });
  final double scale;
  final ClassNavTab currentTab;
  final ValueChanged<ClassNavTab> onTabChanged;

  @override
  State<_BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<_BottomNav> {
  @override
  Widget build(BuildContext context) {
    final scale = widget.scale;
    return Container(
      padding: EdgeInsets.only(
        left: 24 * scale,
        right: 24 * scale,
        top: 10 * scale,
        bottom: 20 * scale,
      ),
      decoration: const BoxDecoration(color: Colors.white),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _BottomItem(
            icon: Icons.home_rounded,
            label: 'Home',
            scale: scale,
            isActive: widget.currentTab == ClassNavTab.classes,
            onTap: () => widget.onTabChanged(ClassNavTab.classes),
          ),
          _BottomItem(
            icon: Icons.calendar_month_rounded,
            label: 'Schedule',
            scale: scale,
            isActive: widget.currentTab == ClassNavTab.schedule,
            onTap: () => widget.onTabChanged(ClassNavTab.schedule),
          ),
          _BottomItem(
            icon: Icons.settings_rounded,
            label: 'Settings',
            scale: scale,
            isActive: widget.currentTab == ClassNavTab.settings,
            onTap: () => widget.onTabChanged(ClassNavTab.settings),
          ),
        ],
      ),
    );
  }
}

class _BottomItem extends StatefulWidget {
  const _BottomItem({
    required this.icon,
    required this.label,
    required this.scale,
    required this.onTap,
    this.isActive = false,
  });

  final IconData icon;
  final String label;
  final double scale;
  final VoidCallback onTap;
  final bool isActive;

  @override
  State<_BottomItem> createState() => _BottomItemState();
}

class _BottomItemState extends State<_BottomItem> {
  @override
  Widget build(BuildContext context) {
    final Color iconAndTextColor = Colors.black87;
    final Color activeBg = _accentCyan;
    return Semantics(
      label: widget.label,
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(16 * widget.scale),
        onTap: widget.onTap,
        child: Container(
          padding: EdgeInsets.all(12 * widget.scale),
          decoration: BoxDecoration(
            color: widget.isActive ? activeBg : Colors.transparent,
            borderRadius: BorderRadius.circular(16 * widget.scale),
          ),
          child: Icon(widget.icon, color: iconAndTextColor, size: 24 * widget.scale),
        ),
      ),
    );
  }
}

// --- Notification Data & Widgets ---
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
];

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

class _NotificationTile extends StatefulWidget {
  const _NotificationTile({required this.item});

  final _StudentNotification item;

  @override
  State<_NotificationTile> createState() => _NotificationTileState();
}

class _NotificationTileState extends State<_NotificationTile> {
  @override
  Widget build(BuildContext context) {
    final _Indicator indicator = _indicatorFor(widget.item.type);

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
                  widget.item.title,
                  style: const TextStyle(
                    color: Color(0xFF1A2B3C),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.item.subtitle,
                  style: const TextStyle(
                    color: Color(0xFF2A5F84),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.item.timestamp,
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