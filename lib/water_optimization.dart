import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'ai_service.dart';
import 'notification_service.dart';
import 'localization_service.dart';
import 'weather_service.dart';

// Inlined WaterOptimizationService to keep water-related code in a single file
class WaterOptimizationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final WeatherService _weatherService = WeatherService();
  final NotificationService _notificationService = NotificationService();

  String get userId => _auth.currentUser?.uid ?? '';

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  double _convertToHectares(double area, String unit) {
    try {
      if (area <= 0 || area.isNaN) return 1.0;
      switch (unit.toLowerCase()) {
        case 'acres':
          return area * 0.404686;
        case 'hectares':
          return area;
        case 'sqm':
          return area / 10000.0;
        default:
          return area;
      }
    } catch (e) {
      return 1.0;
    }
  }

  // 1. Expand the Local Crop Database to 100-200 Crops
  // Baseline water requirements (L/m²/day) for 3 lifecycle stages.
  final Map<String, Map<String, double>> _cropWaterRequirements = {
    // Cereals & Grains
    'rice': {'Seedling': 4.0, 'Mid-Season': 11.0, 'Harvesting': 7.0},
    'wheat': {'Seedling': 2.0, 'Mid-Season': 6.0, 'Harvesting': 3.0},
    'maize': {'Seedling': 2.5, 'Mid-Season': 7.0, 'Harvesting': 4.0},
    'corn': {'Seedling': 2.5, 'Mid-Season': 7.0, 'Harvesting': 4.0},
    'barley': {'Seedling': 2.0, 'Mid-Season': 5.5, 'Harvesting': 3.0},
    'millet': {'Seedling': 1.5, 'Mid-Season': 3.5, 'Harvesting': 2.0},
    'sorghum': {'Seedling': 1.5, 'Mid-Season': 5.0, 'Harvesting': 2.5},
    'oats': {'Seedling': 2.0, 'Mid-Season': 5.5, 'Harvesting': 3.0},
    'rye': {'Seedling': 2.0, 'Mid-Season': 5.5, 'Harvesting': 3.0},
    'triticale': {'Seedling': 2.0, 'Mid-Season': 5.5, 'Harvesting': 3.0},
    'fonio': {'Seedling': 1.5, 'Mid-Season': 3.5, 'Harvesting': 2.0},
    'teff': {'Seedling': 1.5, 'Mid-Season': 3.5, 'Harvesting': 2.0},
    'quinoa': {'Seedling': 2.0, 'Mid-Season': 4.5, 'Harvesting': 2.5},
    'amaranth': {'Seedling': 2.0, 'Mid-Season': 4.5, 'Harvesting': 2.5},
    'buckwheat': {'Seedling': 2.0, 'Mid-Season': 4.5, 'Harvesting': 2.5},

    // Vegetables
    'cabbage': {'Seedling': 2.5, 'Mid-Season': 5.5, 'Harvesting': 4.0},
    'cauliflower': {'Seedling': 2.5, 'Mid-Season': 5.5, 'Harvesting': 4.0},
    'spinach': {'Seedling': 2.0, 'Mid-Season': 4.5, 'Harvesting': 3.5},
    'lettuce': {'Seedling': 2.0, 'Mid-Season': 4.0, 'Harvesting': 3.0},
    'kale': {'Seedling': 2.0, 'Mid-Season': 4.5, 'Harvesting': 3.5},
    'celery': {'Seedling': 2.5, 'Mid-Season': 5.0, 'Harvesting': 4.0},
    'potato': {'Seedling': 2.5, 'Mid-Season': 6.5, 'Harvesting': 4.5},
    'onion': {'Seedling': 2.0, 'Mid-Season': 5.0, 'Harvesting': 3.5},
    'carrot': {'Seedling': 2.0, 'Mid-Season': 4.5, 'Harvesting': 3.0},
    'beetroot': {'Seedling': 2.0, 'Mid-Season': 4.5, 'Harvesting': 3.0},
    'radish': {'Seedling': 1.5, 'Mid-Season': 3.5, 'Harvesting': 2.5},
    'turnip': {'Seedling': 1.5, 'Mid-Season': 3.5, 'Harvesting': 2.5},
    'tomato': {'Seedling': 2.5, 'Mid-Season': 6.0, 'Harvesting': 4.0},
    'chili': {'Seedling': 2.0, 'Mid-Season': 5.5, 'Harvesting': 3.5},
    'brinjal': {'Seedling': 2.5, 'Mid-Season': 6.0, 'Harvesting': 4.0},
    'eggplant': {'Seedling': 2.5, 'Mid-Season': 6.0, 'Harvesting': 4.0},
    'cucumber': {'Seedling': 2.5, 'Mid-Season': 5.5, 'Harvesting': 4.0},
    'pumpkin': {'Seedling': 2.5, 'Mid-Season': 5.5, 'Harvesting': 3.5},
    'okra': {'Seedling': 2.5, 'Mid-Season': 6.0, 'Harvesting': 4.0},
    'bell pepper': {'Seedling': 2.0, 'Mid-Season': 5.5, 'Harvesting': 3.5},
    'pepper': {'Seedling': 2.0, 'Mid-Season': 5.5, 'Harvesting': 3.5},
    'sweet potato': {'Seedling': 2.5, 'Mid-Season': 5.5, 'Harvesting': 4.0},
    'zucchini': {'Seedling': 2.5, 'Mid-Season': 5.5, 'Harvesting': 4.0},
    'garlic': {'Seedling': 1.5, 'Mid-Season': 4.0, 'Harvesting': 2.5},
    'yam': {'Seedling': 2.5, 'Mid-Season': 5.5, 'Harvesting': 4.0},
    'cassava': {'Seedling': 2.0, 'Mid-Season': 5.0, 'Harvesting': 3.5},
    'taro': {'Seedling': 3.0, 'Mid-Season': 6.5, 'Harvesting': 4.5},
    'artichoke': {'Seedling': 2.0, 'Mid-Season': 5.0, 'Harvesting': 3.5},
    'asparagus': {'Seedling': 2.0, 'Mid-Season': 4.5, 'Harvesting': 3.0},
    'broccoli': {'Seedling': 2.5, 'Mid-Season': 5.5, 'Harvesting': 4.0},
    'brussels sprouts': {'Seedling': 2.0, 'Mid-Season': 5.0, 'Harvesting': 3.5},
    'leek': {'Seedling': 2.0, 'Mid-Season': 4.5, 'Harvesting': 3.0},
    'parsnip': {'Seedling': 2.0, 'Mid-Season': 4.5, 'Harvesting': 3.0},
    'rutabaga': {'Seedling': 2.0, 'Mid-Season': 4.5, 'Harvesting': 3.0},
    'watercress': {'Seedling': 3.0, 'Mid-Season': 6.0, 'Harvesting': 4.5},

    // Fruits
    'banana': {'Seedling': 4.0, 'Mid-Season': 8.0, 'Harvesting': 6.0},
    'mango': {'Seedling': 3.0, 'Mid-Season': 7.0, 'Harvesting': 5.0},
    'citrus': {'Seedling': 3.0, 'Mid-Season': 6.0, 'Harvesting': 4.5},
    'papaya': {'Seedling': 3.5, 'Mid-Season': 7.0, 'Harvesting': 5.0},
    'apple': {'Seedling': 2.5, 'Mid-Season': 6.0, 'Harvesting': 4.0},
    'pear': {'Seedling': 2.5, 'Mid-Season': 6.0, 'Harvesting': 4.0},
    'peach': {'Seedling': 2.5, 'Mid-Season': 5.5, 'Harvesting': 4.0},
    'plum': {'Seedling': 2.5, 'Mid-Season': 5.5, 'Harvesting': 4.0},
    'grapes': {'Seedling': 2.0, 'Mid-Season': 5.0, 'Harvesting': 3.5},
    'strawberry': {'Seedling': 2.0, 'Mid-Season': 4.5, 'Harvesting': 3.0},
    'watermelon': {'Seedling': 2.5, 'Mid-Season': 6.0, 'Harvesting': 4.0},
    'melon': {'Seedling': 2.5, 'Mid-Season': 5.5, 'Harvesting': 4.0},
    'pomegranate': {'Seedling': 2.0, 'Mid-Season': 5.0, 'Harvesting': 3.5},
    'guava': {'Seedling': 2.5, 'Mid-Season': 5.5, 'Harvesting': 4.0},
    'lychee': {'Seedling': 3.0, 'Mid-Season': 6.5, 'Harvesting': 5.0},
    'kiwi': {'Seedling': 3.0, 'Mid-Season': 6.0, 'Harvesting': 4.5},
    'fig': {'Seedling': 2.0, 'Mid-Season': 5.0, 'Harvesting': 3.5},
    'dates': {'Seedling': 4.0, 'Mid-Season': 8.0, 'Harvesting': 6.0},
    'avocado': {'Seedling': 3.0, 'Mid-Season': 6.0, 'Harvesting': 4.5},
    'pineapple': {'Seedling': 2.0, 'Mid-Season': 4.0, 'Harvesting': 3.0},
    'blueberries': {'Seedling': 2.0, 'Mid-Season': 4.5, 'Harvesting': 3.0},
    'cranberries': {'Seedling': 2.5, 'Mid-Season': 5.5, 'Harvesting': 4.0},
    'raspberries': {'Seedling': 2.0, 'Mid-Season': 4.5, 'Harvesting': 3.0},
    'blackberries': {'Seedling': 2.0, 'Mid-Season': 4.5, 'Harvesting': 3.0},
    'gooseberries': {'Seedling': 2.0, 'Mid-Season': 4.5, 'Harvesting': 3.0},
    'passion fruit': {'Seedling': 2.5, 'Mid-Season': 5.5, 'Harvesting': 4.0},
    'dragon fruit': {'Seedling': 1.5, 'Mid-Season': 3.5, 'Harvesting': 2.0},
    'star fruit': {'Seedling': 2.5, 'Mid-Season': 5.5, 'Harvesting': 4.0},
    'durian': {'Seedling': 3.0, 'Mid-Season': 6.5, 'Harvesting': 5.0},
    'jackfruit': {'Seedling': 3.0, 'Mid-Season': 6.0, 'Harvesting': 5.0},
    'rambutan': {'Seedling': 3.0, 'Mid-Season': 6.0, 'Harvesting': 5.0},
    'mangosteen': {'Seedling': 3.0, 'Mid-Season': 6.0, 'Harvesting': 5.0},

    // Cash & Industrial Crops
    'sugarcane': {'Seedling': 3.5, 'Mid-Season': 9.0, 'Harvesting': 6.0},
    'cotton': {'Seedling': 2.5, 'Mid-Season': 7.0, 'Harvesting': 4.0},
    'tea': {'Seedling': 3.0, 'Mid-Season': 5.5, 'Harvesting': 4.5},
    'coffee': {'Seedling': 2.5, 'Mid-Season': 5.5, 'Harvesting': 4.0},
    'cocoa': {'Seedling': 3.0, 'Mid-Season': 6.0, 'Harvesting': 4.5},
    'tobacco': {'Seedling': 2.5, 'Mid-Season': 6.0, 'Harvesting': 4.0},
    'rubber': {'Seedling': 3.0, 'Mid-Season': 6.5, 'Harvesting': 5.0},
    'oil palm': {'Seedling': 3.5, 'Mid-Season': 7.5, 'Harvesting': 6.0},
    'jute': {'Seedling': 3.0, 'Mid-Season': 7.0, 'Harvesting': 5.0},
    'hemp': {'Seedling': 2.5, 'Mid-Season': 6.0, 'Harvesting': 4.0},
    'flax': {'Seedling': 2.0, 'Mid-Season': 5.0, 'Harvesting': 3.5},
    'safflower': {'Seedling': 2.0, 'Mid-Season': 4.5, 'Harvesting': 3.0},
    'sunflower': {'Seedling': 2.5, 'Mid-Season': 6.0, 'Harvesting': 4.0},
    'mustard': {'Seedling': 2.0, 'Mid-Season': 4.5, 'Harvesting': 3.0},
    'sesame': {'Seedling': 2.0, 'Mid-Season': 4.5, 'Harvesting': 3.0},
    'castor': {'Seedling': 2.0, 'Mid-Season': 5.0, 'Harvesting': 3.5},
    'bamboo': {'Seedling': 3.0, 'Mid-Season': 7.0, 'Harvesting': 5.0},
    'sago': {'Seedling': 3.5, 'Mid-Season': 7.5, 'Harvesting': 6.0},

    // Pulses & Legumes
    'chickpea': {'Seedling': 1.5, 'Mid-Season': 4.5, 'Harvesting': 2.5},
    'lentil': {'Seedling': 1.5, 'Mid-Season': 4.0, 'Harvesting': 2.5},
    'pigeon pea': {'Seedling': 2.0, 'Mid-Season': 5.0, 'Harvesting': 3.0},
    'mung bean': {'Seedling': 2.0, 'Mid-Season': 4.5, 'Harvesting': 3.0},
    'black gram': {'Seedling': 2.0, 'Mid-Season': 4.5, 'Harvesting': 3.0},
    'soybean': {'Seedling': 2.0, 'Mid-Season': 5.5, 'Harvesting': 3.5},
    'cowpea': {'Seedling': 2.0, 'Mid-Season': 4.5, 'Harvesting': 3.0},
    'faba bean': {'Seedling': 2.0, 'Mid-Season': 5.0, 'Harvesting': 3.0},
    'green gram': {'Seedling': 2.0, 'Mid-Season': 4.5, 'Harvesting': 3.0},
    'peas': {'Seedling': 2.0, 'Mid-Season': 4.5, 'Harvesting': 3.0},
    'beans': {'Seedling': 2.0, 'Mid-Season': 4.5, 'Harvesting': 3.0},

    // Spices & Herbs
    'cumin': {'Seedling': 1.5, 'Mid-Season': 3.5, 'Harvesting': 2.0},
    'coriander': {'Seedling': 1.5, 'Mid-Season': 4.0, 'Harvesting': 2.5},
    'turmeric': {'Seedling': 2.5, 'Mid-Season': 5.5, 'Harvesting': 4.0},
    'ginger': {'Seedling': 2.5, 'Mid-Season': 5.5, 'Harvesting': 4.0},
    'cardamom': {'Seedling': 3.0, 'Mid-Season': 6.0, 'Harvesting': 4.5},
    'black pepper': {'Seedling': 2.5, 'Mid-Season': 5.5, 'Harvesting': 4.0},
    'clove': {'Seedling': 3.0, 'Mid-Season': 6.0, 'Harvesting': 4.5},
    'nutmeg': {'Seedling': 3.0, 'Mid-Season': 6.0, 'Harvesting': 4.5},
    'saffron': {'Seedling': 1.5, 'Mid-Season': 3.5, 'Harvesting': 2.0},
    'vanilla': {'Seedling': 2.5, 'Mid-Season': 5.5, 'Harvesting': 4.0},
    'mint': {'Seedling': 2.0, 'Mid-Season': 5.0, 'Harvesting': 4.0},
    'basil': {'Seedling': 2.0, 'Mid-Season': 4.5, 'Harvesting': 3.5},
    'rosemary': {'Seedling': 1.5, 'Mid-Season': 3.5, 'Harvesting': 2.5},
    'thyme': {'Seedling': 1.5, 'Mid-Season': 3.5, 'Harvesting': 2.5},
    'oregano': {'Seedling': 1.5, 'Mid-Season': 3.5, 'Harvesting': 2.5},
    'lavender': {'Seedling': 1.5, 'Mid-Season': 3.5, 'Harvesting': 2.5},
    'hops': {'Seedling': 2.5, 'Mid-Season': 6.0, 'Harvesting': 4.0},

    // Forage & Fodder
    'alfalfa': {'Seedling': 2.5, 'Mid-Season': 7.0, 'Harvesting': 5.0},
    'clover': {'Seedling': 2.0, 'Mid-Season': 6.0, 'Harvesting': 4.5},
    'ryegrass': {'Seedling': 2.0, 'Mid-Season': 5.5, 'Harvesting': 4.0},
    'napier grass': {'Seedling': 3.0, 'Mid-Season': 7.5, 'Harvesting': 5.5},
    'sudan grass': {'Seedling': 2.5, 'Mid-Season': 6.5, 'Harvesting': 4.5},
    'bermuda grass': {'Seedling': 2.0, 'Mid-Season': 5.5, 'Harvesting': 4.0},
    'fescue': {'Seedling': 2.0, 'Mid-Season': 5.5, 'Harvesting': 4.0},
    'timothy grass': {'Seedling': 2.0, 'Mid-Season': 5.5, 'Harvesting': 4.0},
    'vetiver': {'Seedling': 2.5, 'Mid-Season': 6.0, 'Harvesting': 4.5},

    // Nuts & Oilseeds
    'groundnut': {'Seedling': 2.0, 'Mid-Season': 5.5, 'Harvesting': 3.5},
    'peanut': {'Seedling': 2.0, 'Mid-Season': 5.5, 'Harvesting': 3.5},
    'almond': {'Seedling': 2.5, 'Mid-Season': 6.5, 'Harvesting': 4.5},
    'walnut': {'Seedling': 2.5, 'Mid-Season': 6.0, 'Harvesting': 4.5},
    'cashew': {'Seedling': 3.0, 'Mid-Season': 6.5, 'Harvesting': 4.5},
    'pistachio': {'Seedling': 2.0, 'Mid-Season': 5.5, 'Harvesting': 4.0},
    'hazelnut': {'Seedling': 2.5, 'Mid-Season': 6.0, 'Harvesting': 4.5},
    'coconut': {'Seedling': 3.5, 'Mid-Season': 7.0, 'Harvesting': 5.5},
    'macadamia': {'Seedling': 2.5, 'Mid-Season': 6.0, 'Harvesting': 4.5},
    'pecan': {'Seedling': 3.0, 'Mid-Season': 6.5, 'Harvesting': 4.5},
    'chestnut': {'Seedling': 2.5, 'Mid-Season': 6.0, 'Harvesting': 4.5},
    
    // Miscellaneous
    'agave': {'Seedling': 1.0, 'Mid-Season': 2.5, 'Harvesting': 1.5},
    'aloe vera': {'Seedling': 1.0, 'Mid-Season': 2.0, 'Harvesting': 1.5},
    'ginseng': {'Seedling': 2.0, 'Mid-Season': 4.0, 'Harvesting': 3.0},
  };

  // Expose the list of available crops for the UI Autocomplete
  List<String> get availableCrops => _cropWaterRequirements.keys.toList();

  Map<String, dynamic> calculateWaterRequirement({
    required double area,
    required String areaUnit,
    required String cropType,
    required String soilType,
    required int growingDays,
    double forecastRainMm = 0.0,
    String irrigationMethod = 'Sprinkler Irrigation',
  }) {
    try {
      // 4. Robust Error Handling & Edge Cases
      double safeArea = (area <= 0 || area.isNaN) ? 1.0 : area;
      int safeDays = (growingDays <= 0) ? 120 : growingDays;
      double safeRain = (forecastRainMm < 0 || forecastRainMm.isNaN) ? 0.0 : forecastRainMm;

      double areaHectares = _convertToHectares(safeArea, areaUnit);
      double areaSqm = areaHectares * 10000.0;

      String crop = cropType.toLowerCase().trim();
      
      // Fallback default for unknown crops
      Map<String, double> cropStages = _cropWaterRequirements[crop] ?? 
          {'Seedling': 2.0, 'Mid-Season': 5.0, 'Harvesting': 3.0};

      // 1. Calculate Average Daily Baseline Requirement (L/m²/day) over the season
      // Assuming typical distribution: 20% Seedling, 60% Mid-Season, 20% Harvesting
      double avgDailyBaseline = (cropStages['Seedling']! * 0.2) + 
                                (cropStages['Mid-Season']! * 0.6) + 
                                (cropStages['Harvesting']! * 0.2);

      // 3. Fix the Rainfall Logic (Effective Rainfall Subtraction)
      // P_eff = Measured Rainfall (mm) × 0.7
      double pEff = safeRain * 0.7;

      // Net Irrigation Requirement (I_net)
      // I_net = Baseline - P_eff
      double iNet = avgDailyBaseline - pEff;
      if (iNet < 0.0) {
        iNet = 0.0; // gracefully floor at 0.0
      }

      // 2. Fix the Irrigation System Efficiency Formula
      double efficiencyRating;
      if (irrigationMethod.contains('Drip')) {
        efficiencyRating = 0.90;
      } else if (irrigationMethod.contains('Sprinkler')) {
        efficiencyRating = 0.75;
      } else if (irrigationMethod.contains('Surface') || irrigationMethod.contains('Flood')) {
        efficiencyRating = 0.50;
      } else {
        efficiencyRating = 0.75; // safe operational constant
      }

      // I_gross = I_net / Efficiency Rating
      double iGross = iNet / efficiencyRating;

      // Calculate Total Liters
      // I_gross is in L/m²/day.
      double dailyWaterLiters = iGross * areaSqm;
      double totalWaterLiters = dailyWaterLiters * safeDays;

      String methodMessage = "I_gross = I_net / Efficiency ($efficiencyRating)\n"
          "Crop Baseline: ${avgDailyBaseline.toStringAsFixed(1)} L/m²/day";
      
      if (pEff > 0) {
        methodMessage += "\nEffective rainfall (${pEff.toStringAsFixed(1)}mm) subtracted.";
      }

      return {
        'success': true,
        'crop': cropType,
        'area': safeArea,
        'areaUnit': areaUnit,
        'areaHectares': areaHectares.toStringAsFixed(2),
        'water': totalWaterLiters.ceil(),
        'dailyWater': dailyWaterLiters.ceil(),
        'soilType': soilType,
        'growingDays': safeDays,
        'message': 'Total: ${totalWaterLiters.ceil()} liters\n'
                   'Daily: ${dailyWaterLiters.ceil()} liters/day\n'
                   'Method: $methodMessage',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Calculation Error: $e',
        'water': 0,
        'dailyWater': 0,
        'growingDays': growingDays,
      };
    }
  }

  Map<String, dynamic> calculateWaterRequirementCustom({
    required double area,
    required String areaUnit,
    required String cropType,
    required String soilType,
    required int growingDays,
    required Map<String, dynamic> cropDetails,
    double forecastRainMm = 0.0,
  }) {
    // Directly route through the refactored mathematical engine
    return calculateWaterRequirement(
      area: area,
      areaUnit: areaUnit,
      cropType: cropType,
      soilType: soilType,
      growingDays: growingDays,
      forecastRainMm: forecastRainMm,
    );
  }

  Stream<List<Map<String, dynamic>>> getZonesFromCrops() {
    if (userId.isEmpty) return Stream.value([]);

    return _firestore
        .collection('users').doc(userId).collection('fields').snapshots()
        .asyncMap((fieldsSnapshot) async {
      List<Map<String, dynamic>> allZones = [];
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
      }
      return allZones;
    });
  }

  Future<int> calculateRealSoilMoisture(String zoneId) async {
    try {
      if (userId.isEmpty) return 0;
      final dateStr = _formatDate(DateTime.now());
      final usageSnapshot = await _firestore
          .collection('users').doc(userId).collection('water_usage')
          .where('zoneId', isEqualTo: zoneId)
          .where('date', isEqualTo: dateStr).get();

      double totalWaterApplied = 0;
      for (var doc in usageSnapshot.docs) {
        totalWaterApplied += (doc.data()['liters'] as num?)?.toDouble() ?? 0.0;
      }

      const double approximateDailyTarget = 500.0;
      if (totalWaterApplied == 0) return 0;
      int calculatedMoisture = ((totalWaterApplied / approximateDailyTarget) * 100).toInt();
      return calculatedMoisture > 95 ? 95 : calculatedMoisture;
    } catch (e) {
      return 0;
    }
  }

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

  Future<Map<String, dynamic>> checkWeatherForWatering() async {
    try {
      final weather = await _weatherService.getCurrentWeather();
      final weatherList = weather['weather'] as List? ?? [];
      final condition = weatherList.isNotEmpty ? weatherList[0]['main'] ?? '' : '';
      
      double rainMm = 0.0;
      if (weather['rain'] != null) {
        if (weather['rain']['1h'] != null) {
          rainMm = (weather['rain']['1h'] as num).toDouble();
        } else if (weather['rain']['3h'] != null) {
          rainMm = (weather['rain']['3h'] as num).toDouble();
        }
      } else if (condition.toLowerCase().contains('rain')) {
        rainMm = 5.0; // fallback if rain is mentioned but no volume provided
      }

      return {
        'condition': condition,
        'rainMm': rainMm,
        'temperature': weather['main']?['temp'],
        'humidity': weather['main']?['humidity'],
      };
    } catch (e) {
      return {'condition': 'Unknown', 'rainMm': 0.0, 'message': ' Weather data unavailable'};
    }
  }

  Future<Map<String, dynamic>> getWateringRecommendation({
    required double area, required String areaUnit, required String cropType,
    required String soilType, required int growingDays,
  }) async {
    final weatherCheck = await checkWeatherForWatering();
    double rainMm = weatherCheck['rainMm'] ?? 0.0;

    final calculation = calculateWaterRequirement(
      area: area, areaUnit: areaUnit, cropType: cropType,
      soilType: soilType, growingDays: growingDays, forecastRainMm: rainMm,
    );

    return {
      'recommendation': calculation['message'],
      'action': 'water',
      'details': calculation,
    };
  }

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

  Future<void> deleteCalculation(String id) async {
    if (userId.isEmpty) return;
    try {
      await _firestore.collection('users').doc(userId)
          .collection('irrigation_calculations').doc(id).delete();
    } catch (e) {
      rethrow;
    }
  }

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

