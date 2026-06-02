import 'package:flutter/material.dart';

class DeleteAccountConfirmationDialog extends StatelessWidget {
  const DeleteAccountConfirmationDialog({super.key, required this.onConfirm});

  final VoidCallback onConfirm;

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
            const Text(
              'Delete Profile',
              style: TextStyle(
                color: Color(0xFFE53935), // Red color
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Are you sure you want to delete your Profile? This action is irreversible.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: primaryTextColor,
                fontSize: 16,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () =>
                          Navigator.of(context).pop(false), // Return false
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: borderColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        foregroundColor: primaryTextColor,
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: onConfirm,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(
                          0xFFE53935,
                        ), // Red background
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        foregroundColor: Colors.white, // White text
                      ),
                      child: const Text(
                        'Delete',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
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

Future<bool> showDeleteAccountConfirmationDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext) {
      return DeleteAccountConfirmationDialog(
        onConfirm: () {
          Navigator.of(dialogContext).pop(true); // Return true
        },
      );
    },
  );
  return result ?? false;
}
