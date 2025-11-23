import 'package:flutter/material.dart';

class ForgotPage1 extends StatelessWidget {
  // We accept the controller and function from the parent
  final TextEditingController emailController;

  const ForgotPage1({super.key, required this.emailController});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Forgot Your Password?",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF21446D),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Enter your Email address to get the confirmation code",
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 30),

          const Text(
            "Email",
            style: TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              hintText: "demo@email.com",
              prefixIcon: Icon(Icons.email_outlined, color: Colors.grey),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey),
              ),
              focusedBorder: UnderlineInputBorder(
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
