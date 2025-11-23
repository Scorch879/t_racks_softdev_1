import 'package:flutter/material.dart';

class StudentPage2 extends StatelessWidget {
  // --- CONTROLLERS & CALLBACKS ---
  final TextEditingController institutionController;
  final TextEditingController programController;

  final String? educationalLevel; // 'primary', 'secondary', or 'tertiary'
  final String? gradeYearLevel;     // The selected grade or year
  
  final ValueChanged<String?> onEducationalLevelChanged;
  final ValueChanged<String?> onGradeYearLevelChanged;

  const StudentPage2({
    super.key,
    required this.institutionController,
    required this.programController,
    required this.educationalLevel,
    required this.gradeYearLevel,
    required this.onEducationalLevelChanged,
    required this.onGradeYearLevelChanged,
  });
  // ---------------------------------

  // Helper for styling the section headers
  final TextStyle _headerStyle = const TextStyle(
    color: Colors.black54,
    fontWeight: FontWeight.w600,
    fontSize: 16,
  );

  // --- THIS IS THE DYNAMIC LOGIC ---
  List<String> _getGradeLevelOptions() {
    switch (educationalLevel) {
      case 'primary':
        return List.generate(6, (index) => 'Grade ${index + 1}'); // Grade 1-6
      case 'secondary':
        return List.generate(6, (index) => 'Grade ${index + 7}'); // Grade 7-12
      case 'tertiary':
        return [
          '1st Year',
          '2nd Year',
          '3rd Year',
          '4th Year',
          '5th Year',
        ]; // 1st-5th Year
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the correct list of options
    final gradeLevelOptions = _getGradeLevelOptions();
    // Check if the current value is valid for this list
    final bool isGradeLevelValid = gradeLevelOptions.contains(gradeYearLevel);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- HEADER (Same as Page 1) ---
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
          const SizedBox(height: 20),

          // --- INSTITUTION (SCHOOL) ---
          Text('Institution (School)', style: _headerStyle),
          TextField(
            controller: institutionController,
            textAlignVertical: TextAlignVertical.center,
            decoration: const InputDecoration(
              isDense: true,
              hintText: 'Cebu Institute of Technology - University',
              hintStyle: TextStyle(color: Color.fromARGB(255, 207, 207, 207)),
              prefixIcon: Icon(Icons.school_outlined, color: Colors.grey),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF21446D)),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // --- EDUCATIONAL LEVEL ---
          Text('Educational Level', style: _headerStyle),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildEduRadio(context, 'primary', 'primary'),
              _buildEduRadio(context, 'secondary', 'secondary'),
              _buildEduRadio(context, 'tertiary', 'tertiary'),
            ],
          ),
          const SizedBox(height: 16),

          Text('Grade/Year Level', style: _headerStyle),
          DropdownButtonFormField<String>(
            value: isGradeLevelValid ? gradeYearLevel : null, // Show selected value
            hint: const Text('Select Level'),
            decoration: const InputDecoration(
              hintStyle: TextStyle(color: Color.fromARGB(255, 207, 207, 207)),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF21446D)),
              ),
            ),
            items: gradeLevelOptions.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: onGradeYearLevelChanged, // Calls parent function
          ),
          const SizedBox(height: 20),

          // --- PROGRAM (Conditional) ---
          if (educationalLevel == 'tertiary')
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Program', style: _headerStyle),
                TextField(
                  controller: programController,
                  decoration: const InputDecoration(
                    hintText: 'Program',
                    hintStyle: TextStyle(color: Color.fromARGB(255, 207, 207, 207)),
                    prefixIcon: Icon(Icons.menu_book_outlined, color: Colors.grey),
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
        ],
      ),
    );
  }

  // Helper widget to build the radio buttons
  Widget _buildEduRadio(BuildContext context, String title, String value) {
    return Flexible(
      child: RadioListTile<String>(
        title: Text(title, style: const TextStyle(fontSize: 14)),
        value: value,
        groupValue: educationalLevel, // This is the state variable
        onChanged: onEducationalLevelChanged, // This calls the function in the parent
        activeColor: const Color(0xFF21446D),
        contentPadding: EdgeInsets.zero,
        dense: true,
      ),
    );
  }
}