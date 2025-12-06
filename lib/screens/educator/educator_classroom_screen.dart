import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:t_racks_softdev_1/services/database_service.dart';
import 'package:t_racks_softdev_1/screens/educator/educator_add_student_screen.dart';
import 'package:t_racks_softdev_1/services/models/class_model.dart';

class EducatorClassroomScreen extends StatefulWidget {
  final String classId;
  final String className;
  final String schedule;

  const EducatorClassroomScreen({
    super.key,
    required this.classId,
    required this.className,
    required this.schedule,
  });

  @override
  State<EducatorClassroomScreen> createState() =>
      _EducatorClassroomScreenState();
}

class _EducatorClassroomScreenState extends State<EducatorClassroomScreen> {
  final DatabaseService _dbService = DatabaseService();
  final TextEditingController _searchController = TextEditingController();

  List<StudentAttendanceItem> studentList = [];
  bool isLoading = true;
  String? _classCode;

  @override
  void initState() {
    super.initState();
    _fetchClassData();
  }

  void _fetchClassData() async {
    // 1. Fetch Students
    final students = await _dbService.getClassStudents(widget.classId);

    // 2. Fetch Class Details
    String? code;
    try {
      final classDetails = await _dbService.getClassDetails(widget.classId);
      code = classDetails.classCode;
    } catch (e) {
      print("Error fetching class code: $e");
      code = "Error";
    }

    if (mounted) {
      setState(() {
        studentList = students;
        _classCode = code;
        isLoading = false;
      });
    }
  }

  void _copyClassCode() {
    if (_classCode != null) {
      Clipboard.setData(ClipboardData(text: _classCode!));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Class Code '$_classCode' copied to clipboard!"),
          backgroundColor: const Color(0xFF2A7FA3),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // --- NEW: Attendance Dialog Logic ---
  void _showAttendanceDialog(StudentAttendanceItem student) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Mark Attendance",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F3951),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                student.name,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 24),

              // Option: Present
              _buildAttendanceOption(
                label: "Present",
                color: const Color(0xFF4CAF50),
                icon: Icons.check_circle_outline,
                onTap: () => _submitAttendance(student, "Present"),
              ),
              const SizedBox(height: 12),

              // Option: Late
              _buildAttendanceOption(
                label: "Late",
                color: const Color(0xFFFF9800),
                icon: Icons.access_time,
                onTap: () => _submitAttendance(student, "Late"),
              ),
              const SizedBox(height: 12),

              // Option: Absent
              _buildAttendanceOption(
                label: "Absent",
                color: const Color(0xFFE53935),
                icon: Icons.cancel_outlined,
                onTap: () => _submitAttendance(student, "Absent"),
              ),

              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitAttendance(
    StudentAttendanceItem student,
    String status,
  ) async {
    Navigator.pop(context); // Close dialog

    // Show loading indicator briefly or optimistic update
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Marking ${student.name} as $status..."),
        duration: const Duration(milliseconds: 500),
      ),
    );

    try {
      await _dbService.markManualAttendance(
        classId: widget.classId,
        studentId: student.id,
        status: status,
      );
      // Refresh list to show new status
      _fetchClassData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to update attendance"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildAttendanceOption({
    required String label,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          border: Border.all(color: color, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color.fromARGB(221, 255, 255, 255),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Classroom",
          style: TextStyle(color: Color.fromARGB(221, 255, 255, 255)),
        ),

        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white70),
            tooltip: 'Delete Class',
            onPressed: _confirmDeleteClass,
          ),
          const SizedBox(width: 8), // Little padding from right edge
        ],
      ),
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF194B61),
                    Color(0xFF2A7FA3),
                    Color(0xFF267394),
                    Color(0xFF349BC7),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Opacity(
                opacity: 0.3,
                child: Image.asset(
                  'assets/images/squigglytexture.png',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                children: [
                  Flexible(fit: FlexFit.loose, child: _buildClassroomCard()),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassroomCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0C3343).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.star, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.className,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.schedule,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (_classCode != null)
                InkWell(
                  onTap: _copyClassCode,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7FE26B).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF7FE26B).withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _classCode!,
                          style: const TextStyle(
                            color: Color(0xFF7FE26B),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.copy_rounded,
                          color: Color(0xFF7FE26B),
                          size: 14,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 20),

          // Search Bar
          TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search Student',
              hintStyle: const TextStyle(color: Colors.white70),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.1),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(Icons.search, color: Colors.white70),
            ),
          ),
          const SizedBox(height: 16),

          // List Area
          Flexible(
            fit: FlexFit.loose,
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : studentList.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Center(
                      child: Text(
                        "No students enrolled",
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: studentList.length,
                    itemBuilder: (context, index) {
                      return _buildStudentTile(studentList[index]);
                    },
                  ),
          ),

          const SizedBox(height: 16),

          // Add Student Button
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () async {
                final available = await _dbService.getAvailableStudents(
                  widget.classId,
                );

                if (context.mounted) {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EducatorAddStudentScreen(
                        classId: widget.classId,
                        className: widget.className,
                        availableStudents: available,
                      ),
                    ),
                  );
                  _fetchClassData();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2A7FA3),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.add, color: Colors.white, size: 20),
              label: const Text(
                'Add Student',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentTile(StudentAttendanceItem student) {
    // Determine color based on status for better visual feedback
    Color statusColor = Colors.grey;
    String displayStatus =
        student.status; // 'Present', 'Absent', or 'Mark Attendance'

    if (student.status == 'Present')
      statusColor = const Color(0xFF4CAF50);
    else if (student.status == 'Absent')
      statusColor = const Color(0xFFE53935);
    else if (student.status == 'Late')
      statusColor = const Color(0xFFFF9800); // Assuming Late is tracked

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF133A53),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            child: const Icon(Icons.person_outline, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              student.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // --- UPDATED BUTTON ---
          InkWell(
            onTap: () => _showAttendanceDialog(student),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor, // Dynamic color
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                displayStatus == "Mark Attendance"
                    ? "Mark Attendance"
                    : displayStatus,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteClass() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Class?"),
        content: Text(
          "Are you sure you want to delete '${widget.className}'? This action cannot be undone and will remove all student data associated with this class.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Cancel
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _deleteClass(); // Proceed to delete
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteClass() async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await _dbService.deleteClass(widget.classId);

      if (mounted) {
        Navigator.pop(context); // Pop loading dialog
        Navigator.pop(context, true); // Pop the Classroom Screen to go back to list

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Class deleted successfully"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Pop loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to delete class: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
