import 'package:flutter/material.dart';

class EducatorProfileService {
  static Future<Map<String, String>> fetchProfile() async {
    // Mock data for now
    await Future.delayed(const Duration(milliseconds: 500));
    return {
      'firstName': 'John',
      'lastName': 'Virtues',
      'email': 'john.virtues@example.com',
      'bio': 'Teacher | Plumber | Fireman | Astronaut',
      'role': 'Educator',
    };
  }
}
