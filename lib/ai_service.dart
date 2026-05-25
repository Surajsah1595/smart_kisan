import 'dart:convert';
import 'dart:io';
import 'localization_service.dart';
import 'package:http/http.dart' as http;

class AiService {
  static const String apiKey = '';

  // We will try these models in order. The app will use the first one that works.
  static const List<String> _modelCandidates = [
    'gemini-1.5-flash',
    'gemini-2.5-flash', 
    'gemini-pro',
    'gemini-1.5-pro',
    'gemini-1.0-pro',
  ];

  Future<String?> sendMessage(String message) async {
    for (String modelName in _modelCandidates) {
      print(" Trying model: $modelName...");
      final result = await _tryModel(modelName, message);
      
      if (result != null) {
        print(" Success! Connected using: $modelName");
        return result;
      }
    }
    return "Error: Could not connect to any AI model. Please check your API Key permissions.";
  }

  Future<String?> _tryModel(String modelName, String message) async {
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent?key=$apiKey'
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
      print(" Failed to connect to $modelName: $e");
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
        print(" [IMAGE] Trying model: $modelName...");
        final result = await _tryImageModel(modelName, base64Image);
        
        if (result != null) {
          print(" [IMAGE] Success! Connected using: $modelName");
          return result;
        }
      }
      return null;
    } catch (e) {
      print(" [IMAGE] analyzeImage error: $e");
      return null;
    }
  }

  Future<String?> _tryImageModel(String modelName, String base64Image) async {
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent?key=$apiKey'
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

IMPORTANT: If the image is NOT a plant/crop (e.g., it's an animal, person, object, building, landscape without crops, etc.), return status as "Not a Plant" with confidence 0.0.

Respond with ONLY a JSON object (no markdown, no extra text):
{
  "cropName": "crop name here or 'Not a Plant'",
  "status": "Healthy" or "Pest Alert" or "Disease Detected" or "Not a Plant",
  "confidence": 0.92,
  "pestName": "pest/disease name or null",
  "description": "brief description of findings",
  "treatment": "recommended treatment or empty string if not applicable",
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
      print(" [IMAGE] Failed with $modelName: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> analyzePlotImage(String imagePath, String selectedSoil, bool waterAvailable) async {
    try {
      final imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        throw Exception('Image file not found: $imagePath');
      }

      final imageBytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(imageBytes);

      for (String modelName in _modelCandidates) {
        print(" [PLOT] Trying model: $modelName...");
        final result = await _tryPlotImageModel(modelName, base64Image, selectedSoil, waterAvailable);
        
        if (result != null) {
          print(" [PLOT] Success! Connected using: $modelName");
          return result;
        }
      }
      return null;
    } catch (e) {
      print(" [PLOT] analyzePlotImage error: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> _tryPlotImageModel(String modelName, String base64Image, String selectedSoil, bool waterAvailable) async {
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent?key=$apiKey'
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
                  "text": """You are an agriculture and land assessment expert.
Analyze this image to verify if it depicts an agricultural land, plot, field, or farm.
The user has provided the following details about this zone:
- Soil Type: $selectedSoil
- Water Availability: ${waterAvailable ? 'Irrigated (Yes)' : 'Rainfed (No)'}

IMPORTANT: If the image clearly shows people, indoors, close-ups of random objects, or dense city buildings with no agricultural land context, you MUST set isValidLand to false and provide an error message.
If it is a valid land/plot, provide exactly 4-6 recommended crops optimized for the visual land features and the provided user details.

Respond with ONLY a JSON object (no markdown, no extra text):
{
  "isValidLand": true or false,
  "message": "Reasoning why it's valid or invalid",
  "recommendations": ["Crop1", "Crop2"]
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
          final textResponse = data['candidates'][0]['content']['parts'][0]['text'] as String;
          // Clean up potential markdown formatting
          String cleanJson = textResponse.replaceAll('```json', '').replaceAll('```', '').trim();
          return jsonDecode(cleanJson) as Map<String, dynamic>;
        }
      }
      return null;
    } catch (e) {
      print(" [PLOT] Failed with $modelName: $e");
      return null;
    }
  }

  Future<String?> sendMessageWithHistory(List<Map<String, String>> history) async {
    for (String modelName in _modelCandidates) {
      print(" Trying model with history: $modelName...");
      final result = await _tryModelWithHistory(modelName, history);
      
      if (result != null) {
         print(" Success! Connected using: $modelName");
         return result;
      }
    }
    return "Error: Could not connect to any AI model for chat history.";
  }

  Future<String?> _tryModelWithHistory(String modelName, List<Map<String, String>> history) async {
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent?key=$apiKey'
    );

    // Map roles to Gemini roles
    final contents = <Map<String, dynamic>>[];
    for (int i = 0; i < history.length; i++) {
      final msg = history[i];
      var role = msg['role'] == 'ai' ? 'model' : 'user';
      var text = msg['text'] ?? '';
      
      if (i == history.length - 1 && role == 'user') {
        text = '''
[System Prompt: You are 'Smart Kisan', a practical agriculture expert. Follow these rules strictly:
1. Use clear BULLET POINTS.
2. Use **BOLD** for important names of medicines or techniques.
3. Keep the answer very SHORT (maximum 100-150 words).
4. Give direct advice, no long introductions.]

User Question: $text
''';
      }
      
      contents.add({
        "role": role,
        "parts": [{"text": text}]
      });
    }

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"contents": contents}),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
           return data['candidates'][0]['content']['parts'][0]['text'];
        }
      }
      return null;
    } catch (e) {
      print(" Failed to connect to $modelName: $e");
      return null;
    }
  }
}