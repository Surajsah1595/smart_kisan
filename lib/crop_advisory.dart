import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'ai_service.dart';
import 'notification_service.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'localization_service.dart';

// --- MODELS ---

class Field {
  final String id;
  final String name;
  final String size;
  final String soilType;
  final DateTime createdAt;
  final double? latitude;
  final double? longitude;

  Field({
    required this.id,
    required this.name,
    required this.size,
    required this.soilType,
    required this.createdAt,
    this.latitude,
    this.longitude,
  });

  factory Field.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Field(
      id: doc.id,
      name: data['name'] ?? '',
      size: data['size'] ?? '',
      soilType: data['soilType'] ?? 'Loamy Soil (Ideal)',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
    );
  }
}

class Crop {
  final String id;
  final String name;
  final String season;
  final String duration;
  final String waterNeed;
  final String cropStage;
  final DateTime createdAt;
  final String notes;

  Crop({
    required this.id,
    required this.name,
    required this.season,
    required this.duration,
    required this.waterNeed,
    this.cropStage = 'Seedling',
    required this.createdAt,
    this.notes = '',
  });

  factory Crop.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Crop(
      id: doc.id,
      name: data['name'] ?? '',
      season: data['season'] ?? '',
      duration: data['duration'] ?? '',
      waterNeed: data['waterNeed'] ?? '',
      cropStage: data['cropStage'] ?? 'Seedling',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      notes: data['notes'] ?? '',
    );
  }
}

// --- SCREEN ---

class CropAdvisoryScreen extends StatefulWidget {
  const CropAdvisoryScreen({super.key});

  @override
  State<CropAdvisoryScreen> createState() => _CropAdvisoryScreenState();
}

class _CropAdvisoryScreenState extends State<CropAdvisoryScreen> {
  final String uid = FirebaseAuth.instance.currentUser!.uid;
  final CollectionReference _usersCollection = FirebaseFirestore.instance.collection('users');
  final NotificationService _notificationService = NotificationService();

  String? selectedFieldId; 
  String? selectedFieldName;
  Field? selectedFieldObject;
  
  // Security: Rate limiting
  DateTime? _lastFieldCreated;
  DateTime? _lastCropCreated;
  static const _fieldCreationCooldown = Duration(seconds: 2);
  static const _cropCreationCooldown = Duration(seconds: 1);
  static const _maxFieldsPerUser = 10;
  static const _maxCropsPerField = 20; 

  // Standardized Soil Types for Dropdown
  final List<String> _soilTypes = [
    'Loamy Soil',
    'Clay Soil',
    'Sandy Soil',
    'Silt Soil',
    'Peaty Soil',
    'Chalky Soil',
    'Black Soil'
  ];

