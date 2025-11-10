import 'package:flutter/material.dart';
import 'package:t_racks_softdev_1/commonWidgets/commonwidgets.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:t_racks_softdev_1/screens/onBoarding_screen/boarding_screens.dart';

class OnBoardingScreen extends StatefulWidget {
  final String role;
  const OnBoardingScreen({super.key, required this.role});

  @override
  State<OnBoardingScreen> createState() => _OnBoardingScreenState();
}

class _OnBoardingScreenState extends State<OnBoardingScreen> {
  final _pageController = PageController();
  int currentPage = 0;
  final _fullNameController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _ageController = TextEditingController();
  String? _gender = 'male';
  List<Widget> _pagesToShow = [];

  final _institutionController = TextEditingController();
  final _programController = TextEditingController();
  String? _educationalLevel = 'primary';
  String? _gradeYearLevel;

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

  //validations
  bool _validateStudentPage1() {
    if (_fullNameController.text.isEmpty ||
        _birthDateController.text.isEmpty ||
        _gender == null) {
      showCustomSnackBar(context, "Please fill in all fields.");
      return false; // Validation failed
    }
    return true; // Validation passed
  }

  bool _validateStudentPage2() {
    if (_institutionController.text.isEmpty || _gradeYearLevel == null) {
      showCustomSnackBar(
        context,
        "Please select your institution and grade level.",
      );
      return false;
    }
    // Program is only required if they are tertiary
    if (_educationalLevel == 'tertiary' && _programController.text.isEmpty) {
      showCustomSnackBar(context, "Please enter your program.");
      return false;
    }
    return true;
  }

  bool _validateTeacherPage1() {
    // Teachers have all fields on one page
    if (_fullNameController.text.isEmpty ||
        _birthDateController.text.isEmpty ||
        _gender == null ||
        _institutionController.text.isEmpty) {
      showCustomSnackBar(context, "Please fill in all fields.");
      return false;
    }
    return true;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fullNameController.dispose();
    _birthDateController.dispose();
    _ageController.dispose();
    _institutionController.dispose();
    _programController.dispose();
    super.dispose();
  }

  void _onSaveAndContinue() async {
    if (currentPage < _pagesToShow.length - 1) {
      if (_validateStudentPage1()) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeIn,
        );
      }
    } else {
      bool isLastPageValid = false;
      if (widget.role == 'student') {
        isLastPageValid = _validateStudentPage2();
      } else {
        isLastPageValid = _validateTeacherPage1();
      }
      // If all fields are filled can now proceed to database saving logic 
      if (isLastPageValid) {
        print("Button tapped on LAST page. (All fields are filled)");
        // database saving logic here
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _studentPages = [
      StudentPage1(
        fullNameController: _fullNameController,
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
    ];

    final List<Widget> _teacherPages = [
      TeacherPage1(
        fullNameController: _fullNameController,
        birthDateController: _birthDateController,
        ageController: _ageController,
        gender: _gender,
        onGenderChanged: _onGenderChanged,
        onBirthDateTapped: () => _selectDate(context),
        institutionController: _institutionController,
      ),
    ];

    _pagesToShow = (widget.role == 'student') ? _studentPages : _teacherPages;

    return Scaffold(
      body: Stack(
        children: [
          Container(color: Colors.white),
          Column(
            children: [
              // --- TOP BLUE HEADER ---
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

              // --- BOTTOM WHITE AREA ---
              Expanded(
                flex: 9,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30.0),
                  child: Column(
                    children: [
                      // --- PageView ---
                      Expanded(
                        child: PageView(
                          controller: _pageController,
                          onPageChanged: (int page) {
                            setState(() {
                              currentPage = page;
                            });
                          },
                          children: _pagesToShow,
                        ),
                      ),

                      // --- The Page Indicator Dots ---
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
                            currentPage < _pagesToShow.length - 1
                                ? 'Save and Continue'
                                : 'Save and Finish',
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
