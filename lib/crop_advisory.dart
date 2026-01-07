import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crop Advisory',
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Arimo',
      ),
      home: const CropAdvisoryScreen(),
    );
  }
}

class Field {
  final String id;
  final String name;
  final String location;
  final String size;
  final String soilType;
  final List<String> crops;
  final bool isActive;

  Field({
    required this.id,
    required this.name,
    required this.location,
    required this.size,
    required this.soilType,
    required this.crops,
    this.isActive = false,
  });
}

class Crop {
  final String id;
  final String name;
  final String season;
  final String duration;
  final String waterNeed;
  final String fieldId;
  final double progress;

  Crop({
    required this.id,
    required this.name,
    required this.season,
    required this.duration,
    required this.waterNeed,
    required this.fieldId,
    this.progress = 0.0,
  });
}

class CropAdvisoryScreen extends StatefulWidget {
  const CropAdvisoryScreen({super.key});

  @override
  State<CropAdvisoryScreen> createState() => _CropAdvisoryScreenState();
}

class _CropAdvisoryScreenState extends State<CropAdvisoryScreen> {
  List<Field> fields = [
    Field(
      id: '1',
      name: 'North Field',
      location: 'Kathmandu Valley, Zone A',
      size: '2.5 acres',
      soilType: 'Clay Loam',
      crops: ['Rice', 'Wheat'],
      isActive: true,
    ),
    Field(
      id: '2',
      name: 'East Field',
      location: 'Kathmandu Valley, Zone B',
      size: '1.8 acres',
      soilType: 'Sandy Loam',
      crops: ['Corn'],
    ),
  ];

  List<Crop> crops = [
    Crop(
      id: '1',
      name: 'Mustard',
      season: 'Winter',
      duration: '80-100 days',
      waterNeed: 'Low',
      fieldId: '1',
      progress: 0.94,
    ),
    Crop(
      id: '2',
      name: 'Lentils',
      season: 'Winter',
      duration: '95-115 days',
      waterNeed: 'Low',
      fieldId: '1',
      progress: 0.89,
    ),
    Crop(
      id: '3',
      name: 'Sugarcane',
      season: 'Spring',
      duration: '300-365 days',
      waterNeed: 'High',
      fieldId: '1',
      progress: 0.65,
    ),
  ];

  String selectedFieldId = '1';

