import 'package:flutter/material.dart';
import 'package:t_racks_softdev_1/services/database_service.dart';
// import 'package:t_racks_softdev_1/screens/educator/educator_add_student_screen.dart';

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
  State<EducatorClassroomScreen> createState() => _EducatorClassroomScreenState();
}

class _EducatorClassroomScreenState extends State<EducatorClassroomScreen> {
  final DatabaseService _dbService = DatabaseService();
  final TextEditingController _searchController = TextEditingController();
  
  List<StudentAttendanceItem> studentList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  void _fetchStudents() async {
    final students = await _dbService.getClassStudents(widget.classId);
    if (mounted) {
      setState(() {
        studentList = students;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color.fromARGB(221, 255, 255, 255)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Classroom", style: TextStyle(color: Color.fromARGB(221, 255, 255, 255))),
      ),
      body: Stack(
        children: [
          // --- 1. BACKGROUND ---
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF194B61), Color(0xFF2A7FA3), Color(0xFF267394), Color(0xFF349BC7)],
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
          
          // --- 2. CONTENT ---
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0), // Remove bottom padding here
              child: Column(
                // This Column takes up the screen height
                children: [
                  // Use Flexible to allow the card to shrink/grow
                  Flexible(
                    fit: FlexFit.loose, // This makes it "hug" content when small
                    child: _buildClassroomCard(),
                  ),
                  // Add some spacing at bottom so card doesn't touch edge
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
        border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Important: Hug vertical content
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Header ---
          Row(
            children: [
              const Icon(Icons.star, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.className, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(widget.schedule, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // --- Search Bar ---
          TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search Student',
              hintStyle: const TextStyle(color: Colors.white70),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.1),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              prefixIcon: const Icon(Icons.search, color: Colors.white70),
            ),
          ),
          const SizedBox(height: 16),

          // --- LIST AREA ---
          // Flexible + shrinkWrap allows it to be small when few items,
          // but scrollable when it hits the max height of the screen.
          Flexible(
            fit: FlexFit.loose,
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : studentList.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Center(child: Text("No students enrolled", style: TextStyle(color: Colors.white70))),
                      )
                    : ListView.builder(
                        shrinkWrap: true, // Allow it to shrink!
                        padding: EdgeInsets.zero, // Remove extra padding
                        itemCount: studentList.length,
                        itemBuilder: (context, index) {
                          return _buildStudentTile(studentList[index]);
                        },
                      ),
          ),
          
          const SizedBox(height: 16),
          
          // --- Add Student Button ---
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () {
                // Navigate to Add Student
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2A7FA3)),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Add Student', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentTile(StudentAttendanceItem student) {
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
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey, 
              borderRadius: BorderRadius.circular(12)
            ),
            child: const Text("Mark Attendance", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}