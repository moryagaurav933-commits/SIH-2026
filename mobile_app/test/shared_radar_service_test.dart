import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:krishi_saarthi/services/shared_radar_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('CommunityRadarReport Unit Conversion & Radius Tests', () {
    test('calculateRadiusMeters handles Acres accurately', () {
      // 1 Acre = 4046.86 m^2. Radius = sqrt(4046.86 / pi) ≈ 35.89m
      final r1 = CommunityRadarReport.calculateRadiusMeters(1.0, 'Acres');
      expect(r1, closeTo(35.89, 0.5));

      final r4 = CommunityRadarReport.calculateRadiusMeters(4.5, 'एकड़ (Acres)');
      expect(r4, closeTo(76.14, 0.5));
    });

    test('calculateRadiusMeters handles Sq Feet accurately', () {
      // 1000 sq ft = 92.903 m^2. Radius = sqrt(92.903 / pi) ≈ 5.43m
      final r = CommunityRadarReport.calculateRadiusMeters(1000.0, 'Sq Feet');
      expect(r, closeTo(5.43, 0.5));

      final rHindi = CommunityRadarReport.calculateRadiusMeters(2500.0, 'वर्ग फुट (Sq Feet)');
      expect(rHindi, closeTo(8.59, 0.5));
    });

    test('calculateRadiusMeters handles Bigha accurately', () {
      // 1 Bigha (UP) = 2529.29 m^2. Radius = sqrt(2529.29 / pi) ≈ 28.37m
      final r = CommunityRadarReport.calculateRadiusMeters(2.0, 'Bigha');
      expect(r, closeTo(40.12, 0.5));

      final rHindi = CommunityRadarReport.calculateRadiusMeters(1.0, 'बीघा (Bigha)');
      expect(rHindi, closeTo(28.37, 0.5));
    });

    test('calculateRadiusMeters handles Hectare accurately', () {
      // 1 Hectare = 10000 m^2. Radius = sqrt(10000 / pi) ≈ 56.41m
      final r = CommunityRadarReport.calculateRadiusMeters(1.0, 'Hectare');
      expect(r, closeTo(56.41, 0.5));

      final rHindi = CommunityRadarReport.calculateRadiusMeters(2.0, 'हेक्टेयर (Hectare)');
      expect(rHindi, closeTo(79.78, 0.5));
    });
  });

  group('CommunityRadarReport Model Tests', () {
    test('Serializes to and from JSON correctly', () {
      final report = CommunityRadarReport(
        id: 'test-123',
        farmerName: 'सुनील कुमार',
        farmerVillage: 'माल (लखनऊ)',
        diseaseName: 'Yellow Rust',
        diseaseNameHi: 'पीला रतुआ',
        cropType: 'Wheat',
        confidence: 0.94,
        spreadArea: 2.5,
        spreadUnit: 'Acres',
        spreadRadiusM: 56.7,
        lat: 26.85,
        lon: 80.95,
        reportedAt: DateTime(2026, 10, 1),
        isMyReport: true,
        curativeAdvice: 'प्रोपीकोनाज़ोल का छिड़काव करें।',
      );

      final json = report.toJson();
      final restored = CommunityRadarReport.fromJson(json);

      expect(restored.id, report.id);
      expect(restored.farmerName, 'सुनील कुमार');
      expect(restored.confidence, 0.94);
      expect(restored.spreadArea, 2.5);
      expect(restored.spreadUnit, 'Acres');
      expect(restored.isMyReport, true);
    });
  });

  group('SharedRadarService Storage & News Bulletin Flow', () {
    test('Pre-seeds community neighbor reports when storage empty', () async {
      final service = SharedRadarService();
      final reports = await service.getReports(centerLat: 26.8467, centerLon: 80.9462);

      // Pre-seeded with realistic neighbors (Ram Kumar, Suresh, Dharam Singh, Mohd Aslam)
      expect(reports.length, greaterThanOrEqualTo(4));
      expect(reports.any((r) => r.farmerName.contains('राम कुमार')), isTrue);
      expect(reports.any((r) => r.spreadUnit.contains('Sq Feet')), isTrue);
      expect(reports.any((r) => r.spreadUnit.contains('Bigha')), isTrue);
    });

    test('Adding new outbreak report saves it and marks as isMyReport: true', () async {
      final service = SharedRadarService();
      final newReport = await service.addReport(
        farmerName: 'मेरी फ़सल (मेरा खेत)',
        farmerVillage: 'मोहनलालगंज',
        diseaseName: 'Early Blight',
        diseaseNameHi: 'अगेती झुलसा',
        cropType: 'Tomato',
        confidence: 0.92,
        spreadArea: 1500,
        spreadUnit: 'Sq Feet',
        lat: 26.8480,
        lon: 80.9470,
        curativeAdvice: 'मैनकोजेब 75% WP का छिड़काव करें।',
      );

      expect(newReport.isMyReport, isTrue);
      expect(newReport.confidence, greaterThan(0.80));
      expect(newReport.spreadUnit, 'Sq Feet');

      final allReports = await service.getReports(centerLat: 26.8467, centerLon: 80.9462);
      expect(allReports.first.id, newReport.id);
      expect(allReports.first.isMyReport, isTrue);
    });

    test('deleteReport removes single outbreak report', () async {
      final service = SharedRadarService();
      final report = await service.addReport(
        farmerName: 'किसान (You)',
        farmerVillage: 'माल',
        diseaseName: 'Powdery Mildew',
        diseaseNameHi: 'चूर्णी फफूंद',
        cropType: 'Mustard',
        confidence: 0.89,
        spreadArea: 2.0,
        spreadUnit: 'Acres',
        lat: 26.85,
        lon: 80.95,
        curativeAdvice: 'सल्फर 80% WP छिड़कें',
      );

      final myBefore = await service.getMyReports();
      expect(myBefore.any((r) => r.id == report.id), isTrue);

      await service.deleteReport(report.id);

      final myAfter = await service.getMyReports();
      expect(myAfter.any((r) => r.id == report.id), isFalse);
    });

    test('deleteMyReportsByDisease removes matching user reports and preserves neighbor reports', () async {
      final service = SharedRadarService();
      // Pre-seed neighbor reports
      await service.getReports(centerLat: 26.8467, centerLon: 80.9462);

      // Add two user reports with the same disease
      await service.addReport(
        farmerName: 'मेरी फ़सल',
        farmerVillage: 'गाँव 1',
        diseaseName: 'Yellow Rust (Puccinia striiformis)',
        diseaseNameHi: 'पीला रतुआ (Yellow Rust)',
        cropType: 'Wheat',
        confidence: 0.95,
        spreadArea: 1.5,
        spreadUnit: 'Acres',
        lat: 26.85,
        lon: 80.95,
        curativeAdvice: 'प्रोपीकोनाज़ोल',
      );

      // Add another user report with a different disease
      final tomatoReport = await service.addReport(
        farmerName: 'मेरी फ़सल 2',
        farmerVillage: 'गाँव 2',
        diseaseName: 'Early Blight',
        diseaseNameHi: 'अगेती झुलसा',
        cropType: 'Tomato',
        confidence: 0.91,
        spreadArea: 0.5,
        spreadUnit: 'Acres',
        lat: 26.86,
        lon: 80.96,
        curativeAdvice: 'मैनकोजेब',
      );

      final deletedCount = await service.deleteMyReportsByDisease('Yellow Rust');
      expect(deletedCount, greaterThanOrEqualTo(1));

      final myReports = await service.getMyReports();
      expect(myReports.any((r) => r.diseaseName.contains('Yellow Rust')), isFalse);
      expect(myReports.any((r) => r.id == tomatoReport.id), isTrue);

      // Neighbor's reports should NOT be deleted
      final allReports = await service.getReports();
      expect(allReports.any((r) => !r.isMyReport), isTrue);
    });
  });
}
