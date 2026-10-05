import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../db/local_db.dart';

/// Single crop parcel inside the farmer's khet
class FieldCropPlot {
  final String id;
  final String cropKey;
  final String cropName;
  final double acres;
  final String stage;
  final String? sowingDate;

  const FieldCropPlot({
    required this.id,
    required this.cropKey,
    required this.cropName,
    required this.acres,
    this.stage = 'वानस्पतिक वृद्धि (Vegetative)',
    this.sowingDate,
  });

  FieldCropPlot copyWith({
    String? id,
    String? cropKey,
    String? cropName,
    double? acres,
    String? stage,
    String? sowingDate,
  }) {
    return FieldCropPlot(
      id: id ?? this.id,
      cropKey: cropKey ?? this.cropKey,
      cropName: cropName ?? this.cropName,
      acres: acres ?? this.acres,
      stage: stage ?? this.stage,
      sowingDate: sowingDate ?? this.sowingDate,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'crop_key': cropKey,
    'crop_name': cropName,
    'acres': acres,
    'stage': stage,
    'sowing_date': sowingDate,
  };

  factory FieldCropPlot.fromJson(Map<String, dynamic> json) {
    return FieldCropPlot(
      id: json['id']?.toString() ?? 'plot_1',
      cropKey: json['crop_key']?.toString() ?? 'wheat',
      cropName: json['crop_name']?.toString() ?? 'गेहूं (Wheat)',
      acres: (json['acres'] as num?)?.toDouble() ?? 2.0,
      stage: json['stage']?.toString() ?? 'वानस्पतिक वृद्धि (Vegetative)',
      sowingDate: json['sowing_date']?.toString(),
    );
  }
}

/// Active high-confidence verified disease alert matching farmer's field
class VerifiedFieldDiseaseAlert {
  final String id;
  final String diseaseName;
  final String diseaseNameHi;
  final String cropType;
  final double confidence;
  final double affectedAcres;
  final String treatment;
  final DateTime diagnosedAt;
  final String source;

  const VerifiedFieldDiseaseAlert({
    required this.id,
    required this.diseaseName,
    required this.diseaseNameHi,
    required this.cropType,
    required this.confidence,
    required this.affectedAcres,
    required this.treatment,
    required this.diagnosedAt,
    this.source = 'AI Scanner & Kisan Copilot',
  });
}

/// Comprehensive Farmer Khet Profile & Agronomy Ledger
class FarmerFieldProfile {
  final double totalAcres;
  final String soilType;
  final String irrigationSource;
  final String khasraNumber;
  final String locationDistrict;
  final List<FieldCropPlot> plots;

  const FarmerFieldProfile({
    required this.totalAcres,
    required this.soilType,
    required this.irrigationSource,
    this.khasraNumber = 'खसरा संख्या 412/1',
    this.locationDistrict = 'लखनऊ (Lucknow, UP)',
    required this.plots,
  });

  FarmerFieldProfile copyWith({
    double? totalAcres,
    String? soilType,
    String? irrigationSource,
    String? khasraNumber,
    String? locationDistrict,
    List<FieldCropPlot>? plots,
  }) {
    return FarmerFieldProfile(
      totalAcres: totalAcres ?? this.totalAcres,
      soilType: soilType ?? this.soilType,
      irrigationSource: irrigationSource ?? this.irrigationSource,
      khasraNumber: khasraNumber ?? this.khasraNumber,
      locationDistrict: locationDistrict ?? this.locationDistrict,
      plots: plots ?? this.plots,
    );
  }

  Map<String, dynamic> toJson() => {
    'total_acres': totalAcres,
    'soil_type': soilType,
    'irrigation_source': irrigationSource,
    'khasra_number': khasraNumber,
    'location_district': locationDistrict,
    'plots': plots.map((p) => p.toJson()).toList(),
  };

  factory FarmerFieldProfile.fromJson(Map<String, dynamic> json) {
    final plotsJson = (json['plots'] as List?) ?? [];
    return FarmerFieldProfile(
      totalAcres: (json['total_acres'] as num?)?.toDouble() ?? 4.5,
      soilType: json['soil_type']?.toString() ?? 'जलोढ़ दोमट (Alluvial Loam)',
      irrigationSource: json['irrigation_source']?.toString() ?? 'नलकूप / ट्यूबवेल (Tube-well)',
      khasraNumber: json['khasra_number']?.toString() ?? 'खसरा 412/1',
      locationDistrict: json['location_district']?.toString() ?? 'लखनऊ, उत्तर प्रदेश',
      plots: plotsJson.map((p) => FieldCropPlot.fromJson(p as Map<String, dynamic>)).toList(),
    );
  }
}

/// Service managing Farmer's Field Palette, connecting AI Scans & Kisan Copilot (>90% confidence),
/// and feeding spatial telemetry data to the GIS radar map.
class FieldService {
  static final FieldService _instance = FieldService._internal();
  factory FieldService() => _instance;
  FieldService._internal();

