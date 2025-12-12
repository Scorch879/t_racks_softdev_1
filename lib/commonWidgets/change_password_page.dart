import 'package:flutter/material.dart';

class ChangePasswordPage extends StatefulWidget {
  final TextEditingController currentPasswordController;
  final TextEditingController newPasswordController;
  final TextEditingController confirmPasswordController;

  const ChangePasswordPage({
    super.key,
    required this.currentPasswordController,
    required this.newPasswordController,
    required this.confirmPasswordController,
  });

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  bool _currentPassVisible = true;
  bool _newPassVisible = true;
  bool _confirmPassVisible = true;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Set your new password",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF21446D),
            ),
          ),
          const SizedBox(height: 30),

          // --- CURRENT PASSWORD FIELD ---
          const Text(
            "Current Password",
            style: TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextField(
            controller: widget.currentPasswordController,
            obscureText: _currentPassVisible,
            decoration: InputDecoration(
              hintText: "Enter your current password",
              prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
              suffixIcon: IconButton(
                icon: Icon(
                  _currentPassVisible
                      ? Icons.visibility_off
                      : Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _currentPassVisible = !_currentPassVisible;
                  });
                },
              ),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF21446D)),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // --- NEW PASSWORD FIELD ---
          const Text(
            "New Password",
            style: TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextField(
            controller: widget.newPasswordController,
            obscureText: _newPassVisible,
            decoration: InputDecoration(
              hintText: "Enter your new password",
              prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
              suffixIcon: IconButton(
                icon: Icon(
                  _newPassVisible ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _newPassVisible = !_newPassVisible;
                  });
                },
              ),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF21446D)),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // --- CONFIRM NEW PASSWORD FIELD ---
          const Text(
            "Confirm New Password",
            style: TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextField(
            controller: widget.confirmPasswordController,
            obscureText: _confirmPassVisible,
            decoration: InputDecoration(
              hintText: "Confirm your new password",
              prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
              suffixIcon: IconButton(
                icon: Icon(
                  _confirmPassVisible
                      ? Icons.visibility_off
                      : Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _confirmPassVisible = !_confirmPassVisible;
                  });
                },
              ),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF21446D)),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
