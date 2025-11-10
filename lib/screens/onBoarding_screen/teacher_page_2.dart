import 'package:flutter/material.dart';

class TeacherPage2 extends StatelessWidget {
  final TextEditingController institutionController;
  final String? gender; // The currently selected gender (e.g., 'male')
  final ValueChanged<String?> onGenderChanged;

  const TeacherPage2({
    super.key,
    required this.institutionController,
    required this.gender,
    required this.onGenderChanged,
  });

  final TextStyle _headerStyle = const TextStyle(
    color: Colors.black54,
    fontWeight: FontWeight.w600,
    fontSize: 16,
  );
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "User Onboarding",
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.bold,
            color: Color(0xFF21446D),
          ),
        ),
        const SizedBox(height: 5),
        Container(height: 5, width: 80, color: const Color(0xFF21446D)),
        const SizedBox(height: 12),
        const Text(
          "Welcome! Please complete your profile so we can personalize your experience.",
          style: TextStyle(fontSize: 16, color: Colors.black54),
        ),
        const SizedBox(height: 24),

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
