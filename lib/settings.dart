import 'package:flutter/material.dart';
import 'package:smart_kisan/welcome_screen.dart';
import 'auth_service.dart'; // Import your auth service
import 'localization_service.dart'; // Import localization

// Colors used in the settings screens
const Color _lightGreen = Color(0xFFDCFCE7);
const Color _darkGreen = Color(0xFF008236);
const Color _white = Colors.white;
const Color _black = Colors.black;
const Color _gray = Color(0xFF4A5565);
const Color _lightGray = Color(0xFFF9FAFB);
const Color _borderGray = Color(0xFFE5E7EB);
const Color _textDark = Color(0xFF101727);
const Color _textGray = Color(0xFF495565);
const Color _textLightGray = Color(0xFF354152);
const Color _red = Color(0xFFE7000B);

// Main Settings Screen
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late String selectedLanguage;
  String selectedTheme = 'Dark Mode';
  String temperatureUnit = 'Celsius (°C)';
  String areaUnit = 'Acres';
  String volumeUnit = 'Liters';

  bool shareUsageData = true;
  bool analytics = true;
  bool locationTracking = true;
  bool twoFactorAuth = false;

  @override
  void initState() {
    super.initState();
    // Set initial language based on current language code
    final currentLang = LocalizationService.currentLanguage;
    selectedLanguage = currentLang == LocalizationService.EN
        ? 'English'
        : currentLang == LocalizationService.HI
            ? 'Hindi'
            : 'Nepali';
  }

  void _setLanguage(String languageName, String languageCode) {
    setState(() {
      selectedLanguage = languageName;
    });
    LocalizationService.setLanguage(languageCode);
    // Trigger app rebuild
    if (Navigator.of(context).canPop()) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightGray,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(),
              _buildProfileCard(),
              _buildNotificationCard(),
              _buildLanguageCard(),
              _buildThemeCard(),
              _buildUnitsCard(),
              _buildPrivacyCard(),
              _buildAboutCard(),
              _buildLogoutButton(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [_darkGreen, Color(0xFF00A63D)],
        ),
        boxShadow: [
          BoxShadow(color: _black.withValues(alpha: 0.1), blurRadius: 6, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.arrow_back, color: _white, size: 20),
                ),
              ),
              const SizedBox(width: 16),
              Text(LocalizationService.translate('Settings'),
                  style: const TextStyle(color: _white, fontSize: 24, fontFamily: 'Arimo', fontWeight: FontWeight.w400)),
            ],
          ),
          const SizedBox(height: 16),
          Text(LocalizationService.translate('Manage your account and preferences'),
              style: TextStyle(color: _white.withValues(alpha: 0.8), fontSize: 16, fontFamily: 'Arimo', fontWeight: FontWeight.w400)),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return _buildSettingsCard(
      icon: Icons.person,
      title: LocalizationService.translate('Profile Settings'),
      subtitle: LocalizationService.translate('Manage your personal information'),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF00A63D), _darkGreen],
                  ),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: const Center(child: Text('R', style: TextStyle(color: _white, fontSize: 30, fontFamily: 'Arimo', fontWeight: FontWeight.w400))),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ramesh Kumar', style: TextStyle(color: _textDark, fontSize: 16, fontFamily: 'Arimo', fontWeight: FontWeight.w400)),
                    SizedBox(height: 4),
                    Text('Kumar Organic Farm', style: TextStyle(color: _textGray, fontSize: 16, fontFamily: 'Arimo', fontWeight: FontWeight.w400)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildContactInfo(Icons.email, 'ramesh.kumar@example.com'),
              const SizedBox(height: 8),
              _buildContactInfo(Icons.phone, '+977 98XXXXXXXX'),
              const SizedBox(height: 8),
              _buildContactInfo(Icons.location_on, 'Kathmandu Valley, Nepal'),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileEditScreen())),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(color: _darkGreen, borderRadius: BorderRadius.circular(10)),
              child: Center(child: Text(LocalizationService.translate('Edit Profile'), style: const TextStyle(color: _white, fontSize: 16, fontFamily: 'Arimo', fontWeight: FontWeight.w400))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: _textGray, size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(color: _textGray, fontSize: 16, fontFamily: 'Arimo', fontWeight: FontWeight.w400))),
      ],
    );
  }

  Widget _buildNotificationCard() {
    return _buildSettingsCard(
      icon: Icons.notifications,
      title: LocalizationService.translate('Notification Settings'),
      subtitle: LocalizationService.translate('Manage your alerts and notifications'),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
                  Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(LocalizationService.translate('Active Notifications'), style: TextStyle(color: _textDark, fontSize: 18, fontFamily: 'Arimo', fontWeight: FontWeight.w400)),
                  const SizedBox(height: 4),
                  Text(LocalizationService.translate('You have 7 notifications enabled'), style: TextStyle(color: _textGray, fontSize: 16, fontFamily: 'Arimo', fontWeight: FontWeight.w400)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: _lightGreen, borderRadius: BorderRadius.circular(10)),
                child: Text(LocalizationService.translate('7/9'), style: const TextStyle(color: Color(0xFF0D532B), fontSize: 16, fontFamily: 'Arimo', fontWeight: FontWeight.w400)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationSettingsScreen())),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(color: _darkGreen, borderRadius: BorderRadius.circular(10)),
              child: Center(child: Text(LocalizationService.translate('Manage Notifications'), style: const TextStyle(color: _white, fontSize: 16, fontFamily: 'Arimo', fontWeight: FontWeight.w400))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard({required IconData icon, required String title, required String subtitle, required Widget child}) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: _black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _borderGray, width: 1.3))),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: _lightGreen, borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, color: _darkGreen, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(color: _textDark, fontSize: 20, fontFamily: 'Arimo', fontWeight: FontWeight.w400)),
                      Text(subtitle, style: const TextStyle(color: _textGray, fontSize: 16, fontFamily: 'Arimo', fontWeight: FontWeight.w400)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }

  Widget _buildLanguageCard() {
    return _buildSettingsCard(
      icon: Icons.language,
      title: LocalizationService.translate('Language'),
      subtitle: LocalizationService.translate('Select your preferred language'),
      child: Column(
        children: [
            _buildOption(LocalizationService.translate('English'), selectedLanguage == 'English',
              () => _setLanguage('English', LocalizationService.EN)),
          const SizedBox(height: 8),
            _buildOption(LocalizationService.translate('नेपाली'), selectedLanguage == 'Nepali',
              () => _setLanguage('Nepali', LocalizationService.NE)),
          const SizedBox(height: 8),
            _buildOption(LocalizationService.translate('Hindi'), selectedLanguage == 'Hindi',
              () => _setLanguage('Hindi', LocalizationService.HI)),
        ],
      ),
    );
  }

  Widget _buildThemeCard() {
    return _buildSettingsCard(
      icon: Icons.brightness_medium,
      title: LocalizationService.translate('Theme'),
      subtitle: LocalizationService.translate('Choose your display theme'),
      child: Column(
        children: [
          _buildOption(LocalizationService.translate('Light Mode'), selectedTheme == 'Light Mode', () => setState(() => selectedTheme = 'Light Mode')),
          const SizedBox(height: 8),
          _buildOption(LocalizationService.translate('Dark Mode'), selectedTheme == 'Dark Mode', () => setState(() => selectedTheme = 'Dark Mode')),
          const SizedBox(height: 8),
          _buildOption(LocalizationService.translate('Auto Mode'), selectedTheme == 'Auto Mode', () => setState(() => selectedTheme = 'Auto Mode')),
        ],
      ),
    );
  }

  Widget _buildOption(String text, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? _lightGreen : _lightGray,
          borderRadius: BorderRadius.circular(10),
          border: isSelected ? Border.all(color: _darkGreen, width: 1.3) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(text, style: TextStyle(color: isSelected ? const Color(0xFF0D532B) : _textDark, fontSize: 16, fontFamily: 'Arimo', fontWeight: FontWeight.w400)),
            if (isSelected) const Icon(Icons.check_circle, color: _darkGreen, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildUnitsCard() {
    return _buildSettingsCard(
      icon: Icons.straighten,
      title: LocalizationService.translate('Units of Measurement'),
      subtitle: LocalizationService.translate('Set your preferred units'),
      child: Column(
        children: [
          _buildUnitSection(LocalizationService.translate('Temperature'), temperatureUnit, [LocalizationService.translate('Celsius (°C)'), LocalizationService.translate('Fahrenheit (°F)')], (value) => setState(() => temperatureUnit = value)),
          const SizedBox(height: 16),
          _buildUnitSection(LocalizationService.translate('Area'), areaUnit, [LocalizationService.translate('Acres'), LocalizationService.translate('Hectares')], (value) => setState(() => areaUnit = value)),
          const SizedBox(height: 16),
          _buildUnitSection(LocalizationService.translate('Volume'), volumeUnit, [LocalizationService.translate('Liters'), LocalizationService.translate('Gallons')], (value) => setState(() => volumeUnit = value)),
        ],
      ),
    );
  }

  Widget _buildUnitSection(String title, String selected, List<String> options, ValueChanged<String> onSelect) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: _textLightGray, fontSize: 16, fontFamily: 'Arimo', fontWeight: FontWeight.w400)),
        const SizedBox(height: 8),
        Row(
          children: options.map((option) {
            return Expanded(
              child: GestureDetector(
                onTap: () => onSelect(option),
                child: Container(
                  margin: option == options.first ? null : const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: selected == option ? _lightGreen : _lightGray,
                    borderRadius: BorderRadius.circular(10),
                    border: selected == option ? Border.all(color: _darkGreen, width: 1.3) : null,
                  ),
                  child: Center(
                    child: Text(option,
                        style: TextStyle(
                            color: selected == option ? const Color(0xFF0D532B) : _textDark, fontSize: 16, fontFamily: 'Arimo', fontWeight: FontWeight.w400)),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPrivacyCard() {
    return _buildSettingsCard(
      icon: Icons.security,
      title: LocalizationService.translate('Privacy & Security'),
      subtitle: LocalizationService.translate('Manage your privacy settings'),
      child: Column(
        children: [
          _buildPrivacySwitch(LocalizationService.translate('Share Usage Data'), LocalizationService.translate('Help improve the app'), shareUsageData, (value) => setState(() => shareUsageData = value)),
          const SizedBox(height: 12),
          _buildPrivacySwitch(LocalizationService.translate('Analytics'), LocalizationService.translate('Allow analytics tracking'), analytics, (value) => setState(() => analytics = value)),
          const SizedBox(height: 12),
          _buildPrivacySwitch(LocalizationService.translate('Location Tracking'), LocalizationService.translate('For weather and field data'), locationTracking, (value) => setState(() => locationTracking = value)),
          const SizedBox(height: 12),
          _buildPrivacyItem(LocalizationService.translate('Change Password'), Icons.lock, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ChangePasswordScreen()))),
          const SizedBox(height: 12),
          _buildPrivacySwitch('Two-Factor Authentication', '', twoFactorAuth, (value) => setState(() => twoFactorAuth = value)),
        ],
      ),
    );
  }

  Widget _buildPrivacySwitch(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(color: _lightGray, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: _textDark, fontSize: 16, fontFamily: 'Arimo', fontWeight: FontWeight.w400)),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: _textGray, fontSize: 16, fontFamily: 'Arimo', fontWeight: FontWeight.w400)),
                ],
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged, activeThumbColor: _darkGreen),
        ],
      ),
    );
  }

  Widget _buildPrivacyItem(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(color: _lightGray, borderRadius: BorderRadius.circular(10)),
        child: Row(
          children: [
            Icon(icon, color: _textDark, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: const TextStyle(color: _textDark, fontSize: 16, fontFamily: 'Arimo', fontWeight: FontWeight.w400))),
            const Icon(Icons.chevron_right, color: _gray),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutCard() {
  return _buildSettingsCard(
    icon: Icons.info,
    title: LocalizationService.translate('About'),
    subtitle: LocalizationService.translate('App information and version'),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(LocalizationService.translate('Smart Kisan App'), style: const TextStyle(color: _textGray, fontSize: 16, fontFamily: 'Arimo', fontWeight: FontWeight.w400)),
        const SizedBox(height: 8),
        Text(LocalizationService.translate('Version 1.0.0'), style: const TextStyle(color: _textGray, fontSize: 16, fontFamily: 'Arimo', fontWeight: FontWeight.w400)),
        const SizedBox(height: 8),
        Text(LocalizationService.translate('© 2024 Smart Kisan. All rights reserved.'),
            style: const TextStyle(color: _textGray, fontSize: 16, fontFamily: 'Arimo', fontWeight: FontWeight.w400)),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onTap: _showLogoutConfirmation,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: _red,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [BoxShadow(color: _black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.logout, color: _white, size: 20),
              const SizedBox(width: 8),
              Text(LocalizationService.translate('Logout'), style: const TextStyle(color: _white, fontSize: 16, fontFamily: 'Arimo', fontWeight: FontWeight.w400)),
            ],
          ),
        ),
      ),
    );
  }

    void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(LocalizationService.translate('Logout'), style: const TextStyle(color: _textDark, fontFamily: 'Arimo')),
        content: Text(LocalizationService.translate('Are you sure you want to logout?'), style: const TextStyle(fontFamily: 'Arimo', fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: Text(LocalizationService.translate('Cancel'), style: const TextStyle(color: _gray, fontFamily: 'Arimo'))
          ),
          TextButton(
            onPressed: () async {
              // 1. Close the dialog
              Navigator.pop(context);
              
              // 2. Show a loading indicator briefly
              showDialog(
                context: context, 
                barrierDismissible: false,
                builder: (_) => const Center(child: CircularProgressIndicator())
              );

              // 3. Perform actual Firebase Sign Out
              await AuthService.instance.signOut();

              // 4. Navigate to Welcome Screen
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                (route) => false,
              );
            },
            child: Text(LocalizationService.translate('Logout'), style: const TextStyle(color: _red, fontFamily: 'Arimo')),
          ),
        ],
      ),
    );
  }
}