class WaterOptimizationScreen extends StatefulWidget {
  const WaterOptimizationScreen({super.key});

  @override
  State<WaterOptimizationScreen> createState() => _WaterOptimizationScreenState();
}

class _WaterOptimizationScreenState extends State<WaterOptimizationScreen> {
  final WaterOptimizationService _service = WaterOptimizationService();
  final AiService _aiService = AiService();
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _cropController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String _selectedUnit = 'acres';
  String _selectedSoil = 'loamy';
  // NEW: Irrigation dropdown state
  String _selectedIrrigationMethod = 'Sprinkler (75% efficient)';
  bool _isLoading = false;
  Map<String, dynamic>? _result;
  Map<String, dynamic>? _weatherData;
  String _currentLanguage = 'en';

  final List<String> soilTypes = [
    'sandy',
    'sandy-loam',
    'loamy',
    'clay-loam',
    'clay',
    'silty',
  ];

  final List<String> areaUnits = ['acres', 'hectares', 'sqm'];

  // NEW: Irrigation dropdown options
  final List<String> irrigationMethods = [
    'Drip (90% efficient)',
    'Sprinkler (75% efficient)',
    'Flood (50% efficient)',
  ];

  final Map<String, Map<String, String>> _translations = {
    'en': {
      'water_optimization': 'Water Optimization',
      'land_area': 'Land Area',
      'crop_type': 'Crop Type',
      'soil_type': 'Soil Type',
      'calculate': 'Calculate Water Need',
      'weather': 'Weather Status',
      'history': 'Calculation History',
      'no_data': 'No calculations yet',
      'enter_area': 'Please enter land area',
      'enter_crop': 'Please enter crop name',
      'water_needed': 'Water Needed',
      'daily_water': 'Daily Water',
      'total_water': 'Total Water Required',
      'growing_days': 'Growing Days',
      'recommendation': 'Recommendation',
      'invalid_crop': 'Invalid crop name. Please enter a real agricultural crop.',
    },
    'hi': {
      'water_optimization': 'जल अनुकूलन',
      'land_area': 'भूमि क्षेत्र',
      'crop_type': 'फसल का प्रकार',
      'soil_type': 'मिट्टी का प्रकार',
      'calculate': 'जल आवश्यकता की गणना करें',
      'weather': 'मौसम की स्थिति',
      'history': 'गणना इतिहास',
      'no_data': 'अभी कोई गणना नहीं',
      'enter_area': 'कृपया भूमि क्षेत्र दर्ज करें',
      'enter_crop': 'कृपया फसल का नाम दर्ज करें',
      'water_needed': 'आवश्यक जल',
      'daily_water': 'दैनिक जल',
      'total_water': 'कुल जल आवश्यक',
      'growing_days': 'बढ़ने के दिन',
      'recommendation': 'सिफारिश',
      'invalid_crop': 'अमान्य फसल। कृपया एक वास्तविक कृषि फसल दर्ज करें।',
    },
  };

