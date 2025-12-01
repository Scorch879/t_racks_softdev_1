import 'package:flutter/material.dart';
import 'package:t_racks_softdev_1/screens/student/student_class_screen.dart';

class StudentShellCamvoiceScreen extends StatefulWidget {
  final Widget child;

  const StudentShellCamvoiceScreen({super.key, required this.child});

  @override
  State<StudentShellCamvoiceScreen> createState() =>
      _StudentShellCamvoiceScreenState();
}

class _StudentShellCamvoiceScreenState extends State<StudentShellCamvoiceScreen>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Important for the FAB docking effect
      body: Stack(
        children: [
          widget.child,

          // Dim background when expanded (optional, but good for focus)
          if (_isExpanded)
            Positioned.fill(
              child: GestureDetector(
                onTap: _toggleMenu,
                child: Container(
                  color: Colors.black.withOpacity(0.3),
                ),
              ),
            ),

          // Expanded Button (Close/Exit)
          if (_isExpanded)
            Positioned(
              bottom: 150, // Positioned above the FAB
              left: 0,
              right: 0,
              child: Center(
                child: ScaleTransition(
                  scale: _expandAnimation,
                  child: _CircleButton(
                    icon: Icons.close,
                    color: const Color(0xFFDA6A6A), // Red
                    iconColor: Colors.white,
                    size: 60,
                    onTap: () {
                      Navigator.of(context).pop(); // Exit the screen
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: SizedBox(
        width: 80,
        height: 80,
        child: FloatingActionButton(
          onPressed: _toggleMenu,
          backgroundColor: const Color(0xFF93C0D3), // Light Blue
          elevation: 4,
          shape: const CircleBorder(),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(
                Icons.person_outline_rounded,
                size: 40,
                color: Color(0xFF173C45),
              ),
              Positioned(
                top: 12,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Color(0xFF93C0D3), // Match bg to hide line
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.schedule,
                    size: 18,
                    color: Color(0xFF173C45),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 12.0,
        color: Colors.white,
        elevation: 10,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Left Side - Home
              IconButton(
                icon: const Icon(Icons.home_outlined, size: 32),
                color: Colors.black87,
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              ),

              // Spacer for FAB
              const SizedBox(width: 60),

              // Right Side - Calendar
              IconButton(
                icon: const Icon(Icons.calendar_today_outlined, size: 28),
                color: Colors.black87,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const StudentClassScreen(
                        initialTab: ClassNavTab.schedule,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
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
