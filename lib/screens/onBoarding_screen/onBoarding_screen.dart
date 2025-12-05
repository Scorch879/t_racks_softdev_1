import 'dart:io'; // Import for File
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:t_racks_softdev_1/commonWidgets/commonwidgets.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:t_racks_softdev_1/screens/educator/educator_shell.dart';
import 'package:t_racks_softdev_1/screens/onBoarding_screen/boarding_screens.dart';
import 'package:t_racks_softdev_1/screens/onBoarding_screen/face_registration_page.dart';
import 'package:t_racks_softdev_1/screens/student/student_shell_screen.dart';
import 'package:t_racks_softdev_1/services/onboarding_service.dart';

class OnBoardingScreen extends StatefulWidget {
  final String role;
  const OnBoardingScreen({super.key, required this.role});

  @override
  State<OnBoardingScreen> createState() => _OnBoardingScreenState();
}

class _OnBoardingScreenState extends State<OnBoardingScreen> {
  final OnboardingService _onboardingService = OnboardingService();
  final AiServices _aiServices = AiServices();

  //Loading State
  bool _isLoading = false;

  final _pageController = PageController();
  final _lastNameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _ageController = TextEditingController();
  final _institutionController = TextEditingController();
  final _programController = TextEditingController();

  int currentPage = 0;
  String? _gender = 'male';
  List<Widget> _pagesToShow = [];
  String? _educationalLevel = 'primary';
  String? _gradeYearLevel;

  // New Variables for Face Data
  File? _capturedFaceImage;
  List<double>? _capturedFaceVector;

  void _onEducationalLevelChanged(String? value) {
    setState(() {
      _educationalLevel = value;
      _gradeYearLevel = null;
    });
  }

