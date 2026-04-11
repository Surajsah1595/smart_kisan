import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'ai_service.dart';
import 'notification_service.dart';

/// Product Recommendation Model
class ProductRecommendation {
  final String id;
  final String productName;
  final String category; // e.g., 'Fungicide', 'Insecticide', 'Organic', 'Herbicide'
  final String description;
  final double price; // Approximate price in local currency
  final String dosage; // How to apply/use
  final List<String> treatsDisease; // List of diseases/pests this treats
  final String availability; // 'Available', 'Limited', 'Out of Stock'
  final double rating; // 0-5 rating
  final int reviews;
  final String manufacturer;
  final String chemicalComposition;
  final String safetyWarnings;

  ProductRecommendation({
    required this.id,
    required this.productName,
    required this.category,
    required this.description,
    required this.price,
    required this.dosage,
    required this.treatsDisease,
    required this.availability,
    required this.rating,
    required this.reviews,
    required this.manufacturer,
    required this.chemicalComposition,
    required this.safetyWarnings,
  });

  factory ProductRecommendation.fromMap(Map<String, dynamic> map) {
    return ProductRecommendation(
      id: map['id'] ?? '',
      productName: map['productName'] ?? '',
      category: map['category'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      dosage: map['dosage'] ?? '',
      treatsDisease: List<String>.from(map['treatsDisease'] ?? []),
      availability: map['availability'] ?? 'Available',
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      reviews: map['reviews'] ?? 0,
      manufacturer: map['manufacturer'] ?? '',
      chemicalComposition: map['chemicalComposition'] ?? '',
      safetyWarnings: map['safetyWarnings'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'productName': productName,
    'category': category,
    'description': description,
    'price': price,
    'dosage': dosage,
    'treatsDisease': treatsDisease,
    'availability': availability,
    'rating': rating,
    'reviews': reviews,
    'manufacturer': manufacturer,
    'chemicalComposition': chemicalComposition,
    'safetyWarnings': safetyWarnings,
  };
}

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
  final List<ProductRecommendation> productRecommendations;

  PestAlertData({
    required this.id,
    required this.pestName,
    required this.cropName,
    required this.description,
    required this.treatment,
    required this.severity,
    required this.detectedDate,
    this.resolved = false,
    this.productRecommendations = const [],
  });

  factory PestAlertData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    List<ProductRecommendation> products = [];
    
    if (data['productRecommendations'] != null) {
      products = (data['productRecommendations'] as List)
          .map((p) => ProductRecommendation.fromMap(p as Map<String, dynamic>))
          .toList();
    }
    
    return PestAlertData(
      id: doc.id,
      pestName: data['pestName'] ?? 'Unknown',
      cropName: data['cropName'] ?? 'Unknown',
      description: data['description'] ?? '',
      treatment: data['treatment'] ?? '',
      severity: data['severity'] ?? 'Medium',
      detectedDate: (data['detectedDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      resolved: data['resolved'] ?? false,
      productRecommendations: products,
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
    'productRecommendations': productRecommendations.map((p) => p.toMap()).toList(),
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
  final NotificationService _notificationService = NotificationService();

  factory PestDiseaseService() {
    return _instance;
  }

  PestDiseaseService._internal();

  final String? uid = FirebaseAuth.instance.currentUser?.uid;
  final db = FirebaseFirestore.instance;
  final firebase_storage.FirebaseStorage _storage = firebase_storage.FirebaseStorage.instance;

  // Rate limiting & storage protection
  static const int maxScansPerDay = 50; // Max 50 scans per user per day
  static const int maxStorageGB = 5; // Max 5GB per user
  static const Duration scanCooldown = Duration(seconds: 2); // 2 second cooldown between scans

  /// Product Database - Map of diseases/pests to recommended products
  final Map<String, List<Map<String, dynamic>>> _productDatabase = {
    // Rice diseases and pests
    'Brown Spot': [
      {
        'productName': 'Mancozeb 75% WP',
        'category': 'Fungicide',
        'description': 'Broad-spectrum fungicide effective against brown spot in rice',
        'price': 350.0,
        'dosage': '2 kg per hectare, spray every 7-10 days',
        'availability': 'Available',
        'rating': 4.5,
        'reviews': 230,
        'manufacturer': 'Syngenta/Bayer',
        'chemicalComposition': 'Mancozeb (75%)',
        'safetyWarnings': 'Wear protective gloves and mask during application',
      },
      {
        'productName': 'Tricyclazole 75% WP',
        'category': 'Fungicide',
        'description': 'Systemic fungicide for blast and brown spot diseases',
        'price': 450.0,
        'dosage': '1 kg per hectare',
        'availability': 'Available',
        'rating': 4.7,
        'reviews': 189,
        'manufacturer': 'BASF',
        'chemicalComposition': 'Tricyclazole (75%)',
        'safetyWarnings': 'Do not spray on flowers or open blossoms',
      },
    ],
    'Leaf Blast': [
      {
        'productName': 'Tricyclazole 75% WP',
        'category': 'Fungicide',
        'description': 'Most effective fungicide for blast disease control',
        'price': 450.0,
        'dosage': '1 kg per hectare, spray at boot and heading stage',
        'availability': 'Available',
        'rating': 4.8,
        'reviews': 412,
        'manufacturer': 'BASF',
        'chemicalComposition': 'Tricyclazole (75%)',
        'safetyWarnings': 'Apply in the evening to avoid leaf burn',
      },
      {
        'productName': 'Hexaconazole 5% EC',
        'category': 'Fungicide',
        'description': 'Contact and systemic fungicide for blast management',
        'price': 280.0,
        'dosage': '1-1.5 liters per hectare',
        'availability': 'Available',
        'rating': 4.3,
        'reviews': 156,
        'manufacturer': 'Rallis',
        'chemicalComposition': 'Hexaconazole (5%)',
        'safetyWarnings': 'Keep away from children and animals',
      },
    ],
    'Panicle Blast': [
      {
        'productName': 'Tricyclazole 75% WP',
        'category': 'Fungicide',
        'description': 'Preventive fungicide for panicle blast',
        'price': 450.0,
        'dosage': '1 kg per hectare at heading stage',
        'availability': 'Available',
        'rating': 4.8,
        'reviews': 412,
        'manufacturer': 'BASF',
        'chemicalComposition': 'Tricyclazole (75%)',
        'safetyWarnings': 'Apply in the evening to avoid leaf burn',
      },
    ],
    'Stem Rot': [
      {
        'productName': 'Carbendazim 50% WP',
        'category': 'Fungicide',
        'description': 'Systemic fungicide for stem rot disease control',
        'price': 320.0,
        'dosage': '1 kg per hectare',
        'availability': 'Available',
        'rating': 4.4,
        'reviews': 198,
        'manufacturer': 'FMC',
        'chemicalComposition': 'Carbendazim (50%)',
        'safetyWarnings': 'Do not use continuously to prevent resistance',
      },
    ],
    'Rice Sheath Blight': [
      {
        'productName': 'Bacillus subtilis 1% WP (Organic)',
        'category': 'Organic',
        'description': 'Bio-fungicide for sheath blight management',
        'price': 200.0,
        'dosage': '2.5 kg per hectare, spray 3 times',
        'availability': 'Available',
        'rating': 4.2,
        'reviews': 142,
        'manufacturer': 'IISR',
        'chemicalComposition': 'Bacillus subtilis (1%)',
        'safetyWarnings': 'Safe for organic farming',
      },
      {
        'productName': 'Mancozeb 75% WP',
        'category': 'Fungicide',
        'description': 'Preventive fungicide for sheath blight',
        'price': 350.0,
        'dosage': '2 kg per hectare',
        'availability': 'Available',
        'rating': 4.5,
        'reviews': 230,
        'manufacturer': 'Syngenta',
        'chemicalComposition': 'Mancozeb (75%)',
        'safetyWarnings': 'Wear protective equipment during application',
      },
    ],
    // Rice pests
    'Brown Plant Hopper': [
      {
        'productName': 'Imidacloprid 17.8% SL',
        'category': 'Insecticide',
        'description': 'Systemic insecticide for sucking pests including BPH',
        'price': 380.0,
        'dosage': '500 ml per hectare (2500 liters water)',
        'availability': 'Available',
        'rating': 4.6,
        'reviews': 287,
        'manufacturer': 'Bayer',
        'chemicalComposition': 'Imidacloprid (17.8%)',
        'safetyWarnings': 'Avoid spray on flowers, toxic to bees',
      },
      {
        'productName': 'Thiamethoxam 25% WG',
        'category': 'Insecticide',
        'description': 'Broad-spectrum insecticide for BPH and leafhoppers',
        'price': 420.0,
        'dosage': '1 kg per hectare',
        'availability': 'Available',
        'rating': 4.7,
        'reviews': 315,
        'manufacturer': 'Syngenta',
        'chemicalComposition': 'Thiamethoxam (25%)',
        'safetyWarnings': 'Do not mix with alkaline pesticides',
      },
    ],
    'White Backed Plant Hopper': [
      {
        'productName': 'Imidacloprid 17.8% SL',
        'category': 'Insecticide',
        'description': 'Effective against WBPH',
        'price': 380.0,
        'dosage': '500 ml per hectare',
        'availability': 'Available',
        'rating': 4.6,
        'reviews': 287,
        'manufacturer': 'Bayer',
        'chemicalComposition': 'Imidacloprid (17.8%)',
        'safetyWarnings': 'Apply in early morning or late evening',
      },
    ],
    'Leaf Folder': [
      {
        'productName': 'Spinosad 45% SC',
        'category': 'Organic',
        'description': 'Bio-pesticide for caterpillar control',
        'price': 320.0,
        'dosage': '1.5 liters per hectare',
        'availability': 'Available',
        'rating': 4.4,
        'reviews': 165,
        'manufacturer': 'Dow AgroSciences',
        'chemicalComposition': 'Spinosad (45%)',
        'safetyWarnings': 'Safe for organic farming, do not use with fungicides',
      },
      {
        'productName': 'Chlorpyrifos 20% EC',
        'category': 'Insecticide',
        'description': 'Contact insecticide for leaf folder larvae',
        'price': 280.0,
        'dosage': '1 liter per hectare',
        'availability': 'Available',
        'rating': 4.3,
        'reviews': 198,
        'manufacturer': 'Syngenta',
        'chemicalComposition': 'Chlorpyrifos (20%)',
        'safetyWarnings': 'Harmful if ingested, keep away from children',
      },
    ],
    'Rice Stem Borer': [
      {
        'productName': 'Chlorpyrifos 20% EC',
        'category': 'Insecticide',
        'description': 'Contact insecticide for stem borer control',
        'price': 280.0,
        'dosage': '1 liter per hectare, spray at tillering stage',
        'availability': 'Available',
        'rating': 4.3,
        'reviews': 198,
        'manufacturer': 'Syngenta',
        'chemicalComposition': 'Chlorpyrifos (20%)',
        'safetyWarnings': 'Apply in early morning or late evening',
      },
      {
        'productName': 'Cypermethrin 10% EC',
        'category': 'Insecticide',
        'description': 'Synthetic pyrethroid for stem and shoot borer',
        'price': 250.0,
        'dosage': '1 liter per hectare',
        'availability': 'Available',
        'rating': 4.2,
        'reviews': 154,
        'manufacturer': 'FMC',
        'chemicalComposition': 'Cypermethrin (10%)',
        'safetyWarnings': 'Toxic to aquatic organisms',
      },
    ],
    // Wheat diseases and pests
    'Powdery Mildew': [
      {
        'productName': 'Sulphur 80% WP',
        'category': 'Fungicide',
        'description': 'Elemental sulfur for powdery mildew control',
        'price': 180.0,
        'dosage': '1 kg per hectare',
        'availability': 'Available',
        'rating': 4.3,
        'reviews': 201,
        'manufacturer': 'Multiple',
        'chemicalComposition': 'Sulphur (80%)',
        'safetyWarnings': 'Do not use with oils or in hot weather',
      },
      {
        'productName': 'Hexaconazole 5% EC',
        'category': 'Fungicide',
        'description': 'Systemic fungicide for powdery mildew',
        'price': 280.0,
        'dosage': '1-1.5 liters per hectare',
        'availability': 'Available',
        'rating': 4.5,
        'reviews': 176,
        'manufacturer': 'Rallis',
        'chemicalComposition': 'Hexaconazole (5%)',
        'safetyWarnings': 'Keep away from children and animals',
      },
    ],
    'Rust': [
      {
        'productName': 'Propiconazole 25% EC',
        'category': 'Fungicide',
        'description': 'Systemic fungicide for leaf and stem rust',
        'price': 320.0,
        'dosage': '1 liter per hectare',
        'availability': 'Available',
        'rating': 4.6,
        'reviews': 243,
        'manufacturer': 'Syngenta',
        'chemicalComposition': 'Propiconazole (25%)',
        'safetyWarnings': 'Do not spray during extreme heat',
      },
      {
        'productName': 'Mancozeb 75% WP',
        'category': 'Fungicide',
        'description': 'Broad-spectrum fungicide for rust management',
        'price': 350.0,
        'dosage': '2 kg per hectare',
        'availability': 'Available',
        'rating': 4.4,
        'reviews': 189,
        'manufacturer': 'Syngenta',
        'chemicalComposition': 'Mancozeb (75%)',
        'safetyWarnings': 'Wear protective equipment',
      },
    ],
    'Septoria': [
      {
        'productName': 'Mancozeb 75% WP',
        'category': 'Fungicide',
        'description': 'Contact fungicide for Septoria leaf blotch',
        'price': 350.0,
        'dosage': '2 kg per hectare',
        'availability': 'Available',
        'rating': 4.5,
        'reviews': 230,
        'manufacturer': 'Syngenta',
        'chemicalComposition': 'Mancozeb (75%)',
        'safetyWarnings': 'Wear protective gloves and mask',
      },
    ],
    'Armyworm': [
      {
        'productName': 'Spinosad 45% SC',
        'category': 'Organic',
        'description': 'Bio-pesticide for armyworm larvae',
        'price': 320.0,
        'dosage': '1.5 liters per hectare',
        'availability': 'Available',
        'rating': 4.4,
        'reviews': 165,
        'manufacturer': 'Dow',
        'chemicalComposition': 'Spinosad (45%)',
        'safetyWarnings': 'Safe for organic farming',
      },
      {
        'productName': 'Chlorpyrifos 20% EC',
        'category': 'Insecticide',
        'description': 'Contact insecticide for armyworm control',
        'price': 280.0,
        'dosage': '1 liter per hectare',
        'availability': 'Available',
        'rating': 4.3,
        'reviews': 198,
        'manufacturer': 'Syngenta',
        'chemicalComposition': 'Chlorpyrifos (20%)',
        'safetyWarnings': 'Keep away from children',
      },
    ],
    // Vegetable diseases (Tomato, Pepper, etc.)
    'Late Blight': [
      {
        'productName': 'Mancozeb 75% WP',
        'category': 'Fungicide',
        'description': 'Preventive fungicide for late blight',
        'price': 350.0,
        'dosage': '2 kg per hectare',
        'availability': 'Available',
        'rating': 4.5,
        'reviews': 230,
        'manufacturer': 'Syngenta',
        'chemicalComposition': 'Mancozeb (75%)',
        'safetyWarnings': 'Apply every 7-10 days during disease season',
      },
      {
        'productName': 'Ridomil Gold (Metalaxyl+Mancozeb)',
        'category': 'Fungicide',
        'description': 'Systemic + contact fungicide for late blight',
        'price': 450.0,
        'dosage': '2.5 kg per hectare',
        'availability': 'Available',
        'rating': 4.7,
        'reviews': 198,
        'manufacturer': 'Syngenta',
        'chemicalComposition': 'Metalaxyl + Mancozeb',
        'safetyWarnings': 'Do not use continuously',
      },
    ],
    'Early Blight': [
      {
        'productName': 'Mancozeb 75% WP',
        'category': 'Fungicide',
        'description': 'Effective against early blight of tomato',
        'price': 350.0,
        'dosage': '2 kg per hectare',
        'availability': 'Available',
        'rating': 4.5,
        'reviews': 230,
        'manufacturer': 'Syngenta',
        'chemicalComposition': 'Mancozeb (75%)',
        'safetyWarnings': 'Wear protective equipment',
      },
    ],
    'Powdery Mildew (Vegetables)': [
      {
        'productName': 'Sulphur 80% WP',
        'category': 'Fungicide',
        'description': 'Organic-approved fungicide for powdery mildew',
        'price': 180.0,
        'dosage': '1 kg per hectare',
        'availability': 'Available',
        'rating': 4.3,
        'reviews': 201,
        'manufacturer': 'Multiple',
        'chemicalComposition': 'Sulphur (80%)',
        'safetyWarnings': 'Do not use with oils',
      },
    ],
    'Yellowing': [
      {
        'productName': 'Imidacloprid 17.8% SL',
        'category': 'Insecticide',
        'description': 'For virus vector control (whiteflies, aphids)',
        'price': 380.0,
        'dosage': '500 ml per hectare',
        'availability': 'Available',
        'rating': 4.6,
        'reviews': 287,
        'manufacturer': 'Bayer',
        'chemicalComposition': 'Imidacloprid (17.8%)',
        'safetyWarnings': 'Toxic to bees',
      },
    ],
    // Default for common pests
    'Aphid': [
      {
        'productName': 'Imidacloprid 17.8% SL',
        'category': 'Insecticide',
        'description': 'Systemic insecticide for aphids',
        'price': 380.0,
        'dosage': '500 ml per hectare',
        'availability': 'Available',
        'rating': 4.6,
        'reviews': 287,
        'manufacturer': 'Bayer',
        'chemicalComposition': 'Imidacloprid (17.8%)',
        'safetyWarnings': 'Avoid application on flowers',
      },
      {
        'productName': 'Acetamiprid 20% SP',
        'category': 'Insecticide',
        'description': 'Selective insecticide for aphids',
        'price': 320.0,
        'dosage': '0.5 kg per hectare',
        'availability': 'Available',
        'rating': 4.4,
        'reviews': 156,
        'manufacturer': 'Syngenta',
        'chemicalComposition': 'Acetamiprid (20%)',
        'safetyWarnings': 'Do not mix with other pesticides',
      },
    ],
    'Whitefly': [
      {
        'productName': 'Imidacloprid 17.8% SL',
        'category': 'Insecticide',
        'description': 'Systemic insecticide for whiteflies',
        'price': 380.0,
        'dosage': '500 ml per hectare',
        'availability': 'Available',
        'rating': 4.6,
        'reviews': 287,
        'manufacturer': 'Bayer',
        'chemicalComposition': 'Imidacloprid (17.8%)',
        'safetyWarnings': 'Apply in early morning or evening',
      },
    ],
  };

  /// Get product recommendations for a specific pest/disease
  List<ProductRecommendation> getProductRecommendations(String pestOrDiseaseName) {
    final recommendations = <ProductRecommendation>[];
    final searchTerm = pestOrDiseaseName.toLowerCase().trim();
    
    // Direct lookup
    if (_productDatabase.containsKey(pestOrDiseaseName)) {
      final products = _productDatabase[pestOrDiseaseName]!;
      for (int i = 0; i < products.length; i++) {
        recommendations.add(ProductRecommendation.fromMap({
          'id': '${pestOrDiseaseName}_$i',
          ...products[i],
        }));
      }
      return recommendations;
    }
    
    // Fuzzy search for similar diseases
    for (final key in _productDatabase.keys) {
      if (key.toLowerCase().contains(searchTerm) || searchTerm.contains(key.toLowerCase())) {
        final products = _productDatabase[key]!;
        for (int i = 0; i < products.length; i++) {
          recommendations.add(ProductRecommendation.fromMap({
            'id': '${key}_$i',
            ...products[i],
          }));
        }
        if (recommendations.isNotEmpty) return recommendations;
      }
    }
    
    // If still no match, provide general purpose recommendations
    return _getGeneralRecommendations();
  }

  /// Get general recommendations
  List<ProductRecommendation> _getGeneralRecommendations() {
    return [
      ProductRecommendation.fromMap({
        'id': 'general_1',
        'productName': 'Neem Oil 3% EC',
        'category': 'Organic',
        'description': 'Broad-spectrum bio-pesticide for various pests and diseases',
        'price': 200.0,
        'dosage': '3-5% solution spray',
        'treatsDisease': ['General Pests', 'Fungi'],
        'availability': 'Available',
        'rating': 4.3,
        'reviews': 412,
        'manufacturer': 'Multiple',
        'chemicalComposition': 'Neem Oil (3%)',
        'safetyWarnings': 'Safe for organic farming',
      }),
      ProductRecommendation.fromMap({
        'id': 'general_2',
        'productName': 'Bordeaux Mixture',
        'category': 'Fungicide',
        'description': 'Broad-spectrum fungicide for plant disease control',
        'price': 150.0,
        'dosage': '1% solution',
        'treatsDisease': ['Fungal Diseases'],
        'availability': 'Available',
        'rating': 4.2,
        'reviews': 287,
        'manufacturer': 'Multiple',
        'chemicalComposition': 'Copper Sulphate + Calcium Hydroxide',
        'safetyWarnings': 'Avoid inhalation',
      }),
    ];
  }

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
  Future<Map<String, dynamic>> analyzeImageWithAI(String imagePath, {String? imageUrl}) async {
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

      // Check if it's a wrong object (not a plant)
      if (analysisData['status'] == 'Not a Plant') {
        print('⚠️ [SERVICE] Wrong object detected - not a plant');
        analysisData['description'] = 'This image does not contain a plant or crop. Please scan a plant or crop image.';
        analysisData['confidence'] = 0.0;
      }

      print('💾 [SERVICE] Saving scan to Firestore...');
      await _savePestScan(
        cropName: analysisData['cropName'] ?? 'Unknown',
        status: analysisData['status'] ?? 'Pending',
        confidence: (analysisData['confidence'] as num?)?.toDouble() ?? 0.0,
        aiResponse: response,
        imageUrl: imageUrl,
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
    String? imageUrl,
  }) async {
    if (uid == null) return;

    try {
      final docRef = await db.collection('users').doc(uid).collection('pestScans').add({
        'cropName': cropName,
        'scanDate': FieldValue.serverTimestamp(),
        'status': status,
        'confidence': confidence,
        'aiResponse': aiResponse,
        if (imageUrl != null) 'imageUrl': imageUrl,
      });
      print('✅ Pest scan saved with ID: ${docRef.id}');
    } catch (e) {
      print('❌ Error saving scan: $e');
      rethrow;
    }
  }

  /// Upload an image file to Firebase Storage and return its download URL.
  Future<String> uploadImageToStorage(String localPath) async {
    if (uid == null) throw Exception('User not authenticated');

    final fileName = 'pest_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref().child('users').child(uid!).child('pest_images').child(fileName);

    try {
      final uploadTask = await ref.putFile(File(localPath));
      final downloadUrl = await ref.getDownloadURL();
      print('✅ Image uploaded to Storage: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('❌ Error uploading image to storage: $e');
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
      // Get product recommendations for this pest
      final productRecommendations = getProductRecommendations(pestName);
      
      final docRef = await db.collection('users').doc(uid).collection('pestAlerts').add({
        'pestName': pestName,
        'cropName': cropName,
        'description': description,
        'treatment': treatment,
        'severity': severity,
        'detectedDate': FieldValue.serverTimestamp(),
        'resolved': false,
        'productRecommendations': productRecommendations
            .take(3) // Limit to top 3 recommendations
            .map((p) => p.toMap())
            .toList(),
      });
      print('⚠️ Pest alert created with ID: ${docRef.id}');
      
      // Send notification
      await _notificationService.notifyPestDetected(
        pestName: pestName,
        cropName: cropName,
        severity: severity,
        treatment: treatment,
      );
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
