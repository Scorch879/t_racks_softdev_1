import 'package:flutter/material.dart';
import 'package:t_racks_softdev_1/services/database_service.dart';

class EducatorHomeScreen extends StatefulWidget {
  const EducatorHomeScreen({super.key});

  @override
  State<EducatorHomeScreen> createState() => _EducatorHomeScreenState();
}

class _EducatorHomeScreenState extends State<EducatorHomeScreen> {
  final DatabaseService _dbService = DatabaseService();

  // State
  EducatorClassSummary? selectedClass; // If null, "All Classes" is selected
  List<StudentAttendanceItem> studentList = [];
  bool isLoadingStudents = false;

  @override
  void initState() {
    super.initState();
    // Default to "All Classes" (null) on start
    selectedClass = null;
  }

  // Handle "All Classes" tap
  void _onAllClassesSelected() {
    setState(() {
      selectedClass = null;
      studentList = []; // Clear the list
    });
  }

  // Handle Specific Class tap
  void _onClassSelected(EducatorClassSummary classData) async {
    // If already selected, do nothing
    if (selectedClass?.id == classData.id) return;

    setState(() {
      selectedClass = classData;
      isLoadingStudents = true;
    });

    try {
      final students = await _dbService.getClassStudents(classData.id);
      if (mounted) {
        setState(() {
          studentList = students;
          isLoadingStudents = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoadingStudents = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          const SizedBox(height: 16),

          // 1. SELECT CLASS SECTION
          _buildSelectClassSection(),

          const SizedBox(height: 16),

          // 2. SUMMARY CARDS
          _buildSummaryCards(),

          // 3. ATTENDANCE LIST (Only show if a specific class is selected)
          if (selectedClass != null) ...[
            const SizedBox(height: 16),
            _buildTodaysAttendanceSection(),
          ],

          const SizedBox(height: 100), // Bottom padding
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // WIDGETS
  // ---------------------------------------------------------------------------

  Widget _buildSelectClassSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0C3343),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFB4B4B4).withValues(alpha: 1),
          width: 0.7,
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
                'Select Class',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 12),

          // --- FETCH CLASSES ---
          FutureBuilder<List<EducatorClassSummary>>(
            future: _dbService.getEducatorClasses(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              }

              // Prepare the list of buttons
              List<Widget> classButtons = [];

              // 1. Always add "All Classes" button first
              // We calculate total students for "All Classes" if data exists
              int totalStudents = 0;
              if (snapshot.hasData) {
                for (var c in snapshot.data!) totalStudents += c.studentCount;
              }

              classButtons.add(
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: _buildClassButton(
                    title: "All Classes",
                    count: totalStudents,
                    isSelected: selectedClass == null, // Selected if null
                    onTap: _onAllClassesSelected,
                  ),
                ),
              );

              // 2. Add real classes from DB
              if (snapshot.hasData) {
                final classes = snapshot.data!;
                for (var classData in classes) {
                  classButtons.add(
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: _buildClassButton(
                        title: classData.className,
                        count: classData.studentCount,
                        isSelected: selectedClass?.id == classData.id,
                        onTap: () => _onClassSelected(classData),
                      ),
                    ),
                  );
                }
              }

              return Column(children: classButtons);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildClassButton({
    required String title,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF3AB389)
              : const Color(0xFF277D5F).withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 4,
              offset: isSelected ? const Offset(0, 0) : const Offset(0, 4),
            ),
          ],
        ),
        transform: isSelected
            ? Matrix4.diagonal3Values(1.02, 1.02, 1.0)
            : Matrix4.identity(),
        transformAlignment: Alignment.center,
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
              ),
            ),
            Text(
              '$count students',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaysAttendanceSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0C3343),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFB4B4B4).withValues(alpha: 1),
          width: 0.7,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 5),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person, color: Colors.white, size: 40),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Today's Attendance",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    selectedClass?.className ?? "",
                    style: const TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          isLoadingStudents
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : _buildStudentList(),
        ],
      ),
    );
  }

  Widget _buildStudentList() {
    if (studentList.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20.0),
        child: Text(
          "No students enrolled.",
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return Column(
      children: studentList.map((student) {
        return _buildStudentCard(student);
      }).toList(),
    );
  }

  // --- READ-ONLY STUDENT CARD ---
  Widget _buildStudentCard(StudentAttendanceItem student) {
    Color statusColor;
    String statusText = student.status;

    // Logic to handle colors based on DB status
    // Note: Your DB currently returns 'Present' or 'Absent' or 'Mark Attendance'
    switch (student.status) {
      case 'Present':
        statusColor = const Color(0xFF7FE26B);
        break;
      case 'Absent':
        statusColor = const Color(0xFFFA8989);
        break;
      case 'Late': // Only if you add this logic later
        statusColor = const Color(0xFFFF9155);
        break;
      default:
        statusColor = Colors.grey;
        statusText = "No Record";
    }

    return Container(
      // No GestureDetector here!
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF32657D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFC8C8C8).withValues(alpha: 1),
          width: 0.7,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 3),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          const CircleAvatar(
            radius: 20,
            backgroundColor: Colors.white,
            // Replace with Image.asset if you have one
            child: Icon(Icons.person, color: Colors.grey),
          ),
          const SizedBox(width: 12),

          // Name and Time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "8:00 AM", // Hardcoded time for now
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFFBABABA),
                  ),
                ),
              ],
            ),
          ),

          // Status Pill (Visual Only)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFFB4B4B4).withValues(alpha: 1),
                width: 0.7,
              ),
            ),
            child: Text(
              statusText,
              style: const TextStyle(
                color: Color(0xFF253F4C),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    // If All Classes (null) selected, show empty or aggregate stats?
    // User requested "only show list when class selected", but cards usually show something.
    // Let's show "0" if All Classes is selected to match your previous screenshot logic.

    if (selectedClass == null) {
      return _buildSummaryGrid(
        present: '0',
        absent: '0',
        rate: '0%',
        late: '0',
      );
    }

    // If Class Selected, calculate from studentList
    int presentCount = studentList.where((s) => s.status == 'Present').length;
    int absentCount = studentList.where((s) => s.status == 'Absent').length;
    int total = studentList.length;

    String rate = total == 0
        ? "0%"
        : "${((presentCount / total) * 100).toInt()}%";

    return _buildSummaryGrid(
      present: '$presentCount',
      absent: '$absentCount',
      rate: rate,
      late: '0', // Late logic needs DB support
    );
  }

  Widget _buildSummaryGrid({
    required String present,
    required String absent,
    required String rate,
    required String late,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  icon: Icons.verified_user,
                  iconColor: const Color(0xFF68D080),
                  value: present,
                  label: 'Present Today',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  icon: Icons.person_off,
                  iconColor: const Color(0xFFE54E4E),
                  value: absent,
                  label: 'Absent Today',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  icon: Icons.check_circle,
                  iconColor: const Color(0xFF4994B5),
                  value: rate,
                  label: 'Attendance Rate',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  icon: Icons.access_time,
                  iconColor: const Color(0xFFCED04F),
                  value: late,
                  label: 'Late Arrival',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0C3343),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: const Color(0xFFB4B4B4).withValues(alpha: 1),
            width: 0.7,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 32),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
