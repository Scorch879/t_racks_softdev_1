import 'package:flutter/material.dart';
import 'package:t_racks_softdev_1/screens/logIn_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // The body is now a Column, just like LoginScreen
    return Scaffold(
      body: Column(
        children: [
          // Layer 1: Top Expanded (Blue Header)
          Expanded(
            // You can adjust this flex ratio
            child: ClipPath(
              // We use the convex (outward) curve from your LoginScreen
              clipper: BottomWaveClipper(),
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
                child: Image.asset(
                  'assets/images/squigglytexture.png',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            ),
          ),

          // Layer 2: Bottom Expanded (White Content Area)
          Expanded(
            // You can adjust this flex ratio
            child: Container(
              color: Colors.white,
              // We adjust padding, especially 'top', since the curve is different
              padding: const EdgeInsets.fromLTRB(32, 32, 32, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // "Welcome" Text
                  const Text(
                    'Welcome',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // "Lorem ipsum" Text
                  const Text(
                    'Lorem ipsum dolor sit amet consectetur.\nLorem id sit',
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),

                  // This spacer pushes the "Continue" button
                  // to the bottom of the screen
                  const Spacer(),

                  // "Continue" Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Green Circle Button
                      ElevatedButton(
                        onPressed: () {
                          // This navigation is correct
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(16),
                          backgroundColor: const Color(
                            0xFF4AC097,
                          ), // Teal/Green color
                        ),
                        child: const Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// This is the clipper from your LoginScreen (convex/outward curve)
class BottomWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height);

    var firstControlPoint = Offset(size.width * 0.25, size.height - 50);
    var firstEndPoint = Offset(size.width * 0.5, size.height - 20);
    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );

    var secondControlPoint = Offset(size.width * 0.75, size.height + 10);
    var secondEndPoint = Offset(size.width, size.height - 20);
    path.quadraticBezierTo(
      secondControlPoint.dx,
      secondControlPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );

    path.lineTo(size.width, 0);
    path.lineTo(0, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return false;
  }
}
