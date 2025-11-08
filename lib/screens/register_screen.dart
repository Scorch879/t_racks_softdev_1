import 'package:flutter/material.dart';
import 'package:t_racks_softdev_1/commonWidgets/commonwidgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  final supabase = Supabase.instance.client;

// async function to handle registration
  Future<void> _handleRegister() async {
    //get all user inputs first
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final String role = _isStudent ? 'student' : 'educator';
    
    //simple validation
    if (email.isEmpty ||phone.isEmpty ||password.isEmpty || confirmPassword.isEmpty) {
      _showErrorSnackBar('Please fill in all fields.');
      return;
    }
    if (password != confirmPassword) {
      _showErrorSnackBar('Passwords do not match.');
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      final authResponse = await supabase.auth.signUp(
        email: email,
        password: password,
        // This 'data' map stores extra info like phone and role
        // in the 'user_metadata' column in Supabase
        data: {
          'phone_number': phone,
          'role': role,
        },
      );
      // 5. Handle success
      if (mounted) {
        _showErrorSnackBar("Success! Please check your email to verify.", isError: false);
        // Go back to the login screen
        Navigator.pop(context); 
      }

    } on AuthException catch (e) {
      // 6. Handle errors (e.g., email already taken)
      _showErrorSnackBar(e.message);
    } catch (e) {
      // 7. Handle other unexpected errors
      _showErrorSnackBar("An unexpected error occurred.");
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

//for showing snackbar messages
  void _showErrorSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : Colors.green,
      ),
    );
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

                      // Email Field
                      const Text(
                        'Email',
                        style: TextStyle(
                          color: Colors.black54,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          hintText: 'Email address',
                          // --- ADD THIS ICON ---
                          prefixIcon: Icon(
                            Icons.email_outlined,
                            color: Colors.grey,
                          ),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF21446D)),
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
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          hintText: 'Phone number',
                          // --- ADD THIS ICON ---
                          prefixIcon: Icon(
                            Icons.phone_android_outlined,
                            color: Colors.grey,
                          ),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF21446D)),
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
                        obscureText: _passwordVisible,
                        decoration: InputDecoration(
                          // Removed const
                          hintText: 'Password',
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
                            borderSide: BorderSide(color: Color(0xFF21446D)),
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
                        obscureText: _confirmPasswordVisible,
                        decoration: InputDecoration(
                          // Removed const
                          hintText: 'Confirm Password',
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
                            borderSide: BorderSide(color: Color(0xFF21446D)),
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
                            onChanged: (val) {
                              /* ... */
                            },
                          ),
                          const Text('Student'),
                          const SizedBox(width: 20),
                          Checkbox(
                            value: _isEducator,
                            onChanged: (val) {
                              /* ... */
                            },
                          ),
                          const Text('Educator'),
                        ],
                      ),

                      // This Spacer WILL work, but will cause an overflow
                      const Spacer(),

                      // Create Account Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleRegister,
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
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                        ),
                      ),

                      // "Already have an Account?" Row
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Already have an Account? "),
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                            },
                            child: const Text(
                              'Login',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF26A69A),
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
            ],
          ),
        ],
      ),
    );
  }
}
