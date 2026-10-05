import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';

/// Sends leaf images to the project's local FastAPI/PyTorch crop classifiers.
class CVService {
  static const String modelPath = 'assets/models/mobilenetv4_leaf_classifier_int8.tflite';
  static const String labelsPath = 'assets/models/labels.txt';
  static const int inputSize = 224;
  static const int numClasses = 38; // PlantVillage dataset classes

  bool _isInitialized = false;

  DiagnosisResult _unavailableResult(String? cropHint, {String? reason}) => DiagnosisResult(
        diseaseName: 'Could not identify disease from this photo',
        diseaseNameHi: 'रोग की पहचान नहीं हो सकी',
        confidence: 0,
        severity: 'low',
        treatmentEn: '',
        treatmentHi: '',
        cropType: cropHint ?? 'Unknown',
        isHealthy: false,
        isLowConfidence: true,
        lowConfidenceMessageEn: reason ??
            'The local crop classifier is unavailable. Start the project backend, then try again.',
        lowConfidenceMessageHi:
            'फोटो का विश्लेषण उपलब्ध नहीं है। फसल पहचान सेवा से जुड़कर पत्ती की साफ़, नज़दीकी फोटो के साथ फिर प्रयास करें।',
        modelVersion: 'no_classifier_result',
        pathogen: 'Unknown',
        immediateAction:
            'Do not apply a pesticide based on this result. Retake the photo or reconnect to the classifier.',
        spotDosage: 0,
      );

  // Disease name mapping (English -> Hindi)
  static const Map<String, String> diseaseNamesHindi = {
    'Apple___Apple_scab': 'सेब - पपड़ी रोग',
    'Apple___Black_rot': 'सेब - काला सड़न',
    'Apple___Cedar_apple_rust': 'सेब - जंग रोग',
    'Apple___healthy': 'सेब - स्वस्थ',
    'Corn___Common_rust': 'मक्का - सामान्य जंग',
    'Corn___Gray_leaf_spot': 'मक्का - भूरा पत्ती धब्बा',
    'Corn___healthy': 'मक्का - स्वस्थ',
    'Grape___Black_rot': 'अंगूर - काला सड़न',
    'Grape___healthy': 'अंगूर - स्वस्थ',
    'Potato___Early_blight': 'आलू - अगेती अंगमारी',
    'Potato___Late_blight': 'आलू - पछेती अंगमारी',
    'Potato___healthy': 'आलू - स्वस्थ',
    'Rice___Bacterial_leaf_blight': 'चावल - जीवाणु पत्ती झुलसा',
    'Rice___Brown_spot': 'चावल - भूरा धब्बा',
    'Rice___Leaf_smut': 'चावल - पत्ती कांगियारी',
    'Rice___healthy': 'चावल - स्वस्थ',
    'Tomato___Bacterial_spot': 'टमाटर - जीवाणु धब्बा',
    'Tomato___Early_blight': 'टमाटर - अगेती अंगमारी',
    'Tomato___Late_blight': 'टमाटर - पछेती अंगमारी',
    'Tomato___Leaf_Mold': 'टमाटर - पत्ती फफूंद',
    'Tomato___healthy': 'टमाटर - स्वस्थ',
    'Wheat___Brown_rust': 'गेहूं - भूरी जंग',
    'Wheat___Yellow_rust': 'गेहूं - पीली जंग',
    'Wheat___healthy': 'गेहूं - स्वस्थ',
  };

  // Treatment recommendations
  static const Map<String, Map<String, String>> treatments = {
    'Rice___Bacterial_leaf_blight': {
      'en': 'Apply streptocycline (0.01%) + copper oxychloride (0.25%). Drain excess water. Use resistant varieties like Improved Samba Mahsuri.',
      'hi': 'स्ट्रेप्टोसाइक्लिन (0.01%) + कॉपर ऑक्सीक्लोराइड (0.25%) का छिड़काव करें। अतिरिक्त पानी निकालें। प्रतिरोधी किस्मों का उपयोग करें।',
    },
    'Tomato___Late_blight': {
      'en': 'Spray Mancozeb (0.25%) or Metalaxyl + Mancozeb. Remove infected parts. Ensure proper spacing.',
      'hi': 'मैंकोज़ेब (0.25%) या मेटालैक्सिल + मैंकोज़ेब का छिड़काव करें। संक्रमित हिस्से हटाएं। उचित दूरी रखें।',
    },
    'Wheat___Brown_rust': {
      'en': 'Spray Propiconazole (0.1%) at first symptom. Use resistant varieties. Avoid late sowing.',
      'hi': 'पहले लक्षण पर प्रोपिकोनाज़ोल (0.1%) का छिड़काव करें। प्रतिरोधी किस्मों का उपयोग करें। देर से बुवाई से बचें।',
    },
    'Potato___Late_blight': {
      'en': 'Apply Mancozeb (0.25%) preventively. Spray Cymoxanil + Mancozeb when symptoms appear. Harvest early.',
      'hi': 'मैंकोज़ेब (0.25%) का निवारक छिड़काव करें। लक्षण दिखने पर सिमोक्सानिल + मैंकोज़ेब लगाएं। जल्दी कटाई करें।',
    },
  };

