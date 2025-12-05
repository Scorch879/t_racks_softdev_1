import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:t_racks_softdev_1/services/database_service.dart';
import 'package:t_racks_softdev_1/commonWidgets/join_class_dialog.dart';
import 'package:t_racks_softdev_1/services/models/class_model.dart';
import 'package:t_racks_softdev_1/services/models/attendance_model.dart';

const _bgTeal = Color(0xFF167C94);
// Summary/top-stat cards background (dark slate sampled from Figma)
const _darkBluePanel = Color(0xFF0C3343);
// Class list cards must be this exact color per request
const _myClassCardSurface = Color(0xFF32657D);
const _cardSurface = Color(0xFF0C3343);
const _accentCyan = Color(0xFF32657D);

// UPDATED GREEN COLOR
const _chipGreen = Color(0xFF7FE26B);

const _statusRed = Color(0xFFE26B6B);
const _statusOrange = Color(0xFFFF8442);

// --- MAIN CLASSES CONTENT VIEW ---
class StudentClassClassesContent extends StatefulWidget {
  const StudentClassClassesContent({super.key});

  @override
  State<StudentClassClassesContent> createState() =>
      _StudentClassClassesContentState();
}

class _StudentClassClassesContentState
    extends State<StudentClassClassesContent> {
  final _databaseService = DatabaseService();
  late Future<List<StudentClass>> _classesFuture;
  final Map<String, GlobalKey<__ClassCardState>> _cardKeys = {};

  // State for search functionality
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _classesFuture = _databaseService.getStudentClasses();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() => _searchQuery = _searchController.text);
  }

  void _refreshClasses() {
    // This triggers a re-fetch of the classes and rebuilds the FutureBuilder
    setState(() {
      _classesFuture = _databaseService.getStudentClasses();
    });
  }

  void _handleCardTap(String classId) {
    // Trigger the animation on the specific card that was tapped
    _cardKeys[classId]?.currentState?.triggerTapAnimation();
    _showClassDetails(classId);
  }

  void _showClassDetails(String classId) {
    showDialog(
      context: context,
      builder: (context) {
        return ClassDetailsDialog(classId: classId);
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
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }

            final classes = snapshot.data ?? [];

            // Filter the classes based on the search query
            final filteredClasses = classes.where((sClass) {
              final query = _searchQuery.toLowerCase().trim();
              if (query.isEmpty) return true;

              final name = sClass.name?.toLowerCase() ?? '';
              final subject = sClass.subject?.toLowerCase() ?? '';
              return name.contains(query) || subject.contains(query);
            }).toList();

            return SizedBox.expand(
              child: Stack(
                children: [
                  // Background Texture (stretches to full viewport height)
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.12,
                      child: SizedBox(
                        width: double.infinity,
                        height: MediaQuery.of(context).size.height,
                        child: Image.asset(
                          'assets/images/squigglytexture.png',
                          width: double.infinity,
                          height: MediaQuery.of(context).size.height,
                          fit: BoxFit.cover,
                        ),
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
                                  child: FutureBuilder<int>(
                                    future: _databaseService
                                        .getAbsencesThisWeek(),
                                    builder: (context, snapshot) {
                                      String value = '...';
                                      if (snapshot.connectionState ==
                                          ConnectionState.done) {
                                        if (snapshot.hasData) {
                                          value = snapshot.data!.toString();
                                        } else {
                                          value = '0'; // Show 0 on error
                                        }
                                      }
                                      return _SummaryCard(
                                        scale: scale,
                                        icon: Icons.bar_chart_rounded,
                                        value: value,
                                        label: 'Absences This Week',
                                        // Change icon color based on absences
                                        iconColor: (snapshot.data ?? 0) > 0
                                            ? _statusRed
                                            : _chipGreen,
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16 * scale),

                            // 2. Main 'My Classes' Container
                            Container(
                              padding: EdgeInsets.all(16 * scale),
                              decoration: BoxDecoration(
                                color: _darkBluePanel,
                                borderRadius: BorderRadius.circular(16 * scale),
                                border: Border.all(
                                  color: const Color(0xFFBDBBBB),
                                  width: 0.75,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.25),
                                    blurRadius: 10 * scale,
                                    offset: Offset(0, 6 * scale),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Header
                                  _MyClassesHeader(
                                    scale: scale,
                                    onAddPressed: () => showJoinClassDialog(
                                      context,
                                      _refreshClasses,
                                    ),
                                  ),
                                  SizedBox(height: 12 * scale),

                                  // Search
                                  _SearchBar(
                                    scale: scale,
                                    controller: _searchController,
                                  ),
                                  SizedBox(height: 12 * scale),

                                  // Class List
                                  if (filteredClasses.isEmpty)
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 60 * scale,
                                      ),
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
                                    ...filteredClasses.map((sClass) {
                                      // Ensure each card has a key
                                      _cardKeys.putIfAbsent(
                                        sClass.id,
                                        () => GlobalKey<__ClassCardState>(),
                                      );
                                      final dynamicStatus = getDynamicStatus(
                                        sClass,
                                        _chipGreen, // Ongoing
                                        _statusRed, // Absent
                                        _statusOrange, // Late
                                        _darkBluePanel, // Upcoming
                                        Colors.grey.shade600,
                                      ); // Done
                                      return Padding(
                                        padding: EdgeInsets.only(
                                          bottom: 12 * scale,
                                        ),
                                        child: GestureDetector(
                                          onTap: () =>
                                              _handleCardTap(sClass.id),
                                          child: _ClassCard(
                                            key: _cardKeys[sClass.id]!,
                                            scale: scale,
                                            title:
                                                sClass.name ?? 'Unnamed Class',
                                            subject: sClass.subject,
                                            students: sClass.studentCount,
                                            time:
                                                sClass.schedule ??
                                                'No schedule',
                                            status: dynamicStatus.text,
                                            statusColor: dynamicStatus.color,
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
              ),
            );
          },
        );
      },
    );
  }
}

class ClassDetailsDialog extends StatefulWidget {
  final String classId;
  const ClassDetailsDialog({super.key, required this.classId});

  @override
  State<ClassDetailsDialog> createState() => _ClassDetailsDialogState();
}

class _ClassDetailsDialogState extends State<ClassDetailsDialog> {
  final _databaseService = DatabaseService();
  late final Future<(StudentClass, List<AttendanceRecord>)>
  _detailsAndAttendanceFuture;

  @override
  void initState() {
    super.initState();
    _detailsAndAttendanceFuture = _fetchDetailsAndAttendance();
  }

  Future<(StudentClass, List<AttendanceRecord>)>
  _fetchDetailsAndAttendance() async {
    return await Future.wait([
      _databaseService.getClassDetails(widget.classId),
      _databaseService.getStudentAttendanceForClass(widget.classId),
    ]).then(
      (results) =>
          (results[0] as StudentClass, results[1] as List<AttendanceRecord>),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _darkBluePanel,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: FutureBuilder<(StudentClass, List<AttendanceRecord>)>(
        future: _detailsAndAttendanceFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 200,
              child: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            );
          }

          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.white),
              ),
            );
          }

          final sClass = snapshot.data!.$1;
          final attendanceHistory = snapshot.data!.$2;

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 600),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sClass.name ?? 'Class Details',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _DetailItem(label: 'Subject', value: sClass.subject),
                  const Divider(color: Colors.white24),
                  _DetailItem(
                    label: 'Schedule',
                    value: '${sClass.day} ${sClass.time}',
                  ),
                  const Divider(color: Colors.white24),
                  _DetailItem(label: 'Status', value: sClass.status),
                  const SizedBox(height: 24),
                  const Text(
                    'My Attendance History',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: attendanceHistory.isEmpty
                        ? const Center(
                            child: Text(
                              'No attendance records yet.',
                              style: TextStyle(color: Colors.white70),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            itemCount: attendanceHistory.length,
                            separatorBuilder: (context, index) =>
                                const Divider(color: Colors.white12, height: 1),
                            itemBuilder: (context, index) {
                              final record = attendanceHistory[index];
                              return _AttendanceHistoryItem(record: record);
                            },
                          ),
                  ),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Close',
                        style: TextStyle(color: _accentCyan),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AttendanceHistoryItem extends StatelessWidget {
  final AttendanceRecord record;
  const _AttendanceHistoryItem({required this.record});

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat.yMMMMd().format(record.date);
    final statusText = record.isPresent ? 'Present' : 'Absent';
    final statusColor = record.isPresent ? _chipGreen : _statusRed;

    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      title: Text(
        formattedDate,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: statusColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          statusText,
          // Used a darker color for text on the bright green pill to ensure readability
          style: TextStyle(
            color: record.isPresent ? _cardSurface : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

// --- SCHEDULE CONTENT VIEW (Now Stateful) ---
class StudentClassScheduleContent extends StatefulWidget {
  const StudentClassScheduleContent({super.key});

  @override
  State<StudentClassScheduleContent> createState() =>
      _StudentClassScheduleContentState();
}

class _StudentClassScheduleContentState
    extends State<StudentClassScheduleContent> {
  @override
  Widget build(BuildContext context) {
    return const StudentClassClassesContent();
  }
}

// --- SETTINGS CONTENT VIEW  ---
class StudentClassSettingsContent extends StatefulWidget {
  const StudentClassSettingsContent({super.key});

  @override
  State<StudentClassSettingsContent> createState() =>
      _StudentClassSettingsContentState();
}

class _StudentClassSettingsContentState
    extends State<StudentClassSettingsContent> {
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
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            value ?? 'Not available',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
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
        color: _darkBluePanel,
        borderRadius: BorderRadius.circular(16 * widget.scale),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10 * widget.scale,
            offset: Offset(0, 6 * widget.scale),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(widget.icon, color: widget.iconColor, size: 40 * widget.scale),
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
  const _MyClassesHeader({required this.scale, required this.onAddPressed});
  final double scale;
  final VoidCallback onAddPressed;

  @override
  State<_MyClassesHeader> createState() => _MyClassesHeaderState();
}

class _MyClassesHeaderState extends State<_MyClassesHeader> {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.star_rounded, color: _accentCyan, size: 28 * widget.scale),
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
        // UPDATED: Replaced simple IconButton with a Pill Button
        InkWell(
          onTap: widget.onAddPressed,
          borderRadius: BorderRadius.circular(20 * widget.scale),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: 16 * widget.scale,
              vertical: 8 * widget.scale,
            ),
            decoration: BoxDecoration(
              color: _chipGreen,
              borderRadius: BorderRadius.circular(20 * widget.scale),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add,
                  color: _cardSurface, // Dark icon for contrast
                  size: 20 * widget.scale,
                ),
                SizedBox(width: 6 * widget.scale),
                Text(
                  'Join class',
                  style: TextStyle(
                    color: _cardSurface, // Dark text for contrast
                    fontSize: 14 * widget.scale,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchBar extends StatefulWidget {
  const _SearchBar({required this.scale, required this.controller});
  final double scale;
  final TextEditingController controller;

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      style: TextStyle(color: Colors.white, fontSize: 16 * widget.scale),
      decoration: InputDecoration(
        hintText: 'Search Class by Name or Subject',
        hintStyle: TextStyle(
          color: Colors.white70,
          fontSize: 16 * widget.scale,
        ),
        prefixIcon: Icon(
          Icons.search_rounded,
          color: Colors.white70,
          size: 20 * widget.scale,
        ),
        filled: true,
        fillColor: const Color(0xFF6AAFBF).withOpacity(0.3),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16 * widget.scale,
          vertical: 12 * widget.scale,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22 * widget.scale),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22 * widget.scale),
          borderSide: const BorderSide(color: _chipGreen, width: 2),
        ),
      ),
    );
  }
}

class _ClassCard extends StatefulWidget {
  const _ClassCard({
    super.key,
    required this.scale,
    required this.title,
    this.subject,
    required this.students,
    required this.time,
    required this.status,
    required this.statusColor,
    this.isUpcoming = false,
    this.cardColor,
  });

  final double scale;
  final String title;
  final String? subject;
  final int students;
  final String time;
  final String status;
  final Color statusColor;
  final bool isUpcoming;
  final Color? cardColor;

  @override
  State<_ClassCard> createState() => __ClassCardState();
}

class __ClassCardState extends State<_ClassCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Public method to be called from the parent
  Future<void> triggerTapAnimation() async {
    await _controller.forward();
    await Future.delayed(const Duration(milliseconds: 50));
    await _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    // If the statusColor is our bright green, change text color to dark for readability
    final textColor = widget.statusColor == _chipGreen
        ? _cardSurface
        : Colors.white;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        padding: EdgeInsets.all(16 * widget.scale),
        decoration: BoxDecoration(
          color: widget.cardColor ?? _cardSurface,
          borderRadius: BorderRadius.circular(16 * widget.scale),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
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
            if (widget.subject != null && widget.subject!.isNotEmpty) ...[
              SizedBox(height: 4 * widget.scale),
              Text(
                widget.subject!,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14 * widget.scale,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            SizedBox(height: 8 * widget.scale),
            Row(
              children: [
                Icon(
                  Icons.group,
                  color: Colors.white70,
                  size: 16 * widget.scale,
                ),
                SizedBox(width: 6 * widget.scale),
                Text(
                  '${widget.students} Students',
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
                  color: textColor, // Adjusted for contrast
                  fontSize: 14 * widget.scale,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
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
          color: const Color(0xFF6AAFBF).withValues(alpha: 0.45),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .25),
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
                Icon(
                  Icons.settings,
                  color: Colors.white,
                  size: 24 * widget.scale,
                ),
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
    // If background is our bright green, text/icons should be dark
    final textColor = widget.color == _chipGreen ? _cardSurface : Colors.white;

    return InkWell(
      borderRadius: BorderRadius.circular(22 * widget.scale),
      onTap: () {},
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 18 * widget.scale,
          vertical: 16 * widget.scale,
        ),
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(22 * widget.scale),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 10 * widget.scale,
              offset: Offset(0, 6 * widget.scale),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(widget.icon, color: textColor, size: 20 * widget.scale),
            SizedBox(width: 12 * widget.scale),
            Expanded(
              child: Text(
                widget.label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16 * widget.scale,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: textColor,
              size: 22 * widget.scale,
            ),
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
            color: Colors.black.withValues(alpha: 0.25),
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
          ...widget.classes.map(
            (item) => Padding(
              padding: EdgeInsets.only(bottom: 12 * widget.scale),
              child: _ScheduleItemWidget(scale: widget.scale, item: item),
            ),
          ),
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
  const _ScheduleItemWidget({required this.scale, required this.item});

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
