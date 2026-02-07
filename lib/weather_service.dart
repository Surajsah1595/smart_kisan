import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'notification_service.dart';

class WeatherService {
  final NotificationService _notificationService = NotificationService();
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
          return await getWeatherByCity('Kathmandu');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return await getWeatherByCity('Kathmandu');
      }

      // 2. Get Current Position (GPS) with timeout
      Position position;
      try {
        position = await Geolocator.getCurrentPosition(
          // ignore: deprecated_member_use
          desiredAccuracy: LocationAccuracy.high,
        ).timeout(
          const Duration(seconds: 8),
          onTimeout: () => throw TimeoutException('Location fetch timeout'),
        );
      } catch (e) {
        // GPS failed, use fallback city
        return await getWeatherByCity('Kathmandu');
      }

      // 3. Call OpenWeatherMap API with timeout
      final response = await http.get(Uri.parse(
          '$baseUrl?lat=${position.latitude}&lon=${position.longitude}&appid=$apiKey&units=metric')).timeout(
        const Duration(seconds: 8),
        onTimeout: () => throw TimeoutException('Weather API timeout'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load weather data: ${response.statusCode}');
      }
    } catch (e) {
      // If GPS fails, return Kathmandu as fallback
      try {
        return await getWeatherByCity('Kathmandu');
      } catch (e) {
        // Return empty map if all fails - recommendations will handle gracefully
        return {};
      }
    }
  }

  // 2. NEW: Get by City Name
  Future<Map<String, dynamic>> getWeatherByCity(String cityName) async {
    try {
      // Remove " Nepal" or extra spaces if present for better API matching
      final cleanName = cityName.replaceAll(', Nepal', '').trim();

      final response = await http.get(Uri.parse(
          '$baseUrl?q=$cleanName&appid=$apiKey&units=metric')).timeout(
        const Duration(seconds: 8),
        onTimeout: () => throw TimeoutException('Weather API timeout'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load weather for $cityName: ${response.statusCode}');
      }
    } catch (e) {
      // Return empty map on failure
      return {};
    }
  }

  // 3. Check weather and send notifications
  Future<void> checkWeatherAndNotify() async {
    try {
      final weatherData = await getCurrentWeather();
      if (weatherData.isEmpty) return;

      final temperature = (weatherData['main']['temp'] as num?)?.toDouble() ?? 0;
      final humidity = (weatherData['main']['humidity'] as num?)?.toInt() ?? 0;
      final condition = weatherData['weather']?[0]?['main'] as String? ?? '';
      final cityName = weatherData['name'] as String? ?? 'Your location';

      print('Weather Check: Temp=${temperature}°C, Humidity=${humidity}%, Condition=$condition');

      // Temperature alerts - LOWERED THRESHOLDS FOR TESTING
      if (temperature > 28) {
        print('Temperature alert triggered (${temperature}°C > 28°C)');
        await _notificationService.notifyHighTemperature(
          temperature: temperature,
          location: cityName,
        );
      } else if (temperature < 15) {
        print('❄️ Temperature alert triggered (${temperature}°C < 15°C)');
        await _notificationService.notifyLowTemperature(
          temperature: temperature,
          location: cityName,
        );
      }

      // Humidity alerts
      if (humidity > 70 || humidity < 50) {
        print('💧 Humidity alert triggered (${humidity}% > 70% or < 50%)');
        await _notificationService.notifyHumidityLevel(
          humidity: humidity.toDouble(),
          location: cityName,
        );
      } else {
        print('✓ Humidity OK (${humidity}% is between 50-70%)');
      }

      // Rain alerts
      if (condition.toLowerCase().contains('rain')) {
        print('🌧️ Rain alert triggered');
        await _notificationService.notifyRainAlert(
          rainType: condition,
          location: cityName,
        );
      }
    } catch (e) {
      print('❌ Error checking weather: $e');
    }
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => message;
}