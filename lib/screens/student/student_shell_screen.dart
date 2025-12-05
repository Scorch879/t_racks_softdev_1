import 'package:flutter/material.dart';
import 'package:t_racks_softdev_1/commonWidgets/notifications_dialog.dart'; // <--- IMPORT THIS
import 'package:t_racks_softdev_1/screens/student/student_home_content.dart';
import 'package:t_racks_softdev_1/screens/student/student_settings_content.dart';
import 'package:t_racks_softdev_1/screens/student/student_class_content.dart';
import 'package:t_racks_softdev_1/services/database_service.dart';
import 'package:t_racks_softdev_1/services/in_app_notification_service.dart'; // Import service for badge count

const _bgTeal = Color(0xFF167C94);
const _accentCyan = Color(0xFF93C0D3);

enum StudentNavTab { home, schedule, settings }

class StudentShellScreen extends StatefulWidget {
  const StudentShellScreen({super.key});

  @override
  State<StudentShellScreen> createState() => _StudentShellScreenState();
}

class _StudentShellScreenState extends State<StudentShellScreen> {
  StudentNavTab _currentTab = StudentNavTab.home;
  String _studentName = "Loading...";

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final dbService = DatabaseService();
    final profile = await dbService.getProfile();

    if (mounted && profile != null) {
      setState(() {
        _studentName = "${profile.firstName} ${profile.lastName}";
      });
    }
  }

  void _onTabChanged(StudentNavTab tab) {
    if (_currentTab != tab) {
      setState(() {
        _currentTab = tab;
      });
    }
  }

  // --- UPDATED METHOD ---
  // Simply shows the new dynamic dialog
  void _onNotificationsPressed() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const NotificationsDialog(),
    );
  }

  Widget _buildContent() {
    switch (_currentTab) {
      case StudentNavTab.home:
        return StudentHomeContent(
          onNotificationsPressed: _onNotificationsPressed,
        );
      case StudentNavTab.schedule:
        return const StudentClassClassesContent();
      case StudentNavTab.settings:
        return StudentSettingsContent(
          onNotificationsPressed: _onNotificationsPressed,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final scale = (width / 430).clamp(0.8, 1.6);

        return Scaffold(
          extendBody: true,
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(64 * scale),
            child: _TopBar(
              scale: scale,
              onNotificationsPressed: _onNotificationsPressed,
              studentName: _studentName,
            ),
          ),
          body: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF194B61),
                        Color(0xFF2A7FA3),
                        Color(0xFF267394),
                        Color(0xFF349BC7),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Opacity(
                    opacity: 0.3,
                    child: Image.asset(
                      'assets/images/squigglytexture.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              _buildContent(),
            ],
          ),
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
    required this.studentName,
  });

  final double scale;
  final VoidCallback onNotificationsPressed;
  final String studentName;

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
                    widget.studentName,
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
            // --- UPDATED BELL ICON WITH BADGE ---
            AnimatedBuilder(
              animation: InAppNotificationService(),
              builder: (context, _) {
                int count = InAppNotificationService().unreadCount;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      iconSize: 22 * scale + 1,
                      onPressed: widget.onNotificationsPressed,
                      icon: const Icon(Icons.notifications_none_rounded),
                      color: Colors.black87,
                    ),
                    if (count > 0)
                      Positioned(
                        right: 8 * scale,
                        top: 8 * scale,
                        child: Container(
                          padding: EdgeInsets.all(2.5 * scale),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE26B6B), // Red status color
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          child: Text(
                            count > 9 ? '9+' : count.toString(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10 * scale,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.scale,
    required this.currentTab,
    required this.onTabChanged,
  });
  final double scale;
  final StudentNavTab currentTab;
  final ValueChanged<StudentNavTab> onTabChanged;

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
            isActive: currentTab == StudentNavTab.home,
            onTap: () => onTabChanged(StudentNavTab.home),
          ),
          _BottomItem(
            icon: Icons.calendar_month_rounded,
            label: 'Schedule',
            scale: scale,
            isActive: currentTab == StudentNavTab.schedule,
            onTap: () => onTabChanged(StudentNavTab.schedule),
          ),
          _BottomItem(
            icon: Icons.settings_rounded,
            label: 'Settings',
            scale: scale,
            isActive: currentTab == StudentNavTab.settings,
            onTap: () => onTabChanged(StudentNavTab.settings),
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
