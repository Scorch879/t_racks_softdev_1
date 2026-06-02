import 'package:flutter/material.dart';
import 'package:t_racks_softdev_1/services/database_service.dart';

class EducatorAddStudentScreen extends StatefulWidget {
  const EducatorAddStudentScreen({
    super.key,
    required this.classId,
    required this.className,
    required this.availableStudents,
  });

  final String classId;
  final String className;
  final List<Map<String, String>> availableStudents;

  @override
  State<EducatorAddStudentScreen> createState() =>
      _EducatorAddStudentScreenState();
}

class _EducatorAddStudentScreenState extends State<EducatorAddStudentScreen> {
  final DatabaseService _dbService = DatabaseService();
  final TextEditingController _searchController = TextEditingController();

  // 1. Master list (everyone available)
  late List<Map<String, String>> _studentsList;
  // 2. Filtered list (what is shown on screen)
  late List<Map<String, String>> _filteredList;

  @override
  void initState() {
    super.initState();
    _studentsList = List.from(widget.availableStudents);
    // Initially, the filtered list is the same as the master list
    _filteredList = _studentsList;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 3. THE SEARCH LOGIC
  void _runFilter(String enteredKeyword) {
    List<Map<String, String>> results = [];
    if (enteredKeyword.isEmpty) {
      // If the search field is empty, show everyone
      results = _studentsList;
    } else {
      // Filter based on name (case-insensitive)
      results = _studentsList
          .where(
            (user) => user["name"]!.toLowerCase().contains(
              enteredKeyword.toLowerCase(),
            ),
          )
          .toList();
    }

    // Refresh the UI
    setState(() {
      _filteredList = results;
    });
  }

  Future<void> _handleAddStudent(String studentId) async {
    try {
      await _dbService.enrollStudent(
        classId: widget.classId,
        studentId: studentId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Student added successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        setState(() {
          // 4. IMPORTANT FIX: Remove by ID, not Index!
          // Since the list might be filtered, "Index 0" might delete the wrong person.
          _studentsList.removeWhere((student) => student['id'] == studentId);

          // Re-run the filter so the UI updates correctly
          _runFilter(_searchController.text);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding student: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? const Color(0xFF071E29) : Colors.white;
    final primaryTextColor = isDarkMode
        ? Colors.white
        : const Color(0xFF0C3343);
    final secondaryTextColor = isDarkMode
        ? Colors.white70
        : const Color(0xFF42697A);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: isDarkMode ? null : backgroundColor,
                gradient: isDarkMode
                    ? const LinearGradient(
                        colors: [
                          Color(0xFF194B61),
                          Color(0xFF2A7FA3),
                          Color(0xFF267394),
                          Color(0xFF349BC7),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      )
                    : null,
              ),
              child: Opacity(
                opacity: isDarkMode ? 0.2 : 0.08,
                child: Image.asset(
                  'assets/images/squigglytexture.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopBar(context),
                  const SizedBox(height: 16),
                  Text(
                    'Add Student: ${widget.className}',
                    style: TextStyle(
                      color: primaryTextColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 5. Connect the search field
                  _buildSearchField(),

                  const SizedBox(height: 16),
                  Expanded(
                    child: _filteredList.isEmpty
                        ? Center(
                            child: Text(
                              'No students found',
                              style: TextStyle(color: secondaryTextColor),
                            ),
                          )
                        : ListView.separated(
                            itemCount: _filteredList.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final student = _filteredList[index];
                              return _buildStudentCard(
                                name: student['name'] ?? '',
                                subtitle: student['subtitle'] ?? '',
                                onAdd: () => _handleAddStudent(student['id']!),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDarkMode ? Colors.white : const Color(0xFF0C3343);

    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios_new, color: iconColor),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final fieldColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.15)
        : const Color(0xFFEAF4F7);
    final primaryTextColor = isDarkMode
        ? Colors.white
        : const Color(0xFF0C3343);
    final secondaryTextColor = isDarkMode
        ? Colors.white70
        : const Color(0xFF42697A);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: fieldColor,
        borderRadius: BorderRadius.circular(20),
        border: isDarkMode ? null : Border.all(color: const Color(0xFFBBD7E2)),
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: secondaryTextColor, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              // 7. Call _runFilter whenever text changes
              onChanged: (value) => _runFilter(value),
              style: TextStyle(color: primaryTextColor),
              decoration: InputDecoration(
                hintText: 'Search Student',
                hintStyle: TextStyle(color: secondaryTextColor),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard({
    required String name,
    required String subtitle,
    required VoidCallback onAdd,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDarkMode
        ? const Color(0xFF10324A).withValues(alpha: 0.85)
        : Colors.white.withValues(alpha: 0.96);
    final primaryTextColor = isDarkMode
        ? Colors.white
        : const Color(0xFF0C3343);
    final secondaryTextColor = isDarkMode
        ? Colors.white70
        : const Color(0xFF42697A);
    final avatarBackgroundColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.2)
        : const Color(0xFFEAF4F7);
    final avatarIconColor = isDarkMode ? Colors.white : const Color(0xFF2A7FA3);
    final borderColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.1)
        : const Color(0xFFBBD7E2);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: avatarBackgroundColor,
            child: Icon(Icons.person_outline, color: avatarIconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: primaryTextColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: secondaryTextColor, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onAdd,
            icon: Icon(Icons.add_circle_outline, color: secondaryTextColor),
          ),
        ],
      ),
    );
  }
}
