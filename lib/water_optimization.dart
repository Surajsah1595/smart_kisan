import 'package:flutter/material.dart';
import 'water_optimization_service.dart';
import 'ai_service.dart';
import 'notification_service.dart';
import 'localization_service.dart';

class WaterOptimizationScreen extends StatefulWidget {
  const WaterOptimizationScreen({super.key});

  @override
  State<WaterOptimizationScreen> createState() => _WaterOptimizationScreenState();
}

class _WaterOptimizationScreenState extends State<WaterOptimizationScreen> {
  final WaterOptimizationService _service = WaterOptimizationService();
  final AiService _aiService = AiService();
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _cropController = TextEditingController();

  String _selectedUnit = 'acres';
  String _selectedSoil = 'loamy';
  bool _isLoading = false;
  Map<String, dynamic>? _result;
  Map<String, dynamic>? _weatherData;
  String _currentLanguage = 'en';

  final List<String> soilTypes = [
    'sandy',
    'sandy-loam',
    'loamy',
    'clay-loam',
    'clay',
    'silty',
  ];

  final List<String> areaUnits = ['acres', 'hectares', 'sqm'];

  final Map<String, Map<String, String>> _translations = {
    'en': {
      'water_optimization': 'Water Optimization',
      'land_area': 'Land Area',
      'crop_type': 'Crop Type',
      'soil_type': 'Soil Type',
      'calculate': 'Calculate Water Need',
      'weather': 'Weather Status',
      'history': 'Calculation History',
      'no_data': 'No calculations yet',
      'enter_area': 'Please enter land area',
      'enter_crop': 'Please enter crop name',
      'water_needed': 'Water Needed',
      'daily_water': 'Daily Water',
      'total_water': 'Total Water Required',
      'growing_days': 'Growing Days',
      'recommendation': 'Recommendation',
      'invalid_crop': 'Invalid crop name. Please enter a real agricultural crop.',
    },
    'hi': {
      'water_optimization': 'जल अनुकूलन',
      'land_area': 'भूमि क्षेत्र',
      'crop_type': 'फसल का प्रकार',
      'soil_type': 'मिट्टी का प्रकार',
      'calculate': 'जल आवश्यकता की गणना करें',
      'weather': 'मौसम की स्थिति',
      'history': 'गणना इतिहास',
      'no_data': 'अभी कोई गणना नहीं',
      'enter_area': 'कृपया भूमि क्षेत्र दर्ज करें',
      'enter_crop': 'कृपया फसल का नाम दर्ज करें',
      'water_needed': 'आवश्यक जल',
      'daily_water': 'दैनिक जल',
      'total_water': 'कुल जल आवश्यक',
      'growing_days': 'बढ़ने के दिन',
      'recommendation': 'सिफारिश',
      'invalid_crop': 'अमान्य फसल। कृपया एक वास्तविक कृषि फसल दर्ज करें।',
    },
  };

  String tr(String key) => _translations[_currentLanguage]?[key] ?? key;

  @override
  void initState() {
    super.initState();
    _currentLanguage = LocalizationService.currentLanguage;
  }

  @override
  void dispose() {
    _areaController.dispose();
    _cropController.dispose();
    super.dispose();
  }

