import 'package:flutter/material.dart';
import 'user_registration.dart';
import 'localization_service.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  int _currentScreen = 0;
  String? _selectedLanguage;

  // Helper method to translate text using current global language
  String tr(String key) => LocalizationService.translate(key);

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
          image: const AssetImage('assets/sk.jpg'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.4), BlendMode.darken),
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            Positioned(
              left: 34,
              top: 150,
              child: SizedBox(
                width: MediaQuery.of(context).size.width - 68,
                child: Column(
                  children: [
                    Container(
                      width: 172,
                      height: 172,
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Image.asset('assets/Logo.png', fit: BoxFit.contain),
                    ),
                    _buildText(tr('smart_kisan'), 48, FontWeight.w700),
                    const SizedBox(height: 20),
                    _buildText(tr('empowering_farmers'), 20, FontWeight.w700),
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
                    tr('get_updates'),
                    16,
                    FontWeight.w700,
                    color: const Color(0xCCFFFEFE),
                  ),
                  const SizedBox(height: 40),
                  _buildButton(tr('get_started'), () => setState(() => _currentScreen = 1)),
                  const SizedBox(height: 20),
                  _buildOutlineButton(tr('log_in'), () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
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
      {'name': tr('English'), 'code': 'EN', 'flag': '🇬🇧'},
      {'name': tr('Nepali'), 'code': 'NE', 'flag': '🇳🇵'},
      {'name': tr('Hindi'), 'code': 'HI', 'flag': '🇮🇳'},
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Align(alignment: Alignment.topRight, child: Padding(padding: const EdgeInsets.all(20), child: _buildSkipButton())),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: SizedBox(
                        width: 159,
                        height: 153,
                        child: Image.asset('assets/Onboarding3.png', fit: BoxFit.contain),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                      child: _buildTitle(tr('choose_language'), 284),
                    ),
                    ...List.generate(3, (index) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: _buildLanguageCard(languages[index]),
                    )),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Container(
                        width: 35,
                        height: 7,
                        decoration: ShapeDecoration(
                          color: index == 0 ? const Color(0xFF2C7C48) : const Color(0xFFF3F3F3),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    )),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: _buildNavButton(tr('back'), const Color(0xFFF3F3F3), const Color(0xFFA1A1A1), 
                            () => setState(() => _currentScreen = 0)),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _buildNavButton(tr('next'), _selectedLanguage != null ? const Color(0xFF2C7C48) : const Color(0xFFF3F3F3), 
                            _selectedLanguage != null ? Colors.white : const Color(0xFFA1A1A1), 
                            _selectedLanguage != null ? () {
                              // Map selected language to language code
                              String languageCode = 'EN'; // default
                              if (_selectedLanguage == tr('Hindi')) {
                                languageCode = LocalizationService.HI;
                              } else if (_selectedLanguage == tr('Nepali')) {
                                languageCode = LocalizationService.NE;
                              } else {
                                languageCode = LocalizationService.EN;
                              }
                              
                              // Set language globally - this triggers app rebuild via main.dart listener
                              LocalizationService.setLanguage(languageCode);
                              
                              setState(() => _currentScreen = 2);
                            } : () {}),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingScreen(int index) {
    final data = [
      {
        'image': 'assets/Onboarding1.png',
        'title': 'Monitoring soil and plant',
        'desc': 'We aim to use optical (VIR) sensing to observe the fields and make timely crop management decisions.',
      },
      {
        'image': 'assets/Onboarding2.png',
        'title': 'Crop Selection',
        'desc': 'Our project can use AI & Machine learning to select the best crop according to the land and water resources.',
      },
      {
        'image': 'assets/Onboarding3.png',
        'title': 'Improve agriculture precision',
        'desc': 'We will use satellite imagery, image processing, deep learning, computer vision, and remote sensing to detect changes in the field and crops and solve the problems whenever they pop.',
      },
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Align(alignment: Alignment.topRight, child: Padding(padding: const EdgeInsets.all(20), child: _buildSkipButton())),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: SizedBox(
                        width: index == 1 ? 213.96 : 215,
                        height: index == 1 ? 294.04 : 236,
                        child: Image.asset(data[index]['image']!, fit: BoxFit.contain),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                      child: _buildTitle(tr(data[index]['title']!), 300),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: _buildDescription(tr(data[index]['desc']!)),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (dotIndex) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Container(
                        width: 35,
                        height: 7,
                        decoration: ShapeDecoration(
                          color: dotIndex == index + 1 ? const Color(0xFF2C7C48) : const Color(0xFFF3F3F3),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    )),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: _buildNavButton(tr('back'), const Color(0xFFF3F3F3), const Color(0xFFA1A1A1), 
                            () => setState(() => _currentScreen = index + 1)),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _buildNavButton(tr('next'), const Color(0xFF2C7C48), Colors.white, () => setState(() {
                          if (index < 2) {
                            _currentScreen = index + 3;
                          } else {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                          }
                        })),
                      ),
                    ],
                  ),
                ],
              ),
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
        shadows: [Shadow(blurRadius: 5, color: Colors.black.withValues(alpha: 0.3), offset: const Offset(1, 1))],
      ),
    );
  }

  Widget _buildButton(String text, VoidCallback onTap) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF00C850), Color(0xFF00A63D)]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
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
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(width: 1.5, color: const Color(0x33FFFEFE)),
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
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
      child: Text(tr('skip'), style: const TextStyle(color: Color(0xFF1E1E1E), fontSize: 24, fontFamily: 'PT Sans')),
    );
  }

  Widget _buildTitle(String text, double width) {
    return SizedBox(
      width: width,
      child: Text(text, style: const TextStyle(color: Color(0xFF1E1E1E), fontSize: 24, fontFamily: 'PT Sans', fontWeight: FontWeight.w700)),
    );
  }

  Widget _buildDescription(String text) {
    return SizedBox(
      width: 258,
      child: Text(
        text,
        textAlign: TextAlign.justify,
        style: const TextStyle(color: Color(0xFF9C9C9C), fontSize: 15, fontFamily: 'PT Sans'),
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
          color: _selectedLanguage == language['name'] ? const Color(0xFFE8F5E9) : const Color(0xFFFBFBFB),
          shape: RoundedRectangleBorder(
            side: BorderSide(width: 1.5, color: _selectedLanguage == language['name'] ? const Color(0xFF2C7C48) : const Color(0xFFAFA5A5)),
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(language['flag']!, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(language['name']!, style: const TextStyle(color: Color(0xFF101727), fontSize: 16)),
                Text(language['code']!, style: const TextStyle(color: Color(0xFF697282), fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Removed unused _buildProgressDots method

  Widget _buildNavButton(String text, Color bgColor, Color textColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: ShapeDecoration(color: bgColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        child: Center(child: Text(text, style: TextStyle(color: textColor, fontSize: 16, fontFamily: 'PT Sans', fontWeight: FontWeight.w700))),
      ),
    );
  }
}