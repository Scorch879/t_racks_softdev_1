import 'package:flutter/material.dart';

// Shared background widget for all educator screens
class EducatorBackground extends StatelessWidget {
  const EducatorBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF194B61),
                  Color(0xFF2A7FA3),
                  Color(0xFF267394),
                  Color(0xFF349BC7),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Opacity(
              opacity: 0.3,
              child: Image.asset(
                'assets/images/squigglytexture.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

