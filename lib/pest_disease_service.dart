import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'ai_service.dart';
import 'notification_service.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'localization_service.dart';

/// Purpose: Data model representing a single agrochemical product recommendation.
/// Each field maps directly to a key in the in-memory product database or a Firestore document.
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

  /// Purpose: Factory constructor that safely deserializes a raw Map into a typed ProductRecommendation.
  /// Inputs: [map] - A Map<String, dynamic> from the product database or Firestore.
  /// Outputs: Returns a fully instantiated ProductRecommendation with null-safe defaults.
  factory ProductRecommendation.fromMap(Map<String, dynamic> map) {
    return ProductRecommendation(
      id: map['id'] ?? '', // 1. Default to empty string if ID is missing.
      productName: map['productName'] ?? '',
      category: map['category'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0, // 2. Safe numeric cast from Firestore's dynamic typing.
      dosage: map['dosage'] ?? '',
      treatsDisease: List<String>.from(map['treatsDisease'] ?? []), // 3. Deep-copy the list to prevent shared-reference mutations.
      availability: map['availability'] ?? 'Available',
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      reviews: map['reviews'] ?? 0,
      manufacturer: map['manufacturer'] ?? '',
      chemicalComposition: map['chemicalComposition'] ?? '',
      safetyWarnings: map['safetyWarnings'] ?? '',
    );
  }

  /// Purpose: Serializes this model back into a Map for Firestore writes or embedding inside alert documents.
  /// Inputs: None.
  /// Outputs: Returns a Map<String, dynamic> matching the Firestore schema.
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

  /// Purpose: Deserializes a Firestore document snapshot into a strongly-typed PestAlertData object.
  /// Inputs: [doc] - The raw DocumentSnapshot.
  /// Outputs: Returns an instantiated PestAlertData model.
  factory PestAlertData.fromFirestore(DocumentSnapshot doc) {
    // 1. Extract the raw map payload.
    final data = doc.data() as Map<String, dynamic>;
    List<ProductRecommendation> products = [];
    
    // 2. Iterate and recursively deserialize any nested product recommendation objects.
    if (data['productRecommendations'] != null) {
      products = (data['productRecommendations'] as List)
          .map((p) => ProductRecommendation.fromMap(p as Map<String, dynamic>))
          .toList();
    }
    
    // 3. Construct the model with safe default fallbacks for missing fields.
    return PestAlertData(
      id: doc.id,
      pestName: data['pestName'] ?? 'Unknown',
      cropName: data['cropName'] ?? 'Unknown',
      description: data['description'] ?? '',
      treatment: data['treatment'] ?? '',
      severity: data['severity'] ?? 'Medium',
      // 4. Safely cast the Firestore Timestamp to a Dart DateTime object.
      detectedDate: (data['detectedDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      resolved: data['resolved'] ?? false,
      productRecommendations: products,
    );
  }

  /// Purpose: Serializes this PestAlertData model into a Map for writing to Firestore.
  /// Inputs: None.
  /// Outputs: Returns a Map<String, dynamic> with DateTime converted to Firestore Timestamp.
  Map<String, dynamic> toMap() => {
    'pestName': pestName,
    'cropName': cropName,
    'description': description,
    'treatment': treatment,
    'severity': severity,
    'detectedDate': Timestamp.fromDate(detectedDate), // 1. Convert Dart DateTime back to Firestore-native Timestamp.
    'resolved': resolved,
    'productRecommendations': productRecommendations.map((p) => p.toMap()).toList(), // 2. Recursively serialize nested models.
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

  /// Purpose: Deserializes a Firestore document representing a historical AI scan into a Dart model.
  /// Inputs: [doc] - The raw DocumentSnapshot.
  /// Outputs: Returns an instantiated PestScanData model.
  factory PestScanData.fromFirestore(DocumentSnapshot doc) {
    // 1. Extract the raw map payload.
    final data = doc.data() as Map<String, dynamic>;
    
    // 2. Construct the model with safe fallbacks.
    return PestScanData(
      id: doc.id,
      cropName: data['cropName'] ?? 'Unknown',
      // 3. Cast the Firestore Timestamp to DateTime.
      scanDate: (data['scanDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] ?? 'Pending',
      // 4. Safely cast the numeric confidence score.
      confidence: (data['confidence'] as num?)?.toDouble() ?? 0.0,
      aiResponse: data['aiResponse'] ?? '',
    );
  }

  /// Purpose: Serializes this PestScanData model into a Map for Firestore writes.
  /// Inputs: None.
  /// Outputs: Returns a Map with the scanDate converted to a Firestore Timestamp.
  Map<String, dynamic> toMap() => {
    'cropName': cropName,
    'scanDate': Timestamp.fromDate(scanDate), // 1. Convert DateTime to Firestore Timestamp for server-side querying.
    'status': status,
    'confidence': confidence,
    'aiResponse': aiResponse,
  };
}

/// Purpose: Singleton service class that handles the entire pest & disease lifecycle:
/// AI image analysis, Firestore CRUD for alerts/scans, product recommendations, and push notifications.
/// Architecture: Uses the Singleton pattern to ensure a single shared instance across the app.
class PestDiseaseService {
  // 1. The single static instance — created once and reused for every call to PestDiseaseService().
  static final PestDiseaseService _instance = PestDiseaseService._internal();
  
  // 2. Inject the NotificationService for sending device-level push alerts when pests are detected.
  final NotificationService _notificationService = NotificationService();

  /// Purpose: Factory constructor that always returns the same singleton instance.
  /// Inputs: None.
  /// Outputs: Returns [_instance].
  factory PestDiseaseService() {
    return _instance;
  }

  // 3. Private named constructor — prevents external instantiation, enforcing the singleton.
  PestDiseaseService._internal();

  // 4. Capture the currently authenticated user's UID for scoping all Firestore queries.
  final String? uid = FirebaseAuth.instance.currentUser?.uid;
  
  // 5. Firestore database reference — the central document store for all pest data.
  final db = FirebaseFirestore.instance;
  
  // 6. Firebase Cloud Storage reference — used for uploading crop scan images.
  final firebase_storage.FirebaseStorage _storage = firebase_storage.FirebaseStorage.instance;

  // --- Rate Limiting & Storage Protection Constants ---
  // These constants act as server-side guardrails to prevent abuse and control cloud costs.
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
          print(' Error fetching alerts: $error');
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
          print(' Error fetching scans: $error');
          return [];
        });
  }

  /// Purpose: Orchestrates the AI pipeline to analyze a crop image for diseases and triggers subsequent database alerts.
  /// Inputs: [imagePath] - Local file path. Optional [imageUrl] - Remote storage URL.
  /// Outputs: Returns a parsed map of the AI's analysis results and potentially creates a Firestore alert.
  Future<Map<String, dynamic>> analyzeImageWithAI(String imagePath, {String? imageUrl}) async {
    // 1. Enforce security: Ensure a user is actively authenticated before invoking costly AI endpoints.
    if (uid == null) throw Exception('User not authenticated');

    try {
      print(' [SERVICE] analyzeImageWithAI START');
      print(' [SERVICE] Image path: $imagePath');
      
      print(' [SERVICE] Calling AiService.analyzeImage...');
      // 2. Transmit the local image to the Gemini AI via the dedicated AI Service wrapper.
      final textResponse = await AiService().analyzeImage(imagePath);
      print(' [SERVICE] AiService response received');
      
      // 3. Validate that the AI successfully returned a payload.
      if (textResponse == null || textResponse.isEmpty) {
        throw Exception('AI service failed to analyze the image or returned an empty response.');
      }

      print(' [SERVICE] Parsing response...');
      Map<String, dynamic> analysisData;
      try {
        // 4. Sanitize the AI's raw text response, removing Markdown formatting ticks (```json ... ```).
        String cleanJson = textResponse.replaceAll('```json', '').replaceAll('```', '').trim();
        // 5. Attempt a direct standard JSON parse of the cleaned string.
        try {
          analysisData = jsonDecode(cleanJson);
        } catch (e) {
          // 6. Fallback: Use Regex to extract the first valid JSON object `{...}` if the AI included conversational padding.
          final jsonMatch = RegExp(r'\{[^{}]*\}', dotAll: true).firstMatch(cleanJson);
          if (jsonMatch != null) {
            analysisData = jsonDecode(jsonMatch.group(0)!);
          } else {
            throw Exception('Could not extract JSON from AI response.');
          }
        }
      } catch (e) {
        throw Exception('Failed to parse AI response: $e');
      }

      // 7. Agronomic Guardrail: Reject the analysis if the AI determines the image does not contain a plant.
      if (analysisData['status'] == 'Not a Plant') {
        print(' [SERVICE] Wrong object detected - not a plant');
        analysisData['description'] = 'This image does not contain a plant or crop. Please scan a plant or crop image.';
        analysisData['confidence'] = 0.0;
      }

      print(' [SERVICE] Saving scan to Firestore...');
      // 8. Log the raw scan result (healthy or diseased) to the user's history in Firestore.
      await _savePestScan(
        cropName: analysisData['cropName'] ?? 'Unknown',
        status: analysisData['status'] ?? 'Pending',
        confidence: (analysisData['confidence'] as num?)?.toDouble() ?? 0.0,
        aiResponse: textResponse,
        imageUrl: imageUrl,
      );
      print(' [SERVICE] Scan saved');

      // 9. If the plant is diseased, escalate the finding by generating a permanent Actionable Alert.
      if (analysisData['status'] != 'Healthy' && analysisData['status'] != 'Not a Plant' && analysisData['pestName'] != null) {
        print(' [SERVICE] Creating alert...');
        await _createPestAlert(
          pestName: analysisData['pestName'] as String,
          cropName: analysisData['cropName'] as String,
          description: analysisData['description'] as String? ?? '',
          treatment: analysisData['treatment'] as String? ?? '',
          severity: analysisData['severity'] as String? ?? 'Medium',
        );
        print(' [SERVICE] Alert created');
      }

      print(' [SERVICE] analyzeImageWithAI DONE');
      return analysisData;
    } catch (e) {
      print(' [SERVICE] analyzeImageWithAI ERROR: $e');
      rethrow;
    }
  }

  /// Purpose: Persists the results of an AI scan to the user's Firestore history.
  /// Inputs: [cropName], [status], [confidence], [aiResponse], and optional [imageUrl].
  /// Outputs: Writes a document to the 'pestScans' subcollection.
  Future<void> _savePestScan({
    required String cropName,
    required String status,
    required double confidence,
    required String aiResponse,
    String? imageUrl,
  }) async {
    // 1. Guard against unauthenticated writes.
    if (uid == null) return;

    try {
      // 2. Add a new document with server-side timestamping for accurate temporal querying.
      final docRef = await db.collection('users').doc(uid).collection('pestScans').add({
        'cropName': cropName,
        'scanDate': FieldValue.serverTimestamp(),
        'status': status,
        'confidence': confidence,
        'aiResponse': aiResponse,
        // 3. Conditionally include the image URL if the upload succeeded.
        if (imageUrl != null) 'imageUrl': imageUrl,
      });
      print(' Pest scan saved with ID: ${docRef.id}');
    } catch (e) {
      print(' Error saving scan: $e');
      rethrow; // 4. Bubble up the error to trigger UI error states.
    }
  }

  /// Purpose: Uploads a local image file to Firebase Cloud Storage and retrieves its public URL.
  /// Inputs: [localPath] - The absolute path to the local image file.
  /// Outputs: Returns the public download URL as a String.
  Future<String> uploadImageToStorage(String localPath) async {
    // 1. Verify user authentication.
    if (uid == null) throw Exception('User not authenticated');

    // 2. Generate a unique filename using the current Unix epoch to prevent collisions.
    final fileName = 'pest_${DateTime.now().millisecondsSinceEpoch}.jpg';
    
    // 3. Construct the secure storage reference bound to the user's UID.
    final ref = _storage.ref().child('users').child(uid!).child('pest_images').child(fileName);

    try {
      // 4. Execute the binary upload.
      final uploadTask = await ref.putFile(File(localPath));
      
      // 5. Retrieve the resolvable web URL for the uploaded asset.
      final downloadUrl = await ref.getDownloadURL();
      print(' Image uploaded to Storage: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print(' Error uploading image to storage: $e');
      rethrow;
    }
  }

  /// Purpose: Generates an actionable pest alert in Firestore and triggers a push notification.
  /// Inputs: Agronomic details ([pestName], [cropName], [description], [treatment], [severity]).
  /// Outputs: Writes to 'pestAlerts' subcollection and invokes NotificationService.
  Future<void> _createPestAlert({
    required String pestName,
    required String cropName,
    required String description,
    required String treatment,
    required String severity,
  }) async {
    if (uid == null) return;

    try {
      // 1. Query the internal product database for recommended agrochemicals based on the pest.
      final productRecommendations = getProductRecommendations(pestName);
      
      // 2. Persist the alert to the database with an unresolved state flag.
      final docRef = await db.collection('users').doc(uid).collection('pestAlerts').add({
        'pestName': pestName,
        'cropName': cropName,
        'description': description,
        'treatment': treatment,
        'severity': severity,
        'detectedDate': FieldValue.serverTimestamp(),
        'resolved': false,
        // 3. Embed the top 3 product recommendations directly into the alert document for fast UI rendering.
        'productRecommendations': productRecommendations
            .take(3) 
            .map((p) => p.toMap())
            .toList(),
      });
      print(' Pest alert created with ID: ${docRef.id}');
      
      // 4. Delegate to the NotificationService to push a device-level alert.
      await _notificationService.notifyPestDetected(
        pestName: pestName,
        cropName: cropName,
        severity: severity,
        treatment: treatment,
      );
    } catch (e) {
      print(' Error creating alert: $e');
      rethrow;
    }
  }

  /// Purpose: Updates an active pest alert, marking it as resolved so it disappears from the active dashboard.
  /// Inputs: [alertId] - The Firestore document ID.
  /// Outputs: Mutates the 'resolved' boolean field in Firestore.
  Future<void> resolveAlert(String alertId) async {
    // 1. Enforce authentication guardrail.
    if (uid == null) return;

    try {
      // 2. Perform a partial document update to flip the status flag.
      await db.collection('users').doc(uid).collection('pestAlerts').doc(alertId).update({
        'resolved': true,
      });
      print(' Alert resolved');
    } catch (e) {
      print(' Error resolving alert: $e');
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
      print(' Audit log failed: $e');
    }
  }
}
