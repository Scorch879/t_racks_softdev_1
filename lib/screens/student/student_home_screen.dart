import 'package:flutter/material.dart';
import 'package:t_racks_softdev_1/screens/shared/global_settings_screen.dart';
import 'package:t_racks_softdev_1/screens/student/student_class_screen.dart';
import 'package:t_racks_softdev_1/screens/student/student_camera_screen.dart';

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

  void onOngoingClassStatusPressed() {
    print('onOngoingClassStatusPressed');
  }

  void onFilterAllClasses() {
    print('onFilterAllClasses');
  }

  void onClassPressed() {
    print('onClassPressed');
  }

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
  
  void onNavSchedule() {
    if (_isNavigating()) return;

    try {
      print('onNavSchedule called');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Navigating to Classes...'), duration: Duration(milliseconds: 600)),
      );
      final navigator = Navigator.of(context);
      final currentRoute = ModalRoute.of(context);
      final routeName = currentRoute?.settings.name;

      if (routeName == '/schedule') return;

      navigator.push(
        MaterialPageRoute(
          builder: (context) => const StudentClassScreen(),
          settings: const RouteSettings(name: '/schedule'),
        ),
      );
    } catch (e) {}
  }
  
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
            return Scaffold(
              backgroundColor: _bgTeal,
              appBar: PreferredSize(
                preferredSize: const Size.fromHeight(64),
                child: _TopBar(scale: 1.0, onNotificationsPressed: onNotificationsPressed),
              ),
              body: const GlobalSettingsScreen(isEducator: false),
            );
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

class _WelcomeAndOngoingCard extends StatefulWidget {
  const _WelcomeAndOngoingCard({
    required this.scale,
    required this.radius,
    required this.onOngoingClassStatusPressed,
  });
  final double scale;
  final double radius;
  final VoidCallback onOngoingClassStatusPressed;

  @override
  State<_WelcomeAndOngoingCard> createState() => _WelcomeAndOngoingCardState();
}

