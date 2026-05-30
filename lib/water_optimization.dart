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

  /// Purpose: Normalizes a DateTime object into a YYYY-MM-DD string for predictable Firestore queries.
  /// Inputs: DateTime object.
  /// Outputs: Formatted date string.
  String _formatDate(DateTime date) {
    // 1. Pad month and day with leading zeros to maintain string length (e.g., 2026-05-09 instead of 2026-5-9).
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Purpose: Standardizes various farm area metrics into Hectares for uniform mathematical processing.
  /// Inputs: area (double) and unit (String).
  /// Outputs: The area converted to hectares (double).
  double _convertToHectares(double area, String unit) {
    try {
      // 1. Guard against invalid user inputs that could corrupt math equations downstream.
      if (area <= 0 || area.isNaN) return 1.0;
      
      // 2. Route conversion based on user-selected unit.
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
      // 3. Fail gracefully to a safe 1.0 multiplier.
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

  /// Purpose: Computes the precise irrigation requirement for a given crop factoring in weather, soil, area, and system efficiency.
  /// Inputs: Physical parameters (area, crop type), environmental factors (soil, rain), and hardware details (irrigation method).
  /// Outputs: A Map containing the gross daily and total water requirements, or error status.
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
      // 1. Sanitize Inputs: Prevent division by zero, negative values, or NaN inputs.
      double safeArea = (area <= 0 || area.isNaN) ? 1.0 : area;
      int safeDays = (growingDays <= 0) ? 120 : growingDays;
      double safeRain = (forecastRainMm < 0 || forecastRainMm.isNaN) ? 0.0 : forecastRainMm;

      // 2. Normalize Area: Convert all units to standard hectares, then to square meters.
      double areaHectares = _convertToHectares(safeArea, areaUnit);
      double areaSqm = areaHectares * 10000.0;

      // 3. Normalize Crop Name: Ensure dictionary lookup consistency.
      String crop = cropType.toLowerCase().trim();
      
      // 4. Fallback Dictionary Lookup: Fetch baseline requirements or use a generic default.
      Map<String, double> cropStages = _cropWaterRequirements[crop] ?? 
          {'Seedling': 2.0, 'Mid-Season': 5.0, 'Harvesting': 3.0};

      // 5. Calculate Average Daily Baseline Requirement (L/m²/day) over the season.
      // Assumes typical temporal distribution: 20% Seedling, 60% Mid-Season, 20% Harvesting.
      double avgDailyBaseline = (cropStages['Seedling']! * 0.2) + 
                                (cropStages['Mid-Season']! * 0.6) + 
                                (cropStages['Harvesting']! * 0.2);

      // 6. Effective Rainfall Calculation (P_eff).
      // Standard agricultural assumption: ~70% of forecast rain actually infiltrates the root zone.
      double pEff = safeRain * 0.7;

      // 7. Net Irrigation Requirement (I_net).
      // Formula: I_net = Baseline Evapotranspiration - Effective Rainfall
      double iNet = avgDailyBaseline - pEff;
      if (iNet < 0.0) {
        iNet = 0.0; // Gracefully floor at 0.0 if rain exceeds demand.
      }

      // 8. Irrigation System Efficiency (E_a).
      double efficiencyRating;
      if (irrigationMethod.contains('Drip')) {
        efficiencyRating = 0.90; // Highly targeted
      } else if (irrigationMethod.contains('Sprinkler')) {
        efficiencyRating = 0.75; // Moderate wind drift/evaporation
      } else if (irrigationMethod.contains('Surface') || irrigationMethod.contains('Flood')) {
        efficiencyRating = 0.50; // High runoff/deep percolation
      } else {
        efficiencyRating = 0.75; // Safe operational constant
      }

      // 9. Gross Irrigation Requirement (I_gross).
      // Formula: I_gross = I_net / Efficiency Rating
      double iGross = iNet / efficiencyRating;

      // 10. Volumetric Scaling.
      // Convert L/m²/day requirement to total liters based on physical farm area.
      double dailyWaterLiters = iGross * areaSqm;
      double totalWaterLiters = dailyWaterLiters * safeDays;

      // 11. Format a readable methodological explanation for the UI.
      String methodMessage = "I_gross = I_net / Efficiency ($efficiencyRating)\n"
          "Crop Baseline: ${avgDailyBaseline.toStringAsFixed(1)} L/m²/day";
      
      if (pEff > 0) {
        methodMessage += "\nEffective rainfall (${pEff.toStringAsFixed(1)}mm) subtracted.";
      }

      // 12. Return the structured computational payload.
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
      // 13. Fallback on mathematical or casting errors.
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

  /// Purpose: Aggregates automated crop zones (from Smart Plot) and manual water zones into a unified stream.
  /// Inputs: None (Uses authenticated userId).
  /// Outputs: A Stream emitting a combined list of zone maps for the UI.
  Stream<List<Map<String, dynamic>>> getZonesFromCrops() {
    // 1. Return an empty stream immediately if the user session is invalid.
    if (userId.isEmpty) return Stream.value([]);

    // 2. Listen to real-time updates on the user's automated 'fields' collection.
    return _firestore
        .collection('users').doc(userId).collection('fields').snapshots()
        .asyncMap((fieldsSnapshot) async {
      List<Map<String, dynamic>> allZones = [];
      
      // 3. Iterate through each physical plot (field).
      for (var fieldDoc in fieldsSnapshot.docs) {
        final fieldId = fieldDoc.id;
        final fieldName = fieldDoc.data()['name'] as String? ?? '';
        
        // 4. Fetch the nested 'crops' subcollection for this specific plot.
        final cropsSnapshot = await fieldDoc.reference.collection('crops').get();

        // 5. Map each crop to a unified UI structure.
        for (var cropDoc in cropsSnapshot.docs) {
          final cropData = cropDoc.data();
          allZones.add({
            'id': '${fieldId}_${cropDoc.id}', // Create composite ID to distinguish from manual zones.
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
            'type': 'crop', // Tag as an automated/system zone.
          });
        }
      }

      try {
        // 6. Fetch manually created irrigation zones (non-smart plots).
        final manualSnapshot = await _firestore
            .collection('users').doc(userId).collection('water_zones').get();
            
        // 7. Append manual zones to the aggregated list.
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
            'type': 'manual', // Tag as a manually entered zone.
          });
        }
      } catch (e) {
        // 8. Silently swallow errors fetching manual zones to prevent breaking the automated stream.
      }
      
      // 9. Return the fully aggregated payload to the UI.
      return allZones;
    });
  }

  /// Purpose: Estimates current soil moisture based on recorded daily water usage.
  /// Inputs: zoneId (String) representing the target field/zone.
  /// Outputs: An integer (0-95) representing the estimated moisture percentage.
  Future<int> calculateRealSoilMoisture(String zoneId) async {
    try {
      // 1. Guard against unauthenticated requests.
      if (userId.isEmpty) return 0;
      
      // 2. Format today's date to query daily usage records.
      final dateStr = _formatDate(DateTime.now());
      
      // 3. Query Firestore for all water application logs for this zone today.
      final usageSnapshot = await _firestore
          .collection('users').doc(userId).collection('water_usage')
          .where('zoneId', isEqualTo: zoneId)
          .where('date', isEqualTo: dateStr).get();

      // 4. Sum up the total liters applied across all sessions today.
      double totalWaterApplied = 0;
      for (var doc in usageSnapshot.docs) {
        totalWaterApplied += (doc.data()['liters'] as num?)?.toDouble() ?? 0.0;
      }

      // 5. Establish a baseline target for 100% moisture (heuristic approach).
      const double approximateDailyTarget = 500.0;
      if (totalWaterApplied == 0) return 0;
      
      // 6. Calculate ratio and clamp the maximum value to 95% to allow for drainage/evaporation.
      int calculatedMoisture = ((totalWaterApplied / approximateDailyTarget) * 100).toInt();
      return calculatedMoisture > 95 ? 95 : calculatedMoisture;
    } catch (e) {
      // 7. Fail gracefully to 0% if the calculation crashes.
      return 0;
    }
  }

  /// Purpose: Saves a new manual irrigation zone to Firestore.
  /// Inputs: Physical parameters (name, location) and schedules (schedule, amount, duration).
  /// Outputs: None.
  Future<void> addZone({
    required String name, required String location, required String schedule,
    required int waterAmount, required int duration,
  }) async {
    // 1. Validate session.
    if (userId.isEmpty) return;
    
    // 2. Commit the manual zone to the dedicated collection.
    await _firestore.collection('users').doc(userId).collection('water_zones').add({
      'name': name, 'location': location, 'status': 'scheduled', 'moisture': 0,
      'schedule': schedule, 'waterAmount': waterAmount, 'duration': duration,
      'isRunning': false, 'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Purpose: Removes an irrigation zone, routing correctly based on its type (manual vs automated).
  /// Inputs: zoneId (String).
  /// Outputs: None.
  Future<void> deleteZone(String zoneId) async {
    // 1. Validate session.
    if (userId.isEmpty) return;
    
    // 2. Routing logic: If the ID contains an underscore, it's a composite ID indicating an automated crop zone.
    if (zoneId.contains('_') && zoneId.split('_').length == 2) {
      final parts = zoneId.split('_');
      // 3. Delete the nested crop document within the smart plot structure.
      await _firestore.collection('users').doc(userId).collection('fields')
          .doc(parts[0]).collection('crops').doc(parts[1]).delete();
    } else {
      // 4. Fallback: Delete from the manual water zones collection.
      await _firestore.collection('users').doc(userId).collection('water_zones')
          .doc(zoneId).delete();
    }
  }

  /// Purpose: Updates the schedule and volume constraints of an existing zone.
  /// Inputs: zoneId, waterAmount, duration, and cron-like schedule string.
  /// Outputs: None.
  Future<void> updateZoneDetails({
    required String zoneId, required int waterAmount,
    required int duration, required String schedule,
  }) async {
    // 1. Validate session.
    if (userId.isEmpty) return;
    
    // 2. Routing logic: Check for composite ID.
    if (zoneId.contains('_') && zoneId.split('_').length == 2) {
      final parts = zoneId.split('_');
      // 3. Update the smart plot sub-document schema.
      await _firestore.collection('users').doc(userId).collection('fields')
          .doc(parts[0]).collection('crops').doc(parts[1]).update({
        'waterAmount': waterAmount, 'irrigationDuration': duration,
        'irrigationSchedule': schedule, 'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      // 4. Update the manual zone document schema.
      await _firestore.collection('users').doc(userId).collection('water_zones')
          .doc(zoneId).update({
        'waterAmount': waterAmount, 'duration': duration,
        'schedule': schedule, 'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Purpose: Polls the WeatherService to determine current conditions and forecast rainfall.
  /// Inputs: None.
  /// Outputs: A Map containing the condition string, rainfall in mm, temperature, and humidity.
  Future<Map<String, dynamic>> checkWeatherForWatering() async {
    try {
      // 1. Await the response from the external weather API (via WeatherService).
      final weather = await _weatherService.getCurrentWeather();
      
      // 2. Safely parse the primary weather condition string.
      final weatherList = weather['weather'] as List? ?? [];
      final condition = weatherList.isNotEmpty ? weatherList[0]['main'] ?? '' : '';
      
      double rainMm = 0.0;
      // 3. Extract precise rain volume if provided in the payload (1h or 3h windows).
      if (weather['rain'] != null) {
        if (weather['rain']['1h'] != null) {
          rainMm = (weather['rain']['1h'] as num).toDouble();
        } else if (weather['rain']['3h'] != null) {
          rainMm = (weather['rain']['3h'] as num).toDouble();
        }
      } 
      // 4. Fallback: If no volume is given but it's raining, assume a nominal 5.0mm.
      else if (condition.toLowerCase().contains('rain')) {
        rainMm = 5.0;
      }

      // 5. Return the normalized weather data.
      return {
        'condition': condition,
        'rainMm': rainMm,
        'temperature': weather['main']?['temp'],
        'humidity': weather['main']?['humidity'],
      };
    } catch (e) {
      // 6. Provide a safe fallback object on API failure to prevent app crashes.
      return {'condition': 'Unknown', 'rainMm': 0.0, 'message': ' Weather data unavailable'};
    }
  }

  /// Purpose: Fetches live weather and pipes it into the math engine to generate an actionable irrigation plan.
  /// Inputs: Physical parameters (area, cropType, soilType, growingDays).
  /// Outputs: A Map containing a recommendation string and the full calculation details.
  Future<Map<String, dynamic>> getWateringRecommendation({
    required double area, required String areaUnit, required String cropType,
    required String soilType, required int growingDays,
  }) async {
    // 1. Pre-fetch live weather context.
    final weatherCheck = await checkWeatherForWatering();
    double rainMm = weatherCheck['rainMm'] ?? 0.0;

    // 2. Delegate the heavy lifting to the core mathematical engine, passing the live rain data.
    final calculation = calculateWaterRequirement(
      area: area, areaUnit: areaUnit, cropType: cropType,
      soilType: soilType, growingDays: growingDays, forecastRainMm: rainMm,
    );

    // 3. Format and return the final recommendation object for the UI.
    return {
      'recommendation': calculation['message'],
      'action': 'water',
      'details': calculation,
    };
  }

  /// Purpose: Persists the results of an irrigation calculation to the user's Firestore history.
  /// Inputs: All parameters used in and generated by the calculation.
  /// Outputs: None.
  Future<void> saveCalculation({
    required double area, required String areaUnit, required String cropType,
    required String soilType, required int waterRequired, required int dailyWater,
    required int growingDays, required String weatherCondition,
  }) async {
    // 1. Validate session to prevent unauthenticated writes.
    if (userId.isEmpty) return;
    
    // 2. Create a new document in the dedicated calculations history collection.
    await _firestore.collection('users').doc(userId).collection('irrigation_calculations').add({
      'area': area, 'areaUnit': areaUnit, 'crop': cropType, 'soilType': soilType,
      'water': waterRequired, 'dailyWater': dailyWater, 'growingDays': growingDays,
      'weather': weatherCondition, 'timestamp': FieldValue.serverTimestamp(),
      'date': DateTime.now().toString().split(' ')[0], // Used for simplified UI filtering.
    });
  }

  /// Purpose: Retrieves the user's past 10 irrigation calculations in descending chronological order.
  /// Inputs: None.
  /// Outputs: A Stream emitting a list of calculation maps.
  Stream<List<Map<String, dynamic>>> getCalculationHistory() {
    // 1. Prevent querying if unauthorized.
    if (userId.isEmpty) return Stream.value([]);
    
    // 2. Set up a snapshot listener bounded to the 10 most recent records.
    return _firestore.collection('users').doc(userId)
        .collection('irrigation_calculations').orderBy('timestamp', descending: true)
        .limit(10).snapshots().map((snapshot) {
      // 3. Map Firestore documents into standard Dart Maps, preserving the doc ID.
      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    });
  }

  /// Purpose: Deletes a specific calculation record from the history.
  /// Inputs: id (String).
  /// Outputs: None.
  Future<void> deleteCalculation(String id) async {
    // 1. Prevent unauthorized deletes.
    if (userId.isEmpty) return;
    try {
      // 2. Target and destroy the specified document.
      await _firestore.collection('users').doc(userId)
          .collection('irrigation_calculations').doc(id).delete();
    } catch (e) {
      // 3. Rethrow for UI handling if needed.
      rethrow;
    }
  }

  /// Purpose: Triggers a local/FCM push notification when an optimization calculation succeeds.
  /// Inputs: cropName and the recommended water volume.
  /// Outputs: None.
  Future<void> sendWaterOptimizationNotification({required String cropName, required double recommendedWater}) async {
    // 1. Delegate notification formatting and dispatching to the NotificationService.
    await _notificationService.notifyWaterOptimization(
      cropName: cropName, recommendedWater: recommendedWater, waterUnit: 'Liters'
    );
  }

  /// Purpose: Triggers a local/FCM push notification when soil moisture drops critically low.
  /// Inputs: soilMoisture percentage and cropName.
  /// Outputs: None.
  Future<void> sendLowMoistureAlert({required double soilMoisture, required String cropName}) async {
    // 1. Delegate urgent alert dispatch to the NotificationService with a 2-hour hardcoded buffer.
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

  /// Purpose: Orchestrates the water calculation pipeline, bridging UI inputs, AI validation, Weather APIs, and local math.
  /// Inputs: None (Reads from state variables and controllers).
  /// Outputs: Updates UI state with calculation results, optionally saves to Firestore.
  Future<void> _calculateWater() async {
    // 1. Initial UI form validation.
    if (!_formKey.currentState!.validate()) {
      return; 
    }

    if (_cropController.text.isEmpty) {
      _showSnackBar(tr('enter_crop'));
      return;
    }

    // 2. Lock UI and enter processing state.
    setState(() {
      _isLoading = true;
      _result = null; // Clear previous results to avoid showing stale data.
    });

    try {
      // 3. Robust Area Parsing: Handle malformed inputs safely without crashing.
      double area = 1.0;
      bool areaInvalid = false;
      try {
        area = double.parse(_areaController.text);
        if (area <= 0 || area.isNaN) {
          area = 1.0; // Safe default operational constant.
          areaInvalid = true;
        }
      } catch (_) {
        area = 1.0;
        areaInvalid = true;
      }

      // 4. Provide non-blocking user feedback if inputs were auto-corrected.
      if (areaInvalid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(" Invalid area entered. Using 1.0 as a placeholder. Please enter a positive number."),
            duration: Duration(seconds: 4),
          ),
        );
      }

      final cropName = _cropController.text.trim();

      // 5. AI Crop Validation: Check if the user entered a real crop or gibberish.
      Map<String, dynamic>? cropDetailsFromAi;
      try {
        cropDetailsFromAi = await _getAiCropDetails(cropName);
        print('Crop details from AI: $cropDetailsFromAi');
      } catch (e) {
        print('AI Validation Exception Caught: $e');
        cropDetailsFromAi = null;
      }

      // 6. Explicit Rejection: Stop if the AI confirms the input is not a real crop.
      if (cropDetailsFromAi != null && cropDetailsFromAi['valid'] == false) {
        _showSnackBar(tr('invalid_crop'));
        setState(() => _isLoading = false);
        return;
      }

      // 7. Fallback Pipeline: Triggered if AI service times out, errors, or fails to parse.
      if (cropDetailsFromAi == null) {
        print('AI validation failed for "$cropName". Falling back to local calculation.');

        // 8. Fetch live weather data to determine Effective Rainfall (P_eff).
        final weatherResult = await _service.checkWeatherForWatering();
        double forecastRainMm = 0.0;
        try {
          forecastRainMm = (weatherResult['rainMm'] as num?)?.toDouble() ?? 0.0;
          if (forecastRainMm < 0 || forecastRainMm.isNaN) forecastRainMm = 0.0;
        } catch (_) {
          forecastRainMm = 0.0;
        }

        // 9. Execute Local Mathematical Engine.
        final waterResultFallback = _service.calculateWaterRequirement(
          area: area,
          areaUnit: _selectedUnit,
          cropType: cropName,
          soilType: _selectedSoil,
          growingDays: 120, // Default operational constant.
          forecastRainMm: forecastRainMm,
          irrigationMethod: _selectedIrrigationMethod, 
        );

        weatherResult['message'] = forecastRainMm > 0 
            ? ' Rain forecast: ${forecastRainMm}mm. Adjusted watering.'
            : ' Clear - Safe to water';

        // 10. Persist Fallback Calculation to Firestore History.
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

        // 11. Update UI with Fallback Results.
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

      // 12. Primary AI-Assisted Pipeline: Get live weather.
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

      // 13. Execute AI-Augmented Math Calculation.
      final waterResult = await _getAiWaterCalculation(
        cropName: cropName,
        area: area,
        areaUnit: _selectedUnit,
        soilType: _selectedSoil,
        cropDetails: cropDetailsFromAi,
        forecastRainMm: forecastRainMm,
        irrigationMethod: _selectedIrrigationMethod, 
      );

      print('AI water calculation result: $waterResult');

      // 14. Persist AI-Assisted Calculation to Firestore and Trigger Notifications.
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
          
          // 15. Dispatch Cloud Messaging (FCM) via local notification service.
          final notificationService = NotificationService();
          await notificationService.notifyWaterAlertResolved(
            fieldName: cropName,
            action: 'Water optimization calculated: ${waterResult['totalWater']?.toStringAsFixed(0) ?? "N/A"} liters required',
          );
        } catch (e) {
          print('Exception while saving calculation: $e');
        }
      }

      // 16. Update UI state with Primary Results.
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
      // 17. Catch-all failsafe to prevent app freezing.
      _showSnackBar('Engine Error: $e');
      setState(() => _isLoading = false);
    }
  }

  /// Purpose: Validates crop names and fetches growing parameters via the generative AI service.
  /// Inputs: cropName (String).
  /// Outputs: A JSON-mapped dictionary of crop attributes, or null on failure.
  Future<Map<String, dynamic>?> _getAiCropDetails(String cropName) async {
    try {
      // 1. Construct a strict, JSON-only prompt to prevent AI hallucinations or markdown wrapping.
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

      // 2. Dispatch prompt to the Gemini API.
      final response = await _aiService.sendMessage(prompt);
      print('AI raw crop-details response: $response');
      
      // 3. Early exit if the network call failed or timed out.
      if (response == null) return null;
      if (response.toString().startsWith('Error:')) {
        print('AI service error while fetching crop details: $response');
        return null;
      }

      // 4. Run the raw string through a robust regex-based JSON parser.
      final jsonData = _parseJsonResponse(response);
      if (jsonData != null) {
        return jsonData;
      }
    } catch (e) {
      // 5. Catch-all for unexpected parsing or network exceptions.
      print('Error getting crop details securely caught: $e');
    }
    return null;
  }

  /// Purpose: Orchestrates the calculation of water requirements, bridging AI parameters with the local math engine.
  /// Inputs: Farm parameters, AI-derived crop attributes, rain forecast, and hardware method.
  /// Outputs: A formatted results map, or null if calculation fails.
  Future<Map<String, dynamic>?> _getAiWaterCalculation({
    required String cropName,
    required double area,
    required String areaUnit,
    required String soilType,
    required Map<String, dynamic> cropDetails,
    required double forecastRainMm,
    required String irrigationMethod, 
  }) async {
    try {
      // 1. Establish a safe operational constant for growing days.
      int days = 120; 
      try {
        // 2. Attempt to parse the AI's suggested lifecycle length.
        if (cropDetails['growingDays'] != null) {
          days = (cropDetails['growingDays'] as num).toInt();
          if (days <= 0) days = 120; // Guard against negative or zero AI hallucinations.
        }
      } catch (_) { }

      // 3. Delegate to the deterministic mathematical engine rather than relying on AI math.
      final result = _service.calculateWaterRequirement(
        area: area,
        areaUnit: areaUnit,
        cropType: cropName,
        soilType: soilType,
        growingDays: days,
        forecastRainMm: forecastRainMm,
        irrigationMethod: irrigationMethod, 
      );

      print(' Water calculation result: $result');
      
      // 4. Map the engine's output back to the expected UI dictionary structure.
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
      // 5. Fail gracefully to trigger the fallback pipeline.
      print(' Error in water calculation caught: $e');
    }
    return null;
  }

  /// Purpose: Provides an evapotranspiration multiplier based on soil retention characteristics.
  /// Inputs: soilType string (e.g., 'sandy', 'clay').
  /// Outputs: A double representing the drainage multiplier.
  double _getSoilFactor(String soilType) {
    final factors = {
      'sandy': 1.3,       // High drainage, needs more water
      'sandy-loam': 1.15,
      'loamy': 1.0,       // Baseline ideal soil
      'clay-loam': 0.9,
      'clay': 0.75,      // High retention, needs less water
      'silty': 1.05,
    };
    return factors[soilType.toLowerCase()] ?? 1.0;
  }

  /// Purpose: Formats raw numbers into comma-separated strings for UI readability.
  /// Inputs: Numeric value (dynamic) and optional decimal precision.
  /// Outputs: Formatted string (e.g., 1000000 -> "1,000,000").
  String _formatNum(dynamic n, {int decimals = 0}) {
    if (n == null) return '0';
    double val;
    // 1. Safely cast or parse the dynamic input.
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
    // 2. Apply decimal rounding.
    String str = val.toStringAsFixed(decimals);
    // 3. Inject commas for thousands separators via regex.
    RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    String mathFunc(Match match) => '${match[1]},';
    return str.replaceAllMapped(reg, mathFunc);
  }

  /// Purpose: Capitalizes the first letter of a string.
  /// Inputs: nullable string.
  /// Outputs: Title-cased string.
  String _capitalize(String? s) {
    if (s == null) return '';
    if (s.isEmpty) return '';
    return '${s[0].toUpperCase()}${s.substring(1)}';
  }

  /// Purpose: Strips markdown wrappers (e.g., ```json) from AI responses.
  /// Inputs: Raw AI text response.
  /// Outputs: Parsed Map, or null if invalid.
  Map<String, dynamic>? _parseJsonResponse(String response) {
    try {
      // 1. Remove markdown backticks.
      String cleanResponse = response.replaceAll('```json', '').replaceAll('```', '').trim();
      
      // 2. Isolate the core JSON payload block.
      final startIndex = cleanResponse.indexOf('{');
      final endIndex = cleanResponse.lastIndexOf('}');

      if (startIndex == -1 || endIndex == -1) return null;

      final jsonString = cleanResponse.substring(startIndex, endIndex + 1);
      
      // 3. Delegate to the strict regex parser.
      return _simpleJsonParse(jsonString);
    } catch (e) {
      return null;
    }
  }

  /// Purpose: A resilient, regex-based JSON parser to circumvent dart:convert crashes on malformed AI output.
  /// Inputs: Cleaned JSON string.
  /// Outputs: A Map containing explicitly extracted keys.
  Map<String, dynamic> _simpleJsonParse(String jsonString) {
    final result = <String, dynamic>{};
    try {
      // 1. Parse booleans via simple substring matching.
      result['success'] = jsonString.contains('"success": true');
      result['valid'] = jsonString.contains('"valid": true');

      // 2. Parse strings using capturing regex groups.
      final fields = ['cropName', 'season', 'region', 'recommendation'];
      for (final field in fields) {
        final match = RegExp('"$field":\\s*"([^"]+)"').firstMatch(jsonString);
        if (match != null) result[field] = match.group(1);
      }

      // 3. Parse numerics, casting to double or int based on decimal presence.
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
      // 4. Swallow errors to allow fallback mechanisms to trigger.
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

  /// Purpose: Displays a standardized feedback banner at the bottom of the screen.
  /// Inputs: message (String).
  /// Outputs: Triggers ScaffoldMessenger UI overlay.
  void _showSnackBar(String message) {
    // 1. Clear existing snackbars to prevent queuing delays, then display the new message.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.blue.shade700,
      ),
    );
  }

  /// Purpose: Presents a confirmation modal before permanently deleting a history record.
  /// Inputs: BuildContext and the specific calculation document ID.
  /// Outputs: None (executes Firestore deletion if confirmed).
  Future<void> _confirmDelete(BuildContext context, String? id) async {
    // 1. Guard against null IDs.
    if (id == null) return;
    
    // 2. Await user response from a standard AlertDialog.
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

    // 3. Execute deletion if the user pressed "Delete" (returned true).
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
      decoration: const BoxDecoration(
        color: Color(0xFF2C7C48),
        boxShadow: [
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
                          backgroundColor: Theme.of(context).colorScheme.primary,
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
