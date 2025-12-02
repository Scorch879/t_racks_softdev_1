import 'package:flutter/material.dart';
import 'package:t_racks_softdev_1/screens/educator/educator_shell.dart';

class EducatorViewModel {
  static List<Map<String, dynamic>> getClasses() {
    return [
      {
        'name': 'Calculus 137',
        'students': 28,
        'attendance': 92,
        'next': '8:00 AM Tomorrow',
        'status': 'On Track',
        'studentsList': [
          {'name': 'Carla Jay D. Rimera', 'status': 'Present'},
          {'name': 'Mama Merto Rodigo', 'status': 'Absent'},
          {'name': 'One Pablo Reinstal..', 'status': 'Present'},
          {'name': 'Joaquin De Coco', 'status': 'Present'},
          {'name': 'Zonrox D. Color', 'status': 'Present'},
        ],
      },
      {
        'name': 'Physics 138',
        'students': 38,
        'attendance': 88,
        'next': '10:00 AM Tomorrow',
        'status': 'Attention',
        'studentsList': [],
      },
      {
        'name': 'Calculus 237',
        'students': 18,
        'attendance': 75,
        'next': '1:00 PM Tomorrow',
        'status': 'Critical',
        'studentsList': [],
      },
    ];
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
