import 'dart:async'; // Import this for the Timer
import 'package:flutter/material.dart';
// We'll create this file next
 import 'package:t_racks_softdev_1/screens/welcome_screen.dart'; 

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    // Start the timer when the screen is built
    startTimer();
  }

  startTimer() {
    // Wait for 3 seconds, then run the code inside
    Timer(const Duration(seconds: 3), () {
      
      // Navigate to the Welcome Screen
      // You'll need to create 'welcome_screen.dart' just like you did this file.
       Navigator.pushReplacement(
         context,
         MaterialPageRoute(builder: (context) => const WelcomeScreen()),
       );
    });
  }

  @override
  Widget build(BuildContext context) {
    // This is the same UI code from before
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/placeholder.png',
              width: 200,
            ),
            const SizedBox(height: 16),
            const Text(
              'Intelligent Attendance',
              style: TextStyle(
                fontSize: 18,
                color: Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}