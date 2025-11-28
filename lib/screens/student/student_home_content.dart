import 'package:flutter/material.dart';
import 'package:t_racks_softdev_1/screens/student/student_class_content.dart';
import 'package:t_racks_softdev_1/screens/student/student_camera_screen.dart';
import 'package:t_racks_softdev_1/services/database_service.dart';
import 'package:t_racks_softdev_1/services/models/class_model.dart';
import 'package:t_racks_softdev_1/services/models/attendance_record_model.dart';
import 'package:t_racks_softdev_1/services/models/student_model.dart';
import 'package:t_racks_softdev_1/services/database_service.dart';

//const _bgTeal = Color(0xFF167C94);
const _cardSurface = Color(0xFF173C45);
const _cardHeader = Color(0xFF1B4A55);
const _accentCyan = Color(0xFF93C0D3);
const _chipGreen = Color(0xFF4DBD88);
const _statusRed = Color(0xFFDA6A6A);
const _titleRed = Color(0xFFE57373);
const _titleGreen = Color(0xFF4DBD88);

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
  final _databaseService = DatabaseService();
  late Future<Map<String, dynamic>> _dataFuture;

  //void onOngoingClassStatusPressed() {} commented this out cuz awas giving errors

  void onFilterAllClasses() {}

  void _navigateToClassDetails(String classId) {
    showDialog(
      context: context,
      builder: (context) => _ClassDetailsDialog(classId: classId),
    );
  }

  @override
  void initState() {
    super.initState();
    _dataFuture = _fetchData();
  }

  Future<Map<String, dynamic>> _fetchData() async {
    try {
      // Fetch student profile and classes concurrently
      final results = await Future.wait([
        _databaseService.getStudentData(),
        _databaseService.getStudentClasses(),
        _databaseService.getTodaysAttendanceStatus(),
      ]);
      return {
        'student': results[0] as Student?,
        'classes': results[1] as List<StudentClass>,
        'attendanceStatus': results[2] as String,
      };
    } catch (e) {
      // Propagate error to FutureBuilder
      throw Exception('Failed to load home screen data: $e');
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

        return FutureBuilder<Map<String, dynamic>>(
          future: _dataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.white));
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
            }

            final student = snapshot.data?['student'] as Student?;
            final classes = snapshot.data?['classes'] as List<StudentClass>? ?? [];
            final attendanceStatus = snapshot.data?['attendanceStatus'] as String? ?? 'Unknown';

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
                            attendanceStatus: attendanceStatus,
                            student: student,
                            scale: scale,
                            radius: cardRadius,
                            onOngoingClassStatusPressed: onOngoingClassStatusPressed,
                          ),
                          SizedBox(height: 16 * scale),
                          _MyClassesCard(
                            classes: classes,
                            scale: scale,
                            radius: cardRadius,
                            onFilterAllClasses: onFilterAllClasses,
                            onClassPressed: _navigateToClassDetails,
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
}

class _ClassDetailsDialog extends StatefulWidget {
  final String classId;
  const _ClassDetailsDialog({required this.classId});

  @override
  State<_ClassDetailsDialog> createState() => _ClassDetailsDialogState();
}

class _ClassDetailsDialogState extends State<_ClassDetailsDialog> {
  final _databaseService = DatabaseService();
  late final Future<Map<String, dynamic>> _detailsFuture;

  @override
  void initState() {
    super.initState();
    _detailsFuture = _fetchDetails();
  }

  Future<Map<String, dynamic>> _fetchDetails() async {
    final results = await Future.wait([
      _databaseService.getClassDetails(widget.classId),
      _databaseService.getAttendanceHistory(widget.classId),
    ]);
    return {'class': results[0], 'history': results[1]};
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _cardHeader, // Using a color available in this file
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: FutureBuilder<Map<String, dynamic>>(
        future: _detailsFuture,
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

          final sClass = snapshot.data?['class'] as StudentClass?;
          final history = snapshot.data?['history'] as List<AttendanceRecord>? ?? [];
          if (sClass == null) return const Center(child: Text('Class not found.'));

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
                _DetailItem(label: 'Current Status', value: sClass.status),
                const SizedBox(height: 24),
                const Text(
                  'Attendance History',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (history.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Text('No attendance records found.', style: TextStyle(color: Colors.white70)),
                  )
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 150),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: history.length,
                      itemBuilder: (context, index) {
                        final record = history[index];
                        final dateString = '${record.date.month}/${record.date.day}/${record.date.year}';
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(dateString, style: const TextStyle(color: Colors.white)),
                          trailing: Text(
                            record.isPresent ? 'Present' : 'Absent',
                            style: TextStyle(color: record.isPresent ? _titleGreen : _titleRed, fontWeight: FontWeight.bold),
                          ),
                        );
                      },
                    ),
                  ),
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

