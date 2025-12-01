import 'package:flutter/material.dart';

class StudentShellCamvoiceScreen extends StatelessWidget {
  final Widget child;

  const StudentShellCamvoiceScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Important for the FAB docking effect
      body: child,
      floatingActionButton: SizedBox(
        width: 70, // Slightly larger than standard
        height: 70,
        child: FloatingActionButton(
          onPressed: () => _showAttendanceOptions(context),
          backgroundColor: const Color(0xFF4DD0E1), // Teal/Light Blue
          elevation: 4,
          shape: const CircleBorder(),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(
                Icons.person,
                size: 32,
                color: Colors.white,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.access_time_filled,
                    size: 14,
                    color: Color(0xFF167C94),
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
        notchMargin: 8.0,
        color: Colors.white,
        elevation: 10,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Left Side - Home
              IconButton(
                icon: const Icon(Icons.home_rounded, size: 30),
                color: const Color(0xFF167C94), // Active color
                onPressed: () {
                  // Navigate back to Home if needed, or just pop
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              ),
              
              // Spacer for FAB
              const SizedBox(width: 48),

              // Right Side - Calendar
              IconButton(
                icon: const Icon(Icons.calendar_month_rounded, size: 30),
                color: Colors.grey, // Inactive color
                onPressed: () {
                  // Placeholder for Calendar navigation
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAttendanceOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Attendance Options',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF173C45),
              ),
            ),
            const SizedBox(height: 20),
            _AttendanceOptionTile(
              icon: Icons.qr_code_scanner,
              title: 'Scan QR Code',
              onTap: () => Navigator.pop(context),
            ),
            _AttendanceOptionTile(
              icon: Icons.face,
              title: 'Face Recognition',
              onTap: () => Navigator.pop(context),
            ),
            _AttendanceOptionTile(
              icon: Icons.pin,
              title: 'Enter PIN',
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _AttendanceOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _AttendanceOptionTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFE0F7FA),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF006064)),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: onTap,
    );
  }
}
