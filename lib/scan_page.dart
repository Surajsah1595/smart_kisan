// scan_page.dart
import 'package:flutter/material.dart';
import 'home_page.dart'; // For navigation back to home

class ScanPage extends StatefulWidget {
  final bool isNewUser;

  const ScanPage({Key? key, this.isNewUser = false}) : super(key: key);

  @override
  _ScanPageState createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final Color _primaryGreen = const Color(0xFF2C7C48);
  final Color _lightGreen = const Color(0xFFDBFBE6);
  final Color _accentGreen = const Color(0xFF00C950);
  final Color _darkGreen = const Color(0xFF008236);
  final Color _white = Colors.white;
  final Color _darkGray = const Color(0xFF101727);
  final Color _mediumGray = const Color(0xFF697282);
  final Color _warningYellow = const Color(0xFFF0B100);
  final Color _warningOrange = const Color(0xFFA65F00);
  final Color _errorRed = const Color(0xFFC10007);
  final Color _infoBlue = const Color(0xFF2B7FFF);
  final Color _darkBlue = const Color(0xFF1B388E);

  // Sample data for recent scans
  final List<Map<String, dynamic>> _recentScans = [
    {
      'crop': 'Rice',
      'time': 'Today, 2:30 PM',
      'status': 'HEALTHY',
      'statusColor': const Color(0xFF008236),
      'bgColor': const Color(0xFFDCFCE7),
      'diagnosis': 'Healthy',
      'confidence': 95,
      'progressColor': const Color(0xFF00C950),
    },
    {
      'crop': 'Wheat',
      'time': 'Yesterday, 10:15 AM',
      'status': 'WARNING',
      'statusColor': const Color(0xFFA65F00),
      'bgColor': const Color(0xFFFEF9C2),
      'diagnosis': 'Pest Detected: Aphids',
      'confidence': 87,
      'progressColor': const Color(0xFFF0B100),
    },
    {
      'crop': 'Corn',
      'time': 'Dec 13, 4:20 PM',
      'status': 'ALERT',
      'statusColor': const Color(0xFFC10007),
      'bgColor': const Color(0xFFFFE2E2),
      'diagnosis': 'Disease: Leaf Blight',
      'confidence': 92,
      'progressColor': const Color(0xFF00C950),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header Section
              _buildHeader(),
              
              // Stats Section
              _buildStatsSection(),
              
              // Start New Scan Section
              _buildNewScanSection(),
              
              // Tips Section
              _buildTipsSection(),
              
              // Recent Scans Section
              _buildRecentScansSection(),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 24, left: 24, right: 24, bottom: 24),
      decoration: BoxDecoration(
        color: _primaryGreen,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(10),
          bottomRight: Radius.circular(10),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back Button and Title Row
          Row(
            children: [
              // Back Button
              GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => HomePage()),
                  );
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Scan Crop',
                      style: TextStyle(
                        color: _white,
                        fontSize: 24,
                        fontFamily: 'Arimo',
                        fontWeight: FontWeight.w400,
                        height: 1.33,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'AI-powered disease & pest detection',
                      style: TextStyle(
                        color: _lightGreen,
                        fontSize: 14,
                        fontFamily: 'Arimo',
                        fontWeight: FontWeight.w400,
                        height: 1.43,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 24),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          width: 1.27,
          color: const Color.fromARGB(75, 2, 175, 2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatItem('24', 'Total Scans'),
          _buildStatItem('18', 'Healthy'),
          _buildStatItem('6', 'Issues Found'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: _primaryGreen,
              fontSize: 24,
              fontFamily: 'Arimo',
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: _primaryGreen,
              fontSize: 12,
              fontFamily: 'Arimo',
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewScanSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Start New Scan',
            style: TextStyle(
              color: _darkGray,
              fontSize: 16,
              fontFamily: 'Arimo',
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildScanOption(
                  title: 'Take Photo',
                  subtitle: 'Use camera',
                  color: _primaryGreen,
                  textColor: _white,
                  icon: Icons.camera_alt,
                  onTap: () => _handleCameraScan(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildScanOption(
                  title: 'Upload Image',
                  subtitle: 'From gallery',
                  color: _white,
                  textColor: _primaryGreen,
                  icon: Icons.upload,
                  onTap: () => _handleGalleryUpload(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScanOption({
    required String title,
    required String subtitle,
    required Color color,
    required Color textColor,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 160,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
          border: color == _white ? Border.all(color: _primaryGreen, width: 1.27) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: 32),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontFamily: 'Arimo',
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor.withOpacity(0.8),
                fontSize: 12,
                fontFamily: 'Arimo',
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          width: 3.82,
          color: _infoBlue,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How to get best results',
            style: TextStyle(
              color: _darkBlue,
              fontSize: 14,
              fontFamily: 'Arimo',
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 8),
          _buildTip('• Take clear, well-lit photos'),
          _buildTip('• Focus on affected areas'),
          _buildTip('• Include whole leaf when possible'),
          _buildTip('• Avoid blurry or dark images'),
        ],
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        text,
        style: TextStyle(
          color: const Color(0xFF1447E6),
          fontSize: 12,
          fontFamily: 'Arimo',
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  Widget _buildRecentScansSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Scans',
                style: TextStyle(
                  color: _darkGray,
                  fontSize: 16,
                  fontFamily: 'Arimo',
                  fontWeight: FontWeight.w400,
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.more_horiz, color: Color(0xFF697282)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (widget.isNewUser || _recentScans.isEmpty)
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: _white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                children: [
                  Icon(Icons.photo_camera_back, color: _mediumGray.withOpacity(0.5), size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'No scans yet',
                    style: TextStyle(
                      color: _darkGray,
                      fontSize: 16,
                      fontFamily: 'Arimo',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start by taking a photo or uploading an image',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _mediumGray,
                      fontSize: 14,
                      fontFamily: 'Arimo',
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: _recentScans.map((scan) => _buildScanCard(scan)).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildScanCard(Map<String, dynamic> scan) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
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
          // Image/Icon Placeholder
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: scan['bgColor'],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.eco, color: scan['statusColor'], size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and Status Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      scan['crop'],
                      style: TextStyle(
                        color: _darkGray,
                        fontSize: 16,
                        fontFamily: 'Arimo',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: scan['bgColor'],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        scan['status'],
                        style: TextStyle(
                          color: scan['statusColor'],
                          fontSize: 12,
                          fontFamily: 'Arimo',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  scan['time'],
                  style: TextStyle(
                    color: _mediumGray,
                    fontSize: 12,
                    fontFamily: 'Arimo',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  scan['diagnosis'],
                  style: TextStyle(
                    color: scan['statusColor'],
                    fontSize: 14,
                    fontFamily: 'Arimo',
                  ),
                ),
                const SizedBox(height: 8),
                // Confidence Bar
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5E7EB),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: scan['confidence'] / 100,
                          child: Container(
                            decoration: BoxDecoration(
                              color: scan['progressColor'],
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${scan['confidence']}%',
                      style: TextStyle(
                        color: _mediumGray,
                        fontSize: 12,
                        fontFamily: 'Arimo',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // View Details Button
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () => _viewScanDetails(scan),
                    child: Text(
                      'View Details →',
                      style: TextStyle(
                        color: _primaryGreen,
                        fontSize: 12,
                        fontFamily: 'Arimo',
                        fontWeight: FontWeight.w400,
                      ),
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

  // ============== Event Handlers ==============

  void _handleCameraScan() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Camera Access',
          style: TextStyle(
            color: _primaryGreen,
            fontFamily: 'Arimo',
          ),
        ),
        content: Text(
          'This feature will open the camera for scanning in the next phase.\n\nYou can take photos of crops for disease detection.',
          style: TextStyle(
            fontFamily: 'Arimo',
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey,
                fontFamily: 'Arimo',
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Add your camera logic here
            },
            child: Text(
              'Open Camera',
              style: TextStyle(
                color: _primaryGreen,
                fontFamily: 'Arimo',
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleGalleryUpload() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Upload Image',
          style: TextStyle(
            color: _primaryGreen,
            fontFamily: 'Arimo',
          ),
        ),
        content: Text(
          'This feature will open the gallery for image selection in the next phase.\n\nYou can upload crop photos for analysis.',
          style: TextStyle(
            fontFamily: 'Arimo',
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey,
                fontFamily: 'Arimo',
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Add your gallery picker logic here
            },
            child: Text(
              'Choose Image',
              style: TextStyle(
                color: _primaryGreen,
                fontFamily: 'Arimo',
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _viewScanDetails(Map<String, dynamic> scan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Scan Details',
          style: TextStyle(
            color: _primaryGreen,
            fontFamily: 'Arimo',
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Crop: ${scan['crop']}',
              style: const TextStyle(fontFamily: 'Arimo', fontSize: 14),
            ),
            Text(
              'Time: ${scan['time']}',
              style: const TextStyle(fontFamily: 'Arimo', fontSize: 14),
            ),
            Text(
              'Status: ${scan['status']}',
              style: TextStyle(
                fontFamily: 'Arimo',
                fontSize: 14,
                color: scan['statusColor'],
              ),
            ),
            Text(
              'Diagnosis: ${scan['diagnosis']}',
              style: const TextStyle(fontFamily: 'Arimo', fontSize: 14),
            ),
            Text(
              'Confidence: ${scan['confidence']}%',
              style: const TextStyle(fontFamily: 'Arimo', fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(
                color: _primaryGreen,
                fontFamily: 'Arimo',
              ),
            ),
          ),
        ],
      ),
    );
  }
}