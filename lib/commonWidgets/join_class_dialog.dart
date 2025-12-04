import 'package:flutter/material.dart';
import 'package:t_racks_softdev_1/commonWidgets/show_snackbar.dart';
import 'package:t_racks_softdev_1/services/database_service.dart';

// App-specific colors for Light Theme
const _lightBackground = Colors.white;
const _inputFill = Color(0xFFF1F5F9); // Light grey for input fields
const _textBlack = Colors.black;
const _textGrey = Color(0xFF64748B); // Slate grey for secondary text/icons
const _chipGreen = Color(0xFF3AB389); // The requested green

/// Shows a dialog for the student to enter a class code and join a class.
void showJoinClassDialog(BuildContext context, VoidCallback onClassJoined) {
  showDialog(
    context: context,
    barrierDismissible: false, // Force use of X button or Cancel
    builder: (BuildContext dialogContext) {
      return _JoinClassDialogContent(onClassJoined: onClassJoined);
    },
  );
}

class _JoinClassDialogContent extends StatefulWidget {
  final VoidCallback onClassJoined;
  const _JoinClassDialogContent({required this.onClassJoined});

  @override
  State<_JoinClassDialogContent> createState() =>
      _JoinClassDialogContentState();
}

class _JoinClassDialogContentState extends State<_JoinClassDialogContent> {
  final _classCodeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _focusNode = FocusNode();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Request focus after the dialog animation completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _classCodeController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      try {
        await DatabaseService().enrollInClassWithCode(
          _classCodeController.text,
        );

        if (mounted) {
          Navigator.of(context).pop();
          showCustomSnackBar(
            context,
            'Successfully joined class!',
            isError: false,
          );
        }
        widget.onClassJoined();
      } catch (e) {
        if (mounted) {
          showCustomSnackBar(context, e.toString());
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _lightBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Wrap content height
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header Row (Title + Close Icon)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Join a Class',
                  style: TextStyle(
                    color: _textBlack, // Black text
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: _textGrey),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 20,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 2. Form Content
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Label outside the box (matches image style)
                  const Text(
                    'Class Code',
                    style: TextStyle(
                      color: _textBlack, // Black text
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Input Field
                  TextFormField(
                    controller: _classCodeController,
                    focusNode: _focusNode,
                    style: const TextStyle(
                      color: _textBlack,
                    ), // Black text input
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: 'Enter 6-digit code',
                      hintStyle: TextStyle(
                        color: _textBlack.withOpacity(0.4),
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: _inputFill, // Light background
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      // Rounded borders matching image
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.black.withOpacity(0.05),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: _chipGreen,
                          width: 1.5,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE26B6B)),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFE26B6B),
                          width: 1.5,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().length != 6) {
                        return 'Please enter a valid 6-digit code.';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 3. Full Width Action Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _chipGreen,
                  foregroundColor:
                      Colors.white, // Keep button text white like the image
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Join Class',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