  String tr(String key) => _translations[_currentLanguage]?[key] ?? key;

  @override
  void initState() {
    super.initState();
    _currentLanguage = LocalizationService.currentLanguage;
  }

  @override
  void dispose() {
    _areaController.dispose();
    _cropController.dispose();
    super.dispose();
  }

  Future<void> _calculateWater() async {
    if (!_formKey.currentState!.validate()) {
      return; // Form validation will handle showing error messages in red under fields
    }

    if (_cropController.text.isEmpty) {
      _showSnackBar(tr('enter_crop'));
      return;
    }

    setState(() {
      _isLoading = true;
      _result = null; // clear previous results to avoid showing stale data
    });

    try {
      // Robust Area Parsing
      double area = 1.0;
      bool areaInvalid = false;
      try {
        area = double.parse(_areaController.text);
        if (area <= 0 || area.isNaN) {
          area = 1.0; // Safe default operational constant
          areaInvalid = true;
        }
      } catch (_) {
        area = 1.0;
        areaInvalid = true;
      }

      // NEW: User-friendly Error Message for Invalid Inputs
      if (areaInvalid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(" Invalid area entered. Using 1.0 as a placeholder. Please enter a positive number."),
            duration: Duration(seconds: 4),
          ),
        );
      }

      final cropName = _cropController.text.trim();

