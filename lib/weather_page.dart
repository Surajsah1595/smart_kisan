import 'package:flutter/material.dart';
import 'weather_service.dart'; // Imports the API logic we wrote earlier
import 'localization_service.dart';

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  // Service to handle API calls
  final WeatherService _weatherService = WeatherService();
  
  // UI State Variables
  bool _isLoading = true; // Shows spinner while fetching data
  String _errorMessage = ''; // Stores error text if API fails

  // Default location text before GPS loads
  String _selectedLocation = 'Locating...';
  
  // List of locations for the Dropdown
  // NOTE: These are specific locations relevant to the project context (Nepal)
  final List<String> _locations = [
    'Kathmandu, Nepal',
    'Lalitpur, Nepal',
    'Bhaktapur, Nepal',
    'Pokhara, Nepal',
    'Bharatpur, Nepal',
    'Biratnagar, Nepal',
    'Dhangadhi, Nepal',
    'Janakpur, Nepal',
    'Matihani, Nepal',
    'Jaleshwar, Nepal',
    'Siraha, Nepal',
    'Lahan, Nepal',
  ];

  // Stores the Real Weather Data fetched from API
  Map<String, dynamic> _currentWeather = {
    'temp': 0,
    'feelsLike': 0,
    'condition': 'Loading...',
    'humidity': 0,
    'wind': 0,
    'visibility': 0,
  };

  // --- DYNAMIC DATA ---
  // These are generated locally based on the temperature/condition
  List<Map<String, dynamic>> _adviceData = [];
  Map<String, dynamic>? _activeAlert; // Can be null if weather is good

  // --- STATIC PLACEHOLDERS ---
  // The Free OpenWeatherMap API key only provides "Current Weather".
  // To get 7-Day Forecasts, a paid subscription is required.
  // These placeholders demonstrate UI layout for future upgrades.
  final List<Map<String, dynamic>> _hourlyData = [
    {'time': 'Now', 'temp': 18, 'chance': 20},
    {'time': '+1h', 'temp': 19, 'chance': 15},
    {'time': '+2h', 'temp': 20, 'chance': 10},
    {'time': '+3h', 'temp': 21, 'chance': 15},
    {'time': '+4h', 'temp': 22, 'chance': 30},
    {'time': '+5h', 'temp': 21, 'chance': 60},
  ];

  final List<Map<String, dynamic>> _weeklyData = [
    {'day': 'Today', 'date': 'Now', 'condition': 'Partly Cloudy', 'high': 30, 'low': 24, 'chance': 30},
    {'day': 'Tomorrow', 'date': '--', 'condition': 'Rain', 'high': 28, 'low': 23, 'chance': 70},
    {'day': 'Wednesday', 'date': '--', 'condition': 'Rain', 'high': 27, 'low': 22, 'chance': 65},
    {'day': 'Thursday', 'date': '--', 'condition': 'Cloudy', 'high': 29, 'low': 23, 'chance': 40},
    {'day': 'Friday', 'date': '--', 'condition': 'Sunny', 'high': 31, 'low': 24, 'chance': 10},
    {'day': 'Saturday', 'date': '--', 'condition': 'Sunny', 'high': 32, 'low': 25, 'chance': 5},
    {'day': 'Sunday', 'date': '--', 'condition': 'Partly Cloudy', 'high': 30, 'low': 24, 'chance': 20},
  ];

  /// Purpose: Initializes the widget state and triggers the initial data fetch.
  /// Inputs: None.
  /// Outputs: Initiates the asynchronous [_fetchWeatherByGPS] workflow.
  @override
  void initState() {
    super.initState();
    // 1. Automatically fetch weather via GPS immediately when the screen opens.
    _fetchWeatherByGPS();
  }

  /// Purpose: Automatically requests and resolves weather data using the device's hardware GPS coordinates.
  /// Inputs: None (reads from device).
  /// Outputs: Updates local component state with fetched data or triggers an error handler.
  Future<void> _fetchWeatherByGPS() async {
    // 1. Reset UI state to show loading spinners and clear old errors.
    setState(() { _isLoading = true; _errorMessage = ''; });
    try {
      // 2. Await the response from the abstracted WeatherService layer.
      final data = await _weatherService.getCurrentWeather();
      // 3. Process the raw JSON payload if successful.
      _updateUI(data);
    } catch (e) {
      // 4. Catch and process failures (e.g., GPS denied, network timeout).
      _handleError(e);
    }
  }

  /// Purpose: Fetches weather data for a hardcoded, user-selected city.
  /// Inputs: [cityName] - The name of the target city.
  /// Outputs: Updates UI state with localized weather data.
  Future<void> _fetchWeatherByCity(String cityName) async {
    // 1. Update UI state: toggle loader and instantly display the targeted city name.
    setState(() { 
      _isLoading = true; 
      _errorMessage = ''; 
      _selectedLocation = cityName; 
    });
    try {
      // 2. Delegate the network request to the WeatherService.
      final data = await _weatherService.getWeatherByCity(cityName);
      // 3. Process the incoming JSON payload.
      _updateUI(data);
    } catch (e) {
      _handleError(e);
    }
  }

  /// Purpose: Parses the OpenWeatherMap JSON payload and translates it into UI-friendly state variables.
  /// Inputs: [data] - The raw JSON map from the API.
  /// Outputs: Mutates the [_currentWeather], [_adviceData], and [_activeAlert] variables, and triggers a UI rebuild.
  void _updateUI(Map<String, dynamic> data) {
    setState(() {
      // 1. If the request was made via GPS, extract the resolved city name from the API response.
      if (_selectedLocation == 'Locating...') {
        _selectedLocation = data['name'];
      }

      // 2. Safely cast incoming numeric values. The API may return Ints or Doubles; `num` handles both gracefully.
      double temp = (data['main']['temp'] as num).toDouble();
      String condition = data['weather'][0]['main'].toString();
      
      // 3. Convert wind speed from meters/second (API default) to kilometers/hour (User preference).
      double windSpeedKmh = (data['wind']['speed'] as num).toDouble() * 3.6;
      int humidity = data['main']['humidity'];

      // 4. Construct the sanitized weather object used by the presentation layer.
      _currentWeather = {
        'temp': temp.round(),
        'feelsLike': (data['main']['feels_like'] as num).round(),
        'condition': condition,
        'humidity': humidity,
        'wind': windSpeedKmh.round(),
        // 5. Convert visibility from meters to kilometers.
        'visibility': (data['visibility'] / 1000).round(),
      };

      // 6. Execute local logic algorithms to generate agronomic advice and alerts based on the raw metrics.
      _adviceData = _generateSmartAdvice(temp, condition, windSpeedKmh, humidity);
      _activeAlert = _generateSmartAlert(condition, windSpeedKmh);

      // 7. Hide the loading spinner.
      _isLoading = false;
    });
  }

  /// Purpose: Generates a list of actionable agricultural advice based on localized environmental thresholds.
  /// Inputs: [temp], [condition], [wind], [humidity].
  /// Outputs: A List of Maps containing title, description, color, and icon for UI rendering.
  List<Map<String, dynamic>> _generateSmartAdvice(double temp, String condition, double wind, int humidity) {
    // 1. Initialize an empty list to aggregate multiple advice cards if conditions overlap.
    List<Map<String, dynamic>> list = [];
    String condLower = condition.toLowerCase();

    // 2. Precipitation Logic: Warn against chemical applications that could wash away.
    if (condLower.contains('rain') || condLower.contains('drizzle')) {
      list.add({
        'title': 'Rain Detected',
        'desc': 'Avoid applying fertilizers or pesticides to prevent runoff.',
        'color': const Color(0xFFDBEAFE),
        'icon': Icons.water_drop
      });
    } else {
      // 3. Heat Stress Logic: If it's not raining, check if irrigation is urgently required.
      if (temp > 28) {
         list.add({
          'title': 'Irrigation Needed',
          'desc': 'High temperatures detected. Water crops to prevent heat stress.',
          'color': const Color(0xFFDCFCE7),
          'icon': Icons.water_drop
        });
      }
    }

    // 4. Wind Drift Logic: High winds make spray applications dangerous and ineffective.
    if (wind > 15) {
      list.add({
        'title': 'High Winds (${wind.round()} km/h)',
        'desc': 'Avoid spraying pesticides as drift may occur.',
        'color': const Color(0xFFFEF9C2),
        'icon': Icons.air
      });
    }

    // 5. Ideal Conditions Logic: Greenlight standard farm operations.
    if (condLower.contains('clear') || condLower.contains('sun')) {
      list.add({
        'title': 'Good Field Conditions',
        'desc': 'Ideal weather for sowing, harvesting, or equipment maintenance.',
        'color': const Color(0xFFFFF7ED),
        'icon': Icons.wb_sunny
      });
    } else if (condLower.contains('thunder') || condLower.contains('storm')) {
      // 6. Lightning Hazard Logic: Prioritize farmer safety over crop management.
       list.add({
        'title': 'Safety Warning',
        'desc': 'Lightning risk. Stay away from open fields and metal equipment.',
        'color': const Color(0xFFFEE2E2),
        'icon': Icons.flash_on
      });
    }

    // 7. Cold Stress Logic: Warn about potential frost damage.
    if (temp < 10) {
      list.add({
        'title': 'Cold Stress Risk',
        'desc': 'Temperatures are low. Protect sensitive seedlings from frost.',
        'color': const Color(0xFFEFF6FF),
        'icon': Icons.ac_unit
      });
    }

    // 8. Fallback Logic: Ensure the UI never displays an empty section if no rules match.
    if (list.isEmpty) {
      list.add({
        'title': 'Stable Conditions',
        'desc': 'Weather is normal. Continue routine farm operations.',
        'color': const Color(0xFFF3F4F6),
        'icon': Icons.check_circle
      });
    }

    return list;
  }

  /// Purpose: Evaluates weather conditions to surface high-priority danger alerts.
  /// Inputs: [condition], [wind].
  /// Outputs: A Map containing alert details, or null if no extreme weather is detected.
  Map<String, dynamic>? _generateSmartAlert(String condition, double wind) {
    String condLower = condition.toLowerCase();
    
    // 1. Prioritize immediate threats to human life (Lightning).
    if (condLower.contains('thunder') || condLower.contains('storm')) {
      return {
        'title': 'Storm Alert',
        'desc': 'Thunderstorm activity detected. Halt all field work immediately.'
      };
    }
    // 2. Evaluate infrastructure threats (Flooding).
    if (condLower.contains('rain') && condLower.contains('heavy')) {
       return {
        'title': 'Heavy Rain Alert',
        'desc': 'Heavy precipitation expected. Ensure drainage systems are clear.'
      };
    }
    // 3. Evaluate property/livestock threats (Gale-force winds).
    if (wind > 30) {
       return {
        'title': 'Gale Warning',
        'desc': 'Damaging winds detected. Secure loose structures and livestock.'
      };
    }
    // 4. Return null to signal the UI to hide the alert banner entirely.
    return null;
  }

  /// Purpose: Handles API failures, updating the UI to reflect the disconnected state.
  /// Inputs: The thrown Exception [e].
  /// Outputs: Mutates state to stop loading and display an error banner.
  void _handleError(dynamic e) {
    setState(() {
      // 1. Fallback to a generic error message indicating network or GPS failure.
      _errorMessage = "Could not load weather. Check internet/GPS.";
      _isLoading = false;
      _currentWeather['condition'] = 'Error';
    });
    // 2. Log the exact stack trace/error for debugging.
    print(e);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Custom AppBar with Gradient
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight * 2), 
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF9800), Color(0xFFF57C00)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            children: [
              SizedBox(height: MediaQuery.of(context).padding.top),
              Expanded(
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(LocalizationService.translate('Weather Forecast'),
                          style: TextStyle(color: Theme.of(context).cardColor, fontSize: 25, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      onPressed: _fetchWeatherByGPS,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      
      // Main Body handles Loading and Scroll
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Colors.orange))
        : SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Error Display
                if (_errorMessage.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(bottom: 10),
                    color: Colors.red[100],
                    child: Text(_errorMessage, style: const TextStyle(color: Colors.red)),
                  ),

                // 1. Location
                _buildLocationRow(),
                const SizedBox(height: 16),
                
                // 2. Current Weather (Big Card)
                _buildCurrentWeather(),
                const SizedBox(height: 24),
                
                // 3. Conditions (Wind, Humid, etc)
                _buildConditionsRow(),
                const SizedBox(height: 24),
                
                // 4. Hourly Forecast (Static for demo)
                _buildHourlySection(),
                const SizedBox(height: 24),
                
                // 5. Weekly Forecast (Static for demo)
                _buildWeeklySection(),
                const SizedBox(height: 24),
                
                // 6. Farming Advice (Dynamically Generated)
                _buildAdviceSection(),
                const SizedBox(height: 24),
                
                // 7. Alert Card (Only shows if alert exists)
                if (_activeAlert != null)
                  _buildAlertCard(),
                
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
    );
  }

  // --- WIDGET BUILDERS (Keep UI clean) ---

  /// Purpose: Renders the top bar displaying the currently selected city and a dropdown to change it.
  /// Inputs: None (reads from [_selectedLocation]).
  /// Outputs: A Container widget with a location icon and dropdown button.
  Widget _buildLocationRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2, offset: const Offset(0, 1))],
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _selectedLocation, 
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_drop_down), 
            onPressed: _showLocationDialog,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  /// Purpose: Renders the primary weather card showing the large temperature text and condition icon.
  /// Inputs: None (reads from [_currentWeather] state).
  /// Outputs: A large stylized Container widget with gradient background.
  Widget _buildCurrentWeather() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF9800), Color(0xFFF57C00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.white70),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _selectedLocation,
                  style: TextStyle(color: Theme.of(context).cardColor, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(LocalizationService.translate('Today'),
                    style: TextStyle(color: Theme.of(context).cardColor, fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _currentWeather['condition'].toString(),
                    style: TextStyle(color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7), fontSize: 16),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getWeatherIcon(_currentWeather['condition'].toString()),
                        color: Theme.of(context).cardColor,
                        size: 40,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_currentWeather['temp']}°C',
                        style: TextStyle(color: Theme.of(context).cardColor, fontSize: 36, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Feels like ${_currentWeather['feelsLike']}°C',
                    style: TextStyle(color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7), fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Purpose: Renders a horizontal scrollable row of secondary weather metrics.
  /// Inputs: None.
  /// Outputs: A Column containing multiple [_conditionCard] widgets for wind, humidity, and visibility.
  Widget _buildConditionsRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(LocalizationService.translate('Current Conditions'),
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _conditionCard(Icons.water_drop, 'Humidity', '${_currentWeather['humidity']}%'),
              const SizedBox(width: 12),
              _conditionCard(Icons.air, 'Wind', '${_currentWeather['wind']} km/h'),
              const SizedBox(width: 12),
              _conditionCard(Icons.visibility, 'Visibility', '${_currentWeather['visibility']} km'),
            ],
          ),
        ),
      ],
    );
  }

  /// Purpose: Helper widget to render a single, uniform card for a secondary weather metric.
  /// Inputs: [icon] (IconData), [title] (String), [value] (String).
  /// Outputs: A stylized Container widget.
  Widget _conditionCard(IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2, offset: const Offset(0, 1))],
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.orange, size: 24),
          const SizedBox(height: 8),
          Text(LocalizationService.translate(title), style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodyMedium?.color)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color)),
        ],
      ),
    );
  }

  /// Purpose: Renders a horizontal timeline of hourly weather forecasts.
  /// Inputs: None (uses static placeholder [_hourlyData]).
  /// Outputs: A scrollable ListView widget.
  Widget _buildHourlySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          Text(LocalizationService.translate('Hourly Forecast'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color)),
        const SizedBox(height: 12),
        SizedBox(
          height: 140, 
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _hourlyData.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final data = _hourlyData[index];
              return Container(
                width: 85,
                margin: EdgeInsets.only(
                  left: index == 0 ? 0 : 8,
                  right: index == _hourlyData.length - 1 ? 8 : 0,
                ),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2, offset: const Offset(0, 1))],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(data['time'] as String, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Theme.of(context).textTheme.bodyLarge?.color), textAlign: TextAlign.center),
                    Icon(_getWeatherIcon('Partly Cloudy'), color: Colors.orange, size: 28),
                    Text('${data['temp']}°', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.water_drop, color: Color(0xFF155CFB), size: 14),
                          const SizedBox(width: 4),
                          Text('${data['chance']}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF155CFB))),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Purpose: Renders a vertical list of upcoming weather forecasts for the week.
  /// Inputs: None (uses static placeholder [_weeklyData]).
  /// Outputs: A Column widget mapping daily data to list items.
  Widget _buildWeeklySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(LocalizationService.translate('7-Day Forecast'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color)),
        const SizedBox(height: 12),
        Column(
          children: _weeklyData.map((day) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2, offset: const Offset(0, 1))],
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(day['day'] as String, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Theme.of(context).textTheme.bodyLarge?.color), overflow: TextOverflow.ellipsis),
                        Text(day['date'] as String, style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodyMedium?.color)),
                      ],
                    ),
                  ),
                  Icon(_getWeatherIcon(day['condition'] as String), color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text((day['condition'] as String).split(' ').first, style: const TextStyle(fontSize: 14, color: Color(0xFF354152)), overflow: TextOverflow.ellipsis),
                        Row(
                          children: [
                            const Icon(Icons.water_drop, color: Color(0xFF155CFB), size: 12),
                            const SizedBox(width: 2),
                            Text('${day['chance']}%', style: const TextStyle(fontSize: 12, color: Color(0xFF155CFB))),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${day['high']}°', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color)),
                      Text('${day['low']}°', style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium?.color)),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Purpose: Renders the dynamic agricultural advice cards based on current weather thresholds.
  /// Inputs: None (reads from [_adviceData] state).
  /// Outputs: A Column containing mapped advice Containers, or a fallback empty state.
  Widget _buildAdviceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LocalizationService.translate('Farming Advice'),
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color),
        ),
        const SizedBox(height: 12),
        if (_adviceData.isEmpty)
           Padding(
             padding: const EdgeInsets.all(8.0),
             child: Text(LocalizationService.translate('Conditions are stable. No specific warnings.'), style: const TextStyle(color: Colors.grey)),
           ),
        Column(
          children: _adviceData.map((advice) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2, offset: const Offset(0, 1))],
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(color: advice['color'] as Color, borderRadius: BorderRadius.circular(8)),
                    child: Icon(advice['icon'] as IconData, color: Colors.black.withOpacity(0.6), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(advice['title'] as String, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Theme.of(context).textTheme.bodyLarge?.color)),
                        const SizedBox(height: 4),
                        Text(advice['desc'] as String, style: const TextStyle(fontSize: 12, color: Color(0xFF354152)), maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Purpose: Renders a high-visibility warning banner if severe weather is detected.
  /// Inputs: None (reads from [_activeAlert] state).
  /// Outputs: A stylized warning Container widget.
  Widget _buildAlertCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFDFBE8), Color(0xFFFEF9C1)]),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFDF20), width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFF723D0A), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_activeAlert!['title'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF723D0A))),
                const SizedBox(height: 4),
                Text(_activeAlert!['desc'], style: const TextStyle(fontSize: 12, color: Color(0xFF884A00)), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Purpose: Renders a modal dialog allowing the user to select from a predefined list of Nepali cities or revert to GPS.
  /// Inputs: None.
  /// Outputs: Shows an AlertDialog and triggers a fetch operation on selection.
  void _showLocationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(LocalizationService.translate('Select Location')),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _locations.length,
            itemBuilder: (context, index) => ListTile(
              title: Text(_locations[index]),
              leading: const Icon(Icons.location_city, color: Colors.orange),
              onTap: () {
                // 1. Trigger the targeted city fetch.
                _fetchWeatherByCity(_locations[index]); 
                // 2. Dismiss the dialog.
                Navigator.pop(context);
              },
            ),
          ),
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.my_location),
            label: Text(LocalizationService.translate('Use Current GPS')),
            onPressed: () {
              // 3. Revert to hardware GPS.
              _fetchWeatherByGPS();
              Navigator.pop(context);
            },
          )
        ],
      ),
    );
  }

  /// Purpose: Maps raw weather condition strings to corresponding Material Icons.
  /// Inputs: [condition] - The weather description string from OpenWeatherMap.
  /// Outputs: A single [IconData] object.
  IconData _getWeatherIcon(String condition) {
    condition = condition.toLowerCase();
    // 1. Fallthrough matching logic.
    if (condition.contains('cloud')) return Icons.cloud;
    if (condition.contains('rain')) return Icons.umbrella;
    if (condition.contains('clear') || condition.contains('sun')) return Icons.wb_sunny;
    if (condition.contains('snow')) return Icons.ac_unit;
    if (condition.contains('thunder')) return Icons.flash_on;
    // 2. Default fallback icon.
    return Icons.wb_sunny;
  }
}