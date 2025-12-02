import 'dart:async';
import 'package:flutter/material.dart';
import 'package:t_racks_softdev_1/screens/educator/educator_classroom_screen.dart';
import 'package:t_racks_softdev_1/screens/educator/create_class_modal.dart';
import 'package:t_racks_softdev_1/services/database_service.dart';

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

    // Refresh every minute to keep "Ongoing" status accurate
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

  bool _isClassToday(String days) {
    final now = DateTime.now();
    final weekday = now.weekday;
    // M=1, T=2, W=3, Th=4, F=5, S=6, Su=7

    if (days.contains("Su") && weekday == 7) return true;
    if (days.contains("M") && weekday == 1) return true;
    if (days.contains("Th") && weekday == 4) return true;
    if (days.contains("T") && !days.contains("Th") && weekday == 2) return true;
    if (days.contains("W") && weekday == 3) return true;
    if (days.contains("F") && weekday == 5) return true;
    if (days.contains("S") && !days.contains("Su") && weekday == 6) return true;

    return false;
  }

  // --- ROBUST TIME PARSER ---
  TimeOfDay _parseTime(String timeString) {
    // Clean up input: " 10:30  AM " -> "10:30AM"
    String cleaned = timeString.toUpperCase().replaceAll(".", "").trim();

    // Handle NN (Noon) and MN (Midnight)
    if (cleaned.contains("NN")) cleaned = cleaned.replaceAll("NN", "PM");
    if (cleaned.contains("MN")) cleaned = cleaned.replaceAll("MN", "AM");

    // Add space between number and letter if missing: "10:30AM" -> "10:30 AM"
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
      String period = parts[1]; // AM or PM

      if (period == "PM" && hour != 12) hour += 12;
      if (period == "AM" && hour == 12) hour = 0;

      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      print("ERROR PARSING TIME: $timeString ($e)");
      return const TimeOfDay(hour: 0, minute: 0);
    }
  }

  double _timeToDouble(TimeOfDay time) => time.hour + time.minute / 60.0;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<EducatorClassSummary>>(
      future: _classesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        final classes = snapshot.data ?? [];

        // --- DEBUGGING PRINTS ---
        // Look at your "Run" or "Debug" tab in VS Code / Android Studio to see this!
        final nowTime = TimeOfDay.now();
        final nowDouble = _timeToDouble(nowTime);
        print("--------------------------------------------------");
        print(
          "DEBUG: Current Device Time: ${nowTime.format(context)} (Value: $nowDouble)",
        );

        var todaysClasses = classes
            .where((c) => _isClassToday(c.rawDay))
            .toList();

        // Sort classes
        todaysClasses.sort((a, b) {
          String startA = a.rawTime.split("-")[0];
          String startB = b.rawTime.split("-")[0];
          return _timeToDouble(
            _parseTime(startA),
          ).compareTo(_timeToDouble(_parseTime(startB)));
        });

        EducatorClassSummary? ongoingClass;
        List<EducatorClassSummary> upcomingClasses = [];

        for (var c in todaysClasses) {
          // Assume format "10:30 AM - 1:30 PM"
          final parts = c.rawTime.split("-");
          if (parts.length < 2) continue;

          final startDouble = _timeToDouble(_parseTime(parts[0]));
          final endDouble = _timeToDouble(_parseTime(parts[1]));

          print("DEBUG CHECK: ${c.className}");
          print("   Start: $startDouble, End: $endDouble");

          if (nowDouble >= startDouble && nowDouble < endDouble) {
            print("   -> STATUS: ONGOING");
            ongoingClass = c;
          } else if (startDouble > nowDouble) {
            print("   -> STATUS: UPCOMING");
            upcomingClasses.add(c);
          } else {
            print("   -> STATUS: ENDED");
          }
        }
        print("--------------------------------------------------");

        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              const SizedBox(height: 16),
              _buildDynamicTopSection(ongoingClass, upcomingClasses),
              const SizedBox(height: 24),
              _buildMyClassesSection(classes),
              const SizedBox(height: 100),
            ],
          ),
        );
      },
    );
  }

  // ... (Keep _buildDynamicTopSection, _buildSummaryCard, etc. exactly the same as before)
  // Just make sure to COPY the buildDynamicTopSection from the previous response
  // if you haven't pasted it into this file yet.

  Widget _buildDynamicTopSection(
    EducatorClassSummary? ongoing,
    List<EducatorClassSummary> upcoming,
  ) {
    List<Widget> stackedCards = [];

    // CARD 1
    if (ongoing != null) {
      stackedCards.add(
        _buildSummaryCard(
          icon: Icons.access_time_filled,
          iconColor: const Color(0xFF7FE26B),
          value: ongoing.className,
          label: "Ongoing Class",
          subLabel: ongoing.rawTime,
          isOngoing: true,
        ),
      );
    } else if (upcoming.isNotEmpty) {
      stackedCards.add(
        _buildSummaryCard(
          icon: Icons.calendar_today,
          iconColor: const Color(0xFF68D080),
          value: upcoming[0].className,
          label: "Up Next",
          subLabel: upcoming[0].rawTime,
        ),
      );
    } else {
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

    // CARD 2
    if (ongoing != null) {
      if (upcoming.isNotEmpty) {
        stackedCards.add(const SizedBox(height: 12));
        stackedCards.add(
          _buildSummaryCard(
            icon: Icons.next_plan_outlined,
            iconColor: Colors.white70,
            value: upcoming[0].className,
            label: "Up Next",
            subLabel: upcoming[0].rawTime,
          ),
        );
      }
    } else {
      if (upcoming.length > 1) {
        stackedCards.add(const SizedBox(height: 12));
        stackedCards.add(
          _buildSummaryCard(
            icon: Icons.next_plan_outlined,
            iconColor: Colors.white70,
            value: upcoming[1].className,
            label: "Later",
            subLabel: upcoming[1].rawTime,
          ),
        );
      }
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
      height: 120,
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
