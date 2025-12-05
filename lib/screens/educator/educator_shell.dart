import 'package:flutter/material.dart';
import 'package:t_racks_softdev_1/screens/educator/educator_home_screen.dart';
import 'package:t_racks_softdev_1/screens/educator/educator_classes_screen.dart';
import 'package:t_racks_softdev_1/screens/educator/educator_report_screen.dart';
import 'package:t_racks_softdev_1/screens/educator/educator_settings_screen.dart';
import 'package:t_racks_softdev_1/services/database_service.dart';
import 'package:t_racks_softdev_1/services/in_app_notification_service.dart';
import 'package:t_racks_softdev_1/commonWidgets/commonwidgets.dart';
class EducatorShell extends StatefulWidget {
  final int initialIndex;
  const EducatorShell({super.key, this.initialIndex = 0});

  @override
  State<EducatorShell> createState() => _EducatorShellState();
}

class _EducatorShellState extends State<EducatorShell> {
  late int _currentIndex;
  String _educatorName = "Loading...";

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _loadProfile();
    InAppNotificationService().startListeningForEducatorNotifications();
  }

  Future<void> _loadProfile() async {
    final dbService = DatabaseService();
    final profile = await dbService.getProfile();
    if (profile != null) {
      if (mounted) {
        setState(() {
          _educatorName = "${profile.firstName} ${profile.lastName}";
        });
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  // 👇 UPDATED: Uses showDialog instead of BottomSheet
  void _showNotifications() {
    showDialog(
      context: context,
      builder: (context) => const NotificationsDialog(),
    );
    // Note: I removed the auto-mark-as-read here because your 
    // dialog has a specific "Mark all read" button.
  }

  Widget _buildContent() {
    switch (_currentIndex) {
      case 0:
        return const EducatorHomeScreen();
      case 1:
        return const EducatorClassesScreen();
      case 2:
        return const EducatorReportScreen();
      case 3:
        return const EducatorSettingsScreen();
      default:
        return const EducatorHomeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: _TopBar(
          educatorName: _educatorName,
          onNotificationTap: _showNotifications,
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
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 80),
              child: _buildContent(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 10, bottom: 20),
      decoration: const BoxDecoration(color: Colors.white),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.home, 0),
          _buildNavItem(Icons.calendar_today, 1),
          _buildNavItem(Icons.upload_file, 2),
          _buildNavItem(Icons.settings, 3),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    final isSelected = _currentIndex == index;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _onItemTapped(index),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF93C0D3) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(icon, color: Colors.black87, size: 24),
      ),
    );
  }
}

// TopBar remains mostly the same, just keeping it here for completeness
class _TopBar extends StatelessWidget {
  final String educatorName;
  final VoidCallback onNotificationTap;

  const _TopBar({
    required this.educatorName,
    required this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleSpacing: 0,
      automaticallyImplyLeading: false,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            const CircleAvatar(
                radius: 20, backgroundColor: Color(0xFFB7C5C9)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    educatorName,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Text(
                    'Teacher',
                    style: TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                ],
              ),
            ),
            AnimatedBuilder(
              animation: InAppNotificationService(),
              builder: (context, child) {
                final unreadCount = InAppNotificationService().unreadCount;

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: onNotificationTap,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: const Icon(
                          Icons.notifications_none_rounded,
                          size: 23,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: IgnorePointer(
                          child: Container(
                            padding: const EdgeInsets.all(2.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE26B6B),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white, width: 1.5),
                            ),
                            child: Text(
                              '$unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
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