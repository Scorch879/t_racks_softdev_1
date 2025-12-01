import 'package:flutter/material.dart';
import 'package:t_racks_softdev_1/services/database_service.dart';
import 'package:t_racks_softdev_1/services/models/class_model.dart';

const _bgTeal = Color(0xFF167C94);
// Summary/top-stat cards background (dark slate sampled from Figma)
const _summaryCardSurface = Color(0xFF0F3A40);
// Panel behind "My Classes"
const _myClassesPanel = Color(0xFF0B2F33);
// Class list cards must be this exact color per request
const _myClassCardSurface = Color(0xFF32657D);
const _cardSurface = Color(0xFF173C45);
const _accentCyan = Color(0xFF93C0D3);
const _chipGreen = Color(0xFF4DBD88);
const _statusRed = Color(0xFFDA6A6A);
const _statusYellow = Color(0xFFFFC107);

// --- MAIN CLASSES CONTENT VIEW ---
class StudentClassClassesContent extends StatefulWidget {
  const StudentClassClassesContent({super.key});

  @override
  State<StudentClassClassesContent> createState() => _StudentClassClassesContentState();
}

class _StudentClassClassesContentState extends State<StudentClassClassesContent> {
  final _databaseService = DatabaseService();
  late Future<List<StudentClass>> _classesFuture;

  @override
  void initState() {
    super.initState();
    _classesFuture = _databaseService.getStudentClasses();
  }

  void _showClassDetails(String classId) {
    showDialog(
      context: context,
      builder: (context) {
        return _ClassDetailsDialog(classId: classId);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final scale = (width / 430).clamp(0.8, 1.6);
        final horizontalPadding = 16.0 * scale;

        return FutureBuilder<List<StudentClass>>(
          future: _classesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.white));
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
            }

            final classes = snapshot.data ?? [];

            return Stack(
              children: [
                // Background Texture
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.12,
                    child: Image.asset(
                      'assets/images/squigglytexture.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Scrollable Content
                SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    12 * scale,
                    horizontalPadding,
                    100 * scale, // Padding for bottom nav
                  ),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 980),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. Top Summary Row
                          Row(
                            children: [
                              Expanded(
                                child: _SummaryCard(
                                  scale: scale,
                                  icon: Icons.bookmark_rounded,
                                  value: classes.length.toString(),
                                  label: 'Total Classes',
                                  iconColor: _chipGreen,
                                ),
                              ),
                              SizedBox(width: 12 * scale),
                              Expanded(
                                child: _SummaryCard(
                                  scale: scale,
                                  icon: Icons.bar_chart_rounded,
                                  value: '1', // This can be calculated later
                                  label: 'Absences This Week',
                                  iconColor: _chipGreen,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16 * scale),

                          // 2. Main 'My Classes' Container
                          Container(
                            padding: EdgeInsets.all(16 * scale),
                            decoration: BoxDecoration(
                              color: _myClassesPanel,
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
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Header
                                _MyClassesHeader(scale: scale),
                                SizedBox(height: 12 * scale),
                                
                                // Search
                                _SearchBar(scale: scale),
                                SizedBox(height: 12 * scale),

                                // Class List
                                if (classes.isEmpty)
                                  Padding(
                                    padding: EdgeInsets.symmetric(vertical: 60 * scale),
                                    child: Text(
                                      'No classes yet',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 18 * scale,
                                      ),
                                    ),
                                  )
                                else
                                  ...classes.map((sClass) {
                                    return Padding(
                                      padding: EdgeInsets.only(bottom: 12 * scale),
                                      child: GestureDetector(
                                        onTap: () => _showClassDetails(sClass.id),
                                        child: _ClassCard(
                                          scale: scale,
                                          title: sClass.name ?? 'Unnamed Class',
                                          students: 0, // This data would need another query
                                          present: 0, // This data would need another query
                                          time: sClass.schedule ?? 'No schedule',
                                          status: sClass.status ?? 'Unknown',
                                          statusColor: _getStatusColor(sClass.status),
                                          cardColor: _myClassCardSurface,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                              ],
                            ),
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
      },
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'ongoing':
        return _chipGreen;
      case 'absent':
        return _statusRed;
      case 'upcoming':
        return _statusYellow;
      default:
        return Colors.grey;
    }
  }
}

class _ClassDetailsDialog extends StatefulWidget {
  final String classId;
  const _ClassDetailsDialog({required this.classId});

  @override
  State<_ClassDetailsDialog> createState() => _ClassDetailsDialogState();
}

class _ClassDetailsDialogState extends State<_ClassDetailsDialog> {
  final _databaseService = DatabaseService();
  late final Future<StudentClass> _classDetailsFuture;

  @override
  void initState() {
    super.initState();
    _classDetailsFuture = _databaseService.getClassDetails(widget.classId);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _myClassesPanel,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: FutureBuilder<StudentClass>(
        future: _classDetailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator(color: Colors.white)),
            );
          }

          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)),
            );
          }

          final sClass = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sClass.name ?? 'Class Details',
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                _DetailItem(label: 'Subject', value: sClass.subject),
                const Divider(color: Colors.white24),
                _DetailItem(label: 'Schedule', value: sClass.schedule),
                const Divider(color: Colors.white24),
                _DetailItem(label: 'Status', value: sClass.status),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close', style: TextStyle(color: _accentCyan)),
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}

// --- SCHEDULE CONTENT VIEW (Now Stateful) ---
class StudentClassScheduleContent extends StatefulWidget {
  const StudentClassScheduleContent({super.key});

