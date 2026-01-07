import 'package:flutter/material.dart';

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  String _selectedLocation = 'Kathmandu, Nepal';
  final List<String> _locations = [
    'Kathmandu, Nepal',
    'Pokhara, Nepal',
    'Chitwan, Nepal',
    'Biratnagar, Nepal',
  ];

  // Weather data with explicit types
  final Map<String, dynamic> _currentWeather = {
    'temp': 28,
    'feelsLike': 26,
    'condition': 'Partly Cloudy',
    'humidity': 68,
    'wind': 12,
    'visibility': 8,
  };

  final List<Map<String, dynamic>> _hourlyData = [
    {'time': '12 PM', 'temp': 28, 'chance': 20},
    {'time': '1 PM', 'temp': 29, 'chance': 15},
    {'time': '2 PM', 'temp': 30, 'chance': 10},
    {'time': '3 PM', 'temp': 29, 'chance': 15},
    {'time': '4 PM', 'temp': 28, 'chance': 30},
    {'time': '5 PM', 'temp': 27, 'chance': 60},
  ];

  final List<Map<String, dynamic>> _weeklyData = [
    {'day': 'Today', 'date': 'Dec 15', 'condition': 'Partly Cloudy', 'high': 30, 'low': 24, 'chance': 30},
    {'day': 'Tomorrow', 'date': 'Dec 16', 'condition': 'Rain', 'high': 28, 'low': 23, 'chance': 70},
    {'day': 'Wednesday', 'date': 'Dec 17', 'condition': 'Rain', 'high': 27, 'low': 22, 'chance': 65},
    {'day': 'Thursday', 'date': 'Dec 18', 'condition': 'Cloudy', 'high': 29, 'low': 23, 'chance': 40},
    {'day': 'Friday', 'date': 'Dec 19', 'condition': 'Sunny', 'high': 31, 'low': 24, 'chance': 10},
    {'day': 'Saturday', 'date': 'Dec 20', 'condition': 'Sunny', 'high': 32, 'low': 25, 'chance': 5},
    {'day': 'Sunday', 'date': 'Dec 21', 'condition': 'Partly Cloudy', 'high': 30, 'low': 24, 'chance': 20},
  ];

  final List<Map<String, dynamic>> _adviceData = [
    {'title': 'Heavy Rain Expected', 'desc': 'Rain likely tomorrow and Wednesday. Delay fertilizer application.', 'color': Color(0xFFDBEAFE), 'icon': Icons.cloudy_snowing},
    {'title': 'Good Irrigation Window', 'desc': 'Today is ideal for irrigation before the rain.', 'color': Color(0xFFDCFCE7), 'icon': Icons.water_drop},
    {'title': 'Wind Advisory', 'desc': 'Strong winds expected this afternoon. Secure loose equipment.', 'color': Color(0xFFFEF9C2), 'icon': Icons.air},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
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
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 25,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Location
              _buildLocationRow(),
              const SizedBox(height: 16),
              
              // Current Weather
              _buildCurrentWeather(),
              const SizedBox(height: 24),
              
              // Conditions
              _buildConditionsRow(),
              const SizedBox(height: 24),
              
              // Hourly Forecast
              _buildHourlySection(),
              const SizedBox(height: 24),
              
              // Weekly Forecast
              _buildWeeklySection(),
              const SizedBox(height: 24),
              
              // Farming Advice
              _buildAdviceSection(),
              const SizedBox(height: 24),
              
              // Alert
              _buildAlertCard(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
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
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _currentWeather['condition'] as String,
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
                        _getWeatherIcon(_currentWeather['condition'] as String),
                        color: Colors.white,
                        size: 40,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_currentWeather['temp']}°C',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w600,
                        ),
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
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF101727),
          ),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.orange, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Color(0xFF495565)),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF101727),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHourlySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hourly Forecast',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF101727),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 140, // Increased height
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _hourlyData.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final data = _hourlyData[index];
              return Container(
                width: 85, // Increased width slightly
                margin: EdgeInsets.only(
                  left: index == 0 ? 0 : 8,
                  right: index == _hourlyData.length - 1 ? 8 : 0,
                ),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(
                      data['time'] as String,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF101727),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Icon(
                      _getWeatherIcon('Partly Cloudy'),
                      color: Colors.orange,
                      size: 28,
                    ),
                    Text(
                      '${data['temp']}°',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF101727),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.water_drop,
                            color: Color(0xFF155CFB),
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${data['chance']}%',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF155CFB),
                            ),
                          ),
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
        const Text(
          '7-Day Forecast',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF101727),
          ),
        ),
        const SizedBox(height: 12),
        Column(
          children: _weeklyData.map((day) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          day['day'] as String,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF101727),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          day['date'] as String,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF495565),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _getWeatherIcon(day['condition'] as String),
                    color: Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (day['condition'] as String).split(' ').first,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF354152),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.water_drop,
                              color: Color(0xFF155CFB),
                              size: 12,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${day['chance']}%',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF155CFB),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${day['high']}°',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF101727),
                        ),
                      ),
                      Text(
                        '${day['low']}°',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF495565),
                        ),
                      ),
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
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF101727),
          ),
        ),
        const SizedBox(height: 12),
        Column(
          children: _adviceData.map((advice) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: advice['color'] as Color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      advice['icon'] as IconData,
                      color: Colors.black.withOpacity(0.6),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          advice['title'] as String,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF101727),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          advice['desc'] as String,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF354152),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
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
        gradient: const LinearGradient(
          colors: [Color(0xFFFDFBE8), Color(0xFFFEF9C1)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFDF20), width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFF723D0A),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Weather Alert',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF723D0A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Light rain expected tomorrow and Wednesday. Plan farming activities accordingly.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF884A00),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
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
              trailing: _selectedLocation == _locations[index]
                  ? const Icon(Icons.check, color: Colors.orange)
                  : null,
              onTap: () {
                setState(() => _selectedLocation = _locations[index]);
                Navigator.pop(context);
              },
            ),
          ),
        ),
      ),
    );
  }

  IconData _getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'sunny':
        return Icons.wb_sunny;
      case 'partly cloudy':
        return Icons.wb_cloudy;
      case 'cloudy':
        return Icons.cloud;
      case 'rain':
        return Icons.umbrella;
      default:
        return Icons.wb_sunny;
    }
  }
}