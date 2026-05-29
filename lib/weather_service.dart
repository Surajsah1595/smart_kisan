import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'notification_service.dart';
import 'localization_service.dart';

class WeatherService {
  final NotificationService _notificationService = NotificationService();
    static const String apiKey = '4f7836b6527f8ad5480bb403d7e4795c'; 
  static const String baseUrl = 'https://api.openweathermap.org/data/2.5/weather';

  /// Purpose: Fetches live weather data based on device GPS coordinates, with fallback to a default city.
  /// Inputs: None.
  /// Outputs: A JSON Map from the OpenWeatherMap API, or an empty map on total failure.
  Future<Map<String, dynamic>> getCurrentWeather() async {
    try {
      // 1. Check Permissions: Verify OS-level location access.
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        // 2. Request permission if not currently granted.
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // 3. Fallback: If denied, route to a static location (Kathmandu) to ensure app continuity.
          return await getWeatherByCity('Kathmandu');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        // 4. Fallback: Handle permanent denial similarly.
        return await getWeatherByCity('Kathmandu');
      }

      // 5. Get Current Position: Fetch GPS coordinates with a strict 8-second timeout to prevent UI hangs.
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
        // 6. GPS Hardware Failure: Use fallback city.
        return await getWeatherByCity('Kathmandu');
      }

      // 7. API Call: Request weather data via OpenWeatherMap using the retrieved coordinates.
      final response = await http.get(Uri.parse(
          '$baseUrl?lat=${position.latitude}&lon=${position.longitude}&appid=$apiKey&units=metric')).timeout(
        const Duration(seconds: 8),
        onTimeout: () => throw TimeoutException('Weather API timeout'),
      );

      if (response.statusCode == 200) {
        // 8. Success: Decode and return the JSON payload.
        return jsonDecode(response.body);
      } else {
        // 9. API Error: Throw to trigger the outer catch block.
        throw Exception('Failed to load weather data: ${response.statusCode}');
      }
    } catch (e) {
      // 10. Outer Catch: If anything in the GPS -> API chain fails, attempt the static fallback.
      try {
        return await getWeatherByCity('Kathmandu');
      } catch (e) {
        // 11. Total Failure: Return an empty map so dependent services can handle the absence gracefully.
        return {};
      }
    }
  }

  /// Purpose: Fetches live weather data using a specific city name string.
  /// Inputs: cityName (String).
  /// Outputs: A JSON Map from the OpenWeatherMap API, or an empty map on failure.
  Future<Map<String, dynamic>> getWeatherByCity(String cityName) async {
    try {
      // 1. Sanitize Input: Remove country suffixes that confuse the OpenWeatherMap search algorithm.
      final cleanName = cityName.replaceAll(', Nepal', '').trim();

      // 2. API Call: Request weather data via HTTP GET, enforcing a strict timeout.
      final response = await http.get(Uri.parse(
          '$baseUrl?q=$cleanName&appid=$apiKey&units=metric')).timeout(
        const Duration(seconds: 8),
        onTimeout: () => throw TimeoutException('Weather API timeout'),
      );

      if (response.statusCode == 200) {
        // 3. Success: Decode and return payload.
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load weather for $cityName: ${response.statusCode}');
      }
    } catch (e) {
      // 4. Failure: Return an empty map to prevent downstream parsing crashes.
      return {};
    }
  }

  /// Purpose: Evaluates current weather against agronomic thresholds and dispatches push notifications.
  /// Inputs: None (Fetches context internally).
  /// Outputs: Triggers system notifications via NotificationService.
  Future<void> checkWeatherAndNotify() async {
    try {
      // 1. Fetch current environmental context.
      final weatherData = await getCurrentWeather();
      if (weatherData.isEmpty) return; // Exit if context is unavailable.

      // 2. Extract key metrics, providing safe defaults for nulls.
      final temperature = (weatherData['main']['temp'] as num?)?.toDouble() ?? 0;
      final humidity = (weatherData['main']['humidity'] as num?)?.toInt() ?? 0;
      final condition = weatherData['weather']?[0]?['main'] as String? ?? '';
      final cityName = weatherData['name'] as String? ?? 'Your location';

      print('Weather Check: Temp=${temperature}°C, Humidity=${humidity}%, Condition=$condition');

      // 3. Temperature Threshold Checks. (Thresholds currently set aggressively for testing purposes).
      if (temperature > 28) {
        print('Temperature alert triggered (${temperature}°C > 28°C)');
        await _notificationService.notifyHighTemperature(
          temperature: temperature,
          location: cityName,
        );
      } else if (temperature < 15) {
        print(' Temperature alert triggered (${temperature}°C < 15°C)');
        await _notificationService.notifyLowTemperature(
          temperature: temperature,
          location: cityName,
        );
      }

      // 4. Humidity Threshold Checks (Optimal range roughly 50-70% for many crops).
      if (humidity > 70 || humidity < 50) {
        print(' Humidity alert triggered (${humidity}% > 70% or < 50%)');
        await _notificationService.notifyHumidityLevel(
          humidity: humidity.toDouble(),
          location: cityName,
        );
      } else {
        print(' Humidity OK (${humidity}% is between 50-70%)');
      }

      // 5. Precipitation Checks.
      if (condition.toLowerCase().contains('rain')) {
        print(' Rain alert triggered');
        await _notificationService.notifyRainAlert(
          rainType: condition,
          location: cityName,
        );
      }
    } catch (e) {
      // 6. Fail silently to prevent background task crashes.
      print(' Error checking weather: $e');
    }
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => message;
}