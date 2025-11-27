import 'package:flutter/material.dart';
import 'package:t_racks_softdev_1/screens/student/student_camera_screen.dart';

const _bgTeal = Color(0xFF167C94);
const _cardSurface = Color(0xFF173C45);
const _cardHeader = Color(0xFF1B4A55);
const _accentCyan = Color(0xFF93C0D3);
const _chipGreen = Color(0xFF4DBD88);
const _statusRed = Color(0xFFDA6A6A);
const _titleRed = Color(0xFFE57373);

class StudentHomeContent extends StatefulWidget {
  const StudentHomeContent({
    super.key,
    required this.onNotificationsPressed,
  });

  final VoidCallback onNotificationsPressed;

  @override
  State<StudentHomeContent> createState() => _StudentHomeContentState();
}

class _StudentHomeContentState extends State<StudentHomeContent> {
  void onOngoingClassStatusPressed() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const StudentCameraScreen(),
      ),
    );
  }

  void onFilterAllClasses() {}

  void onClassPressed() {}

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final scale = (width / 430).clamp(0.8, 1.6);
        final horizontalPadding = 16.0 * scale;
        final cardRadius = 16.0 * scale;

        return Stack(
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
    return _CardContainer(
      radius: widget.radius,
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
                    Icon(Icons.access_time_filled_rounded,
                        color: _chipGreen, size: 28 * scale),
                    SizedBox(width: 8 * scale),
                    Text(
                      'Ongoing',
                      style: TextStyle(
                        color: _chipGreen,
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
                        'Physics 138',
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
                Material(
                  color: _chipGreen,
                  borderRadius: BorderRadius.circular(20 * scale),
                  child: InkWell(
                    onTap: widget.onOngoingClassStatusPressed,
                    borderRadius: BorderRadius.circular(20 * scale),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        vertical: 12 * scale,
                        horizontal: 18 * scale,
                      ),
                      child: Text(
                        'Ongoing',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12 * scale,
                          fontWeight: FontWeight.w700,
                        ),
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
  @override
  Widget build(BuildContext context) {
    final scale = widget.scale;
    return _CardContainer(
      radius: widget.radius,
      scale: scale,
      borderColor: const Color(0xFF6AAFBF).withOpacity(0.55),
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
              trailingText: 'Total: 3',
              backgroundColor: _chipGreen,
            ),
            SizedBox(height: 16 * scale),
            _ClassRow(
              scale: scale,
              title: 'Calculus 137',
              statusText: 'Absent',
              statusColor: _statusRed,
              onTap: widget.onClassPressed,
            ),
            SizedBox(height: 16 * scale),
            _ClassRow(
              scale: scale,
              title: 'Physics 138',
              statusText: 'Ongoing',
              statusColor: _chipGreen,
              onTap: widget.onClassPressed,
            ),
            SizedBox(height: 16 * scale),
            _ClassRow(
              scale: scale,
              title: 'Calculus 237',
              statusText: 'Upcoming',
              statusColor: _chipGreen,
              onTap: widget.onClassPressed,
            ),
          ],
        ),
      ),
    );
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

class _ClassRow extends StatefulWidget {
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
  State<_ClassRow> createState() => _ClassRowState();
}

class _ClassRowState extends State<_ClassRow> {
  @override
  Widget build(BuildContext context) {
    final scale = widget.scale;
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 16 * scale),
        decoration: BoxDecoration(
          color: widget.statusColor,
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
                widget.title,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18 * scale,
                ),
              ),
            ),
            Text(
              widget.statusText,
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
    return Container(
      decoration: BoxDecoration(
        color: _cardSurface,
        borderRadius: BorderRadius.circular(widget.radius),
        border: widget.borderColor != null ? Border.all(color: widget.borderColor!) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 10 * widget.scale,
            offset: Offset(0, 6 * widget.scale),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (widget.background != null) widget.background!,
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
        opacity: 0.0,
        child: Image.asset(
          'assets/images/squigglytexture.png',
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

