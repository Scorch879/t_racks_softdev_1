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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDarkMode
        ? Colors.white
        : const Color(0xFF21446D);
    final secondaryTextColor = isDarkMode ? Colors.white70 : Colors.black54;
    final inputTextColor = isDarkMode ? Colors.white : Colors.black87;
    final borderColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.28)
        : Colors.grey;
    final focusedBorderColor = isDarkMode
        ? const Color(0xFF93C0D3)
        : const Color(0xFF21446D);
    final iconColor = isDarkMode ? Colors.white70 : Colors.grey;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Set your new password",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: primaryTextColor,
            ),
          ),
          const SizedBox(height: 30),

          // --- CURRENT PASSWORD FIELD ---
          Text(
            "Current Password",
            style: TextStyle(
              color: secondaryTextColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextField(
            controller: widget.currentPasswordController,
            obscureText: _currentPassVisible,
            style: TextStyle(color: inputTextColor),
            decoration: InputDecoration(
              hintText: "Enter your current password",
              hintStyle: TextStyle(color: secondaryTextColor),
              prefixIcon: Icon(Icons.lock_outline, color: iconColor),
              suffixIcon: IconButton(
                icon: Icon(
                  _currentPassVisible ? Icons.visibility_off : Icons.visibility,
                  color: iconColor,
                ),
                onPressed: () {
                  setState(() {
                    _currentPassVisible = !_currentPassVisible;
                  });
                },
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: focusedBorderColor),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // --- NEW PASSWORD FIELD ---
          Text(
            "New Password",
            style: TextStyle(
              color: secondaryTextColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextField(
            controller: widget.newPasswordController,
            obscureText: _newPassVisible,
            style: TextStyle(color: inputTextColor),
            decoration: InputDecoration(
              hintText: "Enter your new password",
              hintStyle: TextStyle(color: secondaryTextColor),
              prefixIcon: Icon(Icons.lock_outline, color: iconColor),
              suffixIcon: IconButton(
                icon: Icon(
                  _newPassVisible ? Icons.visibility_off : Icons.visibility,
                  color: iconColor,
                ),
                onPressed: () {
                  setState(() {
                    _newPassVisible = !_newPassVisible;
                  });
                },
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: focusedBorderColor),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // --- CONFIRM NEW PASSWORD FIELD ---
          Text(
            "Confirm New Password",
            style: TextStyle(
              color: secondaryTextColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextField(
            controller: widget.confirmPasswordController,
            obscureText: _confirmPassVisible,
            style: TextStyle(color: inputTextColor),
            decoration: InputDecoration(
              hintText: "Confirm your new password",
              hintStyle: TextStyle(color: secondaryTextColor),
              prefixIcon: Icon(Icons.lock_outline, color: iconColor),
              suffixIcon: IconButton(
                icon: Icon(
                  _confirmPassVisible ? Icons.visibility_off : Icons.visibility,
                  color: iconColor,
                ),
                onPressed: () {
                  setState(() {
                    _confirmPassVisible = !_confirmPassVisible;
                  });
                },
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: focusedBorderColor),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
