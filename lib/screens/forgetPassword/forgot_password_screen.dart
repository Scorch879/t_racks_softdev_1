import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:t_racks_softdev_1/commonWidgets/commonwidgets.dart';
import 'package:t_racks_softdev_1/screens/forgetPassword/forgot_password_pages.dart';
import 'package:t_racks_softdev_1/services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

final _authService = AuthService();

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _pageController = PageController();
  final _emailController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(
    6, // Changed to 6 to match the 6 OTP input boxes
    (index) => TextEditingController(),
  );
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;

  List<Widget> _pagesToShow = [];
  int currentPage = 0;

  @override
  void initState() {
    super.initState();
    // Initialize the pages here so we can pass the controllers and functions
    _pagesToShow = [
      ForgotPage1(emailController: _emailController),
      ForgotPage2(otpControllers: _otpControllers),
      ForgotPage3(
        passController: _newPasswordController,
        confirmController: _confirmPasswordController,
      ),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    _emailController.dispose();
    for (var c in _otpControllers) c.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onContinuePressed() async {
    setState(() {
      _isLoading = true;
    });
    try {
      if (currentPage == 0) {
        // -STEP 1: SEND EMAIL
        if (_emailController.text.isEmpty) {
          showCustomSnackBar(context, "Please enter your email");
          setState(() => _isLoading = false); // Add this line
          return;
        }

        /// This is the api for sending an otp
        await _authService.forgotPassword(email: _emailController.text);
        showCustomSnackBar(
          context,
          "Reset code sent to the email",
          isError: false,
        );

        print("Sending reset code to ${_emailController.text}");
        _goToNextPage();
      } else if (currentPage == 1) {
        //  STEP 2: VERIFY CODE
        String code = _otpControllers.map((c) => c.text).join();

        if (code.length < 6) {
          showCustomSnackBar(context, "Please enter the full code");
          setState(() => _isLoading = false); // Add this line
          return;
        }

        ///Api for verifying the password reset otp
        await _authService.verifyPasswordResetOtp(
          email: _emailController.text,
          token: code,
        );

        //more validation here like if error code or what
        print("Verifying code: $code");
        _goToNextPage();
      } else {
        // STEP 3: RESET PASSWORD
        ///Password validations
        final newPassword = _newPasswordController.text;
        if (newPassword.isEmpty || newPassword.length < 8) {
          showCustomSnackBar(
            context,
            "Passwords must be at least 8 characters",
          );
          setState(() => _isLoading = false); // Add this line
          return;
        }
        if (newPassword != _confirmPasswordController.text) {
          showCustomSnackBar(context, "Passwords do not match");
          setState(() => _isLoading = false);
          return;
        }

        if (!RegExp(r'[A-Z]').hasMatch(newPassword)) {
          showCustomSnackBar(
            context,
            "Password must contain at least one uppercase letter.",
          );
          setState(() => _isLoading = false); // Add this line
          return;
        }

        if (!RegExp(r'[0-9]').hasMatch(newPassword)) {
          showCustomSnackBar(
            context,
            "Password must contain at least one number.",
          );
          setState(() => _isLoading = false); // Add this line
          return;
        }

        //if all validation suceeds

        await _authService.updateUserPassword(newPassword: newPassword);
        if (mounted) {
          showCustomSnackBar(
            context,
            "Password updated successfully",
            isError: false,
          );
        }

        print("Updating password...");
        Navigator.pop(context); // Go back to login
      }
    } catch (e) {
      showCustomSnackBar(context, "Error: ${e.toString()}");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } finally {
      // The loading state is now handled inside the try/catch blocks,
      // so we can remove this to avoid setting state after the page has changed.
    }
  }

  void _goToNextPage() {
    // We set isLoading to false here to stop the loader before switching pages.
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeIn,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(color: Colors.white),
          Column(
            children: [
              Expanded(
                flex: 4,
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
              //bottom part
              Expanded(
                flex: 7,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30.0),
                  child: Column(
                    children: [
                      Expanded(
                        child: PageView(
                          controller: _pageController,
                          physics: const NeverScrollableScrollPhysics(),
                          onPageChanged: (int page) {
                            setState(() {
                              currentPage = page;
                            });
                          },
                          children: _pagesToShow,
                        ),
                      ),

                      SmoothPageIndicator(
                        controller: _pageController,
                        count: _pagesToShow.length,
                        effect: const WormEffect(
                          dotHeight: 10,
                          dotWidth: 10,
                          activeDotColor: Color(0xFF26A69A),
                          dotColor: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 24),

                      //button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _onContinuePressed,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF26A69A),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : Text(
                                  'Continue',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 40),
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
