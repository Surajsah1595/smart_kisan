import 'package:flutter/material.dart';
import 'user_registration.dart';
class WelcomeScreen extends StatefulWidget {
  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  // 0 = Welcome, 1 = Language Selection, 2 = Onboarding 1, 3 = Onboarding 2, 4 = Onboarding 3
  int _currentScreen = 0;
  String? _selectedLanguage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildCurrentScreen(),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_currentScreen) {
      case 0:
        return _buildWelcomeScreen();
      case 1:
        return _buildLanguageSelectionScreen();
      case 2:
        return _buildOnboarding1Screen();
      case 3:
        return _buildOnboarding2Screen();
      case 4:
        return _buildOnboarding3Screen();
      default:
        return _buildWelcomeScreen();
    }
  }

  // WELCOME SCREEN
  Widget _buildWelcomeScreen() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('sk.jpg'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.4),
            BlendMode.darken,
          ),
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            Positioned(
              left: 34,
              top: 150,
              child: Container(
                width: MediaQuery.of(context).size.width - 68,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 172,
                      height: 172,
                      margin: EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('Logo.png'),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    Text(
                      'Smart Kisan',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontFamily: 'Arimo',
                        fontWeight: FontWeight.w700,
                        height: 1,
                        shadows: [
                          Shadow(
                            blurRadius: 10,
                            color: Colors.black.withOpacity(0.5),
                            offset: Offset(2, 2),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Empowering Farmers with Smart Solutions',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color.fromARGB(255, 255, 254, 254),
                        fontSize: 20,
                        fontFamily: 'Arimo',
                        fontWeight: FontWeight.w700,
                        height: 1.40,
                        shadows: [
                          Shadow(
                            blurRadius: 5,
                            color: Colors.black.withOpacity(0.3),
                            offset: Offset(1, 1),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 34,
              right: 34,
              bottom: 100,
              child: Column(
                children: [
                  Text(
                    'Get real-time Weather updates, Crop advice, Pest & Diseases Help and Water optimizations at your fingertips.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xCCFFFEFE),
                      fontSize: 16,
                      fontFamily: 'Arimo',
                      fontWeight: FontWeight.w700,
                      height: 1.50,
                      shadows: [
                        Shadow(
                          blurRadius: 3,
                          color: Colors.black.withOpacity(0.3),
                          offset: Offset(1, 1),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 40),
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [Color(0xFF00C850), Color(0xFF00A63D)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x19000000),
                          blurRadius: 6,
                          offset: Offset(0, 4),
                          spreadRadius: -4,
                        ),
                        BoxShadow(
                          color: Color(0x19000000),
                          blurRadius: 15,
                          offset: Offset(0, 10),
                          spreadRadius: -3,
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          setState(() {
                            _currentScreen = 1; // Go to language selection screen
                          });
                        },
                        child: Center(
                          child: Text(
                            'Get Started',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontFamily: 'Arimo',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        width: 1.5,
                        color: Color(0x33FFFEFE),
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                            Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => LoginScreen()),
                            );
                        },
                        child: Center(
                          child: Text(
                            'Log In',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontFamily: 'Arimo',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // LANGUAGE SELECTION SCREEN (First onboarding screen)
  Widget _buildLanguageSelectionScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Skip Button
            Positioned(
              right: 20,
              top: 20,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                  );
                },
                child: Text(
                  'Skip',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF1E1E1E),
                    fontSize: 24,
                    fontFamily: 'PT Sans',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
            
            // Onboarding 3 Image (from your design)
            Positioned(
              left: 123,
              top: 97,
              child: Container(
                width: 159,
                height: 153,
                child: Image.asset(
                  'Onboarding3.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            
            // Title
            Positioned(
              left: 91,
              top: 314,
              child: SizedBox(
                width: 284,
                child: Text(
                  'Choose Your Language',
                  style: TextStyle(
                    color: Color(0xFF1E1E1E),
                    fontSize: 24,
                    fontFamily: 'PT Sans',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            
            // English Language Card
            Positioned(
              left: 50,
              top: 372,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedLanguage = 'English';
                  });
                },
                child: Container(
                  width: 308,
                  height: 71,
                  decoration: ShapeDecoration(
                    color: _selectedLanguage == 'English' ? Color(0xFFE8F5E9) : Color(0xFFFBFBFB),
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        width: 1.5,
                        color: _selectedLanguage == 'English' ? Color(0xFF2C7C48) : Color(0xFFAFA5A5),
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        left: 89,
                        top: 16,
                        child: Container(
                          width: 145,
                          height: 39.99,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 27,
                                height: 31.99,
                                child: Center(
                                  child: Text(
                                    '🇬🇧',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Color(0xFF0A0A0A),
                                      fontSize: 24,
                                      fontFamily: 'Arimo',
                                      fontWeight: FontWeight.w400,
                                      height: 1.33,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 11.99),
                              Container(
                                width: 101.26,
                                height: 39.99,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: double.infinity,
                                      height: 23.98,
                                      child: Text(
                                        'English',
                                        style: TextStyle(
                                          color: Color(0xFF101727),
                                          fontSize: 16,
                                          fontFamily: 'Arimo',
                                          fontWeight: FontWeight.w400,
                                          height: 1.50,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      width: double.infinity,
                                      height: 16.01,
                                      child: Text(
                                        'EN',
                                        style: TextStyle(
                                          color: Color(0xFF697282),
                                          fontSize: 12,
                                          fontFamily: 'Arimo',
                                          fontWeight: FontWeight.w400,
                                          height: 1.33,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Nepali Language Card
            Positioned(
              left: 51,
              top: 453,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedLanguage = 'Nepali';
                  });
                },
                child: Container(
                  width: 308,
                  height: 71,
                  decoration: ShapeDecoration(
                    color: _selectedLanguage == 'Nepali' ? Color(0xFFE8F5E9) : Color(0xFFFBFBFB),
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        width: 1.5,
                        color: _selectedLanguage == 'Nepali' ? Color(0xFF2C7C48) : Color(0xFFAFA5A5),
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        left: 84,
                        top: 16,
                        child: Container(
                          width: 140.73,
                          height: 39.99,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 25.49,
                                height: 31.99,
                                child: Center(
                                  child: Text(
                                    '🇳🇵',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Color(0xFF0A0A0A),
                                      fontSize: 24,
                                      fontFamily: 'Arimo',
                                      fontWeight: FontWeight.w400,
                                      height: 1.33,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 11.99),
                              Container(
                                width: 103.25,
                                height: 39.99,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: double.infinity,
                                      height: 23.98,
                                      child: Text(
                                        'नेपाली (Nepali)',
                                        style: TextStyle(
                                          color: Color(0xFF101727),
                                          fontSize: 16,
                                          fontFamily: 'Arimo',
                                          fontWeight: FontWeight.w400,
                                          height: 1.50,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      width: double.infinity,
                                      height: 16.01,
                                      child: Text(
                                        'NE',
                                        style: TextStyle(
                                          color: Color(0xFF697282),
                                          fontSize: 12,
                                          fontFamily: 'Arimo',
                                          fontWeight: FontWeight.w400,
                                          height: 1.33,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Hindi Language Card
            Positioned(
              left: 48,
              top: 534,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedLanguage = 'Hindi';
                  });
                },
                child: Container(
                  width: 308,
                  height: 71,
                  decoration: ShapeDecoration(
                    color: _selectedLanguage == 'Hindi' ? Color(0xFFE8F5E9) : Color(0xFFFBFBFB),
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        width: 1.5,
                        color: _selectedLanguage == 'Hindi' ? Color(0xFF2C7C48) : Color(0xFFAFA5A5),
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        left: 92,
                        top: 20,
                        child: Container(
                          width: 21.67,
                          height: 31.99,
                          child: Center(
                            child: Text(
                              '🇮🇳',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF0A0A0A),
                                fontSize: 24,
                                fontFamily: 'Arimo',
                                fontWeight: FontWeight.w400,
                                height: 1.33,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 125.66,
                        top: 16,
                        child: Container(
                          width: 86.68,
                          height: 39.99,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: double.infinity,
                                height: 23.98,
                                child: Text(
                                  'हिन्दी (Hindi)',
                                  style: TextStyle(
                                    color: Color(0xFF101727),
                                    fontSize: 16,
                                    fontFamily: 'Arimo',
                                    fontWeight: FontWeight.w400,
                                    height: 1.50,
                                  ),
                                ),
                              ),
                              Container(
                                width: double.infinity,
                                height: 16.01,
                                child: Text(
                                  'HI',
                                  style: TextStyle(
                                    color: Color(0xFF697282),
                                    fontSize: 12,
                                    fontFamily: 'Arimo',
                                    fontWeight: FontWeight.w400,
                                    height: 1.33,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Progress Dots - First dot active (for language selection)
            Positioned(
              left: 112.60,
              top: 738.83,
              child: Container(
                width: 34.83,
                height: 7.48,
                decoration: ShapeDecoration(
                  color: Color(0xFF2C7C48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 171.32,
              top: 738.83,
              child: Container(
                width: 34.83,
                height: 7.48,
                decoration: ShapeDecoration(
                  color: Color(0xFFF3F3F3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 219.09,
              top: 740.08,
              child: Container(
                width: 34.83,
                height: 7.48,
                decoration: ShapeDecoration(
                  color: Color(0xFFF3F3F3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 267.85,
              top: 738.83,
              child: Container(
                width: 34.83,
                height: 7.48,
                decoration: ShapeDecoration(
                  color: Color(0xFFF3F3F3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            
            // Back Button
            Positioned(
              left: 29.86,
              top: 804.87,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _currentScreen = 0; // Go back to welcome screen
                  });
                },
                child: Container(
                  width: 171.17,
                  height: 49.84,
                  decoration: ShapeDecoration(
                    color: Color(0xFFF3F3F3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Back',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFA1A1A1),
                        fontSize: 16,
                        fontFamily: 'PT Sans',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            // Next Button
            Positioned(
              left: 210.98,
              top: 804.87,
              child: GestureDetector(
                onTap: () {
                  if (_selectedLanguage != null) {
                    print('Selected Language: $_selectedLanguage');
                    setState(() {
                      _currentScreen = 2; // Go to first onboarding screen
                    });
                  }
                },
                child: Container(
                  width: 171.17,
                  height: 49.84,
                  decoration: ShapeDecoration(
                    color: _selectedLanguage != null ? Color(0xFF2C7C48) : Color(0xFFF3F3F3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Next',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _selectedLanguage != null ? Colors.white : Color(0xFFA1A1A1),
                        fontSize: 16,
                        fontFamily: 'PT Sans',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ONBOARDING SCREEN 2
  Widget _buildOnboarding1Screen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              right: 20,
              top: 20,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                  );
                },
                child: Text(
                  'Skip',
                  style: TextStyle(
                    color: Color(0xFF1E1E1E),
                    fontSize: 24,
                    fontFamily: 'PT Sans',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 94,
              top: 93,
              child: Container(
                width: 215,
                height: 236,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('Onboarding1.png'),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 78,
              top: 379,
              child: Container(
                width: 280,
                child: Text(
                  'Monitoring soil and plant',
                  style: TextStyle(
                    color: Color(0xFF1E1E1E),
                    fontSize: 24,
                    fontFamily: 'PT Sans',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 78,
              top: 449,
              child: Container(
                width: 258,
                child: Text(
                  'We aim to use optical (VIR) sensing to observe the fields and make timely crop management decisions.',
                  textAlign: TextAlign.justify,
                  style: TextStyle(
                    color: Color(0xFF9C9C9C),
                    fontSize: 15,
                    fontFamily: 'PT Sans',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
            // Progress Dots - Second dot active
            Positioned(
              left: 107.61,
              top: 743.82,
              child: Container(
                width: 34.83,
                height: 7.48,
                decoration: ShapeDecoration(
                  color: Color(0xFFF3F3F3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 160.35,
              top: 743.82,
              child: Container(
                width: 34.83,
                height: 7.48,
                decoration: ShapeDecoration(
                  color: Color(0xFF2C7C48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 214.09,
              top: 744.08,
              child: Container(
                width: 34.83,
                height: 7.48,
                decoration: ShapeDecoration(
                  color: Color(0xFFF3F3F3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 263.85,
              top: 742.83,
              child: Container(
                width: 34.83,
                height: 7.48,
                decoration: ShapeDecoration(
                  color: Color(0xFFF3F3F3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            // Back Button
            Positioned(
              left: 29.86,
              top: 804.87,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _currentScreen = 1;
                  });
                },
                child: Container(
                  width: 171.17,
                  height: 49.84,
                  decoration: ShapeDecoration(
                    color: Color(0xFFF3F3F3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Back',
                      style: TextStyle(
                        color: Color(0xFFA1A1A1),
                        fontSize: 16,
                        fontFamily: 'PT Sans',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Next Button
            Positioned(
              left: 210.98,
              top: 804.87,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _currentScreen = 3;
                  });
                },
                child: Container(
                  width: 171.17,
                  height: 49.84,
                  decoration: ShapeDecoration(
                    color: Color(0xFF2C7C48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Next',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontFamily: 'PT Sans',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ONBOARDING SCREEN  3
  Widget _buildOnboarding2Screen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              right: 20,
              top: 20,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                  );
                },
                child: Text(
                  'Skip',
                  style: TextStyle(
                    color: Color(0xFF1E1E1E),
                    fontSize: 24,
                    fontFamily: 'PT Sans',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 99.52,
              top: 119.61,
              child: Container(
                width: 213.96,
                height: 294.04,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('Onboarding2.png'),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 98,
              top: 448,
              child: Container(
                width: 216,
                child: Text(
                  'Crop Selection',
                  style: TextStyle(
                    color: Color(0xFF1E1E1E),
                    fontSize: 24,
                    fontFamily: 'PT Sans',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 77,
              top: 484,
              child: Container(
                width: 258,
                child: Text(
                  'Our project can use AI & Machine learning to select the best crop according to the land and water resources.',
                  textAlign: TextAlign.justify,
                  style: TextStyle(
                    color: Color(0xFF9C9C9C),
                    fontSize: 15,
                    fontFamily: 'PT Sans',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
            // Progress Dots - Third dot active
            Positioned(
              left: 106.61,
              top: 738.83,
              child: Container(
                width: 34.83,
                height: 7.48,
                decoration: ShapeDecoration(
                  color: Color(0xFFF3F3F3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 159.37,
              top: 738.83,
              child: Container(
                width: 34.83,
                height: 7.48,
                decoration: ShapeDecoration(
                  color: Color(0xFFF3F3F3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 214.09,
              top: 739,
              child: Container(
                width: 34.83,
                height: 7.48,
                decoration: ShapeDecoration(
                  color: Color(0xFF2C7C48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 262.85,
              top: 739,
              child: Container(
                width: 34.83,
                height: 7.48,
                decoration: ShapeDecoration(
                  color: Color(0xFFF3F3F3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            // Back Button
            Positioned(
              left: 29.86,
              top: 804.87,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _currentScreen = 2;
                  });
                },
                child: Container(
                  width: 171.17,
                  height: 49.84,
                  decoration: ShapeDecoration(
                    color: Color(0xFFF3F3F3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Back',
                      style: TextStyle(
                        color: Color(0xFFA1A1A1),
                        fontSize: 16,
                        fontFamily: 'PT Sans',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Next Button
            Positioned(
              left: 210.98,
              top: 804.87,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _currentScreen = 4;
                  });
                },
                child: Container(
                  width: 171.17,
                  height: 49.84,
                  decoration: ShapeDecoration(
                    color: Color(0xFF2C7C48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Next',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontFamily: 'PT Sans',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ONBOARDING SCREEN 4
  Widget _buildOnboarding3Screen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Skip Button
            Positioned(
              right: 20,
              top: 20,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                  );
                },
                child: Text(
                  'Skip',
                  style: TextStyle(
                    color: Color(0xFF1E1E1E),
                    fontSize: 24,
                    fontFamily: 'PT Sans',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
            // Onboarding 3 Image
            Positioned(
              left: 100,
              top: 96,
              child: Container(
                width: 215,
                height: 236,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('Onboarding3.png'),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            // Title Text
            Positioned(
              left: 104,
              top: 368,
              child: Container(
                width: 285,
                child: Text(
                  'Improve agriculture precision', 
                  style: TextStyle(
                    color: Color(0xFF1E1E1E),
                    fontSize: 24,
                    fontFamily: 'PT Sans',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            // Description Text
            Positioned(
              left: 78,
              top: 449,
              child: Container(
                width: 258,
                child: Text(
                  'We will use satellite imagery, image processing, deep learning, computer vision, and remote sensing to detect changes in the field and crops and solve the problems whenever they pop.',
                  textAlign: TextAlign.justify,
                  style: TextStyle(
                    color: Color(0xFF9C9C9C),
                    fontSize: 15,
                    fontFamily: 'PT Sans',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
            // Progress Dots - Fourth dot active
            Positioned(
              left: 120.58,
              top: 738.83,
              child: Container(
                width: 34.83,
                height: 7.48,
                decoration: ShapeDecoration(
                  color: Color(0xFFF3F3F3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 166.32,
              top: 738.83,
              child: Container(
                width: 34.83,
                height: 7.48,
                decoration: ShapeDecoration(
                  color: Color(0xFFF3F3F3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 209.11,
              top: 738.83,
              child: Container(
                width: 34.83,
                height: 7.48,
                decoration: ShapeDecoration(
                  color: Color(0xFFF3F3F3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 252.90,
              top: 738.83,
              child: Container(
                width: 34.83,
                height: 7.48,
                decoration: ShapeDecoration(
                  color: Color(0xFF2C7C48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            // Back Button
            Positioned(
              left: 29.86,
              top: 804.87,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _currentScreen = 3;
                  });
                },
                child: Container(
                  width: 171.17,
                  height: 49.84,
                  decoration: ShapeDecoration(
                    color: Color(0xFFF3F3F3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Back',
                      style: TextStyle(
                        color: Color(0xFFA1A1A1),
                        fontSize: 16,
                        fontFamily: 'PT Sans',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Next Button - Final
            Positioned(
              left: 210.98,
              top: 804.87,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                  );
                  // TODO: Navigate to main app home screen
                  // Navigator.pushReplacementNamed(context, '/home');
                },
                child: Container(
                  width: 171.17,
                  height: 49.84,
                  decoration: ShapeDecoration(
                    color: Color(0xFF2C7C48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Next', 
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontFamily: 'PT Sans',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}