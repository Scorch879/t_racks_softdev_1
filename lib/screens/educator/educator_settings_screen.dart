import 'package:flutter/material.dart';
import 'package:t_racks_softdev_1/services/auth_service.dart';
import 'package:t_racks_softdev_1/screens/login_screen.dart';
import 'package:t_racks_softdev_1/screens/educator/educator_profile_screen.dart';
import 'package:t_racks_softdev_1/commonWidgets/theme_mode_switch_tile.dart';
// Import the separated dialog
import 'package:t_racks_softdev_1/commonWidgets/commonwidgets.dart';

// Educator Colors
const _educatorCardSurface = Color(0xFF0F3951);
const _educatorAccentCyan = Color(0xFF93C0D3);
const _educatorChipGreen = Color(0xFF4CAF50);
const _educatorStatusRed = Color(0xFFE53935);

class EducatorSettingsScreen extends StatefulWidget {
  const EducatorSettingsScreen({super.key, this.onProfileUpdated});

  final VoidCallback? onProfileUpdated;

  @override
  State<EducatorSettingsScreen> createState() => _EducatorSettingsScreenState();
}

class _EducatorSettingsScreenState extends State<EducatorSettingsScreen> {
  final AuthService _authService = AuthService();

  // 1. Shows the separated LogoutDialog
  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => LogoutDialog(onConfirm: _performLogout),
    );
  }

  // 2. Performs the actual logout logic when "Yes" is clicked
  Future<void> _performLogout() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final scale = (width / 430).clamp(0.8, 1.6);
        final horizontalPadding = 16.0 * scale;
        final cardRadius = 16.0 * scale;

        return SizedBox(
          height: constraints.maxHeight,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
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
                    _SettingsCard(
                      scale: scale,
                      radius: cardRadius,
                      onProfileSettingsPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EducatorProfileScreen(),
                          ),
                        );
                        widget.onProfileUpdated?.call();
                      },
                      onAccountSettingsPressed: () {
                        showAccountSettingsDialog(context);
                      },
                      onLogoutPressed: _handleLogout,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SettingsCard extends StatefulWidget {
  const _SettingsCard({
    required this.scale,
    required this.radius,
    required this.onProfileSettingsPressed,
    required this.onAccountSettingsPressed,
    required this.onLogoutPressed,
  });
  final double scale;
  final double radius;
  final VoidCallback onProfileSettingsPressed;
  final VoidCallback onAccountSettingsPressed;
  final VoidCallback onLogoutPressed;

  @override
  State<_SettingsCard> createState() => _SettingsCardState();
}

class _SettingsCardState extends State<_SettingsCard> {
  @override
  Widget build(BuildContext context) {
    final scale = widget.scale;
    final radius = widget.radius;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final foregroundColor = isDarkMode ? Colors.white : _educatorCardSurface;
    final cardBackground = isDarkMode
        ? _educatorCardSurface
        : Colors.white.withValues(alpha: 0.9);
    final optionColor = isDarkMode
        ? _educatorChipGreen
        : const Color(0xFFEAF4F7);
    final optionForegroundColor = isDarkMode
        ? Colors.white
        : _educatorCardSurface;

    return _CardContainer(
      radius: radius,
      scale: scale,
      backgroundColor: cardBackground,
      borderColor: isDarkMode
          ? Colors.white.withValues(alpha: 0.15)
          : _educatorAccentCyan.withValues(alpha: 0.5),
      child: Padding(
        padding: EdgeInsets.all(18 * scale),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.settings,
                  color: isDarkMode ? _educatorAccentCyan : foregroundColor,
                  size: 24 * scale,
                ),
                SizedBox(width: 8 * scale),
                Text(
                  'Settings',
                  style: TextStyle(
                    color: foregroundColor,
                    fontSize: 20 * scale,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20 * scale),
            _SettingsPill(
              label: 'Profile Settings',
              icon: Icons.person,
              color: optionColor,
              foregroundColor: optionForegroundColor,
              scale: scale,
              onTap: widget.onProfileSettingsPressed,
            ),
            SizedBox(height: 14 * scale),
            _SettingsPill(
              label: 'Account Settings',
              icon: Icons.settings,
              color: optionColor,
              foregroundColor: optionForegroundColor,
              scale: scale,
              onTap: widget.onAccountSettingsPressed,
            ),
            SizedBox(height: 14 * scale),
            ThemeModeSwitchTile(
              scale: scale,
              backgroundColor: isDarkMode
                  ? const Color(0xFF32657D)
                  : const Color(0xFFEAF4F7),
              foregroundColor: foregroundColor,
              iconColor: foregroundColor,
              borderColor: isDarkMode
                  ? Colors.white.withValues(alpha: 0.12)
                  : null,
            ),
            SizedBox(height: 14 * scale),
            _SettingsPill(
              label: 'Log Out',
              icon: Icons.logout,
              color: _educatorStatusRed,
              foregroundColor: Colors.white,
              scale: scale,
              onTap: widget.onLogoutPressed,
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsPill extends StatefulWidget {
  const _SettingsPill({
    required this.label,
    required this.icon,
    required this.color,
    required this.foregroundColor,
    required this.scale,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Color foregroundColor;
  final double scale;
  final VoidCallback onTap;

  @override
  State<_SettingsPill> createState() => _SettingsPillState();
}

class _SettingsPillState extends State<_SettingsPill> {
  @override
  Widget build(BuildContext context) {
    final scale = widget.scale;
    return InkWell(
      borderRadius: BorderRadius.circular(22 * scale),
      onTap: widget.onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 18 * scale,
          vertical: 16 * scale,
        ),
        decoration: BoxDecoration(
          color: widget.color,
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
            Icon(widget.icon, color: widget.foregroundColor, size: 20 * scale),
            SizedBox(width: 12 * scale),
            Expanded(
              child: Text(
                widget.label,
                style: TextStyle(
                  color: widget.foregroundColor,
                  fontSize: 16 * scale,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: widget.foregroundColor,
              size: 16 * scale,
            ),
          ],
        ),
      ),
    );
  }
}

class _CardContainer extends StatefulWidget {
  const _CardContainer({
    required this.child,
    required this.radius,
    required this.scale,
    required this.backgroundColor,
    this.borderColor,
  });

  final Widget child;
  final double radius;
  final double scale;
  final Color backgroundColor;
  final Color? borderColor;

  @override
  State<_CardContainer> createState() => _CardContainerState();
}

class _CardContainerState extends State<_CardContainer> {
  @override
  Widget build(BuildContext context) {
    final radius = widget.radius;
    final scale = widget.scale;
    final borderColor = widget.borderColor;
    return Container(
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(radius),
        border: borderColor != null
            ? Border.all(color: borderColor, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10 * scale,
            offset: Offset(0, 6 * scale),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: widget.child,
    );
  }
}
