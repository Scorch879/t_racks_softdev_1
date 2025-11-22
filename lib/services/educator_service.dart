import 'package:flutter/material.dart';
import 'package:t_racks_softdev_1/screens/educator/educator_classes_screen.dart';
import 'package:t_racks_softdev_1/screens/educator/educator_home_screen.dart';
import 'package:t_racks_softdev_1/screens/educator/educator_settings_screen.dart';
import 'package:t_racks_softdev_1/screens/educator/educator_report_screen.dart';

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
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const EducatorReportScreen(),
          ),
        );
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const EducatorSettingsScreen(),
          ),
        );
        break;
      default:
        break;
    }
  }
}

