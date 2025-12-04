import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:t_racks_softdev_1/screens/camera_screen.dart';

class AttendanceInstructionScreen extends StatelessWidget {
  const AttendanceInstructionScreen({super.key});

  Future<void> _openCamera(BuildContext context) async {
    try {
      // 1. Fetch available cameras from the device
      final cameras = await availableCameras();
      
      if (cameras.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No cameras found on device")),
          );
        }
        return;
      }

      // 2. Navigate to the actual Camera Screen
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AttendanceCameraScreen(cameras: cameras),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error initializing camera: $e")),
        );
      }
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
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Background
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
                ),
              ),
            ),
          ),
          
          // Content Card
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFF0C3343).withOpacity(0.95),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.face_retouching_natural, size: 64, color: Color(0xFF7FE26B)),
                  const SizedBox(height: 24),
                  const Text(
                    "Start Attendance",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Ensure you are in a well-lit area.\nThe system will verify student identity and liveness before marking attendance.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: () => _openCamera(context),
                      icon: const Icon(Icons.camera_alt_rounded),
                      label: const Text("Open Camera"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7FE26B),
                        foregroundColor: const Color(0xFF0C3343),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
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
}