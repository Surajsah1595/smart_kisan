import 'package:flutter/material.dart';

// Active Alert Item Widget (Separate class)
class ActiveAlertItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String description;
  final String treatment;
  final String severity;
  final Color severityColor;
  final Color severityBgColor;
  final IconData icon;
  final Color iconBgColor;
  final String detectedDate;
  final Color borderColor;
  final VoidCallback? onTap;

  const ActiveAlertItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.treatment,
    required this.severity,
    required this.severityColor,
    required this.severityBgColor,
    required this.icon,
    required this.iconBgColor,
    required this.detectedDate,
    required this.borderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border(
            left: BorderSide(color: borderColor, width: 4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 2,
              offset: const Offset(0, 1),
              spreadRadius: -1,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 3,
              offset: const Offset(0, 1),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: borderColor),
                  ),
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
                          ),
                        ),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: const Color(0xFF495565),
                            fontSize: 16,
                            fontFamily: 'Arimo',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: severityBgColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      severity,
                      style: TextStyle(
                        color: severityColor,
                        fontSize: 16,
                        fontFamily: 'Arimo',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(left: 48),
                child: Text(
                  description,
                  style: TextStyle(
                    color: const Color(0xFF354152),
                    fontSize: 16,
                    fontFamily: 'Arimo',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Treatment: ',
                      style: TextStyle(
                        color: const Color(0xFF101727),
                        fontSize: 16,
                        fontFamily: 'Arimo',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        treatment,
                        style: TextStyle(
                          color: const Color(0xFF354152),
                          fontSize: 16,
                          fontFamily: 'Arimo',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(left: 48),
                child: Text(
                  'Detected: $detectedDate',
                  style: TextStyle(
                    color: const Color(0xFF495565),
                    fontSize: 16,
                    fontFamily: 'Arimo',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Recent Scan Item Widget (Separate class)
class RecentScanItem extends StatelessWidget {
  final String cropName;
  final String date;
  final String status;
  final String confidence;
  final Color statusColor;
  final IconData icon;
  final Color iconBgColor;
  final VoidCallback? onTap;

  const RecentScanItem({
    super.key,
    required this.cropName,
    required this.date,
    required this.status,
    required this.confidence,
    required this.statusColor,
    required this.icon,
    required this.iconBgColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 3,
              offset: const Offset(0, 1),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: statusColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cropName,
                      style: const TextStyle(
                        color: Color(0xFF101727),
                        fontSize: 18,
                        fontFamily: 'Arimo',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    Text(
                      date,
                      style: TextStyle(
                        color: const Color(0xFF495565),
                        fontSize: 16,
                        fontFamily: 'Arimo',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 16,
                      fontFamily: 'Arimo',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  Text(
                    confidence,
                    style: TextStyle(
                      color: const Color(0xFF495565),
                      fontSize: 16,
                      fontFamily: 'Arimo',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Main Pest Disease Help Screen
class PestDiseaseHelpScreen extends StatelessWidget {
  const PestDiseaseHelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFFFB2C36),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'Pest & Disease Help',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontFamily: 'Arimo',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      Icon(Icons.bug_report, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Early detection and treatment guidance',
                        style: TextStyle(
                          color: Color(0xE5FFFEFE),
                          fontSize: 16,
                          fontFamily: 'Arimo',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Scan Crop Section
                    _buildScanCropSection(context),
                    const SizedBox(height: 24),
                    // Active Alerts Section
                    _buildActiveAlertsSection(context),
                    const SizedBox(height: 24),
                    // Recent Scans Section
                    _buildRecentScansSection(context),
                    const SizedBox(height: 24),
                    // Prevention Tips Section
                    _buildPreventionTipsSection(),
                    const SizedBox(height: 24),
                    // Search Knowledge Base
                    _buildSearchKnowledgeSection(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanCropSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFB2C36), Color(0xFFE7000B)],
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Scan Your Crop',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontFamily: 'Arimo',
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Use your camera to identify pests and diseases',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                    fontFamily: 'Arimo',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: () => _showScanDialog(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Row(
              children: [
                const Icon(Icons.camera_alt, color: Color(0xFFFB2C36)),
                const SizedBox(width: 8),
                Text(
                  'Scan Now',
                  style: TextStyle(
                    color: const Color(0xFFFB2C36),
                    fontSize: 16,
                    fontFamily: 'Arimo',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveAlertsSection(BuildContext context) {
    final activeAlerts = [
      {
        'title': 'Aphids',
        'subtitle': 'Pest • Wheat',
        'description': 'Small green insects on leaf undersides',
        'treatment': 'Apply neem oil spray or introduce ladybugs',
        'severity': 'Medium',
        'severityColor': const Color(0xFFA65F00),
        'severityBgColor': const Color(0xFFFEF9C2),
        'icon': Icons.bug_report,
        'iconBgColor': const Color(0xFFFEF9C2),
        'detectedDate': '2024-12-14',
        'borderColor': const Color(0xFFFB2C36),
      },
      {
        'title': 'Leaf Blight',
        'subtitle': 'Disease • Rice',
        'description': 'Brown spots spreading on leaves',
        'treatment': 'Remove affected leaves and apply fungicide',
        'severity': 'High',
        'severityColor': const Color(0xFFC10007),
        'severityBgColor': const Color(0xFFFFE2E2),
        'icon': Icons.sick,
        'iconBgColor': const Color(0xFFFFE2E2),
        'detectedDate': '2024-12-13',
        'borderColor': const Color(0xFFFB2C36),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Active Alerts',
          style: TextStyle(
            color: Color(0xFF101727),
            fontSize: 16,
            fontFamily: 'Arimo',
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 16),
        Column(
          children: activeAlerts.map((alert) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ActiveAlertItem(
                title: alert['title'] as String,
                subtitle: alert['subtitle'] as String,
                description: alert['description'] as String,
                treatment: alert['treatment'] as String,
                severity: alert['severity'] as String,
                severityColor: alert['severityColor'] as Color,
                severityBgColor: alert['severityBgColor'] as Color,
                icon: alert['icon'] as IconData,
                iconBgColor: alert['iconBgColor'] as Color,
                detectedDate: alert['detectedDate'] as String,
                borderColor: alert['borderColor'] as Color,
                onTap: () => _showAlertDetails(context, alert),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRecentScansSection(BuildContext context) {
    final recentScans = [
      {
        'cropName': 'Corn',
        'date': '2024-12-15',
        'status': 'Healthy',
        'confidence': '95% confidence',
        'statusColor': const Color(0xFF008236),
        'icon': Icons.agriculture,
        'iconBgColor': const Color(0xFFDCFCE7),
      },
      {
        'cropName': 'Rice',
        'date': '2024-12-14',
        'status': 'Disease Detected',
        'confidence': '88% confidence',
        'statusColor': const Color(0xFFC10007),
        'icon': Icons.sick,
        'iconBgColor': const Color(0xFFFFE2E2),
      },
      {
        'cropName': 'Wheat',
        'date': '2024-12-14',
        'status': 'Pest Alert',
        'confidence': '82% confidence',
        'statusColor': const Color(0xFFC10007),
        'icon': Icons.bug_report,
        'iconBgColor': const Color(0xFFFFE2E2),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Scans',
          style: TextStyle(
            color: Color(0xFF101727),
            fontSize: 16,
            fontFamily: 'Arimo',
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 16),
        Column(
          children: recentScans.map((scan) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: RecentScanItem(
                cropName: scan['cropName'] as String,
                date: scan['date'] as String,
                status: scan['status'] as String,
                confidence: scan['confidence'] as String,
                statusColor: scan['statusColor'] as Color,
                icon: scan['icon'] as IconData,
                iconBgColor: scan['iconBgColor'] as Color,
                onTap: () => _showScanDetails(context, scan),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPreventionTipsSection() {
    final preventionTips = [
      'Regular field inspections to catch issues early',
      'Crop rotation to prevent pest buildup',
      'Maintain proper plant spacing for air circulation',
      'Remove plant debris to reduce disease habitat',
      'Use disease-resistant crop varieties when available',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Prevention Tips',
          style: TextStyle(
            color: Color(0xFF101727),
            fontSize: 16,
            fontFamily: 'Arimo',
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 16),
        Container(
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
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 3,
                offset: const Offset(0, 1),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            children: preventionTips.map((tip) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle, size: 16, color: Color(0xFF008236)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        tip,
                        style: TextStyle(
                          color: const Color(0xFF354152),
                          fontSize: 16,
                          fontFamily: 'Arimo',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchKnowledgeSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF2F4F6), Color(0xFFE5E7EB)],
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, size: 24, color: Color(0xFF354152)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Search Knowledge Base',
                  style: TextStyle(
                    color: Color(0xFF101727),
                    fontSize: 18,
                    fontFamily: 'Arimo',
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Text(
                  'Find information about pests and diseases',
                  style: TextStyle(
                    color: const Color(0xFF495565),
                    fontSize: 16,
                    fontFamily: 'Arimo',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () => _showSearchDialog(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFB2C36),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              'Search',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontFamily: 'Arimo',
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Dialog Methods
  void _showScanDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Scan Your Crop'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('This feature will open your camera to scan crops for pests and diseases.'),
            SizedBox(height: 16),
            Text('Make sure to:'),
            Text('1. Focus on the affected area'),
            Text('2. Use good lighting'),
            Text('3. Keep camera steady'),
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
              _showScanningDialog(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFB2C36),
            ),
            child: const Text('Open Camera'),
          ),
        ],
      ),
    );
  }

  void _showScanningDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: const Color(0xFFFB2C36)),
              const SizedBox(height: 16),
              const Text(
                'Analyzing crop image...',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Arimo',
                ),
              ),
            ],
          ),
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context);
      _showScanResults(context);
    });
  }

  void _showScanResults(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Scan Results'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Crop: Tomato', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Status: Healthy'),
            SizedBox(height: 8),
            Text('Confidence: 92%'),
            SizedBox(height: 16),
            Text('No pests or diseases detected. Continue regular monitoring.', style: TextStyle(color: Color(0xFF008236))),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Scan saved to history')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFB2C36)),
            child: const Text('Save Result'),
          ),
        ],
      ),
    );
  }

  void _showAlertDetails(BuildContext context, Map<String, dynamic> alert) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(alert['title'] as String),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Crop: ${alert['subtitle']}'),
            const SizedBox(height: 8),
            Text('Description: ${alert['description']}'),
            const SizedBox(height: 8),
            Text('Severity: ${alert['severity']}'),
            const SizedBox(height: 16),
            Text(
              'Treatment: ${alert['treatment']}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Treatment guide opened')),
              );
            },
            child: const Text('View Treatment'),
          ),
        ],
      ),
    );
  }

  void _showScanDetails(BuildContext context, Map<String, dynamic> scan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${scan['cropName']} Scan Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Date: ${scan['date']}'),
            const SizedBox(height: 8),
            Text('Status: ${scan['status']}'),
            const SizedBox(height: 8),
            Text('Confidence: ${scan['confidence']}'),
            const SizedBox(height: 16),
            const Text('Tap to view detailed analysis and recommendations.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Detailed analysis opened')),
              );
            },
            child: const Text('View Details'),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog(BuildContext context) {
    final TextEditingController searchController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Knowledge Base'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: searchController,
              decoration: const InputDecoration(
                labelText: 'Search for pests and diseases',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Enter keywords like "aphids", "leaf blight", "corn diseases", etc.',
              style: TextStyle(fontSize: 14),
            ),
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
              _performSearch(context, searchController.text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFB2C36)),
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  void _performSearch(BuildContext context, String query) {
    if (query.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a search term')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Search Results for "$query"'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.bug_report, color: Color(0xFFFB2C36)),
                title: const Text('Aphid Management'),
                subtitle: const Text('Comprehensive guide for aphid control'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Opening aphid guide')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.local_florist, color: Color(0xFF008236)),
                title: const Text('Disease Prevention'),
                subtitle: const Text('Best practices for crop health'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Opening prevention guide')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.agriculture, color: Color(0xFFA65F00)),
                title: const Text('Integrated Pest Management'),
                subtitle: const Text('Sustainable pest control methods'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Opening IPM guide')),
                  );
                },
              ),
            ],
          ),
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
}