import 'package:flutter/material.dart';
import 'package:t_racks_softdev_1/commonWidgets/commonwidgets.dart';
import 'package:t_racks_softdev_1/screens/register_screen.dart';
import 'package:t_racks_softdev_1/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:t_racks_softdev_1/screens/student_home_screen.dart';
import 'package:t_racks_softdev_1/screens/educator/educator_home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _isLoading = false; // For the login button
  bool _passwordVisible = false;

  final _authService = AuthService();

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      showCustomSnackBar(context, "Please fill all fields.");
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      // 1. Call the service, which now returns the role
      final String userRole = await _authService.logIn(
        email: email,
        password: password,
      );

      // 2. Handle success and navigate based on the role
      if (mounted) {
        _emailController.clear();
        _passwordController.clear();

        // 3. Use a switch to decide where to go
        switch (userRole) {
          case 'student':
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const StudentHomeScreen(),
              ), // TODO: Create StudentHomeScreen
            );
            break;
          case 'educator':
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const EducatorHomeScreen(),
              ), // TODO: Create EducatorHomeScreen
            );
            break;
          default:
            // Handle unknown roles
            showCustomSnackBar(context, "Unknown user role: $userRole");
        }
      }
    } on AuthException catch (e) {
      // 4. Handle errors using your global snackbar
      showCustomSnackBar(context, e.message);
    } catch (e) {
      showCustomSnackBar(context, "An unexpected error occurred.");
    }

    // 5. Stop loading
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
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(color: Colors.white),
          Column(
            children: [
              Expanded(
                flex: 5,
                child: ClipPath(
                  clipper: BottomWaveClipper(),
                  child: Container(
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
              Expanded(
                flex: 7,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30.0),
                  child: Column(
                    children: [
                      // "Sign in" Title
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              child: const Text(
                                "Sign in",
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
                          physics: const ClampingScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(
                                height: 24,
                              ), // Space after the title/line
                              // Email Label
                              const Text(
                                'Email',
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),

                              // Email Field
                              TextField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  hintText: 'Email address',
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
                              const SizedBox(
                                height: 24,
                              ), // Space between fields
                              // Password Label
                              const Text(
                                'Password',
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),

                              // Password Field
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
                                    borderSide: BorderSide(
                                      color: Color(0xFF21446D),
                                    ),
                                  ),
                                ),
                              ),
                              // --- START: NEW "REMEMBER ME" / "FORGOT PASSWORD" ROW ---
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:MainAxisAlignment.spaceBetween,
                                children: [
                                  // "Remember Me" Row
                                  Row(
                                    children: [
                                      SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: Checkbox(
                                          value: _rememberMe,
                                          onChanged: (bool? newValue) {
                                            setState(() {
                                              _rememberMe = newValue ?? false;
                                            });
                                          },
                                          activeColor: const Color(
                                            0xFF26A69A,
                                          ), // Green/teal
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Text('Remember Me'),
                                    ],
                                  ),
                                  // "Forgot Password?" Button
                                  TextButton(
                                    onPressed: () {
                                      // TODO: Handle forgot password
                                    },
                                    child: const Text(
                                      'Forgot Password?',
                                      style: TextStyle(
                                        color: Color(0xFF26A69A),
                                      ), // Green/teal
                                    ),
                                  ),
                                ],
                              ),
                              // --- END: NEW ROW ---
                              // --- START: NEW LOGIN BUTTON ---
                            ],
                          ),
                        ),
                      ),

                      SizedBox(
                        width: double.infinity, // Makes button full-width
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(
                              0xFF26A69A,
                            ), // Green/teal
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  'Login',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      // --- END: NEW LOGIN BUTTON ---

                      // --- START: NEW "DON'T HAVE AN ACCOUNT?" ROW ---
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Don't have an account? ",
                            style: TextStyle(color: Colors.black54),
                          ),
                          TextButton(
                            onPressed: () {
                              // TODO: Navigate to Register screen
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const RegisterScreen(),
                                ),
                              );
                            },
                            // You might need this style to remove default padding
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Register',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF26A69A), // Green/teal
                              ),
                            ),
                          ),
                        ],
                      ),
                      // --- END: NEW ROW ---
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
