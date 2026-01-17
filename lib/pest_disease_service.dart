import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'ai_service.dart';

/// Pest & Disease Data Model
class PestAlertData {
  final String id;
  final String pestName;
  final String cropName;
  final String description;
  final String treatment;
  final String severity;
  final DateTime detectedDate;
  final bool resolved;

  PestAlertData({
    required this.id,
    required this.pestName,
    required this.cropName,
    required this.description,
    required this.treatment,
    required this.severity,
    required this.detectedDate,
    this.resolved = false,
  });

  factory PestAlertData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PestAlertData(
      id: doc.id,
      pestName: data['pestName'] ?? 'Unknown',
      cropName: data['cropName'] ?? 'Unknown',
      description: data['description'] ?? '',
      treatment: data['treatment'] ?? '',
      severity: data['severity'] ?? 'Medium',
      detectedDate: (data['detectedDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      resolved: data['resolved'] ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
    'pestName': pestName,
    'cropName': cropName,
    'description': description,
    'treatment': treatment,
    'severity': severity,
    'detectedDate': Timestamp.fromDate(detectedDate),
    'resolved': resolved,
  };
}

class PestScanData {
  final String id;
  final String cropName;
  final DateTime scanDate;
  final String status;
  final double confidence;
  final String aiResponse;

  PestScanData({
    required this.id,
    required this.cropName,
    required this.scanDate,
    required this.status,
    required this.confidence,
    required this.aiResponse,
  });

  factory PestScanData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PestScanData(
      id: doc.id,
      cropName: data['cropName'] ?? 'Unknown',
      scanDate: (data['scanDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] ?? 'Pending',
      confidence: (data['confidence'] as num?)?.toDouble() ?? 0.0,
      aiResponse: data['aiResponse'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'cropName': cropName,
    'scanDate': Timestamp.fromDate(scanDate),
    'status': status,
    'confidence': confidence,
    'aiResponse': aiResponse,
  };
}

/// Pest & Disease Backend Service
class PestDiseaseService {
  static final PestDiseaseService _instance = PestDiseaseService._internal();

  factory PestDiseaseService() {
    return _instance;
  }

  PestDiseaseService._internal();

  final String? uid = FirebaseAuth.instance.currentUser?.uid;
  final db = FirebaseFirestore.instance;

  // Rate limiting & storage protection
  static const int maxScansPerDay = 50; // Max 50 scans per user per day
  static const int maxStorageGB = 5; // Max 5GB per user
  static const Duration scanCooldown = Duration(seconds: 2); // 2 second cooldown between scans
  DateTime? _lastScanTime;

  /// Get stream of active pest alerts
  Stream<List<PestAlertData>> getActiveAlerts() {
    if (uid == null) return Stream.value([]);
    
    return db.collection('users').doc(uid).collection('pestAlerts')
        .where('resolved', isEqualTo: false)
        .orderBy('detectedDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PestAlertData.fromFirestore(doc))
            .toList())
        .handleError((error) {
          print('⚠️ Error fetching alerts: $error');
          return [];
        });
  }

  /// Get stream of recent pest scans
  Stream<List<PestScanData>> getRecentScans({int limit = 5}) {
    if (uid == null) return Stream.value([]);
    
    return db.collection('users').doc(uid).collection('pestScans')
        .orderBy('scanDate', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PestScanData.fromFirestore(doc))
            .toList())
        .handleError((error) {
          print('⚠️ Error fetching scans: $error');
          return [];
        });
  }

  /// Analyze image with AI and create alert if pest detected
  Future<Map<String, dynamic>> analyzeImageWithAI(String imagePath) async {
    if (uid == null) throw Exception('User not authenticated');

    try {
      print('📸 [SERVICE] analyzeImageWithAI START');
      print('📸 [SERVICE] Image path: $imagePath');
      
      print('🤖 [SERVICE] Calling AiService.analyzeImage...');
      final response = await AiService().analyzeImage(imagePath);
      print('🤖 [SERVICE] AiService response received');
      
      if (response == null || response.isEmpty) {
        // Save failed scan
        print('💾 [SERVICE] Saving FAILED scan to Firestore...');
        await _savePestScan(
          cropName: 'Unknown',
          status: 'Failed',
          confidence: 0.0,
          aiResponse: 'API Error: Unable to analyze image',
        );
        throw Exception('No response from AI');
      }

      print('📊 [SERVICE] Parsing response...');
      // Try to extract JSON from response
      Map<String, dynamic> analysisData;
      try {
        analysisData = jsonDecode(response);
        print('✅ [SERVICE] JSON parsed directly');
      } catch (e) {
        print('⚠️ [SERVICE] Direct parse failed, trying regex...');
        final jsonMatch = RegExp(r'\{[^{}]*\}', dotAll: true).firstMatch(response);
        if (jsonMatch != null) {
          analysisData = jsonDecode(jsonMatch.group(0)!);
          print('✅ [SERVICE] JSON extracted via regex');
        } else {
          print('⚠️ [SERVICE] Using fallback data');
          analysisData = {
            'cropName': 'Unknown',
            'status': 'Failed',
            'confidence': 0.0,
            'pestName': null,
            'description': 'Could not parse AI response',
            'treatment': 'Please try again',
            'severity': 'Low'
          };
        }
      }

      print('💾 [SERVICE] Saving scan to Firestore...');
      await _savePestScan(
        cropName: analysisData['cropName'] ?? 'Unknown',
        status: analysisData['status'] ?? 'Pending',
        confidence: (analysisData['confidence'] as num?)?.toDouble() ?? 0.0,
        aiResponse: response,
      );
      print('✅ [SERVICE] Scan saved');

      if (analysisData['status'] != 'Healthy' && analysisData['pestName'] != null) {
        print('⚠️ [SERVICE] Creating alert...');
        await _createPestAlert(
          pestName: analysisData['pestName'] as String,
          cropName: analysisData['cropName'] as String,
          description: analysisData['description'] as String? ?? '',
          treatment: analysisData['treatment'] as String? ?? '',
          severity: analysisData['severity'] as String? ?? 'Medium',
        );
        print('✅ [SERVICE] Alert created');
      }

      print('✅ [SERVICE] analyzeImageWithAI DONE');
      return analysisData;
    } catch (e) {
      print('❌ [SERVICE] analyzeImageWithAI ERROR: $e');
      rethrow;
    }
  }

  /// Save pest scan to Firestore
  Future<void> _savePestScan({
    required String cropName,
    required String status,
    required double confidence,
    required String aiResponse,
  }) async {
    if (uid == null) return;

    try {
      final docRef = await db.collection('users').doc(uid).collection('pestScans').add({
        'cropName': cropName,
        'scanDate': FieldValue.serverTimestamp(),
        'status': status,
        'confidence': confidence,
        'aiResponse': aiResponse,
      });
      print('✅ Pest scan saved with ID: ${docRef.id}');
    } catch (e) {
      print('❌ Error saving scan: $e');
      rethrow;
    }
  }

  /// Create pest alert in Firestore
  Future<void> _createPestAlert({
    required String pestName,
    required String cropName,
    required String description,
    required String treatment,
    required String severity,
  }) async {
    if (uid == null) return;

    try {
      final docRef = await db.collection('users').doc(uid).collection('pestAlerts').add({
        'pestName': pestName,
        'cropName': cropName,
        'description': description,
        'treatment': treatment,
        'severity': severity,
        'detectedDate': FieldValue.serverTimestamp(),
        'resolved': false,
      });
      print('⚠️ Pest alert created with ID: ${docRef.id}');
    } catch (e) {
      print('❌ Error creating alert: $e');
      rethrow;
    }
  }

  /// Mark alert as resolved
  Future<void> resolveAlert(String alertId) async {
    if (uid == null) return;

    try {
      await db.collection('users').doc(uid).collection('pestAlerts').doc(alertId).update({
        'resolved': true,
      });
      print('✅ Alert resolved');
    } catch (e) {
      print('❌ Error resolving alert: $e');
    }
  }

  /// Log audit action
  Future<void> logAction(String action, Map<String, dynamic> data) async {
    if (uid == null) return;

    try {
      await db.collection('users').doc(uid).collection('auditLog').add({
        'action': action,
        'module': 'pest_disease',
        'data': data,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('⚠️ Audit log failed: $e');
    }
  }
}
