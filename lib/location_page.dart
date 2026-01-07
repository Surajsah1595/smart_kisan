import 'package:flutter/material.dart';
import 'home_page.dart'; // For navigation back to home

class LocationPage extends StatefulWidget {
  const LocationPage({Key? key}) : super(key: key);

  @override
  _LocationPageState createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  final Color _primaryGreen = const Color(0xFF2C7C48);
  final Color _lightGreen = const Color(0xFFDBFBE6);
  final Color _accentGreen = const Color(0xFF00C950);
  final Color _white = Colors.white;
  final Color _darkGray = const Color(0xFF101727);
  final Color _mediumGray = const Color(0xFF697282);
  final Color _infoBlue = const Color(0xFF2B7FFF);
  final Color _darkBlue = const Color(0xFF155DFC);

  // Sample location data
  final List<Map<String, dynamic>> _savedFields = [
    {
      'name': 'Main Rice Field',
      'isPrimary': true,
      'area': '2.5 acres',
      'activeCrops': ['Rice', 'Wheat'],
      'coordinates': '27.7172° N, 85.3240° E',
    },
    {
      'name': 'North Wheat Field',
      'isPrimary': false,
      'area': '1.8 acres',
      'activeCrops': ['Wheat'],
      'coordinates': '27.7185° N, 85.3255° E',
    },
    {
      'name': 'South Corn Field',
      'isPrimary': false,
      'area': '3.2 acres',
      'activeCrops': ['Corn', 'Vegetables'],
      'coordinates': '27.7160° N, 85.3230° E',
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
              
              // Current Location Section
              _buildCurrentLocation(),
              
              // Map Section
              _buildMapSection(),
              
              // Add New Field Button
              _buildAddFieldButton(),
              
              // Saved Fields Section
              _buildSavedFieldsSection(),
              
              // Overview Section
              _buildOverviewSection(),
              
              // Insights Banner
              _buildInsightsBanner(),
              
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
                      'My Locations',
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
                      'Manage your farm fields',
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
                child: const Icon(Icons.location_on, color: Colors.white, size: 24),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentLocation() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _primaryGreen.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          width: 1.27,
          color: _primaryGreen,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on, color: _accentGreen, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Location',
                  style: TextStyle(
                    color: _accentGreen,
                    fontSize: 14,
                    fontFamily: 'Arimo',
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Kathmandu, Nepal',
                  style: TextStyle(
                    color: _accentGreen,
                    fontSize: 12,
                    fontFamily: 'Arimo',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _updateLocation,
            child: Text(
              'Update',
              style: TextStyle(
                color: _accentGreen,
                fontSize: 12,
                fontFamily: 'Arimo',
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
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
      child: Column(
        children: [
          Container(
            height: 150,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFDBFBE6), Color(0xFFB8F7CF)],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Stack(
              children: [
                // Map pins
                Positioned(
                  left: 100,
                  top: 50,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2B7FFF),
                      shape: BoxShape.circle,
                      border: Border.all(color: _white, width: 3),
                    ),
                  ),
                ),
                Positioned(
                  left: 180,
                  top: 90,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C950),
                      shape: BoxShape.circle,
                      border: Border.all(color: _white, width: 3),
                    ),
                  ),
                ),
                Positioned(
                  left: 140,
                  top: 120,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFB2C36),
                      shape: BoxShape.circle,
                      border: Border.all(color: _white, width: 3),
                    ),
                  ),
                ),
                const Center(
                  child: Icon(Icons.location_on, size: 48, color: Color(0xFF495565)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'Map View',
                  style: TextStyle(
                    color: const Color(0xFF495565),
                    fontSize: 14,
                    fontFamily: 'Arimo',
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Showing all your fields',
                  style: TextStyle(
                    color: _mediumGray,
                    fontSize: 12,
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

  Widget _buildAddFieldButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: ElevatedButton(
        onPressed: _addNewField,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryGreen,
          foregroundColor: _white,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
          shadowColor: Colors.black.withOpacity(0.1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add, size: 20),
            const SizedBox(width: 8),
            Text(
              'Add New Field',
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'Arimo',
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedFieldsSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Saved Fields',
            style: TextStyle(
              color: _darkGray,
              fontSize: 16,
              fontFamily: 'Arimo',
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 16),
          Column(
            children: _savedFields.map((field) => _buildFieldCard(field)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldCard(Map<String, dynamic> field) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: field['isPrimary'] ? const Color(0xFFF0FDF4) : const Color(0xFFF9FAFB),
              border: field['isPrimary']
                  ? Border.all(color: const Color(0xFF00C950))
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: field['isPrimary'] ? const Color(0xFF00C950) : const Color(0xFF99A1AF),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.agriculture,
                    color: _white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              field['name'],
                              style: TextStyle(
                                color: _darkGray,
                                fontSize: field['isPrimary'] ? 16 : 18,
                                fontFamily: 'Arimo',
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                          if (field['isPrimary'])
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00C950),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Primary',
                                style: TextStyle(
                                  color: _white,
                                  fontSize: 12,
                                  fontFamily: 'Arimo',
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                        ],
                      ),
                      Text(
                        field['area'],
                        style: TextStyle(
                          color: const Color(0xFF495565),
                          fontSize: 14,
                          fontFamily: 'Arimo',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: _mediumGray),
                  onSelected: (value) => _handleFieldAction(value, field),
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
          ),
          // Content
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Active Crops
                Text(
                  'Active Crops',
                  style: TextStyle(
                    color: _mediumGray,
                    fontSize: 12,
                    fontFamily: 'Arimo',
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: (field['activeCrops'] as List<String>)
                      .map((crop) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              crop,
                              style: TextStyle(
                                color: const Color(0xFF008236),
                                fontSize: 12,
                                fontFamily: 'Arimo',
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 16),
                // Coordinates
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Coordinates',
                        style: TextStyle(
                          color: _mediumGray,
                          fontSize: 12,
                          fontFamily: 'Arimo',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        field['coordinates'],
                        style: TextStyle(
                          color: _darkGray,
                          fontSize: 14,
                          fontFamily: 'Cousine',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _navigateToField(field),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF3F4F6),
                          foregroundColor: const Color(0xFF354152),
                          minimumSize: const Size(0, 36),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Navigate',
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Arimo',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _viewFieldDetails(field),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryGreen,
                          foregroundColor: _white,
                          minimumSize: const Size(0, 36),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'View Details',
                          style: TextStyle(
                            fontSize: 14,
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
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Overview',
            style: TextStyle(
              color: _darkGray,
              fontSize: 16,
              fontFamily: 'Arimo',
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildOverviewStat('3', 'Total Fields'),
                _buildOverviewStat('7.5', 'Total Area', subtitle: 'acres'),
                _buildOverviewStat('4', 'Crop Types'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewStat(String value, String label, {String? subtitle}) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: _mediumGray,
              fontSize: 12,
              fontFamily: 'Arimo',
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: _darkGray,
              fontSize: 24,
              fontFamily: 'Arimo',
              fontWeight: FontWeight.w400,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: _mediumGray,
                fontSize: 12,
                fontFamily: 'Arimo',
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInsightsBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_infoBlue, _darkBlue],
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Location-Based Insights',
                  style: TextStyle(
                    color: _white,
                    fontSize: 16,
                    fontFamily: 'Arimo',
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Get weather forecasts, soil recommendations, and alerts specific to each field location.',
                  style: TextStyle(
                    color: const Color(0xFFDAEAFE),
                    fontSize: 14,
                    fontFamily: 'Arimo',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          const Icon(Icons.insights, color: Colors.white, size: 40),
        ],
      ),
    );
  }

  // ============== Event Handlers ==============

  void _updateLocation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Update Location',
          style: TextStyle(
            color: _primaryGreen,
            fontFamily: 'Arimo',
          ),
        ),
        content: Text(
          'This feature will access your current location or allow you to search for a new location in the next phase.',
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
              // Add location update logic here
            },
            child: Text(
              'Update',
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

  void _addNewField() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Add New Field',
          style: TextStyle(
            color: _primaryGreen,
            fontFamily: 'Arimo',
          ),
        ),
        content: Text(
          'This feature will allow you to add a new farm field with location, size, and crop information in the next phase.',
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
              // Add new field logic here
            },
            child: Text(
              'Add Field',
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

  void _handleFieldAction(String action, Map<String, dynamic> field) {
    switch (action) {
      case 'edit':
        _editField(field);
        break;
      case 'delete':
        _deleteField(field);
        break;
    }
  }

  void _editField(Map<String, dynamic> field) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Edit Field',
          style: TextStyle(
            color: _primaryGreen,
            fontFamily: 'Arimo',
          ),
        ),
        content: Text(
          'Editing ${field['name']}. This feature will be fully functional in the next phase.',
          style: TextStyle(
            fontFamily: 'Arimo',
            fontSize: 14,
          ),
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

  void _deleteField(Map<String, dynamic> field) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Field',
          style: TextStyle(
            color: Colors.red,
            fontFamily: 'Arimo',
          ),
        ),
        content: Text(
          'Are you sure you want to delete ${field['name']}?',
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
              // Add delete logic here
            },
            child: const Text(
              'Delete',
              style: TextStyle(
                color: Colors.red,
                fontFamily: 'Arimo',
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToField(Map<String, dynamic> field) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Navigate to Field',
          style: TextStyle(
            color: _primaryGreen,
            fontFamily: 'Arimo',
          ),
        ),
        content: Text(
          'Opening navigation to ${field['name']} at coordinates ${field['coordinates']}. This will open your preferred map app in the next phase.',
          style: TextStyle(
            fontFamily: 'Arimo',
            fontSize: 14,
          ),
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

  void _viewFieldDetails(Map<String, dynamic> field) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Field Details',
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
              'Name: ${field['name']}',
              style: const TextStyle(fontFamily: 'Arimo', fontSize: 14),
            ),
            Text(
              'Area: ${field['area']}',
              style: const TextStyle(fontFamily: 'Arimo', fontSize: 14),
            ),
            Text(
              'Active Crops: ${(field['activeCrops'] as List<String>).join(', ')}',
              style: const TextStyle(fontFamily: 'Arimo', fontSize: 14),
            ),
            Text(
              'Coordinates: ${field['coordinates']}',
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