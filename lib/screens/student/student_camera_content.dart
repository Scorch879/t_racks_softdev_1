import 'package:flutter/material.dart';

class StudentCameraContent extends StatelessWidget {
  const StudentCameraContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Full-screen camera placeholder background
        Image.asset(
          'assets/images/placeholder.png', // Using a placeholder as requested
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(color: Colors.black);
          },
        ),
        
        // Overlay Gradient for better visibility of text/icons
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.3),
                Colors.transparent,
                Colors.transparent,
                Colors.black.withOpacity(0.5),
              ],
              stops: const [0.0, 0.2, 0.8, 1.0],
            ),
          ),
        ),

        // 2. Top: Back arrow and Notification Banner
        SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back Arrow
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Icon(
                        Icons.arrow_back_rounded, // Using rounded arrow as per style
                        color: Color(0xFF93C0D3), // Light blue accent color
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Notification Banner
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Text(
                          'You have not taken your attendance for Physics 138',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 3. Center: Face-scanning viewfinder frame
        Center(
          child: SizedBox(
            width: 300,
            height: 450,
            child: Stack(
              children: [
                // Corner Brackets
                // Top Left
                Positioned(
                  top: 0,
                  left: 0,
                  child: _CornerBracket(isTop: true, isLeft: true),
                ),
                // Top Right
                Positioned(
                  top: 0,
                  right: 0,
                  child: _CornerBracket(isTop: true, isLeft: false),
                ),
                // Bottom Left
                Positioned(
                  bottom: 0,
                  left: 0,
                  child: _CornerBracket(isTop: false, isLeft: true),
                ),
                // Bottom Right
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: _CornerBracket(isTop: false, isLeft: false),
                ),

                // REC Indicator
                const Positioned(
                  top: 20,
                  right: 20,
                  child: Column(
                    children: [
                      Icon(Icons.circle, color: Colors.red, size: 12),
                      SizedBox(height: 4),
                      RotatedBox(
                        quarterTurns: 1,
                        child: Text(
                          'REC',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 10,
                            letterSpacing: 2,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Technical Text (Left)
                const Positioned(
                  top: 100,
                  left: 10,
                  child: RotatedBox(
                    quarterTurns: 1,
                    child: Text(
                      '1920 x 1080',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),
                
                 // Technical Text (Left - FULL-HD)
                const Positioned(
                  top: 200,
                  left: 10,
                  child: RotatedBox(
                    quarterTurns: 1,
                    child: Text(
                      'FULL-HD 60FPS',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),

                 // Technical Text (Right - Timecode)
                const Positioned(
                  top: 200,
                  right: 10,
                  child: RotatedBox(
                    quarterTurns: 1,
                    child: Text(
                      '00:00:00:00',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),

                // Center Focus Box (Small)
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white30, width: 1),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // 4. Bottom: Controls removed (handled by Shell)
        // Positioned(
        //   bottom: 20,
        //   left: 0,
        //   right: 0,
        //   child: Row(
        //     mainAxisAlignment: MainAxisAlignment.center,
        //     children: [
        //       // ... buttons ...
        //     ],
        //   ),
        // ),
      ],
    );
  }
}

class _CornerBracket extends StatelessWidget {
  final bool isTop;
  final bool isLeft;

  const _CornerBracket({required this.isTop, required this.isLeft});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        border: Border(
          top: isTop ? const BorderSide(color: Colors.black87, width: 2) : BorderSide.none,
          bottom: !isTop ? const BorderSide(color: Colors.black87, width: 2) : BorderSide.none,
          left: isLeft ? const BorderSide(color: Colors.black87, width: 2) : BorderSide.none,
          right: !isLeft ? const BorderSide(color: Colors.black87, width: 2) : BorderSide.none,
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color iconColor;
  final double size;
  final VoidCallback onTap;

  const _CircleButton({
    required this.icon,
    required this.color,
    required this.iconColor,
    this.size = 48,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: size * 0.5,
        ),
      ),
    );
  }
}
