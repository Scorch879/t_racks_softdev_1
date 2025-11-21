import 'package:flutter/material.dart';
import 'package:t_racks_softdev_1/screens/educator/educator_background.dart';
import 'package:t_racks_softdev_1/screens/educator/educator_view_model.dart';

// Content-only widget for use in EducatorShell
class EducatorHomeContent extends StatefulWidget {
  const EducatorHomeContent({super.key});

  @override
  State<EducatorHomeContent> createState() => _EducatorHomeContentState();
}

class _EducatorHomeContentState extends State<EducatorHomeContent> {
  String selectedClass = 'All Classes';
  List<Map<String, dynamic>> _classes = [];
  Map<String, String> _attendanceSummary = {
    'present': '-',
    'absent': '-',
    'rate': '-',
    'late': '-',
  };
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final classes = await EducatorViewModel.getClasses();
    final summary = await EducatorViewModel.getAttendanceSummary();
    if (mounted) {
      setState(() {
        _classes = classes;
        _attendanceSummary = summary;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return EducatorBackground(
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 16),
              _buildSelectClassSection(),
              const SizedBox(height: 16),
              _buildSummaryCards(),
              if (selectedClass != 'All Classes') ...[
                const SizedBox(height: 16),
                _buildTodaysAttendanceSection(),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectClassSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF194B61),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Select Class',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildClassButton('All Classes', _classes.fold(0, (sum, item) => sum + (item['students'] as int)), selectedClass == 'All Classes'),
              ..._classes.map((c) => _buildClassButton(c['name'], c['students'], selectedClass == c['name'])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClassButton(String className, int studentCount, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedClass = className;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF66BB6A) : const Color(0xFF388E3C),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              className,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$studentCount students',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  icon: Icons.verified_user,
                  iconColor: const Color(0xFF4CAF50),
                  value: _attendanceSummary['present']!,
                  label: 'Present Today',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  icon: Icons.person_off,
                  iconColor: Colors.red,
                  value: _attendanceSummary['absent']!,
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
                  iconColor: const Color(0xFF4CAF50),
                  value: _attendanceSummary['rate']!,
                  label: 'Attendance Rate',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  icon: Icons.access_time,
                  iconColor: Colors.amber,
                  value: _attendanceSummary['late']!,
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
          color: const Color(0xFF194B61),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaysAttendanceSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.person,
                color: Color(0xFF424242),
                size: 24,
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Today's Attendance",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF424242),
                    ),
                  ),
                  Text(
                    selectedClass,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF424242),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildStudentList(),
        ],
      ),
    );
  }

  Widget _buildStudentList() {
    // Find the selected class
    final classData = _classes.firstWhere(
      (c) => c['name'] == selectedClass,
      orElse: () => {},
    );

    if (classData.isEmpty || classData['studentsList'] == null) {
      return const Text('No students found.');
    }

    final students = (classData['studentsList'] as List).cast<Map<String, String>>();

    return Column(
      children: students.map((student) {
        return _buildStudentCard(
          name: student['name']!,
          time: student['time']!,
          status: student['status']!,
        );
      }).toList(),
    );
  }

  Widget _buildStudentCard({
    required String name,
    required String time,
    required String status,
  }) {
    Color statusColor;
    switch (status) {
      case 'Present':
        statusColor = const Color(0xFF4CAF50);
        break;
      case 'Absent':
        statusColor = Colors.red;
        break;
      case 'Late':
        statusColor = Colors.orange;
        break;
      default:
        statusColor = Colors.grey;
    }

    return GestureDetector(
      onTap: () {},
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFD0D0D0),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white,
              child: Image.asset(
                'assets/images/placeholder.png',
                width: 30,
                height: 30,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF424242),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    time,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF757575),
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}