  @override
  State<StudentClassScheduleContent> createState() => _StudentClassScheduleContentState();
}

class _StudentClassScheduleContentState extends State<StudentClassScheduleContent> {
  @override
  Widget build(BuildContext context) {
    // Render the Classes content in place of the daily schedule cards.
    // Using the Classes component directly avoids nested scrollables
    // and shows totals, absences, search, and class cards as requested.
    return const StudentClassClassesContent();
  }
}

// --- SETTINGS CONTENT VIEW  ---
class StudentClassSettingsContent extends StatefulWidget {
  const StudentClassSettingsContent({super.key});

  @override
  State<StudentClassSettingsContent> createState() => _StudentClassSettingsContentState();
}

class _StudentClassSettingsContentState extends State<StudentClassSettingsContent> {
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
                child: Align(
                  alignment: Alignment.topCenter,
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

class _DetailItem extends StatelessWidget {
  final String label;
  final String? value;

  const _DetailItem({required this.label, this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 4),
          Text(value ?? 'Not available', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// --- HELPER WIDGETS ---

class _SummaryCard extends StatefulWidget {
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
  State<_SummaryCard> createState() => _SummaryCardState();
}

class _SummaryCardState extends State<_SummaryCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20 * widget.scale),
      decoration: BoxDecoration(
        color: _summaryCardSurface,
        borderRadius: BorderRadius.circular(16 * widget.scale),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 10 * widget.scale,
            offset: Offset(0, 6 * widget.scale),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(widget.icon, color: widget.iconColor, size: 32 * widget.scale),
          SizedBox(height: 12 * widget.scale),
          Text(
            widget.value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 32 * widget.scale,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 4 * widget.scale),
          Text(
            widget.label,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14 * widget.scale,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MyClassesHeader extends StatefulWidget {
  const _MyClassesHeader({required this.scale});
  final double scale;

  @override
  State<_MyClassesHeader> createState() => _MyClassesHeaderState();
}

class _MyClassesHeaderState extends State<_MyClassesHeader> {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.star_rounded,
          color: _accentCyan,
          size: 28 * widget.scale,
        ),
        SizedBox(width: 8 * widget.scale),
        Expanded(
          child: Text(
            'My Classes',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28 * widget.scale,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: Icon(
            Icons.add_circle_rounded,
            color: _chipGreen,
            size: 28 * widget.scale,
          ),
        ),
      ],
    );
  }
}

class _SearchBar extends StatefulWidget {
  const _SearchBar({required this.scale});
  final double scale;

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16 * widget.scale, vertical: 12 * widget.scale),
      decoration: BoxDecoration(
        color: const Color(0xFF6AAFBF).withOpacity(0.3),
        borderRadius: BorderRadius.circular(22 * widget.scale),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            color: Colors.white70,
            size: 20 * widget.scale,
          ),
          SizedBox(width: 12 * widget.scale),
          Expanded(
            child: Text(
              'Search Class',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16 * widget.scale,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClassCard extends StatefulWidget {
  const _ClassCard({
    required this.scale,
    required this.title,
    required this.students,
    required this.present,
    required this.time,
    required this.status,
    required this.statusColor,
    bool isUpcoming = false,
    this.cardColor,
  }) : isUpcoming = isUpcoming;

  final double scale;
  final String title;
  final int students;
  final int present;
  final String time;
  final String status;
  final Color statusColor;
  final bool isUpcoming;
  final Color? cardColor;

  @override
  State<_ClassCard> createState() => _ClassCardState();
}

class _ClassCardState extends State<_ClassCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16 * widget.scale),
      decoration: BoxDecoration(
        color: widget.cardColor ?? _cardSurface,
        borderRadius: BorderRadius.circular(16 * widget.scale),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 10 * widget.scale,
            offset: Offset(0, 6 * widget.scale),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20 * widget.scale,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 8 * widget.scale),
          Row(
            children: [
              Text(
                'Students ${widget.students}',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14 * widget.scale,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: 16 * widget.scale),
              Text(
                widget.isUpcoming ? 'Present Upcoming' : 'Present ${widget.present}',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14 * widget.scale,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 8 * widget.scale),
          Text(
            widget.time,
            style: TextStyle(
              color: Colors.white60,
              fontSize: 12 * widget.scale,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 12 * widget.scale),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 16 * widget.scale,
              vertical: 8 * widget.scale,
            ),
            decoration: BoxDecoration(
              color: widget.statusColor,
              borderRadius: BorderRadius.circular(20 * widget.scale),
            ),
            child: Text(
              widget.status,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14 * widget.scale,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatefulWidget {
  const _SettingsCard({required this.scale, required this.radius});
  final double scale;
  final double radius;

  @override
  State<_SettingsCard> createState() => _SettingsCardState();
}

class _SettingsCardState extends State<_SettingsCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _cardSurface,
        borderRadius: BorderRadius.circular(widget.radius),
        border: Border.all(
          color: const Color(0xFF6AAFBF).withOpacity(0.45),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 10 * widget.scale,
            offset: Offset(0, 6 * widget.scale),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(18 * widget.scale),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings, color: Colors.white, size: 24 * widget.scale),
                SizedBox(width: 8 * widget.scale),
                Text(
                  'Settings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20 * widget.scale,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20 * widget.scale),
            _SettingsPill(
              label: 'Profile Settings',
              icon: Icons.person,
              color: _chipGreen,
              scale: widget.scale,
            ),
            SizedBox(height: 14 * widget.scale),
            _SettingsPill(
              label: 'Account Settings',
              icon: Icons.settings,
              color: _chipGreen,
              scale: widget.scale,
            ),
            SizedBox(height: 14 * widget.scale),
            _SettingsPill(
              label: 'Delete Account',
              icon: Icons.person_off,
              color: _statusRed,
              scale: widget.scale,
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
  });

  final String label;
  final IconData icon;
  final Color color;
  final double scale;

  @override
  State<_SettingsPill> createState() => _SettingsPillState();
}

class _SettingsPillState extends State<_SettingsPill> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22 * widget.scale),
      onTap: () {},
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 18 * widget.scale, vertical: 16 * widget.scale),
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(22 * widget.scale),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 10 * widget.scale,
              offset: Offset(0, 6 * widget.scale),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(widget.icon, color: Colors.white, size: 20 * widget.scale),
            SizedBox(width: 12 * widget.scale),
            Expanded(
              child: Text(
                widget.label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16 * widget.scale,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.white, size: 22 * widget.scale),
          ],
        ),
      ),
    );
  }
}

