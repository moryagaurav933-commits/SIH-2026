import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Community & Neighboring Outbreak Report on the OpenStreetMap GIS Radar
class CommunityRadarReport {
  final String id;
  final String farmerName;
  final String farmerVillage;
  final String diseaseName;
  final String diseaseNameHi;
  final String cropType;
  final double confidence;
  final double spreadArea;
  final String spreadUnit; // 'Acres', 'Sq Feet', 'Bigha', 'Hectare'
  final double spreadRadiusM;
  final double lat;
  final double lon;
  final DateTime reportedAt;
  final bool isMyReport;
  final String curativeAdvice;
  final String windDirection;
  final double windSpeedKmh;

  const CommunityRadarReport({
    required this.id,
    required this.farmerName,
    required this.farmerVillage,
    required this.diseaseName,
    required this.diseaseNameHi,
    required this.cropType,
    required this.confidence,
    required this.spreadArea,
    required this.spreadUnit,
    required this.spreadRadiusM,
    required this.lat,
    required this.lon,
    required this.reportedAt,
    this.isMyReport = false,
    required this.curativeAdvice,
    this.windDirection = 'NE (42°)',
    this.windSpeedKmh = 12.0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'farmer_name': farmerName,
        'farmer_village': farmerVillage,
        'disease_name': diseaseName,
        'disease_name_hi': diseaseNameHi,
        'crop_type': cropType,
        'confidence': confidence,
        'spread_area': spreadArea,
        'spread_unit': spreadUnit,
        'spread_radius_m': spreadRadiusM,
        'lat': lat,
        'lon': lon,
        'reported_at': reportedAt.toIso8601String(),
        'is_my_report': isMyReport,
        'curative_advice': curativeAdvice,
        'wind_direction': windDirection,
        'wind_speed_kmh': windSpeedKmh,
      };

  factory CommunityRadarReport.fromJson(Map<String, dynamic> json) {
    return CommunityRadarReport(
      id: json['id']?.toString() ?? 'rep_${DateTime.now().millisecondsSinceEpoch}',
      farmerName: json['farmer_name']?.toString() ?? 'पड़ोसी किसान (Neighbor)',
      farmerVillage: json['farmer_village']?.toString() ?? 'निकटवर्ती क्षेत्र (Local Block)',
      diseaseName: json['disease_name']?.toString() ?? 'Crop Disease',
      diseaseNameHi: json['disease_name_hi']?.toString() ?? 'फसल रोग',
      cropType: json['crop_type']?.toString() ?? 'Wheat',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.85,
      spreadArea: (json['spread_area'] as num?)?.toDouble() ?? 2.0,
      spreadUnit: json['spread_unit']?.toString() ?? 'Acres',
      spreadRadiusM: (json['spread_radius_m'] as num?)?.toDouble() ?? 1200.0,
      lat: (json['lat'] as num?)?.toDouble() ?? 26.85,
      lon: (json['lon'] as num?)?.toDouble() ?? 80.95,
      reportedAt: DateTime.tryParse(json['reported_at']?.toString() ?? '') ?? DateTime.now(),
      isMyReport: json['is_my_report'] == true,
      curativeAdvice: json['curative_advice']?.toString() ?? 'जैविक नीम तेल या फफूंदनाशक का स्प्रे करें।',
      windDirection: json['wind_direction']?.toString() ?? 'NE (42°)',
      windSpeedKmh: (json['wind_speed_kmh'] as num?)?.toDouble() ?? 12.0,
    );
  }

  /// Convert given spread area & unit to circular radius in meters
  static double calculateRadiusMeters(double area, String unit) {
    double sqMeters = 0.0;
    final normalizedUnit = unit.toLowerCase();
    if (normalizedUnit.contains('acre') || normalizedUnit.contains('एकड़')) {
      sqMeters = area * 4046.86;
    } else if (normalizedUnit.contains('foot') || normalizedUnit.contains('feet') || normalizedUnit.contains('फीट')) {
      sqMeters = area * 0.092903;
    } else if (normalizedUnit.contains('bigha') || normalizedUnit.contains('बीघा')) {
      sqMeters = area * 2529.29; // Standard UP/North India Bigha
    } else if (normalizedUnit.contains('hectare') || normalizedUnit.contains('हेक्टेयर')) {
      sqMeters = area * 10000.0;
    } else {
      sqMeters = area * 4046.86;
    }
    return math.sqrt(math.max(100.0, sqMeters) / math.pi);
  }
}

/// Service managing persistent Community Shared Radar reports,
/// neighbor disease bulletins, and OpenStreetMap spatial synchronizations.
class SharedRadarService {
  static final SharedRadarService _instance = SharedRadarService._internal();
  factory SharedRadarService() => _instance;
  SharedRadarService._internal();