class _WelcomeAndOngoingCard extends StatefulWidget {
  const _WelcomeAndOngoingCard({
    required this.attendanceStatus,
    this.student,
    required this.scale,
    required this.radius,
    required this.onOngoingClassStatusPressed,
  });
  final double scale;
  final String attendanceStatus;
  final double radius;
  final Student? student;
  final VoidCallback onOngoingClassStatusPressed;

  @override
  State<_WelcomeAndOngoingCard> createState() => _WelcomeAndOngoingCardState();
}

class _WelcomeAndOngoingCardState extends State<_WelcomeAndOngoingCard> {
  @override
  Widget build(BuildContext context) {
    final scale = widget.scale;
    final isPresent = widget.attendanceStatus == 'Present';
    final statusColor = isPresent ? _titleGreen : _titleRed;

    // Handle 'Not Recorded' or 'Error' cases
    String displayStatus = widget.attendanceStatus;
    Color displayColor = statusColor;
    IconData displayIcon = isPresent ? Icons.person_pin_circle_outlined : Icons.person_off_outlined;

    if (widget.attendanceStatus != 'Present' && widget.attendanceStatus != 'Absent') {
      displayStatus = 'Not Recorded';
      displayColor = Colors.grey;
      displayIcon = Icons.help_outline;
    }

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
                  'Welcome! ${widget.student?.profile?.firstName ?? 'user'}',
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
                    Icon(displayIcon,
                        color: displayColor, size: 28 * scale),
                    SizedBox(width: 8 * scale),
                    Text(
                      displayStatus,
                      style: TextStyle(
                        color: displayColor,
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
                GestureDetector(
                  onTap: widget.onOngoingClassStatusPressed,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      vertical: 8 * scale,
                      horizontal: 14 * scale,
                    ),
                    decoration: BoxDecoration(
                      color: displayColor,
                      borderRadius: BorderRadius.circular(20 * scale),
                    ),
                    child: Text(
                      displayStatus,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12 * scale,
                        fontWeight: FontWeight.w800,
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

class _MyClassesCard extends StatefulWidget {
  const _MyClassesCard({
    required this.classes,
    required this.scale,
    required this.radius,
    required this.onFilterAllClasses,
    required this.onClassPressed,
  });
  final double scale;
  final List<StudentClass> classes;
  final double radius;
  final VoidCallback onFilterAllClasses;
  final void Function(String classId) onClassPressed;

  @override
  State<_MyClassesCard> createState() => _MyClassesCardState();
}

class _MyClassesCardState extends State<_MyClassesCard> {
  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'ongoing':
        return _chipGreen;
      case 'absent':
        return _statusRed;
      case 'upcoming':
        return _accentCyan.withOpacity(0.7);
      default:
        return Colors.grey;
    }
  }

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
              trailingText: 'Total: ${widget.classes.length}',
              backgroundColor: _chipGreen,
            ),
            if (widget.classes.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 40 * scale),
                child: Text(
                  'No classes yet',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16 * scale,
                  ),
                ),
              )
            else
              ...widget.classes.map((sClass) {
                return Padding(
                  padding: EdgeInsets.only(top: 16 * scale),
                  child: _ClassRow(
                    scale: scale,
                    title: sClass.name ?? 'Unnamed Class',
                    // Status logic can be implemented later
                    statusText: sClass.status ?? 'Unknown',
                    statusColor: _getStatusColor(sClass.status),
                    onTap: () => widget.onClassPressed(sClass.id),
                  ),
                );
              }).toList(),
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
