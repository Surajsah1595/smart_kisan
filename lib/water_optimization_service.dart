import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'weather_service.dart';
import 'notification_service.dart';

class WaterOptimizationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final WeatherService _weatherService = WeatherService();
  final NotificationService _notificationService = NotificationService();

  String get userId => _auth.currentUser?.uid ?? '';

  // ============ HELPERS ============

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Convert any area unit to Hectares (Standard Agricultural Unit)
  double _convertToHectares(double area, String unit) {
    switch (unit.toLowerCase()) {
      case 'acres':
        return area * 0.404686; // 1 acre = ~0.404 ha
      case 'hectares':
        return area;
      case 'sqm':
        return area / 10000.0; // 10,000 sqm = 1 ha
      default:
        return area;
    }
  }

  // ============ PRECISE WATER CALCULATION (STANDARD) ============

  Map<String, dynamic> calculateWaterRequirement({
    required double area,
    required String areaUnit,
    required String cropType,
    required String soilType,
    required int growingDays,
  }) {
    if (area <= 0) {
      return {
        'success': false,
        'message': 'Land area must be greater than 0',
        'water': 0,
      };
    }

    // 1. STANDARDIZE AREA
    double areaHectares = _convertToHectares(area, areaUnit);
    
    // Constant: 1 mm of water depth over 1 hectare = 10,000 Liters
    const double mmToLitersPerHa = 10000.0;

    // 2. CROP ETc (Evapotranspiration in mm/day)
    final cropEtcDaily = {
      'rice': 6.0, 'wheat': 4.0, 'corn': 5.0, 'sugarcane': 8.0, 'cotton': 6.0,
      'potato': 5.0, 'tomato': 4.5, 'onion': 3.0, 'cabbage': 4.0, 'carrot': 4.0,
      'cucumber': 4.5, 'pepper': 5.0, 'spinach': 3.5, 'lettuce': 3.0, 'radish': 2.5,
      'brinjal': 5.0, 'cauliflower': 4.0, 'peas': 3.5, 'beans': 3.5, 'okra': 5.0,
      'mustard': 3.5, 'rice_transplant': 6.0, 'soybean': 4.5, 'maize': 5.0,
      'barley': 3.5, 'oats': 3.0, 'sunflower': 5.5,
    };

    // 3. SOIL PARAMETERS
    // Percolation: Only relevant for flooded crops (Rice)
    final soilPercolationDaily = {
      'sandy': 25.0, 'sandy-loam': 15.0, 'loamy': 7.0, 
      'clay-loam': 3.0, 'clay': 1.5, 'silty': 5.0,
    };

    // Efficiency: Only relevant for upland crops (Wheat, Veggies)
    final soilEfficiencyMultiplier = {
      'sandy': 1.30,      // +30% water needed due to fast drainage
      'sandy-loam': 1.15,
      'loamy': 1.0,       // Standard
      'clay-loam': 0.95,
      'clay': 0.90,       // -10% water needed due to retention
      'silty': 1.05,
    };

    // 4. DETERMINE LOGIC TYPE
    String crop = cropType.toLowerCase();
    String soil = soilType.toLowerCase();
    bool isFloodedCrop = crop.contains('rice');
    double etcMmPerDay = cropEtcDaily[crop] ?? 4.0;

    double dailyMm;
    double landPrepLiters = 0.0;
    String methodMessage = '';

    if (isFloodedCrop) {
      // === FLOOD LOGIC (Rice) ===
      // Needs to replace water lost to leakage (percolation) constantly
      double percolation = soilPercolationDaily[soil] ?? 7.0;
      dailyMm = etcMmPerDay + percolation; 
      
      // Land Prep: 200mm puddling layer
      landPrepLiters = 200.0 * mmToLitersPerHa * areaHectares;
      methodMessage = "Flooded Crop Logic (ETc + Percolation)";
    } else {
      // === UPLAND LOGIC (Wheat, Veggies) ===
      // No leakage math; just efficiency adjustment
      double efficiency = soilEfficiencyMultiplier[soil] ?? 1.0;
      dailyMm = etcMmPerDay * efficiency;
      
      // Land Prep: 0 (No puddling)
      landPrepLiters = 0.0;
      methodMessage = "Upland Irrigation Logic (ETc * Soil Efficiency)";
    }

    // 5. FINAL CALCULATION
    double dailyWaterLiters = dailyMm * mmToLitersPerHa * areaHectares;
    double totalWaterLiters = (dailyWaterLiters * growingDays) + landPrepLiters;

    return {
      'success': true,
      'crop': cropType,
      'area': area,
      'areaUnit': areaUnit,
      'areaHectares': areaHectares.toStringAsFixed(2),
      'water': totalWaterLiters.ceil(),
      'dailyWater': dailyWaterLiters.ceil(),
      'soilType': soilType,
      'growingDays': growingDays,
      'message': 'Total: ${totalWaterLiters.ceil()} liters\n'
                 'Daily: ${dailyWaterLiters.ceil()} liters/day\n'
                 'Method: $methodMessage',
    };
  }

  // ============ CUSTOM WATER CALCULATION (AI SUPPORT) ============

  Map<String, dynamic> calculateWaterRequirementCustom({
    required double area,
    required String areaUnit,
    required String cropType,
    required String soilType,
    required int growingDays,
    required Map<String, dynamic> cropDetails,
  }) {
    if (area <= 0) {
      return {'success': false, 'message': 'Land area must be greater than 0', 'water': 0};
    }

    double areaHectares = _convertToHectares(area, areaUnit);
    const double mmToLitersPerHa = 10000.0;

    // Use AI provided water data, or fallback to 4.0
    double etcMmPerDay = (cropDetails['waterPerDay'] ?? 4.0).toDouble();
    
    bool isFloodedCrop = cropType.toLowerCase().contains('rice');
    String soil = soilType.toLowerCase();

    // Re-use standard maps
    final soilPercolationDaily = {
      'sandy': 25.0, 'sandy-loam': 15.0, 'loamy': 7.0, 
      'clay-loam': 3.0, 'clay': 1.5, 'silty': 5.0,
    };
    final soilEfficiencyMultiplier = {
      'sandy': 1.30, 'sandy-loam': 1.15, 'loamy': 1.0, 
      'clay-loam': 0.95, 'clay': 0.90, 'silty': 1.05,
    };

    double dailyMm;
    double landPrepLiters = 0.0;
    String methodMessage = '';

    if (isFloodedCrop) {
      double percolation = soilPercolationDaily[soil] ?? 7.0;
      dailyMm = etcMmPerDay + percolation; 
      landPrepLiters = 200.0 * mmToLitersPerHa * areaHectares;
      methodMessage = "Flooded Crop Logic (AI Data + Percolation)";
    } else {
      double efficiency = soilEfficiencyMultiplier[soil] ?? 1.0;
      dailyMm = etcMmPerDay * efficiency;
      landPrepLiters = 0.0;
      methodMessage = "Upland Irrigation Logic (AI Data * Efficiency)";
    }

    double dailyWaterLiters = dailyMm * mmToLitersPerHa * areaHectares;
    double totalWaterLiters = (dailyWaterLiters * growingDays) + landPrepLiters;

    return {
      'success': true,
      'crop': cropType,
      'area': area,
      'areaUnit': areaUnit,
      'areaHectares': areaHectares.toStringAsFixed(2),
      'water': totalWaterLiters.ceil(),
      'dailyWater': dailyWaterLiters.ceil(),
      'soilType': soilType,
      'growingDays': growingDays,
      'message': 'Total: ${totalWaterLiters.ceil()} liters\n'
                 'Daily: ${dailyWaterLiters.ceil()} liters/day\n'
                 'Method: $methodMessage',
    };
  }

  // ============ ZONES MANAGEMENT ============

  Stream<List<Map<String, dynamic>>> getZonesFromCrops() {
    if (userId.isEmpty) return Stream.value([]);

    return _firestore
        .collection('users').doc(userId).collection('fields').snapshots()
        .asyncMap((fieldsSnapshot) async {
      List<Map<String, dynamic>> allZones = [];

      // 1. Fetch Crop Zones
      for (var fieldDoc in fieldsSnapshot.docs) {
        final fieldId = fieldDoc.id;
        final fieldName = fieldDoc.data()['name'] as String? ?? '';
        final cropsSnapshot = await fieldDoc.reference.collection('crops').get();

        for (var cropDoc in cropsSnapshot.docs) {
          final cropData = cropDoc.data();
          allZones.add({
            'id': '${fieldId}_${cropDoc.id}',
            'fieldId': fieldId,
            'cropId': cropDoc.id,
            'name': '${cropData['name'] ?? 'Crop'} - $fieldName',
            'location': fieldName,
            'status': cropData['irrigationStatus'] ?? 'scheduled',
            'moisture': cropData['soilMoisture'] ?? 0,
            'schedule': cropData['irrigationSchedule'] ?? '06:00 AM Daily',
            'waterAmount': cropData['waterAmount'] ?? 200,
            'duration': cropData['irrigationDuration'] ?? 60,
            'isRunning': cropData['irrigationStatus'] == 'active',
            'type': 'crop',
          });
        }
      }

      // 2. Fetch Manual Zones
      try {
        final manualSnapshot = await _firestore
            .collection('users').doc(userId).collection('water_zones').get();
        for (var zoneDoc in manualSnapshot.docs) {
          final data = zoneDoc.data();
          allZones.add({
            'id': zoneDoc.id,
            'name': data['name'] ?? 'Unnamed Zone',
            'location': data['location'] ?? 'Unknown',
            'status': data['status'] ?? 'scheduled',
            'moisture': data['moisture'] ?? 0,
            'schedule': data['schedule'] ?? '06:00 AM Daily',
            'waterAmount': data['waterAmount'] ?? 300,
            'duration': data['duration'] ?? 60,
            'isRunning': data['status'] == 'active',
            'type': 'manual',
          });
        }
      } catch (e) {
        // Ignore manual zone errors
      }
      return allZones;
    });
  }

  // ============ SOIL MOISTURE CALCULATION ============

  /// Calculate real soil moisture based on today's water usage vs target
  Future<int> calculateRealSoilMoisture(String zoneId) async {
    try {
      if (userId.isEmpty) return 0;

      // 1. Get total water used today for this zone
      final dateStr = _formatDate(DateTime.now());
      final usageSnapshot = await _firestore
          .collection('users').doc(userId).collection('water_usage')
          .where('zoneId', isEqualTo: zoneId)
          .where('date', isEqualTo: dateStr).get();

      double totalWaterApplied = 0;
      for (var doc in usageSnapshot.docs) {
        totalWaterApplied += (doc.data()['liters'] as num?)?.toDouble() ?? 0.0;
      }

      // 2. We assume a standard daily requirement target (e.g., 500L) 
      // Ideally, pass the calculated 'dailyWaterNeeded' here. 
      // For now, using a safe default or based on accumulated logic.
      const double approximateDailyTarget = 500.0; 

      if (totalWaterApplied == 0) return 0;

      // Simple Logic: 500L = 100% moisture for the day
      int calculatedMoisture = ((totalWaterApplied / approximateDailyTarget) * 100).toInt();
      
      // Cap at 95% (Field capacity)
      return calculatedMoisture > 95 ? 95 : calculatedMoisture;
    } catch (e) {
      return 0;
    }
  }

  // ============ CRUD OPERATIONS ============

  Future<void> addZone({
    required String name, required String location, required String schedule,
    required int waterAmount, required int duration,
  }) async {
    if (userId.isEmpty) return;
    await _firestore.collection('users').doc(userId).collection('water_zones').add({
      'name': name, 'location': location, 'status': 'scheduled', 'moisture': 0,
      'schedule': schedule, 'waterAmount': waterAmount, 'duration': duration,
      'isRunning': false, 'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteZone(String zoneId) async {
    if (userId.isEmpty) return;
    // Check if crop-based ID
    if (zoneId.contains('_') && zoneId.split('_').length == 2) {
      final parts = zoneId.split('_');
      await _firestore.collection('users').doc(userId).collection('fields')
          .doc(parts[0]).collection('crops').doc(parts[1]).delete();
    } else {
      await _firestore.collection('users').doc(userId).collection('water_zones')
          .doc(zoneId).delete();
    }
  }

  Future<void> updateZoneDetails({
    required String zoneId, required int waterAmount,
    required int duration, required String schedule,
  }) async {
    if (userId.isEmpty) return;
    if (zoneId.contains('_') && zoneId.split('_').length == 2) {
      final parts = zoneId.split('_');
      await _firestore.collection('users').doc(userId).collection('fields')
          .doc(parts[0]).collection('crops').doc(parts[1]).update({
        'waterAmount': waterAmount, 'irrigationDuration': duration,
        'irrigationSchedule': schedule, 'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await _firestore.collection('users').doc(userId).collection('water_zones')
          .doc(zoneId).update({
        'waterAmount': waterAmount, 'duration': duration,
        'schedule': schedule, 'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // ============ WEATHER & RECOMMENDATIONS ============

  Future<Map<String, dynamic>> checkWeatherForWatering() async {
    try {
      final weather = await _weatherService.getCurrentWeather();
      final weatherList = weather['weather'] as List? ?? [];
      final condition = weatherList.isNotEmpty ? weatherList[0]['main'] ?? '' : '';
      bool shouldSkip = condition.toLowerCase().contains('rain');

      return {
        'shouldSkipWatering': shouldSkip,
        'condition': condition,
        'message': shouldSkip ? '🌧️ Rain detected - Skip watering' : '☀️ Clear - Safe to water',
        'temperature': weather['main']?['temp'],
        'humidity': weather['main']?['humidity'],
      };
    } catch (e) {
      return {'shouldSkipWatering': false, 'message': '⚪ Weather data unavailable'};
    }
  }

  Future<Map<String, dynamic>> getWateringRecommendation({
    required double area, required String areaUnit, required String cropType,
    required String soilType, required int growingDays,
  }) async {
    final weatherCheck = await checkWeatherForWatering();
    if (weatherCheck['shouldSkipWatering'] == true) {
      return {'recommendation': weatherCheck['message'], 'action': 'skip'};
    }

    final calculation = calculateWaterRequirement(
      area: area, areaUnit: areaUnit, cropType: cropType,
      soilType: soilType, growingDays: growingDays,
    );

    return {
      'recommendation': '💧 Apply ${calculation['dailyWater']} L today',
      'action': 'water',
      'details': calculation,
    };
  }

  // ============ HISTORY ============

  Future<void> saveCalculation({
    required double area, required String areaUnit, required String cropType,
    required String soilType, required int waterRequired, required int dailyWater,
    required int growingDays, required String weatherCondition,
  }) async {
    if (userId.isEmpty) return;
    await _firestore.collection('users').doc(userId).collection('irrigation_calculations').add({
      'area': area, 'areaUnit': areaUnit, 'crop': cropType, 'soilType': soilType,
      'water': waterRequired, 'dailyWater': dailyWater, 'growingDays': growingDays,
      'weather': weatherCondition, 'timestamp': FieldValue.serverTimestamp(),
      'date': DateTime.now().toString().split(' ')[0],
    });
  }

  Stream<List<Map<String, dynamic>>> getCalculationHistory() {
    if (userId.isEmpty) return Stream.value([]);
    return _firestore.collection('users').doc(userId)
        .collection('irrigation_calculations').orderBy('timestamp', descending: true)
        .limit(10).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    });
  }

  // ============ NOTIFICATIONS (Pass-through) ============

  Future<void> sendWaterOptimizationNotification({required String cropName, required double recommendedWater}) async {
    await _notificationService.notifyWaterOptimization(
      cropName: cropName, recommendedWater: recommendedWater, waterUnit: 'Liters'
    );
  }

  Future<void> sendLowMoistureAlert({required double soilMoisture, required String cropName}) async {
    await _notificationService.notifyLowSoilMoisture(
      soilMoisture: soilMoisture, cropName: cropName, hoursToIrrigate: 2
    );
  }
}