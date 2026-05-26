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
  String? _profilePictureUrl;

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
          _profilePictureUrl = profile.profilePictureUrl;
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
        return EducatorSettingsScreen(onProfileUpdated: _loadProfile);
      default:
        return const EducatorHomeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final gradientColors = isDarkMode
        ? const [
            Color(0xFF092633),
            Color(0xFF0F3951),
            Color(0xFF15516B),
            Color(0xFF1A6686),
          ]
        : const [
            Color(0xFFEAF7FB),
            Color(0xFFD9EEF5),
            Color(0xFFC7E4EE),
            Color(0xFFEFF9FC),
          ];

    return Scaffold(
      extendBody: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: _TopBar(
          educatorName: _educatorName,
          profilePictureUrl: _profilePictureUrl,
          onNotificationTap: _showNotifications,
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Opacity(
                opacity: isDarkMode ? 0.3 : 0.12,
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 10, bottom: 20),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF0C3343) : Colors.white,
      ),
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _onItemTapped(index),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF93C0D3) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          icon,
          color: isDarkMode ? Colors.white : Colors.black87,
          size: 24,
        ),
      ),
    );
  }
}

// TopBar remains mostly the same, just keeping it here for completeness
class _TopBar extends StatelessWidget {
  final String educatorName;
  final String? profilePictureUrl;
  final VoidCallback onNotificationTap;

  const _TopBar({
    required this.educatorName,
    this.profilePictureUrl,
    required this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    final trimmedProfilePictureUrl = profilePictureUrl?.trim();
    final hasProfilePicture =
        trimmedProfilePictureUrl != null && trimmedProfilePictureUrl.isNotEmpty;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final foregroundColor = isDarkMode ? Colors.white : Colors.black87;
    final subtitleColor = isDarkMode ? Colors.white70 : Colors.black54;

    return AppBar(
      backgroundColor: isDarkMode ? const Color(0xFF0C3343) : Colors.white,
      elevation: 0,
      centerTitle: false,
      titleSpacing: 0,
      automaticallyImplyLeading: false,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFFB7C5C9),
              backgroundImage: hasProfilePicture
                  ? NetworkImage(trimmedProfilePictureUrl)
                  : const AssetImage('assets/images/t_racks.png')
                        as ImageProvider,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    educatorName,
                    style: TextStyle(
                      color: foregroundColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Teacher',
                    style: TextStyle(color: subtitleColor, fontSize: 12),
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
                        child: Icon(
                          Icons.notifications_none_rounded,
                          size: 23,
                          color: foregroundColor,
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
                                color: Colors.white,
                                width: 1.5,
                              ),
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
