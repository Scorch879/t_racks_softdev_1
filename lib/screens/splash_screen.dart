import 'package:flutter/material.dart';
import 'package:t_racks_softdev_1/screens/student/student_shell_screen.dart';
import 'package:t_racks_softdev_1/screens/educator/educator_shell.dart';
import 'package:t_racks_softdev_1/screens/welcome_screen.dart';
import 'package:t_racks_softdev_1/services/auth_service.dart';
import 'package:t_racks_softdev_1/screens/onBoarding_screen/onBoarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _handleNavigation();
  }

  Future<void> _handleNavigation() async {
    // Optional: Add a minimum delay (e.g., 2 seconds) so the logo doesn't flash too fast
    // We run the delay AND the logic at the same time and wait for both.
    final results = await Future.wait([
      _authService.determineInitialPath(),
      Future.delayed(const Duration(seconds: 2)), 
    ]);

    if (!mounted) return;

    // The first result from the list is our Navigation State
    final AuthNavigationState state = results[0] as AuthNavigationState;

    switch (state) {
      case AuthNavigationState.login:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        );
        break;

      case AuthNavigationState.onboarding:
        // We can fetch the role safely here because we know they are logged in
        final role = _authService.getCurrentUserRole() ?? 'student'; 
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => OnBoardingScreen(role: role)),
        );
        break;

      case AuthNavigationState.studentHome:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const StudentShellScreen()),
        );
        break;

      case AuthNavigationState.educatorHome:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const EducatorShell()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
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
            const SizedBox(height: 20),
            // It is good practice to show a loader while checking the database
            const CircularProgressIndicator(), 
          ],
        ),
      ),
    );
  }
}