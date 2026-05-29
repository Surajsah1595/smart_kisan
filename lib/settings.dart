import 'package:flutter/material.dart';
import 'package:smart_kisan/welcome_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
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

  /// Purpose: Deserializes a Firestore document map into a strongly-typed UserProfile object.
  /// Inputs: [map] - The raw data map from Firestore. [userId] - The user's authentication ID.
  /// Outputs: Returns an instantiated UserProfile model.
  factory UserProfile.fromMap(Map<String, dynamic> map, String userId) {
    // 1. Construct the profile using safe fallbacks for potentially missing fields.
    return UserProfile(
      userId: userId,
      fullName: map['fullName'] ?? '',
      farmName: map['farmName'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      location: map['location'] ?? '',
      profileImageUrl: map['profileImageUrl'],
      // 2. Safely cast the Firestore Timestamp back to a Dart DateTime object, defaulting to now if missing.
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Purpose: Serializes the UserProfile object into a Map for writing to Firestore.
  /// Inputs: None.
  /// Outputs: Returns a Map<String, dynamic> compatible with Firestore.
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'fullName': fullName,
      'farmName': farmName,
      'email': email,
      'phone': phone,
      'location': location,
      'profileImageUrl': profileImageUrl,
      // 1. Write the timestamps as they are; Firestore SDK will handle standard DateTimes, 
      // but it's typically better practice to convert them explicitly to Timestamps.
      'createdAt': createdAt,
      'updatedAt': updatedAt ?? DateTime.now(),
    };
  }

  /// Purpose: Creates a new UserProfile instance by copying the current one and overwriting specified fields.
  /// Inputs: Optional named parameters for any field that should be updated.
  /// Outputs: Returns a new UserProfile object.
  UserProfile copyWith({
    String? fullName,
    String? farmName,
    String? email,
    String? phone,
    String? location,
    String? profileImageUrl,
  }) {
    // 1. Return a fresh instance combining new values (if provided) and old values (as fallback).
    return UserProfile(
      userId: userId,
      fullName: fullName ?? this.fullName,
      farmName: farmName ?? this.farmName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt,
      // 2. Automatically refresh the updatedAt timestamp whenever a copy is made.
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

  /// Purpose: Generates a default set of notification preferences for new users.
  /// Inputs: None.
  /// Outputs: Returns an instantiated NotificationPreferences model with all channels enabled.
  factory NotificationPreferences.defaultPreferences() {
    return NotificationPreferences(
      // 1. Enable all critical agronomic alert categories by default.
      alertTypes: {
        'Weather Alerts': true,
        'Pest & Disease Alerts': true,
        'Irrigation Reminders': true,
        'Crop Health Updates': true,
        'General Updates': true,
      },
      // 2. Enable both primary notification delivery channels.
      notificationChannels: {
        'Push Notifications': true,
        'Email Notifications': true,
      },
    );
  }

  /// Purpose: Deserializes the user's notification preferences from a raw map.
  /// Inputs: [map] - The map data from local storage or Firestore.
  /// Outputs: Returns an instantiated NotificationPreferences model.
  factory NotificationPreferences.fromMap(Map<String, dynamic> map) {
    return NotificationPreferences(
      // 1. Safely parse the nested maps, falling back to empty maps to prevent null crashes.
      alertTypes: Map<String, bool>.from(map['alertTypes'] ?? {}),
      notificationChannels: Map<String, bool>.from(map['notificationChannels'] ?? {}),
    );
  }

  /// Purpose: Serializes the notification preferences into a Map for saving.
  /// Inputs: None.
  /// Outputs: Returns a Map containing the alert types and channels.
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
  /// Purpose: Fetches the current user's profile data from Firestore.
  /// Inputs: None (uses the implicitly authenticated `_userId`).
  /// Outputs: Returns a typed UserProfile object, or null if it doesn't exist or on error.
  Future<UserProfile?> getUserProfile() async {
    try {
      // 1. Guard clause: Ensure the user is actually authenticated before querying.
      if (_userId.isEmpty) return null;
      // 2. Query the 'users' collection for the specific document matching the auth UID.
      final doc = await _firestore.collection('users').doc(_userId).get();
      // 3. Return null if no profile document was ever created during registration.
      if (!doc.exists) return null;
      // 4. Delegate to the factory constructor for deserialization.
      return UserProfile.fromMap(doc.data()!, _userId);
    } catch (e) {
      print(' Error getting profile: $e');
      return null;
    }
  }

  /// Purpose: Updates the core profile fields in Firestore and synchronizes the Firebase Auth display name.
  /// Inputs: Required profile fields (fullName, farmName, email, phone, location).
  /// Outputs: Returns true on success, false on failure.
  Future<bool> updateUserProfile({
    required String fullName,
    required String farmName,
    required String email,
    required String phone,
    required String location,
  }) async {
    try {
      // 1. Guard against unauthenticated writes.
      if (_userId.isEmpty) return false;
      
      // 2. Perform a merge-set operation. Using set with SetOptions(merge: true) acts as an upsert:
      // it creates the doc if missing, or only overwrites the specified fields if it exists.
      await _firestore.collection('users').doc(_userId).set({
        'fullName': fullName,
        'farmName': farmName,
        'email': email,
        'phone': phone,
        'location': location,
        // 3. Let the server dictate the true update timestamp to prevent client-side clock tampering.
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      // 4. Also update the underlying Firebase Auth user profile for consistency (e.g., for standard Firebase UI widgets).
      await _auth.currentUser?.updateDisplayName(fullName);
      print(' Profile updated');
      return true;
    } catch (e) {
      print(' Error updating profile: $e');
      return false;
    }
  }

  // ===== IMAGE HANDLING =====
  /// Purpose: Launches the device camera to capture a profile photo.
  /// Inputs: None.
  /// Outputs: Returns the captured File, or throws an exception/returns null.
  Future<File?> pickImageFromCamera() async {
    try {
      // 1. Explicitly request camera hardware permissions.
      final cameraStatus = await Permission.camera.request();
      if (cameraStatus.isDenied) {
        print(' Camera permission denied');
        throw Exception('Camera permission is required to take photos');
      }
      if (cameraStatus.isPermanentlyDenied) {
        print(' Camera permission permanently denied');
        // 2. Deep link the user to the OS settings app if they previously clicked "Never Ask Again".
        openAppSettings();
        throw Exception('Camera permission is permanently denied. Please enable it in settings.');
      }

      // 3. Launch the native camera UI with constraints (85% quality, max 1024x1024) to save storage bandwidth.
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxHeight: 1024,
        maxWidth: 1024,
      );
      // 4. Handle the user backing out without taking a photo.
      if (pickedFile == null) {
        print('ℹ User cancelled camera selection');
        return null;
      }
      print(' Image picked from camera: ${pickedFile.path}');
      return File(pickedFile.path);
    } catch (e) {
      print(' Camera error: $e');
      throw Exception('Failed to pick image from camera: $e');
    }
  }

  /// Purpose: Opens the device gallery to select an existing photo for the profile.
  /// Inputs: None.
  /// Outputs: Returns the selected File, or throws/returns null.
  Future<File?> pickImageFromGallery() async {
    try {
      // 1. Request general storage access (using the 'storage' permission rather than 'photos' for broader Android version compatibility).
      final storageStatus = await Permission.storage.request();
      if (storageStatus.isDenied) {
        print(' Storage permission denied');
        throw Exception('Storage permission is required to access gallery');
      }
      if (storageStatus.isPermanentlyDenied) {
        print(' Storage permission permanently denied');
        openAppSettings();
        throw Exception('Storage permission is permanently denied. Please enable it in settings.');
      }

      // 2. Launch the native gallery picker with the same bandwidth-saving constraints as the camera.
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxHeight: 1024,
        maxWidth: 1024,
      );
      // 3. Graceful handling if the user hits the back button.
      if (pickedFile == null) {
        print('ℹ User cancelled gallery selection');
        return null;
      }
      print(' Image picked from gallery: ${pickedFile.path}');
      return File(pickedFile.path);
    } catch (e) {
      print(' Gallery error: $e');
      throw Exception('Failed to pick image from gallery: $e');
    }
  }

  /// Purpose: Saves a profile image locally and updates the Firestore user record with its path.
  /// Inputs: [imageFile] - Can be a File object or a String path.
  /// Outputs: Returns the local storage path of the saved image.
  Future<String> uploadProfileImage(dynamic imageFile) async {
    try {
      // 1. Guard against unauthenticated operations.
      if (_userId.isEmpty) throw Exception('No user logged in');
      File file;
      // 2. Safely cast the dynamic input to a File object.
      if (imageFile is File) {
        file = imageFile;
      } else if (imageFile is String) {
        file = File(imageFile);
      } else {
        throw Exception('Invalid image file type');
      }

      if (!file.existsSync()) throw Exception('File does not exist');

      // 3. Resolve the secure app-specific documents directory for permanent local storage.
      final dir = await getApplicationDocumentsDirectory();
      
      // 4. Housekeeping: Identify and purge any previous profile images for this user to save space.
      final existing = dir.listSync().where((f) =>
          f is File && f.path.contains('profile_${_userId}')).toList();
      for (final f in existing) {
        try {
          (f as File).deleteSync();
        } catch (_) {}
      }
      
      // 5. Generate a unique filename using a timestamp to aggressively bust caches.
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final dest = File('${dir.path}/profile_${_userId}_$timestamp.jpg');
      await file.copy(dest.path);

      // 6. Cache the current active path in SharedPreferences for rapid synchronous UI rendering on boot.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_image_path', dest.path);

      // 7. Sync the local path to Firestore as a marker (note: this is a local path, not a cloud URL).
      await _firestore.collection('users').doc(_userId).set({
        'profileImagePath': dest.path,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return dest.path;
    } catch (e) {
      print(' Upload error: $e');
      throw Exception('Failed to save profile image: $e');
    }
  }

  /// Purpose: Retrieves the cached profile image path from SharedPreferences.
  /// Inputs: None.
  /// Outputs: Returns the absolute file path, or null if missing/deleted.
  Future<String?> getProfileImageUrl() async {
    try {
      // 1. Check local key-value store for the fastest possible retrieval.
      final prefs = await SharedPreferences.getInstance();
      final path = prefs.getString('profile_image_path');
      // 2. Validate that the file still physically exists on disk before returning the path.
      if (path != null && File(path).existsSync()) {
        return path;
      }
      return null;
    } catch (e) {
      print(' Error getting profile image path: $e');
      return null;
    }
  }

  /// Purpose: Deletes the user's profile image from local storage and syncs the deletion to Firestore.
  /// Inputs: None.
  /// Outputs: None. Throws exception on failure.
  Future<void> deleteProfileImage() async {
    try {
      if (_userId.isEmpty) throw Exception('No user');
      
      // 1. Clear local SharedPreferences cache.
      final prefs = await SharedPreferences.getInstance();
      final path = prefs.getString('profile_image_path');
      
      if (path != null) {
        // 2. Physically wipe the file from disk to free up space.
        final f = File(path);
        if (f.existsSync()) await f.delete();
        await prefs.remove('profile_image_path');
      }
      
      // 3. Nullify the reference in the cloud database.
      await _firestore.collection('users').doc(_userId).update({
        'profileImagePath': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print(' Image deleted');
    } catch (e) {
      print(' Delete error: $e');
      throw Exception('Failed to delete image');
    }
  }

  // ===== PREFERENCES =====
  
  /// Purpose: Retrieves the user's stored theme preference from Firestore.
  /// Inputs: None.
  /// Outputs: Returns 'Dark Mode' (default) or the stored string.
  Future<String> getThemePreference() async {
    try {
      if (_userId.isEmpty) return 'Dark Mode';
      // 1. Query the dedicated 'preferences' collection for user-specific settings.
      final doc = await _firestore.collection('preferences').doc(_userId).get();
      return doc.data()?['theme'] ?? 'Dark Mode';
    } catch (e) {
      return 'Dark Mode';
    }
  }

  /// Purpose: Saves the chosen theme preference to Firestore.
  /// Inputs: [theme] - The theme string ('Dark Mode' or 'Light Mode').
  /// Outputs: Returns true if successful.
  Future<bool> setThemePreference(String theme) async {
    try {
      if (_userId.isEmpty) return false;
      // 1. Upsert the theme value to ensure preferences exist even if the doc wasn't created at registration.
      await _firestore.collection('preferences').doc(_userId).set(
        {'theme': theme, 'updatedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
      return true;
    } catch (e) {
      print(' Theme error: $e');
      return false;
    }
  }

  /// Purpose: Retrieves all unit preferences (temp, area, volume) from Firestore.
  /// Inputs: None.
  /// Outputs: Returns a Map of unit types to their chosen strings.
  Future<Map<String, String>> getUnitsPreferences() async {
    try {
      // 1. Provide sensible scientific defaults if unauthenticated.
      if (_userId.isEmpty) {
        return {'temperature': 'Celsius (°C)', 'area': 'Acres', 'volume': 'Liters'};
      }
      final doc = await _firestore.collection('preferences').doc(_userId).get();
      // 2. Provide defaults if the document doesn't exist yet.
      if (!doc.exists) {
        return {'temperature': 'Celsius (°C)', 'area': 'Acres', 'volume': 'Liters'};
      }
      // 3. Extract and cast each preference, falling back to defaults for missing keys.
      return {
        'temperature': doc.data()?['temperature'] ?? 'Celsius (°C)',
        'area': doc.data()?['area'] ?? 'Acres',
        'volume': doc.data()?['volume'] ?? 'Liters',
      };
    } catch (e) {
      return {'temperature': 'Celsius (°C)', 'area': 'Acres', 'volume': 'Liters'};
    }
  }

  /// Purpose: Saves the selected temperature unit to Firestore.
  /// Inputs: [unit] - e.g., 'Celsius (°C)'.
  /// Outputs: Returns true on success.
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

  /// Purpose: Saves the selected land area unit to Firestore.
  /// Inputs: [unit] - e.g., 'Acres' or 'Hectares'.
  /// Outputs: Returns true on success.
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

  /// Purpose: Saves the selected liquid volume unit to Firestore.
  /// Inputs: [unit] - e.g., 'Liters' or 'Gallons'.
  /// Outputs: Returns true on success.
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

  /// Purpose: Retrieves the user's data privacy toggles from Firestore.
  /// Inputs: None.
  /// Outputs: Returns a boolean map. Defaults all to true if missing.
  Future<Map<String, bool>> getPrivacySettings() async {
    try {
      // 1. Return default opt-in values if unauthenticated.
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

  /// Purpose: Saves updated privacy toggles to the database.
  /// Inputs: Booleans for usage, analytics, and location sharing.
  /// Outputs: Returns true on successful write.
  Future<bool> updatePrivacySettings({
    required bool shareUsageData,
    required bool analytics,
    required bool locationTracking,
  }) async {
    try {
      if (_userId.isEmpty) return false;
      // 1. Overwrite the entire document for simplicity, rather than merge.
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

  /// Purpose: Checks if Two-Factor Authentication (2FA) is enabled for the account.
  /// Inputs: None.
  /// Outputs: Returns boolean status.
  Future<bool> get2FAStatus() async {
    try {
      if (_userId.isEmpty) return false;
      // 1. Query the 'security' collection which holds auth-related flags.
      final doc = await _firestore.collection('security').doc(_userId).get();
      return doc.data()?['twoFactorAuth'] ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Purpose: Toggles the 2FA status in Firestore. Note: Actual 2FA implementation requires Firebase Auth integration.
  /// Inputs: [enabled] - target state.
  /// Outputs: Returns true on success.
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

  /// Purpose: Securely updates the user's password via Firebase Auth.
  /// Inputs: [currentPassword] (for re-auth) and [newPassword].
  /// Outputs: Returns true on success.
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // 1. Construct fresh credentials using the provided current password.
      final cred = EmailAuthProvider.credential(
        email: user.email ?? '',
        password: currentPassword,
      );

      // 2. Re-authenticate to prove the user is physically present (required by Firebase for sensitive ops).
      await user.reauthenticateWithCredential(cred);
      // 3. Issue the secure password update command.
      await user.updatePassword(newPassword);
      print(' Password changed');
      return true;
    } catch (e) {
      print(' Password change error: $e');
      return false;
    }
  }

  /// Purpose: Fetches the user's specific notification toggles (Push/Email, Alert types).
  /// Inputs: None.
  /// Outputs: Returns a populated NotificationPreferences model.
  Future<NotificationPreferences?> getNotificationPreferences() async {
    try {
      if (_userId.isEmpty) return NotificationPreferences.defaultPreferences();
      // 1. Fetch from the dedicated 'notification_preferences' collection.
      final doc = await _firestore.collection('notification_preferences').doc(_userId).get();
      // 2. If the user hasn't explicitly saved preferences yet, return the default opt-in state.
      if (!doc.exists) return NotificationPreferences.defaultPreferences();
      return NotificationPreferences.fromMap(doc.data()!);
    } catch (e) {
      return NotificationPreferences.defaultPreferences();
    }
  }

  /// Purpose: Saves the notification preference toggles to Firestore.
  /// Inputs: [preferences] - The updated model.
  /// Outputs: Returns true on success.
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

  /// Purpose: Permanently deletes the user's account and all associated setting documents from Firestore.
  /// Inputs: [password] - Required to re-authenticate the sensitive deletion request.
  /// Outputs: Returns true on success, logging the user out implicitly.
  Future<bool> deleteAccount({required String password}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // 1. Re-authenticate to ensure account safety.
      final cred = EmailAuthProvider.credential(
        email: user.email ?? '',
        password: password,
      );

      await user.reauthenticateWithCredential(cred);

      // 2. Wipe PII and settings documents from Firestore collections.
      // Note: A production app might use Cloud Functions for deep recursive deletion of all user data.
      await _firestore.collection('users').doc(_userId).delete();
      await _firestore.collection('preferences').doc(_userId).delete();
      await _firestore.collection('privacy').doc(_userId).delete();
      await _firestore.collection('security').doc(_userId).delete();

      // 3. Finally, delete the actual Firebase Auth record.
      await user.delete();
      print(' Account deleted');
      return true;
    } catch (e) {
      print(' Account deletion error: $e');
      return false;
    }
  }

  /// Purpose: Gathers all user-specific data from Firestore and exports it as a JSON file to the device.
  /// Inputs: None.
  /// Outputs: Returns true if the file was written successfully.
  Future<bool> exportUserData() async {
    try {
      if (_userId.isEmpty) return false;

      // 1. Concurrently fetch the user's data from all relevant collections.
      final userData = await _firestore.collection('users').doc(_userId).get();
      final prefsData = await _firestore.collection('preferences').doc(_userId).get();
      final privacyData = await _firestore.collection('privacy').doc(_userId).get();

      // 2. Resolve the secure local documents directory.
      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      // 3. Create a unique export file.
      final file = File('${dir.path}/user_data_export_$timestamp.json');

      // 4. Structure the raw data into a single nested map.
      final exportData = {
        'user': userData.data() ?? {},
        'preferences': prefsData.data() ?? {},
        'privacy': privacyData.data() ?? {},
        'exportDate': DateTime.now().toIso8601String(),
      };

      // 5. Serialize and write to disk.
      await file.writeAsString(json.jsonEncode(exportData));
      print(' Data exported to: ${file.path}');
      return true;
    } catch (e) {
      print(' Export error: $e');
      return false;
    }
  }

  /// Purpose: Sets a marker in Firestore that can be used by cloud functions or middleware to invalidate existing sessions.
  /// Inputs: None.
  /// Outputs: Returns true on success.
  Future<bool> logoutAllSessions() async {
    try {
      if (_userId.isEmpty) return false;

      // 1. Record the current timestamp. Any session tokens issued before this time should be treated as invalid.
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

  /// Purpose: Initializes the state of the Settings Screen. Sets up the localization display and triggers the data load.
  /// Inputs: None.
  /// Outputs: None.
  @override
  void initState() {
    super.initState();
    // 1. Read the current globally active language code.
    final currentLang = LocalizationService.currentLanguage;
    // 2. Map the language code (e.g., 'en') back to its human-readable display string.
    selectedLanguage = currentLang == LocalizationService.EN
        ? 'English'
        : currentLang == LocalizationService.HI
            ? 'Hindi'
            : 'Nepali';
    // 3. Initiate the async fetch of all user settings from Firestore.
    _loadSettings();
  }

  /// Purpose: Fetches the user profile, unit preferences, privacy settings, and security status concurrently, updating the UI when done.
  /// Inputs: None.
  /// Outputs: Sets state variables and turns off the loading spinner.
  Future<void> _loadSettings() async {
    try {
      print(' Loading settings...');
      
      // 1. Fetch all modular setting blocks from the backend.
      final profile = await _backend.getUserProfile();
      final unitsPrefs = await _backend.getUnitsPreferences();
      final privacySettings = await _backend.getPrivacySettings();
      final twoFAStatus = await _backend.get2FAStatus();
      
      // 2. Load the UI theme preference from fast local storage (fallback to Auto).
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString('ui_theme') ?? 'Auto Mode';
      
      // 3. Re-verify the theme against the cloud database to ensure cross-device consistency.
      final firebaseTheme = await _backend.getThemePreference();

      // 4. Update the widget tree safely.
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
      print(' Settings loaded: Theme=$selectedTheme');
    } catch (e) {
      print(' Error loading settings: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Purpose: Updates the globally selected localization context.
  /// Inputs: [languageName] (e.g. 'English'), [languageCode] (e.g. 'en').
  /// Outputs: Rebuilds the UI and optionally pops the current menu context.
  void _setLanguage(String languageName, String languageCode) {
    // 1. Update the local UI state for the dropdown/selector.
    setState(() => selectedLanguage = languageName);
    // 2. Delegate to the custom localization service.
    LocalizationService.setLanguage(languageCode);
    // 3. Delegate to the easy_localization package.
    context.setLocale(Locale(languageCode));
    // 4. Close the language picker modal or menu.
    if (Navigator.of(context).canPop()) {
      Navigator.pop(context, true);
    }
  }

  /// Purpose: Persists the boolean toggle states for privacy options to the backend.
  /// Inputs: None (reads from component state).
  /// Outputs: Displays a success SnackBar.
  Future<void> _savePrivacySettings() async {
    // 1. Delegate the write operation to the backend service.
    final success = await _backend.updatePrivacySettings(
      shareUsageData: shareUsageData,
      analytics: analytics,
      locationTracking: locationTracking,
    );

    // 2. Provide visual confirmation to the user.
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('Privacy settings saved successfully')),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    }
  }

  /// Purpose: The root build method for the settings screen. Assembles the UI sequentially based on data loading state.
  /// Inputs: [context] - The BuildContext.
  /// Outputs: Returns a Scaffold widget containing the settings layout.
  @override
  Widget build(BuildContext context) {
    // 1. Show a blocking loading spinner while asynchronous data (Firestore, SharedPreferences) is fetched.
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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

  /// Purpose: Renders the gradient top banner with a back button and screen title.
  /// Inputs: None.
  /// Outputs: Returns a styled Container widget.
  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24),
      decoration: BoxDecoration(
        // 1. Use the primary color as a solid block (or gradient if extended later) to match the app's brand identity.
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.primary],
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 6, offset: const Offset(0, 4)),
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
                    color: Theme.of(context).cardColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.arrow_back, color: Theme.of(context).cardColor, size: 20),
                ),
              ),
              const SizedBox(width: 16),
              Text(LocalizationService.translate('Settings'),
                  style: TextStyle(color: Theme.of(context).cardColor, fontSize: 24, fontFamily: 'Arimo', fontWeight: FontWeight.w400)),
            ],
          ),
          const SizedBox(height: 16),
          Text(LocalizationService.translate('Manage your account and preferences'),
              style: TextStyle(color: Theme.of(context).cardColor.withValues(alpha: 0.8), fontSize: 16, fontFamily: 'Arimo', fontWeight: FontWeight.w400)),
        ],
      ),
    );
  }

  /// Purpose: Renders the user's profile summary card (avatar, name, farm, and contact details).
  /// Inputs: None (reads from the `_userProfile` state variable).
  /// Outputs: Returns a configured `_buildSettingsCard` widget.
  Widget _buildProfileCard() {
    return _buildSettingsCard(
      icon: Icons.person,
      title: LocalizationService.translate('Profile Settings'),
      subtitle: LocalizationService.translate('Manage your personal information'),
      child: Column(
        children: [
          Row(
            children: [
              // 1. Render a fallback text avatar if no image URL is present.
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.primary],
                  ),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Center(
                  child: Text(
                    // 2. Safe-extract the first letter of the user's name.
                    (_userProfile?.fullName ?? 'R')[0].toUpperCase(),
                    style: TextStyle(color: Theme.of(context).cardColor, fontSize: 30, fontFamily: 'Arimo', fontWeight: FontWeight.w400),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_userProfile?.fullName ?? 'Farmer', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 16, fontFamily: 'Arimo', fontWeight: FontWeight.w400)),
                    const SizedBox(height: 4),
                    Text(_userProfile?.farmName ?? 'Farm', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 16, fontFamily: 'Arimo', fontWeight: FontWeight.w400)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 3. Render a vertical list of detailed contact info rows.
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
          // 4. Action button to push the ProfileEditScreen to the navigation stack.
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileEditScreen(userProfile: _userProfile, backend: _backend))).then((_) => _loadSettings()),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(10)),
              child: Center(child: Text(LocalizationService.translate('Edit Profile'), style: TextStyle(color: Theme.of(context).cardColor, fontSize: 16, fontFamily: 'Arimo', fontWeight: FontWeight.w400))),
            ),
          ),
        ],
      ),
    );
  }

  /// Purpose: Helper to render a single row of contact information with an icon.
  /// Inputs: [icon] - Material IconData. [text] - The display string.
  /// Outputs: Returns a Row widget.
  Widget _buildContactInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).textTheme.bodyMedium?.color, size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 16, fontFamily: 'Arimo', fontWeight: FontWeight.w400))),
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
                  Text(LocalizationService.translate('Active Notifications'), style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 18, fontFamily: 'Arimo', fontWeight: FontWeight.w400)),
                  const SizedBox(height: 4),
                  Text(LocalizationService.translate('You have 7 notifications enabled'), style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 16, fontFamily: 'Arimo', fontWeight: FontWeight.w400)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
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
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(10)),
              child: Center(child: Text(LocalizationService.translate('Manage Notifications'), style: TextStyle(color: Theme.of(context).cardColor, fontSize: 16, fontFamily: 'Arimo', fontWeight: FontWeight.w400))),
            ),
          ),
        ],
      ),
    );
  }

  /// Purpose: A reusable container component for standardizing the look of settings blocks.
  /// Inputs: [icon], [title], [subtitle], and the specific widget [child] content.
  /// Outputs: Returns a configured Container widget.
  Widget _buildSettingsCard({required IconData icon, required String title, required String subtitle, required Widget child}) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          // 1. The header section with icon, title, and subtitle.
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor, width: 1.3))),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 20, fontFamily: 'Arimo', fontWeight: FontWeight.w400)),
                      Text(subtitle, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 16, fontFamily: 'Arimo', fontWeight: FontWeight.w400)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // 2. The inner content injected by the parent.
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }

  /// Purpose: Builds the card UI for switching app localization.
  /// Inputs: None.
  /// Outputs: Returns the wrapped SettingsCard.
  Widget _buildLanguageCard() {
    return _buildSettingsCard(
      icon: Icons.language,
      title: LocalizationService.translate('Language'),
      subtitle: LocalizationService.translate('Select your preferred language'),
      child: Column(
        children: [
          // 1. Render supported locales, highlighting the active one.
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

  /// Purpose: Builds the card for switching UI themes (Light/Dark/Auto).
  /// Inputs: None.
  /// Outputs: Returns the wrapped SettingsCard.
  Widget _buildThemeCard() {
    return _buildSettingsCard(
      icon: Icons.brightness_medium,
      title: LocalizationService.translate('Theme'),
      subtitle: LocalizationService.translate('Choose your display theme'),
      child: Column(
        children: [
          // 1. Wire up async callbacks that trigger the global theme propagation upon selection.
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

  /// Purpose: Pushes the new theme globally across the app by interacting with the inherited `MyApp` widget.
  /// Inputs: [theme] - A string representation of the target theme.
  /// Outputs: Rebuilds the root app context and displays a confirmation.
  void _updateAppTheme(String theme) async {
    try {
      // 1. Ensure local consistency before network hop.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('ui_theme', theme);
      
      // 2. Queue cloud sync for cross-device consistency.
      await _backend.setThemePreference(theme);
      
      // 3. Attempt to find the global app state to force a full widget tree rebuild.
      var myAppState = MyApp.of(context);
      if (myAppState == null && MyApp.navigatorKey.currentContext != null) {
        myAppState = MyApp.of(MyApp.navigatorKey.currentContext!);
      }
      if (myAppState != null) {
        myAppState.setTheme(theme);
        print(' Theme changed to: $theme');
      } else {
        print(' Could not find MyApp state to apply theme');
      }

      // 4. Show success feedback to the user.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${LocalizationService.translate('Theme changed to')} $theme'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      print(' Error updating theme: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LocalizationService.translate('Failed to update theme')),
            
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Purpose: Renders an interactive option pill used in lists (e.g. Language, Theme menus).
  /// Inputs: [text], [isSelected] boolean, and a closure [onTap].
  /// Outputs: Returns a GestureDetector wrapping a visually stateful Container.
  Widget _buildOption(String text, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          // 1. Dynamically apply active-state highlighting via subtle alpha tint.
          color: isSelected ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1) : Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(10),
          border: isSelected ? Border.all(color: Theme.of(context).colorScheme.primary, width: 1.3) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(text, style: TextStyle(color: isSelected ? Color(0xFF0D532B) : Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black, fontSize: 16, fontFamily: 'Arimo', fontWeight: FontWeight.w400)),
            // 2. Render a checkmark if selected.
            if (isSelected) Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary, size: 20),
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

  /// Purpose: Builds a horizontal toggle group for selecting a specific measurement unit.
  /// Inputs: [title], currently [selected] value, list of [options], and [onSelect] callback.
  /// Outputs: Returns a Column containing the header and toggle buttons.
  Widget _buildUnitSection(String title, String selected, List<String> options, ValueChanged<String> onSelect) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 16, fontFamily: 'Arimo', fontWeight: FontWeight.w400)),
        const SizedBox(height: 8),
        Row(
          // 1. Iterate over the options to build equal-width toggle buttons.
          children: options.map((option) {
            return Expanded(
              child: GestureDetector(
                onTap: () => onSelect(option),
                child: Container(
                  // 2. Add left margin only to non-first items to create consistent spacing.
                  margin: option == options.first ? null : const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: selected == option ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1) : Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(10),
                    border: selected == option ? Border.all(color: Theme.of(context).colorScheme.primary, width: 1.3) : null,
                  ),
                  child: Center(
                    child: Text(option,
                        style: TextStyle(
                            color: selected == option ? Color(0xFF0D532B) : Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black, fontSize: 16, fontFamily: 'Arimo', fontWeight: FontWeight.w400)),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Purpose: Assembles the privacy and security settings card containing various toggles and actions.
  /// Inputs: None.
  /// Outputs: Returns the wrapped SettingsCard.
  Widget _buildPrivacyCard() {
    return _buildSettingsCard(
      icon: Icons.security,
      title: LocalizationService.translate('Privacy & Security'),
      subtitle: LocalizationService.translate('Manage your privacy settings'),
      child: Column(
        children: [
          // 1. App-level analytics tracking toggles.
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
          // 2. Hardware permission toggle.
          _buildPrivacySwitch(LocalizationService.translate('Location Tracking'), LocalizationService.translate('For weather and field data'), locationTracking, (value) async {
            setState(() => locationTracking = value);
            await _savePrivacySettings();
          }),
          const SizedBox(height: 12),
          // 3. Authentication level toggles.
          _buildPrivacySwitch('Two-Factor Authentication', '', twoFactorAuth, (value) async {
            setState(() => twoFactorAuth = value);
            await _backend.update2FAStatus(value);
          }),
          const SizedBox(height: 12),
          // 4. Sensitive account actions.
          _buildPrivacyItem(LocalizationService.translate('Change Password'), Icons.lock, () => Navigator.push(context, MaterialPageRoute(builder: (context) => ChangePasswordScreen(backend: _backend)))),
          const SizedBox(height: 12),
          _buildPrivacyItem(LocalizationService.translate('Export My Data'), Icons.download, () => _exportData()),
          const SizedBox(height: 12),
          _buildPrivacyItem(LocalizationService.translate('Delete Account'), Icons.delete_forever, () => _showDeleteAccountDialog()),
        ],
      ),
    );
  }

  /// Purpose: Helper component to render a single boolean toggle switch.
  /// Inputs: [title], optional [subtitle], boolean [value], and callback [onChanged].
  /// Outputs: Returns a Container holding a Row with text and a Switch.
  Widget _buildPrivacySwitch(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 16, fontFamily: 'Arimo', fontWeight: FontWeight.w400)),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 16, fontFamily: 'Arimo', fontWeight: FontWeight.w400)),
                ],
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged, activeThumbColor: Theme.of(context).colorScheme.primary),
        ],
      ),
    );
  }

  /// Purpose: Helper component to render a clickable row leading to another sub-screen (e.g. Change Password).
  /// Inputs: [title], [icon], and [onTap] callback.
  /// Outputs: Returns a GestureDetector wrapped Container.
  Widget _buildPrivacyItem(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: BorderRadius.circular(10)),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).textTheme.bodyLarge?.color, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 16, fontFamily: 'Arimo', fontWeight: FontWeight.w400))),
            Icon(Icons.chevron_right, color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey),
          ],
        ),
      ),
    );
  }

  /// Purpose: Static information card showing app version and copyright details.
  /// Inputs: None.
  /// Outputs: Returns a configured SettingsCard.
  Widget _buildAboutCard() {
  return _buildSettingsCard(
    icon: Icons.info,
    title: LocalizationService.translate('About'),
    subtitle: LocalizationService.translate('App information and version'),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(LocalizationService.translate('Smart Kisan App'), style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 16, fontFamily: 'Arimo', fontWeight: FontWeight.w400)),
        const SizedBox(height: 8),
        Text(LocalizationService.translate('Version 1.0.0'), style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 16, fontFamily: 'Arimo', fontWeight: FontWeight.w400)),
        const SizedBox(height: 8),
        Text(LocalizationService.translate('© 2026 Smart Kisan. All rights reserved.'),
            style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 16, fontFamily: 'Arimo', fontWeight: FontWeight.w400)),
        ],
      ),
    );
  }

  /// Purpose: Renders the primary destructive action button to log out the user.
  /// Inputs: None.
  /// Outputs: Returns a red-styled GestureDetector button.
  Widget _buildLogoutButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onTap: _showLogoutConfirmation,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout, color: Theme.of(context).cardColor, size: 20),
              const SizedBox(width: 8),
              Text(LocalizationService.translate('Logout'), style: TextStyle(color: Theme.of(context).cardColor, fontSize: 16, fontFamily: 'Arimo', fontWeight: FontWeight.w400)),
            ],
          ),
        ),
      ),
    );
  }

  /// Purpose: Invokes the backend data export and provides UI feedback via SnackBar.
  /// Inputs: None.
  /// Outputs: None.
  void _exportData() async {
    // 1. Await the disk writing process.
    final success = await _backend.exportUserData();
    // 2. Ensure the widget is still active before trying to show a SnackBar.
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Data exported successfully' : 'Export failed'),
          backgroundColor: success ? Theme.of(context).colorScheme.primary : Colors.red,
        ),
      );
    }
  }

  /// Purpose: Shows the initial warning dialog when a user attempts to delete their account.
  /// Inputs: None.
  /// Outputs: Shows an AlertDialog.
  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(LocalizationService.translate('Delete Account'), style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontFamily: 'Arimo')),
        content: Text(LocalizationService.translate('This action cannot be undone. All your data will be permanently deleted.'), style: TextStyle(fontFamily: 'Arimo')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(LocalizationService.translate('Cancel')),
          ),
          TextButton(
            onPressed: () {
              // 1. Dismiss the warning dialog.
              Navigator.pop(context);
              // 2. Escalate to the password confirmation dialog required for sensitive operations.
              _showPasswordConfirmDialog();
            },
            child: Text(LocalizationService.translate('Delete'), style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// Purpose: Prompts the user to enter their password to re-authenticate before account deletion.
  /// Inputs: None.
  /// Outputs: Prompts a Dialog and potentially routes to the WelcomeScreen.
  void _showPasswordConfirmDialog() {
    final passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(LocalizationService.translate('Confirm Password')),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          decoration: InputDecoration(hintText: LocalizationService.translate('Enter your password')),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(LocalizationService.translate('Cancel'))),
          TextButton(
            onPressed: () async {
              // 1. Pop the dialog to prevent double submission.
              Navigator.pop(context);
              // 2. Delegate the deletion workflow to the backend.
              final success = await _backend.deleteAccount(password: passwordController.text);
              // 3. Clear the entire navigation stack and redirect to the unauthenticated Welcome screen.
              if (success && mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                  (route) => false,
                );
              }
            },
            child: Text(LocalizationService.translate('Delete Account'), style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// Purpose: Shows a confirmation dialog before signing the user out.
  /// Inputs: None.
  /// Outputs: Displays an AlertDialog and subsequently performs Firebase Sign Out.
  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(LocalizationService.translate('Logout'), style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontFamily: 'Arimo')),
        content: Text(LocalizationService.translate('Are you sure you want to logout?'), style: const TextStyle(fontFamily: 'Arimo', fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: Text(LocalizationService.translate('Cancel'), style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey, fontFamily: 'Arimo'))
          ),
          TextButton(
            onPressed: () async {
              // 1. Close the dialog.
              Navigator.pop(context);
              
              // 2. Show a non-dismissible loading indicator during the network request.
              showDialog(
                context: context, 
                barrierDismissible: false,
                builder: (_) => const Center(child: CircularProgressIndicator())
              );

              // 3. Perform actual Firebase Auth Sign Out via the dedicated AuthService singleton.
              await AuthService.instance.signOut();

              // 4. Navigate back to the Welcome Screen, clearing all previous routes.
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                (route) => false,
              );
            },
            child: Text(LocalizationService.translate('Logout'), style: const TextStyle(color: Colors.red, fontFamily: 'Arimo')),
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

  /// Purpose: Initializes the editing form with current user profile data.
  /// Inputs: None.
  /// Outputs: None.
  @override
  void initState() {
    super.initState();
    // 1. Populate text controllers with existing data or empty strings to prevent null errors.
    _nameController = TextEditingController(text: widget.userProfile?.fullName ?? '');
    _farmController = TextEditingController(text: widget.userProfile?.farmName ?? '');
    _emailController = TextEditingController(text: widget.userProfile?.email ?? '');
    _phoneController = TextEditingController(text: widget.userProfile?.phone ?? '');
    _locationController = TextEditingController(text: widget.userProfile?.location ?? '');
    _loadProfileImage();
  }

  /// Purpose: Fetches the cached local image path for the avatar.
  /// Inputs: None.
  /// Outputs: Updates state with the image URL.
  void _loadProfileImage() async {
    try {
      final url = await widget.backend.getProfileImageUrl();
      if (mounted) {
        setState(() => _profileImageUrl = url);
      }
    } catch (e) {
      print(' Error loading profile image: $e');
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

  /// Purpose: Validates the form and saves the updated profile to Firestore.
  /// Inputs: None.
  /// Outputs: Updates state and shows a SnackBar on success/failure.
  Future<void> _saveProfile() async {
    // 1. Trigger built-in Flutter form validation (checks for empty fields, etc.).
    if (!_formKey.currentState!.validate()) return;

    // 2. Lock the UI to prevent duplicate submissions.
    setState(() => _isSaving = true);

    try {
      // 3. Delegate to the backend service, trimming whitespace from user input.
      final success = await widget.backend.updateUserProfile(
        fullName: _nameController.text.trim(),
        farmName: _farmController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        location: _locationController.text.trim(),
      );

      if (mounted) {
        // 4. Unlock UI.
        setState(() => _isSaving = false);

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(LocalizationService.translate('Profile updated successfully!')),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
          // 5. Pop the edit screen off the stack, returning to settings.
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(LocalizationService.translate('Failed to update profile. Please try again.')),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print(' Error: $e');
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Purpose: Opens a bottom sheet menu to let the user pick the source of their avatar image.
  /// Inputs: None.
  /// Outputs: Shows a ModalBottomSheet.
  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Visual handle indicating the sheet can be dragged.
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
                style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 18, fontFamily: 'Arimo', fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 20),
              // 2. Option: Camera launch.
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  _pickPhotoFromCamera();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).dividerColor),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt, color: Theme.of(context).colorScheme.primary, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        LocalizationService.translate('Take Photo'),
                        style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 16, fontFamily: 'Arimo', fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // 3. Option: Gallery launch.
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  _pickPhotoFromGallery();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).dividerColor),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image, color: Theme.of(context).colorScheme.primary, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        LocalizationService.translate('Choose from Gallery'),
                        style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 16, fontFamily: 'Arimo', fontWeight: FontWeight.w500),
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
                      border: Border.all(color: Colors.red),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.delete, color: Colors.red, size: 24),
                        const SizedBox(width: 12),
                        Text(
                          LocalizationService.translate('Remove Photo'),
                          style: const TextStyle(color: Colors.red, fontSize: 16, fontFamily: 'Arimo', fontWeight: FontWeight.w500),
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
                      style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 16, fontFamily: 'Arimo', fontWeight: FontWeight.w500),
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

  /// Purpose: Handles launching the camera and initiating the upload process.
  /// Inputs: None.
  /// Outputs: None.
  Future<void> _pickPhotoFromCamera() async {
    // 1. Lock the photo UI buttons while processing.
    setState(() => _isUploadingPhoto = true);
    try {
      // 2. Await the native camera bridge via the backend.
      final imageFile = await widget.backend.pickImageFromCamera();
      if (imageFile != null && mounted) {
        // 3. Immediately queue the upload if a file was successfully captured.
        await _uploadProfileImage(imageFile);
      }
    } catch (e) {
      print(' Error picking image from camera: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      // 4. Ensure the UI is unlocked regardless of success or exception.
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  /// Purpose: Handles launching the device gallery and initiating the upload process.
  /// Inputs: None.
  /// Outputs: None.
  Future<void> _pickPhotoFromGallery() async {
    setState(() => _isUploadingPhoto = true);
    try {
      final imageFile = await widget.backend.pickImageFromGallery();
      if (imageFile != null && mounted) {
        await _uploadProfileImage(imageFile);
      }
    } catch (e) {
      print(' Error picking image from gallery: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  /// Purpose: Manages the end-to-end pipeline of pushing the image file to local storage/Firestore and updating the UI state.
  /// Inputs: [imageFile] - The captured file.
  /// Outputs: Shows a SnackBar on success.
  Future<void> _uploadProfileImage(dynamic imageFile) async {
    try {
      // 1. Await the disk IO operations in the backend service.
      await widget.backend.uploadProfileImage(imageFile);
      // 2. Fetch the newly cached URL/path.
      final url = await widget.backend.getProfileImageUrl();
      if (mounted) {
        // 3. Force a rebuild of the avatar widget to show the new image.
        setState(() => _profileImageUrl = url);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LocalizationService.translate('Profile photo updated successfully!')),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      print(' Error uploading profile image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Purpose: Deletes the profile photo from disk and Firestore, clearing the local UI.
  /// Inputs: None.
  /// Outputs: Shows a confirmation SnackBar.
  Future<void> _deleteProfilePhoto() async {
    try {
      // 1. Issue the delete command to the backend.
      await widget.backend.deleteProfileImage();
      if (mounted) {
        // 2. Nullify the local state, forcing the widget tree to fallback to the text avatar.
        setState(() => _profileImageUrl = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LocalizationService.translate('Profile photo removed')),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      print(' Error deleting profile image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Purpose: Root layout builder for the ProfileEditScreen, rendering the avatar picker and form fields.
  /// Inputs: [context] - The BuildContext.
  /// Outputs: Returns a Scaffold containing the editing form.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader('Edit Profile'),
              Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))],
                ),
                child: Form(
                  // 1. Attach the global form key used during the save routine validation.
                  key: _formKey,
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Column(
                          children: [
                            // 2. Avatar container.
                            Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.primary],
                                ),
                                borderRadius: BorderRadius.circular(48),
                              ),
                              // 3. Render the file image if available, else fallback to text initialization.
                              child: _profileImageUrl != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(48),
                                      child: Image.file(File(_profileImageUrl!), fit: BoxFit.cover),
                                    )
                                  : Center(
                                      child: Text(
                                        (_nameController.text.isEmpty ? 'R' : _nameController.text[0]).toUpperCase(),
                                        style: TextStyle(color: Theme.of(context).cardColor, fontSize: 36, fontFamily: 'Arimo', fontWeight: FontWeight.w400),
                                      ),
                                    ),
                            ),
                            SizedBox(height: 16),
                            GestureDetector(
                              onTap: _isUploadingPhoto ? null : _showPhotoOptions,
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                                child: _isUploadingPhoto
                                    ? SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary, strokeWidth: 2),
                                      )
                                    : Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.camera_alt, color: Theme.of(context).colorScheme.primary, size: 16),
                                          const SizedBox(width: 8),
                                          Text(LocalizationService.translate('Change Photo'), style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 16, fontFamily: 'Arimo', fontWeight: FontWeight.w400)),
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
                                  decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(10)),
                                  child: Center(
                                    child: _isSaving
                                        ? SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(color: Theme.of(context).cardColor, strokeWidth: 2),
                                          )
                                        : Text(LocalizationService.translate('Save Changes'), style: TextStyle(color: Theme.of(context).cardColor, fontSize: 16, fontFamily: 'Arimo', fontWeight: FontWeight.w400)),
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
                                  child: Center(child: Text(LocalizationService.translate('Cancel'), style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 16, fontFamily: 'Arimo', fontWeight: FontWeight.w400))),
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

  /// Purpose: Builds a simple top header bar specifically for sub-screens.
  /// Inputs: [title] - Header text.
  /// Outputs: Returns a Container.
  Widget _buildHeader(String title) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor, width: 1.3))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 1. Back navigation button.
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
              child: Icon(Icons.arrow_back, color: Theme.of(context).textTheme.bodyLarge?.color),
            ),
          ),
          Text(title, style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 16, fontFamily: 'Arimo', fontWeight: FontWeight.w400)),
          // 2. Empty spacer to ensure the title is perfectly centered.
          Container(width: 36, height: 36, decoration: BoxDecoration(borderRadius: BorderRadius.circular(8))),
        ],
      ),
    );
  }

  /// Purpose: Standardizes the appearance of text input fields across the form.
  /// Inputs: [label] - Input name, [controller] - The controller retaining the value.
  /// Outputs: Returns a configured TextFormField block.
  Widget _buildTextField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 16, fontFamily: 'Arimo', fontWeight: FontWeight.w400)),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 16, fontFamily: 'Arimo', fontWeight: FontWeight.w400),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            // 1. Implement unified border styles across normal/enabled/focused states.
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFD0D5DB), width: 1.3)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFD0D5DB), width: 1.3)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.3)),
          ),
          // 2. Inject basic required-field validation.
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

  /// Purpose: Validates the old and new passwords, then issues a re-authentication and update command to the backend.
  /// Inputs: None.
  /// Outputs: Rebuilds UI and shows SnackBar feedback.
  Future<void> _changePassword() async {
    // 1. Verify standard constraints (length, matching confirmations).
    if (!_formKey.currentState!.validate()) return;

    // 2. Lock UI while talking to Firebase Auth.
    setState(() => _isChanging = true);

    try {
      // 3. Delegate the complex re-auth workflow to the SettingsBackend.
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
              backgroundColor: Theme.of(context).colorScheme.primary,
              duration: Duration(seconds: 2),
            ),
          );
          // 4. Delay the pop slightly so the user can read the success message.
          Future.delayed(Duration(seconds: 2), () {
            if (mounted) Navigator.pop(context);
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(LocalizationService.translate('Failed to change password. Please verify your old password and try again.')),
              backgroundColor: Colors.red,
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
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Purpose: Root layout builder for the ChangePasswordScreen, rendering the three required password fields.
  /// Inputs: [context] - The BuildContext.
  /// Outputs: Returns a Scaffold containing the password change form.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // 1. Custom back-navigation header.
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Theme.of(context).cardColor,
                  border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor, width: 1.3)),
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
                        child: Icon(Icons.arrow_back, color: Theme.of(context).textTheme.bodyLarge?.color),
                      ),
                    ),
                    Text(LocalizationService.translate('Change Password'),
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
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
              
              // 2. Main interactive form container.
              Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))],
                ),
                child: Form(
                  // 3. Attach form key for bulk validation.
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
                                  decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(10)),
                                  child: Center(
                                    child: _isChanging
                                        ? SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(color: Theme.of(context).cardColor, strokeWidth: 2),
                                          )
                                        : Text(LocalizationService.translate('Change Password'), style: TextStyle(color: Theme.of(context).cardColor, fontSize: 16, fontFamily: 'Arimo', fontWeight: FontWeight.w400)),
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
                                  child: Center(child: Text(LocalizationService.translate('Cancel'), style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 16, fontFamily: 'Arimo', fontWeight: FontWeight.w400))),
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

  /// Purpose: Standardizes the appearance and behavior of sensitive text input fields.
  /// Inputs: [label], [controller], [isVisible] boolean, [onToggle] callback for visibility, and an optional [validator].
  /// Outputs: Returns a configured TextFormField.
  Widget _buildPasswordField(String label, TextEditingController controller, bool isVisible, VoidCallback onToggle, {String? Function(String?)? validator}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 16, fontFamily: 'Arimo', fontWeight: FontWeight.w400)),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          // 1. Obscure characters unless explicitly toggled by the user.
          obscureText: !isVisible,
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 16, fontFamily: 'Arimo', fontWeight: FontWeight.w400),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFD0D5DB), width: 1.3)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFD0D5DB), width: 1.3)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.3)),
            // 2. Render the interactive eye icon in the suffix slot.
            suffixIcon: IconButton(icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off, color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey), onPressed: onToggle),
          ),
          // 3. Fallback to basic length validation if no custom validator is provided.
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

  /// Purpose: Renders a static informational card listing password criteria.
  /// Inputs: None.
  /// Outputs: Returns a styled Container.
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

  /// Purpose: Helper component to render a single criteria line with a check icon.
  /// Inputs: [text] - The rule text.
  /// Outputs: Returns a Row widget.
  Widget _buildRequirement(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(children: [
        Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary, size: 16),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 14, fontFamily: 'Arimo', fontWeight: FontWeight.w400)),
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
      print(' Error loading notification preferences: $e');
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
            backgroundColor: Theme.of(context).colorScheme.primary,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      if (mounted) {
        setState(() => _isSaving = false);
      }
    } catch (e) {
      print(' Error saving notification preferences: $e');
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
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
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    int enabledCount = alertTypes.values.where((value) => value).length + notificationChannels.values.where((value) => value).length;
    int maxCount = alertTypes.length + notificationChannels.length;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
        gradient: LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.primary]),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 6, offset: const Offset(0, 4))],
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
                  decoration: BoxDecoration(color: Theme.of(context).cardColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                  child: Icon(Icons.arrow_back, color: Theme.of(context).cardColor, size: 16),
                ),
              ),
              const SizedBox(width: 16),
              Text(title, style: TextStyle(color: Theme.of(context).cardColor, fontSize: 24, fontFamily: 'Arimo', fontWeight: FontWeight.w400)),
            ],
          ),
          const SizedBox(height: 16),
          Text(subtitle, style: TextStyle(color: Theme.of(context).cardColor.withValues(alpha: 0.8), fontSize: 16, fontFamily: 'Arimo', fontWeight: FontWeight.w400)),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(int enabledCount, int maxCount) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(LocalizationService.translate('Active Notifications'), style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 18, fontFamily: 'Arimo', fontWeight: FontWeight.w400)),
              const SizedBox(height: 4),
              Text(LocalizationService.translate('You have {count} notifications enabled').replaceAll('{count}', '$enabledCount'), style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 16, fontFamily: 'Arimo', fontWeight: FontWeight.w400)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
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
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor, width: 1.3))),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 20, fontFamily: 'Arimo', fontWeight: FontWeight.w400)),
                      Text(subtitle, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 16, fontFamily: 'Arimo', fontWeight: FontWeight.w400)),
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
      decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: BorderRadius.circular(10)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(title, style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 16, fontFamily: 'Arimo', fontWeight: FontWeight.w400)),
                    const SizedBox(width: 8),
                    if (value)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                        child: Text(LocalizationService.translate('Active'), style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 12, fontFamily: 'Arimo', fontWeight: FontWeight.w400)),
                      ),
                  ],
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(description, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 16, fontFamily: 'Arimo', fontWeight: FontWeight.w400)),
                ],
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged, activeThumbColor: Theme.of(context).colorScheme.primary),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(LocalizationService.translate('Quick Actions'), style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 16, fontFamily: 'Arimo', fontWeight: FontWeight.w400)),
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
                    decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(10)),
                    child: Center(child: Text(LocalizationService.translate('Enable All'), style: TextStyle(color: Theme.of(context).cardColor, fontSize: 16, fontFamily: 'Arimo', fontWeight: FontWeight.w400))),
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
                    child: Center(child: Text(LocalizationService.translate('Disable All'), style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 16, fontFamily: 'Arimo', fontWeight: FontWeight.w400))),
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
            margin: EdgeInsets.only(top: 8),
            decoration: BoxDecoration(color: Color(0xFF0D532B), borderRadius: BorderRadius.circular(3)),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(LocalizationService.translate('About Notifications'), style: TextStyle(color: Color(0xFF0D532B), fontSize: 16, fontFamily: 'Arimo', fontWeight: FontWeight.w400)),
                SizedBox(height: 4),
                Text(LocalizationService.translate('We recommend keeping critical alerts like weather and pest notifications enabled to stay informed about important farming conditions.'),
                  style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 16, fontFamily: 'Arimo', fontWeight: FontWeight.w400),
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
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2))],
          ),
          child: Center(
            child: _isSaving
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Theme.of(context).cardColor, strokeWidth: 2),
                  )
                : Text(LocalizationService.translate('Save Preferences'), style: TextStyle(color: Theme.of(context).cardColor, fontSize: 16, fontFamily: 'Arimo', fontWeight: FontWeight.w400)),
          ),
        ),
      ),
    );
  }
}