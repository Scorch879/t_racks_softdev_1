import 'package:flutter/material.dart';
import 'package:t_racks_softdev_1/commonWidgets/show_snackbar.dart';
import 'package:t_racks_softdev_1/services/database_service.dart';

// App-specific colors to match the theme
const _darkBluePanel = Color(0xFF0C3343);
const _accentCyan = Color(0xFF32657D);
const _chipGreen = Color(0xFF37AA82);

/// Shows a dialog for the student to enter a class code and join a class.
///
/// [context]: The BuildContext from which to show the dialog.
/// [onClassJoined]: A callback function that is executed on successful enrollment,
///                  typically used to refresh the class list.
void showJoinClassDialog(BuildContext context, VoidCallback onClassJoined) {
  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      // By using a dedicated StatefulWidget, we can manage focus and state cleanly.
      return _JoinClassDialogContent(onClassJoined: onClassJoined);
    },
  );
}

class _JoinClassDialogContent extends StatefulWidget {
  final VoidCallback onClassJoined;
  const _JoinClassDialogContent({required this.onClassJoined});

  @override
  State<_JoinClassDialogContent> createState() => _JoinClassDialogContentState();
}

class _JoinClassDialogContentState extends State<_JoinClassDialogContent> {
  final _classCodeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _focusNode = FocusNode();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // This is the key to the performance fix.
    // We wait until after the dialog's entry animation is complete,
    // then we request focus to bring up the keyboard smoothly.
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
        await DatabaseService().enrollInClassWithCode(_classCodeController.text);

        if (mounted) {
          Navigator.of(context).pop();
          showCustomSnackBar(context, 'Successfully joined class!', isError: false);
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
    return AlertDialog(
      backgroundColor: _darkBluePanel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: _accentCyan.withOpacity(0.5)),
      ),
      title: const Text(
        'Join a Class',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _classCodeController,
          focusNode: _focusNode, // Assign the focus node
          // autofocus: true, // REMOVED to prevent animation clash
          style: const TextStyle(color: Colors.white),
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            labelText: 'Class Code',
            labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
            hintText: 'Enter 6-digit code',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _accentCyan.withOpacity(0.7)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _chipGreen, width: 2),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().length != 6) {
              return 'Please enter a valid 6-digit code.';
            }
            return null;
          },
        ),
      ),
      actions: <Widget>[
        TextButton(
          style: TextButton.styleFrom(foregroundColor: Colors.white70),
          child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _chipGreen,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Join', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}