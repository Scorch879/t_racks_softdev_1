import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // We use a Stack to place the white curved container on top
    // of the blue background.
    return Scaffold(
      body: Stack(
        children: [
          // Layer 1: Blue Background
          // TODO: Replace this color with your background image
          Container(
            color: const Color(0xFF0D47A1), // A dark blue, similar to your design
            /* // --- UNCOMMENT THIS WHEN YOU ADD YOUR IMAGE ---
            // Make sure to add your background image to 'assets/images/'
            // and register it in pubspec.yaml
            child: Image.asset(
              'assets/images/welcome_background.png',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
            */
          ),

          // Layer 2: White Content Area with Curve
          Column(
            children: [
              // This SizedBox pushes the white container down
              // Adjust the height to match your design
              SizedBox(height: MediaQuery.of(context).size.height * 0.35),

              // This is the white container
              Expanded(
                child: ClipPath(
                  clipper: WelcomeCurveClipper(), // Our custom curve
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(32, 60, 32, 32), // More padding at top
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
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
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
                                // TODO: Navigate to Sign In page
                              },
                              style: ElevatedButton.styleFrom(
                                shape: const CircleBorder(),
                                padding: const EdgeInsets.all(16),
                                backgroundColor: const Color(0xFF26A69A), // Teal/Green color
                              ),
                              child: const Icon(
                                Icons.arrow_forward,
                                color: Colors.white,
                              ),
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}

// This class creates the custom concave curve
class WelcomeCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    // Start from the top left, but down a bit (this is the curve height)
    path.moveTo(0, 40);

    // Create the quadratic bezier curve
    // This curves "up" to the center and back "down"
    path.quadraticBezierTo(
      size.width / 2, // Control point X (middle)
      0,              // Control point Y (pulls curve up)
      size.width,     // End point X (top right)
      40              // End point Y (same as start)
    );

    // Go to the bottom right
    path.lineTo(size.width, size.height);
    // Go to the bottom left
    path.lineTo(0, size.height);
    // Close the shape
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return false; // This can be false since the curve is static
  }
}