import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'notification.dart';
import 'localization_service.dart';

/// Purpose: A Singleton service to manage all in-app notifications. Integrates with FCM (Firebase Cloud Messaging) and local Firestore collections.
/// Integrates with Weather, Pest, Water, Crop, and other services.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  String get userId => _auth.currentUser?.uid ?? '';
  bool get isAuthenticated => userId.isNotEmpty;

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  /// Purpose: Requests iOS/Android permissions for push notifications and initializes the FlutterLocalNotificationsPlugin channels.
  /// Inputs: None.
  /// Outputs: Sets up background and foreground message listeners.
  Future<void> initFCM() async {
    // 1. Request native OS permissions for displaying alerts, updating badges, and playing sounds.
    NotificationSettings settings = await _fcm.requestPermission(alert: true, badge: true, sound: true);
    
    // 2. Abort initialization if the user denied notification permissions.
    if (settings.authorizationStatus != AuthorizationStatus.authorized) return;

    // 3. Define the Android launcher icon to use in the system tray.
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    // 4. Initialize iOS specific settings (default empty parameters suffice for basic pushes).
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();
    // 5. Bundle platform settings and initialize the local notifications plugin.
    const InitializationSettings initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _localNotifications.initialize(settings: initSettings);

    // 6. Set up a listener for push payloads received while the app is actively in the foreground.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      if (notification == null) return;
      
      // 7. Render a local system tray notification using the received payload.
      _localNotifications.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails('smart_kisan_channel', 'Smart Kisan Alerts', importance: Importance.high),
          iOS: DarwinNotificationDetails(),
        ),
      );
    });
  }

  /// Purpose: Retrieves the unique hardware FCM token and binds it to the user's Firestore profile.
  /// Inputs: [userId] - The authenticated Firebase UID.
  /// Outputs: Updates the 'fcmToken' field in the 'users' collection.
  Future<void> saveFcmToken(String userId) async {
    // 1. Ask the Firebase backend for the device's unique routing token.
    String? token = await _fcm.getToken();
    if (token != null) {
      // 2. Perform an atomic update on the user's profile document.
      await FirebaseFirestore.instance.collection('users').doc(userId).update({'fcmToken': token});
    }
  }

  
  /// WEATHER NOTIFICATIONS
  
  /// Create notification for high temperature
  Future<void> notifyHighTemperature({
    required double temperature,
    required String location,
  }) async {
    final notification = NotificationModel(
      id: '',
      title: 'High Temperature Alert',
      message:
          'Temperature is ${temperature.toStringAsFixed(1)}°C. Ensure adequate watering of crops to prevent heat stress.',
      time: Timestamp.now(),
      type: NotificationType.weather,
      priority: NotificationPriority.high,
    );
    await _saveNotification(notification);
  }

  /// Create notification for low temperature
  Future<void> notifyLowTemperature({
    required double temperature,
    required String location,
  }) async {
    final notification = NotificationModel(
      id: '',
      title: 'Low Temperature Warning',
      message:
          'Temperature dropped to ${temperature.toStringAsFixed(1)}°C. Protect seedlings and tender crops from frost.',
      time: Timestamp.now(),
      type: NotificationType.weather,
      priority: NotificationPriority.high,
    );
    await _saveNotification(notification);
  }

  /// Create notification for rain
  Future<void> notifyRainAlert({
    required String rainType,
    required String location,
  }) async {
    String message;
    if (rainType.toLowerCase().contains('heavy')) {
      message =
          'Heavy rainfall expected! Delay fertilizer application and protect young plants.';
    } else if (rainType.toLowerCase().contains('light')) {
      message = 'Light rain expected. Good time for irrigation-dependent crops.';
    } else {
      message = 'Rain alert: $rainType. Check field conditions before irrigation.';
    }

    final notification = NotificationModel(
      id: '',
      title: 'Rain Alert',
      message: message,
      time: Timestamp.now(),
      type: NotificationType.weather,
      priority: rainType.toLowerCase().contains('heavy')
          ? NotificationPriority.high
          : NotificationPriority.normal,
    );
    await _saveNotification(notification);
  }

  /// Purpose: Evaluates humidity data and generates a targeted agronomic alert.
  /// Inputs: [humidity] (double percentage), [location] (optional string).
  /// Outputs: Calls [_saveNotification] to persist the alert.
  Future<void> notifyHumidityLevel({
    required double humidity,
    String? location,
  }) async {
    String title;
    String message;
    NotificationPriority priority;

    // 1. Agronomic Logic: Humidity > 80% increases fungal disease risk.
    if (humidity > 80) {
      title = 'High Humidity Alert';
      message =
          'Humidity is ${humidity.toInt()}%. Risk of fungal diseases. Ensure proper ventilation.';
      priority = NotificationPriority.high;
    // 2. Agronomic Logic: Humidity < 30% increases transpiration stress.
    } else if (humidity < 30) {
      title = 'Low Humidity Alert';
      message =
          'Humidity is ${humidity.toInt()}%. Increase irrigation frequency to maintain soil moisture.';
      priority = NotificationPriority.normal;
    // 3. Agronomic Logic: 30% - 80% is considered optimal for general crop growth.
    } else {
      title = 'Optimal Humidity';
      message = 'Current humidity ${humidity.toInt()}% is suitable for crop growth.';
      priority = NotificationPriority.low;
    }

    // 4. Construct the standardized data model.
    final notification = NotificationModel(
      id: '',
      title: title,
      message: message,
      time: Timestamp.now(),
      type: NotificationType.weather,
      priority: priority,
    );
    
    // 5. Persist to Firestore.
    await _saveNotification(notification);
  }

  /// ============================================
  /// PEST & DISEASE NOTIFICATIONS
  /// ============================================

  /// Create notification for pest detection
  Future<void> notifyPestDetected({
    required String pestName,
    required String cropName,
    required String severity,
    required String treatment,
  }) async {
    final priority = severity.toLowerCase() == 'high'
        ? NotificationPriority.high
        : severity.toLowerCase() == 'medium'
            ? NotificationPriority.normal
            : NotificationPriority.low;

    final notification = NotificationModel(
      id: '',
      title: '$pestName Detected',
      message:
          '$pestName found on your $cropName. Severity: $severity.\nTreatment: $treatment',
      time: Timestamp.now(),
      type: NotificationType.pest,
      priority: priority,
    );
    await _saveNotification(notification);
  }

  /// Create notification for disease detected
  Future<void> notifyDiseaseDetected({
    required String diseaseName,
    required String cropName,
    required String symptoms,
    required String prevention,
  }) async {
    final notification = NotificationModel(
      id: '',
      title: '$diseaseName Alert',
      message:
          '$diseaseName detected on $cropName.\nSymptoms: $symptoms\nPrevention: $prevention',
      time: Timestamp.now(),
      type: NotificationType.pest,
      priority: NotificationPriority.high,
    );
    await _saveNotification(notification);
  }

  /// ============================================
  /// WATER/IRRIGATION NOTIFICATIONS
  /// ============================================

  /// Create notification for low soil moisture
  Future<void> notifyLowSoilMoisture({
    required double soilMoisture,
    required String cropName,
    required int hoursToIrrigate,
  }) async {
    final notification = NotificationModel(
      id: '',
      title: 'Low Soil Moisture Alert',
      message:
          'Soil moisture for $cropName is ${soilMoisture.toStringAsFixed(1)}%. Irrigate within $hoursToIrrigate hours for optimal growth.',
      time: Timestamp.now(),
      type: NotificationType.irrigation,
      priority: NotificationPriority.high,
    );
    await _saveNotification(notification);
  }

  /// Create notification for waterlogging
  Future<void> notifyWaterlogging({
    required String cropName,
    required double soilMoisture,
  }) async {
    final notification = NotificationModel(
      id: '',
      title: 'Waterlogging Alert',
      message:
          '$cropName is experiencing waterlogging (${soilMoisture.toStringAsFixed(1)}% soil moisture). Improve drainage immediately.',
      time: Timestamp.now(),
      type: NotificationType.irrigation,
      priority: NotificationPriority.high,
    );
    await _saveNotification(notification);
  }

  /// Create notification for water optimization recommendation
  Future<void> notifyWaterOptimization({
    required String cropName,
    required double recommendedWater,
    required String waterUnit,
  }) async {
    final notification = NotificationModel(
      id: '',
      title: 'Water Optimization Tip',
      message:
          'Recommended water for $cropName: ${recommendedWater.toStringAsFixed(2)} $waterUnit. This will optimize your crop yield.',
      time: Timestamp.now(),
      type: NotificationType.irrigation,
      priority: NotificationPriority.normal,
    );
    await _saveNotification(notification);
  }

  /// ============================================
  /// CROP NOTIFICATIONS
  /// ============================================

  /// Create notification for crop health
  Future<void> notifyCropHealth({
    required String cropName,
    required String healthStatus,
    required String observation,
  }) async {
    final priority = healthStatus.toLowerCase() == 'poor'
        ? NotificationPriority.high
        : healthStatus.toLowerCase() == 'fair'
            ? NotificationPriority.normal
            : NotificationPriority.low;

    final notification = NotificationModel(
      id: '',
      title: '$cropName Health Status: $healthStatus',
      message: observation,
      time: Timestamp.now(),
      type: NotificationType.crop,
      priority: priority,
    );
    await _saveNotification(notification);
  }

  /// Create notification for planting reminder
  Future<void> notifyPlantingTime({
    required String cropName,
    required String season,
    required String soilCondition,
  }) async {
    final notification = NotificationModel(
      id: '',
      title: 'Planting Time: $cropName',
      message:
          'It\'s a good time to plant $cropName in $season. Soil condition: $soilCondition. Prepare your fields now.',
      time: Timestamp.now(),
      type: NotificationType.crop,
      priority: NotificationPriority.normal,
    );
    await _saveNotification(notification);
  }

  /// Create notification for harvest reminder
  Future<void> notifyHarvestTime({
    required String cropName,
    required int daysUntilHarvest,
    required String harvestIndicators,
  }) async {
    final priority = daysUntilHarvest <= 7
        ? NotificationPriority.high
        : NotificationPriority.normal;

    final notification = NotificationModel(
      id: '',
      title: 'Harvest Ready: $cropName',
      message:
          '$cropName will be ready to harvest in $daysUntilHarvest days. Indicators: $harvestIndicators',
      time: Timestamp.now(),
      type: NotificationType.crop,
      priority: priority,
    );
    await _saveNotification(notification);
  }

  /// Create notification for growth stage milestone
  Future<void> notifyGrowthStage({
    required String cropName,
    required String growthStage,
    required String recommendations,
  }) async {
    final notification = NotificationModel(
      id: '',
      title: '$cropName - $growthStage Stage',
      message: recommendations,
      time: Timestamp.now(),
      type: NotificationType.crop,
      priority: NotificationPriority.normal,
    );
    await _saveNotification(notification);
  }

  /// ============================================
  /// FIELD MANAGEMENT NOTIFICATIONS
  /// ============================================

  /// Create notification for new field creation
  Future<void> notifyFieldCreated({
    required String fieldName,
    required double area,
    required String areaUnit,
    required String cropType,
  }) async {
    final notification = NotificationModel(
      id: '',
      title: 'New Field Added',
      message:
          'Field "$fieldName" created with area $area $areaUnit for growing $cropType. Start monitoring your field.',
      time: Timestamp.now(),
      type: NotificationType.system,
      priority: NotificationPriority.normal,
    );
    await _saveNotification(notification);
  }

  /// Create notification for field soil test results
  Future<void> notifySoilTestResults({
    required String fieldName,
    required Map<String, dynamic> soilResults,
  }) async {
    String message = 'Soil test results for $fieldName:\n';
    soilResults.forEach((key, value) {
      message += '• $key: $value\n';
    });

    final notification = NotificationModel(
      id: '',
      title: 'Soil Test Results',
      message: message,
      time: Timestamp.now(),
      type: NotificationType.crop,
      priority: NotificationPriority.normal,
    );
    await _saveNotification(notification);
  }

  /// ============================================
  /// SCANNING & ANALYSIS NOTIFICATIONS
  /// ============================================

  /// Purpose: Generates an alert summarizing the results of an AI plant scan.
  /// Inputs: [cropName], [analysisResult], [confidence] (0.0 to 1.0), [recommendations].
  /// Outputs: Calls [_saveNotification] to persist the alert.
  Future<void> notifyPlantScanAnalysis({
    required String cropName,
    required String analysisResult,
    required double confidence,
    required String recommendations,
  }) async {
    // 1. Escalate priority only if the AI model is highly confident (> 80%).
    final priority = confidence > 0.8
        ? NotificationPriority.high
        : NotificationPriority.normal;

    // 2. Construct the data model, formatting the confidence decimal to a readable percentage.
    final notification = NotificationModel(
      id: '',
      title: 'Plant Scan Analysis Complete',
      message:
          'Analysis of $cropName completed with ${(confidence * 100).toStringAsFixed(1)}% confidence.\nResult: $analysisResult\nRecommendation: $recommendations',
      time: Timestamp.now(),
      type: NotificationType.crop,
      priority: priority,
    );
    
    // 3. Persist to Firestore.
    await _saveNotification(notification);
  }

  /// Create notification for disease detected in scan
  Future<void> notifyDiseaseScanDetected({
    required String cropName,
    required String diseaseName,
    required double confidence,
    required String treatment,
  }) async {
    final notification = NotificationModel(
      id: '',
      title: 'Disease Detected in Scan',
      message:
          '$diseaseName detected on $cropName (${(confidence * 100).toStringAsFixed(1)}% confidence).\nTreatment: $treatment',
      time: Timestamp.now(),
      type: NotificationType.pest,
      priority: NotificationPriority.high,
    );
    await _saveNotification(notification);
  }

  /// ============================================
  /// RESOLUTION NOTIFICATIONS
  /// ============================================

  /// Create notification when an alert is resolved
  Future<void> notifyAlertResolved({
    required String alertType,
    required String alertName,
    required String resolutionAction,
  }) async {
    final notification = NotificationModel(
      id: '',
      title: '$alertName Resolved ',
      message: 'Alert has been resolved with: $resolutionAction',
      time: Timestamp.now(),
      type: _getTypeFromAlertType(alertType),
      priority: NotificationPriority.normal,
    );
    await _saveNotification(notification);
  }

  /// Create notification for pest alert resolution
  Future<void> notifyPestAlertResolved({
    required String pestName,
    required String treatment,
  }) async {
    final notification = NotificationModel(
      id: '',
      title: 'Pest Alert Resolved ',
      message: '$pestName pest has been treated with: $treatment',
      time: Timestamp.now(),
      type: NotificationType.pest,
      priority: NotificationPriority.normal,
    );
    await _saveNotification(notification);
  }

  /// Create notification for disease alert resolution
  Future<void> notifyDiseaseAlertResolved({
    required String diseaseName,
    required String treatment,
  }) async {
    final notification = NotificationModel(
      id: '',
      title: 'Disease Alert Resolved ',
      message: '$diseaseName has been treated with: $treatment',
      time: Timestamp.now(),
      type: NotificationType.pest,
      priority: NotificationPriority.normal,
    );
    await _saveNotification(notification);
  }

  /// Create notification for water/irrigation alert resolution
  Future<void> notifyWaterAlertResolved({
    required String fieldName,
    required String action,
  }) async {
    final notification = NotificationModel(
      id: '',
      title: 'Water Alert Resolved ',
      message: '$fieldName: $action',
      time: Timestamp.now(),
      type: NotificationType.irrigation,
      priority: NotificationPriority.normal,
    );
    await _saveNotification(notification);
  }

  /// Create notification for crop health alert resolution
  Future<void> notifyCropAlertResolved({
    required String cropName,
    required String issue,
    required String solution,
  }) async {
    final notification = NotificationModel(
      id: '',
      title: 'Crop Health Alert Resolved ',
      message: '$cropName - $issue: $solution',
      time: Timestamp.now(),
      type: NotificationType.crop,
      priority: NotificationPriority.normal,
    );
    await _saveNotification(notification);
  }

  /// Helper method to convert alert type string to NotificationType
  NotificationType _getTypeFromAlertType(String alertType) {
    switch (alertType.toLowerCase()) {
      case 'pest':
        return NotificationType.pest;
      case 'disease':
        return NotificationType.pest;
      case 'water':
      case 'irrigation':
        return NotificationType.irrigation;
      case 'weather':
        return NotificationType.weather;
      case 'crop':
        return NotificationType.crop;
      default:
        return NotificationType.system;
    }
  }

  /// ============================================
  /// ADVISORY NOTIFICATIONS
  /// ============================================

  /// Create notification for crop advisory
  Future<void> notifyCropAdvisory({
    required String cropName,
    required String advisoryTitle,
    required String advisoryDetails,
  }) async {
    final notification = NotificationModel(
      id: '',
      title: 'Advisory: $advisoryTitle',
      message: '$cropName - $advisoryDetails',
      time: Timestamp.now(),
      type: NotificationType.crop,
      priority: NotificationPriority.normal,
    );
    await _saveNotification(notification);
  }

  // Create notification for weather-based advisory
  Future<void> notifyWeatherAdvisory({
    required String weatherCondition,
    required String advice,
  }) async {
    final notification = NotificationModel(
      id: '',
      title: 'Weather Advisory',
      message: '$weatherCondition\nAdvice: $advice',
      time: Timestamp.now(),
      type: NotificationType.weather,
      priority: NotificationPriority.normal,
    );
    await _saveNotification(notification);
  }

  // HELPER METHODS
  

  /// Purpose: Commits a [NotificationModel] directly into the current authenticated user's `notifications` subcollection in Firestore.
  /// Inputs: [notification] - The constructed data model.
  /// Outputs: A Future completing when the document is saved.
  Future<void> _saveNotification(NotificationModel notification) async {
    if (!isAuthenticated) {
      print(' User not authenticated, cannot save notification');
      return;
    }
    
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add(notification.toFirestore());
      print(' Notification saved: ${notification.title}');
    } catch (e) {
      print(' Error saving notification: $e');
    }
  }

  /// Purpose: Queries Firestore for the total number of unread notifications for the active user.
  /// Inputs: None.
  /// Outputs: Returns an integer count. Returns 0 if unauthenticated or on error.
  Future<int> getUnreadCount() async {
    // 1. Guard against unauthenticated queries to prevent permission crashes.
    if (!isAuthenticated) return 0;
    
    try {
      // 2. Execute a filtered query specifically searching for the 'isRead' boolean flag.
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();
      // 3. Count the returned documents.
      return snapshot.docs.length;
    } catch (e) {
      print(' Error getting unread count: $e');
      return 0;
    }
  }

  /// Purpose: Mutates a specific notification document's state to 'read'.
  /// Inputs: [notificationId] - The Firestore document ID.
  /// Outputs: Updates the database asynchronously.
  Future<void> markAsRead(String notificationId) async {
    if (!isAuthenticated) return;
    
    try {
      // 1. Target the specific document using its unique ID and update the boolean flag.
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      print(' Error marking as read: $e');
    }
  }

  /// Purpose: Permanently deletes a specific notification document.
  /// Inputs: [notificationId] - The Firestore document ID.
  /// Outputs: Removes the document from the database asynchronously.
  Future<void> deleteNotification(String notificationId) async {
    if (!isAuthenticated) return;
    
    try {
      // 1. Execute the destructive delete operation on the target document.
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .delete();
    } catch (e) {
      print(' Error deleting notification: $e');
    }
  }

  /// Get notification stream (real-time updates)
  Stream<QuerySnapshot> getNotificationsStream() {
    if (!isAuthenticated) {
      return Stream.empty();
    }
    
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('time', descending: true)
        .snapshots();
  }

  /// Get unread notifications stream
  Stream<QuerySnapshot> getUnreadNotificationsStream() {
    if (!isAuthenticated) {
      return Stream.empty();
    }
    
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .orderBy('time', descending: true)
        .snapshots();
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Background message: ${message.messageId}');
}