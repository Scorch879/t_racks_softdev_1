import 'package:flutter/material.dart';

class ForgotPage3 extends StatefulWidget {
  final TextEditingController passController;
  final TextEditingController confirmController;

  const ForgotPage3({
    super.key,
    required this.passController,
    required this.confirmController,
  });

  @override
  State<ForgotPage3> createState() => _ForgotPage3State();
}

class _ForgotPage3State extends State<ForgotPage3> {
  // Local state variables for the "Eye" icons
  bool _passVisible = true;
  bool _confirmVisible = true;

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

          // --- PASSWORD FIELD ---
          const Text(
            "Password",
            style: TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextField(
            controller:
                widget.passController, // Use widget. to access parent vars
            obscureText: _passVisible, // Use local state
            decoration: InputDecoration(
              hintText: "Enter your password",
              prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
              // The Toggle Button
              suffixIcon: IconButton(
                icon: Icon(
                  _passVisible ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _passVisible = !_passVisible;
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

          // --- CONFIRM PASSWORD FIELD ---
          const Text(
            "Confirm Password",
            style: TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextField(
            controller: widget.confirmController,
            obscureText: _confirmVisible,
            decoration: InputDecoration(
              hintText: "Confirm your password",
              prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
              suffixIcon: IconButton(
                icon: Icon(
                  _confirmVisible ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _confirmVisible = !_confirmVisible;
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
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                // Go back to the Login Screen
                Navigator.pop(context);
              },
              // Removes default padding so it aligns perfectly to the right
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Log In?',
                style: TextStyle(
                  color: Color(0xFF26A69A), // Your Green/teal theme color
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
