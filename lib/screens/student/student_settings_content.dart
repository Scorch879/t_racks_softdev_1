import 'package:flutter/material.dart';
import 'package:t_racks_softdev_1/commonWidgets/theme_mode_switch_tile.dart';
import 'package:t_racks_softdev_1/services/auth_service.dart';
import 'package:t_racks_softdev_1/screens/student/student_profile_screen.dart';
// Adjust this import path if you placed the file elsewhere
import 'package:t_racks_softdev_1/commonWidgets/commonwidgets.dart';

const _cardSurface = Color(0xFF0C3343);
const _chipGreen = Color(0xFF4CAF50);
const _statusRed = Color(0xFFE53935);
const _borderTeal = Color(0xFF6AAFBF);

class StudentSettingsContent extends StatefulWidget {
  const StudentSettingsContent({
    super.key,
    required this.onNotificationsPressed,
    this.onProfileUpdated,
  });

  final VoidCallback onNotificationsPressed;
  final VoidCallback? onProfileUpdated;

  @override
  State<StudentSettingsContent> createState() => _StudentSettingsContentState();
}

class _StudentSettingsContentState extends State<StudentSettingsContent> {
  Future<void> onProfileSettingsPressed() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const StudentProfileScreen()),
    );
    widget.onProfileUpdated?.call();
  }

  void onAccountSettingsPressed() {
    showAccountSettingsDialog(context);
  }

  void onDeleteAccountPressed() {}

  void onLogoutPressed() {
    showDialog(
      context: context,
      // Updated to use the imported public widget
      builder: (context) => LogoutDialog(onConfirm: _handleLogout),
    );
  }

  Future<void> _handleLogout() async {
    await AuthService().logoutAndNavigateToLogin(context);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        final width = constraints.maxWidth;
        final scale = (width / 430).clamp(0.8, 1.6);
        final horizontalPadding = 16.0 * scale;
        final cardRadius = 16.0 * scale;

        return Container(
          constraints: const BoxConstraints.expand(),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDarkMode
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
                    ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Opacity(
                  opacity: 0.3,
                  child: Image.asset(
                    'assets/images/squigglytexture.png',
                    width: double.infinity,
                    height: double.infinity,
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
                        _SettingsCard(
                          scale: scale,
                          radius: cardRadius,
                          onProfileSettingsPressed: onProfileSettingsPressed,
                          onAccountSettingsPressed: onAccountSettingsPressed,
                          onLogoutPressed: onLogoutPressed,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final foregroundColor = isDarkMode ? Colors.white : _cardSurface;
    final cardBackground = isDarkMode ? _cardSurface : Colors.white;
    final optionColor = isDarkMode ? _chipGreen : const Color(0xFFEAF4F7);
    final optionForegroundColor = isDarkMode ? Colors.white : _cardSurface;

    return _CardContainer(
      radius: 16,
      scale: scale,
      border: Border.all(
        color: isDarkMode ? const Color(0xFFBDBBBB) : _borderTeal,
        width: 0.5,
      ),
      backgroundColor: cardBackground,
      background: _CardBackground(opacity: isDarkMode ? 0.3 : 0.08),
      child: Padding(
        padding: EdgeInsets.all(18 * scale),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings, color: foregroundColor, size: 24 * scale),
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
              labelFontSize: 16 * scale,
              labelFontWeight: FontWeight.w100,
              icon: Icons.person,
              color: optionColor,
              foregroundColor: optionForegroundColor,
              scale: scale,
              onTap: widget.onProfileSettingsPressed,
            ),
            SizedBox(height: 14 * scale),
            _SettingsPill(
              label: 'Account Settings',
              labelFontSize: 16 * scale,
              labelFontWeight: FontWeight.w100,
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
              labelFontSize: 16 * scale,
              labelFontWeight: FontWeight.w100,
              icon: Icons.logout_rounded,
              color: _statusRed,
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
    this.labelFontSize,
    this.labelFontWeight,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Color foregroundColor;
  final double scale;
  final VoidCallback onTap;

  final double? labelFontSize;
  final FontWeight? labelFontWeight;

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
              blurRadius: 3,
              offset: const Offset(0, 6),
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
                  fontSize: widget.labelFontSize ?? 16 * scale,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: widget.foregroundColor,
              size: 22 * scale,
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
    this.border,
    this.background,
  });

  final Widget child;
  final double radius;
  final double scale;
  final Color backgroundColor;
  final Border? border;
  final Widget? background;

  @override
  State<_CardContainer> createState() => _CardContainerState();
}

class _CardContainerState extends State<_CardContainer> {
  @override
  Widget build(BuildContext context) {
    final radius = widget.radius;
    final scale = widget.scale;
    final background = widget.background;
    return Container(
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(radius),
        border: widget.border,
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
        children: [if (background != null) background, widget.child],
      ),
    );
  }
}

class _CardBackground extends StatefulWidget {
  const _CardBackground({required this.opacity});

  final double opacity;

  @override
  State<_CardBackground> createState() => _CardBackgroundState();
}

class _CardBackgroundState extends State<_CardBackground> {
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Opacity(
        opacity: widget.opacity,
        child: Image.asset(
          'assets/images/squigglytexture.png',
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
