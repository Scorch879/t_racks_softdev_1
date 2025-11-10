import 'package:flutter/material.dart';

class TeacherPage1 extends StatelessWidget {
  // --- CONTROLLERS & CALLBACKS ---
  // These are passed from the parent OnboardingScreen
  final TextEditingController fullNameController;
  final TextEditingController birthDateController;
  final TextEditingController ageController;
  final TextEditingController institutionController;
  final String? gender; // The currently selected gender (e.g., 'male')
  final ValueChanged<String?> onGenderChanged; // Function to call when gender changes
  final VoidCallback onBirthDateTapped;

  const TeacherPage1({
    super.key,
    required this.fullNameController,
    required this.birthDateController,
    required this.ageController,
    required this.institutionController,
    required this.gender,
    required this.onGenderChanged,
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
    return Column(
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
        Text('Full Name', style: _headerStyle),
        TextField(
          controller: fullNameController,
          decoration: const InputDecoration(
            hintText: 'Ma. Angelica May A. Mantalaba',
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
                      hintText: 'May / 31 / 2005',
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
                      hintText: '20',
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

        // --- GENDER ---
        Text('Gender', style: _headerStyle),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildGenderRadio(context, 'Male', 'male'),
            _buildGenderRadio(context, 'Female', 'female'),
            _buildGenderRadio(context, 'Prefer not to say', 'other'),
          ],
        ),
        const SizedBox(height: 16),

        // --- INSTITUTION (SCHOOL) ---
        Text('Institution (School)', style: _headerStyle),
        TextField(
          controller: institutionController,
          decoration: const InputDecoration(
            hintText: 'Cebu Institute of Technology - University',
            prefixIcon: Icon(Icons.school_outlined, color: Colors.grey),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF21446D)),
            ),
          ),
        ),
      ],
    );
  }

  // Helper widget to build the radio buttons
  Widget _buildGenderRadio(BuildContext context, String title, String value) {
    return Flexible(
      child: RadioListTile<String>(
        title: Text(title, style: const TextStyle(fontSize: 14)),
        value: value,
        groupValue: gender,
        onChanged: onGenderChanged,
        activeColor: const Color(0xFF21446D),
        contentPadding: EdgeInsets.zero,
        dense: true,
      ),
    );
  }
}