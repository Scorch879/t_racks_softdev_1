import 'package:flutter/material.dart';
import 'package:t_racks_softdev_1/screens/educator/educator_classroom_screen.dart';
import 'package:t_racks_softdev_1/screens/educator/educator_view_model.dart';

class EducatorClassesScreen extends StatefulWidget {
  const EducatorClassesScreen({super.key});

  @override
  State<EducatorClassesScreen> createState() => _EducatorClassesContentState();
}

class _EducatorClassesContentState extends State<EducatorClassesScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 16),
              _buildSummaryCards(),
          const SizedBox(height: 24), // Increased spacing to separate sections
              _buildMyClassesSection(),
              const SizedBox(height: 16),
            ],
          ),
    );
  }

  Widget _buildSummaryCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              icon: Icons.book, // Changed to Book icon to match image
              iconColor: const Color(0xFF68D080),
              value: '3',
              label: 'Total Classes',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              icon: Icons.bar_chart,
              iconColor: const Color(0xFF68D080),
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
      height: 140, // Fixed height to match aspect ratio
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0C3343),
        borderRadius: BorderRadius.circular(20), // More rounded corners
        border: Border.all(
          color: const Color(0xFFBDBBBB),
          width: 0.75,
        ),
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
          Icon(icon, color: iconColor, size: 28),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Text(
            value,
            style: const TextStyle(
                  fontSize: 32, // Larger font for the number
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
                  fontSize: 13,
              color: Colors.white70,
            ),
          ),
        ],
          )
        ],
      ),
    );
  }

  Widget _buildMyClassesSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0C3343),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFBDBBBB),
          width: 0.75,
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
              Row(
                children: [
                  const Icon(
                    Icons.star,
                    color: Color(0xFF64B5F6), // Light blue star
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'My Classes',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(
                  Icons.add,
                  color: Color(0xFF7FE26B), // Matching green color
                  size: 36,
                ),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildSearchBar(),
          const SizedBox(height: 15),
          _buildClassList(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF538DAB), // Adjusted to match Figma blue-grey
        borderRadius: BorderRadius.circular(24), // Pill shape
      ),
      child: Row(
        children: [
          Icon(
            Icons.search,
            color: const Color(0xFF0C3343).withValues(alpha: 0.75),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Search Class',
                hintStyle: TextStyle(
                  color: Colors.white60,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassList() {
    final classes = EducatorViewModel.getClasses();

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
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.only(left: 40, top: 20, right: 20, bottom: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF376375), // Lighter slate blue for cards
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFBDBBBB), width: 0.75),
          boxShadow: [
             BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
          ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 5),
            
            // Stats Row
            Row(
              children: [
                _buildStatColumn('Students', '$students'),
                const SizedBox(width: 75), // Gap between stats
                _buildStatColumn('Attendance', '$attendance%'),
                  ],
                ),
            
            const SizedBox(height: 5),
            
            // Next Schedule
            Text(
              'Next: $next',
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFFD5D5D5),
                fontWeight: FontWeight.w400,
              ),
            ),
            
            const SizedBox(height: 5),
            
            // Active Button (Left Aligned now)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                decoration: BoxDecoration(
                color: const Color(0xFF7FE26B), // Lime green from Figma
                borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: const TextStyle(
                  color: Color(0xFF0C3343), // Dark text for contrast
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
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
          style: const TextStyle(
            fontSize: 15,
            color: Colors.white60,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}