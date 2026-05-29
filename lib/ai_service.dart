import 'dart:convert';
import 'dart:io';
import 'localization_service.dart';
import 'package:http/http.dart' as http;

/// [AiService] handles all communication with the Gemini AI API.
/// It provides methods for text-based chat, image-based crop disease analysis, 
/// and plot validation. It includes fallback logic to iterate through multiple
/// AI models to ensure high availability.
class AiService {
  // TODO: Refactor for production - Move API key to a secure environment variable or remote config.
  // Stores the API key required for authenticating with the Gemini API endpoint.
  static const String apiKey = '';

  // Defines a prioritized list of Gemini model versions to attempt connections with.
  // The app iterates through this list, using the first model that successfully responds.
  static const List<String> _modelCandidates = [
    'gemini-1.5-flash',
    'gemini-2.5-flash', 
    'gemini-pro',
    'gemini-1.5-pro',
    'gemini-1.0-pro',
  ];

  /// Purpose: Sends a single, stateless text message to the AI and returns the response.
  /// Inputs: [message] - A string representing the user's question or prompt.
  /// Outputs: A Future containing the AI's response string, or an error message if all models fail.
  Future<String?> sendMessage(String message) async {
    // Iterate through the predefined list of fallback models
    for (String modelName in _modelCandidates) {
      print(" Trying model: $modelName...");
      
      // Attempt to get a response from the current model in the loop
      final result = await _tryModel(modelName, message);
      
      // If the result is not null, the API call was successful
      if (result != null) {
        print(" Success! Connected using: $modelName");
        // Return the valid response and break out of the loop
        return result;
      }
    }
    // If the loop finishes without returning, all models failed
    return "Error: Could not connect to any AI model. Please check your API Key permissions.";
  }

  /// Purpose: Handles the actual HTTP POST request to a specific Gemini model for text generation.
  /// Inputs: [modelName] - The specific Gemini model ID to use. [message] - The user's prompt.
  /// Outputs: The parsed text response from the API, or null if the request fails.
  Future<String?> _tryModel(String modelName, String message) async {
    // Construct the full URL endpoint dynamically using the model name and API key
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent?key=$apiKey'
    );

    try {
      // Execute an asynchronous HTTP POST request to the constructed URL
      final response = await http.post(
        url,
        // Set standard headers indicating we are sending JSON data
        headers: {'Content-Type': 'application/json'},
        // Serialize the Dart map into a JSON string for the request body
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {
                  // Provide a rigid system prompt to enforce the persona and formatting constraints
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

      // Check if the HTTP response status code indicates success (200 OK)
      if (response.statusCode == 200) {
        // Deserialize the JSON string response back into a Dart Map
        final data = jsonDecode(response.body);
        
        // Safely traverse the Gemini JSON response structure to extract the text content
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
           return data['candidates'][0]['content']['parts'][0]['text'];
        }
      }
      // If the status code was not 200 or the JSON structure was missing data, return null
      return null; 
    } catch (e) {
      // Catch network exceptions or JSON parsing errors and log them
      print(" Failed to connect to $modelName: $e");
      // Return null so the outer function knows to try the next fallback model
      return null; 
    }
  }

  /// Purpose: Reads a local image file and initiates the AI analysis process for crop disease detection.
  /// Inputs: [imagePath] - The local file system path to the image to analyze.
  /// Outputs: The JSON-formatted string response from the AI, or null on failure.
  Future<String?> analyzeImage(String imagePath) async {
    try {
      // Create a Dart File object pointing to the provided path
      final imageFile = File(imagePath);
      
      // Verify the file actually exists on the disk before proceeding
      if (!await imageFile.exists()) {
        throw Exception('Image file not found: $imagePath');
      }

      // Read the raw binary data (bytes) of the image
      final imageBytes = await imageFile.readAsBytes();
      
      // Convert the raw bytes into a Base64 encoded string, which is required by the Gemini API for inline image data
      final base64Image = base64Encode(imageBytes);

      // Iterate through the fallback models for image processing
      for (String modelName in _modelCandidates) {
        print(" [IMAGE] Trying model: $modelName...");
        
        // Pass the model name and the Base64 image to the helper method
        final result = await _tryImageModel(modelName, base64Image);
        
        // If a valid result is returned, the operation was successful
        if (result != null) {
          print(" [IMAGE] Success! Connected using: $modelName");
          return result;
        }
      }
      // Return null if all models in the fallback loop fail
      return null;
    } catch (e) {
      // Log any file reading or processing errors
      print(" [IMAGE] analyzeImage error: $e");
      return null;
    }
  }

  /// Purpose: Handles the HTTP POST request to analyze an image for diseases using Gemini.
  /// Inputs: [modelName] - The specific Gemini model. [base64Image] - The encoded image data.
  /// Outputs: A strictly formatted JSON string from the AI containing the diagnosis, or null.
  Future<String?> _tryImageModel(String modelName, String base64Image) async {
    // Construct the endpoint URL for the generative model
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent?key=$apiKey'
    );

