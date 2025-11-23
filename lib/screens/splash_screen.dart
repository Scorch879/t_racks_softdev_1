import 'dart:async'; // Import this for the Timer
import 'package:flutter/material.dart';
import 'package:t_racks_softdev_1/screens/welcome_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:t_racks_softdev_1/services/auth_service.dart';
import 'package:t_racks_softdev_1/screens/onBoarding_screen/onBoarding_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:t_racks_softdev_1/screens/login_screen.dart';
import 'package:t_racks_softdev_1/services/database_service.dart';
import 'package:t_racks_softdev_1/screens/student_home_screen.dart';
import 'package:t_racks_softdev_1/screens/educator/educator_home_screen.dart';

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
    _redirect();
  }

Future<void> _redirect() async {
    await Future.delayed(Duration.zero);
    
    // 1. Check the "Remember Me" preference first
    final prefs = await SharedPreferences.getInstance();
    final bool rememberMe = prefs.getBool('remember_me') ?? true; // Default to true if unknown

    final supabase = Supabase.instance.client;
    final session = supabase.auth.currentSession;

    if (!mounted) return;

    // 2. Logic: If they exist BUT didn't want to be remembered, log them out now.
    if (session != null && !rememberMe) {
      await supabase.auth.signOut();
      if (!mounted) return;
      Navigator.pushReplacement(context,MaterialPageRoute(builder: (context) => const LoginScreen()), );
      return; // Stop here
    }

    // 3. Standard Session Check (Your existing logic)
    if (session == null) {
      Navigator.pushReplacement(context,MaterialPageRoute(builder: (context) => const LoginScreen()),);
    } else {
      // ... Your existing role/onboarding check ...
      final user = session.user;
      final role = user.userMetadata?['role'] as String;
      final bool didOnboarding = await DatabaseService().checkProfileExists();

      if (!didOnboarding) {
         // Go to Onboarding
         Navigator.pushReplacement(context,MaterialPageRoute(builder: (context) => OnBoardingScreen(role: role)),);
      } else {
        // Go to Home
        switch (role) {
          case 'student':
            Navigator.pushReplacement(context,MaterialPageRoute(builder: (context) => const StudentHomeScreen()),);
            break;
          case 'educator':
            Navigator.pushReplacement(context,MaterialPageRoute(builder: (context) => const EducatorHomeScreen()),);
            break;
          default:
            await supabase.auth.signOut();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
        }
      }
    }
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
            Image.asset('assets/images/t_racks_logo.png', width: 500),
            const SizedBox(height: 40),
            const Text(
              'Intelligent Attendance',
              style: TextStyle(
                fontSize: 30,
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
