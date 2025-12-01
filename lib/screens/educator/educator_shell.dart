import 'package:flutter/material.dart';
import 'package:t_racks_softdev_1/screens/educator/educator_home_screen.dart';
import 'package:t_racks_softdev_1/screens/educator/educator_classes_screen.dart';
import 'package:t_racks_softdev_1/screens/educator/educator_report_screen.dart';
import 'package:t_racks_softdev_1/screens/educator/educator_settings_screen.dart';
import 'package:t_racks_softdev_1/services/educator_notification_service.dart';
import 'package:t_racks_softdev_1/services/database_service.dart'; // Import DB Service

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
  }

  Future<void> _loadProfile() async {
    final dbService = DatabaseService();
    // Use getProfile or getEducatorData depending on where the name is
    print("--- FETCHING PROFILE ---");
    final profile = await dbService.getProfile();
    if (profile != null) {
      // Now it's safe to print and use
      print("--- PROFILE FOUND: ${profile.firstName} ---");
      if (mounted && profile != null) {
        setState(() {
          // Combine first and last name
          _educatorName = "${profile.firstName} ${profile.lastName}";
        });
      } else {
        print("Profile is null or widget not mounted");
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
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
    EducatorNotificationService.register(context);
    return Scaffold(
      // 1. Allow body to extend behind the bottom bar
      extendBody: true,

      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: _TopBar(educatorName: _educatorName),
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

          // 2. Wrap content in SafeArea so it doesn't get hidden behind the nav bar
          // BUT only apply safe area to the bottom if needed
          SafeArea(
            bottom: false, // Let content go to bottom if you want
            child: Padding(
              // Add padding equal to nav bar height so scrolling content isn't hidden
              padding: const EdgeInsets.only(bottom: 80),
              child: _buildContent(),
            ),
          ),
        ],
      ),

      // 3. Make the bottom nav bar transparent so background shows
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 10, bottom: 20),
      // 4. Change color to transparent or semi-transparent if you want the blue to show
      // If you want it WHITE like your design, keep it white.
      // But if you want the blue background to go all the way down, remove this line:
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
        padding: const EdgeInsets.all(
          16,
        ), // Increased padding for larger hit area
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF93C0D3) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(icon, color: Colors.black87, size: 24),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final String educatorName;
  const _TopBar({required this.educatorName});
  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleSpacing: 0,
      automaticallyImplyLeading: false, // Hide default back button
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            CircleAvatar(radius: 20, backgroundColor: const Color(0xFFB7C5C9)),
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
                  Text(
                    'Teacher',
                    style: TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                ],
              ),
            ),
            Stack(
              clipBehavior: Clip.none,
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: EducatorNotificationService.onNotificationsPressed,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0), // Increase hit slop
                    child: const Icon(
                      Icons.notifications_none_rounded,
                      size: 23,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: IgnorePointer(
                    // Ensure the badge doesn't block touches
                    child: Container(
                      padding: const EdgeInsets.all(2.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF167C94),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: const Text(
                        '1',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
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
