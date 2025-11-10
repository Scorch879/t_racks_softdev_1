import 'package:flutter/material.dart';

class StudentPage1 extends StatelessWidget {
  // --- CONTROLLERS & CALLBACKS ---
  // These are passed from the parent OnboardingScreen
  final TextEditingController fullNameController;
  final TextEditingController birthDateController;
  final TextEditingController ageController;
  final String? gender; // The currently selected gender (e.g., 'male')
  final ValueChanged<String?> onGenderChanged; // Function to call when gender changes
  final VoidCallback onBirthDateTapped;
  const StudentPage1({
    super.key,
    required this.fullNameController,
    required this.birthDateController,
    required this.ageController,
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
    // Use SingleChildScrollView to prevent overflow when keyboard appears
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
          Text('Full Name', style: _headerStyle),
          TextField(
            controller: fullNameController,
            decoration: const InputDecoration(
              hintText: 'Full name',
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

          // --- GENDER ---
          Text('Gender', style: _headerStyle),
          // We use RadioListTile for a better tap target
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildGenderRadio(context, 'Male', 'male'),
              _buildGenderRadio(context, 'Female', 'female'),
              _buildGenderRadio(context, 'Prefer not to say', 'other'),
            ],
          ),
          const SizedBox(height: 24),

          // --- BIRTH DATE & AGE ---
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Birth Date
              Expanded(
                flex: 2, // Give Birth Date more space
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Birth date', style: _headerStyle),
                    TextField(
                      controller: birthDateController,
                      // We'd add a date picker to this
                      readOnly: true, // Make it read-only
                      onTap: onBirthDateTapped,
                      decoration: const InputDecoration(
                        hintText: 'month / day / year',
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
                flex: 1, // Give Age less space
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Age', style: _headerStyle),
                    TextField(
                      controller: ageController,
                      readOnly: true, // Age is calculated, not typed
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
        ],
      ),
    );
  }

  // Helper widget to build the radio buttons
  Widget _buildGenderRadio(BuildContext context, String title, String value) {
    return Flexible(
      child: RadioListTile<String>(
        title: Text(title, style: const TextStyle(fontSize: 14)),
        value: value,
        groupValue: gender, // This is the state variable
        onChanged: onGenderChanged, // This calls the function in the parent
        activeColor: const Color(0xFF21446D),
        contentPadding: EdgeInsets.zero,
        dense: true,
      ),
    );
  }
}