  void _onGradeYearLevelChanged(String? value) {
    setState(() {
      _gradeYearLevel = value;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      DateTime today = DateTime.now();
      int age = today.year - picked.year;
      if (today.month < picked.month ||
          (today.month == picked.month && today.day < picked.day)) {
        age--;
      }
      String formattedDate = "${picked.month} / ${picked.day} / ${picked.year}";
      setState(() {
        _birthDateController.text = formattedDate;
        _ageController.text = age.toString();
      });
    }
  }

  void _onGenderChanged(String? value) {
    setState(() {
      _gender = value;
    });
  }

  // --- Callback from FaceRegistrationPage ---
  void _handleFaceCaptured(File image, List<double> vector) {
    setState(() {
      _capturedFaceImage = image;
      _capturedFaceVector = vector;
    });
    // Optional: Automatically move to next step or just enable the "Save and Finish" button
    print("Face Captured. Vector length: ${vector.length}");
  }

  //validations
  bool _validateStudentPage1() {
    if (_lastNameController.text.isEmpty ||
        _firstNameController.text.isEmpty ||
        _birthDateController.text.isEmpty ||
        _gender == null) {
      showCustomSnackBar(context, "Please fill in all fields.");
      return false;
    }
    return true;
  }

  bool _validateStudentPage2() {
    if (_institutionController.text.isEmpty || _gradeYearLevel == null) {
      showCustomSnackBar(
        context,
        "Please select your institution and grade level.",
      );
      return false;
    }
    if (_educationalLevel == 'tertiary' && _programController.text.isEmpty) {
      showCustomSnackBar(context, "Please enter your program.");
      return false;
    }
    return true;
  }

  bool _validateTeacherPage1() {
    if (_lastNameController.text.isEmpty ||
        _firstNameController.text.isEmpty ||
        _birthDateController.text.isEmpty) {
      showCustomSnackBar(context, "Please fill in all fields.");
      return false;
    }
    return true;
  }

  bool _validateTeacherPage2() {
    if (_institutionController.text.isEmpty || _gender == null) {
      showCustomSnackBar(context, "Please fill in all fields.");
      return false;
    }
    return true;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _lastNameController.dispose();
    _firstNameController.dispose();
    _middleNameController.dispose();
    _birthDateController.dispose();
    _ageController.dispose();
    _institutionController.dispose();
    _programController.dispose();
    super.dispose();
  }

  void _onSaveAndContinue() async {
    bool isCurrentPageValid = false;
    if (widget.role == 'student') {
      if (currentPage == 0) {
        isCurrentPageValid = _validateStudentPage1();
      } else if (currentPage == 1) {
        isCurrentPageValid = _validateStudentPage2();
      } else if (currentPage == 2) {
        // Validation for Face Registration Page
        if (_capturedFaceImage == null || _capturedFaceVector == null) {
          showCustomSnackBar(
            context,
            "Please capture your face before finishing.",
          );
          return;
        }
        isCurrentPageValid = true;
      }
    } else {
      if (currentPage == 0) {
        isCurrentPageValid = _validateTeacherPage1();
      } else if (currentPage == 1) {
        isCurrentPageValid = _validateTeacherPage2();
      }
    }

    if (!isCurrentPageValid) {
      return;
    }

    if (currentPage < _pagesToShow.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    } else {
      // All fields are filled
      print("Button tapped on LAST page. Saving data...");

      setState(() {
        _isLoading = true;
      });

      try {
        if (widget.role == 'student') {
          // --- TEMP: Saving Face Data Locally (Console/Log) ---
          //print("--- SAVING FACE DATA ---");
          //print("Image Path: ${_capturedFaceImage!.path}");
          //print("Vector: $_capturedFaceVector");
          // You can upload _capturedFaceImage to Supabase Storage here
          // You can save _capturedFaceVector to Supabase Database (as array/json) herece
          // ----------------------------------------------------
        

          await _onboardingService.saveStudentProfile(
            firstname: _firstNameController.text,
            middlename: _middleNameController.text,
            lastname: _lastNameController.text,
            role: widget.role,
            birthDate: _birthDateController.text,
            age: int.parse(_ageController.text),
            gender: _gender,
            institution: _institutionController.text,
            program: _programController.text,
            educationalLevel: _educationalLevel,
            gradeYearLevel: _gradeYearLevel,
          );

            if (_capturedFaceImage == null || _capturedFaceVector == null) {
            throw 'Face data is missing.';
          } else {
            await _aiServices.saveFaceData(
              imageFile: _capturedFaceImage!,
              faceVector: _capturedFaceVector!,
            );
          }
        } else {
          await _onboardingService.saveEducatorProfile(
            firstname: _firstNameController.text,
            middlename: _middleNameController.text,
            lastname: _lastNameController.text,
            role: widget.role,
            birthDate: _birthDateController.text,
            age: int.parse(_ageController.text),
            gender: _gender,
            institution: _institutionController.text,
          );
        }

        setState(() {
          _isLoading = false;
        });

        if (mounted ) {
          showCustomSnackBar(
            context,
            "Profile saved successfully!",
            isError: false,
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) {
                if (widget.role == 'student') {
                  return const StudentShellScreen();
                } else {
                  return const EducatorShell();
                }
              },
            ),
          );
        }
      } on AuthException catch (e) {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          showCustomSnackBar(context, 'Error: ${e.message}');
        }
      } catch (e) {
        print(e);
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          showCustomSnackBar(context, 'Error occured ${e.toString()}'); ///error temp
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> studentPages = [
      StudentPage1(
        lastNameController: _lastNameController,
        firstNameController: _firstNameController,
        middleNameController: _middleNameController,
        birthDateController: _birthDateController,
        ageController: _ageController,
        gender: _gender,
        onGenderChanged: _onGenderChanged,
        onBirthDateTapped: () => _selectDate(context),
      ),
      StudentPage2(
        institutionController: _institutionController,
        programController: _programController,
        educationalLevel: _educationalLevel,
        gradeYearLevel: _gradeYearLevel,
        onEducationalLevelChanged: _onEducationalLevelChanged,
        onGradeYearLevelChanged: _onGradeYearLevelChanged,
      ),
      // --- Added Face Registration Page ---
      FaceRegistrationPage(onFaceCaptured: _handleFaceCaptured),
    ];

    final List<Widget> teacherPages = [
      TeacherPage1(
        lastNameController: _lastNameController,
        firstNameController: _firstNameController,
        middleNameController: _middleNameController,
        birthDateController: _birthDateController,
        ageController: _ageController,
        onBirthDateTapped: () => _selectDate(context),
      ),
      TeacherPage2(
        gender: _gender,
        onGenderChanged: _onGenderChanged,
        institutionController: _institutionController,
      ),
    ];

    _pagesToShow = (widget.role == 'student') ? studentPages : teacherPages;

    // Check if on last page for students (Face ID page) to possibly change button text
    bool isFacePage = widget.role == 'student' && currentPage == 2;
    String buttonText = currentPage < _pagesToShow.length - 1
        ? 'Save and Continue'
        : 'Save and Finish';

    // Disable main button if on face page and not yet captured?
    // Or just let validation handle it (preferred for consistent UI).

    return Scaffold(
      body: Stack(
        children: [
          Container(color: Colors.white),
          Column(
            children: [
              // top wave thingy
              Expanded(
                flex: 2,
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

              // bottom part
              Expanded(
                flex: 9,
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
                          onPressed: _onSaveAndContinue,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF26A69A),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            buttonText,
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