  /// Initialize the CV model (load TFLite model + labels).
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;
  }

  /// Run leaf inference only through the project's local FastAPI/PyTorch models.
  Future<DiagnosisResult> diagnose([
    dynamic imageSource,
    String? cropHint,
    double? gpsLat,
    double? gpsLon,
    String? districtCode,
  ]) async {
    if (!_isInitialized) await initialize();

    String? base64Str;
    try {
      if (imageSource is Uint8List) {
        base64Str = base64Encode(imageSource);
      } else if (imageSource is File && imageSource.path.isNotEmpty) {
        if (await imageSource.exists()) {
          final bytes = await imageSource.readAsBytes();
          base64Str = base64Encode(bytes);
        }
      } else if (imageSource is String && imageSource.isNotEmpty) {
        base64Str = imageSource;
      }
    } catch (e) {
      debugPrint('Error reading leaf image bytes: $e');
    }

    if (base64Str == null || base64Str.isEmpty) {
      return _unavailableResult(cropHint);
    }

    // 1. Primary: Direct high-performance Backend PyTorch + PostgreSQL diagnosis endpoint
    try {
      final uri = Uri.parse(ApiConfig.diagnoseEndpoint);
      final request = http.MultipartRequest('POST', uri);
      if (imageSource is Uint8List) {
        request.files.add(http.MultipartFile.fromBytes('file', imageSource, filename: 'leaf.jpg'));
      } else if (imageSource is File && await imageSource.exists()) {
        request.files.add(await http.MultipartFile.fromPath('file', imageSource.path));
      } else if (base64Str.isNotEmpty) {
        final decoded = base64Decode(base64Str);
        request.files.add(http.MultipartFile.fromBytes('file', decoded, filename: 'leaf.jpg'));
      }
      if (cropHint != null && cropHint.isNotEmpty) {
        request.fields['crop_hint'] = cropHint;
      }
      if (gpsLat != null) request.fields['gps_lat'] = gpsLat.toString();
      if (gpsLon != null) request.fields['gps_lon'] = gpsLon.toString();
      if (districtCode != null) request.fields['district_code'] = districtCode;

      // The first request may take longer while the local PyTorch service warms up.
      final streamedResponse = await request.send().timeout(const Duration(seconds: 120));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final dp = (data['disease_profile'] as Map<String, dynamic>?) ?? {};
        final kb = (data['kb_info'] as Map<String, dynamic>?) ?? {};

        final diseaseValue = data['disease_name'] ?? data['predicted_class'];
        if (diseaseValue == null || diseaseValue.toString().trim().isEmpty) {
          throw StateError('The crop classifier returned no disease label.');
        }
        final diseaseEn = diseaseValue.toString();
        final diseaseHi = data['disease_name_hi']?.toString() ?? diseaseNamesHindi[diseaseEn] ?? diseaseEn;
        final rawConfidence = data['confidence'];
        final conf = rawConfidence is num ? rawConfidence.toDouble() : 0.0;
        final crop = data['crop']?.toString() ?? cropHint ?? 'Unknown';
        final isHealthy = data['is_healthy'] == true;
        final isLowConfidence = data['is_low_confidence'] == true || rawConfidence is! num;
        final isCropMismatch = data['is_crop_mismatch'] == true;
        final cropMatchConf = (data['crop_match_confidence'] as num?)?.toDouble() ?? 1.0;

        // Extract treatments
        final treatMap = (dp['treatments'] as Map<String, dynamic>?) ?? {};
        final cultList = (treatMap['cultural'] as List?)?.map((e) => e.toString()).toList() ?? <String>[];
        final chemList = (treatMap['chemical'] as List?)?.map((e) => e.toString()).toList() ?? <String>[];
        final bioList = (treatMap['biological'] as List?)?.map((e) => e.toString()).toList() ?? <String>[];

        final chemCure = chemList.isNotEmpty ? chemList.join('; ') : '';
        final orgCure = bioList.isNotEmpty ? bioList.join('; ') : cultList.join('; ');
        final action = dp['farmer_action']?.toString() ?? kb['immediate_action']?.toString() ?? 'Isolate affected plant parts.';

        final symptomsList = (dp['symptoms'] as List?)?.map((e) => e.toString()).toList() ?? <String>[];
        final healthySignsList = (dp['healthy_signs'] as List?)?.map((e) => e.toString()).toList() ?? <String>[];
        final prevList = (dp['prevention_steps'] as List?)?.map((e) => e.toString()).toList() ?? <String>[];
        final condList = (dp['favorable_conditions'] as List?)?.map((e) => e.toString()).toList() ?? <String>[];
        final sourcesList = (dp['sources'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? <Map<String, dynamic>>[];

        final sevStr = dp['severity']?.toString().toLowerCase() ?? 'medium';
        final cleanSev = sevStr.contains('critical') ? 'critical' : (sevStr.contains('high') ? 'high' : (sevStr.contains('low') ? 'low' : 'medium'));

        return DiagnosisResult(
          diseaseName: diseaseEn,
          diseaseNameHi: diseaseHi,
          confidence: conf,
          severity: cleanSev,
          treatmentEn: chemCure,
          treatmentHi: orgCure,
          cropType: crop,
          isHealthy: isHealthy,
          isLowConfidence: isLowConfidence,
          isCropMismatch: isCropMismatch,
          cropMatchConfidence: cropMatchConf,
          lowConfidenceMessageEn: data['message']?.toString() ??
              'Low confidence - please retake the photo in good light, close-up and in focus.',
          lowConfidenceMessageHi: data['message_hi']?.toString() ??
              'आत्मविश्वास कम - कृपया अच्छी रोशनी में, पत्ती के करीब से साफ़ फोटो दोबारा लें।',
          modelVersion: data['model_version']?.toString() ?? 'PyTorch MobileNetV3 + Postgres KB',
          pathogen: dp['scientific_name_or_pathogen']?.toString() ?? 'Pathogen',
          chemicalCure: chemCure,
          organicCure: orgCure,
          immediateAction: action,
          spotDosage: 1.5,
          description: dp['description']?.toString() ?? '',
          cause: dp['cause']?.toString() ?? '',
          farmerAction: dp['farmer_action']?.toString() ?? '',
          symptoms: symptomsList,
          healthySigns: healthySignsList,
          culturalTreatments: cultList,
          chemicalTreatments: chemList,
          biologicalTreatments: bioList,
          preventionSteps: prevList,
          favorableConditions: condList,
          sources: sourcesList,
        );
      }
      final detail = response.body.length > 300
          ? '${response.body.substring(0, 300)}?'
          : response.body;
      debugPrint('Local crop classifier returned HTTP ${response.statusCode}: $detail');
      return _unavailableResult(
        cropHint,
        reason: 'The local crop classifier returned HTTP ${response.statusCode}. '
            'Check that the backend is running and both model files loaded.',
      );
    } catch (e) {
      debugPrint('Local /api/diagnose request failed: $e');
      return _unavailableResult(
        cropHint,
        reason: 'Could not reach the local crop classifier at ${ApiConfig.diagnoseEndpoint}. '
            'Start the backend and retry. Details: $e',
      );
    }
  }
}

