import 'package:flutter/material.dart';
import 'package:t_racks_softdev_1/commonWidgets/commonwidgets.dart';
import 'package:t_racks_softdev_1/services/database_service.dart';
import 'package:t_racks_softdev_1/services/auth_service.dart';
import 'package:t_racks_softdev_1/commonWidgets/change_password_screen.dart';

void showAccountSettingsDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return const AccountSettingsDialog();
    },
  );
}

class AccountSettingsDialog extends StatelessWidget {
  const AccountSettingsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final dialogColor = isDarkMode ? const Color(0xFF0C3343) : Colors.white;
    final primaryTextColor = isDarkMode
        ? Colors.white
        : const Color(0xFF1A2B3C);
    final borderColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.18)
        : const Color(0xFFBFD5E3);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: dialogColor,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Account Settings',
              style: TextStyle(
                color: primaryTextColor,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'What would you like to do?',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: primaryTextColor,
                fontSize: 16,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 32),
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ChangePasswordScreen(),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: borderColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      foregroundColor: primaryTextColor,
                    ),
                    child: const Text(
                      'Change Password',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () async {
                      final confirmed =
                          await showDeleteAccountConfirmationDialog(context);
                      if (confirmed) {
                        try {
                          // Note: This only deletes the profile from the database, not the auth user.
                          // A Supabase Edge Function is required to delete the auth user.
                          await AccountServices().deleteProfile();
                          await AuthService().logoutAndNavigateToLogin(context);
                          showCustomSnackBar(
                            context,
                            'Profile deleted successfully.',
                          );
                        } catch (e) {
                          showCustomSnackBar(
                            context,
                            'Error deleting profile: $e',
                          );
                        }
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: Color(0xFFE53935),
                      ), // Red border
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      foregroundColor: const Color(0xFFE53935), // Red text
                    ),
                    child: const Text(
                      'Delete Profile',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