class _WelcomeAndOngoingCardState extends State<_WelcomeAndOngoingCard> {
  @override
  Widget build(BuildContext context) {
    final scale = widget.scale;
    final radius = widget.radius;
    return _CardContainer(
      radius: radius,
      scale: scale,
      borderColor: Color(0xFF6AAFBF).withValues(alpha: 0.35),
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
                  color: Colors.black.withValues(alpha: 0.35),
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
                  onTap: widget.onOngoingClassStatusPressed,
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

class _TopBar extends StatefulWidget {
  const _TopBar({required this.scale, required this.onNotificationsPressed});
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
                  constraints: BoxConstraints(
                    minWidth: 44 * scale,
                    minHeight: 44 * scale,
                  ),
                  padding: EdgeInsets.zero,
                  onPressed: widget.onNotificationsPressed,
                  icon: const Icon(Icons.notifications_none_rounded),
                  color: Colors.black87,
                ),
                Positioned(
                  right: 10 * scale,
                  top: 10 * scale,
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

class _MyClassesCard extends StatefulWidget {
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
  State<_MyClassesCard> createState() => _MyClassesCardState();
}

class _MyClassesCardState extends State<_MyClassesCard> {
  final List<Map<String, dynamic>> _classes = [
    {'id': '1', 'title': 'Calculus 137', 'status': 'Absent', 'teacher': 'Prof. Smith', 'room': 'Room 101', 'time': '9:00 AM'},
    {'id': '2', 'title': 'Physics 138', 'status': 'Ongoing', 'teacher': 'Dr. Jones', 'room': 'Lab 3', 'time': '10:00 AM'},
    {'id': '3', 'title': 'Calculus 237', 'status': 'Upcoming', 'teacher': 'Prof. Smith', 'room': 'Room 202', 'time': '1:00 PM'},
  ];

  @override
  Widget build(BuildContext context) {
    final scale = widget.scale;
    final radius = widget.radius;
    return _CardContainer(
      radius: radius,
      scale: scale,
      borderColor: Color(0xFF6AAFBF).withValues(alpha: 0.55),
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
              onTap: widget.onFilterAllClasses,
              title: 'All Classes',
              trailingText: 'Total: ${_classes.length}',
              backgroundColor: _chipGreen,
            ),
            SizedBox(height: 16 * scale),
            ..._classes.map((classData) {
              return Padding(
                padding: EdgeInsets.only(bottom: 16 * scale),
                child: _ClassRow(
                  scale: scale,
                  title: classData['title'],
                  status: classData['status'],
                  teacher: classData['teacher'],
                  room: classData['room'],
                  time: classData['time'],
                  onTap: () => _handleClassTap(classData),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _handleClassTap(Map<String, dynamic> classData) {
    print('Pressed class: ${classData['title']}');
    print('Class status: ${classData['status']}');

    if (classData['status'] == 'Ongoing') {
      print('Navigating to CameraScreen');
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => StudentCameraScreen(
            classId: classData['id'],
            className: classData['title'],
          ),
        ),
      );
    } else {
      print('Showing inactive SnackBar');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('This class is not currently active.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: const Color(0xFF1A2B3C),
        ),
      );
    }
  }
}

class _FilterChipRow extends StatefulWidget {
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
  State<_FilterChipRow> createState() => _FilterChipRowState();
}

class _FilterChipRowState extends State<_FilterChipRow> {
  @override
  Widget build(BuildContext context) {
    final scale = widget.scale;
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 14 * scale,
          vertical: 12 * scale,
        ),
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          borderRadius: BorderRadius.circular(22 * scale),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 10 * scale,
              offset: Offset(0, 6 * scale),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                widget.title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18 * scale,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              widget.trailingText,
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
    required this.status,
    required this.teacher,
    required this.room,
    required this.time,
    required this.onTap,
  });

  final double scale;
  final String title;
  final String status;
  final String teacher;
  final String room;
  final String time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    Color statusTextColor = const Color(0xFF0C3343);
    switch (status) {
      case 'Ongoing':
        statusColor = const Color(0xFF7FE26B); // Lime Green
        break;
      case 'Absent':
        statusColor = const Color(0xFFFA8989); // Red
        break;
      case 'Upcoming':
        statusColor = const Color(0xFF64B5F6); // Blue
        break;
      default:
        statusColor = Colors.grey;
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF376375),
        borderRadius: BorderRadius.circular(24 * scale),
        border: Border.all(color: const Color(0xFFBDBBBB), width: 0.75 * scale),
        boxShadow: [
           BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4 * scale,
            offset: Offset(0, 2 * scale),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            print('ClassRow tapped: $title');
            onTap();
          },
          child: Padding(
            padding: EdgeInsets.only(left: 40 * scale, top: 20 * scale, right: 20 * scale, bottom: 20 * scale),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 22 * scale,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 5 * scale),
                
                // Stats Row
                Row(
                  children: [
                    _buildStatColumn('Teacher', teacher, scale),
                    SizedBox(width: 40 * scale), // Gap
                    _buildStatColumn('Room', room, scale),
                  ],
                ),
                
                SizedBox(height: 5 * scale),
                
                // Next Schedule (Time)
                Text(
                  'Schedule: $time',
                  style: TextStyle(
                    fontSize: 15 * scale,
                    color: const Color(0xFFD5D5D5),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                
                SizedBox(height: 5 * scale),
                
                // Status Button
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 20 * scale, vertical: 6 * scale),
                    decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20 * scale),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                      color: statusTextColor,
                      fontSize: 13 * scale,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, double scale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 15 * scale,
            color: Colors.white60,
            fontWeight: FontWeight.w400,
          ),
        ),
        SizedBox(height: 2 * scale),
        Text(
          value,
          style: TextStyle(
            fontSize: 18 * scale,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _CardContainer extends StatefulWidget {
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
  State<_CardContainer> createState() => _CardContainerState();
}

class _CardContainerState extends State<_CardContainer> {
  @override
  Widget build(BuildContext context) {
    final radius = widget.radius;
    final scale = widget.scale;
    final background = widget.background;
    final borderColor = widget.borderColor;
    return Container(
      decoration: BoxDecoration(
        color: _cardSurface,
        borderRadius: BorderRadius.circular(radius),
        border: borderColor != null ? Border.all(color: borderColor) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10 * scale,
            offset: Offset(0, 6 * scale),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (background != null) background,
          widget.child,
        ],
      ),
    );
  }
}

class _CardBackground extends StatefulWidget {
  const _CardBackground();

  @override
  State<_CardBackground> createState() => _CardBackgroundState();
}

class _CardBackgroundState extends State<_CardBackground> {
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Opacity(
          opacity: 0.0,
          child: Image.asset(
            'assets/images/squigglytexture.png',
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

class _BottomNav extends StatefulWidget {
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
  State<_BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<_BottomNav> {
  @override
  Widget build(BuildContext context) {
    final scale = widget.scale;
    return Container(
      height: 70 * scale,
      decoration: const BoxDecoration(color: Colors.white),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _BottomItem(
              icon: Icons.home_rounded,
              label: 'Home',
              scale: scale,
              isActive: true,
              onTap: widget.onNavHome,
            ),
          ),
          Expanded(
            child: _BottomItem(
              icon: Icons.calendar_month_rounded,
              label: 'Schedule',
              scale: scale,
              onTap: widget.onNavSchedule,
            ),
          ),
          Expanded(
            child: _BottomItem(
              icon: Icons.settings_rounded,
              label: 'Settings',
              scale: scale,
              onTap: widget.onNavSettings,
            ),
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
    this.isActive = false,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final double scale;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isActive ? _bgTeal : Colors.grey,
            size: 28 * scale,
          ),
          SizedBox(height: 4 * scale),
          Text(
            label,
            style: TextStyle(
              color: isActive ? _bgTeal : Colors.grey,
              fontSize: 12 * scale,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

final List<_StudentNotification> _notifications = [
  _StudentNotification(
    title: 'Attendance Recorded',
    subtitle: 'You have successfully recorded your attendance for Physics 138',
    timestamp: '1 hour ago',
    type: _NotificationType.success,
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
    final item = widget.item;
    final _Indicator indicator = _indicatorFor(item.type);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: indicator.borderColor),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF1A2B3C).withValues(alpha: 0.08),
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

enum _NotificationType { success, warning, info }