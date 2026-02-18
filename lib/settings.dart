import 'package:flutter/material.dart';
import 'package:smart_kisan/welcome_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:convert' as json;
import 'auth_service.dart';
import 'localization_service.dart';
import 'main.dart';

// ========== MODELS ==========
class UserProfile {
  final String userId;
  final String fullName;
  final String farmName;
  final String email;
  final String phone;
  final String location;
  final String? profileImageUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;

  UserProfile({
    required this.userId,
    required this.fullName,
    required this.farmName,
    required this.email,
    required this.phone,
    required this.location,
    this.profileImageUrl,
    required this.createdAt,
    this.updatedAt,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map, String userId) {
    return UserProfile(
      userId: userId,
      fullName: map['fullName'] ?? '',
      farmName: map['farmName'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      location: map['location'] ?? '',
      profileImageUrl: map['profileImageUrl'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'fullName': fullName,
      'farmName': farmName,
      'email': email,
      'phone': phone,
      'location': location,
      'profileImageUrl': profileImageUrl,
      'createdAt': createdAt,
      'updatedAt': updatedAt ?? DateTime.now(),
    };
  }

  UserProfile copyWith({
    String? fullName,
    String? farmName,
    String? email,
    String? phone,
    String? location,
    String? profileImageUrl,
  }) {
    return UserProfile(
      userId: userId,
      fullName: fullName ?? this.fullName,
      farmName: farmName ?? this.farmName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

class NotificationPreferences {
  final Map<String, bool> alertTypes;
  final Map<String, bool> notificationChannels;

  NotificationPreferences({
    required this.alertTypes,
    required this.notificationChannels,
  });

  factory NotificationPreferences.defaultPreferences() {
    return NotificationPreferences(
      alertTypes: {
        'Weather Alerts': true,
        'Pest & Disease Alerts': true,
        'Irrigation Reminders': true,
        'Crop Health Updates': true,
        'General Updates': true,
      },
      notificationChannels: {
        'Push Notifications': true,
        'Email Notifications': true,
      },
    );
  }

  factory NotificationPreferences.fromMap(Map<String, dynamic> map) {
    return NotificationPreferences(
      alertTypes: Map<String, bool>.from(map['alertTypes'] ?? {}),
      notificationChannels: Map<String, bool>.from(map['notificationChannels'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'alertTypes': alertTypes,
      'notificationChannels': notificationChannels,
    };
  }
}

// ========== BACKEND SERVICE (INTEGRATED) ==========
class _SettingsBackend {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();

  String get _userId => _auth.currentUser?.uid ?? '';

  // ===== USER PROFILE =====
  Future<UserProfile?> getUserProfile() async {
    try {
      if (_userId.isEmpty) return null;
      final doc = await _firestore.collection('users').doc(_userId).get();
      if (!doc.exists) return null;
      return UserProfile.fromMap(doc.data()!, _userId);
    } catch (e) {
      print('❌ Error getting profile: $e');
      return null;
    }
  }

  Future<bool> updateUserProfile({
    required String fullName,
    required String farmName,
    required String email,
    required String phone,
    required String location,
  }) async {
    try {
      if (_userId.isEmpty) return false;
      
      await _firestore.collection('users').doc(_userId).set({
        'fullName': fullName,
        'farmName': farmName,
        'email': email,
        'phone': phone,
        'location': location,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      await _auth.currentUser?.updateDisplayName(fullName);
      print('✅ Profile updated');
      return true;
    } catch (e) {
      print('❌ Error updating profile: $e');
      return false;
    }
  }

  // ===== IMAGE HANDLING =====
  Future<File?> pickImageFromCamera() async {
    try {
      // Request camera permission
      final cameraStatus = await Permission.camera.request();
      if (cameraStatus.isDenied) {
        print('❌ Camera permission denied');
        throw Exception('Camera permission is required to take photos');
      }
      if (cameraStatus.isPermanentlyDenied) {
        print('❌ Camera permission permanently denied');
        openAppSettings();
        throw Exception('Camera permission is permanently denied. Please enable it in settings.');
      }

      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxHeight: 1024,
        maxWidth: 1024,
      );
      if (pickedFile == null) {
        print('ℹ️ User cancelled camera selection');
        return null;
      }
      print('✅ Image picked from camera: ${pickedFile.path}');
      return File(pickedFile.path);
    } catch (e) {
      print('❌ Camera error: $e');
      throw Exception('Failed to pick image from camera: $e');
    }
  }

  Future<File?> pickImageFromGallery() async {
    try {
      // Request storage permission - use storage instead of photos for broader compatibility
      final storageStatus = await Permission.storage.request();
      if (storageStatus.isDenied) {
        print('❌ Storage permission denied');
        throw Exception('Storage permission is required to access gallery');
      }
      if (storageStatus.isPermanentlyDenied) {
        print('❌ Storage permission permanently denied');
        openAppSettings();
        throw Exception('Storage permission is permanently denied. Please enable it in settings.');
      }

      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxHeight: 1024,
        maxWidth: 1024,
      );
      if (pickedFile == null) {
        print('ℹ️ User cancelled gallery selection');
        return null;
      }
      print('✅ Image picked from gallery: ${pickedFile.path}');
      return File(pickedFile.path);
    } catch (e) {
      print('❌ Gallery error: $e');
      throw Exception('Failed to pick image from gallery: $e');
    }
  }

  // store profile image path locally and in Firestore if needed
  Future<String> uploadProfileImage(dynamic imageFile) async {
    try {
      if (_userId.isEmpty) throw Exception('No user logged in');
      File file;
      if (imageFile is File) {
        file = imageFile;
      } else if (imageFile is String) {
        file = File(imageFile);
      } else {
        throw Exception('Invalid image file type');
      }

      if (!file.existsSync()) throw Exception('File does not exist');

      // copy file to app documents directory with a unique name to force reload
      final dir = await getApplicationDocumentsDirectory();
      // remove any previous profile images for this user
      final existing = dir.listSync().where((f) =>
          f is File && f.path.contains('profile_${_userId}')).toList();
      for (final f in existing) {
        try {
          (f as File).deleteSync();
        } catch (_) {}
      }
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final dest = File('${dir.path}/profile_${_userId}_$timestamp.jpg');
      await file.copy(dest.path);

      // save path in shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_image_path', dest.path);

      // optionally update Firestore user record with local path or marker
      await _firestore.collection('users').doc(_userId).set({
        'profileImagePath': dest.path,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return dest.path;
    } catch (e) {
      print('❌ Upload error: $e');
      throw Exception('Failed to save profile image: $e');
    }
  }

  Future<String?> getProfileImageUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final path = prefs.getString('profile_image_path');
      if (path != null && File(path).existsSync()) {
        return path;
      }
      return null;
    } catch (e) {
      print('❌ Error getting profile image path: $e');
      return null;
    }
  }

  Future<void> deleteProfileImage() async {
    try {
      if (_userId.isEmpty) throw Exception('No user');
      final prefs = await SharedPreferences.getInstance();
      final path = prefs.getString('profile_image_path');
      if (path != null) {
        final f = File(path);
        if (f.existsSync()) await f.delete();
        await prefs.remove('profile_image_path');
      }
      await _firestore.collection('users').doc(_userId).update({
        'profileImagePath': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ Image deleted');
    } catch (e) {
      print('❌ Delete error: $e');
      throw Exception('Failed to delete image');
    }
  }

  // ===== PREFERENCES =====
  Future<String> getThemePreference() async {
    try {
      if (_userId.isEmpty) return 'Dark Mode';
      final doc = await _firestore.collection('preferences').doc(_userId).get();
      return doc.data()?['theme'] ?? 'Dark Mode';
    } catch (e) {
      return 'Dark Mode';
    }
  }

  Future<bool> setThemePreference(String theme) async {
    try {
      if (_userId.isEmpty) return false;
      await _firestore.collection('preferences').doc(_userId).set(
        {'theme': theme, 'updatedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
      return true;
    } catch (e) {
      print('❌ Theme error: $e');
      return false;
    }
  }

  Future<Map<String, String>> getUnitsPreferences() async {
    try {
      if (_userId.isEmpty) {
        return {'temperature': 'Celsius (°C)', 'area': 'Acres', 'volume': 'Liters'};
      }
      final doc = await _firestore.collection('preferences').doc(_userId).get();
      if (!doc.exists) {
        return {'temperature': 'Celsius (°C)', 'area': 'Acres', 'volume': 'Liters'};
      }
      return {
        'temperature': doc.data()?['temperature'] ?? 'Celsius (°C)',
        'area': doc.data()?['area'] ?? 'Acres',
        'volume': doc.data()?['volume'] ?? 'Liters',
      };
    } catch (e) {
      return {'temperature': 'Celsius (°C)', 'area': 'Acres', 'volume': 'Liters'};
    }
  }

  Future<bool> setTemperatureUnit(String unit) async {
    try {
      if (_userId.isEmpty) return false;
      await _firestore.collection('preferences').doc(_userId).set(
        {'temperature': unit, 'updatedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> setAreaUnit(String unit) async {
    try {
      if (_userId.isEmpty) return false;
      await _firestore.collection('preferences').doc(_userId).set(
        {'area': unit, 'updatedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> setVolumeUnit(String unit) async {
    try {
      if (_userId.isEmpty) return false;
      await _firestore.collection('preferences').doc(_userId).set(
        {'volume': unit, 'updatedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, bool>> getPrivacySettings() async {
    try {
      if (_userId.isEmpty) {
        return {'shareUsageData': true, 'analytics': true, 'locationTracking': true};
      }
      final doc = await _firestore.collection('privacy').doc(_userId).get();
      if (!doc.exists) {
        return {'shareUsageData': true, 'analytics': true, 'locationTracking': true};
      }
      return {
        'shareUsageData': doc.data()?['shareUsageData'] ?? true,
        'analytics': doc.data()?['analytics'] ?? true,
        'locationTracking': doc.data()?['locationTracking'] ?? true,
      };
    } catch (e) {
      return {'shareUsageData': true, 'analytics': true, 'locationTracking': true};
    }
  }

  Future<bool> updatePrivacySettings({
    required bool shareUsageData,
    required bool analytics,
    required bool locationTracking,
  }) async {
    try {
      if (_userId.isEmpty) return false;
      await _firestore.collection('privacy').doc(_userId).set({
        'shareUsageData': shareUsageData,
        'analytics': analytics,
        'locationTracking': locationTracking,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> get2FAStatus() async {
    try {
      if (_userId.isEmpty) return false;
      final doc = await _firestore.collection('security').doc(_userId).get();
      return doc.data()?['twoFactorAuth'] ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> update2FAStatus(bool enabled) async {
    try {
      if (_userId.isEmpty) return false;
      await _firestore.collection('security').doc(_userId).set({
        'twoFactorAuth': enabled,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final cred = EmailAuthProvider.credential(
        email: user.email ?? '',
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(newPassword);
      print('✅ Password changed');
      return true;
    } catch (e) {
      print('❌ Password change error: $e');
      return false;
    }
  }

  Future<NotificationPreferences?> getNotificationPreferences() async {
    try {
      if (_userId.isEmpty) return NotificationPreferences.defaultPreferences();
      final doc = await _firestore.collection('notification_preferences').doc(_userId).get();
      if (!doc.exists) return NotificationPreferences.defaultPreferences();
      return NotificationPreferences.fromMap(doc.data()!);
    } catch (e) {
      return NotificationPreferences.defaultPreferences();
    }
  }

  Future<bool> updateNotificationPreferences(NotificationPreferences preferences) async {
    try {
      if (_userId.isEmpty) return false;
      await _firestore.collection('notification_preferences').doc(_userId).set({
        ...preferences.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteAccount({required String password}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final cred = EmailAuthProvider.credential(
        email: user.email ?? '',
        password: password,
      );

      await user.reauthenticateWithCredential(cred);

      await _firestore.collection('users').doc(_userId).delete();
      await _firestore.collection('preferences').doc(_userId).delete();
      await _firestore.collection('privacy').doc(_userId).delete();
      await _firestore.collection('security').doc(_userId).delete();

      await user.delete();
      print('✅ Account deleted');
      return true;
    } catch (e) {
      print('❌ Account deletion error: $e');
      return false;
    }
  }

  Future<bool> exportUserData() async {
    try {
      if (_userId.isEmpty) return false;

      final userData = await _firestore.collection('users').doc(_userId).get();
      final prefsData = await _firestore.collection('preferences').doc(_userId).get();
      final privacyData = await _firestore.collection('privacy').doc(_userId).get();

      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${dir.path}/user_data_export_$timestamp.json');

      final exportData = {
        'user': userData.data() ?? {},
        'preferences': prefsData.data() ?? {},
        'privacy': privacyData.data() ?? {},
        'exportDate': DateTime.now().toIso8601String(),
      };

      await file.writeAsString(json.jsonEncode(exportData));
      print('✅ Data exported to: ${file.path}');
      return true;
    } catch (e) {
      print('❌ Export error: $e');
      return false;
    }
  }

  Future<bool> logoutAllSessions() async {
    try {
      if (_userId.isEmpty) return false;

      await _firestore.collection('security').doc(_userId).set({
        'lastLogoutAll': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return true;
    } catch (e) {
      return false;
    }
  }
}
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

  UserProfile? _userProfile;
  bool _isLoading = true;
  final _SettingsBackend _backend = _SettingsBackend();

  String tr(String key) => LocalizationService.translate(key);

  @override
  void initState() {
    super.initState();
    final currentLang = LocalizationService.currentLanguage;
    selectedLanguage = currentLang == LocalizationService.EN
        ? 'English'
        : currentLang == LocalizationService.HI
            ? 'Hindi'
            : 'Nepali';
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      print('⏳ Loading settings...');
      
      final profile = await _backend.getUserProfile();
      final unitsPrefs = await _backend.getUnitsPreferences();
      final privacySettings = await _backend.getPrivacySettings();
      final twoFAStatus = await _backend.get2FAStatus();
      
      // Load theme from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString('ui_theme') ?? 'Auto Mode';
      
      // Verify theme against Firebase
      final firebaseTheme = await _backend.getThemePreference();

      if (mounted) {
        setState(() {
          _userProfile = profile;
          temperatureUnit = unitsPrefs['temperature'] ?? 'Celsius (°C)';
          areaUnit = unitsPrefs['area'] ?? 'Acres';
          volumeUnit = unitsPrefs['volume'] ?? 'Liters';
          selectedTheme = firebaseTheme.isNotEmpty ? firebaseTheme : 'Auto Mode';
          shareUsageData = privacySettings['shareUsageData'] ?? true;
          analytics = privacySettings['analytics'] ?? true;
          locationTracking = privacySettings['locationTracking'] ?? true;
          twoFactorAuth = twoFAStatus;
          _isLoading = false;
        });
      }
      print('✅ Settings loaded: Theme=$selectedTheme');
    } catch (e) {
      print('❌ Error loading settings: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _setLanguage(String languageName, String languageCode) {
    setState(() => selectedLanguage = languageName);
    LocalizationService.setLanguage(languageCode);
    if (Navigator.of(context).canPop()) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _savePrivacySettings() async {
    final success = await _backend.updatePrivacySettings(
      shareUsageData: shareUsageData,
      analytics: analytics,
      locationTracking: locationTracking,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('Privacy settings saved successfully')),
          backgroundColor: _darkGreen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: _lightGray,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: _lightGray,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(),
              if (_userProfile != null) _buildProfileCard(),
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
                child: Center(
                  child: Text(
                    (_userProfile?.fullName ?? 'R')[0].toUpperCase(),
                    style: const TextStyle(color: _white, fontSize: 30, fontFamily: 'Arimo', fontWeight: FontWeight.w400),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_userProfile?.fullName ?? 'Farmer', style: const TextStyle(color: _textDark, fontSize: 16, fontFamily: 'Arimo', fontWeight: FontWeight.w400)),
                    const SizedBox(height: 4),
                    Text(_userProfile?.farmName ?? 'Farm', style: const TextStyle(color: _textGray, fontSize: 16, fontFamily: 'Arimo', fontWeight: FontWeight.w400)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildContactInfo(Icons.email, _userProfile?.email ?? 'N/A'),
              const SizedBox(height: 8),
              _buildContactInfo(Icons.phone, _userProfile?.phone ?? 'N/A'),
              const SizedBox(height: 8),
              _buildContactInfo(Icons.location_on, _userProfile?.location ?? 'N/A'),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileEditScreen(userProfile: _userProfile, backend: _backend))).then((_) => _loadSettings()),
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
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => NotificationSettingsScreen(backend: _backend))),
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
          _buildOption(LocalizationService.translate('Light Mode'), selectedTheme == 'Light Mode', () async {
            setState(() => selectedTheme = 'Light Mode');
            await _backend.setThemePreference('Light Mode');
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('ui_theme', 'Light Mode');
            _updateAppTheme('Light Mode');
          }),
          const SizedBox(height: 8),
          _buildOption(LocalizationService.translate('Dark Mode'), selectedTheme == 'Dark Mode', () async {
            setState(() => selectedTheme = 'Dark Mode');
            await _backend.setThemePreference('Dark Mode');
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('ui_theme', 'Dark Mode');
            _updateAppTheme('Dark Mode');
          }),
          const SizedBox(height: 8),
          _buildOption(LocalizationService.translate('Auto Mode'), selectedTheme == 'Auto Mode', () async {
            setState(() => selectedTheme = 'Auto Mode');
            await _backend.setThemePreference('Auto Mode');
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('ui_theme', 'Auto Mode');
            _updateAppTheme('Auto Mode');
          }),
        ],
      ),
    );
  }

  void _updateAppTheme(String theme) async {
    try {
      // Save to SharedPreferences immediately
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('ui_theme', theme);
      
      // Update Firebase
      await _backend.setThemePreference(theme);
      
      // Apply theme to app
      var myAppState = MyApp.of(context);
      if (myAppState == null && MyApp.navigatorKey.currentContext != null) {
        myAppState = MyApp.of(MyApp.navigatorKey.currentContext!);
      }
      if (myAppState != null) {
        myAppState.setTheme(theme);
        print('✅ Theme changed to: $theme');
      } else {
        print('⚠️ Could not find MyApp state to apply theme');
      }

      // Show confirmation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Theme changed to $theme'),
            backgroundColor: _darkGreen,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      print('❌ Error updating theme: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update theme'),
            backgroundColor: Color(0xFFE7000B),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
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
          _buildUnitSection(LocalizationService.translate('Temperature'), temperatureUnit, [LocalizationService.translate('Celsius (°C)'), LocalizationService.translate('Fahrenheit (°F)')], (value) async {
            setState(() => temperatureUnit = value);
            await _backend.setTemperatureUnit(value);
          }),
          const SizedBox(height: 16),
          _buildUnitSection(LocalizationService.translate('Area'), areaUnit, [LocalizationService.translate('Acres'), LocalizationService.translate('Hectares')], (value) async {
            setState(() => areaUnit = value);
            await _backend.setAreaUnit(value);
          }),
          const SizedBox(height: 16),
          _buildUnitSection(LocalizationService.translate('Volume'), volumeUnit, [LocalizationService.translate('Liters'), LocalizationService.translate('Gallons')], (value) async {
            setState(() => volumeUnit = value);
            await _backend.setVolumeUnit(value);
          }),
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
          _buildPrivacySwitch(LocalizationService.translate('Share Usage Data'), LocalizationService.translate('Help improve the app'), shareUsageData, (value) async {
            setState(() => shareUsageData = value);
            await _savePrivacySettings();
          }),
          const SizedBox(height: 12),
          _buildPrivacySwitch(LocalizationService.translate('Analytics'), LocalizationService.translate('Allow analytics tracking'), analytics, (value) async {
            setState(() => analytics = value);
            await _savePrivacySettings();
          }),
          const SizedBox(height: 12),
          _buildPrivacySwitch(LocalizationService.translate('Location Tracking'), LocalizationService.translate('For weather and field data'), locationTracking, (value) async {
            setState(() => locationTracking = value);
            await _savePrivacySettings();
          }),
          const SizedBox(height: 12),
          _buildPrivacySwitch('Two-Factor Authentication', '', twoFactorAuth, (value) async {
            setState(() => twoFactorAuth = value);
            await _backend.update2FAStatus(value);
          }),
          const SizedBox(height: 12),
          _buildPrivacyItem(LocalizationService.translate('Change Password'), Icons.lock, () => Navigator.push(context, MaterialPageRoute(builder: (context) => ChangePasswordScreen(backend: _backend)))),
          const SizedBox(height: 12),
          _buildPrivacyItem(LocalizationService.translate('Export My Data'), Icons.download, () => _exportData()),
          const SizedBox(height: 12),
          _buildPrivacyItem(LocalizationService.translate('Delete Account'), Icons.delete_forever, () => _showDeleteAccountDialog()),
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
        Text(LocalizationService.translate('© 2026 Smart Kisan. All rights reserved.'),
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

    void _exportData() async {
    final success = await _backend.exportUserData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Data exported successfully' : 'Export failed'),
          backgroundColor: success ? _darkGreen : _red,
        ),
      );
    }
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account', style: TextStyle(color: _textDark, fontFamily: 'Arimo')),
        content: const Text('This action cannot be undone. All your data will be permanently deleted.', style: TextStyle(fontFamily: 'Arimo')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showPasswordConfirmDialog();
            },
            child: const Text('Delete', style: TextStyle(color: _red)),
          ),
        ],
      ),
    );
  }

  void _showPasswordConfirmDialog() {
    final passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Password'),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          decoration: const InputDecoration(hintText: 'Enter your password'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await _backend.deleteAccount(password: passwordController.text);
              if (success && mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('Delete Account', style: TextStyle(color: _red)),
          ),
        ],
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
  final UserProfile? userProfile;
  final _SettingsBackend backend;

  const ProfileEditScreen({
    super.key,
    this.userProfile,
    required this.backend,
  });

  @override
  _ProfileEditScreenState createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _farmController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _locationController;
  
  bool _isSaving = false;
  String? _profileImageUrl;
  bool _isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userProfile?.fullName ?? '');
    _farmController = TextEditingController(text: widget.userProfile?.farmName ?? '');
    _emailController = TextEditingController(text: widget.userProfile?.email ?? '');
    _phoneController = TextEditingController(text: widget.userProfile?.phone ?? '');
    _locationController = TextEditingController(text: widget.userProfile?.location ?? '');
    _loadProfileImage();
  }

  void _loadProfileImage() async {
    try {
      final url = await widget.backend.getProfileImageUrl();
      if (mounted) {
        setState(() => _profileImageUrl = url);
      }
    } catch (e) {
      print('❌ Error loading profile image: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _farmController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final success = await widget.backend.updateUserProfile(
        fullName: _nameController.text.trim(),
        farmName: _farmController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        location: _locationController.text.trim(),
      );

      if (mounted) {
        setState(() => _isSaving = false);

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(LocalizationService.translate('Profile updated successfully!')),
              backgroundColor: _darkGreen,
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update profile. Please try again.'),
              backgroundColor: _red,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error: $e');
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: _red,
          ),
        );
      }
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1D5DC),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                LocalizationService.translate('Select Photo Source'),
                style: const TextStyle(color: _textDark, fontSize: 18, fontFamily: 'Arimo', fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  _pickPhotoFromCamera();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: _borderGray),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.camera_alt, color: _darkGreen, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        LocalizationService.translate('Take Photo'),
                        style: const TextStyle(color: _darkGreen, fontSize: 16, fontFamily: 'Arimo', fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  _pickPhotoFromGallery();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: _borderGray),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.image, color: _darkGreen, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        LocalizationService.translate('Choose from Gallery'),
                        style: const TextStyle(color: _darkGreen, fontSize: 16, fontFamily: 'Arimo', fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (_profileImageUrl != null)
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _deleteProfilePhoto();
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: _red),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.delete, color: _red, size: 24),
                        const SizedBox(width: 12),
                        Text(
                          LocalizationService.translate('Remove Photo'),
                          style: const TextStyle(color: _red, fontSize: 16, fontFamily: 'Arimo', fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1D5DC),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      LocalizationService.translate('Cancel'),
                      style: const TextStyle(color: _textDark, fontSize: 16, fontFamily: 'Arimo', fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickPhotoFromCamera() async {
    setState(() => _isUploadingPhoto = true);
    try {
      final imageFile = await widget.backend.pickImageFromCamera();
      if (imageFile != null && mounted) {
        await _uploadProfileImage(imageFile);
      }
    } catch (e) {
      print('❌ Error picking image from camera: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: _red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  Future<void> _pickPhotoFromGallery() async {
    setState(() => _isUploadingPhoto = true);
    try {
      final imageFile = await widget.backend.pickImageFromGallery();
      if (imageFile != null && mounted) {
        await _uploadProfileImage(imageFile);
      }
    } catch (e) {
      print('❌ Error picking image from gallery: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: _red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  Future<void> _uploadProfileImage(dynamic imageFile) async {
    try {
      await widget.backend.uploadProfileImage(imageFile);
      final url = await widget.backend.getProfileImageUrl();
      if (mounted) {
        setState(() => _profileImageUrl = url);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LocalizationService.translate('Profile photo updated successfully!')),
            backgroundColor: _darkGreen,
          ),
        );
      }
    } catch (e) {
      print('❌ Error uploading profile image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: ${e.toString()}'), backgroundColor: _red),
        );
      }
    }
  }

  Future<void> _deleteProfilePhoto() async {
    try {
      await widget.backend.deleteProfileImage();
      if (mounted) {
        setState(() => _profileImageUrl = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LocalizationService.translate('Profile photo removed')),
            backgroundColor: _darkGreen,
          ),
        );
      }
    } catch (e) {
      print('❌ Error deleting profile image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: _red),
        );
      }
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
                              child: _profileImageUrl != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(48),
                                      child: Image.file(File(_profileImageUrl!), fit: BoxFit.cover),
                                    )
                                  : Center(
                                      child: Text(
                                        (_nameController.text.isEmpty ? 'R' : _nameController.text[0]).toUpperCase(),
                                        style: const TextStyle(color: _white, fontSize: 36, fontFamily: 'Arimo', fontWeight: FontWeight.w400),
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 16),
                            GestureDetector(
                              onTap: _isUploadingPhoto ? null : _showPhotoOptions,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(color: _lightGreen, borderRadius: BorderRadius.circular(10)),
                                child: _isUploadingPhoto
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(color: _darkGreen, strokeWidth: 2),
                                      )
                                    : Row(
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
                                onTap: _isSaving ? null : _saveProfile,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  decoration: BoxDecoration(color: _darkGreen, borderRadius: BorderRadius.circular(10)),
                                  child: Center(
                                    child: _isSaving
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(color: _white, strokeWidth: 2),
                                          )
                                        : Text(LocalizationService.translate('Save Changes'), style: const TextStyle(color: _white, fontSize: 16, fontFamily: 'Arimo', fontWeight: FontWeight.w400)),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: _isSaving ? null : () => Navigator.pop(context),
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
  final _SettingsBackend backend;

  const ChangePasswordScreen({
    super.key,
    required this.backend,
  });

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
  bool _isChanging = false;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isChanging = true);

    try {
      final success = await widget.backend.changePassword(
        currentPassword: _oldPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      if (mounted) {
        setState(() => _isChanging = false);

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(LocalizationService.translate('Password changed successfully!')),
              backgroundColor: _darkGreen,
              duration: const Duration(seconds: 2),
            ),
          );
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) Navigator.pop(context);
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to change password. Please verify your old password and try again.'),
              backgroundColor: _red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error: $e');
      if (mounted) {
        setState(() => _isChanging = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: _red,
          ),
        );
      }
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
                                onTap: _isChanging ? null : _changePassword,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  decoration: BoxDecoration(color: _darkGreen, borderRadius: BorderRadius.circular(10)),
                                  child: Center(
                                    child: _isChanging
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(color: _white, strokeWidth: 2),
                                          )
                                        : Text(LocalizationService.translate('Change Password'), style: const TextStyle(color: _white, fontSize: 16, fontFamily: 'Arimo', fontWeight: FontWeight.w400)),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: _isChanging ? null : () => Navigator.pop(context),
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
  final _SettingsBackend backend;

  const NotificationSettingsScreen({
    super.key,
    required this.backend,
  });

  @override
  _NotificationSettingsScreenState createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  late Map<String, bool> alertTypes;
  late Map<String, bool> notificationChannels;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadNotificationPreferences();
  }

  Future<void> _loadNotificationPreferences() async {
    try {
      final prefs = await widget.backend.getNotificationPreferences();
      if (prefs != null && mounted) {
        // filter out any obsolete keys
        const allowedAlerts = [
          'Weather Alerts',
          'Pest & Disease Alerts',
          'Irrigation Reminders',
          'Crop Health Updates',
          'General Updates',
        ];
        const allowedChannels = [
          'Push Notifications',
          'Email Notifications',
        ];
        setState(() {
          alertTypes = Map.fromEntries(
              prefs.alertTypes.entries.where((e) => allowedAlerts.contains(e.key)));
          notificationChannels = Map.fromEntries(
              prefs.notificationChannels.entries.where((e) => allowedChannels.contains(e.key)));
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading notification preferences: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveNotificationPreferences() async {
    setState(() => _isSaving = true);

    try {
      final prefs = NotificationPreferences(
        alertTypes: alertTypes,
        notificationChannels: notificationChannels,
      );

      final success = await widget.backend.updateNotificationPreferences(prefs);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LocalizationService.translate('Notification preferences saved')),
            backgroundColor: _darkGreen,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      if (mounted) {
        setState(() => _isSaving = false);
      }
    } catch (e) {
      print('❌ Error saving notification preferences: $e');
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: _red,
          ),
        );
      }
    }
  }

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
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: _lightGray,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    int enabledCount = alertTypes.values.where((value) => value).length + notificationChannels.values.where((value) => value).length;
    int maxCount = alertTypes.length + notificationChannels.length;

    return Scaffold(
      backgroundColor: _lightGray,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader('Notification Settings', 'Manage your alerts and notifications'),
              _buildSummaryCard(enabledCount, enabledCount + (alertTypes.length + notificationChannels.length - enabledCount)),
              _buildSectionCard('Alert Types', 'Choose what alerts you want to receive', Icons.notifications_active, alertTypes, _getAlertDescription),
              _buildSectionCard('Notification Channels', 'Choose how you want to receive notifications', Icons.notifications, notificationChannels, _getChannelDescription),
              _buildQuickActions(),
              _buildInfoCard(),
              _buildSaveButton(),
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

  Widget _buildSummaryCard(int enabledCount, int maxCount) {
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
            child: Text('$enabledCount/$maxCount', style: const TextStyle(color: Color(0xFF0D532B), fontSize: 16, fontFamily: 'Arimo', fontWeight: FontWeight.w400)),
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
                return _buildNotificationItem(entry.key, getDescription(entry.key), entry.value, (value) {
                  setState(() => items[entry.key] = value);
                });
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

  Widget _buildSaveButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onTap: _isSaving ? null : _saveNotificationPreferences,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: _darkGreen,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [BoxShadow(color: _black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2))],
          ),
          child: Center(
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: _white, strokeWidth: 2),
                  )
                : Text(LocalizationService.translate('Save Preferences'), style: const TextStyle(color: _white, fontSize: 16, fontFamily: 'Arimo', fontWeight: FontWeight.w400)),
          ),
        ),
      ),
    );
  }
}