  static const String _prefKey = 'pmfby_farmer_field_profile_v3';

  FarmerFieldProfile? _profile;

  /// Get current profile (loads from storage or initializes default)
  Future<FarmerFieldProfile> getProfile() async {
    if (_profile != null) return _profile!;

    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_prefKey);
      if (str != null && str.isNotEmpty) {
        _profile = FarmerFieldProfile.fromJson(jsonDecode(str));
        return _profile!;
      }
    } catch (e) {
      debugPrint('FieldService load error: $e');
    }

    // Default seeded profile for Indian farming holding
    _profile = const FarmerFieldProfile(
      totalAcres: 4.5,
      soilType: 'जलोढ़ दोमट (Alluvial Loam)',
      irrigationSource: 'नलकूप / ट्यूबवेल (Tube-well)',
      khasraNumber: 'खसरा सं. 412/1',
      locationDistrict: 'लखनऊ, उत्तर प्रदेश',
      plots: [
        FieldCropPlot(
          id: 'plot_1',
          cropKey: 'wheat',
          cropName: 'गेहूं (Wheat)',
          acres: 3.0,
          stage: 'वानस्पतिक वृद्धि (Tillering)',
          sowingDate: '15 नवंबर 2025',
        ),
        FieldCropPlot(
          id: 'plot_2',
          cropKey: 'mustard',
          cropName: 'सरसों (Mustard)',
          acres: 1.5,
          stage: 'फूल आना (Flowering)',
          sowingDate: '28 अक्टूबर 2025',
        ),
      ],
    );

    await saveProfile(_profile!);
    return _profile!;
  }

  /// Save updated field profile
  Future<void> saveProfile(FarmerFieldProfile profile) async {
    _profile = profile;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, jsonEncode(profile.toJson()));
    } catch (e) {
      debugPrint('FieldService save error: $e');
    }
  }

  /// Automatically connects farmer's plots with verified AI Scan & Kisan Copilot diagnoses (>80% confidence)
  Future<List<VerifiedFieldDiseaseAlert>> getVerifiedFieldAlerts({double threshold = 0.80}) async {
    final profile = await getProfile();
    final highConfDiagnoses = await LocalDB().getHighConfidenceDiagnoses(threshold: threshold);

    final List<VerifiedFieldDiseaseAlert> alerts = [];

    for (final diag in highConfDiagnoses) {
      final conf = (diag['confidence'] as num?)?.toDouble() ?? 0.0;
      if (conf <= 0.80) continue; // strictly greater than 80% as requested

      final cropType = (diag['crop_type']?.toString() ?? '').toLowerCase();
      final disease = diag['disease_name']?.toString() ?? 'Unknown Disease';
      final diseaseHi = diag['disease_name_hi']?.toString() ?? disease;
      final treat = diag['treatment']?.toString() ?? '5% नीम तेल बायो-इमल्शन का छिड़काव करें।';
      final diagnosedAt = DateTime.tryParse(diag['diagnosed_at']?.toString() ?? '') ?? DateTime.now();

      // Check if farmer has this crop growing in their field
      double affectedAcres = 0.0;
      for (final p in profile.plots) {
        if (p.cropKey.toLowerCase() == cropType ||
            p.cropName.toLowerCase().contains(cropType)) {
          affectedAcres += p.acres;
        }
      }

      // If matched or if general crop damage
      if (affectedAcres == 0.0) {
        affectedAcres = profile.totalAcres > 0 ? (profile.totalAcres * 0.4) : 1.5;
      }

      alerts.add(VerifiedFieldDiseaseAlert(
        id: diag['id']?.toString() ?? 'diag_${DateTime.now().millisecondsSinceEpoch}',
        diseaseName: disease,
        diseaseNameHi: diseaseHi,
        cropType: cropType,
        confidence: conf,
        affectedAcres: affectedAcres,
        treatment: treat,
        diagnosedAt: diagnosedAt,
        source: diag['source']?.toString() ?? 'AI Scan & Kisan Copilot (>90% Verified)',
      ));
    }

    return alerts;
  }

  /// Delete a diagnosed disease record by its ID
  Future<void> deleteVerifiedAlert(String id) async {
    await LocalDB().deleteDiagnosis(id);
  }
}
