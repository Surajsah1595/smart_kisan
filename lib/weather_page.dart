import 'package:flutter/material.dart';
import 'weather_service.dart'; // Imports the API logic we wrote earlier

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

  @override
  void initState() {
    super.initState();
    // Automatically fetch weather via GPS when screen opens
    _fetchWeatherByGPS();
  }

  /// 1. Fetch Weather using User's GPS Location
  Future<void> _fetchWeatherByGPS() async {
    setState(() { _isLoading = true; _errorMessage = ''; });
    try {
      final data = await _weatherService.getCurrentWeather();
      _updateUI(data);
    } catch (e) {
      _handleError(e);
    }
  }

  /// 2. Fetch Weather using a specific City Name (from Dropdown)
  Future<void> _fetchWeatherByCity(String cityName) async {
    setState(() { 
      _isLoading = true; 
      _errorMessage = ''; 
      _selectedLocation = cityName; // Update display text immediately
    });
    try {
      final data = await _weatherService.getWeatherByCity(cityName);
      _updateUI(data);
    } catch (e) {
      _handleError(e);
    }
  }

  /// 3. Process the API Response and Update UI
  void _updateUI(Map<String, dynamic> data) {
    setState(() {
      // If we used GPS, the API gives us the exact location name
      if (_selectedLocation == 'Locating...') {
        _selectedLocation = data['name'];
      }

      // Extract raw values from JSON
      double temp = (data['main']['temp'] as num).toDouble();
      String condition = data['weather'][0]['main'].toString();
      // Convert Wind from meters/sec to km/h
      double windSpeedKmh = (data['wind']['speed'] as num).toDouble() * 3.6;
      int humidity = data['main']['humidity'];

      // Save to state variables
      _currentWeather = {
        'temp': temp.round(),
        'feelsLike': (data['main']['feels_like'] as num).round(),
        'condition': condition,
        'humidity': humidity,
        'wind': windSpeedKmh.round(),
        // Convert visibility from meters to km
        'visibility': (data['visibility'] / 1000).round(),
      };

      // Call our Smart Logic functions to generate text
      _adviceData = _generateSmartAdvice(temp, condition, windSpeedKmh, humidity);
      _activeAlert = _generateSmartAlert(condition, windSpeedKmh);

      _isLoading = false;
    });
  }

  /// 4. LOGIC: Generate specific advice based on weather parameters
  List<Map<String, dynamic>> _generateSmartAdvice(double temp, String condition, double wind, int humidity) {
    List<Map<String, dynamic>> list = [];
    String condLower = condition.toLowerCase();

    // -- Rule 1: Rain --
    if (condLower.contains('rain') || condLower.contains('drizzle')) {
      list.add({
        'title': 'Rain Detected',
        'desc': 'Avoid applying fertilizers or pesticides to prevent runoff.',
        'color': const Color(0xFFDBEAFE),
        'icon': Icons.water_drop
      });
    } else {
      // If no rain, check if it is too hot (Irrigation needed)
      if (temp > 28) {
         list.add({
          'title': 'Irrigation Needed',
          'desc': 'High temperatures detected. Water crops to prevent heat stress.',
          'color': const Color(0xFFDCFCE7),
          'icon': Icons.water_drop
        });
      }
    }

    // -- Rule 2: High Wind --
    if (wind > 15) {
      list.add({
        'title': 'High Winds (${wind.round()} km/h)',
        'desc': 'Avoid spraying pesticides as drift may occur.',
        'color': const Color(0xFFFEF9C2),
        'icon': Icons.air
      });
    }

    // -- Rule 3: General Conditions --
    if (condLower.contains('clear') || condLower.contains('sun')) {
      list.add({
        'title': 'Good Field Conditions',
        'desc': 'Ideal weather for sowing, harvesting, or equipment maintenance.',
        'color': const Color(0xFFFFF7ED),
        'icon': Icons.wb_sunny
      });
    } else if (condLower.contains('thunder') || condLower.contains('storm')) {
       list.add({
        'title': 'Safety Warning',
        'desc': 'Lightning risk. Stay away from open fields and metal equipment.',
        'color': const Color(0xFFFEE2E2),
        'icon': Icons.flash_on
      });
    }

    // -- Rule 4: Frost/Cold --
    if (temp < 10) {
      list.add({
        'title': 'Cold Stress Risk',
        'desc': 'Temperatures are low. Protect sensitive seedlings from frost.',
        'color': const Color(0xFFEFF6FF),
        'icon': Icons.ac_unit
      });
    }

    // Fallback if no specific advice
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

  /// 5. LOGIC: Generate Red Alerts for extreme weather
  Map<String, dynamic>? _generateSmartAlert(String condition, double wind) {
    String condLower = condition.toLowerCase();
    
    if (condLower.contains('thunder') || condLower.contains('storm')) {
      return {
        'title': 'Storm Alert',
        'desc': 'Thunderstorm activity detected. Halt all field work immediately.'
      };
    }
    if (condLower.contains('rain') && condLower.contains('heavy')) {
       return {
        'title': 'Heavy Rain Alert',
        'desc': 'Heavy precipitation expected. Ensure drainage systems are clear.'
      };
    }
    if (wind > 30) {
       return {
        'title': 'Gale Warning',
        'desc': 'Damaging winds detected. Secure loose structures and livestock.'
      };
    }
    return null; // Return null means "No Active Alert"
  }

  void _handleError(dynamic e) {
    setState(() {
      _errorMessage = "Could not load weather. Check internet/GPS.";
      _isLoading = false;
      _currentWeather['condition'] = 'Error';
    });
    print(e);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Custom AppBar with Gradient
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight * 2), 
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
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          'Weather Forecast',
                          style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w600),
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

  Widget _buildLocationRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
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
                  style: const TextStyle(color: Colors.white, fontSize: 16),
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
                  const Text(
                    'Today',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _currentWeather['condition'].toString(),
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
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
                        color: Colors.white,
                        size: 40,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_currentWeather['temp']}°C',
                        style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Feels like ${_currentWeather['feelsLike']}°C',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConditionsRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Current Conditions',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF101727)),
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

  Widget _conditionCard(IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2, offset: const Offset(0, 1))],
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.orange, size: 24),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 12, color: Color(0xFF495565))),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF101727))),
        ],
      ),
    );
  }

  Widget _buildHourlySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Hourly Forecast', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF101727))),
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2, offset: const Offset(0, 1))],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(data['time'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF101727)), textAlign: TextAlign.center),
                    Icon(_getWeatherIcon('Partly Cloudy'), color: Colors.orange, size: 28),
                    Text('${data['temp']}°', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF101727))),
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

  Widget _buildWeeklySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('7-Day Forecast', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF101727))),
        const SizedBox(height: 12),
        Column(
          children: _weeklyData.map((day) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
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
                        Text(day['day'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF101727)), overflow: TextOverflow.ellipsis),
                        Text(day['date'] as String, style: const TextStyle(fontSize: 12, color: Color(0xFF495565))),
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
                      Text('${day['high']}°', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF101727))),
                      Text('${day['low']}°', style: const TextStyle(fontSize: 14, color: Color(0xFF495565))),
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

  Widget _buildAdviceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Farming Advice',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF101727)),
        ),
        const SizedBox(height: 12),
        if (_adviceData.isEmpty)
           const Padding(
             padding: EdgeInsets.all(8.0),
             child: Text("Conditions are stable. No specific warnings.", style: TextStyle(color: Colors.grey)),
           ),
        Column(
          children: _adviceData.map((advice) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
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
                        Text(advice['title'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF101727))),
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

  void _showLocationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Location'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _locations.length,
            itemBuilder: (context, index) => ListTile(
              title: Text(_locations[index]),
              leading: const Icon(Icons.location_city, color: Colors.orange),
              onTap: () {
                // Call API with selected city
                _fetchWeatherByCity(_locations[index]); 
                Navigator.pop(context);
              },
            ),
          ),
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.my_location),
            label: const Text("Use Current GPS"),
            onPressed: () {
              _fetchWeatherByGPS();
              Navigator.pop(context);
            },
          )
        ],
      ),
    );
  }

  IconData _getWeatherIcon(String condition) {
    condition = condition.toLowerCase();
    if (condition.contains('cloud')) return Icons.cloud;
    if (condition.contains('rain')) return Icons.umbrella;
    if (condition.contains('clear') || condition.contains('sun')) return Icons.wb_sunny;
    if (condition.contains('snow')) return Icons.ac_unit;
    if (condition.contains('thunder')) return Icons.flash_on;
    return Icons.wb_sunny;
  }
}