import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
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

  /// Purpose: Acts as a local router for the onboarding sequence.
  /// Inputs: None (relies on _currentScreen state variable).
  /// Outputs: Returns the appropriate Widget for the current onboarding step.
  Widget _buildCurrentScreen() {
    // 1. Define the linear sequence of onboarding screens.
    final screens = [
      _buildWelcomeScreen(),
      _buildLanguageSelectionScreen(),
      _buildOnboardingScreen(0),
      _buildOnboardingScreen(1),
      _buildOnboardingScreen(2),
    ];
    // 2. Safely clamp the index to prevent out-of-bounds array exceptions during navigation.
    return screens[_currentScreen.clamp(0, screens.length - 1)];
  }

  /// Purpose: Renders the initial splash/welcome screen with branding and entry points.
  /// Inputs: None.
  /// Outputs: A Container widget containing the logo, tagline, and call-to-action buttons.
  Widget _buildWelcomeScreen() {
    return Container(
      // 1. Set the fullscreen agricultural background image with a dark overlay for text contrast.
      decoration: BoxDecoration(
        image: DecorationImage(
          image: const AssetImage('assets/sk.jpg'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Theme.of(context).shadowColor.withOpacity(0.4), BlendMode.darken),
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            // 2. Position the logo and branding text at the top left of the screen.
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
            // 3. Position the call-to-action buttons (Get Started, Log In) at the bottom.
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
                    color: (Theme.of(context).brightness == Brightness.dark ? Theme.of(context).textTheme.bodyMedium?.color : const Color(0xFF9C9C9C)) ?? Colors.grey,
                  ),
                  const SizedBox(height: 40),
                  // 4. "Get Started" pushes the local router state to the language selection screen.
                  _buildButton(tr('get_started'), () => setState(() => _currentScreen = 1)),
                  const SizedBox(height: 20),
                  // 5. "Log In" explicitly routes out of the onboarding flow to the LoginScreen.
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

  /// Purpose: Renders the language localization configuration screen.
  /// Inputs: None.
  /// Outputs: A Scaffold allowing the user to select and save their preferred UI language.
  Widget _buildLanguageSelectionScreen() {
    // 1. Define supported localizations.
    final languages = [
      {'name': tr('English'), 'code': 'EN', 'flag': '🇬🇧'},
      {'name': tr('Nepali'), 'code': 'NE', 'flag': '🇳🇵'},
      {'name': tr('Hindi'), 'code': 'HI', 'flag': '🇮🇳'},
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).scaffoldBackgroundColor : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 2. Allow skipping straight to login, bypassing onboarding.
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
                    // 3. Dynamically generate selection cards for each supported language.
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
                  // 4. Progress indicator dots.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Container(
                        width: 35,
                        height: 7,
                        decoration: ShapeDecoration(
                          // Highlight the first dot for the language screen.
                          color: index == 0 ? Theme.of(context).colorScheme.primary : Theme.of(context).dividerColor.withOpacity(0.1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    )),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 5. 'Back' button returns to the welcome screen.
                      Expanded(
                        child: _buildNavButton(tr('back'), Theme.of(context).dividerColor.withOpacity(0.1), (Theme.of(context).brightness == Brightness.dark ? Theme.of(context).textTheme.bodyMedium?.color : const Color(0xFF9C9C9C)) ?? Colors.grey, 
                            () => setState(() => _currentScreen = 0)),
                      ),
                      const SizedBox(width: 15),
                      // 6. 'Next' button validates selection and commits the locale choice.
                      Expanded(
                        child: _buildNavButton(tr('next'), _selectedLanguage != null ? Theme.of(context).colorScheme.primary : Theme.of(context).dividerColor.withOpacity(0.1), 
                            _selectedLanguage != null ? Theme.of(context).cardColor : (Theme.of(context).brightness == Brightness.dark ? Theme.of(context).textTheme.bodyMedium?.color : const Color(0xFF9C9C9C)) ?? Colors.grey, 
                            _selectedLanguage != null ? () {
                              // 7. Map the UI selection back to strict language codes.
                              String languageCode = 'EN'; // default
                              if (_selectedLanguage == tr('Hindi')) {
                                languageCode = LocalizationService.HI;
                              } else if (_selectedLanguage == tr('Nepali')) {
                                languageCode = LocalizationService.NE;
                              } else {
                                languageCode = LocalizationService.EN;
                              }
                              
                              // 8. Commit language choice to SharedPreferences via the singleton service.
                              LocalizationService.setLanguage(languageCode);
                              
                              // 9. Inform the easy_localization package to instantly rebuild the UI with the new locale.
                              context.setLocale(Locale(languageCode));
                              
                              // 10. Proceed to the feature-showcase phase of onboarding.
                              setState(() => _currentScreen = 2);
                            } : () {}), // Disabled if no language is selected.
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

  /// Purpose: Renders one of three sequential feature-showcase screens.
  /// Inputs: index (int) representing the specific onboarding step (0, 1, or 2).
  /// Outputs: A Scaffold containing the relevant illustration, title, and description.
  Widget _buildOnboardingScreen(int index) {
    // 1. Centralized content dictionary for the onboarding carousel.
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
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).scaffoldBackgroundColor : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 2. Universal skip button routing immediately to Login.
            Align(alignment: Alignment.topRight, child: Padding(padding: const EdgeInsets.all(20), child: _buildSkipButton())),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: SizedBox(
                        // 3. Hardcoded dimension adjustments to ensure consistent image aspect ratios.
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
                  // 4. Dot indicator logic mapping to `index + 1` because language selection was index 0.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (dotIndex) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Container(
                        width: 35,
                        height: 7,
                        decoration: ShapeDecoration(
                          color: dotIndex == index + 1 ? Theme.of(context).colorScheme.primary : Theme.of(context).dividerColor.withOpacity(0.1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    )),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 5. Back navigation. Reverts to previous screen.
                      Expanded(
                        child: _buildNavButton(tr('back'), Theme.of(context).dividerColor.withOpacity(0.1), (Theme.of(context).brightness == Brightness.dark ? Theme.of(context).textTheme.bodyMedium?.color : const Color(0xFF9C9C9C)) ?? Colors.grey, 
                            () => setState(() => _currentScreen = index + 1)), // +1 offset due to Language Selection
                      ),
                      const SizedBox(width: 15),
                      // 6. Forward navigation. If on the final screen, break out of local routing and push LoginScreen.
                      Expanded(
                        child: _buildNavButton(tr('next'), Theme.of(context).colorScheme.primary, Theme.of(context).cardColor, () => setState(() {
                          if (index < 2) {
                            _currentScreen = index + 3; // Step forward (+2 offset for Welcome + Language, +1 for next)
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
  Widget _buildText(String text, double fontSize, FontWeight weight, {Color? color}) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: color ?? Theme.of(context).cardColor,
        fontSize: fontSize,
        fontFamily: 'Arimo',
        fontWeight: weight,
        height: 1.4,
        shadows: [Shadow(blurRadius: 5, color: Theme.of(context).shadowColor.withOpacity(0.3), offset: const Offset(1, 1))],
      ),
    );
  }

  Widget _buildButton(String text, VoidCallback onTap) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.primary]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Theme.of(context).shadowColor.withOpacity(0.1), blurRadius: 6, offset: const Offset(0, 4)),
          BoxShadow(color: Theme.of(context).shadowColor.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 10)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Center(child: _buildText(text, 16, FontWeight.w700, color: Theme.of(context).colorScheme.onPrimary)),
        ),
      ),
    );
  }

  Widget _buildOutlineButton(String text, VoidCallback onTap) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).cardColor.withValues(alpha: 0.1) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(width: 1.5, color: Theme.of(context).dividerColor.withOpacity(0.2)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Center(child: _buildText(text, 16, FontWeight.w700, color: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).textTheme.bodyLarge?.color : const Color(0xFF1E1E1E))),
        ),
      ),
    );
  }

  Widget _buildSkipButton() {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
      child: Text(tr('skip'), style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).textTheme.bodyLarge?.color : const Color(0xFF1E1E1E), fontSize: 24, fontFamily: 'PT Sans')),
    );
  }

  Widget _buildTitle(String text, double width) {
    return SizedBox(
      width: width,
      child: Text(text, style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).textTheme.bodyLarge?.color : const Color(0xFF1E1E1E), fontSize: 24, fontFamily: 'PT Sans', fontWeight: FontWeight.w700)),
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
          color: _selectedLanguage == language['name'] ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(
            side: BorderSide(width: 1.5, color: _selectedLanguage == language['name'] ? Theme.of(context).colorScheme.primary : Theme.of(context).dividerColor),
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
                Text(language['name']!, style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).textTheme.bodyLarge?.color : const Color(0xFF1E1E1E), fontSize: 16)),
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