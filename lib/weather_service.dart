import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class WeatherService {
  // Your provided API Key
  static const String apiKey = '4f7836b6527f8ad5480bb403d7e4795c'; 
  static const String baseUrl = 'https://api.openweathermap.org/data/2.5/weather';

  // 1. Get by GPS
  Future<Map<String, dynamic>> getCurrentWeather() async {
    try {
      // 1. Check Permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // If denied, fallback to a default city
          return getWeatherByCity('Kathmandu'); 
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return getWeatherByCity('Kathmandu');
      }

      // 2. Get Current Position (GPS)
      Position position = await Geolocator.getCurrentPosition(
        // ignore: deprecated_member_use
        desiredAccuracy: LocationAccuracy.high,
      );

      // 3. Call OpenWeatherMap API
      final response = await http.get(Uri.parse(
          '$baseUrl?lat=${position.latitude}&lon=${position.longitude}&appid=$apiKey&units=metric'));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load weather data');
      }
    } catch (e) {
      // If GPS fails, return Kathmandu as fallback
      return getWeatherByCity('Kathmandu');
    }
  }

  // 2. NEW: Get by City Name
  Future<Map<String, dynamic>> getWeatherByCity(String cityName) async {
    // Remove " Nepal" or extra spaces if present for better API matching
    final cleanName = cityName.replaceAll(', Nepal', '').trim();
    
    final response = await http.get(Uri.parse(
        '$baseUrl?q=$cleanName&appid=$apiKey&units=metric'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load weather for $cityName');
    }
  }
}