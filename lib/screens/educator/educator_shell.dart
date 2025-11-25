import 'package:flutter/material.dart';
import 'package:t_racks_softdev_1/screens/educator/educator_home_screen.dart';
import 'package:t_racks_softdev_1/screens/educator/educator_classes_screen.dart';
import 'package:t_racks_softdev_1/screens/educator/educator_report_screen.dart';
import 'package:t_racks_softdev_1/screens/educator/educator_settings_screen.dart';

class EducatorShell extends StatelessWidget {
  final int initialIndex;

  const EducatorShell({super.key, this.initialIndex = 0});

  @override
  Widget build(BuildContext context) {
    switch (initialIndex) {
      case 0:
        return const EducatorHomeScreen();
      case 1:
        return const EducatorClassesScreen();
      case 2:
        return const EducatorReportScreen();
      case 3:
        return const EducatorSettingsScreen();
      default:
        return const EducatorHomeScreen();
    }
  }
}
