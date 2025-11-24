import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ForgotPage2 extends StatelessWidget {
  // We receive the list of  controllers from the parent
  final List<TextEditingController> otpControllers;

  const ForgotPage2({super.key, required this.otpControllers});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- HEADER ---
          const Text(
            "Enter Your Code",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF21446D),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Enter the code you got in your email address",
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 30),

          // --- 5 OTP BOXES ROW ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (index) {
              return SizedBox(
                width: 50,
                height: 60,
                child: TextField(
                  controller: otpControllers[index],
                  autofocus: index == 0, // Auto-focus the first box on load
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  maxLength: 1, // Only allow 1 digit
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF21446D),
                  ),
                  decoration: InputDecoration(
                    counterText: "", // Hides the "0/1" character counter
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none, // No border lines
                    ),
                  ),
                  onChanged: (value) {
                    // Logic to move focus automatically
                    if (value.length == 1 && index < otpControllers.length - 1) {
                      // If they typed a number, go to NEXT box
                      FocusScope.of(context).nextFocus();
                    } else if (value.isEmpty && index > 0) {
                      // If they deleted a number, go to PREVIOUS box
                      FocusScope.of(context).previousFocus();
                    }
                  },
                ),
              );
            }),
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
