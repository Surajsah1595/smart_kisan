import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'pest_disease_service.dart';
import 'ai_service.dart';

// For better logging visibility
void _log(String message) {
  debugPrint('🎯 PEST_DISEASE: $message');
}

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
class PestDiseaseHelpScreen extends StatefulWidget {
  const PestDiseaseHelpScreen({super.key});

  @override
  State<PestDiseaseHelpScreen> createState() => _PestDiseaseHelpScreenState();
}

class _PestDiseaseHelpScreenState extends State<PestDiseaseHelpScreen> {
  late final PestDiseaseService _pestDiseaseService = PestDiseaseService();

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
        StreamBuilder<List<PestAlertData>>(
          stream: _pestDiseaseService.getActiveAlerts(),
          initialData: const [],
          builder: (context, snapshot) {
            final alerts = snapshot.data ?? [];
            
            if (alerts.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'No active alerts. Your crops are looking healthy!',
                  style: TextStyle(color: Color(0xFF495565)),
                ),
              );
            }

            return Column(
              children: alerts.map((alert) {
                final severity = alert.severity;
                final Color severityColor;
                final Color severityBgColor;
                
                if (severity == 'High') {
                  severityColor = const Color(0xFFC10007);
                  severityBgColor = const Color(0xFFFFE2E2);
                } else if (severity == 'Medium') {
                  severityColor = const Color(0xFFA65F00);
                  severityBgColor = const Color(0xFFFEF9C2);
                } else {
                  severityColor = const Color(0xFF008236);
                  severityBgColor = const Color(0xFFE2FFFB);
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ActiveAlertItem(
                    title: alert.pestName,
                    subtitle: 'Pest • ${alert.cropName}',
                    description: alert.description,
                    treatment: alert.treatment,
                    severity: severity,
                    severityColor: severityColor,
                    severityBgColor: severityBgColor,
                    icon: Icons.bug_report,
                    iconBgColor: severityBgColor,
                    detectedDate: _formatDate(alert.detectedDate),
                    borderColor: const Color(0xFFFB2C36),
                    onTap: () => _showAlertDetails(context, alert),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentScansSection(BuildContext context) {
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
        StreamBuilder<List<PestScanData>>(
          stream: _pestDiseaseService.getRecentScans(limit: 5),
          initialData: const [],
          builder: (context, snapshot) {
            final scans = snapshot.data ?? [];

            if (scans.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'No scans yet. Start by scanning a crop!',
                  style: TextStyle(color: Color(0xFF495565)),
                ),
              );
            }

            return Column(
              children: scans.map((scan) {
                final Color statusColor;
                final IconData icon;
                final Color iconBgColor;
                final String displayStatus;

                if (scan.status == 'Healthy') {
                  statusColor = const Color(0xFF008236);
                  icon = Icons.agriculture;
                  iconBgColor = const Color(0xFFDCFCE7);
                  displayStatus = 'Healthy';
                } else if (scan.status == 'Disease Detected') {
                  statusColor = const Color(0xFFC10007);
                  icon = Icons.sick;
                  iconBgColor = const Color(0xFFFFE2E2);
                  displayStatus = 'Disease Detected';
                } else {
                  statusColor = const Color(0xFFA65F00);
                  icon = Icons.bug_report;
                  iconBgColor = const Color(0xFFFEF9C2);
                  displayStatus = 'Pest Alert';
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: RecentScanItem(
                    cropName: scan.cropName,
                    date: _formatDate(scan.scanDate),
                    status: displayStatus,
                    confidence: '${(scan.confidence * 100).toStringAsFixed(0)}% confidence',
                    statusColor: statusColor,
                    icon: icon,
                    iconBgColor: iconBgColor,
                    onTap: () => _showScanDetails(context, scan),
                  ),
                );
              }).toList(),
            );
          },
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
              _openCamera();
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

  void _openCamera() async {
    final ImagePicker picker = ImagePicker();
    try {
      _log('Opening camera...');
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      _log('Camera returned: ${photo != null ? "Image captured at ${photo.path}" : "No image (user cancelled)"}');
      
      if (photo != null) {
        _log('Processing image...');
        print('📸 DEBUG: photo.path = ${photo.path}');
        print('✅ DEBUG: About to call _showScanningDialog');
        if (!mounted) return;
        await _showScanningDialog(context, photo.path);
        print('✅ DEBUG: _showScanningDialog completed');
      } else {
        _log('No image selected');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No image selected')),
        );
      }
    } catch (e) {
      _log('Camera error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error accessing camera: $e')),
      );
    }
  }

  Future<void> _showScanningDialog(BuildContext context, String imagePath) async {
    _log('🔍 Showing scanning dialog for: $imagePath');
    print('🔍 DEBUG: _showScanningDialog START');
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        print('🔍 DEBUG: Dialog builder called');
        return Dialog(
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: Color(0xFFFB2C36)),
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
        );
      },
    );

    print('🔍 DEBUG: Dialog shown, about to call _analyzeCropWithAI');
    _log('🔍 Dialog shown, calling analysis...');
    