      // Use AI to validate crop and get details with safe wrapper
      Map<String, dynamic>? cropDetailsFromAi;
      try {
        cropDetailsFromAi = await _getAiCropDetails(cropName);
        print('Crop details from AI: $cropDetailsFromAi');
      } catch (e) {
        print('AI Validation Exception Caught: $e');
        cropDetailsFromAi = null;
      }

      // If AI explicitly validated the crop as invalid, stop and show a message
      if (cropDetailsFromAi != null && cropDetailsFromAi['valid'] == false) {
        _showSnackBar(tr('invalid_crop'));
        setState(() => _isLoading = false);
        return;
      }

      if (cropDetailsFromAi == null) {
        // AI validation failed or AI service unavailable — fallback to local calculation
        print('AI validation failed for "$cropName". Falling back to local calculation.');

        final weatherResult = await _service.checkWeatherForWatering();
        double forecastRainMm = 0.0;
        try {
          forecastRainMm = (weatherResult['rainMm'] as num?)?.toDouble() ?? 0.0;
          if (forecastRainMm < 0 || forecastRainMm.isNaN) forecastRainMm = 0.0;
        } catch (_) {
          forecastRainMm = 0.0;
        }

        // Use the service's built-in accurate calculation
        final waterResultFallback = _service.calculateWaterRequirement(
          area: area,
          areaUnit: _selectedUnit,
          cropType: cropName,
          soilType: _selectedSoil,
          growingDays: 120, // Default operational constant
          forecastRainMm: forecastRainMm,
          irrigationMethod: _selectedIrrigationMethod, // NEW: Irrigation dropdown parameter
        );

        weatherResult['message'] = forecastRainMm > 0 
            ? ' Rain forecast: ${forecastRainMm}mm. Adjusted watering.'
            : ' Clear - Safe to water';

        // Save fallback calculation
        if (waterResultFallback['success'] == true) {
          try {
            await _service.saveCalculation(
              area: area,
              areaUnit: _selectedUnit,
              cropType: cropName,
              soilType: _selectedSoil,
              waterRequired: waterResultFallback['water'] ?? 0,
              dailyWater: waterResultFallback['dailyWater'] ?? 0,
              growingDays: waterResultFallback['growingDays'] ?? 120,
              weatherCondition: weatherResult['condition'] ?? 'Unknown',
            );
          } catch (e) {
            print('Failed to save calculation: $e');
          }
        }

        setState(() {
          _result = {
            'success': true,
            'totalWater': waterResultFallback['water'],
            'dailyWater': waterResultFallback['dailyWater'],
            'growingDays': waterResultFallback['growingDays'],
            'recommendation': waterResultFallback['message'],
          };
          _weatherData = weatherResult;
          _isLoading = false;
        });

        _showResultDialog();
        return;
      }

