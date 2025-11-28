import 'package:flutter/material.dart';

class EducatorProfileService {
  static Future<Map<String, String>> fetchProfile() async {
    // Mock data for now
    await Future.delayed(const Duration(milliseconds: 500));
    return {
      'firstName': 'Sarah',
      'lastName': 'Connor',
      'email': 'sarah.connor@skynet.edu',
      'bio': 'Professor of Robotics | AI Ethics Specialist',
      'role': 'Senior Educator',
    };
  }
}
