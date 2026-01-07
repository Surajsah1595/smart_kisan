import 'package:flutter/material.dart';

void main() {
  runApp(const MaterialApp(
    home: WaterOptimizationScreen(),
    debugShowCheckedModeBanner: false,
  ));
}

class WaterOptimizationScreen extends StatefulWidget {
  const WaterOptimizationScreen({super.key});

  @override
  State<WaterOptimizationScreen> createState() => _WaterOptimizationScreenState();
}

class _WaterOptimizationScreenState extends State<WaterOptimizationScreen> {
  bool _showAddZoneForm = false;
  final TextEditingController _zoneNameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _waterAmountController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  
  // Zone status management
  List<Map<String, dynamic>> zones = [
    {
      'id': 1,
      'name': 'Rice Field - North',
      'location': 'North Section, Field A',
      'status': 'active',
      'moisture': 78,
      'schedule': '06:00 AM Daily',
      'isRunning': true,
    },
    {
      'id': 2,
      'name': 'Wheat Field - East',
      'location': 'East Section, Field B',
      'status': 'scheduled',
      'moisture': 65,
      'schedule': '02:00 PM Daily',
      'isRunning': false,
    },
    {
      'id': 3,
      'name': 'Corn Field - West',
      'location': 'West Section, Field C',
      'status': 'paused',
      'moisture': 45,
      'schedule': '06:00 AM Daily',
      'isRunning': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    // Initialize controllers with default values
    _waterAmountController.text = '300';
    _durationController.text = '60';
  }

  void _toggleAddZoneForm() {
    setState(() {
      _showAddZoneForm = !_showAddZoneForm;
    });
  }

  void _saveNewZone() {
    if (_zoneNameController.text.isEmpty || _locationController.text.isEmpty) {
      _showSnackBar('Please fill in all required fields');
      return;
    }

    final newZone = {
      'id': zones.length + 1,
      'name': _zoneNameController.text,
      'location': _locationController.text,
      'status': 'scheduled',
      'moisture': 65,
      'schedule': '06:00 AM Daily',
      'isRunning': false,
    };

    setState(() {
      zones.add(newZone);
      _showAddZoneForm = false;
      
      // Clear form
      _zoneNameController.clear();
      _locationController.clear();
      _waterAmountController.text = '300';
      _durationController.text = '60';
    });

    _showSnackBar('New zone added successfully!');
  }

  void _cancelAddZone() {
    setState(() {
      _showAddZoneForm = false;
      _zoneNameController.clear();
      _locationController.clear();
    });
  }

  void _updateZoneStatus(int zoneId, String action) {
    setState(() {
      final zoneIndex = zones.indexWhere((zone) => zone['id'] == zoneId);
      if (zoneIndex != -1) {
        switch (action) {
          case 'start':
            zones[zoneIndex]['isRunning'] = true;
            zones[zoneIndex]['status'] = 'active';
            break;
          case 'stop':
            zones[zoneIndex]['isRunning'] = false;
            zones[zoneIndex]['status'] = 'paused';
            break;
          case 'control':
            // Show control dialog
            _showControlDialog(zones[zoneIndex]['name']);
            break;
          case 'auto':
            zones[zoneIndex]['isRunning'] = true;
            zones[zoneIndex]['status'] = 'active';
            _showSnackBar('Auto mode activated for ${zones[zoneIndex]['name']}');
            break;
        }
      }
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showControlDialog(String zoneName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Control $zoneName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.play_arrow, color: Colors.green),
              title: const Text('Start Irrigation'),
              onTap: () {
                Navigator.pop(context);
                _showSnackBar('Starting irrigation for $zoneName');
              },
            ),
            ListTile(
              leading: const Icon(Icons.pause, color: Colors.orange),
              title: const Text('Pause Irrigation'),
              onTap: () {
                Navigator.pop(context);
                _showSnackBar('Pausing irrigation for $zoneName');
              },
            ),
            ListTile(
              leading: const Icon(Icons.timer, color: Colors.blue),
              title: const Text('Set Timer'),
              onTap: () {
                Navigator.pop(context);
                _showTimerDialog(zoneName);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.purple),
              title: const Text('Advanced Settings'),
              onTap: () {
                Navigator.pop(context);
                _showAdvancedSettings(zoneName);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showTimerDialog(String zoneName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Set Timer for $zoneName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Set irrigation duration:'),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTimerButton('15 min', zoneName),
                const SizedBox(width: 10),
                _buildTimerButton('30 min', zoneName),
                const SizedBox(width: 10),
                _buildTimerButton('60 min', zoneName),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerButton(String duration, String zoneName) {
    return ElevatedButton(
      onPressed: () {
        Navigator.pop(context);
        _showSnackBar('Timer set for $duration on $zoneName');
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF155DFC),
      ),
      child: Text(duration),
    );
  }

  void _showAdvancedSettings(String zoneName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Advanced Settings: $zoneName',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildSettingRow('Water Flow Rate', 'Adjust', () {
              Navigator.pop(context);
              _showWaterFlowDialog(zoneName);
            }),
            _buildSettingRow('Irrigation Pattern', 'Change', () {
              Navigator.pop(context);
              _showPatternDialog(zoneName);
            }),
            _buildSettingRow('Soil Moisture Target', 'Set', () {
              Navigator.pop(context);
              _showMoistureDialog(zoneName);
            }),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF155DFC),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Save Settings'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingRow(String title, String actionText, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 16)),
          TextButton(
            onPressed: onTap,
            child: Text(actionText, style: const TextStyle(color: Color(0xFF155DFC))),
          ),
        ],
      ),
    );
  }

  void _showWaterFlowDialog(String zoneName) {
    double flowRate = 50.0;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Water Flow Rate: $zoneName'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${flowRate.toStringAsFixed(1)} L/min',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                Slider(
                  value: flowRate,
                  min: 10,
                  max: 100,
                  divisions: 9,
                  label: '${flowRate.toStringAsFixed(1)} L/min',
                  onChanged: (value) {
                    setState(() {
                      flowRate = value;
                    });
                  },
                ),
                const SizedBox(height: 10),
                const Text('Adjust water flow rate for optimal irrigation'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showSnackBar('Water flow rate set to ${flowRate.toStringAsFixed(1)} L/min for $zoneName');
                },
                child: const Text('Apply'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showPatternDialog(String zoneName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Irrigation Pattern: $zoneName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPatternOption('Circular', Icons.radio_button_checked, zoneName),
            _buildPatternOption('Linear', Icons.straight, zoneName),
            _buildPatternOption('Grid', Icons.grid_on, zoneName),
            _buildPatternOption('Custom', Icons.edit, zoneName),
          ],
        ),
      ),
    );
  }

  Widget _buildPatternOption(String pattern, IconData icon, String zoneName) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF155DFC)),
      title: Text(pattern),
      onTap: () {
        Navigator.pop(context);
        _showSnackBar('$pattern pattern selected for $zoneName');
      },
    );
  }

  void _showMoistureDialog(String zoneName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Soil Moisture Target: $zoneName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Set target moisture level (40-80%):'),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildMoistureButton('40%', zoneName),
                _buildMoistureButton('60%', zoneName),
                _buildMoistureButton('80%', zoneName),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoistureButton(String level, String zoneName) {
    return ElevatedButton(
      onPressed: () {
        Navigator.pop(context);
        _showSnackBar('Moisture target set to $level for $zoneName');
      },
      child: Text(level),
    );
  }

  void _viewSchedule() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Irrigation Schedule'),
            backgroundColor: const Color(0xFF2196F3),
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildScheduleItem('Morning Session', '5:00 AM - 7:00 AM', zones[0]['name']),
              _buildScheduleItem('Afternoon Session', '2:00 PM - 4:00 PM', zones[1]['name']),
              _buildScheduleItem('Evening Session', '6:00 PM - 8:00 PM', 'All Zones'),
              const SizedBox(height: 20),
              const Divider(),
              const Text('Weekly Overview',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              _buildWeeklySchedule(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleItem(String session, String time, String zone) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const Icon(Icons.schedule, color: Color(0xFF155DFC)),
        title: Text(session),
        subtitle: Text('$time - $zone'),
        trailing: IconButton(
          icon: const Icon(Icons.edit, color: Colors.grey),
          onPressed: () => _showSnackBar('Edit $session schedule'),
        ),
      ),
    );
  }

  Widget _buildWeeklySchedule() {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return DataTable(
      columns: const [
        DataColumn(label: Text('Day')),
        DataColumn(label: Text('Sessions')),
        DataColumn(label: Text('Water Used')),
      ],
      rows: days.map((day) {
        return DataRow(cells: [
          DataCell(Text(day)),
          DataCell(const Text('2 sessions')),
          DataCell(Text('${(1000 + days.indexOf(day) * 150)}L')),
        ]);
      }).toList(),
    );
  }

  void _viewHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Irrigation History'),
            backgroundColor: const Color(0xFF2196F3),
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text('Water Usage History',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              _buildHistoryChart(),
              const SizedBox(height: 20),
              ...zones.map((zone) => _buildZoneHistory(zone)).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryChart() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: const Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Last 7 Days', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Total: 24,500L', style: TextStyle(color: Colors.green)),
            ],
          ),
          SizedBox(height: 20),
          // Simulated chart bars
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _ChartBar(height: 80, label: 'Mon'),
              _ChartBar(height: 100, label: 'Tue'),
              _ChartBar(height: 60, label: 'Wed'),
              _ChartBar(height: 120, label: 'Thu'),
              _ChartBar(height: 90, label: 'Fri'),
              _ChartBar(height: 110, label: 'Sat'),
              _ChartBar(height: 70, label: 'Sun'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildZoneHistory(Map<String, dynamic> zone) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFDBEAFE),
          child: Text(zone['name'].substring(0, 1)),
        ),
        title: Text(zone['name']),
        subtitle: Text('Last irrigated: Today, ${zone['schedule']}'),
        trailing: Text('${zone['moisture']}% moisture'),
        onTap: () => _showZoneHistoryDetails(zone['name']),
      ),
    );
  }

  void _showZoneHistoryDetails(String zoneName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'History: $zoneName',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildHistoryEntry('Today', '2,500L', '6:00 AM'),
            _buildHistoryEntry('Yesterday', '2,800L', '6:00 AM'),
            _buildHistoryEntry('2 days ago', '2,400L', '6:00 AM'),
            _buildHistoryEntry('3 days ago', '2,600L', '6:00 AM'),
            _buildHistoryEntry('4 days ago', '2,700L', '6:00 AM'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF155DFC),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryEntry(String date, String amount, String time) {
    return ListTile(
      leading: const Icon(Icons.water_drop, color: Color(0xFF155CFB)),
      title: Text(date),
      subtitle: Text('Irrigated at $time'),
      trailing: Text(amount, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.only(
                top: 24,
                left: 24,
                right: 24,
                bottom: 16,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF2196F3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                    spreadRadius: -2,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 4),
                    spreadRadius: -1,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'Water Optimization',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontFamily: 'Arimo',
                          fontWeight: FontWeight.w400,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Control irrigation by field location',
                        style: TextStyle(
                          color: Color(0xE5FFFEFE),
                          fontSize: 16,
                          fontFamily: 'Arimo',
                          fontWeight: FontWeight.w400,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Usage Statistics
                  _buildUsageStats(),
                  const SizedBox(height: 24),

                  // Irrigation Zones Header with Add Zone Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Irrigation Zones',
                        style: TextStyle(
                          color: Color(0xFF101727),
                          fontSize: 16,
                          fontFamily: 'Arimo',
                          fontWeight: FontWeight.w400,
                          height: 1.5,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _toggleAddZoneForm,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text(
                          'Add Zone',
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: 'Arimo',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF155DFC),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Add Zone Form (Conditional)
                  if (_showAddZoneForm) _buildAddZoneForm(),

                  // Existing Zones
                  ...zones.map((zone) => _buildZoneCard(zone)).toList(),

                  const SizedBox(height: 24),

                  // Smart Recommendations
                  _buildRecommendations(),
                  const SizedBox(height: 24),

                  // Action Buttons
                  _buildActionButtons(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageStats() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 13,
      mainAxisSpacing: 13,
      childAspectRatio: 1.4,
      children: [
        _buildStatCard(
          title: "Today's Usage",
          value: '1250L',
          change: '-12%',
          isPositive: true,
        ),
        _buildStatCard(
          title: 'This Week',
          value: '8500L',
          change: '-8%',
          isPositive: true,
        ),
        _buildStatCard(
          title: 'This Month',
          value: '35000L',
          change: '-15%',
          isPositive: true,
        ),
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2B7FFF), Color(0xFF155CFB)],
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 2,
                offset: const Offset(0, 1),
                spreadRadius: -1,
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Water Saved',
                style: TextStyle(
                  color: Color(0xE5FFFEFE),
                  fontSize: 16,
                  fontFamily: 'Arimo',
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                '15%',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontFamily: 'Arimo',
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'vs last month',
                style: TextStyle(
                  color: Color(0xCCFFFEFE),
                  fontSize: 16,
                  fontFamily: 'Arimo',
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String change,
    required bool isPositive,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
            spreadRadius: -1,
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF495565),
              fontSize: 16,
              fontFamily: 'Arimo',
              fontWeight: FontWeight.w400,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF101727),
              fontSize: 16,
              fontFamily: 'Arimo',
              fontWeight: FontWeight.w400,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                isPositive ? Icons.trending_down : Icons.trending_up,
                color: const Color(0xFF00A63E),
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                change,
                style: const TextStyle(
                  color: Color(0xFF00A63E),
                  fontSize: 16,
                  fontFamily: 'Arimo',
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddZoneForm() {
    return Container(
      padding: const EdgeInsets.all(17),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFBDDAFF), width: 1.3),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
            spreadRadius: -1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add New Irrigation Zone',
            style: TextStyle(
              color: Color(0xFF101727),
              fontSize: 16,
              fontFamily: 'Arimo',
              fontWeight: FontWeight.w400,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          _buildTextField('Zone Name', 'e.g., Rice Field - North', _zoneNameController),
          const SizedBox(height: 12),
          _buildTextField('Field Location', 'e.g., North Section, Field A', _locationController),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTextField('Water Amount (L)', '300', _waterAmountController),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField('Duration (min)', '60', _durationController),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSchedulePicker(),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _saveNewZone,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF155DFC),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Save Zone',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontFamily: 'Arimo',
                      fontWeight: FontWeight.w400,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _cancelAddZone,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD1D5DC),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Color(0xFF354152),
                      fontSize: 16,
                      fontFamily: 'Arimo',
                      fontWeight: FontWeight.w400,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, String hint, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF354152),
            fontSize: 16,
            fontFamily: 'Arimo',
            fontWeight: FontWeight.w400,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: Color(0x7F0A0A0A),
              fontSize: 16,
              fontFamily: 'Arimo',
              fontWeight: FontWeight.w400,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFD0D5DB), width: 1.3),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSchedulePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Schedule Time',
          style: TextStyle(
            color: Color(0xFF354152),
            fontSize: 16,
            fontFamily: 'Arimo',
            fontWeight: FontWeight.w400,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 4),
        ElevatedButton.icon(
          onPressed: () => _showTimePicker(),
          icon: const Icon(Icons.access_time),
          label: const Text('Select Time'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF354152),
            side: const BorderSide(color: Color(0xFFD0D5DB), width: 1.3),
            minimumSize: const Size(double.infinity, 50),
          ),
        ),
      ],
    );
  }

  void _showTimePicker() {
    showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    ).then((selectedTime) {
      if (selectedTime != null) {
        _showSnackBar('Schedule set to ${selectedTime.format(context)}');
      }
    });
  }

  Widget _buildZoneCard(Map<String, dynamic> zone) {
    final statusInfo = _getStatusInfo(zone['status']);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
            spreadRadius: -1,
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDBEAFE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.water_drop, color: Color(0xFF1447E6)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            zone['name'],
                            style: const TextStyle(
                              color: Color(0xFF101727),
                              fontSize: 16,
                              fontFamily: 'Arimo',
                              fontWeight: FontWeight.w400,
                              height: 1.5,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusInfo['bgColor'],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              statusInfo['text'],
                              style: TextStyle(
                                color: statusInfo['color'],
                                fontSize: 14,
                                fontFamily: 'Arimo',
                                fontWeight: FontWeight.w400,
                                height: 1.43,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16, color: Color(0xFF495565)),
                          const SizedBox(width: 8),
                          Text(
                            zone['location'],
                            style: const TextStyle(
                              color: Color(0xFF495565),
                              fontSize: 16,
                              fontFamily: 'Arimo',
                              fontWeight: FontWeight.w400,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Soil Moisture',
                                style: TextStyle(
                                  color: Color(0xFF495565),
                                  fontSize: 16,
                                  fontFamily: 'Arimo',
                                  fontWeight: FontWeight.w400,
                                  height: 1.5,
                                ),
                              ),
                              Text(
                                '${zone['moisture']}%',
                                style: const TextStyle(
                                  color: Color(0xFF101727),
                                  fontSize: 16,
                                  fontFamily: 'Arimo',
                                  fontWeight: FontWeight.w400,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE5E7EB),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: zone['moisture'] / 100,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _getMoistureColor(zone['moisture']),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 16, color: Color(0xFF495565)),
                          const SizedBox(width: 8),
                          Text(
                            zone['schedule'],
                            style: const TextStyle(
                              color: Color(0xFF495565),
                              fontSize: 16,
                              fontFamily: 'Arimo',
                              fontWeight: FontWeight.w400,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 1.3,
            color: const Color(0xFFE5E7EB),
          ),
          Padding(
            padding: const EdgeInsets.all(13.29),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: zone['isRunning']
                        ? () => _updateZoneStatus(zone['id'], 'stop')
                        : () => _updateZoneStatus(zone['id'], 'start'),
                    icon: Icon(zone['isRunning'] ? Icons.stop : Icons.play_arrow, size: 16),
                    label: Text(zone['isRunning'] ? 'Stop' : 'Start'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: zone['isRunning']
                          ? const Color(0xFFDCFCE7)
                          : const Color(0xFFF3F4F6),
                      foregroundColor: zone['isRunning']
                          ? const Color(0xFF008236)
                          : const Color(0xFF354152),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _updateZoneStatus(zone['id'], 'control'),
                    icon: const Icon(Icons.settings, size: 16),
                    label: const Text('Control'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDBEAFE),
                      foregroundColor: const Color(0xFF1447E6),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _updateZoneStatus(zone['id'], 'auto'),
                    icon: const Icon(Icons.autorenew, size: 16),
                    label: const Text('Auto'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF3E8FF),
                      foregroundColor: const Color(0xFF8200DA),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getStatusInfo(String status) {
    switch (status) {
      case 'active':
        return {
          'text': 'Active',
          'color': const Color(0xFF008236),
          'bgColor': const Color(0xFFDCFCE7),
        };
      case 'scheduled':
        return {
          'text': 'Scheduled',
          'color': const Color(0xFF1447E6),
          'bgColor': const Color(0xFFDBEAFE),
        };
      case 'paused':
        return {
          'text': 'Paused',
          'color': const Color(0xFFA65F00),
          'bgColor': const Color(0xFFFEF9C2),
        };
      default:
        return {
          'text': 'Inactive',
          'color': const Color(0xFF6B7280),
          'bgColor': const Color(0xFFF3F4F6),
        };
    }
  }

  Color _getMoistureColor(int moisture) {
    if (moisture >= 70) return const Color(0xFF00C950);
    if (moisture >= 50) return const Color(0xFF2B7FFF);
    return const Color(0xFFF0B100);
  }

  Widget _buildRecommendations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Smart Recommendations',
          style: TextStyle(
            color: Color(0xFF101727),
            fontSize: 16,
            fontFamily: 'Arimo',
            fontWeight: FontWeight.w400,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        _buildRecommendationCard(
          title: 'Reduce morning irrigation',
          description:
              'Weather forecast shows rain expected tomorrow. Consider reducing irrigation by 30%.',
          benefit: 'Save ~150L water',
        ),
        const SizedBox(height: 12),
        _buildRecommendationCard(
          title: 'Adjust West Field schedule',
          description:
              'Soil moisture is low in West Field. Recommend early irrigation today.',
          benefit: 'Improve crop health',
        ),
        const SizedBox(height: 12),
        _buildRecommendationCard(
          title: 'Optimize timing',
          description:
              'Irrigate early morning (5-7 AM) to minimize evaporation losses.',
          benefit: 'Save 10-15% water',
        ),
      ],
    );
  }

  Widget _buildRecommendationCard({
    required String title,
    required String description,
    required String benefit,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
            spreadRadius: -1,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline, color: Color(0xFFF59E0B), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF101727),
                    fontSize: 18,
                    fontFamily: 'Arimo',
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(
                    color: Color(0xFF354152),
                    fontSize: 16,
                    fontFamily: 'Arimo',
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    border: Border.all(color: const Color(0xFFB8F7CF), width: 1.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    benefit,
                    style: const TextStyle(
                      color: Color(0xFF008236),
                      fontSize: 16,
                      fontFamily: 'Arimo',
                      fontWeight: FontWeight.w400,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: _viewSchedule,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF155DFC),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text(
              'View Schedule',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontFamily: 'Arimo',
                fontWeight: FontWeight.w400,
                height: 1.5,
              ),
            ),
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: ElevatedButton(
            onPressed: _viewHistory,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFF155CFB), width: 1.3),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text(
              'View History',
              style: TextStyle(
                color: Color(0xFF155CFB),
                fontSize: 16,
                fontFamily: 'Arimo',
                fontWeight: FontWeight.w400,
                height: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ChartBar extends StatelessWidget {
  final double height;
  final String label;

  const _ChartBar({required this.height, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 30,
          height: height * 0.8,
          decoration: BoxDecoration(
            color: const Color(0xFF155DFC),
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}