      // Get weather check
      final weatherResult = await _service.checkWeatherForWatering();
      double forecastRainMm = 0.0;
      try {
        forecastRainMm = (weatherResult['rainMm'] as num?)?.toDouble() ?? 0.0;
        if (forecastRainMm < 0 || forecastRainMm.isNaN) forecastRainMm = 0.0;
      } catch (_) {
        forecastRainMm = 0.0;
      }
      
      weatherResult['message'] = forecastRainMm > 0 
          ? ' Rain forecast: ${forecastRainMm}mm. Adjusted watering.'
          : ' Clear - Safe to water';

      // Use AI for water calculation
      final waterResult = await _getAiWaterCalculation(
        cropName: cropName,
        area: area,
        areaUnit: _selectedUnit,
        soilType: _selectedSoil,
        cropDetails: cropDetailsFromAi,
        forecastRainMm: forecastRainMm,
        irrigationMethod: _selectedIrrigationMethod, // NEW: Irrigation dropdown parameter
      );

      print('AI water calculation result: $waterResult');

      // Save to history
      if (waterResult != null && waterResult['success'] == true) {
        try {
          print('About to save calculation for $cropName with total ${waterResult['totalWater']}');
          await _service.saveCalculation(
            area: area,
            areaUnit: _selectedUnit,
            cropType: cropName,
            soilType: _selectedSoil,
            waterRequired: waterResult['totalWater'] ?? 0,
            dailyWater: waterResult['dailyWater'] ?? 0,
            growingDays: waterResult['growingDays'] ?? 120,
            weatherCondition: weatherResult['condition'] ?? 'Unknown',
          );
          print('Save returned without exception');
          
          // Send water optimization notification
          final notificationService = NotificationService();
          await notificationService.notifyWaterAlertResolved(
            fieldName: cropName,
            action: 'Water optimization calculated: ${waterResult['totalWater']?.toStringAsFixed(0) ?? "N/A"} liters required',
          );
        } catch (e) {
          print('Exception while saving calculation: $e');
        }
      }

