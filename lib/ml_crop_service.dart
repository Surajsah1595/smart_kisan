import 'dart:convert';
import 'package:http/http.dart' as http;
import 'ai_service.dart';

class MlCropService {
  // Configured to point to the local FastAPI ML instance.
  // Note: 10.0.2.2 is the localhost alias for Android Emulator. 127.0.0.1 for Windows.
  // We use your local Windows IPv4 address since you test on a physical Redmi phone.
  final String _mlApiUrl = 'http://192.168.1.66:8000/predict';

  /// Maps the current month to the appropriate crop season.
  String getCurrentSeason() {
    final int month = DateTime.now().month;
    if (month >= 3 && month <= 5) return 'Summer';
    if (month >= 6 && month <= 9) return 'Monsoon';
    return 'Winter'; // Oct to Feb
  }

  /// Calls the FastAPI ML model prediction endpoint.
  Future<String?> getMLPrediction(String soilType, String season) async {
    try {
      final response = await http.post(
        Uri.parse(_mlApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'soil_type': soilType,
          'season': season,
          'temp': 28.0,
          'ph': 6.5,
          'rainfall': 150.0
        }),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String predictedCrop = data['recommended_crop'];
        print('✅ ML successful: $predictedCrop');
        return predictedCrop;
      } else {
        print('❌ ML API Error: Status ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ ML call failed: $e');
      return null;
    }
  }

  /// Backup recommendation using Gemini via existing AiService.
  Future<String?> getGeminiBackup(String soilType, String season) async {
    try {
      final aiService = AiService();
      final String prompt = 'Based on soil $soilType and $season season, recommend one crop name for South Asia. Reply with just crop name.';
      final String? response = await aiService.sendMessage(prompt);
      
      if (response != null && !response.startsWith('Error:')) {
        final cropName = response.trim();
        print('✅ Gemini Backup successful: $cropName');
        return cropName;
      }
      return null;
    } catch (e) {
      print('❌ Gemini Backup failed: $e');
      return null;
    }
  }

  /// Tries ML prediction first, falls back to Gemini if ML fails.
  Future<String> getRecommendation(String soilType, String season) async {
    print('🔍 Getting recommendation for Soil: $soilType, Season: $season');
    
    // 1. Try ML Model
    String? crop = await getMLPrediction(soilType, season);
    
    if (crop != null && crop.isNotEmpty) {
      return crop;
    }
    
    // 2. Fallback to Gemini
    print('⚠️ Falling back to Gemini Backup');
    crop = await getGeminiBackup(soilType, season);
    
    if (crop != null && crop.isNotEmpty) {
      return crop;
    }
    
    // 3. Complete Failure
    print('🚨 Both ML and Gemini completely failed.');
    return 'Error: Could not determine crop';
  }
}
