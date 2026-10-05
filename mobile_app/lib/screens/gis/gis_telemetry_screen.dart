import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../../localization/app_language.dart';
import '../../localization/app_translations.dart';
import '../../services/api_config.dart';
import '../../services/field_service.dart';
import '../../services/shared_radar_service.dart';

/// Disease Outbreak Item on GIS Telemetry Radar
class GisOutbreakCluster {
  final String id;
  final String diseaseName;
  final String diseaseNameHi;
  final String cropType;
  final double lat;
  final double lon;
  final double distanceKm;
  final String riskLevel;
  final double spreadArea;
  final String spreadUnit;
  final double spreadRadiusM;
  final double confidence;
  final int affectedFarms;
  final String windDirection;
  final String curativeAction;
  final String curativeActionEn;
  final bool isCommunityReport;
  final bool isMyReport;
  final String farmerName;
  final String farmerVillage;

  const GisOutbreakCluster({
    required this.id,
    required this.diseaseName,
    required this.diseaseNameHi,
    required this.cropType,
    required this.lat,
    required this.lon,
    required this.distanceKm,
    required this.riskLevel,
    this.spreadArea = 2.0,
    this.spreadUnit = 'Acres',
    required this.spreadRadiusM,
    required this.confidence,
    required this.affectedFarms,
    required this.windDirection,
    required this.curativeAction,
    required this.curativeActionEn,
    this.isCommunityReport = false,
    this.isMyReport = false,
    this.farmerName = 'निकटवर्ती किसान',
    this.farmerVillage = 'स्थानीय क्षेत्र',
  });

  factory GisOutbreakCluster.fromCommunityReport(CommunityRadarReport rep, double userLat, double userLon) {
    final dLat = (rep.lat - userLat) * 110.574;
    final dLon = (rep.lon - userLon) * 111.320 * math.cos(userLat * math.pi / 180);
    final dist = math.sqrt(dLat * dLat + dLon * dLon);

    String risk = 'MODERATE';
    if (rep.confidence >= 0.92) {
      risk = 'CRITICAL';
    } else if (rep.confidence >= 0.85) {
      risk = 'HIGH';
    }

    return GisOutbreakCluster(
      id: rep.id,
      diseaseName: rep.diseaseName,
      diseaseNameHi: rep.diseaseNameHi,
      cropType: rep.cropType,
      lat: rep.lat,
      lon: rep.lon,
      distanceKm: double.parse(dist.toStringAsFixed(1)),
      riskLevel: risk,
      spreadArea: rep.spreadArea,
      spreadUnit: rep.spreadUnit,
      spreadRadiusM: rep.spreadRadiusM,
      confidence: rep.confidence,
      affectedFarms: rep.isMyReport ? 1 : 4,
      windDirection: rep.windDirection,
      curativeAction: rep.curativeAdvice,
      curativeActionEn: rep.curativeAdvice,
      isCommunityReport: true,
      isMyReport: rep.isMyReport,
      farmerName: rep.isMyReport ? 'आपका खेत (You)' : rep.farmerName,
      farmerVillage: rep.farmerVillage,
    );
  }

  factory GisOutbreakCluster.fromJson(Map<String, dynamic> json) {
    final wind = json['wind_vector'] as Map<String, dynamic>?;
    final radiusM = (json['spread_radius_m'] as num?)?.toDouble() ?? 1500.0;
    final calcAcres = (math.pi * radiusM * radiusM) / 4046.86;

    return GisOutbreakCluster(
      id: json['id']?.toString() ?? 'OUTBREAK_1',
      diseaseName: json['disease_name']?.toString() ?? 'Crop Pathogen',
      diseaseNameHi: json['disease_name_hi']?.toString() ?? 'फसल रोग',
      cropType: json['crop_type']?.toString() ?? 'Wheat',
      lat: (json['lat'] as num?)?.toDouble() ?? 26.8649,
      lon: (json['lon'] as num?)?.toDouble() ?? 80.9607,
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 3.0,
      riskLevel: json['risk_level']?.toString() ?? 'HIGH',
      spreadArea: (json['spread_area'] as num?)?.toDouble() ?? double.parse(calcAcres.toStringAsFixed(1)),
      spreadUnit: json['spread_unit']?.toString() ?? 'Acres',
      spreadRadiusM: radiusM,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.94,
      affectedFarms: (json['affected_farms_count'] as num?)?.toInt() ?? 12,
      windDirection: wind?['direction']?.toString() ?? 'NE (42°)',
      curativeAction: json['curative_action']?.toString() ?? 'नीम तेल बायो-इमल्शन स्प्रे करें।',
      curativeActionEn: json['curative_action_en']?.toString() ?? 'Spray Bio-Emulsion.',
    );
  }
}

/// Comprehensive Geospatial Telemetry Screen powered by High-Resolution World Cartography,
/// Auto Farmer Geolocation Centering, Trackpad Zoom, Top Floating Crop & Critical Near Me Filters,
/// and Precise Acreage Scaled Radar Overlays.
class GisTelemetryScreen extends StatefulWidget {
  final String? initialDisease;
  final double? diseaseConfidence;

  const GisTelemetryScreen({
    super.key,
    this.initialDisease,
    this.diseaseConfidence,
  });

  @override
  State<GisTelemetryScreen> createState() => _GisTelemetryScreenState();
}