// Profile Edit Screen
class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  _ProfileEditScreenState createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'Ramesh Kumar');
  final _farmController = TextEditingController(text: 'Kumar Organic Farm');
  final _emailController = TextEditingController(text: 'ramesh.kumar@example.com');
  final _phoneController = TextEditingController(text: '+977 98XXXXXXXX');
  final _locationController = TextEditingController(text: 'Kathmandu Valley, Nepal');

  @override
  void dispose() {
    _nameController.dispose();
    _farmController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightGray,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader('Edit Profile'),
              Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [BoxShadow(color: _black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))],
                ),
                child: Form(
                  key: _formKey,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Column(
                          children: [
                            Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [Color(0xFF00A63D), _darkGreen],
                                ),
                                borderRadius: BorderRadius.circular(48),
                              ),
                              child: const Center(child: Text('R', style: TextStyle(color: _white, fontSize: 36, fontFamily: 'Arimo', fontWeight: FontWeight.w400))),
                            ),
                            const SizedBox(height: 16),
                            GestureDetector(
                              onTap: () {}, // Handle change photo
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(color: _lightGreen, borderRadius: BorderRadius.circular(10)),
                                child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.camera_alt, color: _darkGreen, size: 16),
                                      const SizedBox(width: 8),
                                      Text(LocalizationService.translate('Change Photo'), style: const TextStyle(color: _darkGreen, fontSize: 16, fontFamily: 'Arimo', fontWeight: FontWeight.w400)),
                                    ],
                                  ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildTextField(LocalizationService.translate('Full Name'), _nameController),
                        const SizedBox(height: 16),
                        _buildTextField(LocalizationService.translate('Farm Name'), _farmController),
                        const SizedBox(height: 16),
                        _buildTextField(LocalizationService.translate('Email'), _emailController),
                        const SizedBox(height: 16),
                        _buildTextField(LocalizationService.translate('Phone Number'), _phoneController),
                        const SizedBox(height: 16),
                        _buildTextField(LocalizationService.translate('Location'), _locationController),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  if (_formKey.currentState!.validate()) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(LocalizationService.translate('Profile updated successfully!')), backgroundColor: _darkGreen),
                                    );
                                    Navigator.pop(context);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  decoration: BoxDecoration(color: _darkGreen, borderRadius: BorderRadius.circular(10)),
                                    child: Center(
                                      child: Text(LocalizationService.translate('Save Changes'), style: const TextStyle(color: _white, fontSize: 16, fontFamily: 'Arimo', fontWeight: FontWeight.w400))),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  decoration: BoxDecoration(color: const Color(0xFFD1D5DC), borderRadius: BorderRadius.circular(10)),
                                  child: Center(child: Text(LocalizationService.translate('Cancel'), style: const TextStyle(color: _textLightGray, fontSize: 16, fontFamily: 'Arimo', fontWeight: FontWeight.w400))),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(color: _white, border: Border(bottom: BorderSide(color: _borderGray, width: 1.3))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.arrow_back, color: _textDark),
            ),
          ),
          Text(title, style: const TextStyle(color: _textDark, fontSize: 16, fontFamily: 'Arimo', fontWeight: FontWeight.w400)),
          Container(width: 36, height: 36, decoration: BoxDecoration(borderRadius: BorderRadius.circular(8))),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: _textLightGray, fontSize: 16, fontFamily: 'Arimo', fontWeight: FontWeight.w400)),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          style: const TextStyle(color: _textDark, fontSize: 16, fontFamily: 'Arimo', fontWeight: FontWeight.w400),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFD0D5DB), width: 1.3)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFD0D5DB), width: 1.3)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _darkGreen, width: 1.3)),
          ),
          validator: (value) => value == null || value.isEmpty ? 'Please enter $label' : null,
        ),
      ],
    );
  }
}

