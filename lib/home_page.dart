import 'package:flutter/material.dart';
import 'crop_advisory.dart';
import 'pest_disease_help.dart';
import 'weather_page.dart';
import 'water_optimization.dart';
import 'notification.dart';
import 'settings.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'weather_service.dart';
import 'ai_chat_page.dart';
import 'localization_service.dart';

class HomePage extends StatefulWidget {
  final bool isNewUser;
  final String userName;
  
  const HomePage({
    super.key,
    this.isNewUser = false,
    this.userName = 'Farmer',
  });

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentNavIndex = 0;
  String displayName = '';

  // Weather State
  final WeatherService _weatherService = WeatherService();
  Map<String, dynamic>? _homeWeatherData;
  bool _loadingWeather = true;

  // Farm Overview State
  int _activeCropsCount = 0;
  int _alertsCount = 0;
  double _yieldRate = 0.0;
  int _tasksDone = 0;
  int _totalTasks = 0;
  List<Map<String, String>> _recentActivities = [];

  String tr(String key) => LocalizationService.translate(key);

  @override
  void initState() {
    super.initState();
    print('🏠 HomePage initState called');
    // Initialize with the name passed from navigation
    displayName = widget.userName;
    // Try to fetch the latest name from database
    _fetchUserName();
    print('🔄 Calling _fetchHomeWeather from initState');
    _fetchHomeWeather(); // Fetch weather when app starts
    _fetchFarmOverviewData(); // Fetch farm overview data
    _fetchRecentActivities(); // Fetch recent activities
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Fetch Weather for Home Card
  Future<void> _fetchHomeWeather() async {
    try {
      print('🔄 _fetchHomeWeather() called');
      final data = await _weatherService.getCurrentWeather();
      print('✅ Weather data fetched: ${data['main']?['temp']}°C');
      
      // Check weather and create notifications
      print('📌 Calling checkWeatherAndNotify()...');
      await _weatherService.checkWeatherAndNotify();
      print('✅ checkWeatherAndNotify() completed');
      
      if (mounted) {
        setState(() {
          _homeWeatherData = data;
          _loadingWeather = false;
        });
      }
    } catch (e) {
      print("❌ Home Weather Error: $e");
      if (mounted) {
        setState(() {
          _loadingWeather = false;
        });
      }
    }
  }

  Future<void> _fetchUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // 1. Try to get name from Auth Profile (Google/Email)
      if (user.displayName != null && user.displayName!.isNotEmpty) {
        setState(() {
          displayName = user.displayName!;
        });
      }

      // 2. Try to get name from Firestore (Database) for more accuracy
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>? ?? {};
          if (data.containsKey('firstName') && data.containsKey('lastName')) {
             setState(() {
               displayName = "${data['firstName']} ${data['lastName']}";
             });
          }
        }
      } catch (e) {
        print("Error fetching user data: $e");
      }
    }
  }

  // Fetch Farm Overview Data from Firestore
  Future<void> _fetchFarmOverviewData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Fetch active crops by aggregating across fields -> users/{uid}/fields/{fieldId}/crops
      final fieldsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('fields')
          .get();

      int totalCrops = 0;
      for (var fieldDoc in fieldsSnapshot.docs) {
        try {
          final cropCount = await fieldDoc.reference.collection('crops').count().get();
          totalCrops += (cropCount.count ?? 0);
        } catch (_) {
          // fallback: try fetching docs if count() not supported
          final cropDocs = await fieldDoc.reference.collection('crops').get();
          totalCrops += cropDocs.docs.length;
        }
      }
      
      // Fetch pest alerts
      final alertsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('pestAlerts')
          .where('resolved', isEqualTo: false)
          .get();

        // Fetch recent notifications (use 'time' field that NotificationService writes)
        final notificationsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .orderBy('time', descending: true)
          .limit(50)
          .get();
          // If no results using 'time', try 'timestamp' as older code might use that key
          if (notificationsSnapshot.docs.isEmpty) {
            final altSnapshot = await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('notifications')
                .orderBy('timestamp', descending: true)
                .limit(50)
                .get();
            if (altSnapshot.docs.isNotEmpty) {
              print(' Found notifications using \"timestamp\" field');
              // replace notificationsSnapshot variable by altSnapshot for counting
              // (we'll keep a local reference)
              // Use altSnapshot for completedTasks calculation below
          
              // set variable by shadowing
          
            }
          }

        int completedTasks = notificationsSnapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        final title = (data['title'] as String?)?.toLowerCase() ?? '';
        final type = (data['type'] as String?)?.toLowerCase() ?? '';
        return type == 'system' || title.contains('task') || title.contains('done') || title.contains('completed');
        }).length;

      if (mounted) {
        setState(() {
          _activeCropsCount = totalCrops;
          _alertsCount = alertsSnapshot.docs.length;
          _yieldRate = 85.0; // Default value - could fetch from crop data
          _tasksDone = completedTasks;
          _totalTasks = completedTasks + 2; // Estimated total
        });
      }
          print('ℹ️ Farm overview: crops=$totalCrops alerts=${alertsSnapshot.docs.length} tasksDone=$completedTasks');
    } catch (e) {
      print('❌ Error fetching farm overview: $e');
    }
  }

  // Fetch Recent Activities from Firestore
  Future<void> _fetchRecentActivities() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Fetch notifications
      final notificationsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .orderBy('time', descending: true)
          .limit(10)
          .get();

      List<QueryDocumentSnapshot> docs = notificationsSnapshot.docs;
      // If no docs with 'time', try 'timestamp'
      if (docs.isEmpty) {
        final alt = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .orderBy('timestamp', descending: true)
            .limit(10)
            .get();
        docs = alt.docs;
        if (docs.isNotEmpty) print('ℹ️ Using notifications ordered by "timestamp"');
      }

      // Fetch pest alerts
      final alertsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('pestAlerts')
          .orderBy('detectedDate', descending: true)
          .limit(10)
          .get();

      List<Map<String, String>> activities = [];

      // Add notifications
      for (var doc in docs) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        final timestamp = (data['time'] as Timestamp?)?.toDate()
            ?? (data['timestamp'] as Timestamp?)?.toDate()
            ?? (data['createdAt'] as Timestamp?)?.toDate()
            ?? DateTime.now();
        final duration = DateTime.now().difference(timestamp);
        
        String timeAgo = _formatTimeAgo(duration);

        activities.add({
          'title': data['title'] ?? 'Activity',
          'time': timeAgo,
          'type': data['module'] ?? data['type'] ?? 'system',
        });
      }

      // Add pest alerts
      for (var doc in alertsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        final timestamp = (data['detectedDate'] as Timestamp?)?.toDate() ?? DateTime.now();
        final duration = DateTime.now().difference(timestamp);
        
        String timeAgo = _formatTimeAgo(duration);
        final pestName = data['pestName'] ?? 'Alert';
        final severity = data['severity'] ?? 'Medium';

        activities.add({
          'title': '⚠️ $pestName detected (${severity.toLowerCase()})',
          'time': timeAgo,
          'type': 'pest',
        });
      }

      // Sort activities by time (most recent first)
      // We need to extract time for sorting - for now keep insertion order
      // (notifications are already sorted, alerts are already sorted)

      // Take only top 5
      activities = activities.take(5).toList();

      if (mounted) {
        setState(() {
          _recentActivities = activities;
        });
      }
      print('ℹ️ Recent Activities: ${activities.length} items (${docs.length} notifications, ${alertsSnapshot.docs.length} pest alerts)');
    } catch (e) {
      print('❌ Error fetching recent activities: $e');
      // Show default welcome message
      if (mounted) {
        setState(() {
          _recentActivities = [
            {'title': 'Welcome to Smart Kisan!', 'time': 'Just now', 'type': 'task'},
          ];
        });
      }
    }
  }

  // Helper to format time ago
  String _formatTimeAgo(Duration duration) {
    if (duration.inMinutes < 1) {
      return 'Just now';
    } else if (duration.inMinutes < 60) {
      return '${duration.inMinutes} minute${duration.inMinutes > 1 ? 's' : ''} ago';
    } else if (duration.inHours < 24) {
      return '${duration.inHours} hour${duration.inHours > 1 ? 's' : ''} ago';
    } else {
      return '${duration.inDays} day${duration.inDays > 1 ? 's' : ''} ago';
    }
  }

  // Show language selection dialog
  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('Select Language')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.language),
              title: const Text('English'),
              onTap: () {
                LocalizationService.setLanguage('en');
                Navigator.pop(context);
                setState(() {});
              },
            ),
            ListTile(
              leading: const Icon(Icons.language),
              title: const Text('हिन्दी (Hindi)'),
              onTap: () {
                LocalizationService.setLanguage('hi');
                Navigator.pop(context);
                setState(() {});
              },
            ),
            ListTile(
              leading: const Icon(Icons.language),
              title: const Text('नेपाली (Nepali)'),
              onTap: () {
                LocalizationService.setLanguage('ne');
                Navigator.pop(context);
                setState(() {});
              },
            ),
          ],
        ),
      ),
    );
  }
  
  // Colors used in the app
  final Color _primaryGreen = const Color(0xFF2C7C48);
  final Color _lightGreen = const Color(0xFFF0FDF4);
  final Color _accentGreen = const Color(0xFF00C950);
  final Color _darkGreen = const Color(0xFF00A63E);
  final Color _warningYellow = const Color(0xFFF0B100);
  final Color _warningOrange = const Color(0xFFFF6900);
  final Color _errorRed = const Color(0xFFFB2C36);
  final Color _darkRed = const Color(0xFFE7000B);
  final Color _infoBlue = const Color(0xFF2B7FFF);
  final Color _darkBlue = const Color(0xFF155DFC);
  final Color _white = Colors.white;
  final Color _black = Colors.black;
  final Color _gray = const Color(0xFF4A5565);
  final Color _darkGray = const Color(0xFF1F2937);
  final Color _lightText = const Color(0xFFDCFCE7);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // App Bar
              _buildAppBar(),
              
              // Weather Card
              _buildWeatherCard(),
              
              // Feature Grid
              _buildFeatureGrid(),
              
              // Farm Overview Title
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 20, right: 16),
                child: Row(
                  children: [
                    Text(
                      tr('Farm Overview'),
                      style: TextStyle(
                        color: _darkGray,
                        fontSize: 16,
                        fontFamily: 'Arimo',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Farm Overview Stats
              _buildFarmOverview(),
              
              // Language Card
              _buildLanguageCard(),
              
              // Recent Activity
              _buildRecentActivity(),
              
              const SizedBox(height: 80), // Space for bottom navigation
            ],
          ),
        ),
      ),
      
      // Bottom Navigation Bar
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  // ============== Widget Builders ==============
  
  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 16),
      decoration: BoxDecoration(
        color: _primaryGreen,
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: _black.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Profile Section
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              // ignore: deprecated_member_use
              color: _white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 20),
          ),
          
          const SizedBox(width: 12),
          
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Text(
              tr('smart_kisan'),
              style: TextStyle(
                color: _white,
                fontSize: 16,
                fontFamily: 'Arimo',
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '${tr('Welcome ')}, $displayName',
              style: TextStyle(
                color: _lightText,
                fontSize: 12,
                fontFamily: 'Arimo',
              ),
            ),
            Text(
              _homeWeatherData != null ? _homeWeatherData!['name'] : tr('Locating...'),
              style: TextStyle(
                color: _lightText,
                fontSize: 11,
                fontFamily: 'Arimo',
              ),
            ),
            ],
          ),
          
          const Spacer(),
          
          //notification part
          
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationScreen()),
              );
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                children: [
                  const Center(child: Icon(Icons.notifications, color: Colors.white, size: 30)),
                  // StreamBuilder to get unread notification count
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(FirebaseAuth.instance.currentUser?.uid ?? '')
                        .collection('notifications')
                        .where('isRead', isEqualTo: false)
                        .snapshots(),
                    builder: (context, snapshot) {
                      int unreadCount = 0;
                      if (snapshot.hasData) {
                        unreadCount = snapshot.data!.docs.length;
                      }
                      
                      // Show badge only if there are unread notifications
                      if (unreadCount == 0) {
                        return const SizedBox.shrink();
                      }
                      
                      return Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: _errorRed,
                            borderRadius: BorderRadius.circular(13),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Center(
                            child: Text(
                              unreadCount > 99 ? '99+' : unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontFamily: 'Arimo',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 12),
          
          // Settings Icon
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.settings, color: Colors.white, size: 30),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherCard() {
    // Default values (if loading or error)
    String temp = '--';
    String condition = tr('Loading...');
    String humidity = '--';
    String wind = '--';
    String visibility = '--';
    String feelsLike = '--';
    String advice = tr('Fetching weather...');

    if (!_loadingWeather && _homeWeatherData != null) {
      double t = (_homeWeatherData!['main']['temp'] as num).toDouble();
      temp = t.round().toString();
      condition = _homeWeatherData!['weather'][0]['main'];
      humidity = "${_homeWeatherData!['main']['humidity']}%";
      wind = "${(_homeWeatherData!['wind']['speed'] * 3.6).round()} km/h"; // m/s to km/h
      // Visibility (meters to km)
      if (_homeWeatherData!['visibility'] != null) {
        try {
          final vis = (_homeWeatherData!['visibility'] as num).toDouble();
          visibility = '${(vis / 1000).toStringAsFixed(1)} km';
        } catch (_) {
          visibility = '--';
        }
      }

      // Feels like
      try {
        feelsLike = '${(_homeWeatherData!['main']['feels_like'] as num).round()}°C';
      } catch (_) {
        feelsLike = '--';
      }
      
      // Dynamic Advice logic
      if (condition.toLowerCase().contains('rain')) {
        advice = tr('Rain Detected');
      } else if (t > 30) {
        advice = tr('Irrigation Needed');
      } else if (t < 10) {
        advice = tr('Cold Stress Risk');
      } else {
        advice = tr('Good Field Conditions');
      }
    }

    return GestureDetector(
      onTap: () async {
        // Navigate to full weather page
        await Navigator.push(context, MaterialPageRoute(builder: (_) => const WeatherPage()));
        // Refresh weather notifications when returning
        if (mounted) {
          await _fetchHomeWeather();
        }
      },
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _primaryGreen,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _white.withValues(alpha: 0.2), width: 1.5),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left side: icon + texts - allow this area to expand
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: _white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.cloud, color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tr('Current Weather'),
                              style: TextStyle(
                                color: _white,
                                fontSize: 12,
                                fontFamily: 'Arimo',
                              ),
                            ),
                            Text(
                              '$temp°C • $condition',
                              style: TextStyle(
                                color: _white,
                                fontSize: 14,
                                fontFamily: 'Arimo',
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Advice Box - allow to shrink and show ellipsis if needed
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _warningYellow,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      advice,
                      style: const TextStyle(
                        color: Color(0xFF733E0A),
                        fontSize: 12,
                        fontFamily: 'Arimo',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildWeatherMetric(Icons.water_drop, tr('Humidity'), humidity),
                _buildWeatherMetric(Icons.air, tr('Wind'), wind),
                _buildWeatherMetric(Icons.visibility, tr('Visibility'), visibility),
                _buildWeatherMetric(Icons.thermostat, tr('Feels Like'), feelsLike),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherMetric(IconData icon, String label, String value) {
    return Container(
      width: 80,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: _white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: _white, size: 16),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: _lightText,
              fontSize: 11,
              fontFamily: 'Arimo',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: _white,
              fontSize: 14,
              fontFamily: 'Arimo',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureGrid() {
    final features = [
      {'title': 'Crop Advisory', 'color1': _accentGreen, 'color2': _darkGreen, 'icon': Icons.agriculture},
      {'title': 'Pest & Disease Help', 'color1': _errorRed, 'color2': _darkRed, 'icon': Icons.bug_report},
      {'title': 'Water Optimization', 'color1': _infoBlue, 'color2': _darkBlue, 'icon': Icons.water_drop},
      {'title': 'Weather Forecast', 'color1': _warningYellow, 'color2': _warningOrange, 'icon': Icons.cloud},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 13,
          mainAxisSpacing: 13,
          childAspectRatio: 196 / 101,
        ),
        itemCount: features.length,
        itemBuilder: (context, index) {
          final feature = features[index];
          return GestureDetector(
            onTap: () {
              // Handle navigation for Crop Advisory
              if (feature['title'] == 'Crop Advisory') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CropAdvisoryScreen(),
                  ),
                );
              }
              // Handle navigation for Pest & Disease Help
              if (feature['title'] == 'Pest & Disease Help') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PestDiseaseHelpScreen(),
                  ),
                );
              }
              // ADD THIS FOR WATER OPTIMIZATION
              if (feature['title'] == 'Water Optimization') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WaterOptimizationScreen(),
                  ),
                );
              }
                // Handle navigation for Weather Card Page
              if (feature['title'] == 'Weather Forecast') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WeatherPage(),
                  ),
                );
              }
            },

            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: const Alignment(0.24, 0.00),
                  end: const Alignment(0.76, 1.00),
                  colors: [feature['color1'] as Color, feature['color2'] as Color],
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: _black.withValues(alpha: 0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(feature['icon'] as IconData, color: _white, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    tr(feature['title'] as String),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _white,
                      fontSize: 12,
                      fontFamily: 'Arimo',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFarmOverview() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: _black.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // First Row
          Row(
            children: [
              Expanded(child: _buildStatCard(
                icon: Icons.agriculture,
                label: tr('Active Crops'),
                value: _activeCropsCount.toString(),
                subtitle: _activeCropsCount == 0 ? tr('Tap to add crops') : tr('Currently growing'),
                color: _lightGreen,
                textColor: _darkGreen,
              )),
              
              const SizedBox(width: 12),
              
              Expanded(child: _buildStatCard(
                icon: Icons.insights,
                label: tr('Yield Rate'),
                value: '${_yieldRate.toStringAsFixed(0)}%',
                subtitle: tr('Farm productivity'),
                color: const Color(0xFFEFF6FF),
                textColor: _darkBlue,
              )),
            ],
          ),
          
          const SizedBox(height: 15),
          
          // Second Row
          Row(
            children: [
              Expanded(child: _buildStatCard(
                icon: Icons.notifications,
                label: tr('Alerts'),
                value: _alertsCount.toString(),
                subtitle: _alertsCount == 0 ? tr('All clear') : tr('Issues detected'),
                color: const Color(0xFFFEF3F2),
                textColor: _darkRed,
              )),
              
              const SizedBox(width: 12),
              
              Expanded(child: _buildStatCard(
                icon: Icons.task,
                label: tr('Tasks Done'),
                value: '$_tasksDone/$_totalTasks',
                subtitle: tr('This period'),
                color: _lightGreen,
                textColor: _darkGreen,
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required String subtitle,
    required Color color,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: textColor.withValues(alpha: 0.12), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _gray, size: 16),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: _gray,
                  fontSize: 12,
                  fontFamily: 'Arimo',
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: _darkGray,
              fontSize: 20,
              fontFamily: 'Arimo',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontFamily: 'Arimo',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFFFDFBE8), Color(0xFFFFF7EC)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFEEF85), width: 1.6),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
              Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF9C2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.language, color: Color(0xFF884A00), size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('Language / भाषा'),
                    style: const TextStyle(
                      color: Color(0xFF884A00),
                      fontSize: 16,
                      fontFamily: 'Arimo',
                    ),
                  ),
                  Text(
                    tr('Currently: English'),
                    style: const TextStyle(
                      color: Color(0xFFD08700),
                      fontSize: 14,
                      fontFamily: 'Arimo',
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Color(0xFFF0B000), Color(0xFFFF6800)],
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: _black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              tr('Nepali'),
              style: TextStyle(
                color: _white,
                fontSize: 14,
                fontFamily: 'Arimo',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    // Use real activities from state or show default if empty
    List<Map<String, String>> activities = _recentActivities.isNotEmpty
        ? _recentActivities
        : [
            {'title': 'Welcome to Smart Kisan!', 'time': 'Just now', 'type': 'task'},
          ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr('Recent Activity'),
            style: TextStyle(
              color: _black,
              fontSize: 14,
              fontFamily: 'Arimo',
            ),
          ),
          
          const SizedBox(height: 12),
          
          if (activities.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  tr('No recent activity'),
                  style: TextStyle(
                    color: _gray,
                    fontSize: 12,
                    fontFamily: 'Arimo',
                  ),
                ),
              ),
            )
          else
            ...activities.map((activity) {
              Color iconColor;
              IconData icon;
              
              final activityType = activity['type']?.toLowerCase() ?? 'task';
              
              if (activityType.contains('pest')) {
                iconColor = _darkRed;
                icon = Icons.bug_report;
              } else if (activityType.contains('weather')) {
                iconColor = const Color(0xFFDBEAFE);
                icon = Icons.cloud;
              } else if (activityType.contains('crop') || activityType.contains('advisory')) {
                iconColor = _primaryGreen;
                icon = Icons.agriculture;
              } else if (activityType.contains('water')) {
                iconColor = _infoBlue;
                icon = Icons.water_drop;
              } else if (activityType.contains('notification') || activityType.contains('alert')) {
                iconColor = _warningYellow;
                icon = Icons.notifications;
              } else {
                iconColor = _primaryGreen;
                icon = Icons.check_circle;
              }
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: iconColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: _white, size: 10),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activity['title'] ?? 'Activity',
                            style: TextStyle(
                              color: _black,
                              fontSize: 12,
                              fontFamily: 'Arimo',
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            activity['time'] ?? 'Recently',
                            style: TextStyle(
                              color: _black.withValues(alpha: 0.6),
                              fontSize: 11,
                              fontFamily: 'Arimo',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      height: 66,
      decoration: BoxDecoration(
        color: _white,
        border: const Border(top: BorderSide(color: Color(0xFFB8F7CF), width: 0.8)),
        boxShadow: [
          BoxShadow(
            color: _black.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(Icons.home, tr('Home'), 0),
                  _buildNavItem(Icons.auto_awesome, tr('Ask AI'), 1),
                  _buildNavItem(Icons.bug_report, tr('Pest & Disease'), 2),
                  _buildNavItem(Icons.eco, tr('Add Crop'), 3),
                ],
              ),
            ),
            
            // Language Button
            GestureDetector(
              onTap: _showLanguageDialog,
              child: Container(
                width: 72,
                margin: const EdgeInsets.only(left: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [Color(0xFFF0B000), Color(0xFFFF6800)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: _black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.language, color: Colors.white, size: 16),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          LocalizationService.currentLanguage,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontFamily: 'Arimo',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _currentNavIndex == index;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentNavIndex = index;
        });
        
        // Handle navigation for different tabs
        if (index == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AiChatPage(),
            ),
          );
        } else if (index == 2) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PestDiseaseHelpScreen(),
            ),
          );
        } else if (index == 3) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CropAdvisoryScreen(),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _lightGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? _darkGreen : _gray,
              size: 16,
            ),
            const SizedBox(height: 4),
            Text(
              tr(label),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? _darkGreen : _gray,
                fontSize: label.contains('\n') ? 10 : 12,
                fontFamily: 'Arimo',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
