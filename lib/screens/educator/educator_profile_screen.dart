import 'package:flutter/material.dart';
import 'package:t_racks_softdev_1/services/database_service.dart';

// Educator Theme Colors
const _bgDarkBlue = Color(0xFF0F3951);
const _textCyan = Color(0xFF93C0D3);
const _textDarkBlue = Color(0xFF1A2B3C);
const _borderGrey = Color(0xFFBFD5E3);
const _statusRed = Color(0xFFDA6A6A);

class EducatorProfileScreen extends StatefulWidget {
  const EducatorProfileScreen({super.key});

  @override
  State<EducatorProfileScreen> createState() => _EducatorProfileScreenState();
}

class _EducatorProfileScreenState extends State<EducatorProfileScreen> {
  final DatabaseService _databaseService = DatabaseService();

  // Logic State
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _bioController;

  String _initialFirstName = '';
  String _initialLastName = '';
  String _initialBio = '';
  
  bool _hasChanges = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _bioController = TextEditingController();

    _firstNameController.addListener(_checkForChanges);
    _lastNameController.addListener(_checkForChanges);
    _bioController.addListener(_checkForChanges);

    _loadData();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final educator = await _databaseService.getEducatorData();

      if (mounted && educator != null) {
        _initialFirstName = educator.profile.firstName;
        _initialLastName = educator.profile.lastName;
        _initialBio = educator.bio; 
        
        _firstNameController.text = _initialFirstName;
        _lastNameController.text = _initialLastName;
        _bioController.text = _initialBio;

        setState(() {
          _hasChanges = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }

  void _checkForChanges() {
    final hasChanges = _firstNameController.text != _initialFirstName ||
        _lastNameController.text != _initialLastName ||
        _bioController.text != _initialBio;

    if (hasChanges != _hasChanges) {
      setState(() {
        _hasChanges = hasChanges;
      });
    }
  }

  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);

    try {
      await _databaseService.updateEducatorProfile(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        bio: _bioController.text.trim(),
      );

      if (mounted) {
        _initialFirstName = _firstNameController.text;
        _initialLastName = _lastNameController.text;
        _initialBio = _bioController.text;
        
        setState(() {
          _hasChanges = false;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving changes: $e'), backgroundColor: _statusRed),
        );
      }
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final scale = (width / 430).clamp(0.8, 1.6);

        if (_isLoading) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: CircularProgressIndicator(color: _bgDarkBlue)),
          );
        }

        return Scaffold(
          backgroundColor: Colors.white,
          body: PopScope(
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
                        SizedBox(height: 10 * scale),
                        Text(
                          '${_firstNameController.text} ${_lastNameController.text}',
                          style: TextStyle(
                            color: _textDarkBlue,
                            fontSize: 28 * scale,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 8 * scale),
                        Text(
                          _bioController.text.isEmpty ? "No bio yet" : _bioController.text,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _textCyan,
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
                        // Removed Email Field SizedBox here
                        SizedBox(height: 20 * scale),
                        _ProfileTextField(
                          label: 'Bio',
                          hint: 'Input your bio here',
                          controller: _bioController,
                          scale: scale,
                          maxLines: 3,
                        ),
                        SizedBox(height: 40 * scale),
                        SizedBox(
                          width: double.infinity,
                          height: 60 * scale,
                          child: OutlinedButton(
                            onPressed: _hasChanges ? _saveChanges : null,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: _hasChanges ? _textCyan : _borderGrey
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16 * scale),
                              ),
                              foregroundColor: _hasChanges ? _textCyan : _borderGrey,
                            ),
                            child: _isLoading 
                              ? const CircularProgressIndicator()
                              : Text(
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
          ),
        );
      },
    );
  }
}

// ... Keep the private classes (_ProfileHeader, _ProfileTextField, etc.) exactly as they were ...
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
              color: _bgDarkBlue,
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
                          image: AssetImage('assets/images/t_racks.png'),
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
                      child: GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => const _PermissionDialog(),
                          );
                        },
                        child: Container(
                          width: 36 * scale,
                          height: 36 * scale,
                          decoration: BoxDecoration(
                            color: _textCyan,
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
    path.lineTo(0, size.height - 50);
    final firstControlPoint = Offset(size.width * 0.25, size.height + 10);
    final firstEndPoint = Offset(size.width * 0.5, size.height - 30);
    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );
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
    this.readOnly = false,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final double scale;
  final int maxLines;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: _bgDarkBlue,
            fontSize: 16 * scale,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 8 * scale),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          readOnly: readOnly,
          style: TextStyle(
            color: readOnly ? Colors.grey[600] : _textDarkBlue,
            fontSize: 16 * scale,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: _textCyan,
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
              borderSide: const BorderSide(color: _textCyan, width: 1.5),
            ),
            filled: true,
            fillColor: readOnly ? Colors.grey[100] : Colors.white,
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
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: _borderGrey),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        foregroundColor: const Color(0xFF1A2B3C),
                      ),
                      child: const Text('Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: _borderGrey),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        foregroundColor: const Color(0xFF1A2B3C),
                      ),
                      child: const Text('Leave', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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

class _PermissionDialog extends StatelessWidget {
  const _PermissionDialog();
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
              'Permission Required',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF2E7D57),
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'We need your permission to access\nthe camera.',
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
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: _borderGrey),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        foregroundColor: const Color(0xFF1A2B3C),
                      ),
                      child: const Text('Allow', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: _borderGrey),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        foregroundColor: const Color(0xFF1A2B3C),
                      ),
                      child: const Text('Do not allow', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
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