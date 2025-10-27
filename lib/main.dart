import 'package:flutter/material.dart';
// 1. Import your new screen file
import 'package:t_racks_softdev_1/screens/splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // This removes the "Debug" banner in the corner
      debugShowCheckedModeBanner: false,
      title: 'T-racks',
      
      // 2. Set the 'home' to your new SplashScreen
      home: const SplashScreen(),
    );
  }
}