  @override
  Widget build(BuildContext context) {
    final selectedField = fields.firstWhere((field) => field.id == selectedFieldId);
    final fieldCrops = crops.where((crop) => crop.fieldId == selectedFieldId).toList();

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
                color: Color(0xFF2C7C48),
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
                        'Crop Advisory',
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
                      Icon(Icons.location_on, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Manage your fields and crops',
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
                    // Fields Section
                    _buildSection(
                      title: 'Select Field Location',
                      buttonText: 'Add Field',
                      onButtonPressed: () => _showAddFieldDialog(context),
                      children: fields.map((field) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildFieldCard(field),
                        );
                      }).toList(),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Crops Section
                    _buildSection(
                      title: 'Crops in ${selectedField.name}',
                      buttonText: 'Add Crop',
                      onButtonPressed: () => _showAddCropDialog(context),
                      children: [
                        ...fieldCrops.map((crop) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildCropCard(crop),
                          );
                        }).toList(),
                        if (fieldCrops.isEmpty) _buildEmptyCropsState(),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // AI Recommendations Button
                    _buildAIButton(selectedField),
                    
                    const SizedBox(height: 24),
                    
                    // Seasonal Tips
                    _buildSeasonalTips(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String buttonText,
    required VoidCallback onButtonPressed,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF101727),
                fontSize: 16,
                fontFamily: 'Arimo',
                fontWeight: FontWeight.w400,
              ),
            ),
            ElevatedButton(
              onPressed: onButtonPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A63E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.add, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    buttonText,
                    style: const TextStyle(
                      color: Colors.white,
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
        const SizedBox(height: 16),
        Column(children: children),
      ],
    );
  }

  Widget _buildFieldCard(Field field) {
    final isSelected = field.id == selectedFieldId;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFieldId = field.id;
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: _cardShadow,
          border: isSelected ? Border.all(
            color: const Color(0xFF00C850),
            width: 2,
          ) : null,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFDCFCE7) : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.agriculture,
                color: isSelected ? const Color(0xFF101727) : Colors.grey,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    field.name,
                    style: const TextStyle(
                      color: Color(0xFF101727),
                      fontSize: 16,
                      fontFamily: 'Arimo',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    field.location,
                    style: const TextStyle(
                      color: Color(0xFF495565),
                      fontSize: 16,
                      fontFamily: 'Arimo',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        field.size,
                        style: const TextStyle(
                          color: Color(0xFF495565),
                          fontSize: 16,
                          fontFamily: 'Arimo',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        '•',
                        style: TextStyle(
                          color: Color(0xFF495565),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        field.soilType,
                        style: const TextStyle(
                          color: Color(0xFF495565),
                          fontSize: 16,
                          fontFamily: 'Arimo',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: field.crops.map((crop) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          crop,
                          style: const TextStyle(
                            color: Color(0xFF008236),
                            fontSize: 14,
                            fontFamily: 'Arimo',
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                if (isSelected)
                  Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: Color(0xFF00C950),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.circle,
                      color: Colors.white,
                      size: 8,
                    ),
                  ),
                const SizedBox(height: 8),
                IconButton(
                  onPressed: () => _showFieldMenu(context, field),
                  icon: const Icon(Icons.more_vert),
                  color: const Color(0xFF101727),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCropCard(Crop crop) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: _cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        crop.name,
                        style: const TextStyle(
                          color: Color(0xFF101727),
                          fontSize: 16,
                          fontFamily: 'Arimo',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      IconButton(
                        onPressed: () => _showCropDetails(context, crop),
                        icon: const Icon(Icons.info_outline, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  Text(
                    'Season: ${crop.season}',
                    style: const TextStyle(
                      color: Color(0xFF495565),
                      fontSize: 16,
                      fontFamily: 'Arimo',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${(crop.progress * 100).toInt()}%',
                    style: const TextStyle(
                      color: Color(0xFF008236),
                      fontSize: 16,
                      fontFamily: 'Arimo',
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Row(
                children: [
                  const Icon(Icons.schedule, size: 16, color: Color(0xFF495565)),
                  const SizedBox(width: 8),
                  Text(
                    crop.duration,
                    style: const TextStyle(
                      color: Color(0xFF495565),
                      fontSize: 16,
                      fontFamily: 'Arimo',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Row(
                children: [
                  const Icon(Icons.water_drop, size: 16, color: Color(0xFF495565)),
                  const SizedBox(width: 8),
                  Text(
                    '${crop.waterNeed} Water',
                    style: const TextStyle(
                      color: Color(0xFF495565),
                      fontSize: 16,
                      fontFamily: 'Arimo',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              widthFactor: crop.progress,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF00C950),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCropsState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: _cardShadow,
      ),
      child: Column(
        children: [
          const Icon(Icons.agriculture, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No crops added yet',
            style: TextStyle(
              color: Color(0xFF495565),
              fontSize: 16,
              fontFamily: 'Arimo',
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add your first crop to get started',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
              fontFamily: 'Arimo',
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIButton(Field field) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00C850), Color(0xFF00A63D)],
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: _cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showAIRecommendations(context, field),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.auto_awesome, color: Colors.white),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Get AI Recommendations for ${field.name}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
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
      ),
    );
  }

  Widget _buildSeasonalTips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Seasonal Tips',
          style: TextStyle(
            color: Color(0xFF101727),
            fontSize: 16,
            fontFamily: 'Arimo',
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF0FDF4), Color(0xFFDBFBE6)],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: Color(0xFF0D532B)),
                  SizedBox(width: 12),
                  Text(
                    'Winter Growing Season',
                    style: TextStyle(
                      color: Color(0xFF0D532B),
                      fontSize: 16,
                      fontFamily: 'Arimo',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildTipItem(
                Icons.water_drop,
                'Reduce watering frequency in cooler weather',
              ),
              const SizedBox(height: 12),
              _buildTipItem(
                Icons.eco,
                'Consider cover crops to improve soil health',
              ),
              const SizedBox(height: 12),
              _buildTipItem(
                Icons.warning,
                'Monitor frost warnings for sensitive crops',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTipItem(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF016630)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF016630),
              fontSize: 16,
              fontFamily: 'Arimo',
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  void _showAddFieldDialog(BuildContext context) {
    final nameController = TextEditingController();
    final locationController = TextEditingController();
    final sizeController = TextEditingController();
    final soilTypeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Add New Field',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _buildTextField('Field Name', 'e.g., South Field', nameController),
              const SizedBox(height: 16),
              _buildTextField('Location', 'e.g., Kathmandu Valley, Zone C', locationController),
              const SizedBox(height: 16),
              _buildTextField('Size', 'e.g., 3.2 acres', sizeController),
              const SizedBox(height: 16),
              _buildTextField('Soil Type', 'e.g., Loamy Sand', soilTypeController),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD1D5DC),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (nameController.text.isNotEmpty) {
                          setState(() {
                            fields.add(Field(
                              id: DateTime.now().millisecondsSinceEpoch.toString(),
                              name: nameController.text,
                              location: locationController.text,
                              size: sizeController.text,
                              soilType: soilTypeController.text,
                              crops: [],
                            ));
                          });
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00A63E),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Save Field'),
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
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(
              width: 1.3,
              color: const Color(0xFFD0D5DB),
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              border: InputBorder.none,
              hintStyle: const TextStyle(
                color: Color(0x7F0A0A0A),
                fontSize: 16,
                fontFamily: 'Arimo',
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showAddCropDialog(BuildContext context) {
    final TextEditingController customCropController = TextEditingController();
    List<Map<String, String>> commonCrops = [
      {'name': 'Mustard', 'season': 'Winter', 'duration': '80-100 days', 'waterNeed': 'Low'},
      {'name': 'Lentils', 'season': 'Winter', 'duration': '95-115 days', 'waterNeed': 'Low'},
      {'name': 'Sugarcane', 'season': 'Spring', 'duration': '300-365 days', 'waterNeed': 'High'},
      {'name': 'Rice', 'season': 'Summer', 'duration': '100-120 days', 'waterNeed': 'High'},
      {'name': 'Wheat', 'season': 'Winter', 'duration': '110-130 days', 'waterNeed': 'Medium'},
      {'name': 'Corn', 'season': 'Summer', 'duration': '60-100 days', 'waterNeed': 'Medium'},
    ];

    List<bool> isSelected = List.generate(commonCrops.length, (index) => false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateSB) {
          return Container(
            padding: const EdgeInsets.all(16),
            height: MediaQuery.of(context).size.height * 0.9,
            child: Column(
              children: [
                Text(
                  'Select Crops to Add',
                  style: TextStyle(
                    color: const Color(0xFF101727),
                    fontSize: 18,
                    fontFamily: 'Arimo',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                // Custom Crop Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF0FDF4), Color(0xFFEEF5FE)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      width: 1.3,
                      color: const Color(0xFF7AF1A7),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.add_circle_outline, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Add Custom Crop',
                            style: TextStyle(
                              color: const Color(0xFF101727),
                              fontSize: 16,
                              fontFamily: 'Arimo',
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            width: 1.3,
                            color: const Color(0xFF05DF72),
                          ),
                        ),
                        child: TextField(
                          controller: customCropController,
                          decoration: InputDecoration(
                            hintText: 'Enter Crop Name Manually',
                            border: InputBorder.none,
                            hintStyle: TextStyle(
                              color: const Color(0xFF008236).withOpacity(0.7),
                              fontSize: 16,
                              fontFamily: 'Arimo',
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Or select from common crops:',
                  style: TextStyle(
                    color: const Color(0xFF354152),
                    fontSize: 16,
                    fontFamily: 'Arimo',
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: commonCrops.length,
                    itemBuilder: (context, index) {
                      final crop = commonCrops[index];
                      return GestureDetector(
                        onTap: () {
                          setStateSB(() {
                            // Toggle selection
                            isSelected[index] = !isSelected[index];
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(
                              width: 1.3,
                              color: isSelected[index] 
                                ? const Color(0xFF7AF1A7) 
                                : const Color(0xFFD0D5DB),
                            ),
                            borderRadius: BorderRadius.circular(10),
                            color: isSelected[index] ? const Color(0xFFF0FDF4) : Colors.white,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      crop['name']!,
                                      style: TextStyle(
                                        color: const Color(0xFF101727),
                                        fontSize: 16,
                                        fontFamily: 'Arimo',
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Row(
                                          children: [
                                            // FIXED: Changed from Icons.seasonal_shift to Icons.seasons
                                            const Icon(Icons.eco, size: 16, color: Color(0xFF495565)),
                                            const SizedBox(width: 4),
                                            Text(
                                              crop['season']!,
                                              style: TextStyle(
                                                color: const Color(0xFF495565),
                                                fontSize: 14,
                                                fontFamily: 'Arimo',
                                                fontWeight: FontWeight.w400,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(width: 16),
                                        Row(
                                          children: [
                                            const Icon(Icons.schedule, size: 16, color: Color(0xFF495565)),
                                            const SizedBox(width: 4),
                                            Text(
                                              crop['duration']!,
                                              style: TextStyle(
                                                color: const Color(0xFF495565),
                                                fontSize: 14,
                                                fontFamily: 'Arimo',
                                                fontWeight: FontWeight.w400,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(width: 16),
                                        Row(
                                          children: [
                                            const Icon(Icons.water_drop, size: 16, color: Color(0xFF495565)),
                                            const SizedBox(width: 4),
                                            Text(
                                              crop['waterNeed']!,
                                              style: TextStyle(
                                                color: const Color(0xFF495565),
                                                fontSize: 14,
                                                fontFamily: 'Arimo',
                                                fontWeight: FontWeight.w400,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // Checkbox for selection
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: isSelected[index] 
                                      ? const Color(0xFF00A63E) 
                                      : const Color(0xFFD0D5DB),
                                    width: isSelected[index] ? 8 : 2,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // Add selected crops or custom crop
                          if (customCropController.text.isNotEmpty) {
                            // Add custom crop
                            setState(() {
                              crops.add(Crop(
                                id: DateTime.now().millisecondsSinceEpoch.toString(),
                                name: customCropController.text,
                                season: 'Seasonal',
                                duration: '90-120 days',
                                waterNeed: 'Medium',
                                fieldId: selectedFieldId,
                              ));
                            });
                          }
                          
                          // Add selected common crops
                          for (int i = 0; i < commonCrops.length; i++) {
                            if (isSelected[i]) {
                              setState(() {
                                crops.add(Crop(
                                  id: '${DateTime.now().millisecondsSinceEpoch}_$i',
                                  name: commonCrops[i]['name']!,
                                  season: commonCrops[i]['season']!,
                                  duration: commonCrops[i]['duration']!,
                                  waterNeed: commonCrops[i]['waterNeed']!,
                                  fieldId: selectedFieldId,
                                ));
                              });
                            }
                          }
                          
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00A63E),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Add Crop',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontFamily: 'Arimo',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD1D5DC),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Close',
                          style: TextStyle(
                            color: Color(0xFF354152),
                            fontSize: 16,
                            fontFamily: 'Arimo',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showFieldMenu(BuildContext context, Field field) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit Field'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete Field', style: TextStyle(color: Colors.red)),
            onTap: () {
              setState(() {
                fields.removeWhere((f) => f.id == field.id);
              });
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showCropDetails(BuildContext context, Crop crop) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(crop.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Season: ${crop.season}'),
            Text('Duration: ${crop.duration}'),
            Text('Water Need: ${crop.waterNeed}'),
            Text('Progress: ${(crop.progress * 100).toInt()}%'),
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

  void _showAIRecommendations(BuildContext context, Field field) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        height: MediaQuery.of(context).size.height * 0.9,
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Recommendations for North Field',
              style: TextStyle(
                color: Color(0xFF101727),
                fontSize: 16,
                fontFamily: 'Arimo',
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  _buildRecommendationCard(
                    icon: Icons.agriculture,
                    title: 'Fertilizer Application',
                    crop: 'Rice',
                    priority: 'High',
                    priorityColor: Color(0xFFC10007),
                    bgColor: Color(0xFFFFE2E2),
                    description: 'Apply nitrogen fertilizer at the tillering stage for optimal growth.',
                    dueDate: '2024-12-20',
                  ),
                  const SizedBox(height: 16),
                  _buildRecommendationCard(
                    icon: Icons.grass,
                    title: 'Weed Control',
                    crop: 'Wheat',
                    priority: 'Medium',
                    priorityColor: Color(0xFFA65F00),
                    bgColor: Color(0xFFFEF9C2),
                    description: 'Monitor for weed growth and apply herbicides if necessary.',
                    dueDate: '2024-12-18',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD1D5DC),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text(
                'Close',
                style: TextStyle(
                  color: Color(0xFF354152),
                  fontSize: 16,
                  fontFamily: 'Arimo',
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationCard({
    required IconData icon,
    required String title,
    required String crop,
    required String priority,
    required Color priorityColor,
    required Color bgColor,
    required String description,
    required String dueDate,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: _cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
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
                          crop,
                          style: const TextStyle(
                            color: Color(0xFF495565),
                            fontSize: 16,
                            fontFamily: 'Arimo',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        priority,
                        style: TextStyle(
                          color: priorityColor,
                          fontSize: 16,
                          fontFamily: 'Arimo',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(
                    color: Color(0xFF354152),
                    fontSize: 16,
                    fontFamily: 'Arimo',
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: Color(0xFF495565)),
                    const SizedBox(width: 8),
                    Text(
                      'Due: $dueDate',
                      style: const TextStyle(
                        color: Color(0xFF495565),
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
        ],
      ),
    );
  }

  static final List<BoxShadow> _cardShadow = [
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
  ];
}