  static const String _prefKey = 'pmfby_shared_disease_radar_v2';
  List<CommunityRadarReport>? _cachedReports;

  /// Load all community reports (pre-seeds neighbor news + user shared reports)
  Future<List<CommunityRadarReport>> getReports({double centerLat = 26.8467, double centerLon = 80.9462}) async {
    if (_cachedReports != null && _cachedReports!.isNotEmpty) {
      return List.unmodifiable(_cachedReports!);
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final strList = prefs.getStringList(_prefKey);
      if (strList != null && strList.isNotEmpty) {
        _cachedReports = strList.map((s) => CommunityRadarReport.fromJson(jsonDecode(s))).toList();
        return List.unmodifiable(_cachedReports!);
      }
    } catch (e) {
      debugPrint('SharedRadarService load error: $e');
    }

    // Seed realistic community & neighbor reports centered around farmer's region
    _cachedReports = [
      CommunityRadarReport(
        id: 'CR-UP-001',
        farmerName: 'राम कुमार पटेल (Ram Kumar)',
        farmerVillage: 'मलिहाबाद (2.4 किमी उत्तर-पूर्व)',
        diseaseName: 'Yellow Rust (Puccinia striiformis)',
        diseaseNameHi: 'पीला रतुआ (Yellow Rust)',
        cropType: 'Wheat (गेहूं)',
        confidence: 0.942,
        spreadArea: 3.5,
        spreadUnit: 'Acres',
        spreadRadiusM: CommunityRadarReport.calculateRadiusMeters(3.5, 'Acres'),
        lat: centerLat + 0.0182,
        lon: centerLon + 0.0145,
        reportedAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 20)),
        isMyReport: false,
        curativeAdvice: 'प्रोपीकोनाज़ोल 25% EC (1 मिली/लीटर) या 5% नीम तेल बायो-इमल्शन का छिड़काव करें।',
        windDirection: 'NE (42°)',
        windSpeedKmh: 14.5,
      ),
      CommunityRadarReport(
        id: 'CR-UP-002',
        farmerName: 'सुरेश वर्मा (Suresh Verma)',
        farmerVillage: 'बख्शी का तालाब (4.1 किमी पूर्व)',
        diseaseName: 'Early Blight (Alternaria solani)',
        diseaseNameHi: 'अगेती झुलसा (Early Blight)',
        cropType: 'Tomato (टमाटर)',
        confidence: 0.918,
        spreadArea: 78400,
        spreadUnit: 'Sq Feet',
        spreadRadiusM: CommunityRadarReport.calculateRadiusMeters(78400, 'Sq Feet'),
        lat: centerLat - 0.0241,
        lon: centerLon + 0.0310,
        reportedAt: DateTime.now().subtract(const Duration(hours: 3, minutes: 45)),
        isMyReport: false,
        curativeAdvice: 'मैनकोजेब 75% WP (2.5 ग्राम/लीटर) पत्तियों के नीचे अच्छी तरह छिड़कें।',
        windDirection: 'E (88°)',
        windSpeedKmh: 9.2,
      ),
      CommunityRadarReport(
        id: 'CR-UP-003',
        farmerName: 'धरम सिंह (Dharam Singh)',
        farmerVillage: 'मोहनलालगंज (5.8 किमी उत्तर-पश्चिम)',
        diseaseName: 'White Rust (Albugo candida)',
        diseaseNameHi: 'सफेद रतुआ (White Rust)',
        cropType: 'Mustard (सरसों)',
        confidence: 0.845,
        spreadArea: 2.5,
        spreadUnit: 'Bigha',
        spreadRadiusM: CommunityRadarReport.calculateRadiusMeters(2.5, 'Bigha'),
        lat: centerLat + 0.0380,
        lon: centerLon - 0.0220,
        reportedAt: DateTime.now().subtract(const Duration(hours: 5, minutes: 10)),
        isMyReport: false,
        curativeAdvice: 'मेटालेक्सिल 8% + मैनकोजेब 64% WP का 2 ग्राम/लीटर पानी में छिड़काव करें।',
        windDirection: 'NW (310°)',
        windSpeedKmh: 11.0,
      ),
      CommunityRadarReport(
        id: 'CR-UP-004',
        farmerName: 'मो. असलम (Mohd. Aslam)',
        farmerVillage: 'काकोरी (7.4 किमी दक्षिण-पश्चिम)',
        diseaseName: 'Late Blight (Phytophthora infestans)',
        diseaseNameHi: 'पछेती झुलसा (Late Blight)',
        cropType: 'Potato (आलू)',
        confidence: 0.880,
        spreadArea: 4.0,
        spreadUnit: 'Acres',
        spreadRadiusM: CommunityRadarReport.calculateRadiusMeters(4.0, 'Acres'),
        lat: centerLat - 0.0450,
        lon: centerLon - 0.0350,
        reportedAt: DateTime.now().subtract(const Duration(hours: 8)),
        isMyReport: false,
        curativeAdvice: 'साइमोक्सानिल + मैनकोजेब का मिश्रण तुरंत स्प्रे करें और खेत में जल निकासी करें।',
        windDirection: 'SW (225°)',
        windSpeedKmh: 16.0,
      ),
    ];