class _ScheduleCard extends StatefulWidget {
  const _ScheduleCard({
    required this.scale,
    required this.day,
    required this.classes,
  });

  final double scale;
  final String day;
  final List<_ScheduleItem> classes;

  @override
  State<_ScheduleCard> createState() => _ScheduleCardState();
}

class _ScheduleCardState extends State<_ScheduleCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16 * widget.scale),
      decoration: BoxDecoration(
        color: _cardSurface,
        borderRadius: BorderRadius.circular(16 * widget.scale),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 10 * widget.scale,
            offset: Offset(0, 6 * widget.scale),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.day,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20 * widget.scale,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 12 * widget.scale),
          ...widget.classes.map((item) => Padding(
                padding: EdgeInsets.only(bottom: 12 * widget.scale),
                child: _ScheduleItemWidget(
                  scale: widget.scale,
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

class _ScheduleItemWidget extends StatefulWidget {
  const _ScheduleItemWidget({
    required this.scale,
    required this.item,
  });

  final double scale;
  final _ScheduleItem item;

  @override
  State<_ScheduleItemWidget> createState() => _ScheduleItemWidgetState();
}

class _ScheduleItemWidgetState extends State<_ScheduleItemWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12 * widget.scale),
      decoration: BoxDecoration(
        color: const Color(0xFF1B4A55),
        borderRadius: BorderRadius.circular(12 * widget.scale),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.item.time,
            style: TextStyle(
              color: _accentCyan,
              fontSize: 14 * widget.scale,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4 * widget.scale),
          Text(
            widget.item.className,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16 * widget.scale,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 4 * widget.scale),
          Row(
            children: [
              Icon(
                Icons.location_on_rounded,
                color: Colors.white60,
                size: 14 * widget.scale,
              ),
              SizedBox(width: 4 * widget.scale),
              Text(
                widget.item.location,
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 12 * widget.scale,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}