import 'package:flutter/material.dart';
import 'package:t_racks_softdev_1/services/models/student_model.dart';

const _bgTeal = Color(0xFF167C94);
const _headerTeal = Color(0xFF1B4A55);
const _textDarkBlue = Color(0xFF1A2B3C);
const _textTeal = Color(0xFF167C94);
const _borderGrey = Color(0xFFBFD5E3);
const _statusRed = Color(0xFFDA6A6A);

class StudentProfileContent extends StatefulWidget {
  const StudentProfileContent({
    super.key,
    required this.student,
    required this.scale,
  });

  final Student student;
  final double scale;

  @override
  State<StudentProfileContent> createState() => _StudentProfileContentState();
}

class _StudentProfileContentState extends State<StudentProfileContent> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _institutionController;

  // Initial values to check for changes
  late String? _initialFirstName;
  late String? _initialLastName;
  late String? _initialEmail;
  late String? _initialInstitution;

  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _initializeControllersAndValues();

    // Add listeners to check for any changes in the text fields
    _firstNameController.addListener(_checkForChanges);
    _lastNameController.addListener(_checkForChanges);
    _emailController.addListener(_checkForChanges);
    _institutionController.addListener(_checkForChanges);
  }

  @override
  void dispose() {
    _firstNameController.removeListener(_checkForChanges);
    _lastNameController.removeListener(_checkForChanges);
    _emailController.removeListener(_checkForChanges);
    _institutionController.removeListener(_checkForChanges);

    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _institutionController.dispose();
    super.dispose();
  }

  void _initializeControllersAndValues() {
    final student = widget.student;
    _initialFirstName = student.profile?.firstName;
    _initialLastName = student.profile?.lastName;
    _initialEmail = student.profile?.email;
    _initialInstitution = student.institution;

    _firstNameController = TextEditingController(text: _initialFirstName);
    _lastNameController = TextEditingController(text: _initialLastName);
    _emailController = TextEditingController(text: _initialEmail);
    _institutionController = TextEditingController(text: _initialInstitution);
  }

  void _checkForChanges() {
    final hasChanges = _firstNameController.text != _initialFirstName ||
        _lastNameController.text != _initialLastName ||
        _emailController.text != _initialEmail ||
        _institutionController.text != _initialInstitution;

    if (hasChanges != _hasChanges) {
      setState(() {
        _hasChanges = hasChanges;
      });
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => const _UnsavedChangesDialog(),
    );

    return shouldPop ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final scale = widget.scale;
    
    // Using PopScope to intercept back button
    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: SingleChildScrollView(
        child: Column(
          children: [
            _ProfileHeader(scale: scale),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24 * scale),
              child: Column(
                children: [
                  SizedBox(height: 10 * scale), // Reduced space for tighter layout
                  Text(
                    widget.student.fullName,
                    style: TextStyle(
                      color: _textDarkBlue,
                      fontSize: 28 * scale,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 8 * scale),
                  Text(
                    '${widget.student.educationalLevel ?? 'Student'} | ${widget.student.gradeYearLevel ?? ''}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _textTeal,
                      fontSize: 14 * scale,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 48 * scale),
                  _ProfileTextField(
                    label: 'First Name',
                    hint: 'Input your first name here',
                    controller: _firstNameController,
                    scale: scale,
                  ),
                  SizedBox(height: 20 * scale),
                  _ProfileTextField(
                    label: 'Last Name',
                    hint: 'Input your last name here',
                    controller: _lastNameController,
                    scale: scale,
                  ),
                  SizedBox(height: 20 * scale),
                  _ProfileTextField(
                    label: 'Email',
                    hint: 'Input your email here',
                    controller: _emailController,
                    scale: scale,
                  ),
                  SizedBox(height: 20 * scale),
                  _ProfileTextField(
                    label: 'Institution',
                    hint: 'Input your institution here',
                    controller: _institutionController,
                    scale: scale,
                  ),
                  SizedBox(height: 40 * scale),
                  SizedBox(
                    width: double.infinity,
                    height: 60 * scale,
                    child: OutlinedButton(
                      onPressed: () {
                        // Save logic would go here
                        setState(() {
                          _hasChanges = false;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Changes Saved')),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: _textTeal),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16 * scale),
                        ),
                        foregroundColor: _textTeal,
                      ),
                      child: Text(
                        'Save Changes',
                        style: TextStyle(
                          fontSize: 20 * scale,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 40 * scale),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 280 * scale,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipPath(
            clipper: _HeaderClipper(),
            child: Container(
              height: 220 * scale,
              color: _bgTeal,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.1,
                      child: Image.asset(
                        'assets/images/squigglytexture.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 60 * scale,
                    left: 24 * scale,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).maybePop(),
                      child: Container(
                        width: 48 * scale,
                        height: 48 * scale,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                          size: 28 * scale,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: 160 * scale,
                height: 160 * scale,
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4 * scale),
                        image: const DecorationImage(
                          image: AssetImage('assets/images/placeholder.png'),
                          fit: BoxFit.cover,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: 4 * scale,
                      right: 4 * scale,
                      child: Container(
                        width: 36 * scale,
                        height: 36 * scale,
                        decoration: BoxDecoration(
                          color: const Color(0xFF93C0D3),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5 * scale),
                        ),
                        child: Icon(
                          Icons.camera_alt_outlined,
                          color: Colors.white,
                          size: 20 * scale,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    // Start slightly higher on the left
    path.lineTo(0, size.height - 50);
    
    // First curve: Convex (Hill) on the left
    final firstControlPoint = Offset(size.width * 0.25, size.height + 10);
    final firstEndPoint = Offset(size.width * 0.5, size.height - 30);
    
    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );
    
    // Second curve: Concave (Scoop) underneath/towards the right
    final secondControlPoint = Offset(size.width * 0.78, size.height - 80);
    final secondEndPoint = Offset(size.width, size.height - 30);
    
    path.quadraticBezierTo(
      secondControlPoint.dx,
      secondControlPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _ProfileTextField extends StatelessWidget {
  const _ProfileTextField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.scale,
    this.maxLines = 1,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final double scale;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: const Color(0xFF1B4A55),
            fontSize: 16 * scale,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 8 * scale),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(
            color: _textDarkBlue,
            fontSize: 16 * scale,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: const Color(0xFF93C0D3),
              fontSize: 16 * scale,
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16 * scale,
              vertical: 20 * scale,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12 * scale),
              borderSide: const BorderSide(color: Color(0xFF93C0D3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12 * scale),
              borderSide: const BorderSide(color: _textTeal, width: 1.5),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _UnsavedChangesDialog extends StatelessWidget {
  const _UnsavedChangesDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Details Unsaved',
              style: TextStyle(
                color: _statusRed,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'You haven’t finished saving your\ndetails.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF1A2B3C),
                fontSize: 16,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false), // Continue editing
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFBFD5E3)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        foregroundColor: const Color(0xFF1A2B3C),
                      ),
                      child: const Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(true), // Leave
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFBFD5E3)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        foregroundColor: const Color(0xFF1A2B3C),
                      ),
                      child: const Text(
                        'Leave',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