    try {
      await _analyzeCropWithAI(context, imagePath);
      print('🔍 DEBUG: _analyzeCropWithAI completed successfully');
    } catch (e) {
      print('❌ DEBUG: _analyzeCropWithAI threw error: $e');
      rethrow;
    }
  }

  Future<void> _analyzeCropWithAI(BuildContext context, String imagePath) async {
    try {
      print('🔍 DEBUG: _analyzeCropWithAI START');
      _log('🔍 [START] _analyzeCropWithAI called');
      _log('🔍 Image path: $imagePath');
      
      print('🔍 DEBUG: About to call analyzeImageWithAI');
      _log('🔍 About to call analyzeImageWithAI...');
      
      final result = await _pestDiseaseService.analyzeImageWithAI(imagePath);
      
      print('🔍 DEBUG: analyzeImageWithAI returned');
      _log('🔍 [DONE] analyzeImageWithAI returned');
      
      _log('🔍 Analysis result keys: ${result.keys.toList()}');
      _log('🔍 Status: ${result['status']}');
      
      if (!context.mounted) {
        print('❌ DEBUG: Context NOT mounted after analysis');
        _log('❌ Context NOT mounted after analysis');
        return;
      }
      
      print('✅ DEBUG: Context still mounted');
      _log('✅ Context still mounted');
      await Future.delayed(const Duration(milliseconds: 500));
      
      print('✅ DEBUG: About to pop dialog');
      Navigator.pop(context);
      _log('✅ Dialog closed, showing results');
      
      if (!context.mounted) {
        print('❌ DEBUG: Context lost after pop');
        _log('❌ Context lost');
        return;
      }
      
      print('✅ DEBUG: About to show results');
      _showScanResults(context, result);
      _log('✅ Results shown');
      
    } catch (e) {
      print('❌ DEBUG: _analyzeCropWithAI caught error: $e');
      _log('❌ ERROR: $e');
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showScanResults(BuildContext context, Map<String, dynamic> result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Scan Results'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Crop: ${result['cropName'] ?? 'Unknown'}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Status: ${result['status'] ?? 'Unknown'}'),
            const SizedBox(height: 8),
            Text('Confidence: ${(((result['confidence'] as num?)?.toDouble() ?? 0.0) * 100).toStringAsFixed(0)}%'),
            const SizedBox(height: 16),
            Text(
              result['description'] ?? 'Scan completed',
              style: TextStyle(
                color: result['status'] == 'Healthy' ? const Color(0xFF008236) : const Color(0xFFC10007),
              ),
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

  void _showAlertDetails(BuildContext context, PestAlertData alert) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(alert.pestName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Crop: ${alert.cropName}'),
            const SizedBox(height: 8),
            Text('Description: ${alert.description}'),
            const SizedBox(height: 8),
            Text('Severity: ${alert.severity}'),
            const SizedBox(height: 16),
            Text(
              'Treatment: ${alert.treatment}',
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
            onPressed: () async {
              Navigator.pop(context);
              await _pestDiseaseService.resolveAlert(alert.id);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Alert marked as resolved')),
              );
            },
            child: const Text('Mark Resolved'),
          ),
        ],
      ),
    );
  }

  void _showScanDetails(BuildContext context, PestScanData scan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${scan.cropName} Scan Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Date: ${_formatDate(scan.scanDate)}'),
            const SizedBox(height: 8),
            Text('Status: ${scan.status}'),
            const SizedBox(height: 8),
            Text('Confidence: ${(scan.confidence * 100).toStringAsFixed(0)}%'),
            const SizedBox(height: 16),
            Text('AI Response: ${scan.aiResponse}'),
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

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
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
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Searching for "$query"...'),
        content: const SizedBox(
          height: 100,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Color(0xFFFB2C36)),
                SizedBox(height: 16),
                Text('Fetching information...'),
              ],
            ),
          ),
        ),
      ),
    );

    _searchKnowledgeBase(context, query);
  }

  Future<void> _searchKnowledgeBase(BuildContext dialogContext, String query) async {
    try {
      print('🔍 Searching for: $query');
      
      final prompt = '''You are an agriculture expert. Provide SHORT and PRACTICAL information about: "$query"

If it's a pest or disease, include:
1. **What it is** (1 line)
2. **Symptoms** (2-3 bullet points)
3. **Treatment** (2-3 practical steps)
4. **Prevention** (1-2 tips)

Keep it SHORT and practical for farmers. Use bullet points and bold for important terms.''';

      final response = await AiService().sendMessage(prompt);
      
      print('✅ Search response received');
      
      // Use the page's context, not the dialog context
      if (!mounted) {
        print('❌ Widget no longer mounted');
        return;
      }

      // Close the loading dialog
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Information about "$query"'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (response != null && response.isNotEmpty)
                  MarkdownBody(
                    data: response,
                    selectable: true,
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(
                        fontSize: 14,
                        height: 1.6,
                      ),
                      strong: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF354152),
                      ),
                      em: const TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                      h1: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      h2: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      h3: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  const Text('No information found. Please try another search.'),
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
    } catch (e) {
      print('❌ Search error: $e');
      
      if (!mounted) return;
      
      // Close loading dialog if still open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}