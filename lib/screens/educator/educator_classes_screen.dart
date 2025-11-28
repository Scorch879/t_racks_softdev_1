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

  @override
  void initState() {
    super.initState();
    // 2. Load the data when the screen first opens
    _classesFuture = _dbService.getEducatorClasses();
  }

  // 3. Add a function to refresh the data
  void _refreshClasses() {
    setState(() {
      _classesFuture = _dbService.getEducatorClasses();
    });
  }

  @override
  Widget build(BuildContext context) {
    // We use a specific scroll physics to ensure it feels right
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 16),
                _buildSummaryCards(),
                const SizedBox(height: 24),
          
                // This is the section with the new button
                _buildMyClassesSection(),
          
                // Add padding at the bottom so content isn't hidden by the nav bar
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
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
          color: const Color(0xFFBDBBBB).withValues(alpha: 1),
          width: 0.75
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25), 
            blurRadius: 5
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'My Classes',
                style: TextStyle(
                  fontSize: 20, 
                  fontWeight: FontWeight.bold, 
                  color: Colors.white
                ),
              ),
              
              // --- REPLACED GESTURE DETECTOR WITH ELEVATED BUTTON ---
              SizedBox(
                height: 32,
                child: ElevatedButton.icon(
                  // 1. Make this async so we can wait
                  onPressed: () async {
                    // 2. Use showDialog for the centered, floating look
                    await showDialog(
                      context: context,
                      builder: (context) => const CreateClassModal(),
                    );
                    
                    // 3. This runs ONLY after the modal closes
                    // It refreshes the list to show your new class immediately
                    _refreshClasses();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7FE26B), // The "Active" green
                    foregroundColor: const Color(0xFF0C3343), // Dark text/icon color
                    elevation: 0, 
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text(
                    "Create Class",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              // ------------------------------------------------------
            ],
          ),
          const SizedBox(height: 15),
          
          // Future Builder
          FutureBuilder<List<EducatorClassSummary>>(
            future: _dbService.getEducatorClasses(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.white));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      "No classes found.", 
                      style: TextStyle(color: Colors.white70)
                    ),
                  ),
                );
              }

              return Column(
                children: snapshot.data!.map((classData) {
                  return _buildClassCard(classData);
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
  Widget _buildClassCard(EducatorClassSummary classData) {
    // Helper to get color based on status
    Color statusColor = classData.status.toLowerCase() == 'active' 
        ? const Color(0xFF7FE26B) 
        : Colors.grey;
    
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
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF376375),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFBDBBBB), width: 0.75),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
        ),
        // Use Stack to position elements
        child: Stack(
          children: [
            // --- 1. MAIN CONTENT ---
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Padding on the right so text doesn't hit the pill
                Padding(
                  padding: const EdgeInsets.only(right: 80.0), 
                  child: Text(
                    classData.className,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
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
                  style: const TextStyle(fontSize: 14, color: Color(0xFFD5D5D5)),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),

            // --- 2. STATUS PILL (TOP RIGHT) ---
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  classData.status,
                  style: const TextStyle(
                    color: Color(0xFF0C3343), 
                    fontSize: 12, 
                    fontWeight: FontWeight.bold
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

  // --- Summary Cards (Same as before) ---
  Widget _buildSummaryCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              icon: Icons.book,
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
      height: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0C3343),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFBDBBBB).withValues(alpha: 1),
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
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                label,
                style: const TextStyle(fontSize: 13, color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
