/// [AppConfig] manages global configuration settings for the Smart Kisan application,
/// particularly network routing configurations for the ML Backend (local USB bridge vs. secure tunnel).
class AppConfig {
  // TODO: Refactor for production - Use environment variables (.env) instead of hardcoded URLs.
  // Flag to toggle between routing API traffic to a local USB bridge or a remote HTTPS tunnel.
  static const bool useTunnel = false;

  // The static local route. 
  // 127.0.0.1 is specifically used here (instead of localhost) to ensure ADB Reverse port forwarding 
  // functions correctly when testing on a physical Android device plugged in via USB.
  static const String _localUrl = 'http://127.0.0.1:8000';
  
  // The secure HTTPS tunnel link. Used when the Python backend is running on a machine 
  // not physically connected to the mobile device (e.g., via Pinggy, Ngrok, or a VPS).
  static const String _tunnelUrl = 'https://owycw-2400-1a00-4b63-2820-5ceb-687-4c5b-6e89.run.pinggy-free.link';

  /// Purpose: Dynamically resolves the base URL based on the current configuration state.
  /// Outputs: The active URL string.
  static String get baseUrl => useTunnel ? _tunnelUrl : _localUrl;

  /// Purpose: Provides standardized HTTP headers required for interacting with tunneled APIs.
  /// Outputs: A Map of header key-value pairs.
  static Map<String, String> get apiHeaders => {
        // Standard JSON payload declaration
        'Content-Type': 'application/json',
        // Identifies the client to the server
        'User-Agent': 'SmartKisanApp/1.0',
        // Specifically bypasses intermediate HTML warning screens often injected by free tunneling services
        'ngrok-skip-browser-warning': 'true', 
        'Bypass-Tunnel-Reminder': 'true', 
      };
}