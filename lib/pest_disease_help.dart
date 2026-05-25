import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'dart:convert';
import 'pest_disease_service.dart';
import 'ai_service.dart';
import 'notification_service.dart';
import 'localization_service.dart';

// For better logging visibility
void _log(String message) {
  debugPrint(' PEST_DISEASE: $message');
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
  final List<dynamic> productRecommendations;
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
    required this.productRecommendations,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(10),
          border: Border(
            left: BorderSide(color: borderColor, width: 4),
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withOpacity(0.1),
              blurRadius: 2,
              offset: const Offset(0, 1),
              spreadRadius: -1,
            ),
            BoxShadow(
              color: Theme.of(context).shadowColor.withOpacity(0.1),
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
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                            fontSize: 18,
                            fontFamily: 'Arimo',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyMedium?.color,
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
                  style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color,
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
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(LocalizationService.translate('Treatment: '),
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        fontSize: 16,
                        fontFamily: 'Arimo',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        treatment,
                        style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color,
                          fontSize: 16,
                          fontFamily: 'Arimo',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Product Recommendations Preview
              if (productRecommendations.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.shopping_bag, size: 16, color: Theme.of(context).colorScheme.primary),
                          SizedBox(width: 8),
                          Text(LocalizationService.translate('Recommended Products'),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getProductsPreview(),
                        style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color,
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(left: 48),
                child: Text(
                  'Detected: $detectedDate',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
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

  String _getProductsPreview() {
    if (productRecommendations.isEmpty) return '';
    
    List<String> productNames = [];
    for (var product in productRecommendations.take(2)) {
      if (product is Map<String, dynamic>) {
        productNames.add(product['productName'] ?? 'Product');
      } else if (product.runtimeType.toString().contains('ProductRecommendation')) {
        productNames.add(product.productName ?? 'Product');
      }
    }
    
    String preview = productNames.join(', ');
    if (productRecommendations.length > 2) {
      preview += ' +${productRecommendations.length - 2} more';
    }
    return preview;
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
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withOpacity(0.1),
              blurRadius: 2,
              offset: const Offset(0, 1),
              spreadRadius: -1,
            ),
            BoxShadow(
              color: Theme.of(context).shadowColor.withOpacity(0.1),
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
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        fontSize: 18,
                        fontFamily: 'Arimo',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    Text(
                      date,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color,
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
                      color: Theme.of(context).textTheme.bodyMedium?.color,
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).shadowColor.withOpacity(0.1),
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
                        icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onPrimary),
                      ),
                      SizedBox(width: 16),
                      Text(LocalizationService.translate('Pest & Disease Help'),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary, fontSize: 24,
                          fontFamily: 'Arimo',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.bug_report, color: Theme.of(context).colorScheme.onPrimary, size: 20),
                      SizedBox(width: 8),
                      Text(LocalizationService.translate('Early detection and treatment guidance'),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
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
        gradient: LinearGradient(
          colors: [Theme.of(context).colorScheme.surface, Theme.of(context).colorScheme.surface],
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
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
                Text(LocalizationService.translate('Scan Your Crop'),
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 20,
                    fontFamily: 'Arimo',
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 8),
                Text(LocalizationService.translate('Use your camera to identify pests and diseases'),
                  style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color,
                    fontSize: 16,
                    fontFamily: 'Arimo',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 16),
          ElevatedButton(
            onPressed: () => _showScanDialog(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Row(
              children: [
                Icon(Icons.camera_alt, color: Theme.of(context).colorScheme.onPrimary),
                SizedBox(width: 8),
                Text(LocalizationService.translate('Scan Now'),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
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
        Text(LocalizationService.translate('Active Alerts'),
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
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
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(LocalizationService.translate('No active alerts. Your crops are looking healthy!'),
                  style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                ),
              );
            }

            return Column(
              children: alerts.map((alert) {
                final severity = alert.severity;
                final Color severityColor;
                final Color severityBgColor;
                
                if (severity == 'High') {
                  severityColor = Theme.of(context).colorScheme.error;
                  severityBgColor = Theme.of(context).colorScheme.error.withOpacity(0.1);
                } else if (severity == 'Medium') {
                  severityColor = Theme.of(context).colorScheme.secondary;
                  severityBgColor = Theme.of(context).colorScheme.secondary.withOpacity(0.1);
                } else {
                  severityColor = Theme.of(context).colorScheme.primary;
                  severityBgColor = Theme.of(context).colorScheme.primary.withOpacity(0.1);
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
                    borderColor: Theme.of(context).colorScheme.error,
                    productRecommendations: alert.productRecommendations,
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
        Text(LocalizationService.translate('Recent Scans'),
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
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
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(LocalizationService.translate('No scans yet. Start by scanning a crop!'),
                  style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
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
                  statusColor = Theme.of(context).colorScheme.primary;
                  icon = Icons.agriculture;
                  iconBgColor = Theme.of(context).colorScheme.primary.withOpacity(0.1);
                  displayStatus = 'Healthy';
                } else if (scan.status == 'Disease Detected') {
                  statusColor = Theme.of(context).colorScheme.error;
                  icon = Icons.sick;
                  iconBgColor = Theme.of(context).colorScheme.error.withOpacity(0.1);
                  displayStatus = 'Disease Detected';
                } else {
                  statusColor = Theme.of(context).colorScheme.secondary;
                  icon = Icons.bug_report;
                  iconBgColor = Theme.of(context).colorScheme.secondary.withOpacity(0.1);
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
        Text(LocalizationService.translate('Prevention Tips'),
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontSize: 16,
            fontFamily: 'Arimo',
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).shadowColor.withOpacity(0.1),
                blurRadius: 2,
                offset: const Offset(0, 1),
                spreadRadius: -1,
              ),
              BoxShadow(
                color: Theme.of(context).shadowColor.withOpacity(0.1),
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
                    Icon(Icons.check_circle, size: 16, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        tip,
                        style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color,
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
        gradient: LinearGradient(
          colors: [Theme.of(context).cardColor, Theme.of(context).cardColor],
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.search, size: 24, color: Theme.of(context).textTheme.bodyMedium?.color),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(LocalizationService.translate('Search Knowledge Base'),
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontSize: 18,
                    fontFamily: 'Arimo',
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Text(LocalizationService.translate('Find information about pests and diseases'),
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
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
              
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(
              LocalizationService.translate('Search'),
              style: TextStyle(
                color: Theme.of(context).cardColor,
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
        title: Text(LocalizationService.translate('Scan Your Crop')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(LocalizationService.translate('This feature will open your camera to scan crops for pests and diseases.')),
            SizedBox(height: 16),
            Text(LocalizationService.translate('Make sure to:')),
            Text(LocalizationService.translate('1. Focus on the affected area')),
            Text(LocalizationService.translate('2. Use good lighting')),
            Text(LocalizationService.translate('3. Keep camera steady')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(LocalizationService.translate('Cancel')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _openGallery();
            },
            child: Text(LocalizationService.translate('Upload Image')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _openCamera();
            },
            style: ElevatedButton.styleFrom(
              
            ),
            child: Text(LocalizationService.translate('Open Camera')),
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
        print(' DEBUG: photo.path = ${photo.path}');
        if (!mounted) return;

        // Attempt to upload image to Firebase Storage and pass URL to analysis
        String? uploadedUrl;
        try {
          uploadedUrl = await _pestDiseaseService.uploadImageToStorage(photo.path);
        } catch (e) {
          print(' Upload failed, continuing without imageUrl: $e');
        }

        print(' DEBUG: About to call _showScanningDialog');
        await _showScanningDialog(context, photo.path, imageUrl: uploadedUrl);
        print(' DEBUG: _showScanningDialog completed');
      } else {
        _log('No image selected');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(LocalizationService.translate('No image selected'))),
        );
      }
    } catch (e) {
      _log('Camera error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${LocalizationService.translate('Error accessing camera:')} $e')),
      );
    }
  }

  void _openGallery() async {
    final ImagePicker picker = ImagePicker();
    try {
      _log('Opening gallery...');
      final XFile? photo = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      _log('Gallery returned: ${photo != null ? "Image selected at ${photo.path}" : "No image (user cancelled)"}');

      if (photo != null) {
        if (!mounted) return;

        String? uploadedUrl;
        try {
          uploadedUrl = await _pestDiseaseService.uploadImageToStorage(photo.path);
        } catch (e) {
          print(' Upload failed, continuing without imageUrl: $e');
        }

        await _showScanningDialog(context, photo.path, imageUrl: uploadedUrl);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(LocalizationService.translate('No image selected'))),
        );
      }
    } catch (e) {
      print(' Gallery error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${LocalizationService.translate('Error accessing gallery:')} $e')),
      );
    }
  }

  Future<void> _showScanningDialog(BuildContext context, String imagePath, {String? imageUrl}) async {
    _log(' Showing scanning dialog for: $imagePath');
    print(' DEBUG: _showScanningDialog START');
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        print(' DEBUG: Dialog builder called');
        return Dialog(
          child: Container(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
                SizedBox(height: 16),
                Text(LocalizationService.translate('Analyzing crop image...'),
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

    print(' DEBUG: Dialog shown, about to call _analyzeCropWithAI');
    _log(' Dialog shown, calling analysis...');
    
    try {
      await _analyzeCropWithAI(context, imagePath, imageUrl: imageUrl);
      print(' DEBUG: _analyzeCropWithAI completed successfully');
    } catch (e) {
      print(' DEBUG: _analyzeCropWithAI threw error: $e');
      rethrow;
    }
  }

  Future<void> _analyzeCropWithAI(BuildContext context, String imagePath, {String? imageUrl}) async {
    try {
      print(' DEBUG: _analyzeCropWithAI START');
      _log(' [START] _analyzeCropWithAI called');
      _log(' Image path: $imagePath');
      
      print(' DEBUG: About to call analyzeImageWithAI');
      _log(' About to call analyzeImageWithAI...');
      
      final result = await _pestDiseaseService.analyzeImageWithAI(imagePath, imageUrl: imageUrl);
      
      print(' DEBUG: analyzeImageWithAI returned');
      _log(' [DONE] analyzeImageWithAI returned');
      
      _log(' Analysis result keys: ${result.keys.toList()}');
      _log(' Status: ${result['status']}');
      
      if (!context.mounted) {
        print(' DEBUG: Context NOT mounted after analysis');
        _log(' Context NOT mounted after analysis');
        return;
      }
      
      print(' DEBUG: Context still mounted');
      _log(' Context still mounted');
      await Future.delayed(const Duration(milliseconds: 500));
      
      print(' DEBUG: About to pop dialog');
      Navigator.pop(context);
      _log(' Dialog closed, showing results');
      
      if (!context.mounted) {
        print(' DEBUG: Context lost after pop');
        _log(' Context lost');
        return;
      }
      
      print(' DEBUG: About to show results');
      _showScanResults(context, result);
      _log(' Results shown');
      
    } catch (e) {
      print(' DEBUG: _analyzeCropWithAI caught error: $e');
      _log(' ERROR: $e');
      if (context.mounted) {
        Navigator.pop(context); // Close the scanning dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(LocalizationService.translate('Error')),
            content: Text(LocalizationService.translate('AI service temporarily unavailable. Please try again.')),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(LocalizationService.translate('OK')),
              ),
            ],
          ),
        );
      }
    }
  }

  void _showScanResults(BuildContext context, Map<String, dynamic> result) {
    // Determine color based on status
    Color descriptionColor = Theme.of(context).colorScheme.primary; // Default green for healthy
    
    final status = result['status'] ?? 'Unknown';
    if (status == 'Healthy') {
      descriptionColor = Theme.of(context).colorScheme.primary; // Green
    } else if (status == 'Not a Plant') {
      descriptionColor = Theme.of(context).colorScheme.error; // Red
    } else if (status == 'Pest Alert' || status == 'Disease Detected') {
      descriptionColor = Theme.of(context).colorScheme.secondary; // Orange
    } else {
      descriptionColor = Theme.of(context).colorScheme.error; // Red for errors
    }

    // Get product recommendations if pest/disease is detected
    final pestName = result['pestName'];
    final recommendations = (pestName != null && pestName.toString().isNotEmpty)
        ? _pestDiseaseService.getProductRecommendations(pestName.toString())
        : <dynamic>[];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(LocalizationService.translate('Scan Results')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(LocalizationService.translate('Crop:') + ' ${result['cropName'] ?? LocalizationService.translate('Unknown')}', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(LocalizationService.translate('Status:') + ' ${result['status'] ?? LocalizationService.translate('Unknown')}'),
              const SizedBox(height: 8),
              Text(LocalizationService.translate('Confidence:') + ' ${(((result['confidence'] as num?)?.toDouble() ?? 0.0) * 100).toStringAsFixed(0)}%'),
              const SizedBox(height: 16),
              Text(
                result['description'] ?? 'Scan completed',
                style: TextStyle(
                  color: descriptionColor,
                ),
              ),
              // Product Recommendations Section
              if (recommendations.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  LocalizationService.translate(' Recommended Products:'),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
                ...recommendations.take(3).map((product) => _buildProductCard(product)),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(LocalizationService.translate('Close')),
          ),
          if (status != 'Not a Plant')
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(LocalizationService.translate('Scan saved to history'))),
                );
              },
              style: ElevatedButton.styleFrom(),
              child: Text(LocalizationService.translate('Save Result')),
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
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Crop Info
              Row(
                children: [
                      Text(LocalizationService.translate('Crop:'), style: const TextStyle(fontWeight: FontWeight.bold)),
                  Expanded(child: Text(alert.cropName)),
                ],
              ),
              const SizedBox(height: 12),
              
              // Severity Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: alert.severity.toLowerCase() == 'high' 
                    ? Theme.of(context).colorScheme.error.withOpacity(0.2)
                    : alert.severity.toLowerCase() == 'medium'
                      ? Theme.of(context).colorScheme.secondary.withOpacity(0.2)
                      : Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Severity: ${alert.severity}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: alert.severity.toLowerCase() == 'high' 
                      ? Theme.of(context).colorScheme.error
                      : alert.severity.toLowerCase() == 'medium'
                        ? Theme.of(context).colorScheme.secondary
                        : Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Description as bullet points
              Text(LocalizationService.translate(' Description:'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _buildBulletPoints(alert.description),
                ),
              ),
              const SizedBox(height: 16),
              
              // Treatment as bullet points
              Text(LocalizationService.translate(' Treatment Options:'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _buildBulletPoints(alert.treatment),
                ),
              ),
              
              // Product Recommendations Section
              if (alert.productRecommendations.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  LocalizationService.translate(' Recommended Products:'),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
                ...alert.productRecommendations.take(3).map((product) => _buildProductCard(product)),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(LocalizationService.translate('Close')),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _pestDiseaseService.resolveAlert(alert.id);
              
              // Send resolution notification
              final notificationService = NotificationService();
              if (alert.pestName.toLowerCase().contains('disease') || alert.description.toLowerCase().contains('disease')) {
                await notificationService.notifyDiseaseAlertResolved(
                  diseaseName: alert.pestName,
                  treatment: alert.treatment,
                );
              } else {
                await notificationService.notifyPestAlertResolved(
                  pestName: alert.pestName,
                  treatment: alert.treatment,
                );
              }
              
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(LocalizationService.translate('Alert marked as resolved'))),
              );
            },
            child: Text(LocalizationService.translate('Mark Resolved')),
          ),
        ],
      ),
    );
  }
  
  /// Convert a block of text into a list of bullet points
  List<Widget> _buildBulletPoints(String text) {
    // Split by common list separators or new lines, keeping the content
    List<String> points = text
        .split(RegExp(r'\n|(?=\d+\.)|(?=•)|(?=\-)|(?=\*)|\.(?=\s*[A-Z])'))
        .where((p) => p.trim().isNotEmpty)
        .map((p) => p.trim().replaceAll(RegExp(r'^[\d\.\-•\*\s]+'), '').trim())
        .where((p) => p.isNotEmpty)
        .toList();

    if (points.isEmpty) {
      points = [text];
    }

    // Render each point with a bullet symbol
    return points.map((point) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(LocalizationService.translate('• '), style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            Expanded(
              child: Text(
                point,
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  /// Build product recommendation card
  Widget _buildProductCard(dynamic product) {
    // Handle both ProductRecommendation objects and maps
    String productName = '';
    String category = '';
    String description = '';
    double rating = 0;
    int reviews = 0;
    String manufacturer = '';
    String dosage = '';

    if (product is Map<String, dynamic>) {
      productName = product['productName'] ?? '';
      category = product['category'] ?? '';
      description = product['description'] ?? '';
      rating = (product['rating'] as num?)?.toDouble() ?? 0;
      reviews = product['reviews'] ?? 0;
      manufacturer = product['manufacturer'] ?? '';
      dosage = product['dosage'] ?? '';
    } else {
      // Handle ProductRecommendation object
      productName = product.productName;
      category = product.category;
      description = product.description;
      rating = product.rating;
      reviews = product.reviews;
      manufacturer = product.manufacturer;
      dosage = product.dosage;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1), width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // name + category row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        productName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        category,
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // short description
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodyMedium?.color,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            // rating only
            if (rating > 0 || reviews > 0)
              Row(
                children: [
                  Icon(Icons.star, size: 14, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 4),
                  Text(
                    '$rating ($reviews)',
                    style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodyMedium?.color),
                  ),
                ],
              ),
            const SizedBox(height: 4),
            // manufacturer info
            if (manufacturer.isNotEmpty)
              Text(
                'Manufacturer: $manufacturer',
                style: TextStyle(fontSize: 10, color: Theme.of(context).textTheme.bodyMedium?.color),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 4),
            // more explicit dosage info
            if (dosage.isNotEmpty)
              Text(
                'Dosage (quantity per area): $dosage',
                style: TextStyle(fontSize: 10, color: Theme.of(context).textTheme.bodyMedium?.color),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIResponseWidget(String aiResponse) {
    // Try parsing AI response as JSON and render key fields; fallback to Markdown/Text
    try {
      String clean = aiResponse.replaceAll('```json', '').replaceAll('```', '').trim();
      // Try direct parse
      Map<String, dynamic>? data;
      try {
        final parsed = jsonDecode(clean);
        if (parsed is Map<String, dynamic>) data = parsed;
      } catch (_) {
        // Try extracting first JSON object via regex
        final match = RegExp(r'\{[^{}]*\}', dotAll: true).firstMatch(clean);
        if (match != null) {
          try {
            final parsed = jsonDecode(match.group(0)!);
            if (parsed is Map<String, dynamic>) data = parsed;
          } catch (_) {
            data = null;
          }
        }
      }

      if (data != null) {
        final pestName = data['pestName'] ?? data['pest'] ?? data['disease'] ?? null;
        final description = data['description'] ?? data['details'] ?? '';
        final treatment = data['treatment'] ?? data['treatments'] ?? '';
        final severity = data['severity'] ?? '';

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (pestName != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('${LocalizationService.translate('Pest:')} $pestName', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              if (severity.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('${LocalizationService.translate('Severity:')} $severity'),
                ),
              if ((description as String).isNotEmpty) ...[
                Text(LocalizationService.translate(' Description:'), style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _buildBulletPoints(description),
                  ),
                ),
              ],
              if ((treatment as String).isNotEmpty) ...[
                Text(LocalizationService.translate(' Treatment Options:'), style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _buildBulletPoints(treatment),
                  ),
                ),
              ],
            ],
          ),
        );
      }
    } catch (e) {
      // fallthrough to show raw
    }

    // Fallback: show raw response as selectable Markdown or text
    if (aiResponse.trim().length > 0) {
      return SizedBox(
        width: double.maxFinite,
        child: MarkdownBody(
          data: aiResponse,
          selectable: true,
          styleSheet: MarkdownStyleSheet(p: const TextStyle(fontSize: 14, height: 1.6)),
        ),
      );
    }

    return Text(LocalizationService.translate('No additional details'));
  }

  void _showScanDetails(BuildContext context, PestScanData scan) {
    // Extract pest name from AI response
    String? pestName;
    try {
      final data = jsonDecode(scan.aiResponse);
      if (data is Map<String, dynamic>) {
        pestName = data['pestName'] ?? data['pest'] ?? data['disease'];
      }
    } catch (_) {
      // Try regex extraction
      final match = RegExp(r'\{[^{}]*\}', dotAll: true).firstMatch(scan.aiResponse);
      if (match != null) {
        try {
          final data = jsonDecode(match.group(0)!);
          if (data is Map<String, dynamic>) {
            pestName = data['pestName'] ?? data['pest'] ?? data['disease'];
          }
        } catch (_) {}
      }
    }

    // Get product recommendations if pest is detected
    final recommendations = (pestName != null && pestName.isNotEmpty)
        ? _pestDiseaseService.getProductRecommendations(pestName)
        : <dynamic>[];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${scan.cropName} ${LocalizationService.translate('Scan Details')}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${LocalizationService.translate('Date:')} ${_formatDate(scan.scanDate)}'),
              const SizedBox(height: 8),
              Text('${LocalizationService.translate('Status:')} ${scan.status}'),
              const SizedBox(height: 8),
              Text('${LocalizationService.translate('Confidence:')} ${(scan.confidence * 100).toStringAsFixed(0)}%'),
              const SizedBox(height: 16),
              // Render AI response in a readable format instead of raw JSON
              _buildAIResponseWidget(scan.aiResponse),
              // Product Recommendations Section
              if (recommendations.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  LocalizationService.translate(' Recommended Products:'),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
                ...recommendations.take(3).map((product) => _buildProductCard(product)),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(LocalizationService.translate('Close')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(LocalizationService.translate('Detailed analysis opened'))),
              );
            },
            child: Text(LocalizationService.translate('View Details')),
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
        title: Text(LocalizationService.translate('Search Knowledge Base')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: LocalizationService.translate('Search for pests and diseases'),
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 16),
            Text(LocalizationService.translate('Enter keywords like "aphids", "leaf blight", "corn diseases", etc.'), style: const TextStyle(fontSize: 14)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(LocalizationService.translate('Cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performSearch(context, searchController.text);
            },
            style: ElevatedButton.styleFrom(),
            child: Text(LocalizationService.translate('Search')),
          ),
        ],
      ),
    );
  }

  void _performSearch(BuildContext context, String query) {
    if (query.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(LocalizationService.translate('Please enter a search term'))),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(LocalizationService.translate('Searching for "{q}"...').replaceAll('{q}', query)),
        content: SizedBox(
          height: 100,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 16),
                Text(LocalizationService.translate('Fetching information...')),
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
      print(' Searching for: $query');
      
      final prompt = '''You are an agriculture expert. Provide SHORT and PRACTICAL information about: "$query"

If it's a pest or disease, include:
1. **What it is** (1 line)
2. **Symptoms** (2-3 bullet points)
3. **Treatment** (2-3 practical steps)
4. **Prevention** (1-2 tips)

Keep it SHORT and practical for farmers. Use bullet points and bold for important terms.''';

      final response = await AiService().sendMessage(prompt);
      
      print(' Search response received');
      
      // Use the page's context, not the dialog context
      if (!mounted) {
        print(' Widget no longer mounted');
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
                      strong: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
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
                  Text(LocalizationService.translate('No information found. Please try another search.')),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(LocalizationService.translate('Close')),
            ),
          ],
        ),
      );
    } catch (e) {
      print(' Search error: $e');
      
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