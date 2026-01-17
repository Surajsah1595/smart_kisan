import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class AiService {
  static const String _apiKey = '';

  // We will try these models in order. The app will use the first one that works.
  static const List<String> _modelCandidates = [
    'gemini-1.5-flash',
    'gemini-2.5-flash', // Found in logs
    'gemini-pro',
    'gemini-1.5-pro',
    'gemini-1.0-pro',
  ];

  Future<String?> sendMessage(String message) async {
    for (String modelName in _modelCandidates) {
      print("🔄 Trying model: $modelName...");
      final result = await _tryModel(modelName, message);
      
      if (result != null) {
        print("✅ Success! Connected using: $modelName");
        return result;
      }
    }
    return "Error: Could not connect to any AI model. Please check your API Key permissions.";
  }

  Future<String?> _tryModel(String modelName, String message) async {
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent?key=$_apiKey'
    );

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {
                  "text": """
                You are 'Smart Kisan', a practical agriculture expert. 
                Answer the following question for a farmer using these rules:
                1. Use clear BULLET POINTS.
                2. Use **BOLD** for important names of medicines or techniques.
                3. Keep the answer very SHORT (maximum 100-150 words).
                4. Give direct advice, no long introductions.

                Question: $message
                """
                }
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
           return data['candidates'][0]['content']['parts'][0]['text'];
        }
      }
      return null; // Failed or empty response, try next model
    } catch (e) {
      print("⚠️ Failed to connect to $modelName: $e");
      return null; // Network error, try next model
    }
  }

  /// Analyze crop image for pests/diseases
  Future<String?> analyzeImage(String imagePath) async {
    try {
      final imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        throw Exception('Image file not found: $imagePath');
      }

      final imageBytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(imageBytes);

      for (String modelName in _modelCandidates) {
        print("🔄 [IMAGE] Trying model: $modelName...");
        final result = await _tryImageModel(modelName, base64Image);
        
        if (result != null) {
          print("✅ [IMAGE] Success! Connected using: $modelName");
          return result;
        }
      }
      return null;
    } catch (e) {
      print("❌ [IMAGE] analyzeImage error: $e");
      return null;
    }
  }

  Future<String?> _tryImageModel(String modelName, String base64Image) async {
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent?key=$_apiKey'
    );

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {
                  "text": """You are a crop disease and pest detection expert. Analyze this crop/plant image and provide assessment in JSON format ONLY.

Respond with ONLY a JSON object (no markdown, no extra text):
{
  "cropName": "crop name here",
  "status": "Healthy" or "Pest Alert" or "Disease Detected",
  "confidence": 0.92,
  "pestName": "pest/disease name or null",
  "description": "brief description of findings",
  "treatment": "recommended treatment",
  "severity": "Low" or "Medium" or "High"
}"""
                },
                {
                  "inlineData": {
                    "mimeType": "image/jpeg",
                    "data": base64Image
                  }
                }
              ]
            }
          ]
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          return data['candidates'][0]['content']['parts'][0]['text'];
        }
      }
      return null;
    } catch (e) {
      print("⚠️ [IMAGE] Failed with $modelName: $e");
      return null;
    }
  }
}