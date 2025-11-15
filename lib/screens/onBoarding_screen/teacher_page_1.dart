import 'package:flutter/material.dart';

class TeacherPage1 extends StatelessWidget {
  // --- CONTROLLERS & CALLBACKS ---
  // These are passed from the parent OnboardingScreen
  final TextEditingController lastNameController;
  final TextEditingController firstNameController;
  final TextEditingController middleNameController;
  final TextEditingController birthDateController;
  final TextEditingController ageController;
  final VoidCallback onBirthDateTapped;

  const TeacherPage1({
    super.key,
    required this.lastNameController,
    required this.firstNameController,
    required this.middleNameController,
    required this.birthDateController,
    required this.ageController,
    required this.onBirthDateTapped,
  });
  // ---------------------------------

  // Helper for styling the section headers
  final TextStyle _headerStyle = const TextStyle(
    color: Colors.black54,
    fontWeight: FontWeight.w600,
    fontSize: 16,
  );

  @override
  Widget build(BuildContext context) {
    // You're right, this will overflow.
    // The fix will be to wrap this Column in a SingleChildScrollView.
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- HEADER ---
          const Text(
            "User Onboarding",
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.bold,
              color: Color(0xFF21446D),
            ),
          ),
          const SizedBox(height: 5),
          Container(
            height: 5,
            width: 80,
            color: const Color(0xFF21446D),
          ),
          const SizedBox(height: 12),
          const Text(
            "Welcome! Please complete your profile so we can personalize your experience.",
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
          const SizedBox(height: 24),
      
          // --- FULL NAME ---
          Text('Last Name', style: _headerStyle),
            TextField(
              controller: lastNameController,
              decoration: const InputDecoration(
                hintText: 'Last Name',
                prefixIcon: Icon(Icons.person_outline, color: Colors.grey),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF21446D)),
                ),
              ),
            ),
            const SizedBox(height: 24),
      
            // --- FIRST & MIDDLE NAME ---
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // First Name
                Expanded(
                  flex: 2, // Give First Name more space
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('First Name', style: _headerStyle),
                      TextField(
                        controller: firstNameController,
                        decoration: const InputDecoration(
                          hintText: 'First Name',
                          prefixIcon: Icon(Icons.person_outline, color: Colors.grey),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF21446D)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                // Middle Name
                Expanded(
                  flex: 1, // Give M.I. less space
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Middle Name', style: _headerStyle),
                      TextField(
                        controller: middleNameController,
                        decoration: const InputDecoration(
                          hintText: 'M.I',
                          prefixIcon: Icon(Icons.person_outline, color: Colors.grey),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF21446D)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          const SizedBox(height: 24),
      
          // --- BIRTH DATE & AGE ---
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Birth Date
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Birth date', style: _headerStyle),
                    TextField(
                      controller: birthDateController,
                      readOnly: true,
                      onTap: onBirthDateTapped,
                      decoration: const InputDecoration(
                        hintText: 'Month/Day/Year',
                        prefixIcon: Icon(Icons.calendar_today_outlined, color: Colors.grey),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF21446D)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              // Age
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Age', style: _headerStyle),
                    TextField(
                      controller: ageController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        hintText: 'Age',
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF21446D)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

}