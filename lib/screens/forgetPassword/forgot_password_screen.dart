import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:t_racks_softdev_1/commonWidgets/commonwidgets.dart';
import 'package:t_racks_softdev_1/screens/forgetPassword/forgot_password_pages.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _pageController = PageController();
  final _emailController = TextEditingController();
  // List of 5 controllers for the OTP boxes
  final List<TextEditingController> _otpControllers = List.generate(
    5,
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
    if (currentPage == 0) {
      // -STEP 1: SEND EMAIL
      if (_emailController.text.isEmpty) {
        showCustomSnackBar(context, "Please enter your email");
        return;
      }
      // TODO: Call API to send reset code
      print("Sending reset code to ${_emailController.text}");
      _goToNextPage();
    } else if (currentPage == 1) {
      //  STEP 2: VERIFY CODE
      String code = _otpControllers.map((c) => c.text).join();
      if (code.length < 5) {
        showCustomSnackBar(context, "Please enter the full code");

        return;
      }
      // TODO: Call API to verify code
      //more validation here like if error code or what
      print("Verifying code: $code");
      _goToNextPage();
    } else {
      // STEP 3: RESET PASSWORD
      if (_newPasswordController.text != _confirmPasswordController.text) {
         showCustomSnackBar(context, "Passwords do not match");
        return;
      }
      // TODO: Call API to update password
      print("Updating password...");
      // Navigator.pop(context); // Go back to login
    }
  }

  void _goToNextPage() {
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
                          onPressed: _onContinuePressed,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF26A69A),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            
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
