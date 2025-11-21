import 'package:flutter/material.dart';

const _bgTeal = Color(0xFF167C94);
const _cardSurface = Color(0xFF173C45);
const _chipGreen = Color(0xFF4DBD88);
const _statusRed = Color(0xFFDA6A6A);
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
  void onProfileSettingsPressed() {}

  void onAccountSettingsPressed() {}

  void onDeleteAccountPressed() {}

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final scale = (width / 430).clamp(0.8, 1.6);
        final horizontalPadding = 16.0 * scale;
        final cardRadius = 16.0 * scale;

        return Container(
          width: double.infinity,
          height: double.infinity,
          color: _bgTeal,
          child: Stack(
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
                        _SettingsCard(
                          scale: scale,
                          radius: cardRadius,
                          onProfileSettingsPressed: onProfileSettingsPressed,
                          onAccountSettingsPressed: onAccountSettingsPressed,
                          onDeleteAccountPressed: onDeleteAccountPressed,
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
    required this.onDeleteAccountPressed,
  });
  final double scale;
  final double radius;
  final VoidCallback onProfileSettingsPressed;
  final VoidCallback onAccountSettingsPressed;
  final VoidCallback onDeleteAccountPressed;

  @override
  State<_SettingsCard> createState() => _SettingsCardState();
}

class _SettingsCardState extends State<_SettingsCard> {
  @override
  Widget build(BuildContext context) {
    final scale = widget.scale;
    final radius = widget.radius;
    return _CardContainer(
      radius: radius,
      scale: scale,
      borderColor: _borderTeal.withOpacity(0.45),
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
              icon: Icons.person,
              color: _chipGreen,
              scale: scale,
              onTap: widget.onProfileSettingsPressed,
            ),
            SizedBox(height: 14 * scale),
            _SettingsPill(
              label: 'Account Settings',
              icon: Icons.settings,
              color: _chipGreen,
              scale: scale,
              onTap: widget.onAccountSettingsPressed,
            ),
            SizedBox(height: 14 * scale),
            _SettingsPill(
              label: 'Delete Account',
              icon: Icons.person_off,
              color: _statusRed,
              scale: scale,
              onTap: widget.onDeleteAccountPressed,
            ),
          ],
        ),
      ),
      background: const _CardBackground(),
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
  });

  final String label;
  final IconData icon;
  final Color color;
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
        padding: EdgeInsets.symmetric(horizontal: 18 * scale, vertical: 16 * scale),
        decoration: BoxDecoration(
          color: widget.color,
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
            Icon(widget.icon, color: Colors.white, size: 20 * scale),
            SizedBox(width: 12 * scale),
            Expanded(
              child: Text(
                widget.label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16 * scale,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.white, size: 22 * scale),
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
    this.borderColor,
    this.background,
  });

  final Widget child;
  final double radius;
  final double scale;
  final Color? borderColor;
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
    final borderColor = widget.borderColor;
    return Container(
      decoration: BoxDecoration(
        color: _cardSurface,
        borderRadius: BorderRadius.circular(radius),
        border: borderColor != null ? Border.all(color: borderColor) : null,
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
      child: Opacity(
        opacity: 0.08,
        child: Image.asset(
          'assets/images/squigglytexture.png',
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