      setState(() {
        _result = waterResult ?? {
          'success': false, 'message': 'Engine Failure: Fallback triggered.'
        };
        _weatherData = weatherResult;
        _isLoading = false;
      });

      if (_result != null && _result!['success'] == true) {
        _showResultDialog();
      }
    } catch (e) {
      _showSnackBar('Engine Error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<Map<String, dynamic>?> _getAiCropDetails(String cropName) async {
    try {
      final prompt = '''You are an agriculture expert. Validate if "$cropName" is a real agricultural crop.
Return ONLY JSON (no markdown, no extra text):
{
  "valid": true/false,
  "cropName": "standard name",
  "growingDays": number (50-400),
  "waterPerDay": number in mm/day (15-120 mm/day, where 1mm/day = 10L/day/hectare),
  "season": "Kharif/Rabi/Summer/Year-round",
  "region": "suitable regions"
}
RESPOND ONLY WITH JSON.''';

      final response = await _aiService.sendMessage(prompt);
      print('AI raw crop-details response: $response');
      if (response == null) return null;
      if (response.toString().startsWith('Error:')) {
        print('AI service error while fetching crop details: $response');
        return null;
      }

      // Safe JSON Parse
      final jsonData = _parseJsonResponse(response);
      if (jsonData != null) {
        return jsonData;
      }
    } catch (e) {
      print('Error getting crop details securely caught: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> _getAiWaterCalculation({
    required String cropName,
    required double area,
    required String areaUnit,
    required String soilType,
    required Map<String, dynamic> cropDetails,
    required double forecastRainMm,
    required String irrigationMethod, // NEW: Irrigation dropdown parameter
  }) async {
    try {
      int days = 120; // safe default
      try {
        if (cropDetails['growingDays'] != null) {
          days = (cropDetails['growingDays'] as num).toInt();
          if (days <= 0) days = 120;
        }
      } catch (_) { }

      // Use the service's accurate calculation
      final result = _service.calculateWaterRequirement(
        area: area,
        areaUnit: areaUnit,
        cropType: cropName,
        soilType: soilType,
        growingDays: days,
        forecastRainMm: forecastRainMm,
        irrigationMethod: irrigationMethod, // NEW: Pass irrigation method to engine
      );

      print(' Water calculation result: $result');
      
      if (result['success'] == true) {
        return {
          'success': true,
          'cropName': result['crop'] ?? cropName,
          'totalWater': result['water'] ?? 0,
          'dailyWater': result['dailyWater'] ?? 0,
          'growingDays': result['growingDays'] ?? days,
          'soilFactor': _getSoilFactor(soilType),
          'recommendation': result['message'] ?? 'Watering optimization calculated',
        };
      }
    } catch (e) {
      print(' Error in water calculation caught: $e');
    }
    return null;
  }

  /// Get soil factor for display
  double _getSoilFactor(String soilType) {
    final factors = {
      'sandy': 1.3,
      'sandy-loam': 1.15,
      'loamy': 1.0,
      'clay-loam': 0.9,
      'clay': 0.75,
      'silty': 1.05,
    };
    return factors[soilType.toLowerCase()] ?? 1.0;
  }

  // Removed unused _convertToHectares method

  String _formatNum(dynamic n, {int decimals = 0}) {
    if (n == null) return '0';
    double val;
    if (n is num) {
      val = n.toDouble();
    } else {
      final parsed = num.tryParse(n.toString());
      if (parsed != null) {
        val = parsed.toDouble();
      } else {
        return n.toString();
      }
    }
    String str = val.toStringAsFixed(decimals);
    RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    String mathFunc(Match match) => '${match[1]},';
    return str.replaceAllMapped(reg, mathFunc);
  }

  String _capitalize(String? s) {
    if (s == null) return '';
    if (s.isEmpty) return '';
    return '${s[0].toUpperCase()}${s.substring(1)}';
  }

  Map<String, dynamic>? _parseJsonResponse(String response) {
    try {
      String cleanResponse = response.replaceAll('```json', '').replaceAll('```', '').trim();
      final startIndex = cleanResponse.indexOf('{');
      final endIndex = cleanResponse.lastIndexOf('}');

      if (startIndex == -1 || endIndex == -1) return null;

      final jsonString = cleanResponse.substring(startIndex, endIndex + 1);
      return _simpleJsonParse(jsonString);
    } catch (e) {
      return null;
    }
  }

  Map<String, dynamic> _simpleJsonParse(String jsonString) {
    final result = <String, dynamic>{};
    try {
      // Parse success
      result['success'] = jsonString.contains('"success": true');

      // Parse valid
      result['valid'] = jsonString.contains('"valid": true');

      // Parse string fields
      final fields = ['cropName', 'season', 'region', 'recommendation'];
      for (final field in fields) {
        final match = RegExp('"$field":\\s*"([^"]+)"').firstMatch(jsonString);
        if (match != null) result[field] = match.group(1);
      }

      // Parse number fields
      final numberFields = {
        'growingDays': 'growingDays',
        'waterPerDay': 'waterPerDay',
        'totalWater': 'totalWater',
        'dailyWater': 'dailyWater',
        'soilFactor': 'soilFactor',
      };

      for (final entry in numberFields.entries) {
        final match = RegExp('"${entry.key}":\\s*([\\d.]+)').firstMatch(jsonString);
        if (match != null) {
          final value = match.group(1)!;
          result[entry.value] = value.contains('.') ? double.parse(value) : int.parse(value);
        }
      }
    } catch (e) {
      print('Safe JSON Parse failure: $e');
    }
    return result;
  }

  void _showResultDialog() {
    if (_result == null || !(_result?['success'] ?? false)) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          color: Theme.of(context).cardColor,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  color: Colors.blue.shade700,
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Icon(Icons.water_drop, color: Theme.of(context).cardColor, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(LocalizationService.translate('Water Recommendation'),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Theme.of(context).cardColor,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Weather Status
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          border: Border.all(color: Colors.blue.shade200),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _weatherData?['message'] ?? 'Weather check done',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Daily Water (Main Highlight)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          border: Border.all(color: Colors.blue.shade400, width: 2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(LocalizationService.translate('Daily Water Needed'),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_formatNum(_result?['dailyWater'], decimals: 0)} L/day',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Total Water (Secondary)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          border: Border.all(color: Colors.blue.shade200),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(LocalizationService.translate('Total Season Water'),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue.shade700,
                              ),
                            ),
                            Text(
                              '${_formatNum(_result?['totalWater'], decimals: 0)} L',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Growing Days
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          border: Border.all(color: Colors.green.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(LocalizationService.translate('Growing Season'),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.green.shade700,
                              ),
                            ),
                            Text(
                              '${_result?['growingDays'] ?? 120} days',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // AI Recommendation
                      if (_result?['recommendation'] != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            border: Border.all(color: Colors.orange.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(LocalizationService.translate('AI Recommendation'),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade900,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _result?['recommendation'] ?? '',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                // Close button
                Padding(
                  padding: const EdgeInsets.only(bottom: 16, right: 16, left: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(LocalizationService.translate('Close'),
                        style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.blue.shade700,
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, String? id) async {
    if (id == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(LocalizationService.translate('Delete')),
        content: Text(LocalizationService.translate('Delete this calculation from history?')),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(LocalizationService.translate('Cancel'))),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(LocalizationService.translate('Delete'))),
        ],
      ),
    );

    if (ok == true) {
      try {
        await _service.deleteCalculation(id);
        _showSnackBar('Deleted');
      } catch (e) {
        _showSnackBar('Delete failed');
      }
    }
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.blue.shade700,
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Text(LocalizationService.translate('Water Optimization'),
                style: TextStyle(
                  color: Theme.of(context).cardColor,
                  fontSize: 24,
                  fontFamily: 'Arimo',
                  fontWeight: FontWeight.w400,
                ),
              ),
              const Spacer(),
              // NEW: Info button for data sources
              IconButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(LocalizationService.translate("Data Sources")),
                      content: const Text(
                        "• Water requirement values are derived from FAO Irrigation and Drainage Paper 56 (Crop Evapotranspiration) and adapted for South Asian conditions.\n\n"
                        "• Crop database includes over 20 crops with stage-specific coefficients.\n\n"
                        "• Effective rainfall formula: P_eff = Rainfall × 0.7 (FAO generalized guideline)."
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(LocalizationService.translate("Close")),
                        )
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.info_outline, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.water_drop, color: Theme.of(context).cardColor, size: 20),
              const SizedBox(width: 8),
              Text(LocalizationService.translate('Calculate Your Water Requirements'),
                style: TextStyle(
                  color: Color(0xE5FFFEFE),
                  fontSize: 16,
                  fontFamily: 'Arimo',
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Input Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Container(
                color: Theme.of(context).cardColor,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Land Area with Unit
                          Text(
                            _capitalize(tr('Land Area')),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue.shade900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start, // Align top for validation errors
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: _areaController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(decimal: true),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) return 'Required';
                                    if (double.tryParse(value) == null || double.parse(value) <= 0) return 'Invalid';
                                    return null;
                                  },
                                  decoration: InputDecoration(
                                    hintText: LocalizationService.translate('Enter area'),
                                    prefixIcon: Icon(Icons.square_foot, color: Colors.blue.shade300),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(color: Colors.blue.shade300),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide:
                                          BorderSide(color: Colors.blue.shade700, width: 2),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 1,
                                child: Container(
                                  height: 48, // Fixed height to match text field before error
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.blue.shade300),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedUnit,
                                      isExpanded: true,
                                      items: areaUnits
                                          .map((unit) => DropdownMenuItem(
                                                value: unit,
                                                child: Text(unit),
                                              ))
                                          .toList(),
                                      onChanged: (value) {
                                        if (value != null) setState(() => _selectedUnit = value);
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Crop Type - Autocomplete
                          Text(
                            _capitalize(tr('Crop Type')),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue.shade900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Autocomplete<String>(
                            optionsBuilder: (TextEditingValue textEditingValue) {
                              if (textEditingValue.text == '') {
                                return const Iterable<String>.empty();
                              }
                              return _service.availableCrops.where((String option) {
                                return option.contains(textEditingValue.text.toLowerCase());
                              });
                            },
                            onSelected: (String selection) {
                              _cropController.text = selection;
                            },
                            fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                              // Ensure the main controller stays in sync
                              controller.addListener(() {
                                if (_cropController.text != controller.text) {
                                  _cropController.text = controller.text;
                                }
                              });
                              // Initialize with existing value if any
                              if (controller.text.isEmpty && _cropController.text.isNotEmpty) {
                                controller.text = _cropController.text;
                              }
                              return TextFormField(
                                controller: controller,
                                focusNode: focusNode,
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'Please enter crop name';
                                  if (!_service.availableCrops.contains(value.toLowerCase())) {
                                    return 'Crop not found in database';
                                  }
                                  return null;
                                },
                                decoration: InputDecoration(
                                  hintText: LocalizationService.translate('Search crop (e.g., wheat, rice)'),
                                  prefixIcon: Icon(Icons.grass, color: Colors.green.shade400),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: Colors.blue.shade300),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Colors.blue.shade700,
                                      width: 2,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                ),
                              );
                            },
                          ),
                    const SizedBox(height: 16),

                    // Soil Type
                    Text(
                      _capitalize(tr('Soil Type')),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedSoil,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.blue.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              BorderSide(color: Colors.blue.shade700, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      items: soilTypes
                          .map((soil) => DropdownMenuItem(
                                value: soil,
                                child: Text(_capitalize(soil.replaceAll('-', ' '))),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => _selectedSoil = value);
                      },
                    ),
                    const SizedBox(height: 16),

                    // NEW: Irrigation Method Dropdown
                    Text(LocalizationService.translate('Irrigation Method'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedIrrigationMethod,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.blue.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              BorderSide(color: Colors.blue.shade700, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      items: irrigationMethods
                          .map((method) => DropdownMenuItem(
                                value: method,
                                child: Text(method),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => _selectedIrrigationMethod = value);
                      },
                    ),
                    const SizedBox(height: 24),

                    // Calculate Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : () {
                          if (_formKey.currentState?.validate() ?? false) {
                            _calculateWater();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          disabledBackgroundColor: Colors.grey,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Theme.of(context).cardColor,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(LocalizationService.translate('Calculate'),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).cardColor,
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
            ),
            const SizedBox(height: 24),

            // History Title
            Text(
              _capitalize(tr('history')),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade900,
              ),
            ),
            const SizedBox(height: 12),

            // History List
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _service.getCalculationHistory(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        tr('no_data'),
                        style: TextStyle(color: Colors.blue.shade500),
                      ),
                    ),
                  );
                }

                final history = snapshot.data ?? [];
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final item = history[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.blue.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '${_capitalize(item['crop']?.toString())} - ${item['area'].toStringAsFixed(1)} ${item['areaUnit'] ?? 'acres'}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Colors.blue.shade900,
                                    ),
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      item['date'] ?? '',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue.shade500,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: Icon(Icons.delete, size: 18, color: Colors.red.shade400),
                                      onPressed: () => _confirmDelete(context, item['id']),
                                      tooltip: 'Delete',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Total: ${_formatNum(item['water'], decimals: 0)} L',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue.shade700,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      'Daily: ${_formatNum(item['dailyWater'], decimals: 0)} L',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Soil: ${_capitalize(item['soilType']?.replaceAll('-', ' ') ?? 'N/A')}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue.shade600,
                                      ),
                                    ),
                                    Text(
                                      'Days: ${item['growingDays'] ?? 120}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
            ),
          ],
        ),
      ),
    );
  }
}
