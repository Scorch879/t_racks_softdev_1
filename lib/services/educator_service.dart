import 'package:flutter/material.dart';
import 'package:t_racks_softdev_1/screens/educator/educator_shell.dart';

class EducatorService {
  static void navigateToHomeScreen(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const EducatorShell(initialIndex: 0),
      ),
    );
  }

  static void navigateToClassesScreen(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const EducatorShell(initialIndex: 1),
      ),
    );
  }

  static void handleNavigationTap(BuildContext context, int index) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => EducatorShell(initialIndex: index),
      ),
    );
  }
}

