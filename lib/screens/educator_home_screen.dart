import 'package:flutter/material.dart';

class EducatorHomeScreen extends StatelessWidget {
  const EducatorHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Educator Home'),
      ),
      body: const Center(
        child: Text('Welcome, Educator!'),
      ),
    );
  }
}