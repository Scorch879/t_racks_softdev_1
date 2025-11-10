import 'package:flutter/material.dart';
import 'package:t_racks_softdev_1/screens/educator_classes_screen.dart';
import 'package:t_racks_softdev_1/screens/educator_home_screen.dart';

class EducatorService {
  static void navigateToHomeScreen(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const EducatorHomeScreen(),
      ),
    );
  }

  static void navigateToClassesScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EducatorClassesScreen(),
      ),
    );
  }

  static void handleNavigationTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        navigateToHomeScreen(context);
        break;
      case 1:
        navigateToClassesScreen(context);
        break;
      case 2:
        break;
      case 3:
        break;
      default:
        break;
    }
  }
}