// Change Password Screen
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  _ChangePasswordScreenState createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _oldPasswordVisible = false;
  bool _newPasswordVisible = false;
  bool _confirmPasswordVisible = false;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightGray,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header for Change Password Screen
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: _white,
                  border: Border(bottom: BorderSide(color: _borderGray, width: 1.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.arrow_back, color: _textDark),
                      ),
                    ),
                    const Text(
                      'Change Password',
                      style: TextStyle(
                        color: _textDark,
                        fontSize: 16,
                        fontFamily: 'Arimo',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
                    ),
                  ],
                ),
              ),
              
              Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [BoxShadow(color: _black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))],
                ),
                child: Form(
                  key: _formKey,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildPasswordField('Old Password', _oldPasswordController, _oldPasswordVisible, () => setState(() => _oldPasswordVisible = !_oldPasswordVisible)),
                        const SizedBox(height: 16),
                        _buildPasswordField('New Password', _newPasswordController, _newPasswordVisible, () => setState(() => _newPasswordVisible = !_newPasswordVisible)),
                        const SizedBox(height: 16),
                        _buildPasswordField('Confirm New Password', _confirmPasswordController, _confirmPasswordVisible,
                            () => setState(() => _confirmPasswordVisible = !_confirmPasswordVisible),
                            validator: (value) => value != _newPasswordController.text ? 'Passwords do not match' : null),
                        const SizedBox(height: 16),
                        _buildPasswordRequirements(),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  if (_formKey.currentState!.validate()) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(LocalizationService.translate('Password changed successfully!')), backgroundColor: _darkGreen, duration: const Duration(seconds: 2)),
                                    );
                                    Future.delayed(const Duration(seconds: 2), () => Navigator.pop(context));
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  decoration: BoxDecoration(color: _darkGreen, borderRadius: BorderRadius.circular(10)),
                                  child: Center(child: Text(LocalizationService.translate('Change Password'), style: const TextStyle(color: _white, fontSize: 16, fontFamily: 'Arimo', fontWeight: FontWeight.w400))),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  decoration: BoxDecoration(color: const Color(0xFFD1D5DC), borderRadius: BorderRadius.circular(10)),
                                  child: Center(child: Text(LocalizationService.translate('Cancel'), style: const TextStyle(color: _textLightGray, fontSize: 16, fontFamily: 'Arimo', fontWeight: FontWeight.w400))),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField(String label, TextEditingController controller, bool isVisible, VoidCallback onToggle, {String? Function(String?)? validator}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: _textLightGray, fontSize: 16, fontFamily: 'Arimo', fontWeight: FontWeight.w400)),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          obscureText: !isVisible,
          style: const TextStyle(color: _textDark, fontSize: 16, fontFamily: 'Arimo', fontWeight: FontWeight.w400),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFD0D5DB), width: 1.3)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFD0D5DB), width: 1.3)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _darkGreen, width: 1.3)),
            suffixIcon: IconButton(icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off, color: _gray), onPressed: onToggle),
          ),
          validator: validator ??
              (value) {
                if (value == null || value.isEmpty) return 'Please enter $label';
                if (label == 'New Password' && value.length < 6) return 'Password must be at least 6 characters';
                return null;
              },
        ),
      ],
    );
  }

  Widget _buildPasswordRequirements() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFB8F7CF), width: 1.3)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(LocalizationService.translate('Password Requirements:'), style: const TextStyle(color: Color(0xFF0D532B), fontSize: 14, fontFamily: 'Arimo', fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _buildRequirement('At least 6 characters'),
          _buildRequirement('Contains uppercase and lowercase letters'),
          _buildRequirement('Contains at least one number'),
          _buildRequirement('Contains at least one special character'),
        ],
      ),
    );
  }

  Widget _buildRequirement(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(children: [
        const Icon(Icons.check_circle, color: _darkGreen, size: 16),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(color: _darkGreen, fontSize: 14, fontFamily: 'Arimo', fontWeight: FontWeight.w400)),
      ]),
    );
  }
}

