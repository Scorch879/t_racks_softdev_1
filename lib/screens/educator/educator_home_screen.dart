import 'package:flutter/material.dart';

class EducatorHomeContent extends StatefulWidget {
  const EducatorHomeContent({super.key});

  @override
  State<EducatorHomeContent> createState() => _EducatorHomeContentState();
}

class _EducatorHomeContentState extends State<EducatorHomeContent> {
  String selectedClass = 'All Classes';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
    );
  }

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
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 5,
            offset: const Offset(0, 0),
          ),
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
                  fontFamily: 'Rubik',
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildClassButton('All Classes', 72, selectedClass == 'All Classes'),
              const SizedBox(height: 8),
              _buildClassButton('Calculus 137', 28, selectedClass == 'Calculus 137'),
              const SizedBox(height: 8),
              _buildClassButton('Physics 138', 38, selectedClass == 'Physics 138'),
              const SizedBox(height: 8),
              _buildClassButton('Calculus 237', 18, selectedClass == 'Calculus 237'),
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3AB389) : const Color(0xFF277D5F).withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 4,
              offset: isSelected ? const Offset(0, 0) : const Offset(0, 4),
            ),
          ],
        ),
        transform: isSelected ? (Matrix4.identity()..scale(1.03)) : Matrix4.identity(),
        transformAlignment: FractionalOffset.center,
        child: Row(
          children: [
            Text(
              className,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 15,
              ),
            ),
            const Spacer(),
            Text(
              '$studentCount students',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 15,
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
                  iconColor: const Color(0xFF68D080),
                  value: '68',
                  label: 'Present Today',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  icon: Icons.person_off,
                  iconColor: const Color(0xFFE54E4E),
                  value: '4',
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
                  value: '94%',
                  label: 'Attendance Rate',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  icon: Icons.access_time,
                  iconColor: const Color(0xFFCED04F),
                  value: '3',
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
            Padding(
              padding: const EdgeInsets.only(left: 0.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: iconColor, size: 32),
                  const SizedBox(height: 15),
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
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
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
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 5,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person, color: Colors.white, size: 46.6),
              const SizedBox(width: 8),
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
                    selectedClass,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color.fromARGB(255, 255, 255, 255),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildStudentList(),
        ],
      ),
    );
  }

  Widget _buildStudentList() {
    final students = [
      {'name': 'Carla Jay D. Rimera', 'time': '8:00 AM', 'status': 'Late'},
      {'name': 'Mama Merto Rodigo', 'time': '8:00 AM', 'status': 'Absent'},
      {'name': 'One Pablo Reinstal..', 'time': '8:00 AM', 'status': 'Present'},
      {'name': 'Joaquin De Coco', 'time': '8:00 AM', 'status': 'Present'},
      {'name': 'Zonrox D. Color', 'time': '8:00 AM', 'status': 'Present'},
    ];

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
        statusColor = const Color(0xFF7FE26B);
        break;
      case 'Absent':
        statusColor = const Color(0xFFFA8989);
        break;
      case 'Late':
        statusColor = const Color(0xFFFF9155);
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
          color: const Color(0xFF32657D),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFC8C8C8).withValues(alpha: 1),
            width: 0.7,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 3,
              offset: const Offset(0, 0),
            ),
          ],
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
                      fontWeight: FontWeight.w400,
                      color: Color.fromARGB(255, 255, 255, 255),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    time,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFFBABABA),
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
                  border: Border.all(
                    color: const Color(0xFFB4B4B4).withValues(alpha: 1),
                    width: 0.7,
                  ),
                ),
                child: Text(
                  status,
                  style: const TextStyle(
                    color: Color(0xFF253F4C),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
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
