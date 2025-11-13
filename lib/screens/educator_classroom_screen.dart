import 'package:flutter/material.dart';
import 'package:t_racks_softdev_1/services/educator_service.dart';
import 'package:t_racks_softdev_1/screens/educator_add_student_screen.dart';

class EducatorClassroomScreen extends StatefulWidget {
  const EducatorClassroomScreen({
    super.key,
    required this.className,
    required this.nextSchedule,
    required this.students,
  });

  final String className;
  final String nextSchedule;
  final List<Map<String, String>> students;

  @override
  State<EducatorClassroomScreen> createState() => _EducatorClassroomScreenState();
}

class _EducatorClassroomScreenState extends State<EducatorClassroomScreen> {
  final TextEditingController _searchController = TextEditingController();
  int currentNavIndex = 1;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
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
                opacity: 0.25,
                child: Image.asset(
                  'assets/images/squigglytexture.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTopBar(context),
                  const SizedBox(height: 16),
                  _buildTeacherCard(),
                  const SizedBox(height: 16),
                  _buildClassroomCard(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'Classroom - Teacher',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.more_horiz, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildTeacherCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.6), width: 2),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0xFFE1F5FE),
            child: Image.asset(
              'assets/images/placeholder.png',
              width: 40,
              height: 40,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Teacher',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF194B61),
                  ),
                ),
                Text(
                  'Teacher',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF2A7FA3),
                  ),
                ),
              ],
            ),
          ),
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none),
                color: const Color(0xFF194B61),
                onPressed: () {},
              ),
              Positioned(
                right: 10,
                top: 10,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2A7FA3),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      '1',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClassroomCard() {
    final students = widget.students;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0F3951).withOpacity(0.85),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.star, color: Colors.white),
              const SizedBox(width: 8),
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
                      widget.nextSchedule,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSearchBar(),
          const SizedBox(height: 16),
          Column(
            children: students.map((student) {
              return _buildStudentTile(
                name: student['name'] ?? '',
                time: student['time'] ?? '',
                status: student['status'] ?? '',
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () {
                final availableStudents = widget.students
                    .map(
                      (student) => {
                        'name': student['name'] ?? '',
                        'subtitle':
                            '${student['status'] ?? 'Available'} • ${student['time'] ?? ''}',
                      },
                    )
                    .toList();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EducatorAddStudentScreen(
                      className: widget.className,
                      availableStudents: availableStudents,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2A7FA3),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Add Student'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.white70),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Search Student',
                hintStyle: TextStyle(color: Colors.white70),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentTile({
    required String name,
    required String time,
    required String status,
  }) {
    final Color statusColor;
    switch (status.toLowerCase()) {
      case 'present':
        statusColor = const Color(0xFF43A047);
        break;
      case 'absent':
        statusColor = const Color(0xFFE53935);
        break;
      case 'late':
        statusColor = const Color(0xFFFFA726);
        break;
      default:
        statusColor = const Color(0xFF90A4AE);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF133A53),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.white.withOpacity(0.1),
            child: const Icon(Icons.person_outline, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.home, 0),
          _buildNavItem(Icons.calendar_today, 1),
          _buildNavItem(Icons.upload_file, 2),
          _buildNavItem(Icons.settings, 3),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    final isSelected = currentNavIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          currentNavIndex = index;
        });
        EducatorService.handleNavigationTap(context, index);
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFB3E5FC) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isSelected ? const Color(0xFF194B61) : Colors.grey[600],
        ),
      ),
    );
  }
}

