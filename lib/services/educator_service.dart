import 'package:flutter/material.dart';
import 'package:t_racks_softdev_1/screens/educator/educator_shell.dart';

class EducatorService {
  // Mock Database Data
  static final List<Map<String, dynamic>> _classes = [
    {
      'name': 'Calculus 137',
      'students': 28,
      'attendance': 91,
      'next': 'Tomorrow 9:00 AM',
      'status': 'Active',
      'studentsList': [
        {'name': 'Carla Jay O. Rimera', 'time': '8:00 AM', 'status': 'Late'},
        {'name': 'Mama Merto Rodigo', 'time': '8:00 AM', 'status': 'Absent'},
        {'name': 'One Pablo Reinstal..', 'time': '8:00 AM', 'status': 'Present'},
        {'name': 'Joaquin De Coco', 'time': '8:00 AM', 'status': 'Present'},
        {'name': 'Zonrox D. Color', 'time': '8:00 AM', 'status': 'Present'},
      ],
    },
    {
      'name': 'Physics 138',
      'students': 38,
      'attendance': 80,
      'next': 'Tomorrow 9:00 AM',
      'status': 'Active',
      'studentsList': [
        {'name': 'Carla Jay O. Rimera', 'time': '8:00 AM', 'status': 'Late'},
        {'name': 'Mama Merto Rodigo', 'time': '8:00 AM', 'status': 'Absent'},
        {'name': 'One Pablo Reinstal..', 'time': '8:00 AM', 'status': 'Present'},
        {'name': 'Joaquin De Coco', 'time': '8:00 AM', 'status': 'Present'},
        {'name': 'Zonrox D. Color', 'time': '8:00 AM', 'status': 'Present'},
      ],
    },
    {
      'name': 'Calculus 237',
      'students': 18,
      'attendance': 100,
      'next': 'Tomorrow 9:00 AM',
      'status': 'Active',
      'studentsList': [
        {'name': 'Carla Jay O. Rimera', 'time': '8:00 AM', 'status': 'Late'},
        {'name': 'Mama Merto Rodigo', 'time': '8:00 AM', 'status': 'Absent'},
        {'name': 'One Pablo Reinstal..', 'time': '8:00 AM', 'status': 'Present'},
        {'name': 'Joaquin De Coco', 'time': '8:00 AM', 'status': 'Present'},
        {'name': 'Zonrox D. Color', 'time': '8:00 AM', 'status': 'Present'},
      ],
    },
  ];

  static final List<Map<String, dynamic>> _notifications = [
    {
      'title': 'Attendance Summary Ready',
      'subtitle': 'Calculus 137 daily report is generated.',
      'timestamp': 'Just now',
      'type': 'success',
    },
    {
      'title': 'Low Attendance Warning',
      'subtitle': 'Physics 138 attendance fell below 80%.',
      'timestamp': '1 hour ago',
      'type': 'warning',
    },
    {
      'title': 'New Submission',
      'subtitle': 'Lab Report for Calculus 237 received.',
      'timestamp': '2 hours ago',
      'type': 'info',
    },
    {
      'title': 'Parent Meeting Scheduled',
      'subtitle': 'Carla Jay O. Rimera - Tomorrow at 3:00 PM.',
      'timestamp': 'Yesterday',
      'type': 'info',
    },
  ];

  // Data Access Methods
  static Future<List<Map<String, dynamic>>> getClasses() async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 100));
    return _classes;
  }

  static Future<List<Map<String, dynamic>>> getNotifications() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _notifications;
  }

  static Future<Map<String, String>> getAttendanceSummary() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return {
      'present': '68',
      'absent': '4',
      'rate': '94%',
      'late': '3',
    };
  }
}

