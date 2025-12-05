import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Import Supabase
import 'package:t_racks_softdev_1/screens/student/student_shell_camvoice_screen.dart';
import 'package:t_racks_softdev_1/screens/student/student_camera_content.dart';

class StudentCameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const StudentCameraScreen({super.key, required this.cameras});

  @override
  State<StudentCameraScreen> createState() => _StudentCameraScreenState();
}

class _StudentCameraScreenState extends State<StudentCameraScreen> {
  List<double>? _faceVector;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchStudentVector();
  }

  Future<void> _fetchStudentVector() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw "User not logged in";

      // Fetch the vector from Student_Table
      final response = await Supabase.instance.client
          .from('Student_Table')
          .select('face_vector')
          .eq('id', userId)
          .single();

      if (response['face_vector'] != null) {
        // Convert dynamic list to List<double>
        final List<dynamic> vectorData = response['face_vector'];
        setState(() {
          _faceVector = vectorData.map((e) => (e as num).toDouble()).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = "No Face ID registered.";
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching face vector: $e");
      setState(() {
        _errorMessage = "Error loading profile.";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Show loading while fetching vector
    if (_isLoading) {
      return const StudentShellCamvoiceScreen(
        child: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    // 2. Show error if no vector found (User needs to register face)
    if (_errorMessage != null || _faceVector == null || _faceVector!.isEmpty) {
      return StudentShellCamvoiceScreen(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.face_retouching_off,
                color: Colors.red,
                size: 60,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage ?? "Face Not Registered",
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 8),
              const Text(
                "Please go to settings to register your Face ID.",
                style: TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Go Back"),
              ),
            ],
          ),
        ),
      );
    }

    // 3. Success: Pass the vector to the camera content
    return StudentShellCamvoiceScreen(
      child: StudentCameraContent(
        cameras: widget.cameras,
        studentSavedVector: _faceVector!, // FIX: Passing the required argument
      ),
    );
  }
}
