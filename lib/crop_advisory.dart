import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- MODELS ---

class Field {
  final String id;
  final String name;
  final String size;
  final String soilType;

  Field({
    required this.id,
    required this.name,
    required this.size,
    required this.soilType,
  });

  factory Field.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Field(
      id: doc.id,
      name: data['name'] ?? '',
      size: data['size'] ?? '',
      soilType: data['soilType'] ?? 'Loamy Soil (Ideal)',
    );
  }
}

class Crop {
  final String id;
  final String name;
  final String season;
  final String duration;
  final String waterNeed;
  final double progress;

  Crop({
    required this.id,
    required this.name,
    required this.season,
    required this.duration,
    required this.waterNeed,
    this.progress = 0.0,
  });

  factory Crop.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Crop(
      id: doc.id,
      name: data['name'] ?? '',
      season: data['season'] ?? '',
      duration: data['duration'] ?? '',
      waterNeed: data['waterNeed'] ?? '',
      progress: (data['progress'] ?? 0.0).toDouble(),
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

  String? selectedFieldId; 
  String? selectedFieldName;
  Field? selectedFieldObject; 

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
    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 2, offset: const Offset(0, 1), spreadRadius: -1),
    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 3, offset: const Offset(0, 1), spreadRadius: 0),
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
                  if (fieldSnapshot.hasError) return Center(child: Text('Error: ${fieldSnapshot.error}'));
                  if (fieldSnapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                  final fieldDocs = fieldSnapshot.data!.docs;
                  final fields = fieldDocs.map((doc) => Field.fromSnapshot(doc)).toList();

                  // Auto-select logic
                  if (selectedFieldId == null && fields.isNotEmpty) {
                    selectedFieldId = fields.first.id;
                    selectedFieldName = fields.first.name;
                    selectedFieldObject = fields.first;
                  } else if (fields.isNotEmpty && selectedFieldId != null) {
                    try {
                      selectedFieldObject = fields.firstWhere((f) => f.id == selectedFieldId);
                      selectedFieldName = selectedFieldObject!.name;
                    } catch (e) {
                      selectedFieldId = fields.first.id;
                      selectedFieldObject = fields.first;
                      selectedFieldName = fields.first.name;
                    }
                  } else if (fields.isEmpty) {
                    selectedFieldId = null;
                    selectedFieldObject = null;
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. FIELDS LIST
                        _buildSection(
                          title: 'Your Fields',
                          buttonText: 'Add Field',
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
                                title: 'Crops in $selectedFieldName',
                                buttonText: 'Add Crop',
                                onButtonPressed: () => _showAddCropDialog(context),
                                child: Column(
                                  children: [
                                    if (crops.isEmpty) _buildEmptyCropsState(),
                                    ...crops.map((crop) => Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: _buildCropCard(crop),
                                    )).toList(),
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
              const Text('Crop Advisory', style: TextStyle(color: Colors.white, fontSize: 24, fontFamily: 'Arimo')),
            ],
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Icon(Icons.eco, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Manage fields & get recommendations', style: TextStyle(color: Color(0xE5FFFEFE), fontSize: 16, fontFamily: 'Arimo')),
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
              Text('Water: ${crop.waterNeed}', style: const TextStyle(color: Color(0xFF495565), fontSize: 14)),
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
      child: const Column(
        children: [
          Icon(Icons.grass, size: 48, color: Colors.grey),
          SizedBox(height: 16),
          Text('No crops added yet', style: TextStyle(color: Color(0xFF495565), fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildAdvisoryButton() {
    return GestureDetector(
      onTap: () => _showRecommendations(context),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF00C850), Color(0xFF00A63D)]),
          borderRadius: BorderRadius.circular(10),
          boxShadow: _cardShadow,
        ),
        child: const Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.auto_awesome, color: Colors.white),
              SizedBox(width: 8),
              Text('Get Smart Recommendations', style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'Arimo', fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeasonalTips() {
    final month = DateTime.now().month;
    String seasonTitle = 'Seasonal Tips';
    List<String> tips = [];

    if (month >= 11 || month <= 2) {
      seasonTitle = 'Winter Season (Nov-Feb)';
      tips = ['Reduce watering frequency.', 'Protect sensitive crops from frost.', 'Plant cover crops for soil health.'];
    } else if (month >= 3 && month <= 5) {
      seasonTitle = 'Spring Season (Mar-May)';
      tips = ['Prepare land for planting.', 'Watch for aphids.', 'Clean irrigation channels.'];
    } else if (month >= 6 && month <= 9) {
      seasonTitle = 'Monsoon Season (Jun-Sep)';
      tips = ['Ensure drainage to prevent waterlogging.', 'Monitor for stem borer.', 'Harvest rainwater.'];
    } else {
      seasonTitle = 'Autumn Season (Oct)';
      tips = ['Harvest monsoon crops.', 'Prepare soil for wheat.', 'Store grains in dry places.'];
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
          )).toList(),
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
                    const Text('Add New Field', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    _buildTextField('Field Name', 'e.g., South Field', nameCtrl),
                    const SizedBox(height: 12),
                    _buildTextField('Size', 'e.g., 2 Acres / 5 Katha', sizeCtrl),
                    const SizedBox(height: 12),
                    
                    // --- SOIL DROPDOWN ---
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Soil Type', style: TextStyle(fontSize: 14, color: Colors.grey)),
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
                        Expanded(child: ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(backgroundColor: Colors.grey), child: const Text('Cancel'))),
                        const SizedBox(width: 12),
                        Expanded(child: ElevatedButton(
                          onPressed: () async {
                            if (nameCtrl.text.isNotEmpty) {
                              try {
                                await _usersCollection.doc(uid).collection('fields').add({
                                  'name': nameCtrl.text,
                                  'size': sizeCtrl.text,
                                  'soilType': selectedSoil, // Save dropdown value
                                  'createdAt': FieldValue.serverTimestamp(),
                                });
                                Navigator.pop(context);
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A63E)),
                          child: const Text('Save', style: TextStyle(color: Colors.white)),
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
              const Text('Add Crop', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildTextField('Custom Crop Name', 'Enter Name', nameCtrl),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () async {
                          if (nameCtrl.text.isNotEmpty) {
                            await _saveCropToFirebase(nameCtrl.text, 'Custom', 'Unknown', 'Medium');
                            Navigator.pop(context);
                          }
                        },
                        child: const Text("Add Custom Crop"),
                      ),
                      const Divider(height: 30),
                      const Text('Or Select Common Crop:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      ...cropDatabase.map((c) => ListTile(
                        leading: const Icon(Icons.eco, color: Colors.green),
                        title: Text(c['name']!),
                        subtitle: Text('${c['season']} • ${c['duration']}'),
                        onTap: () async {
                          await _saveCropToFirebase(c['name']!, c['season']!, c['duration']!, c['waterNeed']!);
                          Navigator.pop(context);
                        },
                      )).toList(),
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

  Future<void> _saveCropToFirebase(String name, String season, String duration, String water) async {
    await _usersCollection.doc(uid).collection('fields').doc(selectedFieldId).collection('crops').add({
      'name': name,
      'season': season,
      'duration': duration,
      'waterNeed': water,
      'progress': 0.0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // --- SMART RECOMMENDATION LOGIC ---

  void _showRecommendations(BuildContext context) {
    if (selectedFieldObject == null) return;

    final month = DateTime.now().month;
    String currentSeason;
    if (month >= 11 || month <= 2) currentSeason = 'Winter';
    else if (month >= 3 && month <= 5) currentSeason = 'Spring';
    else if (month >= 6 && month <= 9) currentSeason = 'Monsoon';
    else currentSeason = 'Autumn';

    String soil = selectedFieldObject!.soilType.toLowerCase();
    List<Map<String, String>> suggestions = [];

    // --- LOGIC FOR DROPDOWN SOIL TYPES ---
    
    if (currentSeason == 'Winter') {
      if (soil.contains('clay')) {
        suggestions.add({'name': 'Wheat', 'reason': 'Clay holds moisture well for wheat.'});
        suggestions.add({'name': 'Lentils', 'reason': 'Pulses thrive in heavy clay soil.'});
      } else if (soil.contains('sandy')) {
        suggestions.add({'name': 'Carrot', 'reason': 'Root vegetables grow straight in sandy soil.'});
        suggestions.add({'name': 'Radish', 'reason': 'Easy root penetration in sandy soil.'});
        suggestions.add({'name': 'Peanut', 'reason': 'Needs loose soil for pod formation.'});
      } else if (soil.contains('black')) { // Black cotton soil
        suggestions.add({'name': 'Chickpea', 'reason': 'Excellent for moisture retentive black soil.'});
        suggestions.add({'name': 'Mustard', 'reason': 'Grows vigorously in rich soil.'});
      } else { // Loam / Silt
        suggestions.add({'name': 'Mustard', 'reason': 'Versatile winter cash crop.'});
        suggestions.add({'name': 'Peas', 'reason': 'Loam provides perfect drainage.'});
        suggestions.add({'name': 'Potato', 'reason': 'Tuber formation is best in loamy soil.'});
      }
    } 
    
    else if (currentSeason == 'Monsoon') {
      if (soil.contains('clay')) {
        suggestions.add({'name': 'Rice (Paddy)', 'reason': 'Clay retains water needed for paddy.'});
      } else if (soil.contains('sandy')) {
        suggestions.add({'name': 'Corn (Maize)', 'reason': 'Prevents root rot with good drainage.'});
        suggestions.add({'name': 'Groundnut', 'reason': 'Requires non-compact soil.'});
      } else if (soil.contains('black')) {
        suggestions.add({'name': 'Cotton', 'reason': 'Black soil is famous for cotton.'});
        suggestions.add({'name': 'Soybean', 'reason': 'High yield in nutrient rich soil.'});
      } else {
        suggestions.add({'name': 'Millet', 'reason': 'Hardy crop for various soils.'});
        suggestions.add({'name': 'Soybean', 'reason': 'Good drainage required.'});
      }
    } 
    
    else if (currentSeason == 'Spring') {
      suggestions.add({'name': 'Cucumber', 'reason': 'Fast growing spring vegetable.'});
      suggestions.add({'name': 'Pumpkin', 'reason': 'Warmth helps vine growth.'});
      if (soil.contains('loam') || soil.contains('clay')) {
        suggestions.add({'name': 'Sugarcane', 'reason': 'Planting season for long duration crop.'});
      }
    } 
    
    else { // Autumn
      suggestions.add({'name': 'Buckwheat', 'reason': 'Short season crop.'});
      suggestions.add({'name': 'Barley', 'reason': 'Drought resistant.'});
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.green, size: 28),
                const SizedBox(width: 12),
                const Text('Smart Recommendations', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(child: Text("Based on ${selectedFieldObject!.soilType} in $currentSeason.", style: const TextStyle(fontSize: 14))),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text("Recommended to Plant:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: suggestions.length,
                itemBuilder: (context, index) {
                  final s = suggestions[index];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.green[100],
                        child: Text(s['name']![0], style: const TextStyle(color: Colors.green)),
                      ),
                      title: Text(s['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(s['reason']!),
                      trailing: IconButton(
                        icon: const Icon(Icons.add_circle, color: Colors.green),
                        onPressed: () {
                          _saveCropToFirebase(s['name']!, currentSeason, 'Seasonal', 'Variable');
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Added ${s['name']} to field!")));
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 45)),
              child: const Text("Close"),
            )
          ],
        ),
      ),
    );
  }

  void _deleteField(String fieldId) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text("Delete Field?"),
      content: const Text("This will delete the field and all crops inside it."),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
        TextButton(onPressed: () async {
          await _usersCollection.doc(uid).collection('fields').doc(fieldId).delete();
          setState(() { selectedFieldId = null; selectedFieldName = null; });
          Navigator.pop(ctx);
        }, child: const Text("Delete", style: TextStyle(color: Colors.red))),
      ],
    ));
  }

  void _deleteCrop(String cropId) {
    if (selectedFieldId == null) return;
    _usersCollection.doc(uid).collection('fields').doc(selectedFieldId).collection('crops').doc(cropId).delete();
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