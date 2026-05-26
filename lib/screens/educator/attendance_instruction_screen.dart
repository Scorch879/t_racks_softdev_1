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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final gradientColors = isDarkMode
        ? const [
            Color(0xFF092633),
            Color(0xFF0F3951),
            Color(0xFF15516B),
            Color(0xFF1A6686),
          ]
        : const [
            Color(0xFFEAF7FB),
            Color(0xFFD9EEF5),
            Color(0xFFC7E4EE),
            Color(0xFFEFF9FC),
          ];
    final cardColor = isDarkMode
        ? const Color(0xFF0C3343).withValues(alpha: 0.95)
        : Colors.white.withValues(alpha: 0.94);
    final primaryTextColor = isDarkMode
        ? Colors.white
        : const Color(0xFF0C3343);
    final secondaryTextColor = isDarkMode
        ? Colors.white70
        : const Color(0xFF376375);
    final accentColor = isDarkMode
        ? const Color(0xFF7FE26B)
        : const Color(0xFF2A7FA3);
    final buttonTextColor = isDarkMode ? const Color(0xFF0C3343) : Colors.white;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: primaryTextColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Opacity(
                opacity: isDarkMode ? 0.3 : 0.12,
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
                color: cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDarkMode ? Colors.white24 : const Color(0xFF93C0D3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.face_retouching_natural,
                    size: 64,
                    color: accentColor,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Start Attendance",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: primaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Ensure you are in a well-lit area.\nThe system will verify student identity and liveness before marking attendance.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 14,
                      height: 1.5,
                    ),
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
                        backgroundColor: accentColor,
                        foregroundColor: buttonTextColor,
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
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
