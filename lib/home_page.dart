import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  final bool isNewUser;
  final String userName;
  
  const HomePage({
    Key? key,
    this.isNewUser = false,
    this.userName = 'Farmer',
  }) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentNavIndex = 0;

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
                      'Farm Overview',
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
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: _primaryGreen,
        boxShadow: [
          BoxShadow(
            color: _black.withOpacity(0.1),
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
            height: 36,
            decoration: BoxDecoration(
              color: _white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 20),
          ),
          
          const SizedBox(width: 12),
          
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Smart Kisan',
                style: TextStyle(
                  color: _white,
                  fontSize: 16,
                  fontFamily: 'Arimo',
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Good morning, ${widget.userName}',
                style: TextStyle(
                  color: _lightText,
                  fontSize: 12,
                  fontFamily: 'Arimo',
                ),
              ),
              Text(
                'Kathmandu, Nepal',
                style: TextStyle(
                  color: _lightText,
                  fontSize: 11,
                  fontFamily: 'Arimo',
                ),
              ),
            ],
          ),
          
          const Spacer(),
          
          // Notification Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              children: [
                const Center(child: Icon(Icons.notifications, color: Colors.white, size: 20)),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _errorRed,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Menu Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.menu, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _primaryGreen,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _white.withOpacity(0.2), width: 1.5),
      ),
      child: Column(
        children: [
          // Weather Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: _white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.cloud, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Today',
                        style: TextStyle(
                          color: _white,
                          fontSize: 12,
                          fontFamily: 'Arimo',
                        ),
                      ),
                      Text(
                        '28°C • Partly Cloudy',
                        style: TextStyle(
                          color: _white,
                          fontSize: 14,
                          fontFamily: 'Arimo',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              // Weather Alert
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _warningYellow,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Light rain expected',
                  style: TextStyle(
                    color: const Color(0xFF733E0A),
                    fontSize: 12,
                    fontFamily: 'Arimo',
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Weather Metrics
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildWeatherMetric(Icons.water_drop, 'Humidity', '68%'),
              _buildWeatherMetric(Icons.air, 'Wind', '12 km/h'),
              _buildWeatherMetric(Icons.visibility, 'Visibility', '8 km'),
              _buildWeatherMetric(Icons.thermostat, 'Feels Like', '26°C'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherMetric(IconData icon, String label, String value) {
    return Container(
      width: 80,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: _white.withOpacity(0.15),
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
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: const Alignment(0.24, 0.00),
                end: const Alignment(0.76, 1.00),
                colors: [feature['color1'] as Color, feature['color2'] as Color],
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: _black.withOpacity(0.1),
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
                  feature['title'] as String,
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
            color: _black.withOpacity(0.1),
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
                label: 'Active Crops',
                value: widget.isNewUser ? '0' : '4',
                subtitle: widget.isNewUser ? 'Tap to add crops' : 'Rice, Wheat, Corn',
                color: _lightGreen,
                textColor: _darkGreen,
              )),
              
              const SizedBox(width: 12),
              
              Expanded(child: _buildStatCard(
                icon: Icons.insights,
                label: 'Yield Rate',
                value: widget.isNewUser ? '0%' : '92%',
                subtitle: widget.isNewUser ? 'Start farming to see' : '+5% from last season',
                color: const Color(0xFFEFF6FF),
                textColor: _darkBlue,
              )),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Second Row
          Row(
            children: [
              Expanded(child: _buildStatCard(
                icon: Icons.notifications,
                label: 'Alerts',
                value: widget.isNewUser ? '0' : '2',
                subtitle: widget.isNewUser ? 'No alerts yet' : 'Pest warning, Rain',
                color: const Color(0xFFFEF3F2),
                textColor: _darkRed,
              )),
              
              const SizedBox(width: 12),
              
              Expanded(child: _buildStatCard(
                icon: Icons.task,
                label: 'Tasks Done',
                value: widget.isNewUser ? '0/0' : '8/10',
                subtitle: widget.isNewUser ? 'Setup your farm' : 'This week',
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
        border: Border.all(color: textColor.withOpacity(0.12), width: 1.5),
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
                    'Language / भाषा',
                    style: TextStyle(
                      color: const Color(0xFF884A00),
                      fontSize: 16,
                      fontFamily: 'Arimo',
                    ),
                  ),
                  Text(
                    'Currently: English',
                    style: TextStyle(
                      color: const Color(0xFFD08700),
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
                  color: _black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              'नेपाली',
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
    List<Map<String, String>> activities;
    
    if (widget.isNewUser) {
      activities = [
        {'title': 'Welcome to Smart Kisan!', 'time': 'Just now', 'type': 'task'},
        {'title': 'Complete farm setup to get started', 'time': '1 minute ago', 'type': 'task'},
      ];
    } else {
      activities = [
        {'title': 'Pest identified in tomato crop', 'time': '2 hours ago', 'type': 'pest'},
        {'title': 'Weather alert: Rain expected', 'time': '5 hours ago', 'type': 'weather'},
      ];
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Activity',
            style: TextStyle(
              color: _black,
              fontSize: 14,
              fontFamily: 'Arimo',
            ),
          ),
          
          const SizedBox(height: 12),
          
          ...activities.map((activity) {
            Color iconColor;
            IconData icon;
            
            if (activity['type'] == 'pest') {
              iconColor = _darkRed;
              icon = Icons.bug_report;
            } else if (activity['type'] == 'weather') {
              iconColor = const Color(0xFFDBEAFE);
              icon = Icons.cloud;
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
                          activity['title']!,
                          style: TextStyle(
                            color: _black,
                            fontSize: 12,
                            fontFamily: 'Arimo',
                          ),
                        ),
                        Text(
                          activity['time']!,
                          style: TextStyle(
                            color: _black.withOpacity(0.6),
                            fontSize: 12,
                            fontFamily: 'Arimo',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      height: 66,
      decoration: BoxDecoration(
        color: _white,
        border: Border(top: BorderSide(color: const Color(0xFFB8F7CF), width: 0.8)),
        boxShadow: [
          BoxShadow(
            color: _black.withOpacity(0.1),
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
                  _buildNavItem(Icons.home, 'Home', 0),
                  _buildNavItem(Icons.auto_awesome, 'Ask AI', 1),
                  _buildNavItem(Icons.qr_code_scanner, 'Scan', 2),
                  _buildNavItem(Icons.add_location, 'Add\nLocation', 3),
                ],
              ),
            ),
            
            // Language Button
            Container(
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
                      color: _black.withOpacity(0.1),
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
                        color: _white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'EN',
                        style: TextStyle(
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
              label,
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