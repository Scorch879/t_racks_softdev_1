import 'package:flutter/material.dart';
import 'package:t_racks_softdev_1/services/student_service.dart';
import 'package:t_racks_softdev_1/screens/camera_detection_screen.dart';

const _bgTeal = Color(0xFF167C94);
const _cardSurface = Color(0xFF173C45);
const _cardHeader = Color(0xFF1B4A55);
const _accentCyan = Color(0xFF93C0D3);
const _chipGreen = Color(0xFF4DBD88);
const _statusRed = Color(0xFFDA6A6A);
const _titleRed = Color(0xFFE57373);

class StudentHomeScreen extends StatelessWidget {
  const StudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        registerStudentPageContext(context);
        final width = constraints.maxWidth;
        final scale = (width / 430).clamp(0.8, 1.6);
        final horizontalPadding = 16.0 * scale;
        final cardRadius = 16.0 * scale;

    return Scaffold(
          backgroundColor: _bgTeal,
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(64 * scale),
            child: _TopBar(scale: scale),
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
                        _WelcomeAndOngoingCard(scale: scale, radius: cardRadius),
                        SizedBox(height: 16 * scale),
                        _MyClassesCard(scale: scale, radius: cardRadius),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: _BottomNav(scale: scale),
          // Test button for camera detection (remove in production)
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CameraDetectionScreen(),
                ),
              );
            },
            backgroundColor: Colors.blue,
            child: const Icon(Icons.camera_alt, color: Colors.white),
            tooltip: 'Test Camera Detection',
          ),
        );
      },
    );
  }
}

class _WelcomeAndOngoingCard extends StatelessWidget {
  const _WelcomeAndOngoingCard({required this.scale, required this.radius});
  final double scale;
  final double radius;

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
                  onTap: StudentService.onOngoingClassStatusPressed,
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
  const _TopBar({required this.scale});
  final double scale;

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
                  onPressed: StudentService.onNotificationsPressed,
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
  const _MyClassesCard({required this.scale, required this.radius});
  final double scale;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return _CardContainer(
      radius: radius,
      scale: scale,
      borderColor: const Color(0xFF6AAFBF).withOpacity(0.55),
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
              onTap: StudentService.onFilterAllClasses,
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
              onTap: StudentService.onClassPressed,
            ),
            SizedBox(height: 16 * scale),
            _ClassRow(
              scale: scale,
              title: 'Physics 138',
              statusText: 'Ongoing',
              statusColor: _chipGreen,
              onTap: StudentService.onClassPressed,
            ),
            SizedBox(height: 16 * scale),
            _ClassRow(
              scale: scale,
              title: 'Calculus 237',
              statusText: 'Upcoming',
              statusColor: _chipGreen,
              onTap: StudentService.onClassPressed,
            ),
          ],
        ),
      ),
      background: const _CardBackground(),
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
  const _BottomNav({required this.scale});
  final double scale;

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
            onTap: StudentService.onNavHome,
          ),
          _BottomItem(
            icon: Icons.calendar_month_rounded,
            label: 'Schedule',
            scale: scale,
            onTap: StudentService.onNavSchedule,
          ),
          _BottomItem(
            icon: Icons.settings_rounded,
            label: 'Settings',
            scale: scale,
            onTap: StudentService.onNavSettings,
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