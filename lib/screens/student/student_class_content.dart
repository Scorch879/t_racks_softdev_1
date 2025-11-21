import 'package:flutter/material.dart';

const _bgTeal = Color(0xFF167C94);
const _cardSurface = Color(0xFF173C45);
const _accentCyan = Color(0xFF93C0D3);
const _chipGreen = Color(0xFF4DBD88);
const _statusRed = Color(0xFFDA6A6A);
const _statusYellow = Color(0xFFFFC107);

// Home Content View
class StudentClassHomeContent extends StatelessWidget {
  const StudentClassHomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final scale = (width / 430).clamp(0.8, 1.6);
        final horizontalPadding = 16.0 * scale;

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
                      Row(
                        children: [
                          Expanded(
                            child: _SummaryCard(
                              scale: scale,
                              icon: Icons.bookmark_rounded,
                              value: '3',
                              label: 'Total Classes',
                              iconColor: _chipGreen,
                            ),
                          ),
                          SizedBox(width: 12 * scale),
                          Expanded(
                            child: _SummaryCard(
                              scale: scale,
                              icon: Icons.bar_chart_rounded,
                              value: '1',
                              label: 'Absences This Week',
                              iconColor: _chipGreen,
                            ),
                          ),
                        ],
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

// Classes Content View (Main View)
class StudentClassClassesContent extends StatelessWidget {
  const StudentClassClassesContent({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final scale = (width / 430).clamp(0.8, 1.6);
        final horizontalPadding = 16.0 * scale;

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
                      _MyClassesHeader(scale: scale),
                      SizedBox(height: 16 * scale),
                      _SearchBar(scale: scale),
                      SizedBox(height: 16 * scale),
                      _ClassCard(
                        scale: scale,
                        title: 'Calculus 137',
                        students: 28,
                        present: 26,
                        time: 'Yesterday 10:00 AM',
                        status: 'Absent',
                        statusColor: _statusRed,
                      ),
                      SizedBox(height: 16 * scale),
                      _ClassCard(
                        scale: scale,
                        title: 'Physics 138',
                        students: 38,
                        present: 35,
                        time: 'Ongoing 9:00 AM',
                        status: 'Ongoing',
                        statusColor: _chipGreen,
                      ),
                      SizedBox(height: 16 * scale),
                      _ClassCard(
                        scale: scale,
                        title: 'Calculus 237',
                        students: 18,
                        present: 0,
                        time: 'Next: Tomorrow 9:00 AM',
                        status: 'Upcoming',
                        statusColor: _statusYellow,
                        isUpcoming: true,
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

// Schedule Content View
class StudentClassScheduleContent extends StatelessWidget {
  const StudentClassScheduleContent({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final scale = (width / 430).clamp(0.8, 1.6);
        final horizontalPadding = 16.0 * scale;

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
                      Text(
                        'Schedule',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28 * scale,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 24 * scale),
                      _ScheduleCard(
                        scale: scale,
                        day: 'Monday',
                        classes: [
                          _ScheduleItem(
                            time: '9:00 AM - 10:30 AM',
                            className: 'Calculus 137',
                            location: 'Room 201',
                          ),
                          _ScheduleItem(
                            time: '2:00 PM - 3:30 PM',
                            className: 'Physics 138',
                            location: 'Room 305',
                          ),
                        ],
                      ),
                      SizedBox(height: 16 * scale),
                      _ScheduleCard(
                        scale: scale,
                        day: 'Tuesday',
                        classes: [
                          _ScheduleItem(
                            time: '10:00 AM - 11:30 AM',
                            className: 'Calculus 237',
                            location: 'Room 201',
                          ),
                        ],
                      ),
                      SizedBox(height: 16 * scale),
                      _ScheduleCard(
                        scale: scale,
                        day: 'Wednesday',
                        classes: [
                          _ScheduleItem(
                            time: '9:00 AM - 10:30 AM',
                            className: 'Calculus 137',
                            location: 'Room 201',
                          ),
                          _ScheduleItem(
                            time: '2:00 PM - 3:30 PM',
                            className: 'Physics 138',
                            location: 'Room 305',
                          ),
                        ],
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

// Settings Content View
class StudentClassSettingsContent extends StatelessWidget {
  const StudentClassSettingsContent({super.key});

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
                        _SettingsCard(scale: scale, radius: cardRadius),
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

// Helper Widgets
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.scale,
    required this.icon,
    required this.value,
    required this.label,
    required this.iconColor,
  });

  final double scale;
  final IconData icon;
  final String value;
  final String label;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20 * scale),
      decoration: BoxDecoration(
        color: _cardSurface,
        borderRadius: BorderRadius.circular(16 * scale),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 10 * scale,
            offset: Offset(0, 6 * scale),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 32 * scale),
          SizedBox(height: 12 * scale),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 32 * scale,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 4 * scale),
          Text(
            label,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14 * scale,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MyClassesHeader extends StatelessWidget {
  const _MyClassesHeader({required this.scale});
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.star_rounded,
          color: _accentCyan,
          size: 28 * scale,
        ),
        SizedBox(width: 8 * scale),
        Expanded(
          child: Text(
            'My Classes',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28 * scale,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: Icon(
            Icons.add_circle_rounded,
            color: _chipGreen,
            size: 28 * scale,
          ),
        ),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.scale});
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 12 * scale),
      decoration: BoxDecoration(
        color: const Color(0xFF6AAFBF).withOpacity(0.3),
        borderRadius: BorderRadius.circular(22 * scale),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            color: Colors.white70,
            size: 20 * scale,
          ),
          SizedBox(width: 12 * scale),
          Expanded(
            child: Text(
              'Search Class',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16 * scale,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  const _ClassCard({
    required this.scale,
    required this.title,
    required this.students,
    required this.present,
    required this.time,
    required this.status,
    required this.statusColor,
    this.isUpcoming = false,
  });

  final double scale;
  final String title;
  final int students;
  final int present;
  final String time;
  final String status;
  final Color statusColor;
  final bool isUpcoming;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16 * scale),
      decoration: BoxDecoration(
        color: _cardSurface,
        borderRadius: BorderRadius.circular(16 * scale),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 10 * scale,
            offset: Offset(0, 6 * scale),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20 * scale,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 8 * scale),
          Row(
            children: [
              Text(
                'Students $students',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14 * scale,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: 16 * scale),
              Text(
                isUpcoming ? 'Present Upcoming' : 'Present $present',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14 * scale,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 8 * scale),
          Text(
            time,
            style: TextStyle(
              color: Colors.white60,
              fontSize: 12 * scale,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 12 * scale),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 16 * scale,
              vertical: 8 * scale,
            ),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(20 * scale),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14 * scale,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.scale, required this.radius});
  final double scale;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _cardSurface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: const Color(0xFF6AAFBF).withOpacity(0.45),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 10 * scale,
            offset: Offset(0, 6 * scale),
          ),
        ],
      ),
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
            ),
            SizedBox(height: 14 * scale),
            _SettingsPill(
              label: 'Account Settings',
              icon: Icons.settings,
              color: _chipGreen,
              scale: scale,
            ),
            SizedBox(height: 14 * scale),
            _SettingsPill(
              label: 'Delete Account',
              icon: Icons.person_off,
              color: _statusRed,
              scale: scale,
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsPill extends StatelessWidget {
  const _SettingsPill({
    required this.label,
    required this.icon,
    required this.color,
    required this.scale,
  });

  final String label;
  final IconData icon;
  final Color color;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22 * scale),
      onTap: () {},
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 18 * scale, vertical: 16 * scale),
        decoration: BoxDecoration(
          color: color,
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
            Icon(icon, color: Colors.white, size: 20 * scale),
            SizedBox(width: 12 * scale),
            Expanded(
              child: Text(
                label,
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

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({
    required this.scale,
    required this.day,
    required this.classes,
  });

  final double scale;
  final String day;
  final List<_ScheduleItem> classes;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16 * scale),
      decoration: BoxDecoration(
        color: _cardSurface,
        borderRadius: BorderRadius.circular(16 * scale),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 10 * scale,
            offset: Offset(0, 6 * scale),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            day,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20 * scale,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 12 * scale),
          ...classes.map((item) => Padding(
                padding: EdgeInsets.only(bottom: 12 * scale),
                child: _ScheduleItemWidget(
                  scale: scale,
                  item: item,
                ),
              )),
        ],
      ),
    );
  }
}

class _ScheduleItem {
  const _ScheduleItem({
    required this.time,
    required this.className,
    required this.location,
  });

  final String time;
  final String className;
  final String location;
}

class _ScheduleItemWidget extends StatelessWidget {
  const _ScheduleItemWidget({
    required this.scale,
    required this.item,
  });

  final double scale;
  final _ScheduleItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12 * scale),
      decoration: BoxDecoration(
        color: const Color(0xFF1B4A55),
        borderRadius: BorderRadius.circular(12 * scale),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.time,
            style: TextStyle(
              color: _accentCyan,
              fontSize: 14 * scale,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4 * scale),
          Text(
            item.className,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16 * scale,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 4 * scale),
          Row(
            children: [
              Icon(
                Icons.location_on_rounded,
                color: Colors.white60,
                size: 14 * scale,
              ),
              SizedBox(width: 4 * scale),
              Text(
                item.location,
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 12 * scale,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