    await _persist();
    return List.unmodifiable(_cachedReports!);
  }

  /// Add user's shared disease report to the community radar
  Future<CommunityRadarReport> addReport({
    required String farmerName,
    required String farmerVillage,
    required String diseaseName,
    required String diseaseNameHi,
    required String cropType,
    required double confidence,
    required double spreadArea,
    required String spreadUnit,
    required double lat,
    required double lon,
    required String curativeAdvice,
  }) async {
    final radiusM = CommunityRadarReport.calculateRadiusMeters(spreadArea, spreadUnit);
    final report = CommunityRadarReport(
      id: 'CR-USER-${DateTime.now().millisecondsSinceEpoch}',
      farmerName: farmerName,
      farmerVillage: farmerVillage,
      diseaseName: diseaseName,
      diseaseNameHi: diseaseNameHi,
      cropType: cropType,
      confidence: confidence,
      spreadArea: spreadArea,
      spreadUnit: spreadUnit,
      spreadRadiusM: radiusM,
      lat: lat,
      lon: lon,
      reportedAt: DateTime.now(),
      isMyReport: true,
      curativeAdvice: curativeAdvice,
      windDirection: 'NNE (25°)',
      windSpeedKmh: 10.5,
    );

    await getReports(centerLat: lat, centerLon: lon);
    _cachedReports!.insert(0, report);
    await _persist();
    return report;
  }

  /// Delete a shared report by ID
  Future<void> deleteReport(String id) async {
    if (_cachedReports == null) await getReports();
    _cachedReports!.removeWhere((r) => r.id == id);
    await _persist();
  }

  /// Delete user's shared reports matching disease name (used when removing disease from Field Palette)
  Future<int> deleteMyReportsByDisease(String diseaseName) async {
    if (_cachedReports == null) await getReports();
    final dLower = diseaseName.trim().toLowerCase();
    final initialCount = _cachedReports!.length;
    _cachedReports!.removeWhere((r) =>
        r.isMyReport &&
        (r.diseaseName.toLowerCase().contains(dLower) ||
         r.diseaseNameHi.toLowerCase().contains(dLower) ||
         dLower.contains(r.diseaseName.toLowerCase()) ||
         dLower.contains(r.diseaseNameHi.toLowerCase())));
    final removed = initialCount - _cachedReports!.length;
    if (removed > 0) {
      await _persist();
    }
    return removed;
  }

  /// Get only user's own shared reports
  Future<List<CommunityRadarReport>> getMyReports() async {
    final all = await getReports();
    return all.where((r) => r.isMyReport).toList();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_cachedReports != null) {
        final list = _cachedReports!.map((r) => jsonEncode(r.toJson())).toList();
        await prefs.setStringList(_prefKey, list);
      }
    } catch (e) {
      debugPrint('SharedRadarService persist error: $e');
    }
  }
}
