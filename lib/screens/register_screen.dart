import 'package:flutter/material.dart';
import 'package:t_racks_softdev_1/commonWidgets/commonwidgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:t_racks_softdev_1/screens/logIn_screen.dart';
import 'package:t_racks_softdev_1/services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // --- STATE VARIABLES ---
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  bool _isStudent = true; // Default to Student
  bool _isEducator = false;
  bool _isLoading = false;
  //Shorthand for supabase client
  final _authService = AuthService();

  // async function to handle registration
  Future<void> _handleRegister() async {
    // 1. Validation (this stays in the UI)
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    final String role = _isStudent ? 'student' : 'educator';

    if (password != confirmPassword) {
      showCustomSnackBar(context, "Passwords do not match.");
      return;
    }
    if (email.isEmpty || phone.isEmpty || password.isEmpty) {
      showCustomSnackBar(context, "Please fill all fields.");
      return;
    }

    //Checks if the email is valid format wise
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      showCustomSnackBar(context, "Please enter a valid email address.");
      return;
    }

    // Checks if the phone number is valid or not
    if (!RegExp(r'^\+?[0-9]{7,15}$').hasMatch(phone)) {
      showCustomSnackBar(context, "Please enter a valid phone number.");
      return;
    }

    ///Password length validation
    if (password.length < 8) {
      showCustomSnackBar(context, "Password must be at least 8 characters.");
      return;
    }

    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      showCustomSnackBar(
        context,
        "Password must contain at least one uppercase letter.",
      );
      return;
    }

    if (!RegExp(r'[0-9]').hasMatch(password)) {
      showCustomSnackBar(context, "Password must contain at least one number.");
      return;
    }

    // 2. Set loading state
    setState(() {
      _isLoading = true;
    });
    // 3. Call the service and handle the result
    try {
      // --- UPDATED ---
      // This is the only line that talks to the service
      await _authService.register(
        email: email,
        password: password,
        phone: phone,
        role: role,
      );

      // 4. Handle success
      if (mounted) {
        showCustomSnackBar(
          context,
          "Success! Please check your email to verify.",
          isError: false,
        );
        Navigator.pop(context);
      }
    } on AuthException catch (e) {
      // 5. Handle errors
      showCustomSnackBar(context, e.message);
    } catch (e) {
      showCustomSnackBar(context, "An unexpected error occurred.");
    }

    // 6. Stop loading (no matter what)
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _passwordVisible = true;
    _confirmPasswordVisible = true;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
  // -------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(color: Colors.white),
          Column(
            children: [
              // --- TOP BLUE HEADER (Unchanged) ---
              Expanded(
                flex: 3,
                child: ClipPath(
                  clipper: BottomWaveClipper(),
                  child: Container(
                    // ... (your header container)
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF194B61),
                          Color(0xFF2A7FA3),
                          Color(0xFF267394),
                          Color(0xFF349BC7),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Image.asset(
                      'assets/images/squigglytexture.png',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                ),
              ),

              // --- BOTTOM WHITE FORM AREA ---
              Expanded(
                flex: 9,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // "Sign up" Title
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              child: const Text(
                                "Sign up",
                                style: TextStyle(
                                  fontSize: 40.0,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF21446D),
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Container(
                              height: 5,
                              width: 80,
                              color: const Color(0xFF21446D),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Email',
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextField(
                                controller: _emailController,
                                textAlignVertical: TextAlignVertical.center,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  isDense: true,
                                  hintText: 'Email address',
                                  hintStyle: TextStyle(
                                    color: Color.fromARGB(255, 207, 207, 207),
                                  ),
                                  // --- ADD THIS ICON ---
                                  prefixIcon: Icon(
                                    Icons.email_outlined,
                                    color: Colors.grey,
                                  ),
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: Colors.grey),
                                  ),
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Color(0xFF21446D),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Phone no Field
                              const Text(
                                'Phone no',
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextField(
                                controller: _phoneController,
                                textAlignVertical: TextAlignVertical.center,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(
                                  isDense: true,
                                  hintText: 'Phone number',
                                  hintStyle: TextStyle(
                                    color: Color.fromARGB(255, 207, 207, 207),
                                  ),
                                  // --- ADD THIS ICON ---
                                  prefixIcon: Icon(
                                    Icons.phone_android_outlined,
                                    color: Colors.grey,
                                  ),
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: Colors.grey),
                                  ),
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Color(0xFF21446D),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Password Field
                              const Text(
                                'Password',
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextField(
                                controller: _passwordController,
                                textAlignVertical: TextAlignVertical.center,
                                obscureText: _passwordVisible,
                                decoration: InputDecoration(
                                  // Removed const
                                  isDense: true,
                                  hintText: 'Password',
                                  hintStyle: TextStyle(
                                    color: Color.fromARGB(255, 207, 207, 207),
                                  ),
                                  // --- ADD THIS ICON ---
                                  prefixIcon: const Icon(
                                    Icons.lock_outline,
                                    color: Colors.grey,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _passwordVisible
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: Colors.grey,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _passwordVisible = !_passwordVisible;
                                      });
                                    },
                                  ),
                                  enabledBorder: const UnderlineInputBorder(
                                    borderSide: BorderSide(color: Colors.grey),
                                  ),
                                  focusedBorder: const UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Color(0xFF21446D),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Confirm Password Field
                              const Text(
                                'Confirm Password',
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextField(
                                controller: _confirmPasswordController,
                                textAlignVertical: TextAlignVertical.center,
                                obscureText: _confirmPasswordVisible,
                                decoration: InputDecoration(
                                  // Removed const
                                  isDense: true,
                                  hintText: 'Confirm Password',
                                  hintStyle: TextStyle(
                                    color: Color.fromARGB(255, 207, 207, 207),
                                  ),
                                  // --- ADD THIS ICON ---
                                  prefixIcon: const Icon(
                                    Icons.lock_outline,
                                    color: Colors.grey,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _confirmPasswordVisible
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: Colors.grey,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _confirmPasswordVisible =
                                            !_confirmPasswordVisible;
                                      });
                                    },
                                  ),
                                  enabledBorder: const UnderlineInputBorder(
                                    borderSide: BorderSide(color: Colors.grey),
                                  ),
                                  focusedBorder: const UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Color(0xFF21446D),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Checkbox Section
                              const Text(
                                'Are you a student or an educator?',
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              Row(
                                children: [
                                  Checkbox(
                                    value: _isStudent,
                                    activeColor: const Color(
                                      0xFF21446D,
                                    ), // Added active color
                                    onChanged: (bool? value) {
                                      // --- ADD THIS ---
                                      setState(() {
                                        _isStudent = true;
                                        _isEducator = false;
                                      });
                                      // -----------------
                                    },
                                  ),
                                  const Text('Student'),
                                  const SizedBox(width: 20),
                                  Checkbox(
                                    value: _isEducator,
                                    activeColor: const Color(
                                      0xFF21446D,
                                    ), // Added active color
                                    onChanged: (bool? value) {
                                      // --- ADD THIS ---
                                      setState(() {
                                        _isEducator = true;
                                        _isStudent = false;
                                      });
                                      // -----------------
                                    },
                                  ),
                                  const Text('Educator'),
                                ],
                              ),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _isLoading
                                      ? null
                                      : _handleRegister,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(
                                      0xFF26A69A,
                                    ), // Green/teal
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    'Create Account',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    "Already have an account? ",
                                    style: TextStyle(color: Colors.black54),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const LoginScreen(),
                                        ),
                                      );
                                    },
                                    // You might need this style to rFmove default padding
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text(
                                      'Log In',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF26A69A), // Green/teal
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),

                      // This Spacer WILL work, but will cause an overflow

                      // Create Account Button

                      // "Already have an Account?" Row
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