  Future<void> _calculateWater() async {
    if (_areaController.text.isEmpty) {
      _showSnackBar(tr('enter_area'));
      return;
    }

    if (_cropController.text.isEmpty) {
      _showSnackBar(tr('enter_crop'));
      return;
    }

    setState(() {
      _isLoading = true;
      _result = null; // clear previous results to avoid showing stale data
    });

    try {
      final area = double.parse(_areaController.text);
      final cropName = _cropController.text.trim();

      // Use AI to validate crop and get details
      final cropDetailsFromAi = await _getAiCropDetails(cropName);
      print('Crop details from AI: $cropDetailsFromAi');

      // If AI explicitly validated the crop as invalid, stop and show a message
      if (cropDetailsFromAi != null && cropDetailsFromAi['valid'] == false) {
        _showSnackBar(tr('invalid_crop'));
        setState(() => _isLoading = false);
        return;
      }

      if (cropDetailsFromAi == null) {
        // AI validation failed or AI service unavailable — fallback to local calculation
        print('AI validation failed for "$cropName". Falling back to local calculation.');

        // Use the service's built-in accurate ETc value (NOT AI's waterPerDay)
        // The service has scientifically-accurate ETc values for all crops
        final waterResultFallback = _service.calculateWaterRequirement(
          area: area,
          areaUnit: _selectedUnit,
          cropType: cropName,
          soilType: _selectedSoil,
          growingDays: 120,
        );

        final weatherResult = await _service.checkWeatherForWatering();

        // Save fallback calculation
        if (waterResultFallback['success'] == true) {
          await _service.saveCalculation(
            area: area,
            areaUnit: _selectedUnit,
            cropType: cropName,
            soilType: _selectedSoil,
            waterRequired: waterResultFallback['water'] ?? 0,
            dailyWater: waterResultFallback['dailyWater'] ?? 0,
            growingDays: waterResultFallback['growingDays'] ?? 120,
            weatherCondition: weatherResult['condition'] ?? 'Unknown',
          );
        }

        setState(() {
          _result = {
            'success': true,
            'totalWater': waterResultFallback['water'],
            'dailyWater': waterResultFallback['dailyWater'],
            'growingDays': waterResultFallback['growingDays'],
            'recommendation': waterResultFallback['message'],
          };
          _weatherData = weatherResult;
          _isLoading = false;
        });

        _showResultDialog();
        return;
      }

      // Use AI for water calculation
      final waterResult = await _getAiWaterCalculation(
        cropName: cropName,
        area: area,
        areaUnit: _selectedUnit,
        soilType: _selectedSoil,
        cropDetails: cropDetailsFromAi,
      );

      print('AI water calculation result: $waterResult');

      // Get weather check
      final weatherResult = await _service.checkWeatherForWatering();

      // Save to history
      if (waterResult != null && waterResult['success'] == true) {
        try {
          print('About to save calculation for $cropName with total ${waterResult['totalWater']}');
          await _service.saveCalculation(
            area: area,
            areaUnit: _selectedUnit,
            cropType: cropName,
            soilType: _selectedSoil,
            waterRequired: waterResult['totalWater'] ?? 0,
            dailyWater: waterResult['dailyWater'] ?? 0,
            growingDays: waterResult['growingDays'] ?? 120,
            weatherCondition: weatherResult['condition'] ?? 'Unknown',
          );
          print('Save returned without exception');
          
          // Send water optimization notification
          final notificationService = NotificationService();
          await notificationService.notifyWaterAlertResolved(
            fieldName: cropName,
            action: 'Water optimization calculated: ${waterResult['totalWater']?.toStringAsFixed(0) ?? "N/A"} liters required',
          );
        } catch (e) {
          print('Exception while saving calculation: $e');
        }
      }

      setState(() {
        _result = waterResult;
        _weatherData = weatherResult;
        _isLoading = false;
      });

      if (waterResult != null) {
        _showResultDialog();
      }
    } catch (e) {
      _showSnackBar('Error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<Map<String, dynamic>?> _getAiCropDetails(String cropName) async {
    try {
      final prompt = '''You are an agriculture expert. Validate if "$cropName" is a real agricultural crop.
Return ONLY JSON (no markdown, no extra text):
{
  "valid": true/false,
  "cropName": "standard name",
  "growingDays": number (50-400),
  "waterPerDay": number in mm/day (15-120 mm/day, where 1mm/day = 10L/day/hectare),
  "season": "Kharif/Rabi/Summer/Year-round",
  "region": "suitable regions"
}
RESPOND ONLY WITH JSON.''';

      final response = await _aiService.sendMessage(prompt);
      print('AI raw crop-details response: $response');
      if (response == null) return null;
      if (response.toString().startsWith('Error:')) {
        print('AI service error while fetching crop details: $response');
        return null;
      }

      // Parse JSON
      final jsonData = _parseJsonResponse(response);
      if (jsonData != null) {
        // Return whatever the AI returned (may include valid: false)
        return jsonData;
      }
    } catch (e) {
      print('Error getting crop details: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> _getAiWaterCalculation({
    required String cropName,
    required double area,
    required String areaUnit,
    required String soilType,
    required Map<String, dynamic> cropDetails,
  }) async {
    try {
      // Use the service's accurate calculation
      // IGNORE the AI's waterPerDay - use the service's built-in ETc values instead
      // The service has scientifically-accurate ETc values from FAO standards
      final result = _service.calculateWaterRequirement(
        area: area,
        areaUnit: areaUnit,
        cropType: cropName,
        soilType: soilType,
        growingDays: cropDetails['growingDays'] ?? 120,
      );

      print('✅ Water calculation result: $result');
      
      if (result['success'] == true) {
        return {
          'success': true,
          'cropName': result['crop'] ?? cropName,
          'totalWater': result['water'] ?? 0,
          'dailyWater': result['dailyWater'] ?? 0,
          'growingDays': result['growingDays'] ?? 120,
          'soilFactor': _getSoilFactor(soilType),
          'recommendation': result['message'] ?? 'Watering optimization calculated',
        };
      }
    } catch (e) {
      print('❌ Error in water calculation: $e');
    }
    return null;
  }

  /// Get soil factor for display
  double _getSoilFactor(String soilType) {
    final factors = {
      'sandy': 1.3,
      'sandy-loam': 1.15,
      'loamy': 1.0,
      'clay-loam': 0.9,
      'clay': 0.75,
      'silty': 1.05,
    };
    return factors[soilType.toLowerCase()] ?? 1.0;
  }

  // Removed unused _convertToHectares method

  String _formatNum(dynamic n, {int decimals = 0}) {
    if (n == null) return '0';
    if (n is num) return n.toDouble().toStringAsFixed(decimals);
    // try parsing
    final parsed = num.tryParse(n.toString());
    if (parsed != null) return parsed.toDouble().toStringAsFixed(decimals);
    return n.toString();
  }

  String _capitalize(String? s) {
    if (s == null) return '';
    if (s.isEmpty) return '';
    return '${s[0].toUpperCase()}${s.substring(1)}';
  }

  Map<String, dynamic>? _parseJsonResponse(String response) {
    try {
      String cleanResponse = response.replaceAll('```json', '').replaceAll('```', '').trim();
      final startIndex = cleanResponse.indexOf('{');
      final endIndex = cleanResponse.lastIndexOf('}');

      if (startIndex == -1 || endIndex == -1) return null;

      final jsonString = cleanResponse.substring(startIndex, endIndex + 1);
      return _simpleJsonParse(jsonString);
    } catch (e) {
      return null;
    }
  }

  Map<String, dynamic> _simpleJsonParse(String jsonString) {
    final result = <String, dynamic>{};

    // Parse success
    result['success'] = jsonString.contains('"success": true');

    // Parse valid
    result['valid'] = jsonString.contains('"valid": true');

    // Parse string fields
    final fields = ['cropName', 'season', 'region', 'recommendation'];
    for (final field in fields) {
      final match = RegExp('"$field":\\s*"([^"]+)"').firstMatch(jsonString);
      if (match != null) result[field] = match.group(1);
    }

    // Parse number fields
    final numberFields = {
      'growingDays': 'growingDays',
      'waterPerDay': 'waterPerDay',
      'totalWater': 'totalWater',
      'dailyWater': 'dailyWater',
      'soilFactor': 'soilFactor',
    };

    for (final entry in numberFields.entries) {
      final match = RegExp('"${entry.key}":\\s*([\\d.]+)').firstMatch(jsonString);
      if (match != null) {
        final value = match.group(1)!;
        result[entry.value] = value.contains('.') ? double.parse(value) : int.parse(value);
      }
    }

    return result;
  }

  void _showResultDialog() {
    if (_result == null || !(_result?['success'] ?? false)) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          color: Colors.white,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  color: Colors.blue.shade700,
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      const Icon(Icons.water_drop, color: Colors.white, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Water Recommendation',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Weather Status
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          border: Border.all(color: Colors.blue.shade200),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _weatherData?['message'] ?? 'Weather check done',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Total Water
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          border: Border.all(color: Colors.blue.shade400, width: 2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Water Required',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_formatNum(_result?['totalWater'], decimals: 0)} Liters',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Daily Water
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          border: Border.all(color: Colors.blue.shade200),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Daily Water',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue.shade700,
                              ),
                            ),
                            Text(
                              '${_formatNum(_result?['dailyWater'], decimals: 0)} L/day',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Growing Days
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          border: Border.all(color: Colors.green.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Growing Season',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.green.shade700,
                              ),
                            ),
                            Text(
                              '${_result?['growingDays'] ?? 120} days',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // AI Recommendation
                      if (_result?['recommendation'] != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            border: Border.all(color: Colors.orange.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'AI Recommendation',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade900,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _result?['recommendation'] ?? '',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                // Close button
                Padding(
                  padding: const EdgeInsets.only(bottom: 16, right: 16, left: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Close',
                        style: TextStyle(color: Colors.white),
                      ),
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

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.blue.shade700,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('water_optimization')),
        backgroundColor: Colors.blue.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Input Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Land Area with Unit
                    Text(
                      tr('land_area'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _areaController,
                            keyboardType:
                                const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              hintText: 'Enter area',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.blue.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    BorderSide(color: Colors.blue.shade700, width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 1,
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.blue.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: DropdownButton<String>(
                              value: _selectedUnit,
                              isExpanded: true,
                              underline: const SizedBox(),
                              items: areaUnits
                                  .map((unit) => DropdownMenuItem(
                                        value: unit,
                                        child: Text(unit),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) setState(() => _selectedUnit = value);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Crop Type - Free Text Input
                    Text(
                      tr('crop_type'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _cropController,
                      decoration: InputDecoration(
                        hintText: 'Enter any crop (e.g., wheat, tomato, rice)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.blue.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Colors.blue.shade700,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Soil Type
                    Text(
                      tr('soil_type'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedSoil,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.blue.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              BorderSide(color: Colors.blue.shade700, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      items: soilTypes
                          .map((soil) => DropdownMenuItem(
                                value: soil,
                                child: Text(_capitalize(soil.replaceAll('-', ' '))),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => _selectedSoil = value);
                      },
                    ),
                    const SizedBox(height: 24),

                    // Calculate Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _calculateWater,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          disabledBackgroundColor: Colors.grey,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(Colors.white),
                                ),
                              )
                            : Text(
                                tr('calculate'),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // History Title
            Text(
              tr('history'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade900,
              ),
            ),
            const SizedBox(height: 12),

            // History List
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _service.getCalculationHistory(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        tr('no_data'),
                        style: TextStyle(color: Colors.blue.shade500),
                      ),
                    ),
                  );
                }

                final history = snapshot.data ?? [];
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final item = history[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.blue.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '${_capitalize(item['crop']?.toString())} - ${item['area'].toStringAsFixed(1)} ${item['areaUnit'] ?? 'acres'}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Colors.blue.shade900,
                                    ),
                                  ),
                                ),
                                Text(
                                  item['date'] ?? '',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue.shade500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Total: ${_formatNum(item['water'], decimals: 0)} L',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue.shade700,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      'Daily: ${_formatNum(item['dailyWater'], decimals: 0)} L',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Soil: ${_capitalize(item['soilType']?.replaceAll('-', ' ') ?? 'N/A')}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue.shade600,
                                      ),
                                    ),
                                    Text(
                                      'Days: ${item['growingDays'] ?? 120}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

