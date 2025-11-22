import 'package:flutter/material.dart';
import 'package:t_racks_softdev_1/screens/educator/educator_background.dart';

// Content-only widget for use in EducatorShell
class EducatorSettingsContent extends StatelessWidget {
  const EducatorSettingsContent({super.key});

  @override
  Widget build(BuildContext context) {
    return EducatorBackground(
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildSettingsCard(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0F3951).withOpacity(0.85),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.settings, color: Color(0xFF93C0D3)),
              SizedBox(width: 8),
              Text(
                'Settings',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSettingsButton(
            label: 'Profile Settings',
            color: const Color(0xFF4CAF50),
            icon: Icons.person,
            onPressed: () {},
          ),
          const SizedBox(height: 12),
          _buildSettingsButton(
            label: 'Account Settings',
            color: const Color(0xFF4CAF50),
            icon: Icons.settings,
            onPressed: () {},
          ),
          const SizedBox(height: 12),
          _buildSettingsButton(
            label: 'Delete Account',
            color: const Color(0xFFE53935),
            icon: Icons.person_remove,
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsButton({
    required String label,
    required Color color,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        elevation: 4,
      ),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 16),
        ],
      ),
    );
  }

}