/// Result of a crop disease diagnosis with ICAR & CIBRC treatment metadata.
class DiagnosisResult {
  final String diseaseName;
  final String diseaseNameHi;
  final double confidence;
  final String severity;
  final String treatmentEn;
  final String treatmentHi;
  final String cropType;
  final bool isHealthy;

  // True when the model was not confident enough to name a disease. The UI
  // should show the retake message instead of presenting a guess as fact.
  final bool isLowConfidence;
  final String lowConfidenceMessageEn;
  final String lowConfidenceMessageHi;

  // True when the selected crop is not what the model sees in the photo. The
  // disease shown below is then meaningless even though its confidence is high,
  // so the UI must ask the farmer to re-select the crop first.
  final bool isCropMismatch;
  final double cropMatchConfidence;

  final String modelVersion;
  final String pathogen;
  final String chemicalCure;
  final String organicCure;
  final String immediateAction;
  final double spotDosage;

  // Rich database fields from PostgreSQL seed
  final String description;
  final String cause;
  final String farmerAction;
  final List<String> symptoms;
  final List<String> healthySigns;
  final List<String> culturalTreatments;
  final List<String> chemicalTreatments;
  final List<String> biologicalTreatments;
  final List<String> preventionSteps;
  final List<String> favorableConditions;
  final List<Map<String, dynamic>> sources;

  DiagnosisResult({
    required this.diseaseName,
    required this.diseaseNameHi,
    required this.confidence,
    required this.severity,
    required this.treatmentEn,
    required this.treatmentHi,
    required this.cropType,
    required this.isHealthy,
    this.isLowConfidence = false,
    this.lowConfidenceMessageEn = '',
    this.lowConfidenceMessageHi = '',
    this.isCropMismatch = false,
    this.cropMatchConfidence = 1.0,
    required this.modelVersion,
    this.pathogen = 'Pathogen',
    this.chemicalCure = '',
    this.organicCure = '',
    this.immediateAction = '',
    this.spotDosage = 1.5,
    this.description = '',
    this.cause = '',
    this.farmerAction = '',
    this.symptoms = const [],
    this.healthySigns = const [],
    this.culturalTreatments = const [],
    this.chemicalTreatments = const [],
    this.biologicalTreatments = const [],
    this.preventionSteps = const [],
    this.favorableConditions = const [],
    this.sources = const [],
  });

  Map<String, dynamic> toJson() => {
    'disease_name': diseaseName,
    'disease_name_hi': diseaseNameHi,
    'confidence': confidence,
    'severity': severity,
    'treatment_en': treatmentEn,
    'treatment_hi': treatmentHi,
    'crop_type': cropType,
    'is_healthy': isHealthy,
    'model_version': modelVersion,
    'pathogen': pathogen,
    'chemical_cure': chemicalCure,
    'organic_cure': organicCure,
    'immediate_action': immediateAction,
    'spot_dosage': spotDosage,
  };
}
