import 'package:flutter/material.dart';
import 'package:t_racks_softdev_1/screens/student/student_settings_screen.dart';

const _bgTeal = Color(0xFF167C94);
const _cardSurface = Color(0xFF173C45);
const _cardHeader = Color(0xFF1B4A55);
const _accentCyan = Color(0xFF93C0D3);
const _chipGreen = Color(0xFF4DBD88);
const _statusRed = Color(0xFFDA6A6A);
const _titleRed = Color(0xFFE57373);

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  DateTime? _lastNavTime;
  static const _navDebounceMs = 300;

  void onOngoingClassStatusPressed() {}

  void onFilterAllClasses() {}

  void onClassPressed() {}

  void onNotificationsPressed() => _showNotifications(full: false);

  void onNavHome() {
    if (_isNavigating()) return;
    
    try {
      final navigator = Navigator.of(context);
      final currentRoute = ModalRoute.of(context);
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
  
  void onNavSchedule() {}
  
  void onNavSettings() {
    if (_isNavigating()) return;
    
    try {
      final navigator = Navigator.of(context);
      final currentRoute = ModalRoute.of(context);
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
  
  bool _isNavigating() {
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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final scale = (width / 430).clamp(0.8, 1.6);
        final horizontalPadding = 16.0 * scale;
        final cardRadius = 16.0 * scale;

        return Scaffold(
          backgroundColor: _bgTeal,
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(64 * scale),
            child: _TopBar(scale: scale, onNotificationsPressed: onNotificationsPressed),
          ),
          body: Stack(
            children: [
              Positioned.fill(
                child: Opacity(
                  opacity: 0.12,
                  child: Image.asset(
                    'assets/images/squigglytexture.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  12 * scale,
                  horizontalPadding,
                  100 * scale,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 980),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _WelcomeAndOngoingCard(
                          scale: scale,
                          radius: cardRadius,
                          onOngoingClassStatusPressed: onOngoingClassStatusPressed,
                        ),
                        SizedBox(height: 16 * scale),
                        _MyClassesCard(
                          scale: scale,
                          radius: cardRadius,
                          onFilterAllClasses: onFilterAllClasses,
                          onClassPressed: onClassPressed,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: _BottomNav(
            scale: scale,
            onNavHome: onNavHome,
            onNavSchedule: onNavSchedule,
            onNavSettings: onNavSettings,
          ),
        );
      },
    );
  }
}

class _WelcomeAndOngoingCard extends StatelessWidget {
  const _WelcomeAndOngoingCard({
    required this.scale,
    required this.radius,
    required this.onOngoingClassStatusPressed,
  });
  final double scale;
  final double radius;
  final VoidCallback onOngoingClassStatusPressed;

  @override
  Widget build(BuildContext context) {
    return _CardContainer(
      radius: radius,
      scale: scale,
      borderColor: const Color(0xFF6AAFBF).withOpacity(0.35),
      background: const _CardBackground(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16 * scale),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome! user',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18 * scale,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4 * scale),
                Text(
                  "Today's Status",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12 * scale,
                  ),
                ),
                SizedBox(height: 12 * scale),
                Row(
                  children: [
                    Icon(Icons.person_off_outlined,
                        color: _titleRed, size: 28 * scale),
                    SizedBox(width: 8 * scale),
                    Text(
                      'Absent',
                      style: TextStyle(
                        color: _titleRed,
                        fontSize: 28 * scale,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            height: 8 * scale,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 12 * scale,
                  offset: Offset(0, 6 * scale),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 10 * scale),
            decoration: const BoxDecoration(color: _cardHeader),
            child: Text(
              'Ongoing Class',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16 * scale,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(12 * scale),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12 * scale),
                  child: Image.asset(
                    'assets/images/cpe361.png',
                    width: 52 * scale,
                    height: 52 * scale,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Image.asset(
                      'assets/images/placeholder.png',
                      width: 52 * scale,
                      height: 52 * scale,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SizedBox(width: 12 * scale),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Calculus 137',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16 * scale,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 2 * scale),
                      Text(
                        '10:00 AM',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12 * scale,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: onOngoingClassStatusPressed,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      vertical: 8 * scale,
                      horizontal: 14 * scale,
                    ),
                    decoration: BoxDecoration(
                      color: _statusRed,
                      borderRadius: BorderRadius.circular(20 * scale),
                    ),
                    child: Text(
                      'Absent',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12 * scale,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
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

class _TopBar extends StatelessWidget {
  const _TopBar({required this.scale, required this.onNotificationsPressed});
  final double scale;
  final VoidCallback onNotificationsPressed;

  @override
  Widget build(BuildContext context) {
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
                  onPressed: onNotificationsPressed,
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

class _MyClassesCard extends StatelessWidget {
  const _MyClassesCard({
    required this.scale,
    required this.radius,
    required this.onFilterAllClasses,
    required this.onClassPressed,
  });
  final double scale;
  final double radius;
  final VoidCallback onFilterAllClasses;
  final VoidCallback onClassPressed;

  @override
  Widget build(BuildContext context) {
    return _CardContainer(
      radius: radius,
      scale: scale,
      borderColor: const Color(0xFF6AAFBF).withOpacity(0.55),
      background: const _CardBackground(),
      child: Padding(
        padding: EdgeInsets.all(16 * scale),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.menu_rounded,
                  color: _accentCyan,
                  size: 24 * scale,
                ),
                SizedBox(width: 10 * scale),
                Expanded(
                  child: Text(
                    'My Classes',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22 * scale,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16 * scale),
            _FilterChipRow(
              scale: scale,
              onTap: onFilterAllClasses,
              title: 'All Classes',
              trailingText: 'Total: 3',
              backgroundColor: _chipGreen,
            ),
            SizedBox(height: 16 * scale),
            _ClassRow(
              scale: scale,
              title: 'Calculus 137',
              statusText: 'Absent',
              statusColor: _statusRed,
              onTap: onClassPressed,
            ),
            SizedBox(height: 16 * scale),
            _ClassRow(
              scale: scale,
              title: 'Physics 138',
              statusText: 'Ongoing',
              statusColor: _chipGreen,
              onTap: onClassPressed,
            ),
            SizedBox(height: 16 * scale),
            _ClassRow(
              scale: scale,
              title: 'Calculus 237',
              statusText: 'Upcoming',
              statusColor: _chipGreen,
              onTap: onClassPressed,
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChipRow extends StatelessWidget {
  const _FilterChipRow({
    required this.scale,
    required this.onTap,
    required this.title,
    required this.trailingText,
    required this.backgroundColor,
  });

  final double scale;
  final VoidCallback onTap;
  final String title;
  final String trailingText;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 14 * scale,
          vertical: 12 * scale,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(22 * scale),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 10 * scale,
              offset: Offset(0, 6 * scale),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18 * scale,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              trailingText,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18 * scale,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClassRow extends StatelessWidget {
  const _ClassRow({
    required this.scale,
    required this.title,
    required this.statusText,
    required this.statusColor,
    required this.onTap,
  });

  final double scale;
  final String title;
  final String statusText;
  final Color statusColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 16 * scale),
        decoration: BoxDecoration(
          color: statusColor,
          borderRadius: BorderRadius.circular(22 * scale),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 10 * scale,
              offset: Offset(0, 6 * scale),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18 * scale,
                ),
              ),
            ),
            Text(
              statusText,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18 * scale,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardContainer extends StatelessWidget {
  const _CardContainer({
    required this.child,
    required this.radius,
    required this.scale,
    this.background,
    this.borderColor,
  });

  final Widget child;
  final double radius;
  final double scale;
  final Widget? background;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _cardSurface,
        borderRadius: BorderRadius.circular(radius),
        border: borderColor != null ? Border.all(color: borderColor!) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 10 * scale,
            offset: Offset(0, 6 * scale),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (background != null) background!,
          child,
        ],
      ),
    );
  }
}

class _CardBackground extends StatelessWidget {
  const _CardBackground();
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Opacity(
        opacity: 0.0,
        child: Image.asset(
          'assets/images/squigglytexture.png',
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.scale,
    required this.onNavHome,
    required this.onNavSchedule,
    required this.onNavSettings,
  });
  final double scale;
  final VoidCallback onNavHome;
  final VoidCallback onNavSchedule;
  final VoidCallback onNavSettings;

  @override
  Widget build(BuildContext context) {
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
            isActive: true,
            onTap: onNavHome,
          ),
          _BottomItem(
            icon: Icons.calendar_month_rounded,
            label: 'Schedule',
            scale: scale,
            onTap: onNavSchedule,
          ),
          _BottomItem(
            icon: Icons.settings_rounded,
            label: 'Settings',
            scale: scale,
            onTap: onNavSettings,
          ),
        ],
      ),
    );
  }
}

class _BottomItem extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final Color iconAndTextColor = Colors.black87;
    final Color activeBg = _accentCyan;
    return Semantics(
      label: label,
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(16 * scale),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(12 * scale),
          decoration: BoxDecoration(
            color: isActive ? activeBg : Colors.transparent,
            borderRadius: BorderRadius.circular(16 * scale),
          ),
          child: Icon(icon, color: iconAndTextColor, size: 24 * scale),
        ),
      ),
    );
  }
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