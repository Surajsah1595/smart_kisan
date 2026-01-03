import 'package:flutter/material.dart';
import 'user_registration.dart';

class WelcomeScreen extends StatefulWidget {
  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  int _currentScreen = 0;
  String? _selectedLanguage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildCurrentScreen(),
    );
  }

  Widget _buildCurrentScreen() {
    final screens = [
      _buildWelcomeScreen(),
      _buildLanguageSelectionScreen(),
      _buildOnboardingScreen(0),
      _buildOnboardingScreen(1),
      _buildOnboardingScreen(2),
    ];
    return screens[_currentScreen.clamp(0, screens.length - 1)];
  }

  Widget _buildWelcomeScreen() {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('sk.jpg'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.4), BlendMode.darken),
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
                  children: [
                    Container(
                      width: 172,
                      height: 172,
                      margin: EdgeInsets.only(bottom: 10),
                      child: Image.asset('Logo.png', fit: BoxFit.contain),
                    ),
                    _buildText('Smart Kisan', 48, FontWeight.w700),
                    SizedBox(height: 20),
                    _buildText('Empowering Farmers with Smart Solutions', 20, FontWeight.w700),
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
                  _buildText(
                    'Get real-time Weather updates, Crop advice, Pest & Diseases Help and Water optimizations at your fingertips.',
                    16,
                    FontWeight.w700,
                    color: Color(0xCCFFFEFE),
                  ),
                  SizedBox(height: 40),
                  _buildButton('Get Started', () => setState(() => _currentScreen = 1)),
                  SizedBox(height: 20),
                  _buildOutlineButton('Log In', () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => LoginScreen()));
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSelectionScreen() {
    final languages = [
      {'name': 'English', 'code': 'EN', 'flag': '🇬🇧'},
      {'name': 'नेपाली (Nepali)', 'code': 'NE', 'flag': '🇳🇵'},
      {'name': 'हिन्दी (Hindi)', 'code': 'HI', 'flag': '🇮🇳'},
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(right: 20, top: 20, child: _buildSkipButton()),
            Positioned(
              left: 123,
              top: 97,
              child: Container(
                width: 159,
                height: 153,
                child: Image.asset('Onboarding3.png', fit: BoxFit.contain),
              ),
            ),
            Positioned(left: 91, top: 314, child: _buildTitle('Choose Your Language', 284)),
            
            ...List.generate(3, (index) => Positioned(
              left: 50,
              top: 372 + (index * 81),
              child: _buildLanguageCard(languages[index]),
            )),

            ..._buildProgressDots(4, activeIndex: 0),
            _buildNavigationButtons(
              onBack: () => setState(() => _currentScreen = 0),
              onNext: _selectedLanguage != null ? () => setState(() => _currentScreen = 2) : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingScreen(int index) {
    final data = [
      {
        'image': 'Onboarding1.png',
        'title': 'Monitoring soil and plant',
        'desc': 'We aim to use optical (VIR) sensing to observe the fields and make timely crop management decisions.',
      },
      {
        'image': 'Onboarding2.png',
        'title': 'Crop Selection',
        'desc': 'Our project can use AI & Machine learning to select the best crop according to the land and water resources.',
      },
      {
        'image': 'Onboarding3.png',
        'title': 'Improve agriculture precision',
        'desc': 'We will use satellite imagery, image processing, deep learning, computer vision, and remote sensing to detect changes in the field and crops and solve the problems whenever they pop.',
      },
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(right: 20, top: 20, child: _buildSkipButton()),
            Positioned(
              left: index == 1 ? 99.52 : 94,
              top: index == 1 ? 119.61 : 93,
              child: Container(
                width: index == 1 ? 213.96 : 215,
                height: index == 1 ? 294.04 : 236,
                child: Image.asset(data[index]['image']!, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              left: index == 0 ? 78 : (index == 1 ? 98 : 104),
              top: index == 0 ? 379 : (index == 1 ? 448 : 368),
              child: _buildTitle(data[index]['title']!, index == 0 ? 280 : (index == 1 ? 216 : 285)),
            ),
            Positioned(
              left: 78,
              top: index == 0 ? 449 : (index == 1 ? 484 : 449),
              child: _buildDescription(data[index]['desc']!),
            ),
            
            ..._buildProgressDots(4, activeIndex: index + 1),
            _buildNavigationButtons(
              onBack: () => setState(() => _currentScreen = index + 1),
              onNext: () => setState(() {
                if (index < 2) _currentScreen = index + 3;
                else Navigator.push(context, MaterialPageRoute(builder: (_) => LoginScreen()));
              }),
            ),
          ],
        ),
      ),
    );
  }

  // Helper Widgets
  Widget _buildText(String text, double fontSize, FontWeight weight, {Color color = Colors.white}) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontFamily: 'Arimo',
        fontWeight: weight,
        height: 1.4,
        shadows: [Shadow(blurRadius: 5, color: Colors.black.withOpacity(0.3), offset: Offset(1, 1))],
      ),
    );
  }

  Widget _buildButton(String text, VoidCallback onTap) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF00C850), Color(0xFF00A63D)]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Color(0x19000000), blurRadius: 6, offset: Offset(0, 4)),
          BoxShadow(color: Color(0x19000000), blurRadius: 15, offset: Offset(0, 10)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Center(child: _buildText(text, 16, FontWeight.w700)),
        ),
      ),
    );
  }

  Widget _buildOutlineButton(String text, VoidCallback onTap) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(width: 1.5, color: Color(0x33FFFEFE)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Center(child: _buildText(text, 16, FontWeight.w700)),
        ),
      ),
    );
  }

  Widget _buildSkipButton() {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LoginScreen())),
      child: Text('Skip', style: TextStyle(color: Color(0xFF1E1E1E), fontSize: 24, fontFamily: 'PT Sans')),
    );
  }

  Widget _buildTitle(String text, double width) {
    return SizedBox(
      width: width,
      child: Text(text, style: TextStyle(color: Color(0xFF1E1E1E), fontSize: 24, fontFamily: 'PT Sans', fontWeight: FontWeight.w700)),
    );
  }

  Widget _buildDescription(String text) {
    return SizedBox(
      width: 258,
      child: Text(
        text,
        textAlign: TextAlign.justify,
        style: TextStyle(color: Color(0xFF9C9C9C), fontSize: 15, fontFamily: 'PT Sans'),
      ),
    );
  }

  Widget _buildLanguageCard(Map<String, String> language) {
    return GestureDetector(
      onTap: () => setState(() => _selectedLanguage = language['name']),
      child: Container(
        width: 308,
        height: 71,
        decoration: ShapeDecoration(
          color: _selectedLanguage == language['name'] ? Color(0xFFE8F5E9) : Color(0xFFFBFBFB),
          shape: RoundedRectangleBorder(
            side: BorderSide(width: 1.5, color: _selectedLanguage == language['name'] ? Color(0xFF2C7C48) : Color(0xFFAFA5A5)),
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(language['flag']!, style: TextStyle(fontSize: 24)),
            SizedBox(width: 12),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(language['name']!, style: TextStyle(color: Color(0xFF101727), fontSize: 16)),
                Text(language['code']!, style: TextStyle(color: Color(0xFF697282), fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildProgressDots(int count, {required int activeIndex}) {
    List<double> positions = [112.60, 171.32, 219.09, 267.85];
    return List.generate(count, (index) => Positioned(
      left: positions[index],
      top: 738.83,
      child: Container(
        width: 34.83,
        height: 7.48,
        decoration: ShapeDecoration(
          color: index == activeIndex ? Color(0xFF2C7C48) : Color(0xFFF3F3F3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    ));
  }

  Widget _buildNavigationButtons({VoidCallback? onBack, VoidCallback? onNext}) {
    return Stack(
      children: [
        if (onBack != null) Positioned(
          left: 29.86,
          top: 804.87,
          child: _buildNavButton('Back', Color(0xFFF3F3F3), Color(0xFFA1A1A1), onBack),
        ),
        Positioned(
          left: 210.98,
          top: 804.87,
          child: _buildNavButton('Next', onNext != null ? Color(0xFF2C7C48) : Color(0xFFF3F3F3), 
              onNext != null ? Colors.white : Color(0xFFA1A1A1), onNext ?? () {}),
        ),
      ],
    );
  }

  Widget _buildNavButton(String text, Color bgColor, Color textColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 171.17,
        height: 49.84,
        decoration: ShapeDecoration(color: bgColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        child: Center(child: Text(text, style: TextStyle(color: textColor, fontSize: 16, fontFamily: 'PT Sans', fontWeight: FontWeight.w700))),
      ),
    );
  }
}