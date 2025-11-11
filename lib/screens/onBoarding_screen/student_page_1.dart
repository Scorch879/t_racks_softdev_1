import 'package:flutter/material.dart';

class StudentPage1 extends StatelessWidget {
  //  CONTROLLERS & CALLBACKS 
  // These are passed from the parent OnboardingScreen
  final TextEditingController lastNameController;
  final TextEditingController firstNameController;
  final TextEditingController middleNameController;
  final TextEditingController birthDateController;
  final TextEditingController ageController;
  final String? gender; 
  final ValueChanged<String?> onGenderChanged; 
  final VoidCallback onBirthDateTapped;
  const StudentPage1({
    super.key,
    required this.lastNameController,
    required this.firstNameController,
    required this.middleNameController,
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
          const SizedBox(height: 20),

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
          const SizedBox(height: 20),
          // --- GENDER ---
          Text('Gender', style: _headerStyle),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildGenderRadio(context, 'Male', 'male'),
              _buildGenderRadio(context, 'Female', 'female'),
              _buildGenderRadio(context, 'Prefer not to say', 'prefer_not_to_say'),
            ],
          ),
          const SizedBox(height: 14), 

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