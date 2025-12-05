import 'dart:async';
import 'package:flutter/material.dart';
import 'package:t_racks_softdev_1/screens/educator/educator_classroom_screen.dart';
import 'package:t_racks_softdev_1/screens/educator/create_class_modal.dart';
import 'package:t_racks_softdev_1/services/database_service.dart';
import 'package:t_racks_softdev_1/services/models/class_model.dart';
import 'package:t_racks_softdev_1/screens/educator/attendance_instruction_screen.dart';

class EducatorClassesScreen extends StatefulWidget {
  const EducatorClassesScreen({super.key});

  @override
  State<EducatorClassesScreen> createState() => _EducatorClassesContentState();
}

class _EducatorClassesContentState extends State<EducatorClassesScreen> {
  final DatabaseService _dbService = DatabaseService();
  late Future<List<EducatorClassSummary>> _classesFuture;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _classesFuture = _dbService.getEducatorClasses();

    // Refresh every minute to keep statuses accurate
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _refreshClasses() {
    setState(() {
      _classesFuture = _dbService.getEducatorClasses();
    });
  }

  void _navigateToAttendance() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AttendanceInstructionScreen(),
      ),
    );
  }

  bool _isClassToday(String days) {
    final now = DateTime.now();
    final weekday = now.weekday;

    if (days.contains("Su") && weekday == 7) return true;
    if (days.contains("M") && weekday == 1) return true;
    if (days.contains("Th") && weekday == 4) return true;
    if (days.contains("T") && !days.contains("Th") && weekday == 2) return true;
    if (days.contains("W") && weekday == 3) return true;
    if (days.contains("F") && weekday == 5) return true;
    if (days.contains("S") && !days.contains("Su") && weekday == 6) return true;

    return false;
  }

  TimeOfDay _parseTime(String timeString) {
    String cleaned = timeString.toUpperCase().replaceAll(".", "").trim();
    if (cleaned.contains("NN")) cleaned = cleaned.replaceAll("NN", "PM");
    if (cleaned.contains("MN")) cleaned = cleaned.replaceAll("MN", "AM");
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'(\d)([A-Z])'),
      (match) => '${match.group(1)} ${match.group(2)}',
    );

    try {
      final parts = cleaned.split(" ");
      if (parts.length < 2) return const TimeOfDay(hour: 0, minute: 0);

      final timeParts = parts[0].split(":");
      int hour = int.parse(timeParts[0]);
      int minute = int.parse(timeParts[1]);
      String period = parts[1];

      if (period == "PM" && hour != 12) hour += 12;
      if (period == "AM" && hour == 12) hour = 0;

      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      return const TimeOfDay(hour: 0, minute: 0);
    }
  }

  double _timeToDouble(TimeOfDay time) => time.hour + time.minute / 60.0;

  @override
  Widget build(BuildContext context) {
    // 1. Wrap everything in LayoutBuilder to get the screen height
    return LayoutBuilder(
      builder: (context, constraints) {
        return FutureBuilder<List<EducatorClassSummary>>(
          future: _classesFuture,
          builder: (context, snapshot) {
            
            // 2. FIX: Force the loading state to fill the screen height
            if (snapshot.connectionState == ConnectionState.waiting) {
              return SizedBox(
                height: constraints.maxHeight,
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              );
            }

            final classes = snapshot.data ?? [];

            final nowTime = TimeOfDay.now();
            final nowDouble = _timeToDouble(nowTime);

            var todaysClasses = classes
                .where((c) => _isClassToday(c.rawDay))
                .toList();
            todaysClasses.sort((a, b) {
              String startA = a.rawTime.split("-")[0];
              String startB = b.rawTime.split("-")[0];
              return _timeToDouble(
                _parseTime(startA),
              ).compareTo(_timeToDouble(_parseTime(startB)));
            });

            List<EducatorClassSummary> ongoingClasses = [];
            List<EducatorClassSummary> upcomingClasses = [];

            for (var c in todaysClasses) {
              final parts = c.rawTime.split("-");
              if (parts.length < 2) continue;

              final startDouble = _timeToDouble(_parseTime(parts[0]));
              final endDouble = _timeToDouble(_parseTime(parts[1]));

              if (nowDouble >= startDouble && nowDouble < endDouble) {
                ongoingClasses.add(c);
              } else if (startDouble > nowDouble) {
                upcomingClasses.add(c);
              }
            }

            // 3. FIX: Ensure the scroll view takes at least the full height
            // This prevents clipping when you have few (or zero) classes.
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    _buildDynamicTopSection(ongoingClasses, upcomingClasses),
                    const SizedBox(height: 24),
                    _buildMyClassesSection(classes),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDynamicTopSection(
    List<EducatorClassSummary> ongoingList,
    List<EducatorClassSummary> upcomingList,
  ) {
    List<Widget> stackedCards = [];
    List<Map<String, dynamic>> combinedQueue = [];

    for (var c in ongoingList) {
      combinedQueue.add({'data': c, 'type': 'ongoing'});
    }
    for (var c in upcomingList) {
      combinedQueue.add({'data': c, 'type': 'upcoming'});
    }

    if (combinedQueue.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: _buildSummaryCard(
          icon: Icons.bed,
          iconColor: Colors.orange,
          value: "No Classes",
          label: "You are free for the rest of the day!",
        ),
      );
    }

    int itemsToShow = combinedQueue.length > 2 ? 2 : combinedQueue.length;

    for (int i = 0; i < itemsToShow; i++) {
      final item = combinedQueue[i];
      final EducatorClassSummary data = item['data'];
      final String type = item['type'];
      final bool isOngoing = type == 'ongoing';

      if (i > 0) stackedCards.add(const SizedBox(height: 12));

      stackedCards.add(
        _buildSummaryCard(
          icon: isOngoing
              ? Icons.access_time_filled
              : (i == 0 ? Icons.calendar_today : Icons.next_plan_outlined),
          iconColor: isOngoing
              ? const Color(0xFF7FE26B)
              : (i == 0 ? const Color(0xFF68D080) : Colors.white70),
          value: data.className,
          label: isOngoing
              ? "Ongoing Class"
              : (i == 0 && ongoingList.isEmpty ? "Up Next" : "Later"),
          subLabel: data.rawTime,
          isOngoing: isOngoing,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(children: stackedCards),
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    String? subLabel,
    bool isOngoing = false,
  }) {
    final borderColor = isOngoing
        ? const Color(0xFF7FE26B)
        : const Color(0xFFBDBBBB).withValues(alpha: 1);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0C3343),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: isOngoing ? 1.5 : 0.75),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: iconColor, size: 28),
              if (isOngoing)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7FE26B).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    "NOW",
                    style: TextStyle(
                      color: Color(0xFF7FE26B),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: const TextStyle(fontSize: 13, color: Colors.white70),
                  ),
                ],
              ),
              if (subLabel != null)
                Text(
                  subLabel,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isOngoing ? const Color(0xFF7FE26B) : Colors.white,
                  ),
                ),
            ],
          ),

          if (isOngoing) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed:_navigateToAttendance,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7FE26B),
                  foregroundColor: const Color(0xFF0C3343),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.camera_alt_rounded, size: 20),
                label: const Text(
                  "Take Attendance",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMyClassesSection(List<EducatorClassSummary> classes) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0C3343),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFBDBBBB).withValues(alpha: 1),
          width: 0.75,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 5),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'My Classes',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(
                height: 32,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await showDialog(
                      context: context,
                      builder: (context) => const CreateClassModal(),
                    );
                    _refreshClasses();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7FE26B),
                    foregroundColor: const Color(0xFF0C3343),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text(
                    "Create Class",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          if (classes.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  "No classes found.",
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            )
          else
            Column(
              children: classes
                  .map((classData) => _buildClassCard(classData))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildClassCard(EducatorClassSummary classData) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EducatorClassroomScreen(
              classId: classData.id,
              className: classData.className,
              schedule: classData.schedule,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.only(
          left: 30,
          top: 20,
          right: 20,
          bottom: 20,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF376375),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFFBDBBBB).withValues(alpha: 1),
            width: 0.75,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 80.0),
                  child: Text(
                    classData.className,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatColumn('Students', '${classData.studentCount}'),
                    const SizedBox(width: 40),
                    Expanded(
                      child: _buildStatColumn('Subject', classData.subject),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Schedule: ${classData.schedule}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFFD5D5D5),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: classData.status.toLowerCase() == 'active'
                      ? const Color(0xFF7FE26B)
                      : Colors.grey,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  classData.status,
                  style: const TextStyle(
                    color: Color(0xFF0C3343),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Colors.white60),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ],
    );
  }
}