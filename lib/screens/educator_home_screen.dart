import 'package:flutter/material.dart';
import 'package:t_racks_softdev_1/services/educator_service.dart';
import 'package:t_racks_softdev_1/services/educator_notification_service.dart';

class EducatorHomeScreen extends StatefulWidget {
  const EducatorHomeScreen({super.key});

  @override
  State<EducatorHomeScreen> createState() => _EducatorHomeScreenState();
}

class _EducatorHomeScreenState extends State<EducatorHomeScreen> {
  String selectedClass = 'All Classes';
  int currentNavIndex = 0;

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
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(      ),
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
          color: const Color(0xFFC8C8C8).withOpacity(1),
          width: 0.7,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 5,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween, // Align header and menu icon
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
          // CHANGED: Wrap -> Column to allow full-width stretching
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, // This stretches buttons to fill width
            children: [
              _buildClassButton('All Classes', 72, selectedClass == 'All Classes'),
              const SizedBox(height: 8), // Add spacing between buttons
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
      child: Container(
        // margin: const EdgeInsets.only(bottom: 8), // Optional: Move spacing here if preferred
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Increased vertical padding slightly
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3AB389) : const Color(0xFF277D5F),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 4,
              offset: isSelected ? const Offset(0, 0) : const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          // REMOVED: mainAxisSize: MainAxisSize.min (This was preventing full width)
          children: [
            Text(
              className,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500, // Slightly bolder for readability
                fontSize: 15,
              ),
            ),
            
            // ADDED: Spacer pushes the next child to the far right
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
      aspectRatio: 1.0, // Keeps the card square
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0C3343),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: const Color(0xFFC8C8C8).withOpacity(1),
            width: 0.7,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
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