  static final List<BoxShadow> _cardShadow = [
    BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 2, offset: const Offset(0, 1), spreadRadius: -1),
    BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 3, offset: const Offset(0, 1), spreadRadius: 0),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _usersCollection.doc(uid).collection('fields').orderBy('createdAt').snapshots(),
                builder: (context, fieldSnapshot) {
                  if (fieldSnapshot.hasError) {
                    return Center(child: Text('${LocalizationService.translate('Error:')} ${fieldSnapshot.error}'));
                  }

                  if (!fieldSnapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final fieldDocs = fieldSnapshot.data!.docs;
                  final fields = fieldDocs.map((doc) => Field.fromSnapshot(doc)).toList();

                  // Auto-select logic
                  if (selectedFieldId == null && fields.isNotEmpty) {
                    selectedFieldId = fields.first.id;
                    selectedFieldObject = fields.first;
                    selectedFieldName = fields.first.name;
                  } else if (fields.isEmpty) {
                    selectedFieldId = null;
                    selectedFieldObject = null;
                    selectedFieldName = null;
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. FIELDS LIST
                        _buildSection(
                          title: LocalizationService.translate('Your Fields'),
                          buttonText: LocalizationService.translate('Add Field'),
                          onButtonPressed: () => _showAddFieldDialog(context),
                          child: Column(
                            children: fields.isEmpty 
                              ? [_buildEmptyFieldState()]
                              : fields.map((field) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _buildFieldCard(field),
                                )).toList(),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // 2. CROPS LIST
                        if (selectedFieldId != null)
                          StreamBuilder<QuerySnapshot>(
                            stream: _usersCollection
                                .doc(uid)
                                .collection('fields')
                                .doc(selectedFieldId)
                                .collection('crops')
                                .orderBy('createdAt')
                                .snapshots(),
                            builder: (context, cropSnapshot) {
                              if (!cropSnapshot.hasData) return const LinearProgressIndicator();
                              
                              final cropDocs = cropSnapshot.data!.docs;
                              final crops = cropDocs.map((doc) => Crop.fromSnapshot(doc)).toList();

                                return _buildSection(
                                title: LocalizationService.translate('Crops in') + ' $selectedFieldName',
                                buttonText: LocalizationService.translate('Add Crop'),
                                onButtonPressed: () => _showAddCropDialog(context),
                                child: Column(
                                  children: [
                                    if (crops.isEmpty) _buildEmptyCropsState(),
                                    ...crops.map((crop) => Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: _buildCropCard(crop),
                                    )),
                                  ],
                                ),
                              );
                            },
                          ),
                        
                        const SizedBox(height: 24),
                        
                        // 3. ADVISORY BUTTON
                        if (selectedFieldId != null) _buildAdvisoryButton(),
                        
                        const SizedBox(height: 24),
                        _buildSeasonalTips(),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF2C7C48),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Text(LocalizationService.translate('Crop Advisory'), style: const TextStyle(color: Colors.white, fontSize: 24, fontFamily: 'Arimo')),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.eco, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(LocalizationService.translate('Manage fields & get recommendations'), style: const TextStyle(color: Color(0xE5FFFEFE), fontSize: 16, fontFamily: 'Arimo')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required String buttonText, required VoidCallback onButtonPressed, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(color: Color(0xFF101727), fontSize: 16, fontFamily: 'Arimo', fontWeight: FontWeight.bold)),
            ElevatedButton(
              onPressed: onButtonPressed,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A63E), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: Row(
                children: [
                  const Icon(Icons.add, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Text(buttonText, style: const TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'Arimo')),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        child,
      ],
    );
  }

  Widget _buildFieldCard(Field field) {
    final isSelected = field.id == selectedFieldId;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFieldId = field.id;
          selectedFieldName = field.name;
          selectedFieldObject = field;
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: _cardShadow,
          border: isSelected ? Border.all(color: const Color(0xFF00C850), width: 2) : null,
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40, padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: isSelected ? const Color(0xFFDCFCE7) : const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.landscape, color: isSelected ? const Color(0xFF101727) : Colors.grey, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(field.name, style: const TextStyle(color: Color(0xFF101727), fontSize: 16, fontFamily: 'Arimo', fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.aspect_ratio, size: 14, color: Color(0xFF495565)),
                      const SizedBox(width: 4),
                      Text(field.size, style: const TextStyle(color: Color(0xFF495565), fontSize: 14, fontFamily: 'Arimo')),
                      const SizedBox(width: 16),
                      const Icon(Icons.layers, size: 14, color: Color(0xFF495565)),
                      const SizedBox(width: 4),
                      Text(field.soilType, style: const TextStyle(color: Color(0xFF495565), fontSize: 14, fontFamily: 'Arimo')),
                    ],
                  ),
                ],
              ),
            ),
            if (isSelected) const Padding(padding: EdgeInsets.only(right: 8.0), child: Icon(Icons.check_circle, color: Color(0xFF00C950), size: 24)),
            IconButton(
              onPressed: () => _deleteField(field.id),
              icon: const Icon(Icons.delete_outline, color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyFieldState() {
    return Container(
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade300)),
      child: const Center(child: Text("No fields added yet. Add one to start tracking.", style: TextStyle(color: Colors.grey))),
    );
  }

  Widget _buildCropCard(Crop crop) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: _cardShadow),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(crop.name, style: const TextStyle(color: Color(0xFF101727), fontSize: 16, fontFamily: 'Arimo', fontWeight: FontWeight.bold)),
              IconButton(
                onPressed: () => _deleteCrop(crop.id),
                icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              )
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 16, color: Color(0xFF495565)),
              const SizedBox(width: 4),
              Text(crop.season, style: const TextStyle(color: Color(0xFF495565), fontSize: 14, fontFamily: 'Arimo')),
              const SizedBox(width: 16),
              const Icon(Icons.schedule, size: 16, color: Color(0xFF495565)),
              const SizedBox(width: 4),
              Text(crop.duration, style: const TextStyle(color: Color(0xFF495565), fontSize: 14)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.water_drop, size: 16, color: Color(0xFF495565)),
              const SizedBox(width: 4),
              Text('${LocalizationService.translate("Water Needed")}: ${crop.waterNeed}', style: const TextStyle(color: Color(0xFF495565), fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCropsState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: _cardShadow),
      child: Column(
        children: [
          const Icon(Icons.grass, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          Text(LocalizationService.translate("No crops added yet"), style: const TextStyle(color: Color(0xFF495565), fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildAdvisoryButton() {
    return GestureDetector(
      onTap: () => _getAiRecommendations(context),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF00C850), Color(0xFF00A63D)]),
          borderRadius: BorderRadius.circular(10),
          boxShadow: _cardShadow,
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.auto_awesome, color: Colors.white),
              const SizedBox(width: 8),
              Text(LocalizationService.translate("Get Smart AI Recommendations"), style: const TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'Arimo', fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeasonalTips() {
    final month = DateTime.now().month;
    String seasonTitle = LocalizationService.translate("Seasonal Tips");
    List<String> tips = [];

    if (month >= 11 || month <= 2) {
      seasonTitle = LocalizationService.translate("Winter Season (Nov-Feb)");
      tips = [
        LocalizationService.translate("Reduce watering frequency."),
        LocalizationService.translate("Protect sensitive crops from frost."),
        LocalizationService.translate("Plant cover crops for soil health."),
      ];
    } else if (month >= 3 && month <= 5) {
      seasonTitle = LocalizationService.translate("Spring Season (Mar-May)");
      tips = [
        LocalizationService.translate("Prepare land for planting."),
        LocalizationService.translate("Watch for aphids."),
        LocalizationService.translate("Clean irrigation channels."),
      ];
    } else if (month >= 6 && month <= 9) {
      seasonTitle = LocalizationService.translate("Monsoon Season (Jun-Sep)");
      tips = [
        LocalizationService.translate("Ensure drainage to prevent waterlogging."),
        LocalizationService.translate("Monitor for stem borer."),
        LocalizationService.translate("Harvest rainwater."),
      ];
    } else {
      seasonTitle = LocalizationService.translate("Autumn Season (Oct)");
      tips = [
        LocalizationService.translate("Harvest monsoon crops."),
        LocalizationService.translate("Prepare soil for wheat."),
        LocalizationService.translate("Store grains in dry places."),
      ];
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFF0FDF4), Color(0xFFDBFBE6)]),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.lightbulb_outline, color: Color(0xFF0D532B)),
            const SizedBox(width: 12),
            Text(seasonTitle, style: const TextStyle(color: Color(0xFF0D532B), fontSize: 16, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 8),
          ...tips.map((tip) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text('• $tip', style: const TextStyle(color: Color(0xFF016630))),
          )),
        ],
      ),
    );
  }

  // --- ACTIONS (Dialogs & DB Writes) ---

  void _showAddFieldDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final sizeCtrl = TextEditingController();
    String selectedSoil = _soilTypes[0]; // Default soil

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateSB) {
          return Dialog(
            insetPadding: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(LocalizationService.translate('Add New Field'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    _buildTextField(LocalizationService.translate('Field Name'), LocalizationService.translate('e.g., South Field'), nameCtrl),
                    const SizedBox(height: 12),
                    _buildTextField(LocalizationService.translate('Size'), LocalizationService.translate('e.g., 2 Acres / 5 Katha'), sizeCtrl),
                    const SizedBox(height: 12),
                    
                    // --- SOIL DROPDOWN ---
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(LocalizationService.translate('Soil Type'), style: const TextStyle(fontSize: 14, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8)
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedSoil,
                              isExpanded: true,
                              items: _soilTypes.map((String soil) {
                                return DropdownMenuItem<String>(
                                  value: soil,
                                  child: Text(soil),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setStateSB(() {
                                  selectedSoil = newValue!;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(child: ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(backgroundColor: Colors.grey), child: Text(LocalizationService.translate('Cancel')))),
                        const SizedBox(width: 12),
                        Expanded(child: ElevatedButton(
                          onPressed: () async {
                            if (nameCtrl.text.isEmpty) return;
                            
                            // Rate limiting check
                            if (_lastFieldCreated != null && DateTime.now().difference(_lastFieldCreated!) < _fieldCreationCooldown) {
                              await _logAuditAction('suspicious_field_spam', reason: 'Attempted to create field too quickly');
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(LocalizationService.translate('Wait 2 seconds before adding another field'))));
                              return;
                            }
                            
                            // Check max fields
                            final existingFields = await _usersCollection.doc(uid).collection('fields').count().get();
                            if ((existingFields.count ?? 0) >= _maxFieldsPerUser) {
                              await _logAuditAction('suspicious_max_fields_exceeded', reason: 'User attempted to exceed max 10 fields');
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(LocalizationService.translate('Max 10 fields allowed per account'))));
                              return;
                            }

                            try {
                              await _usersCollection.doc(uid).collection('fields').add({
                                'name': nameCtrl.text,
                                'size': sizeCtrl.text,
                                'soilType': selectedSoil,
                                'createdAt': FieldValue.serverTimestamp(),
                              });
                              
                              // Send notification
                              await _notificationService.notifyFieldCreated(
                                fieldName: nameCtrl.text,
                                area: double.tryParse(sizeCtrl.text) ?? 0.0,
                                areaUnit: 'acres',
                                cropType: 'Multiple',
                              );
                              
                              await _logAuditAction('field_created', fieldName: nameCtrl.text);
                              _lastFieldCreated = DateTime.now();
                              Navigator.pop(context);
                            } catch (e) {
                              await _logAuditAction('field_creation_failed', fieldName: nameCtrl.text, reason: e.toString());
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${LocalizationService.translate("Error:")} $e')));
                            }
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A63E)),
                          child: Text(LocalizationService.translate('Save'), style: const TextStyle(color: Colors.white)),
                        )),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      ),
    );
  }

  void _showAddCropDialog(BuildContext context) {
    if (selectedFieldId == null) return;
    final nameCtrl = TextEditingController();
    
    // --- 50+ CROPS LIST ---
    List<Map<String, String>> cropDatabase = [
      // Cereals
      {'name': 'Rice (Paddy)', 'season': 'Monsoon', 'duration': '100-150 days', 'waterNeed': 'High'},
      {'name': 'Wheat', 'season': 'Winter', 'duration': '110-130 days', 'waterNeed': 'Medium'},
      {'name': 'Maize (Corn)', 'season': 'Spring/Summer', 'duration': '90-110 days', 'waterNeed': 'Medium'},
      {'name': 'Millet (Kodo)', 'season': 'Summer', 'duration': '100-120 days', 'waterNeed': 'Low'},
      {'name': 'Barley (Jau)', 'season': 'Winter', 'duration': '100-120 days', 'waterNeed': 'Low'},
      {'name': 'Buckwheat (Phapar)', 'season': 'Autumn', 'duration': '70-90 days', 'waterNeed': 'Low'},
      
      // Vegetables
      {'name': 'Potato', 'season': 'Winter', 'duration': '90-120 days', 'waterNeed': 'Medium'},
      {'name': 'Tomato', 'season': 'All Year', 'duration': '90-100 days', 'waterNeed': 'Medium'},
      {'name': 'Cauliflower', 'season': 'Winter', 'duration': '80-100 days', 'waterNeed': 'Medium'},
      {'name': 'Cabbage', 'season': 'Winter', 'duration': '90-110 days', 'waterNeed': 'Medium'},
      {'name': 'Onion', 'season': 'Winter', 'duration': '120-150 days', 'waterNeed': 'Medium'},
      {'name': 'Garlic', 'season': 'Winter', 'duration': '130-160 days', 'waterNeed': 'Low'},
      {'name': 'Ginger', 'season': 'Spring', 'duration': '240-270 days', 'waterNeed': 'Medium'},
      {'name': 'Radish', 'season': 'Winter', 'duration': '40-60 days', 'waterNeed': 'Medium'},
      {'name': 'Carrot', 'season': 'Winter', 'duration': '80-100 days', 'waterNeed': 'Medium'},
      {'name': 'Brinjal (Eggplant)', 'season': 'Summer', 'duration': '100-120 days', 'waterNeed': 'Medium'},
      {'name': 'Okra (Lady Finger)', 'season': 'Summer', 'duration': '60-90 days', 'waterNeed': 'Medium'},
      {'name': 'Spinach (Saag)', 'season': 'Winter', 'duration': '30-45 days', 'waterNeed': 'Medium'},
      {'name': 'Cucumber', 'season': 'Spring', 'duration': '60-80 days', 'waterNeed': 'High'},
      {'name': 'Pumpkin', 'season': 'Spring', 'duration': '90-120 days', 'waterNeed': 'Medium'},
      {'name': 'Bitter Gourd (Karela)', 'season': 'Summer', 'duration': '80-100 days', 'waterNeed': 'Medium'},
      {'name': 'Bottle Gourd (Lauka)', 'season': 'Summer', 'duration': '90-110 days', 'waterNeed': 'Medium'},
      {'name': 'Chili', 'season': 'All Year', 'duration': '90-120 days', 'waterNeed': 'Medium'},
      {'name': 'Peas', 'season': 'Winter', 'duration': '80-100 days', 'waterNeed': 'Medium'},
      {'name': 'Broad Bean (Bakulla)', 'season': 'Winter', 'duration': '100-120 days', 'waterNeed': 'Medium'},

      // Pulses
      {'name': 'Lentil (Musuro)', 'season': 'Winter', 'duration': '90-110 days', 'waterNeed': 'Low'},
      {'name': 'Chickpea (Chana)', 'season': 'Winter', 'duration': '100-120 days', 'waterNeed': 'Low'},
      {'name': 'Black Gram (Mas)', 'season': 'Summer', 'duration': '80-100 days', 'waterNeed': 'Low'},
      {'name': 'Soybean', 'season': 'Summer', 'duration': '90-120 days', 'waterNeed': 'Medium'},
      {'name': 'Pigeon Pea (Rahar)', 'season': 'Summer', 'duration': '150-180 days', 'waterNeed': 'Low'},
      {'name': 'Mung Bean', 'season': 'Summer', 'duration': '60-70 days', 'waterNeed': 'Low'},
      
      // Cash Crops
      {'name': 'Mustard', 'season': 'Winter', 'duration': '80-100 days', 'waterNeed': 'Low'},
      {'name': 'Sugarcane', 'season': 'Spring', 'duration': '300-365 days', 'waterNeed': 'High'},
      {'name': 'Tea', 'season': 'Perennial', 'duration': 'Years', 'waterNeed': 'High'},
      {'name': 'Coffee', 'season': 'Perennial', 'duration': 'Years', 'waterNeed': 'Medium'},
      {'name': 'Cardamom (Alaichi)', 'season': 'Perennial', 'duration': 'Years', 'waterNeed': 'High'},
      {'name': 'Jute', 'season': 'Summer', 'duration': '120-150 days', 'waterNeed': 'High'},
      {'name': 'Sunflower', 'season': 'Spring', 'duration': '90-100 days', 'waterNeed': 'Medium'},
      {'name': 'Groundnut (Peanut)', 'season': 'Summer', 'duration': '100-120 days', 'waterNeed': 'Medium'},
      {'name': 'Turmeric', 'season': 'Spring', 'duration': '240-270 days', 'waterNeed': 'Medium'},
      
      // Fruits
      {'name': 'Banana', 'season': 'Perennial', 'duration': '12-14 months', 'waterNeed': 'High'},
      {'name': 'Mango', 'season': 'Summer', 'duration': 'Perennial', 'waterNeed': 'Medium'},
      {'name': 'Apple', 'season': 'Perennial', 'duration': 'Perennial', 'waterNeed': 'Medium'},
      {'name': 'Orange/Citrus', 'season': 'Winter', 'duration': 'Perennial', 'waterNeed': 'Medium'},
      {'name': 'Papaya', 'season': 'All Year', 'duration': '9-12 months', 'waterNeed': 'Medium'},
      {'name': 'Guava', 'season': 'Perennial', 'duration': 'Perennial', 'waterNeed': 'Medium'},
      {'name': 'Lychee', 'season': 'Summer', 'duration': 'Perennial', 'waterNeed': 'High'},
      {'name': 'Watermelon', 'season': 'Summer', 'duration': '80-100 days', 'waterNeed': 'High'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(16),
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(LocalizationService.translate('Add Crop'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildTextField(LocalizationService.translate('Custom Crop Name'), LocalizationService.translate('Enter Name'), nameCtrl),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () async {
                          if (nameCtrl.text.isEmpty) return;
                          
                          // Rate limiting check
                          if (_lastCropCreated != null && DateTime.now().difference(_lastCropCreated!) < _cropCreationCooldown) {
                            await _logAuditAction('suspicious_crop_spam', fieldName: selectedFieldName, reason: 'Attempted to create crop too quickly');
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(LocalizationService.translate('Wait before adding another crop'))));
                            return;
                          }
                          
                          // Check max crops in field
                          final existingCrops = await _usersCollection.doc(uid).collection('fields').doc(selectedFieldId).collection('crops').count().get();
                          if ((existingCrops.count ?? 0) >= _maxCropsPerField) {
                            await _logAuditAction('suspicious_max_crops_exceeded', fieldName: selectedFieldName, reason: 'User attempted to exceed max 20 crops per field');
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(LocalizationService.translate('Max 20 crops per field allowed'))));
                            return;
                          }
                          
                          await _saveCropToFirebase(nameCtrl.text, 'Custom', 'Unknown', 'Medium');
                          await _logAuditAction('crop_created', fieldName: selectedFieldName, cropName: nameCtrl.text);
                          _lastCropCreated = DateTime.now();
                          Navigator.pop(context);
                        },
                        child: Text(LocalizationService.translate('Add Custom Crop')),
                      ),
                      const Divider(height: 30),
                      Text(LocalizationService.translate('Or Select Common Crop:'), style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      ...cropDatabase.map((c) => ListTile(
                        leading: const Icon(Icons.eco, color: Colors.green),
                        title: Text(c['name']!),
                        subtitle: Text('${c['season']} • ${c['duration']}'),
                        onTap: () async {
                          await _saveCropToFirebase(c['name']!, c['season']!, c['duration']!, c['waterNeed']!);
                          await _logAuditAction('crop_created', fieldName: selectedFieldName, cropName: c['name']!, reason: 'User selected from database');
                          Navigator.pop(context);
                        },
                      )),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveCropToFirebase(String name, String season, String duration, String water, {String cropStage = 'Seedling', String notes = ''}) async {
    await _usersCollection.doc(uid).collection('fields').doc(selectedFieldId).collection('crops').add({
      'name': name,
      'season': season,
      'duration': duration,
      'waterNeed': water,
      'cropStage': cropStage,
      'createdAt': FieldValue.serverTimestamp(),
      'notes': notes,
    });
    
    // Send notification
    await _notificationService.notifyCropHealth(
      cropName: name,
      healthStatus: 'Good',
      observation: 'New $name crop planted in $season season. Duration: $duration. Water need: $water.',
    );
  }

  // --- AUDIT LOGGING ---
  Future<void> _logAuditAction(String action, {String? fieldName, String? cropName, String? reason}) async {
    try {
      await _usersCollection.doc(uid).collection('auditLog').add({
        'action': action,
        'fieldName': fieldName,
        'cropName': cropName,
        'reason': reason,
        'timestamp': FieldValue.serverTimestamp(),
        'userAgent': 'smart_kisan_app_v1.0',
      });
      print('✅ Logged action: $action');
    } catch (e) {
      print('❌ Failed to log action: $e');
    }
  }

  // --- SMART RECOMMENDATION LOGIC ---

  Future<void> _getAiRecommendations(BuildContext context) async {
    if (selectedFieldObject == null) return;

    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));

    try {
      final cropSnapshot = await _usersCollection.doc(uid).collection('fields').doc(selectedFieldId).collection('crops').get();
      final cropNames = cropSnapshot.docs.map((d) => d['name'] ?? '').where((s) => s.isNotEmpty).toList();

      final month = DateTime.now().month;
      String currentSeason;
      if (month >= 11 || month <= 2) {
        currentSeason = 'Winter';
      } else if (month >= 3 && month <= 5) currentSeason = 'Spring';
      else if (month >= 6 && month <= 9) currentSeason = 'Monsoon';
      else currentSeason = 'Autumn';

      final prompt = StringBuffer();
      prompt.writeln('Field Name: ${selectedFieldObject!.name}');
      prompt.writeln('Size: ${selectedFieldObject!.size}');
      prompt.writeln('Soil Type: ${selectedFieldObject!.soilType}');
      prompt.writeln('Current Season: $currentSeason');
      prompt.writeln('Existing Crops: ${cropNames.isEmpty ? 'None' : cropNames.join(", ")}');
      prompt.writeln();
      prompt.writeln('Provide concise actionable recommendations for this field (planting choices, irrigation, fertilizer, pest watch, and quick care).');
      prompt.writeln('Suggest 5-7 suitable crops for planting.');
      prompt.writeln('At the end output ONLY a JSON array under the exact marker SUGGESTED_CROPS_JSON: []; example: SUGGESTED_CROPS_JSON: [{"name":"Wheat","reason":"Clay holds moisture well","season":"Winter"},{"name":"Lentils","reason":"Pulses thrive in clay soil","season":"Winter"}]');

      final ai = AiService();
      final response = await ai.sendMessage(prompt.toString());

      Navigator.pop(context);

      if (response == null || response.startsWith('Error:')) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(LocalizationService.translate('AI returned no response.'))));
        return;
      }

      final regex = RegExp(r'SUGGESTED_CROPS_JSON:\s*(\[.*?\])', dotAll: true);
      final match = regex.firstMatch(response);
      List<dynamic>? suggested;
      if (match != null) {
        try {
          final jsonPart = match.group(1)!;
          print('🌾 Found JSON: $jsonPart');
          suggested = jsonDecode(jsonPart) as List<dynamic>;
          print('🌾 Parsed ${suggested.length} crops from AI');
        } catch (e) {
          print('❌ JSON parse error: $e');
          suggested = null;
        }
      } else {
        print('⚠️ No SUGGESTED_CROPS_JSON marker found in response');
      }

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (ctx) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(16),
            constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.75),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [const Icon(Icons.auto_awesome, color: Colors.green), const SizedBox(width: 8), Text(LocalizationService.translate('AI Recommendation'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]),
                const SizedBox(height: 12),
                Expanded(child: SingleChildScrollView(child: MarkdownBody(data: response, styleSheet: MarkdownStyleSheet(p: const TextStyle(fontSize: 14, color: Colors.black87), strong: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black), em: const TextStyle(fontStyle: FontStyle.italic))))),
                const SizedBox(height: 12),
                if (suggested != null) ...[
                  const Divider(),
                  Text(LocalizationService.translate('Suggested Crops (tap + to add):'), style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Expanded(child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: suggested.length,
                    itemBuilder: (context, i) {
                      final item = suggested![i] as Map<String, dynamic>;
                      final name = item['name'] ?? '';
                      final reason = item['reason'] ?? '';
                      final season = item['season'] ?? currentSeason;
                      final duration = item['duration'] ?? 'Seasonal';
                      final water = item['waterNeed'] ?? 'Variable';
                      return ListTile(
                        leading: CircleAvatar(backgroundColor: Colors.green[100], child: Text(name.isNotEmpty ? name[0] : '?', style: const TextStyle(color: Colors.green))),
                        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(reason),
                        trailing: IconButton(
                          icon: const Icon(Icons.add_circle, color: Colors.green),
                          onPressed: () async {
                            await _saveCropToFirebase(name, season, duration, water);
                            await _logAuditAction('crop_created', fieldName: selectedFieldName, cropName: name, reason: 'Added from AI recommendations');
                            _lastCropCreated = DateTime.now();
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(LocalizationService.translate('Added') + ' $name ' + LocalizationService.translate('to field'))));
                          },
                        ),
                      );
                    },
                  ))
                ],
                const SizedBox(height: 12),
                Row(children: [Expanded(child: ElevatedButton(onPressed: () => Navigator.pop(ctx), style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 45)), child: Text(LocalizationService.translate('Close'))))]),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${LocalizationService.translate('Error:')} $e')));
    }
  }

  void _deleteField(String fieldId) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text("Delete Field?"),
      content: const Text("This will delete the field and all crops inside it."),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
        TextButton(onPressed: () async {
          await _usersCollection.doc(uid).collection('fields').doc(fieldId).delete();
          
          // Send notification
          await _notificationService.notifyFieldCreated(
            fieldName: selectedFieldName ?? 'Unknown Field',
            area: 0,
            areaUnit: 'acres',
            cropType: 'Deleted',
          );
          
          setState(() { selectedFieldId = null; selectedFieldName = null; });
          Navigator.pop(ctx);
        }, child: const Text("Delete", style: TextStyle(color: Colors.red))),
      ],
    ));
  }

  void _deleteCrop(String cropId) {
    if (selectedFieldId == null) return;
    _usersCollection.doc(uid).collection('fields').doc(selectedFieldId).collection('crops').doc(cropId).delete();
    
    // Send notification
    _notificationService.notifyCropHealth(
      cropName: 'Unknown Crop',
      healthStatus: 'Deleted',
      observation: 'Crop has been removed from your field.',
    );
  }

  Widget _buildTextField(String label, String hint, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ],
    );
  }
}