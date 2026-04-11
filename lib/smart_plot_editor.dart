import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_painter/image_painter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'ai_service.dart';

class SmartPlotEditorScreen extends StatefulWidget {
  final String imagePath;

  const SmartPlotEditorScreen({Key? key, required this.imagePath}) : super(key: key);

  @override
  State<SmartPlotEditorScreen> createState() => _SmartPlotEditorScreenState();
}

class _SmartPlotEditorScreenState extends State<SmartPlotEditorScreen> {
  late final ImagePainterController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ImagePainterController(
      color: Colors.red,
      strokeWidth: 3,
      mode: PaintMode.rect,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  
  String _selectedSoil = 'Loam';
  bool _waterAvailable = false;
  List<String> _recommendations = [];
  bool _isSaving = false;
  bool _isRecommending = false;
  String _validationError = '';

  void _openDetailsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16, right: 16, top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Zone Properties', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  const Text('Soil Type', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSoilTypeIcon('Sandy', Icons.grain, _selectedSoil, (val) {
                        setModalState(() { _selectedSoil = val; _recommendations = []; });
                        setState(() { _selectedSoil = val; });
                      }),
                      _buildSoilTypeIcon('Clay', Icons.layers, _selectedSoil, (val) {
                        setModalState(() { _selectedSoil = val; _recommendations = []; });
                        setState(() { _selectedSoil = val; });
                      }),
                      _buildSoilTypeIcon('Loam', Icons.landscape, _selectedSoil, (val) {
                        setModalState(() { _selectedSoil = val; _recommendations = []; });
                        setState(() { _selectedSoil = val; });
                      }),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SwitchListTile(
                    title: const Text('Water Availability', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(_waterAvailable ? 'Yes (Irrigated)' : 'No (Rainfed/Dry)'),
                    value: _waterAvailable,
                    activeThumbColor: Colors.blue,
                    onChanged: (val) {
                      setModalState(() { _waterAvailable = val; _recommendations = []; _validationError = ''; });
                      setState(() { _waterAvailable = val; });
                    },
                  ),
                  const SizedBox(height: 20),
                  if (_validationError.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _validationError,
                              style: const TextStyle(color: Colors.red, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_recommendations.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Recommended Crops (AI):', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                          const SizedBox(height: 4),
                          Text(_recommendations.join(', '), style: const TextStyle(fontSize: 14)),
                        ],
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isRecommending ? Colors.grey : Colors.green,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isRecommending ? null : () {
                        _generateRecommendations(setModalState);
                      },
                      child: _isRecommending
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                                SizedBox(width: 10),
                                Text('Analyzing Plot...', style: TextStyle(fontSize: 16, color: Colors.white)),
                              ],
                            )
                          : const Text('Recommend Crops', style: TextStyle(fontSize: 16, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          }
        );
      }
    );
  }

  Future<void> _generateRecommendations(StateSetter setModalState) async {
    setModalState(() {
      _isRecommending = true;
      _validationError = '';
      _recommendations = [];
    });
    setState(() { _isRecommending = true; });

    final aiService = AiService();
    final result = await aiService.analyzePlotImage(widget.imagePath, _selectedSoil, _waterAvailable);

    if (result != null) {
      if (result['isValidLand'] == true) {
        List<dynamic> cropsDynamic = result['recommendations'] ?? [];
        List<String> crops = cropsDynamic.map((e) => e.toString()).toList();
        
        if (crops.isEmpty) {
            _generateFallbackRecommendations(setModalState);
        } else {
            setModalState(() { _recommendations = crops; });
            setState(() { _recommendations = crops; });
        }
      } else {
        setModalState(() {
          _validationError = result['message'] ?? 'Image is not identified as agricultural land.';
        });
      }
    } else {
      setModalState(() {
        _validationError = 'Failed to connect to AI. Using default recommendations.';
      });
      _generateFallbackRecommendations(setModalState);
    }

    setModalState(() { _isRecommending = false; });
    setState(() { _isRecommending = false; });
  }

  void _generateFallbackRecommendations(StateSetter setModalState) {
    List<String> crops = [];
    if (_selectedSoil == 'Sandy') {
      if (_waterAvailable) {
        crops = ['Watermelon', 'Muskmelon', 'Cucumber', 'Carrot', 'Potato', 'Radish'];
      } else {
        crops = ['Pearl Millet (Bajra)', 'Sorghum', 'Cluster Beans (Guar)', 'Groundnut (arid)', 'Cowpea'];
      }
    } else if (_selectedSoil == 'Clay') {
      if (_waterAvailable) {
        crops = ['Rice', 'Sugarcane', 'Wheat', 'Cabbage', 'Broccoli', 'Cauliflower', 'Peas'];
      } else {
        crops = ['Cotton', 'Chickpea (Gram)', 'Lentil', 'Safflower', 'Linseed'];
      }
    } else {
      // Loam
      if (_waterAvailable) {
        crops = ['Wheat', 'Maize', 'Tomato', 'Onion', 'Garlic', 'Brinjal (Eggplant)', 'Chili', 'Okra'];
      } else {
        crops = ['Mustard', 'Sunflower', 'Pigeon Pea (Tur)', 'Barley', 'Sesame'];
      }
    }
    setModalState(() { _recommendations = crops; });
    setState(() {
      _recommendations = crops;
    });
  }

  Widget _buildSoilTypeIcon(String label, IconData icon, String currentVal, Function(String) onSelect) {
    bool isSelected = label == currentVal;
    return GestureDetector(
      onTap: () => onSelect(label),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? Colors.green.shade100 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isSelected ? Colors.green : Colors.transparent, width: 2),
            ),
            child: Icon(icon, size: 36, color: isSelected ? Colors.green : Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Colors.green : Colors.black87)),
        ],
      ),
    );
  }

  Future<void> _savePlotData() async {
    setState(() { _isSaving = true; });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      final dataToSave = {
        'originalImagePath': widget.imagePath,
        'soilType': _selectedSoil,
        'waterAvailable': _waterAvailable,
        'recommendations': _recommendations,
        'timestamp': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('smartPlots')
          .add(dataToSave);
          
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Plot Details Saved!')));
        Navigator.pop(context); // Go back after saving
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving: $e')));
      }
    } finally {
      if (mounted) setState(() { _isSaving = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Plot Mapper', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          _isSaving
              ? const Center(child: Padding(padding: EdgeInsets.symmetric(horizontal: 16.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))))
              : IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: _savePlotData,
                  tooltip: 'Save Plot Details',
                ),
        ],
      ),
      body: Stack(
        children: [
          ImagePainter.file(
            File(widget.imagePath),
            controller: _controller,
            scalable: true,
          ),
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                icon: const Icon(Icons.add_location_alt, color: Colors.white),
                label: const Text('Add Info to Selected Zone', style: TextStyle(color: Colors.white, fontSize: 16)),
                onPressed: _openDetailsBottomSheet,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
