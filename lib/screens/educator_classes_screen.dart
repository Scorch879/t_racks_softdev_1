import 'package:flutter/material.dart';
import 'package:t_racks_softdev_1/services/educator_service.dart';
import 'package:t_racks_softdev_1/screens/educator_classroom_screen.dart';
import 'package:t_racks_softdev_1/services/educator_notification_service.dart';

class EducatorClassesScreen extends StatefulWidget {
  const EducatorClassesScreen({super.key});

  @override
  State<EducatorClassesScreen> createState() => _EducatorClassesScreenState();
}

class _EducatorClassesScreenState extends State<EducatorClassesScreen> {
  int currentNavIndex = 1;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    EducatorNotificationService.register(context);
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: _TopBar(),
      ),
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
                opacity: 0.3,
                child: Image.asset(
                  'assets/images/squigglytexture.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  _buildSummaryCards(),
                  const SizedBox(height: 16),
                  _buildMyClassesSection(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildSummaryCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              icon: Icons.bookmark,
              iconColor: const Color(0xFF4CAF50),
              value: '3',
              label: 'Total Classes',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              icon: Icons.bar_chart,
              iconColor: const Color(0xFF4CAF50),
              value: '92%',
              label: 'Avg. Attendance',
            ),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF194B61),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
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
    );
  }

  Widget _buildMyClassesSection() {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.star,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'My Classes',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(
                  Icons.add,
                  color: Color(0xFF4CAF50),
                ),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSearchBar(),
          const SizedBox(height: 16),
          _buildClassList(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search Class',
                hintStyle: TextStyle(
                  color: Color(0xFF757575),
                ),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassList() {
    final classes = [
      {
        'name': 'Calculus 137',
        'students': 28,
        'attendance': 91,
        'next': 'Tomorrow 9:00 AM',
        'status': 'Active',
        'studentsList': [
          {'name': 'Carla Jay O. Rimera', 'time': '8:00 AM', 'status': 'Late'},
          {'name': 'Mama Merto Rodigo', 'time': '8:00 AM', 'status': 'Absent'},
          {'name': 'One Pablo Reinstal..', 'time': '8:00 AM', 'status': 'Present'},
          {'name': 'Joaquin De Coco', 'time': '8:00 AM', 'status': 'Present'},
          {'name': 'Zonrox D. Color', 'time': '8:00 AM', 'status': 'Present'},
        ],
      },
      {
        'name': 'Physics 138',
        'students': 38,
        'attendance': 80,
        'next': 'Tomorrow 9:00 AM',
        'status': 'Active',
        'studentsList': [
          {'name': 'Carla Jay O. Rimera', 'time': '8:00 AM', 'status': 'Late'},
          {'name': 'Mama Merto Rodigo', 'time': '8:00 AM', 'status': 'Absent'},
          {'name': 'One Pablo Reinstal..', 'time': '8:00 AM', 'status': 'Present'},
          {'name': 'Joaquin De Coco', 'time': '8:00 AM', 'status': 'Present'},
          {'name': 'Zonrox D. Color', 'time': '8:00 AM', 'status': 'Present'},
        ],
      },
      {
        'name': 'Calculus 237',
        'students': 18,
        'attendance': 100,
        'next': 'Tomorrow 9:00 AM',
        'status': 'Active',
        'studentsList': [
          {'name': 'Carla Jay O. Rimera', 'time': '8:00 AM', 'status': 'Late'},
          {'name': 'Mama Merto Rodigo', 'time': '8:00 AM', 'status': 'Absent'},
          {'name': 'One Pablo Reinstal..', 'time': '8:00 AM', 'status': 'Present'},
          {'name': 'Joaquin De Coco', 'time': '8:00 AM', 'status': 'Present'},
          {'name': 'Zonrox D. Color', 'time': '8:00 AM', 'status': 'Present'},
        ],
      },
    ];

    return Column(
      children: classes.map((classData) {
        return _buildClassCard(
          name: classData['name'] as String,
          students: classData['students'] as int,
          attendance: classData['attendance'] as int,
          next: classData['next'] as String,
          status: classData['status'] as String,
          studentsList:
              (classData['studentsList'] as List).cast<Map<String, String>>(),
        );
      }).toList(),
    );
  }

  Widget _buildClassCard({
    required String name,
    required int students,
    required int attendance,
    required String next,
    required String status,
    required List<Map<String, String>> studentsList,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EducatorClassroomScreen(
              className: name,
              nextSchedule: next,
              students: studentsList,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF194B61),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Students',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      '${students}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Attendance',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      '${attendance}%',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Next: $next',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF66BB6A),
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

  Widget _buildBottomNavBar() {
    return Container(
      padding: const EdgeInsets.only(
        left: 24,
        right: 24,
        top: 10,
        bottom: 20,
      ),
      decoration: const BoxDecoration(color: Colors.white),
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
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        setState(() {
          currentNavIndex = index;
        });
        EducatorService.handleNavigationTap(context, index);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF93C0D3) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          icon,
          color: Colors.black87,
          size: 24,
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFFB7C5C9),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Teacher',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Teacher',
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  iconSize: 23,
                  onPressed: EducatorNotificationService.onNotificationsPressed,
                  icon: const Icon(Icons.notifications_none_rounded),
                  color: Colors.black87,
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF167C94),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: const Text(
                      '1',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

