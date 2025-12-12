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
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Account Settings',
              style: TextStyle(
                color: Color(0xFF1A2B3C), // Dark blueish color
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'What would you like to do?',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF1A2B3C),
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
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => const ChangePasswordScreen()));
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFBFD5E3)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      foregroundColor: const Color(0xFF1A2B3C),
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