class _GisTelemetryScreenState extends State<GisTelemetryScreen>
    with SingleTickerProviderStateMixin {
  // Tactile Pragmatism Tokens
  static const Color colorPrimary = Color(0xFF2E7D32);
  static const Color colorAlert = Color(0xFFD32F2F);
  static const Color colorWarning = Color(0xFFF57C00);

  final FieldService _fieldService = FieldService();
  final SharedRadarService _sharedRadarService = SharedRadarService();

  // Map & Telemetry Coordinates
  double _userLat = 26.8467;
  double _userLon = 80.9462;
  String _userLocationLabel = 'लखनऊ (Lucknow, UP)';
  double _userAcres = 4.5;
  double _khetRadiusMeters = 76.0;

  // Active High Confidence Disease (>80%)
  bool _isUserFieldInfected = false;
  String? _activeDiseaseName;
  double? _activeDiseaseConfidence;
  String? _activeDiseaseTreatment;
  bool _isLocating = true;

  // Map Controls: Standard, Relief/Terrain, Contour, Satellite
  String _mapType = 'osm'; // 'osm', 'osm_hot', 'opentopo', 'satellite'
  double _zoomLevel = 13.5; // 3.0 (Whole World) to 18.0 (Farm Plot)
  Offset _mapOffset = Offset.zero;
  bool _showRadarSweep = true;
  String _activeFilter = 'all';

  // Trackpad / Gesture Zoom State
  double _startZoom = 13.5;
  Offset _lastFocalPoint = Offset.zero;

  late AnimationController _radarController;
  List<GisOutbreakCluster> _outbreaks = [];
  GisOutbreakCluster? _selectedOutbreak;

  // Regional News Bulletin expanded state
  bool _showNewsBulletin = true;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _initTelemetryData();
  }

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }

  Future<void> _initTelemetryData() async {
    // 1. Automatically detect farmer's exact real GPS location
    try {
      final hasPerm = await Geolocator.checkPermission();
      if (hasPerm == LocationPermission.always ||
          hasPerm == LocationPermission.whileInUse) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            timeLimit: Duration(seconds: 5),
            accuracy: LocationAccuracy.high,
          ),
        );
        _userLat = pos.latitude;
        _userLon = pos.longitude;
        _userLocationLabel = '${_userLat.toStringAsFixed(4)}°N, ${_userLon.toStringAsFixed(4)}°E';
        _mapOffset = Offset.zero; // Automatically center on farmer's GPS!
      }
    } catch (e) {
      debugPrint('Location detection fallback: $e');
    }

    // 2. Fetch Farmer's Field Profile (Acreage from Field Palette)
    final profile = await _fieldService.getProfile();
    _userAcres = profile.totalAcres > 0 ? profile.totalAcres : 4.5;
    _khetRadiusMeters = math.sqrt(_userAcres * 4046.86 / math.pi);

    // 3. Check for high-confidence verified disease (>80%)
    if (widget.initialDisease != null) {
      _isUserFieldInfected = true;
      _activeDiseaseName = widget.initialDisease;
      _activeDiseaseConfidence = widget.diseaseConfidence ?? 0.94;
    } else {
      final alerts = await _fieldService.getVerifiedFieldAlerts(threshold: 0.80);
      if (alerts.isNotEmpty) {
        _isUserFieldInfected = true;
        _activeDiseaseName = alerts.first.diseaseName;
        _activeDiseaseConfidence = alerts.first.confidence;
        _activeDiseaseTreatment = alerts.first.treatment;
      }
    }

    // 4. Fetch Community & Neighbor Shared Outbreaks and News
    await _loadCommunityAndBackendData();

    if (mounted) {
      setState(() {
        _isLocating = false;
      });
    }
  }

  Future<void> _loadCommunityAndBackendData() async {
    try {
      // Load community shared radar reports (both neighbor and user's own reports)
      final reports = await _sharedRadarService.getReports(centerLat: _userLat, centerLon: _userLon);
      final communityClusters = reports.map((r) => GisOutbreakCluster.fromCommunityReport(r, _userLat, _userLon)).toList();

      // Also query backend GIS Kriging telemetry
      await _fetchBackendGisData();

      // Merge community clusters with backend clusters (avoid duplicates by ID)
      final existingIds = _outbreaks.map((o) => o.id).toSet();
      for (final c in communityClusters) {
        if (!existingIds.contains(c.id)) {
          _outbreaks.insert(0, c);
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchBackendGisData() async {
    try {
      final uri = Uri.parse(
        'http://127.0.0.1:8000/api/v1/kriging/gis-telemetry'
        '?lat=$_userLat&lon=$_userLon&acres=$_userAcres'
        '${_activeDiseaseName != null ? "&active_disease=${Uri.encodeComponent(_activeDiseaseName!)}" : ""}'
        '${_activeDiseaseConfidence != null ? "&disease_confidence=$_activeDiseaseConfidence" : ""}',
      );

      final resp = await http.get(uri).timeout(const Duration(seconds: 4));
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as Map<String, dynamic>;
        final list = data['nearby_outbreaks'] as List<dynamic>? ?? [];
        final parsed = list.map((item) => GisOutbreakCluster.fromJson(item as Map<String, dynamic>)).toList();

        if (parsed.isNotEmpty) {
          _outbreaks = parsed;
        }
      }
    } catch (e) {
      debugPrint('Backend GIS telemetry fallback: $e');
      if (_outbreaks.isEmpty) {
        _outbreaks = _buildStaticOutbreakSeed();
      }
    }
  }

  List<GisOutbreakCluster> _buildStaticOutbreakSeed() {
    return [
      const GisOutbreakCluster(
        id: 'DIS-001',
        diseaseName: 'Yellow Rust (Puccinia striiformis)',
        diseaseNameHi: 'पीला रतुआ (गेहूं)',
        cropType: 'Wheat (गेहूं)',
        lat: 26.8649,
        lon: 80.9607,
        distanceKm: 2.6,
        riskLevel: 'CRITICAL',
        spreadArea: 2.0,
        spreadUnit: 'Acres',
        spreadRadiusM: 50.8,
        confidence: 0.96,
        affectedFarms: 18,
        windDirection: 'NE (42°)',
        curativeAction: 'प्रोपीकोनाज़ोल 25% EC (1 मिली/लीटर) पत्तियों पर छिड़कें।',
        curativeActionEn: 'Spray Propiconazole 25% EC (1ml/L).',
        farmerName: 'राम कुमार पटेल (Ram Kumar)',
        farmerVillage: 'मलिहाबाद (2.6 km)',
      ),
      const GisOutbreakCluster(
        id: 'DIS-002',
        diseaseName: 'Early Blight (Alternaria solani)',
        diseaseNameHi: 'अगेती झुलसा (टमाटर)',
        cropType: 'Tomato (टमाटर)',
        lat: 26.8226,
        lon: 80.9772,
        distanceKm: 4.1,
        riskLevel: 'HIGH',
        spreadArea: 1000.0,
        spreadUnit: 'Sq Feet',
        spreadRadiusM: 5.4,
        confidence: 0.92,
        affectedFarms: 9,
        windDirection: 'E (88°)',
        curativeAction: 'मैनकोजेब 75% WP (2.5 ग्राम/लीटर) पत्तियों के नीचे अच्छी तरह छिड़कें।',
        curativeActionEn: 'Apply Mancozeb 75% WP (2.5g/L).',
        farmerName: 'सुरेश वर्मा (Suresh Verma)',
        farmerVillage: 'बख्शी का तालाब (4.1 km)',
      ),
      const GisOutbreakCluster(
        id: 'DIS-003',
        diseaseName: 'White Rust (Albugo candida)',
        diseaseNameHi: 'सफेद रतुआ (सरसों)',
        cropType: 'Mustard (सरसों)',
        lat: 26.8847,
        lon: 80.9242,
        distanceKm: 5.8,
        riskLevel: 'MODERATE',
        spreadArea: 2.5,
        spreadUnit: 'Bigha',
        spreadRadiusM: 44.9,
        confidence: 0.91,
        affectedFarms: 6,
        windDirection: 'NW (310°)',
        curativeAction: 'मेटालेक्सिल 8% + मैनकोजेब 64% WP का 2 ग्राम/लीटर पानी में छिड़काव करें।',
        curativeActionEn: 'Spray Metalaxyl 8% + Mancozeb 64% WP at 2g/L.',
        farmerName: 'धरम सिंह (Dharam Singh)',
        farmerVillage: 'मोहनलालगंज (5.8 km)',
      ),
    ];
  }

  List<GisOutbreakCluster> get _filteredOutbreaks {
    if (_activeFilter == 'all') return _outbreaks;
    if (_activeFilter == 'critical') {
      return _outbreaks.where((o) =>
        o.riskLevel == 'CRITICAL' ||
        (o.riskLevel == 'HIGH' && o.distanceKm <= 5.0) ||
        o.distanceKm <= 3.5
      ).toList();
    }
    return _outbreaks.where((o) {
      final cropL = o.cropType.toLowerCase();
      final filtL = _activeFilter.toLowerCase();
      return cropL.contains(filtL) ||
          o.diseaseName.toLowerCase().contains(filtL) ||
          o.diseaseNameHi.toLowerCase().contains(filtL);
    }).toList();
  }

  void _focusOnCluster(GisOutbreakCluster ob) {
    setState(() {
      _selectedOutbreak = ob;
      _zoomLevel = 16.0; // Zoom directly into the 2-acre farm boundary!

      // Global coordinates at current integer zoom
      final int zoomInt = _zoomLevel.floor().clamp(1, 18);
      final double worldPixelSize = 256.0 * (1 << zoomInt);
      final double wx = ((ob.lon + 180.0) / 360.0) * worldPixelSize;
      final double lrad = ob.lat * math.pi / 180.0;
      final double wy = ((1.0 - (math.log(math.tan(lrad) + 1.0 / math.cos(lrad)) / math.pi)) / 2.0) * worldPixelSize;

      final double ulatRad = _userLat * math.pi / 180.0;
      final double uwx = ((_userLon + 180.0) / 360.0) * worldPixelSize;
      final double uwy = ((1.0 - (math.log(math.tan(ulatRad) + 1.0 / math.cos(ulatRad)) / math.pi)) / 2.0) * worldPixelSize;

      _mapOffset = Offset(-(wx - uwx), -(wy - uwy));
    });
  }

  @override
  Widget build(BuildContext context) {
    final isHi = context.currentLanguage != AppLanguage.en;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1710),
      appBar: AppBar(
        backgroundColor: const Color(0xFF131D14),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.radar_rounded, color: Color(0xFF4CAF50), size: 17),
                const SizedBox(width: 7),
                Text(
                  isHi ? 'रोग फैलाव रडार व निगरानी' : 'Regional Disease Spread Radar',
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              isHi ? 'विश्व मानचित्र व लाइव प्रांतीय बुलेटिन' : 'Geospatial Radar & Live Bulletin',
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withValues(alpha: 0.6),
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        actions: [
          // Map Type Switcher Button (Standard, Terrain, Contour, Satellite)
          PopupMenuButton<String>(
            tooltip: isHi ? 'मानचित्र मोड' : 'Map Mode',
            initialValue: _mapType,
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.layers_rounded, size: 14, color: Color(0xFF81C784)),
                  const SizedBox(width: 4),
                  Text(
                    _mapType.toUpperCase(),
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ],
              ),
            ),
            onSelected: (mode) {
              setState(() => _mapType = mode);
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'osm',
                child: Row(
                  children: [
                    const Icon(Icons.public, color: Color(0xFF4CAF50), size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isHi ? 'मानक मानचित्र (Standard Map)' : 'Standard Map View',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'osm_hot',
                child: Row(
                  children: [
                    const Icon(Icons.terrain, color: Color(0xFF81C784), size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isHi ? 'धरातल / स्थलाकृतिक (Terrain)' : 'Terrain & Elevation',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'opentopo',
                child: Row(
                  children: [
                    const Icon(Icons.landscape, color: Color(0xFFFFB74D), size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isHi ? 'कंटूर व ढलान (Contours)' : 'Topographic Contours',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'satellite',
                child: Row(
                  children: [
                    const Icon(Icons.satellite_alt, color: Color(0xFF64B5F6), size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isHi ? 'उपग्रह दृश्य (Satellite View)' : 'Satellite Imagery',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            tooltip: _showRadarSweep ? 'रडार स्वीप रोकें' : 'रडार स्वीप चालू करें',
            icon: Icon(
              _showRadarSweep ? Icons.radar : Icons.radar_outlined,
              color: _showRadarSweep ? const Color(0xFF4CAF50) : Colors.white38,
              size: 20,
            ),
            onPressed: () {
              setState(() => _showRadarSweep = !_showRadarSweep);
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Stack(
        children: [
          // 1. Full Screen Interactive World Map Engine Canvas
          Positioned.fill(
            child: Listener(
              onPointerSignal: (pointerSignal) {
                // Trackpad scroll / mouse wheel zoom
                if (pointerSignal is PointerScrollEvent) {
                  final dy = pointerSignal.scrollDelta.dy;
                  setState(() {
                    _zoomLevel = (_zoomLevel - (dy * 0.005)).clamp(3.0, 18.0);
                  });
                }
              },
              child: GestureDetector(
                onScaleStart: (details) {
                  _startZoom = _zoomLevel;
                  _lastFocalPoint = details.focalPoint;
                },
                onScaleUpdate: (details) {
                  setState(() {
                    // Trackpad pinch zoom
                    if (details.scale != 1.0) {
                      _zoomLevel = (_startZoom + (math.log(details.scale) / math.ln2)).clamp(3.0, 18.0);
                    }
                    // Pan / translation
                    final delta = details.focalPoint - _lastFocalPoint;
                    _lastFocalPoint = details.focalPoint;
                    _mapOffset += delta;
                  });
                },
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final viewportW = constraints.maxWidth;
                    final viewportH = constraints.maxHeight;

                    return Stack(
                      children: [
                        // Base Map: Full-Coverage Slippy Map Tile Grid
                        Positioned.fill(
                          child: _buildWorldMapBaseTiles(viewportW, viewportH),
                        ),

                        // Vector Radar Overlay: Exact 2-acre field boundary, pinpoint zoom-out, and scanning sweep
                        Positioned.fill(
                          child: AnimatedBuilder(
                            animation: _radarController,
                            builder: (context, child) {
                              return CustomPaint(
                                painter: _AgriculturalRadarPainter(
                                  userLat: _userLat,
                                  userLon: _userLon,
                                  userAcres: _userAcres,
                                  khetRadiusMeters: _khetRadiusMeters,
                                  isUserFieldInfected: _isUserFieldInfected,
                                  outbreaks: _filteredOutbreaks,
                                  mapOffset: _mapOffset,
                                  zoomLevel: _zoomLevel,
                                  mapType: _mapType,
                                  radarSweepAngle: _radarController.value * 2 * math.pi,
                                  showRadarSweep: _showRadarSweep,
                                  selectedOutbreakId: _selectedOutbreak?.id,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),

          // 2. Top Sleek Floating Crop & Critical Near Me Filter Carousel (Clean, Translucent)
          Positioned(
            top: 14,
            left: 12,
            right: 12,
            child: _buildTopFilterBar(isHi),
          ),

          // 3. Regional Disease Spread News Feed / Live Bulletin (Collapsible at bottom)
          Positioned(
            left: 12,
            right: 12,
            bottom: _selectedOutbreak != null ? 220 : 20,
            child: _buildRegionalNewsBulletin(isHi),
          ),

          // 4. Map Zoom & Re-Center Controls (Floating Right)
          Positioned(
            right: 14,
            bottom: _selectedOutbreak != null ? 260 : 160,
            child: Column(
              children: [
                _buildMapControlBtn(
                  icon: Icons.add,
                  tooltip: 'Zoom In (ज़ूम इन)',
                  onTap: () {
                    if (_zoomLevel < 18.0) {
                      setState(() => _zoomLevel = (_zoomLevel + 0.5).clamp(3.0, 18.0));
                    }
                  },
                ),
                const SizedBox(height: 8),
                _buildMapControlBtn(
                  icon: Icons.remove,
                  tooltip: 'Zoom Out (ज़ूम आउट)',
                  onTap: () {
                    if (_zoomLevel > 3.0) {
                      setState(() => _zoomLevel = (_zoomLevel - 0.5).clamp(3.0, 18.0));
                    }
                  },
                ),
                const SizedBox(height: 8),
                _buildMapControlBtn(
                  icon: Icons.my_location_rounded,
                  tooltip: 'Re-Center on Farm (खेत पर केंद्रित करें)',
                  highlight: true,
                  onTap: () {
                    setState(() {
                      _mapOffset = Offset.zero;
                      _zoomLevel = 16.0; // Zoom right into the 2-acre farm boundary!
                    });
                  },
                ),
              ],
            ),
          ),

          // 5. Selected Disease Outbreak Detail Bottom Sheet Card
          if (_selectedOutbreak != null)
            Positioned(
              left: 12,
              right: 12,
              bottom: 16,
              child: _buildOutbreakDetailCard(_selectedOutbreak!, isHi),
            ),
        ],
      ),
    );
  }

  // ==========================================
  // TOP COMPACT FLOATING FILTER BAR
  // Contains Crop Filters & Critical Risk (Near Me) with no bulky blocking banners
  // ==========================================
  Widget _buildTopFilterBar(bool isHi) {
    // Collect unique crops from current outbreaks
    final Set<String> cropSet = {};
    for (final ob in _outbreaks) {
      final name = ob.cropType.split('(').first.trim();
      if (name.isNotEmpty) cropSet.add(name);
    }
    // Also include common crops if available
    cropSet.addAll(['Wheat', 'Tomato', 'Mustard', 'Potato']);
    final cropList = cropSet.toList()..sort();

    final List<Map<String, String>> filters = [
      {'key': 'all', 'label': isHi ? 'सभी रोग (${_outbreaks.length})' : 'All (${_outbreaks.length})'},
      {'key': 'critical', 'label': isHi ? '🚨 गंभीर खतरा (निकटतम)' : '🚨 Critical (Near Me)'},
      ...cropList.map((crop) {
        String icon = '🌱';
        final l = crop.toLowerCase();
        if (l.contains('wheat') || l.contains('गेहूं')) icon = '🌾';
        if (l.contains('tomato') || l.contains('टमाटर')) icon = '🍅';
        if (l.contains('apple') || l.contains('सेब')) icon = '🍎';
        if (l.contains('mustard') || l.contains('सरसों')) icon = '🌿';
        if (l.contains('potato') || l.contains('आलू')) icon = '🥔';
        if (l.contains('maize') || l.contains('मक्का')) icon = '🌽';
        return {'key': crop, 'label': '$icon $crop'};
      }),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF131D14).withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 12, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: filters.map((f) {
                  final isSel = _activeFilter == f['key'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: InkWell(
                      onTap: () => setState(() => _activeFilter = f['key']!),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSel ? colorPrimary : Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSel ? const Color(0xFF81C784) : Colors.white10,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          f['label']!,
                          style: TextStyle(
                            color: isSel ? Colors.white : Colors.white70,
                            fontSize: 11.5,
                            fontWeight: isSel ? FontWeight.w800 : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Clean Pill: Tap to view Farm Info Modal without blocking map
          InkWell(
            onTap: () => _showFarmStatusModal(isHi),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: (_isUserFieldInfected ? colorAlert : colorPrimary).withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: (_isUserFieldInfected ? colorAlert : colorPrimary).withValues(alpha: 0.6),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.my_location_rounded,
                    size: 11,
                    color: _isUserFieldInfected ? const Color(0xFFFF5252) : const Color(0xFF81C784),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isLocating ? (isHi ? 'खोज रहे हैं...' : 'Locating...') : '${_userAcres.toStringAsFixed(1)} एकड़',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // FULL-SCREEN SLIPPY MAP TILE ENGINE
  // Renders dynamic world map tiles filling 100% of any viewport
  // ==========================================
  Widget _buildWorldMapBaseTiles(double viewportW, double viewportH) {
    if (_mapType == 'satellite') {
      final staticUrl =
          '${ApiConfig.baseUrl}/kriging/static-map?'
          'lat=$_userLat&lon=$_userLon'
          '&zoom=${_zoomLevel.clamp(3, 18).toInt()}'
          '&size=640x640&scale=2'
          '&maptype=satellite';

      return Transform.translate(
        offset: _mapOffset,
        child: Transform.scale(
          scale: 1.0 + ((_zoomLevel - _zoomLevel.floor()) * 0.5),
          child: Image.network(
            staticUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildCartographyBaseCanvas(),
          ),
        ),
      );
    }

    final int zoomInt = _zoomLevel.floor().clamp(1, 18);
    final double scaleFactor = math.pow(2.0, _zoomLevel - zoomInt).toDouble();
    final double worldTileCount = (1 << zoomInt).toDouble();
    final double worldPixelSize = 256.0 * worldTileCount;

    // Convert (_userLat, _userLon) to global world pixel coordinate at zoomInt
    final double centerWorldX = ((_userLon + 180.0) / 360.0) * worldPixelSize;
    final double latRad = _userLat * math.pi / 180.0;
    final double centerWorldY = ((1.0 - (math.log(math.tan(latRad) + 1.0 / math.cos(latRad)) / math.pi)) / 2.0) * worldPixelSize;

    // Center of the screen in world coordinates taking pan offset into account
    final double screenCenterWorldX = centerWorldX - (_mapOffset.dx / scaleFactor);
    final double screenCenterWorldY = centerWorldY - (_mapOffset.dy / scaleFactor);

    final double halfVisibleW = (viewportW / 2.0) / scaleFactor;
    final double halfVisibleH = (viewportH / 2.0) / scaleFactor;

    final double minWorldX = screenCenterWorldX - halfVisibleW;
    final double maxWorldX = screenCenterWorldX + halfVisibleW;
    final double minWorldY = screenCenterWorldY - halfVisibleH;
    final double maxWorldY = screenCenterWorldY + halfVisibleH;

    int minTileX = (minWorldX / 256.0).floor();
    int maxTileX = (maxWorldX / 256.0).ceil();
    int minTileY = (minWorldY / 256.0).floor().clamp(0, (1 << zoomInt) - 1);
    int maxTileY = (maxWorldY / 256.0).ceil().clamp(0, (1 << zoomInt) - 1);

    // Guard against excessive tile count during extreme window sizes
    if (maxTileX - minTileX > 8) {
      final mid = (minTileX + maxTileX) ~/ 2;
      minTileX = mid - 4;
      maxTileX = mid + 4;
    }
    if (maxTileY - minTileY > 8) {
      final mid = (minTileY + maxTileY) ~/ 2;
      minTileY = (mid - 4).clamp(0, (1 << zoomInt) - 1);
      maxTileY = (mid + 4).clamp(0, (1 << zoomInt) - 1);
    }

    String tileBaseUrl = 'https://tile.openstreetmap.org';
    if (_mapType == 'osm_hot') {
      tileBaseUrl = 'https://a.tile.openstreetmap.fr/hot';
    } else if (_mapType == 'opentopo') {
      tileBaseUrl = 'https://a.tile.opentopomap.org';
    }

    final tiles = <Widget>[];
    for (int ty = minTileY; ty <= maxTileY; ty++) {
      for (int tx = minTileX; tx <= maxTileX; tx++) {
        final wrappedTx = ((tx % (1 << zoomInt)) + (1 << zoomInt)) % (1 << zoomInt);
        final left = (tx * 256.0 - minWorldX) * scaleFactor;
        final top = (ty * 256.0 - minWorldY) * scaleFactor;
        final sizePx = 256.0 * scaleFactor;

        tiles.add(
          Positioned(
            left: left,
            top: top,
            width: sizePx + 0.5, // 0.5px overlap eliminates seam artifacts
            height: sizePx + 0.5,
            child: Image.network(
              '$tileBaseUrl/$zoomInt/$wrappedTx/$ty.png',
              fit: BoxFit.fill,
              cacheWidth: 256,
              cacheHeight: 256,
              headers: const {'User-Agent': 'KrishiSaarthiGeospatialRadar/2.0'},
              errorBuilder: (_, __, ___) => Container(
                color: const Color(0xFF1B281C),
                child: const Center(
                  child: Icon(Icons.terrain, color: Colors.white12, size: 24),
                ),
              ),
            ),
          ),
        );
      }
    }

    return Stack(
      children: [
        _buildCartographyBaseCanvas(),
        ...tiles,
      ],
    );
  }

  Widget _buildCartographyBaseCanvas() {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.2,
          colors: [
            Color(0xFF1C2C1D),
            Color(0xFF121E14),
            Color(0xFF09100B),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // FARM STATUS BOTTOM SHEET (Optional info without blocking map)
  // ==========================================
  void _showFarmStatusModal(bool isHi) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Color(0xFF131D14),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isHi ? 'आपके खेत की स्थिति (Farm Details)' : 'Your Farm Details',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '📍 स्थान: ${_userLat.toStringAsFixed(4)}°N, ${_userLon.toStringAsFixed(4)}°E ($_userLocationLabel)',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Text(
              '🌾 कुल रकबा: ${_userAcres.toStringAsFixed(1)} एकड़ (त्रिज्या: ${_khetRadiusMeters.toStringAsFixed(0)}m)',
              style: const TextStyle(color: Color(0xFFA5D6A7), fontSize: 13, fontWeight: FontWeight.w700),
            ),
            if (_isUserFieldInfected) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorAlert.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colorAlert),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'सक्रिय रोग चेतावनी: ${_activeDiseaseName ?? "रोग"}',
                      style: const TextStyle(color: Color(0xFFFF8A80), fontWeight: FontWeight.w800),
                    ),
                    if (_activeDiseaseTreatment != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'सलाह: $_activeDiseaseTreatment',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // REGIONAL DISEASE SPREAD NEWS FEED & BULLETIN
  // Displays live neighbor outbreaks like agricultural breaking news
  // ==========================================
  Widget _buildRegionalNewsBulletin(bool isHi) {
    final displayReports = _outbreaks.take(5).toList();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF131D14).withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
        boxShadow: const [
          BoxShadow(color: Colors.black87, blurRadius: 16, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          InkWell(
            onTap: () => setState(() => _showNewsBulletin = !_showNewsBulletin),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD32F2F),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'LIVE NEWS',
                          style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isHi ? 'प्रांतीय रोग प्रसार समाचार व बुलेटिन' : 'Regional Disease Spread News',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    _showNewsBulletin ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_up_rounded,
                    color: Colors.white70,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          if (_showNewsBulletin) ...[
            const Divider(height: 1, color: Colors.white12),
            SizedBox(
              height: 105,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: displayReports.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (ctx, i) {
                  final ob = displayReports[i];
                  final isCrit = ob.riskLevel == 'CRITICAL';
                  final isSel = ob.id == _selectedOutbreak?.id;

                  return InkWell(
                    onTap: () => _focusOnCluster(ob),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 250,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSel
                            ? colorPrimary.withValues(alpha: 0.28)
                            : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSel
                              ? colorPrimary
                              : isCrit
                                  ? const Color(0xFFD32F2F).withValues(alpha: 0.6)
                                  : Colors.white12,
                          width: isSel ? 1.5 : 1.0,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  ob.isCommunityReport ? ob.farmerName : ob.cropType,
                                  style: const TextStyle(
                                    color: Color(0xFFA5D6A7),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: isCrit
                                      ? const Color(0xFFD32F2F).withValues(alpha: 0.25)
                                      : const Color(0xFFF57C00).withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${ob.distanceKm} km',
                                  style: TextStyle(
                                    color: isCrit ? const Color(0xFFFF8A80) : const Color(0xFFFFD180),
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              if (ob.isMyReport || ob.id.startsWith('CR-USER-')) ...[
                                const SizedBox(width: 4),
                                InkWell(
                                  onTap: () => _deleteOutbreakReport(ob, isHi),
                                  borderRadius: BorderRadius.circular(4),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    child: Icon(Icons.delete_outline_rounded, color: Color(0xFFFF5252), size: 15),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Text(
                            isHi ? ob.diseaseNameHi : ob.diseaseName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Row(
                            children: [
                              const Icon(Icons.air_rounded, color: Colors.white54, size: 12),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'हवा: ${ob.windDirection} · रकबा: ${ob.spreadArea} ${ob.spreadUnit}',
                                  style: const TextStyle(color: Colors.white60, fontSize: 9.5, fontFamily: 'monospace'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================
  // OUTBREAK DETAIL CARD (BOTTOM POPUP)
  // ==========================================
  Widget _buildOutbreakDetailCard(GisOutbreakCluster outbreak, bool isHi) {
    Color riskColor = colorPrimary;
    if (outbreak.riskLevel == 'CRITICAL') riskColor = colorAlert;
    if (outbreak.riskLevel == 'HIGH') riskColor = colorWarning;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF131D14).withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: riskColor.withValues(alpha: 0.6), width: 1.5),
        boxShadow: const [
          BoxShadow(color: Colors.black87, blurRadius: 20, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: riskColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: riskColor.withValues(alpha: 0.6)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shield_outlined, color: riskColor, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${outbreak.riskLevel} · ${outbreak.distanceKm} km दूर',
                      style: TextStyle(
                        color: riskColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                onPressed: () => setState(() => _selectedOutbreak = null),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            isHi ? outbreak.diseaseNameHi : outbreak.diseaseName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${obLabel(outbreak, isHi)} · रकबा: ${outbreak.spreadArea} ${outbreak.spreadUnit} (~${outbreak.spreadRadiusM.toStringAsFixed(0)}m त्रिज्या)',
            style: const TextStyle(color: Color(0xFFA5D6A7), fontSize: 11, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              children: [
                const Icon(Icons.healing_rounded, size: 16, color: Color(0xFF81C784)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isHi ? outbreak.curativeAction : outbreak.curativeActionEn,
                    style: const TextStyle(color: Colors.white, fontSize: 11.5, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
          if (outbreak.isMyReport || outbreak.id.startsWith('CR-USER-')) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 18),
                label: Text(
                  isHi ? 'रडार से हटाएं (Delete from Radar)' : 'Delete from Radar',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorAlert,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                onPressed: () => _deleteOutbreakReport(outbreak, isHi),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _deleteOutbreakReport(GisOutbreakCluster outbreak, bool isHi) async {
    HapticFeedback.mediumImpact();
    await _sharedRadarService.deleteReport(outbreak.id);
    setState(() {
      _outbreaks.removeWhere((o) => o.id == outbreak.id);
      if (_selectedOutbreak?.id == outbreak.id) {
        _selectedOutbreak = null;
      }
    });
    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isHi
                ? '${outbreak.diseaseNameHi} का प्रकोप रडार से हटा दिया गया'
                : '${outbreak.diseaseName} outbreak removed from radar',
          ),
          backgroundColor: colorPrimary,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  String obLabel(GisOutbreakCluster ob, bool isHi) {
    if (ob.isCommunityReport) {
      return '${ob.farmerName} (${ob.farmerVillage})';
    }
    return '${ob.affectedFarms} खेत प्रभावित · हवा: ${ob.windDirection}';
  }

  Widget _buildMapControlBtn({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    bool highlight = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: highlight ? colorPrimary : const Color(0xFF1A261C).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        elevation: 6,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: highlight ? const Color(0xFF81C784) : Colors.white24),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}

/// Precise Agricultural Radar Painter with Exact Acreage Scaling
/// (e.g. 2 Acres physical boundary with local sweep, and pinpoint beacon when zoomed out)
class _AgriculturalRadarPainter extends CustomPainter {
  final double userLat;
  final double userLon;
  final double userAcres;
  final double khetRadiusMeters;
  final bool isUserFieldInfected;
  final List<GisOutbreakCluster> outbreaks;
  final Offset mapOffset;
  final double zoomLevel;
  final String mapType;
  final double radarSweepAngle;
  final bool showRadarSweep;
  final String? selectedOutbreakId;

  _AgriculturalRadarPainter({
    required this.userLat,
    required this.userLon,
    required this.userAcres,
    required this.khetRadiusMeters,
    required this.isUserFieldInfected,
    required this.outbreaks,
    required this.mapOffset,
    required this.zoomLevel,
    required this.mapType,
    required this.radarSweepAngle,
    required this.showRadarSweep,
    this.selectedOutbreakId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final int zoomInt = zoomLevel.floor().clamp(1, 18);
    final double scaleFactor = math.pow(2.0, zoomLevel - zoomInt).toDouble();
    final double worldPixelSize = 256.0 * (1 << zoomInt);

    // Exact Geo-to-Screen projection matching Slippy Map
    Offset geoToScreen(double lat, double lon) {
      final double wx = ((lon + 180.0) / 360.0) * worldPixelSize;
      final double lrad = lat * math.pi / 180.0;
      final double wy = ((1.0 - (math.log(math.tan(lrad) + 1.0 / math.cos(lrad)) / math.pi)) / 2.0) * worldPixelSize;

      final double ulatRad = userLat * math.pi / 180.0;
      final double uwx = ((userLon + 180.0) / 360.0) * worldPixelSize;
      final double uwy = ((1.0 - (math.log(math.tan(ulatRad) + 1.0 / math.cos(ulatRad)) / math.pi)) / 2.0) * worldPixelSize;

      final double screenCenterX = (size.width / 2.0) + mapOffset.dx;
      final double screenCenterY = (size.height / 2.0) + mapOffset.dy;

      final double dx = (wx - uwx) * scaleFactor;
      final double dy = (wy - uwy) * scaleFactor;

      return Offset(screenCenterX + dx, screenCenterY + dy);
    }

    final center = geoToScreen(userLat, userLon);

    // Physical meters to screen pixels scale factor based on current latitude and continuous zoom
    final metersPerPixel = (156543.03392 * math.cos(userLat * math.pi / 180.0)) / math.pow(2, zoomLevel);
    final pxPerMeter = 1.0 / metersPerPixel;

    // 1. User Farm (Khet) Boundary & Radar
    final userPhysicalPx = khetRadiusMeters * pxPerMeter;
    final isZoomedInFarm = userPhysicalPx >= 12.0 || zoomLevel >= 14.5;

    if (isZoomedInFarm) {
      // Zoomed In: Show exact physical boundary of user's field
      final userColor = isUserFieldInfected ? const Color(0xFFD32F2F) : const Color(0xFF4CAF50);

      // Translucent field zone
      canvas.drawCircle(
        center,
        userPhysicalPx,
        Paint()
          ..color = userColor.withValues(alpha: 0.22)
          ..style = PaintingStyle.fill,
      );

      // Agricultural fence boundary stroke
      canvas.drawCircle(
        center,
        userPhysicalPx,
        Paint()
          ..color = userColor.withValues(alpha: 0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );

      // Local scanning radar sweep confined to user's exact acreage
      if (showRadarSweep) {
        canvas.save();
        canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: userPhysicalPx)));
        final localSweepPaint = Paint()
          ..shader = SweepGradient(
            center: Alignment.center,
            startAngle: 0.0,
            endAngle: math.pi / 2,
            colors: [
              userColor.withValues(alpha: 0.40),
              userColor.withValues(alpha: 0.0),
            ],
            transform: GradientRotation(radarSweepAngle),
          ).createShader(Rect.fromCircle(center: center, radius: userPhysicalPx));
        canvas.drawCircle(center, userPhysicalPx, localSweepPaint);
        canvas.restore();
      }

      // Small beacon dot at center of field
      canvas.drawCircle(center, 4.0, Paint()..color = userColor);
      canvas.drawCircle(center, 6.5, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1.2);
    } else {
      // Zoomed Out: Clean pinpoint beacon
      final userColor = isUserFieldInfected ? const Color(0xFFFF1744) : const Color(0xFF4CAF50);
      canvas.drawCircle(center, 9.0, Paint()..color = userColor.withValues(alpha: 0.35));
      canvas.drawCircle(center, 5.0, Paint()..color = userColor);
      canvas.drawCircle(center, 5.0, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1.5);
    }

    // 2. Neighbor & Community Outbreak Threat Circles & Pins
    for (final ob in outbreaks) {
      final obPos = geoToScreen(ob.lat, ob.lon);

      // Skip offscreen markers to maximize rendering speed
      if (obPos.dx < -100 || obPos.dx > size.width + 100 || obPos.dy < -100 || obPos.dy > size.height + 100) {
        continue;
      }

      final isSelected = ob.id == selectedOutbreakId;
      Color obColor = const Color(0xFF4CAF50);
      if (ob.riskLevel == 'CRITICAL') obColor = const Color(0xFFD32F2F);
      if (ob.riskLevel == 'HIGH') obColor = const Color(0xFFF57C00);

      // Physical spread radius in pixels
      final physicalRadiusPx = ob.spreadRadiusM * pxPerMeter;
      final isOutbreakZoomedIn = physicalRadiusPx >= 12.0 || zoomLevel >= 14.5;

      if (isOutbreakZoomedIn) {
        // Zoomed in: Show EXACT physical acreage boundary (e.g. 2 acres, R = 50.8m)
        final fillPaint = Paint()
          ..color = obColor.withValues(alpha: isSelected ? 0.32 : 0.18)
          ..style = PaintingStyle.fill;

        final borderPaint = Paint()
          ..color = obColor.withValues(alpha: isSelected ? 0.95 : 0.70)
          ..style = PaintingStyle.stroke
          ..strokeWidth = isSelected ? 2.5 : 1.5;

        canvas.drawCircle(obPos, physicalRadiusPx, fillPaint);
        canvas.drawCircle(obPos, physicalRadiusPx, borderPaint);

        // Local Radar Sweep CONFINED TO THIS SPECIFIC OUTBREAK ACREAGE!
        if (showRadarSweep) {
          canvas.save();
          canvas.clipPath(Path()..addOval(Rect.fromCircle(center: obPos, radius: physicalRadiusPx)));
          final localSweep = Paint()
            ..shader = SweepGradient(
              center: Alignment.center,
              startAngle: 0.0,
              endAngle: math.pi / 2,
              colors: [
                obColor.withValues(alpha: 0.35),
                obColor.withValues(alpha: 0.0),
              ],
              transform: GradientRotation(radarSweepAngle),
            ).createShader(Rect.fromCircle(center: obPos, radius: physicalRadiusPx));
          canvas.drawCircle(obPos, physicalRadiusPx, localSweep);
          canvas.restore();
        }

        // Center Pinpoint
        canvas.drawCircle(obPos, isSelected ? 6.0 : 4.5, Paint()..color = obColor);
        canvas.drawCircle(obPos, isSelected ? 8.5 : 6.5, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1.2);

        // Wind Vector Direction Arrow
        final arrowAngle = _parseWindAngle(ob.windDirection);
        const arrowLen = 22.0;
        final arrowEnd = Offset(
          obPos.dx + arrowLen * math.cos(arrowAngle),
          obPos.dy - arrowLen * math.sin(arrowAngle),
        );
        canvas.drawLine(
          obPos,
          arrowEnd,
          Paint()
            ..color = Colors.white70
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      } else {
        // Zoomed Out: Clean pinpoint pin marker
        final pinRadius = isSelected ? 7.0 : 5.0;
        final glowRadius = isSelected ? 12.0 : 9.0;

        canvas.drawCircle(obPos, glowRadius, Paint()..color = obColor.withValues(alpha: 0.35));
        canvas.drawCircle(obPos, pinRadius, Paint()..color = obColor);
        canvas.drawCircle(obPos, pinRadius, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1.2);

        // If selected, small target ring
        if (isSelected) {
          canvas.drawCircle(
            obPos,
            16.0,
            Paint()
              ..color = obColor.withValues(alpha: 0.6)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5,
          );
        }
      }
    }
  }

  double _parseWindAngle(String dir) {
    if (dir.contains('42') || dir.contains('NE')) return math.pi / 4;
    if (dir.contains('88') || dir.contains('E')) return 0.0;
    if (dir.contains('310') || dir.contains('NW')) return 3 * math.pi / 4;
    if (dir.contains('225') || dir.contains('SW')) return 5 * math.pi / 4;
    return math.pi / 3;
  }

  @override
  bool shouldRepaint(covariant _AgriculturalRadarPainter oldDelegate) {
    return oldDelegate.mapOffset != mapOffset ||
        oldDelegate.zoomLevel != zoomLevel ||
        oldDelegate.radarSweepAngle != radarSweepAngle ||
        oldDelegate.selectedOutbreakId != selectedOutbreakId ||
        oldDelegate.outbreaks.length != outbreaks.length;
  }
}
