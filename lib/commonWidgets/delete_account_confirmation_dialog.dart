import 'package:flutter/material.dart';

class DeleteAccountConfirmationDialog extends StatelessWidget {
  const DeleteAccountConfirmationDialog({super.key, required this.onConfirm});

  final VoidCallback onConfirm;

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
              'Delete Profile',
              style: TextStyle(
                color: Color(0xFFE53935), // Red color
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Are you sure you want to delete your Profile? This action is irreversible.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF1A2B3C),
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
                        side: const BorderSide(color: Color(0xFFBFD5E3)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        foregroundColor: const Color(0xFF1A2B3C),
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