    try {
      // Send the HTTP POST request
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        // Construct a multipart JSON payload containing both text instructions and inline image data
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {
                  // Extremely rigid system prompt forcing the model to return ONLY a specific JSON structure, avoiding conversational filler
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
                  // Attach the base64 encoded image data directly in the payload
                  "inlineData": {
                    "mimeType": "image/jpeg",
                    "data": base64Image
                  }
                }
              ]
            }
          ]
        }),
      // Enforce a strict 30-second timeout to prevent the app from hanging indefinitely if the network is slow
      ).timeout(const Duration(seconds: 30));

      // Process the response if the server returns 200 OK
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Extract the AI's textual response (which should be the requested JSON string)
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          return data['candidates'][0]['content']['parts'][0]['text'];
        }
      }
      return null;
    } catch (e) {
      // Catch timeouts or parsing errors
      print(" [IMAGE] Failed with $modelName: $e");
      return null;
    }
  }

  /// Purpose: Orchestrates the analysis of a land plot image to generate crop recommendations.
  /// Inputs: [imagePath] - Path to image, [selectedSoil] - The user's soil type, [waterAvailable] - Irrigation status.
  /// Outputs: A parsed Dart Map containing validity boolean, message, and recommendations array.
  Future<Map<String, dynamic>?> analyzePlotImage(String imagePath, String selectedSoil, bool waterAvailable) async {
    try {
      // Read and validate the image file
      final imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        throw Exception('Image file not found: $imagePath');
      }

      // Convert image to Base64 for the API payload
      final imageBytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(imageBytes);

      // Iterate over fallback models
      for (String modelName in _modelCandidates) {
        print(" [PLOT] Trying model: $modelName...");
        
        // Pass context data (soil, water) along with the image
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

  /// Purpose: Handles the specific API request for plot analysis, parsing the returned JSON.
  /// Inputs: [modelName], [base64Image], [selectedSoil], [waterAvailable].
  /// Outputs: A deserialized Map containing the AI's structured response.
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
                  // Dynamically inject the user's soil and water parameters into the prompt using string interpolation
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
                  // Attach the image payload
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
          // Extract the raw string from the AI response
          final textResponse = data['candidates'][0]['content']['parts'][0]['text'] as String;
          
          // Safety logic: Clean up any accidental markdown formatting (like ```json ... ```) the AI might have included
          String cleanJson = textResponse.replaceAll('```json', '').replaceAll('```', '').trim();
          
          // Deserialize the cleaned string into a Dart Map and return it
          return jsonDecode(cleanJson) as Map<String, dynamic>;
        }
      }
      return null;
    } catch (e) {
      print(" [PLOT] Failed with $modelName: $e");
      return null;
    }
  }

  /// Purpose: Sends a text message to the AI while providing the entire chat history for context.
  /// Inputs: [history] - A list of message maps, each containing 'role' (user/ai) and 'text'.
  /// Outputs: The AI's contextual response string, or an error message.
  Future<String?> sendMessageWithHistory(List<Map<String, String>> history) async {
    // Iterate through fallback models
    for (String modelName in _modelCandidates) {
      print(" Trying model with history: $modelName...");
      
      // Attempt the request passing the full history array
      final result = await _tryModelWithHistory(modelName, history);
      
      if (result != null) {
         print(" Success! Connected using: $modelName");
         return result;
      }
    }
    return "Error: Could not connect to any AI model for chat history.";
  }

  /// Purpose: Constructs a complex payload containing multiple previous messages to maintain conversational state.
  /// Inputs: [modelName], [history].
  /// Outputs: The raw text response from the AI.
  Future<String?> _tryModelWithHistory(String modelName, List<Map<String, String>> history) async {
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent?key=$apiKey'
    );

    // Initialize an empty list to hold the formatted conversation blocks
    final contents = <Map<String, dynamic>>[];
    
    // Loop through the internal app history to map it to Gemini's expected format
    for (int i = 0; i < history.length; i++) {
      final msg = history[i];
      
      // Gemini expects the AI role to be labeled as 'model', but the app internally uses 'ai'. Map this correctly.
      var role = msg['role'] == 'ai' ? 'model' : 'user';
      var text = msg['text'] ?? '';
      
      // If this is the very last message in the history (the newest user prompt), append the system instructions
      // This ensures the AI continues to adhere to the strict formatting rules for its newest reply.
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
      
      // Add the formatted message block to the payload list
      contents.add({
        "role": role,
        "parts": [{"text": text}]
      });
    }

    try {
      // Send the HTTP request containing the entire 'contents' array representing the conversation state
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"contents": contents}),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Extract and return the newly generated text block
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