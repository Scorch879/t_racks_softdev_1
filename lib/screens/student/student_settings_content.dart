import 'package:flutter/material.dart';
import 'package:t_racks_softdev_1/services/auth_service.dart';
import 'package:t_racks_softdev_1/screens/student/student_profile_screen.dart';
// Adjust this import path if you placed the file elsewhere
import 'package:t_racks_softdev_1/commonWidgets/commonwidgets.dart';

const _bgTeal = Color(0xFF167C94);
const _cardSurface = Color(0xFF0C3343);
const _chipGreen = Color(0xFF4CAF50);
const _statusRed = Color(0xFFE53935);
const _borderTeal = Color(0xFF6AAFBF);

class StudentSettingsContent extends StatefulWidget {
  const StudentSettingsContent({
    super.key,
    required this.onNotificationsPressed,
  });

  final VoidCallback onNotificationsPressed;

  @override
  State<StudentSettingsContent> createState() => _StudentSettingsContentState();
}

class _StudentSettingsContentState extends State<StudentSettingsContent> {
  void onProfileSettingsPressed() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const StudentProfileScreen()),
    );
  }

  void onAccountSettingsPressed() {}

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
        final width = constraints.maxWidth;
        final scale = (width / 430).clamp(0.8, 1.6);
        final horizontalPadding = 16.0 * scale;
        final cardRadius = 16.0 * scale;

        return Container(
          constraints: const BoxConstraints.expand(),
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
    return _CardContainer(
      radius: 16,
      scale: scale,
      border: Border.all(color: const Color(0xFFBDBBBB), width: 0.5),
      background: const _CardBackground(),
      child: Padding(
        padding: EdgeInsets.all(18 * scale),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings, color: Colors.white, size: 24 * scale),
                SizedBox(width: 8 * scale),
                Text(
                  'Settings',
                  style: TextStyle(
                    color: Colors.white,
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
              color: _chipGreen,
              scale: scale,
              onTap: widget.onProfileSettingsPressed,
            ),
            SizedBox(height: 14 * scale),
            _SettingsPill(
              label: 'Account Settings',
              labelFontSize: 16 * scale,
              labelFontWeight: FontWeight.w100,
              icon: Icons.settings,
              color: _chipGreen,
              scale: scale,
              onTap: widget.onAccountSettingsPressed,
            ),
            SizedBox(height: 14 * scale),
            _SettingsPill(
              label: 'Log Out',
              labelFontSize: 16 * scale,
              labelFontWeight: FontWeight.w100,
              icon: Icons.logout_rounded,
              color: _statusRed,
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
    required this.scale,
    required this.onTap,
    this.labelFontSize,
    this.labelFontWeight,
  });

  final String label;
  final IconData icon;
  final Color color;
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
            Icon(widget.icon, color: Colors.white, size: 20 * scale),
            SizedBox(width: 12 * scale),
            Expanded(
              child: Text(
                widget.label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: widget.labelFontSize ?? 16 * scale,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white,
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
    this.border,
    this.background,
  });

  final Widget child;
  final double radius;
  final double scale;
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
        color: _cardSurface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: const Color(0xFFBDBBBB), width: 0.5),
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
        children: [if (background != null) background, widget.child],
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
      child: Opacity(
        opacity: 0.3,
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
