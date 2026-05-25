class AppConfig {
  // 1. FLIPPED TO FALSE: This forces the app to use local USB bridge
  static const bool useTunnel = false;

  // The static local route (127.0.0.1 is required for ADB Reverse on physical device)
  static const String _localUrl = 'http://127.0.0.1:8000';
  
  // 2. FIXED: Pasted your clean, single secure HTTPS tunnel link here
  static const String _tunnelUrl = 'https://owycw-2400-1a00-4b63-2820-5ceb-687-4c5b-6e89.run.pinggy-free.link';

  /// Returns the base URL based on the useTunnel flag
  static String get baseUrl => useTunnel ? _tunnelUrl : _localUrl;

  /// Returns standard headers for API requests to bypass intermediate browser warning screens.
  static Map<String, String> get apiHeaders => {
        'Content-Type': 'application/json',
        'User-Agent': 'SmartKisanApp/1.0',
        'ngrok-skip-browser-warning': 'true', 
        'Bypass-Tunnel-Reminder': 'true', 
      };
}