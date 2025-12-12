import 'package:flutter/material.dart';
import 'package:t_racks_softdev_1/commonWidgets/bottom_wave_clipper.dart';
import 'package:t_racks_softdev_1/commonWidgets/show_snackbar.dart';
import 'package:t_racks_softdev_1/commonWidgets/change_password_page.dart';
import 'package:t_racks_softdev_1/services/auth_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  _ChangePasswordScreenState createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _changePassword() async {
    setState(() {
      _isLoading = true;
    });

    final newPassword = _newPasswordController.text;
    if (_currentPasswordController.text.isEmpty) {
      showCustomSnackBar(context, "Please enter your current password");
      setState(() => _isLoading = false);
      return;
    }

    if (newPassword.isEmpty || newPassword.length < 8) {
      showCustomSnackBar(context, "Passwords must be at least 8 characters");
      setState(() => _isLoading = false);
      return;
    }
    if (newPassword != _confirmPasswordController.text) {
      showCustomSnackBar(context, "Passwords do not match");
      setState(() => _isLoading = false);
      return;
    }
    if (!RegExp(r'[A-Z]').hasMatch(newPassword)) {
      showCustomSnackBar(
          context, "Password must contain at least one uppercase letter.");
      setState(() => _isLoading = false);
      return;
    }
    if (!RegExp(r'[0-9]').hasMatch(newPassword)) {
      showCustomSnackBar(context, "Password must contain at least one number.");
      setState(() => _isLoading = false);
      return;
    }

    try {
      final email = _authService.getCurrentUserEmail();
      if (email == null) {
        showCustomSnackBar(context, "Error: Could not find user email.");
        setState(() => _isLoading = false);
        return;
      }

      await _authService.logIn(
        email: email,
        password: _currentPasswordController.text,
      );

      await _authService.updateUserPassword(
        newPassword: _newPasswordController.text,
      );

      if (mounted) {
        showCustomSnackBar(
          context,
          "Password updated successfully",
          isError: false,
        );
        Navigator.pop(context); // Go back to the previous screen
      }
    } catch (e) {
      if (mounted) {
        if (e.toString().contains('Invalid login credentials')) {
          showCustomSnackBar(
            context,
            'Incorrect current password. Please try again.',
          );
        } else {
          showCustomSnackBar(context, "Error: ${e.toString()}");
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(color: Colors.white),
          Column(
            children: [
              Expanded(
                flex: 4,
                child: ClipPath(
                  clipper: BottomWaveClipper(),
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF194B61),
                          Color(0xFF2A7FA3),
                          Color(0xFF267394),
                          Color(0xFF349BC7),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Image.asset(
                      'assets/images/squigglytexture.png',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 7,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30.0),
                  child: Column(
                    children: [
                      Expanded(
                          child: ChangePasswordPage(
                        currentPasswordController: _currentPasswordController,
                        newPasswordController: _newPasswordController,
                        confirmPasswordController: _confirmPasswordController,
                      )),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _changePassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF26A69A),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  'Change Password',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
