import 'package:flutter/material.dart';

class BottomWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height);

    // First curve (dips down)
    var firstControlPoint = Offset(
      size.width * 0.25,
      size.height - 60, // <-- CHANGED (was 30)
    );
    var firstEndPoint = Offset(
      size.width * 0.5,
      size.height - 30, // <-- CHANGED (was 10)
    );

    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );

    // Second curve (swoops up)
    // These are unchanged, but you can tweak them too
    var secondControlPoint = Offset(size.width * 0.75, size.height + 10);
    var secondEndPoint = Offset(size.width, size.height - 20);

    path.quadraticBezierTo(
      secondControlPoint.dx,
      secondControlPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );

    // Line to the top-right corner
    path.lineTo(size.width, 0);
    // Line to the top-left corner
    path.lineTo(0, 0);

    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return false;
  }
}