// Notification Settings Screen
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  _NotificationSettingsScreenState createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  Map<String, bool> alertTypes = {
    'Weather Alerts': true,
    'Pest & Disease Alerts': true,
    'Irrigation Reminders': true,
    'Crop Health Updates': true,
    'Market Prices': false,
    'General Updates': true,
  };

  Map<String, bool> notificationChannels = {
    'Email Notifications': true,
    'Push Notifications': true,
    'SMS Notifications': false,
  };

  String _getAlertDescription(String type) {
    switch (type) {
      case 'Weather Alerts':
        return 'Get notified about weather changes, rain forecasts, and temperature alerts';
      case 'Pest & Disease Alerts':
        return 'Important pest detection notifications and disease outbreak warnings';
      case 'Irrigation Reminders':
        return 'Scheduled irrigation notifications and soil moisture alerts';
      case 'Crop Health Updates':
        return 'Monitor your crop health status and growth stage updates';
      case 'Market Prices':
        return 'Stay updated on crop prices and market trends';
      case 'General Updates':
        return 'App updates, farming tips, and seasonal recommendations';
      default:
        return '';
    }
  }

  String _getChannelDescription(String channel) {
    switch (channel) {
      case 'Email Notifications':
        return 'Receive alerts and updates via email';
      case 'Push Notifications':
        return 'In-app and mobile push notifications';
      case 'SMS Notifications':
        return 'Receive critical alerts via text message';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    int enabledCount = alertTypes.values.where((value) => value).length + notificationChannels.values.where((value) => value).length;

    return Scaffold(
      backgroundColor: _lightGray,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader('Notification Settings', 'Manage your alerts and notifications'),
              _buildSummaryCard(enabledCount),
              _buildSectionCard('Alert Types', 'Choose what alerts you want to receive', Icons.notifications_active, alertTypes, _getAlertDescription),
              _buildSectionCard('Notification Channels', 'Choose how you want to receive notifications', Icons.notifications, notificationChannels, _getChannelDescription),
              _buildQuickActions(),
              _buildInfoCard(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: [_darkGreen, Color(0xFF00A63D)]),
        boxShadow: [BoxShadow(color: _black.withValues(alpha: 0.1), blurRadius: 6, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(color: _white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                  child: const Icon(Icons.arrow_back, color: _white, size: 16),
                ),
              ),
              const SizedBox(width: 16),
              Text(title, style: const TextStyle(color: _white, fontSize: 24, fontFamily: 'Arimo', fontWeight: FontWeight.w400)),
            ],
          ),
          const SizedBox(height: 16),
          Text(subtitle, style: TextStyle(color: _white.withValues(alpha: 0.8), fontSize: 16, fontFamily: 'Arimo', fontWeight: FontWeight.w400)),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(int enabledCount) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: _black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(LocalizationService.translate('Active Notifications'), style: const TextStyle(color: _textDark, fontSize: 18, fontFamily: 'Arimo', fontWeight: FontWeight.w400)),
              const SizedBox(height: 4),
              Text(LocalizationService.translate('You have {count} notifications enabled').replaceAll('{count}', '$enabledCount'), style: const TextStyle(color: _textGray, fontSize: 16, fontFamily: 'Arimo', fontWeight: FontWeight.w400)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: _lightGreen, borderRadius: BorderRadius.circular(10)),
            child: Text('$enabledCount/9', style: const TextStyle(color: Color(0xFF0D532B), fontSize: 16, fontFamily: 'Arimo', fontWeight: FontWeight.w400)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, String subtitle, IconData icon, Map<String, bool> items, String Function(String) getDescription) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: _black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _borderGray, width: 1.3))),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: _lightGreen, borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, color: _darkGreen, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(color: _textDark, fontSize: 20, fontFamily: 'Arimo', fontWeight: FontWeight.w400)),
                      Text(subtitle, style: const TextStyle(color: _textGray, fontSize: 16, fontFamily: 'Arimo', fontWeight: FontWeight.w400)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: items.entries.map((entry) {
                return _buildNotificationItem(entry.key, getDescription(entry.key), entry.value, (value) => setState(() => items[entry.key] = value));
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(String title, String description, bool value, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: _lightGray, borderRadius: BorderRadius.circular(10)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(title, style: const TextStyle(color: _textDark, fontSize: 16, fontFamily: 'Arimo', fontWeight: FontWeight.w400)),
                    const SizedBox(width: 8),
                    if (value)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: _lightGreen, borderRadius: BorderRadius.circular(4)),
                        child: Text(LocalizationService.translate('Active'), style: const TextStyle(color: _darkGreen, fontSize: 12, fontFamily: 'Arimo', fontWeight: FontWeight.w400)),
                      ),
                  ],
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(description, style: const TextStyle(color: _textGray, fontSize: 16, fontFamily: 'Arimo', fontWeight: FontWeight.w400)),
                ],
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged, activeThumbColor: _darkGreen),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: _black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(LocalizationService.translate('Quick Actions'), style: const TextStyle(color: _textDark, fontSize: 16, fontFamily: 'Arimo', fontWeight: FontWeight.w400)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() {
                    alertTypes.forEach((key, value) => alertTypes[key] = true);
                    notificationChannels.forEach((key, value) => notificationChannels[key] = true);
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(color: _darkGreen, borderRadius: BorderRadius.circular(10)),
                    child: Center(child: Text(LocalizationService.translate('Enable All'), style: const TextStyle(color: _white, fontSize: 16, fontFamily: 'Arimo', fontWeight: FontWeight.w400))),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() {
                    alertTypes.forEach((key, value) => alertTypes[key] = false);
                    notificationChannels.forEach((key, value) => notificationChannels[key] = false);
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(color: const Color(0xFFD1D5DC), borderRadius: BorderRadius.circular(10)),
                    child: Center(child: Text(LocalizationService.translate('Disable All'), style: const TextStyle(color: _textLightGray, fontSize: 16, fontFamily: 'Arimo', fontWeight: FontWeight.w400))),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFB8F7CF), width: 1.3),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(color: const Color(0xFF0D532B), borderRadius: BorderRadius.circular(3)),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('About Notifications', style: TextStyle(color: Color(0xFF0D532B), fontSize: 16, fontFamily: 'Arimo', fontWeight: FontWeight.w400)),
                SizedBox(height: 4),
                Text(
                  'We recommend keeping critical alerts like weather and pest notifications enabled to stay informed about important farming conditions.',
                  style: TextStyle(color: _darkGreen, fontSize: 16, fontFamily: 'Arimo', fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}