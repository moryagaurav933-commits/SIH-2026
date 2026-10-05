import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import '../../localization/app_language.dart';
import '../../localization/app_translations.dart';
import '../../services/field_service.dart';
import '../../services/shared_radar_service.dart';
import '../gis/gis_telemetry_screen.dart';

/// Interactive Farmer Khet & Field Palette Screen.
/// Holds the details of the farmer's field (acreage with typing/stepper & units,
/// crop parcels, soil & irrigation) and displays past AI scan disease records
/// with delete capability (styled cleanly for the farmer's own crops).
class FieldPaletteScreen extends StatefulWidget {
  const FieldPaletteScreen({super.key});

  @override
  State<FieldPaletteScreen> createState() => _FieldPaletteScreenState();
}

class _FieldPaletteScreenState extends State<FieldPaletteScreen> {
  // Tactile Pragmatism Design Palette
  static const Color colorBg = Color(0xFFF7FAF7);
  static const Color colorPrimary = Color(0xFF2E7D32);
  static const Color colorPrimaryDark = Color(0xFF1B5E20);
  static const Color colorPrimarySoft = Color(0xFFE8F5E9);
  static const Color colorAlert = Color(0xFFD32F2F);
  static const Color colorAlertSoft = Color(0xFFFFEBEE);
  static const Color colorStone = Color(0xFF1E293B);
  static const Color colorStoneMuted = Color(0xFF64748B);
  static const Color colorHairline = Color(0xFFE2E8F0);

  final FieldService _fieldService = FieldService();
  final SharedRadarService _sharedRadarService = SharedRadarService();

  double _userLat = 26.8467;
  double _userLon = 80.9462;

  bool _isLoading = true;
  double _totalAcres = 4.5;
  String _selectedUnit = 'एकड़ (Acres)';
  String _selectedSoil = 'जलोढ़ दोमट (Alluvial Loam)';
  String _selectedIrrigation = 'नलकूप / ट्यूबवेल (Tube-well)';
  String _khasra = 'खसरा संख्या 412/1';
  List<FieldCropPlot> _plots = [];
  List<VerifiedFieldDiseaseAlert> _verifiedAlerts = [];
  List<CommunityRadarReport> _mySharedReports = [];

  late TextEditingController _acresTextController;

  final List<Map<String, String>> _availableCrops = [
    {'key': 'wheat', 'nameHi': 'गेहूं (Wheat)', 'nameEn': 'Wheat', 'icon': '🌾'},
    {'key': 'mustard', 'nameHi': 'सरसों (Mustard)', 'nameEn': 'Mustard', 'icon': '🌼'},
    {'key': 'tomato', 'nameHi': 'टमाटर (Tomato)', 'nameEn': 'Tomato', 'icon': '🍅'},
    {'key': 'potato', 'nameHi': 'आलू (Potato)', 'nameEn': 'Potato', 'icon': '🥔'},
    {'key': 'paddy', 'nameHi': 'धान / चावल (Paddy)', 'nameEn': 'Paddy', 'icon': '🌾'},
    {'key': 'sugarcane', 'nameHi': 'गन्ना (Sugarcane)', 'nameEn': 'Sugarcane', 'icon': '🎋'},
    {'key': 'maize', 'nameHi': 'मक्का (Maize)', 'nameEn': 'Maize', 'icon': '🌽'},
    {'key': 'cotton', 'nameHi': 'कपास (Cotton)', 'nameEn': 'Cotton', 'icon': '☁️'},
    {'key': 'gram', 'nameHi': 'चना (Gram)', 'nameEn': 'Gram', 'icon': '🌱'},
  ];

  final List<String> _soilOptions = [
    'जलोढ़ दोमट (Alluvial Loam)',
    'काली मिट्टी (Black Soil)',
    'बलुई दोमट (Sandy Loam)',
    'चिकनी मिट्टी (Clay)',
  ];

  final List<String> _irrigationOptions = [
    'नलकूप / ट्यूबवेल (Tube-well)',
    'नहर सिंचाई (Canal)',
    'ड्रिप / स्प्रिंकलर (Drip)',
    'वर्षा आधारित (Rainfed)',
  ];

  @override
  void initState() {
    super.initState();
    _acresTextController = TextEditingController(text: _totalAcres.toStringAsFixed(1));
    _loadProfileData();
  }

  @override
  void dispose() {
    _acresTextController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    final profile = await _fieldService.getProfile();
    final alerts = (await _fieldService.getVerifiedFieldAlerts(threshold: 0.80))
        .where((a) => a.confidence > 0.80)
        .toList();
    final myReports = await _sharedRadarService.getMyReports();

    try {
      final hasPerm = await Geolocator.checkPermission();
      if (hasPerm == LocationPermission.always || hasPerm == LocationPermission.whileInUse) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(timeLimit: Duration(seconds: 4)),
        );
        _userLat = pos.latitude;
        _userLon = pos.longitude;
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _totalAcres = profile.totalAcres > 0 ? profile.totalAcres : 4.5;
        _acresTextController.text = _totalAcres.toStringAsFixed(1);
        _selectedSoil = profile.soilType;
        _selectedIrrigation = profile.irrigationSource;
        _khasra = profile.khasraNumber;
        _plots = List.from(profile.plots);
        _verifiedAlerts = alerts;
        _mySharedReports = myReports;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveAndSync() async {
    HapticFeedback.mediumImpact();
    final updated = FarmerFieldProfile(
      totalAcres: _totalAcres,
      soilType: _selectedSoil,
      irrigationSource: _selectedIrrigation,
      khasraNumber: _khasra,
      plots: _plots,
    );
    await _fieldService.saveProfile(updated);

    if (mounted) {
      final isHi = context.currentLanguage != AppLanguage.en;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isHi
                      ? 'खेत प्रोफ़ाइल सुरक्षित कर दी गई!'
                      : 'Farm profile saved successfully!',
                ),
              ),
            ],
          ),
          backgroundColor: colorPrimaryDark,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _deleteAlert(VerifiedFieldDiseaseAlert alert, bool isHi) async {
    HapticFeedback.lightImpact();
    await _fieldService.deleteVerifiedAlert(alert.id);
    // When deleting from field palette past AI scans, also automatically delete from community radar
    await _sharedRadarService.deleteMyReportsByDisease(alert.diseaseName);
    if (alert.diseaseNameHi.isNotEmpty) {
      await _sharedRadarService.deleteMyReportsByDisease(alert.diseaseNameHi);
    }
    final myReports = await _sharedRadarService.getMyReports();
    setState(() {
      _verifiedAlerts.removeWhere((a) => a.id == alert.id);
      _mySharedReports = myReports;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isHi
                ? '${alert.diseaseNameHi} का रिकॉर्ड खेत व रडार से हटा दिया गया'
                : '${alert.diseaseName} removed from farm & radar',
          ),
          backgroundColor: colorStone,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _deleteSharedRadarReport(String reportId, String diseaseName, bool isHi) async {
    HapticFeedback.lightImpact();
    await _sharedRadarService.deleteReport(reportId);
    final myReports = await _sharedRadarService.getMyReports();
    setState(() {
      _mySharedReports = myReports;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isHi
                ? '$diseaseName का प्रकोप रडार से हटा दिया गया'
                : '$diseaseName outbreak removed from radar',
          ),
          backgroundColor: colorStone,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  double get _allocatedAcres => _plots.fold(0.0, (sum, p) => sum + p.acres);

  @override
  Widget build(BuildContext context) {
    final isHi = context.currentLanguage != AppLanguage.en;

    return Scaffold(
      backgroundColor: colorBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: colorStone, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isHi ? 'मेरा खेत व फसल प्रोफ़ाइल' : 'My Field & Crop Profile',
              style: const TextStyle(
                color: colorStone,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            Text(
              isHi ? 'खेत का क्षेत्रफल, फसलें व पूर्व AI स्कैन' : 'Farm Acreage, Crop Parcels & Past AI Scans',
              style: const TextStyle(
                color: colorStoneMuted,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: colorPrimary),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 60),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Question 1: Total Farming Land (Typing + Stepper + Units)
                  _buildTotalLandCard(isHi),

                  const SizedBox(height: 16),

                  // 2. Question 2: Crop Parcels in Field (Progress + Parcels List)
                  _buildCropParcelsCard(isHi),

                  const SizedBox(height: 16),

                  // 3. Question 3: Soil & Irrigation Configuration
                  _buildSoilAndIrrigationCard(isHi),

                  const SizedBox(height: 16),

                  // 4. Save Profile Action Button
                  _buildSaveButton(isHi),

                  const SizedBox(height: 24),

                  // 5. AT THE END: Past AI Scanned Diseases (Styled cleanly like Image 5 with Delete button)
                  _buildPastAiScannedDiseasesSection(isHi),

                  const SizedBox(height: 20),

                  // 6. Community Shared Radar Palette: Share Disease onto the Radar
                  _buildShareToRadarPalette(isHi),
                ],
              ),
            ),
    );
  }

  // ==========================================
  // QUESTION 1: TOTAL FARMING LAND (TYPING + STEPPER + UNITS)
  // ==========================================
  Widget _buildTotalLandCard(bool isHi) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorHairline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorPrimarySoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.landscape_rounded, color: colorPrimary, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isHi ? 'प्रश्न 1: कुल खेती योग्य भूमि' : 'Question 1: Total Farming Land',
                        style: const TextStyle(
                          color: colorStone,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        isHi ? 'जमीन का रकबा टाइप करें या +/- से बदलें' : 'Type exact land area or use +/- stepper',
                        style: const TextStyle(color: colorStoneMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
              Text(
                '${_totalAcres.toStringAsFixed(1)} $_selectedUnit',
                style: const TextStyle(
                  color: colorPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Interactive Typing & Stepper Palette
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: colorBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colorHairline),
            ),
            child: Row(
              children: [
                // Sequential Series: Minus button
                IconButton(
                  tooltip: 'घटाएं (Subtract 0.5)',
                  icon: const Icon(Icons.remove_circle_outline_rounded, color: colorStoneMuted, size: 26),
                  onPressed: () {
                    if (_totalAcres > 0.5) {
                      setState(() {
                        _totalAcres = double.parse((_totalAcres - 0.5).toStringAsFixed(1));
                        _acresTextController.text = _totalAcres.toStringAsFixed(1);
                      });
                    }
                  },
                ),

                // Direct Typing Palette (Editable Numeric TextField)
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IntrinsicWidth(
                        child: TextField(
                          controller: _acresTextController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: colorStone,
                            fontFamily: 'monospace',
                          ),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                            border: InputBorder.none,
                          ),
                          onChanged: (val) {
                            final parsed = double.tryParse(val.trim());
                            if (parsed != null && parsed > 0) {
                              setState(() {
                                _totalAcres = parsed;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _selectedUnit,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: colorStone,
                        ),
                      ),
                    ],
                  ),
                ),

                // Sequential Series: Plus button
                IconButton(
                  tooltip: 'बढ़ाएं (Add 0.5)',
                  icon: const Icon(Icons.add_circle_outline_rounded, color: colorPrimary, size: 26),
                  onPressed: () {
                    setState(() {
                      _totalAcres = double.parse((_totalAcres + 0.5).toStringAsFixed(1));
                      _acresTextController.text = _totalAcres.toStringAsFixed(1);
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Unit Selector Chips
          Row(
            children: [
              Text(
                isHi ? 'इकाई (Unit): ' : 'Unit: ',
                style: const TextStyle(fontSize: 11.5, color: colorStoneMuted, fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Wrap(
                  spacing: 6,
                  children: [
                    {'key': 'acre', 'hi': 'एकड़ (Acres)', 'en': 'Acres'},
                    {'key': 'bigha', 'hi': 'बीघा (Bigha)', 'en': 'Bigha'},
                    {'key': 'hectare', 'hi': 'हेक्टेयर (Hectare)', 'en': 'Hectare'},
                  ].map((u) {
                    final label = isHi ? u['hi']! : u['en']!;
                    final isSel = _selectedUnit == label;
                    return ChoiceChip(
                      label: Text(label),
                      selected: isSel,
                      onSelected: (_) {
                        setState(() => _selectedUnit = label);
                      },
                      selectedColor: colorPrimarySoft,
                      side: BorderSide(
                        color: isSel ? colorPrimary : colorHairline,
                      ),
                      labelStyle: TextStyle(
                        color: isSel ? colorPrimaryDark : colorStone,
                        fontSize: 11,
                        fontWeight: isSel ? FontWeight.w800 : FontWeight.w500,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Preset Quick Value Chips
          Wrap(
            spacing: 8,
            children: [1.0, 2.5, 5.0, 10.0, 15.0].map((val) {
              final isSel = (_totalAcres - val).abs() < 0.05;
              return ActionChip(
                label: Text('$val $_selectedUnit'),
                backgroundColor: isSel ? colorPrimarySoft : Colors.white,
                side: BorderSide(color: isSel ? colorPrimary : colorHairline),
                labelStyle: TextStyle(
                  color: isSel ? colorPrimaryDark : colorStone,
                  fontSize: 11,
                  fontWeight: isSel ? FontWeight.w800 : FontWeight.w500,
                ),
                onPressed: () {
                  setState(() {
                    _totalAcres = val;
                    _acresTextController.text = _totalAcres.toStringAsFixed(1);
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // QUESTION 2: CROPS IN FIELD (PARCELS)
  // ==========================================
  Widget _buildCropParcelsCard(bool isHi) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorHairline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorPrimarySoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.grass_rounded, color: colorPrimary, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isHi ? 'प्रश्न 2: कौन सी फसल कितने खेत में है?' : 'Question 2: What crops in how much field?',
                        style: const TextStyle(
                          color: colorStone,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        isHi ? 'फसल पार्सल व रकबा आवंटन' : 'Crop parcels and acreage distribution',
                        style: const TextStyle(color: colorStoneMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                tooltip: isHi ? 'नई फसल जोड़ें' : 'Add Crop Parcel',
                icon: const Icon(Icons.add_box_rounded, color: colorPrimary, size: 24),
                onPressed: () => _showAddPlotBottomSheet(context, isHi),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Acreage Distribution Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (_allocatedAcres / (_totalAcres > 0 ? _totalAcres : 1)).clamp(0.0, 1.0),
              backgroundColor: colorBg,
              color: _allocatedAcres > _totalAcres ? colorAlert : colorPrimary,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${isHi ? "आवंटित" : "Allocated"}: ${_allocatedAcres.toStringAsFixed(1)} / ${_totalAcres.toStringAsFixed(1)} एकड़',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _allocatedAcres > _totalAcres ? colorAlert : colorStoneMuted,
                ),
              ),
              Text(
                '${_plots.length} ${isHi ? "फसलें सक्रिय" : "Crops Active"}',
                style: const TextStyle(fontSize: 11, color: colorPrimary, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const Divider(height: 20),

          // Parcels List
          if (_plots.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text(
                  isHi ? 'कोई फसल नहीं जोड़ी गई है। "+ फसल जोड़ें" पर टैप करें।' : 'No crops added yet. Tap "+" to add.',
                  style: const TextStyle(color: colorStoneMuted, fontSize: 12),
                ),
              ),
            )
          else
            ..._plots.asMap().entries.map((entry) {
              final idx = entry.key;
              final plot = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorHairline),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: colorPrimarySoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '#${idx + 1}',
                          style: const TextStyle(
                            color: colorPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plot.cropName,
                            style: const TextStyle(
                              color: colorStone,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            '${plot.stage} · ${plot.acres.toStringAsFixed(1)} एकड़',
                            style: const TextStyle(color: colorStoneMuted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: colorAlert, size: 20),
                      tooltip: isHi ? 'हटाएं' : 'Delete',
                      onPressed: () {
                        setState(() {
                          _plots.removeAt(idx);
                        });
                      },
                    ),
                  ],
                ),
              );
            }),

          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.add_rounded, size: 16),
            label: Text(isHi ? '+ अन्य फसल जोड़ें' : '+ Add Another Crop'),
            style: OutlinedButton.styleFrom(
              foregroundColor: colorPrimary,
              side: const BorderSide(color: colorPrimary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => _showAddPlotBottomSheet(context, isHi),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // QUESTION 3: SOIL & IRRIGATION
  // ==========================================
  Widget _buildSoilAndIrrigationCard(bool isHi) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorHairline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorPrimarySoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.water_drop_rounded, color: colorPrimary, size: 20),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isHi ? 'प्रश्न 3: मिट्टी और सिंचाई व्यवस्था' : 'Question 3: Soil & Irrigation Setup',
                    style: const TextStyle(
                      color: colorStone,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    isHi ? 'सटीक कृषि परामर्श हेतु चयन करें' : 'Select for personalized crop advisory',
                    style: const TextStyle(color: colorStoneMuted, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          Text(
            isHi ? 'मिट्टी का प्रकार (Soil Type):' : 'Soil Type:',
            style: const TextStyle(color: colorStone, fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: _soilOptions.map((soil) {
              final isSel = _selectedSoil == soil;
              return ChoiceChip(
                label: Text(soil),
                selected: isSel,
                onSelected: (_) => setState(() => _selectedSoil = soil),
                selectedColor: colorPrimarySoft,
                labelStyle: TextStyle(
                  color: isSel ? colorPrimary : colorStone,
                  fontSize: 11,
                  fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          Text(
            isHi ? 'सिंचाई का साधन (Irrigation Source):' : 'Irrigation Source:',
            style: const TextStyle(color: colorStone, fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: _irrigationOptions.map((irrig) {
              final isSel = _selectedIrrigation == irrig;
              return ChoiceChip(
                label: Text(irrig),
                selected: isSel,
                onSelected: (_) => setState(() => _selectedIrrigation = irrig),
                selectedColor: colorPrimarySoft,
                labelStyle: TextStyle(
                  color: isSel ? colorPrimary : colorStone,
                  fontSize: 11,
                  fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SAVE BUTTON (CLEAN & SIMPLE)
  // ==========================================
  Widget _buildSaveButton(bool isHi) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.check_circle_rounded, size: 20),
        label: Text(
          isHi ? 'खेत प्रोफ़ाइल सुरक्षित करें (Save Profile)' : 'Save Farm Profile',
          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: colorPrimary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        onPressed: _saveAndSync,
      ),
    );
  }

  // ==========================================
  // PAST AI SCANNED DISEASES (IN THE END, STYLED LIKE IMAGE 5 WITH DELETE BUTTON FOR OURSELVES)
  // ==========================================
  Widget _buildPastAiScannedDiseasesSection(bool isHi) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorHairline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F8E9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.health_and_safety_rounded, color: colorPrimary, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isHi ? 'फसल स्वास्थ्य एवं पूर्व AI स्कैन' : 'Crop Health & Past AI Scans',
                        style: const TextStyle(
                          color: colorStone,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        isHi
                            ? 'आपके पिछले स्कैन में पाए गए रोग (>80% AI सटीकता)'
                            : 'Diseases diagnosed on your crops (>80% Confidence)',
                        style: const TextStyle(color: colorStoneMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _verifiedAlerts.isNotEmpty ? colorAlertSoft : colorPrimarySoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _verifiedAlerts.isNotEmpty
                      ? '${_verifiedAlerts.length} ${isHi ? "रोग दर्ज (>80%)" : "Diseases (>80%)"}'
                      : (isHi ? 'फसल स्वस्थ' : 'Healthy'),
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: _verifiedAlerts.isNotEmpty ? colorAlert : colorPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (_verifiedAlerts.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: colorBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFC8E6C9)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline_rounded, color: colorPrimary, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isHi ? 'सभी फसलें स्वस्थ हैं — कोई सक्रिय रोग नहीं' : 'All crops healthy — No active disease',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: colorStone,
                          ),
                        ),
                        Text(
                          isHi
                              ? 'जब आप AI कैमरा या किसान साथी से स्कैन करेंगे, तो >80% सटीक रोग यहाँ दिखाई देंगे।'
                              : 'When you scan with AI Camera or Copilot, verified diseases (>80% confidence) will appear here.',
                          style: const TextStyle(fontSize: 10.5, color: colorStoneMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            ..._verifiedAlerts.map((alert) {
              final confPct = (alert.confidence * 100).toStringAsFixed(1);
              final cropLabel = alert.cropType.isNotEmpty
                  ? (alert.cropType[0].toUpperCase() + alert.cropType.substring(1))
                  : (isHi ? 'फसल' : 'Crop');

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFD7E5D8)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Row: Bold Disease Title + Delete Button
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            isHi
                                ? 'आपकी $cropLabel फसल पर ${alert.diseaseNameHi} का जोखिम पाया गया'
                                : '${alert.diseaseName} pathogen risk detected on your $cropLabel',
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: colorStone,
                              height: 1.25,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: colorAlert, size: 20),
                          tooltip: isHi ? 'यह रोग रिकॉर्ड हटाएं' : 'Delete disease record',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => _deleteAlert(alert, isHi),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Subtitle (Image 5 style: clean sage green advice for ourselves)
                    Text(
                      isHi
                          ? 'AI सटीकता $confPct% पुष्टि। उपचार: ${alert.treatment}'
                          : 'AI Match $confPct%. Apply ${alert.treatment}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF4A7C59),
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // ==========================================
  // REDESIGNED MODERN BOTTOM SHEET: ADD CROP PARCEL
  // Replaces the clunky Image 4 dialog with a tactile, delightful experience
  // ==========================================
  void _showAddPlotBottomSheet(BuildContext context, bool isHi) {
    String selectedCropKey = 'wheat';
    double plotAcres = 1.0;
    String stage = isHi ? 'वानस्पतिक वृद्धि (Vegetative)' : 'Vegetative Stage';
    final TextEditingController plotTextController = TextEditingController(text: '1.0');

    final remainingLand = math.max(0.0, _totalAcres - _allocatedAcres);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              top: 14,
              left: 20,
              right: 20,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag Handle
                  Center(
                    child: Container(
                      width: 44,
                      height: 4.5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isHi ? 'नई फसल पार्सल जोड़ें' : 'Add New Crop Parcel',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: colorStone,
                            ),
                          ),
                          Text(
                            isHi
                                ? 'फसल चुनें और रकबा टाइप या +/- से दर्ज करें'
                                : 'Select crop & enter area with keypad or +/-',
                            style: const TextStyle(fontSize: 11.5, color: colorStoneMuted),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: colorStoneMuted),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(height: 20),

                  // 1. Select Crop: Visual Tactile Chips
                  Text(
                    isHi ? 'फसल का चयन करें (Select Crop):' : 'Select Crop:',
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: colorStone),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availableCrops.map((c) {
                      final isSel = selectedCropKey == c['key'];
                      return InkWell(
                        onTap: () {
                          setModalState(() => selectedCropKey = c['key']!);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSel ? colorPrimarySoft : colorBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSel ? colorPrimary : colorHairline,
                              width: isSel ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(c['icon'] ?? '🌱', style: const TextStyle(fontSize: 14)),
                              const SizedBox(width: 6),
                              Text(
                                isHi ? c['nameHi']! : c['nameEn']!,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                                  color: isSel ? colorPrimaryDark : colorStone,
                                ),
                              ),
                              if (isSel) ...[
                                const SizedBox(width: 4),
                                const Icon(Icons.check_circle_rounded, size: 14, color: colorPrimary),
                              ],
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),

                  // 2. Growth Stage Selector
                  Text(
                    isHi ? 'विकास चरण (Growth Stage):' : 'Growth Stage:',
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: colorStone),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      isHi ? 'वानस्पतिक वृद्धि (Tillering)' : 'Vegetative',
                      isHi ? 'फूल आना (Flowering)' : 'Flowering',
                      isHi ? 'दाने भरना (Grain filling)' : 'Grain Filling',
                      isHi ? 'परिपक्वता (Maturity)' : 'Maturity',
                    ].map((stg) {
                      final isSel = stage == stg;
                      return ChoiceChip(
                        label: Text(stg),
                        selected: isSel,
                        onSelected: (_) => setModalState(() => stage = stg),
                        selectedColor: colorPrimarySoft,
                        side: BorderSide(color: isSel ? colorPrimary : colorHairline),
                        labelStyle: TextStyle(
                          color: isSel ? colorPrimaryDark : colorStone,
                          fontSize: 11,
                          fontWeight: isSel ? FontWeight.w800 : FontWeight.w500,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),

                  // 3. Area Input: Both Direct Typing & Stepper Series
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isHi ? 'रकबा / Parcel Area (Acres):' : 'Parcel Area (Acres):',
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: colorStone),
                      ),
                      if (remainingLand > 0)
                        Text(
                          '${isHi ? "शेष उपलब्ध" : "Remaining"}: ${remainingLand.toStringAsFixed(1)} एकड़',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: colorPrimary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: colorBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: colorHairline),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: '0.5 एकड़ घटाएं',
                          icon: const Icon(Icons.remove_circle_outline_rounded, color: colorStoneMuted, size: 26),
                          onPressed: () {
                            if (plotAcres > 0.5) {
                              setModalState(() {
                                plotAcres = double.parse((plotAcres - 0.5).toStringAsFixed(1));
                                plotTextController.text = plotAcres.toStringAsFixed(1);
                              });
                            }
                          },
                        ),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IntrinsicWidth(
                                child: TextField(
                                  controller: plotTextController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: colorStone,
                                    fontFamily: 'monospace',
                                  ),
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                                    border: InputBorder.none,
                                  ),
                                  onChanged: (val) {
                                    final parsed = double.tryParse(val.trim());
                                    if (parsed != null && parsed > 0) {
                                      setModalState(() {
                                        plotAcres = parsed;
                                      });
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'एकड़ (Acres)',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: colorStone,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: '0.5 एकड़ बढ़ाएं',
                          icon: const Icon(Icons.add_circle_outline_rounded, color: colorPrimary, size: 26),
                          onPressed: () {
                            setModalState(() {
                              plotAcres = double.parse((plotAcres + 0.5).toStringAsFixed(1));
                              plotTextController.text = plotAcres.toStringAsFixed(1);
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Quick Area Presets
                  Wrap(
                    spacing: 8,
                    children: [
                      0.5,
                      1.0,
                      2.0,
                      3.0,
                      if (remainingLand > 0 && remainingLand != 1.0 && remainingLand != 2.0) remainingLand,
                    ].map((acres) {
                      final isSel = (plotAcres - acres).abs() < 0.05;
                      final isRem = (acres - remainingLand).abs() < 0.05 && remainingLand > 0;
                      return ActionChip(
                        label: Text(
                          isRem
                              ? '${isHi ? "पूरा शेष" : "Remaining"} (${acres.toStringAsFixed(1)})'
                              : '$acres एकड़',
                        ),
                        backgroundColor: isSel ? colorPrimarySoft : Colors.white,
                        side: BorderSide(color: isSel ? colorPrimary : colorHairline),
                        labelStyle: TextStyle(
                          color: isSel ? colorPrimaryDark : colorStone,
                          fontSize: 11,
                          fontWeight: isSel ? FontWeight.w800 : FontWeight.w500,
                        ),
                        onPressed: () {
                          setModalState(() {
                            plotAcres = acres;
                            plotTextController.text = plotAcres.toStringAsFixed(1);
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 22),

                  // Actions: Cancel & Add Parcel
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colorStone,
                            side: const BorderSide(color: colorHairline),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(isHi ? 'रद्द करें' : 'Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.add_task_rounded, size: 18),
                          label: Text(
                            isHi ? 'फसल पार्सल जोड़ें' : 'Add Crop Parcel',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorPrimary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          onPressed: () {
                            final matched = _availableCrops.firstWhere((c) => c['key'] == selectedCropKey);
                            setState(() {
                              _plots.add(FieldCropPlot(
                                id: 'plot_${DateTime.now().millisecondsSinceEpoch}',
                                cropKey: selectedCropKey,
                                cropName: isHi ? matched['nameHi']! : matched['nameEn']!,
                                acres: plotAcres,
                                stage: stage,
                              ));
                            });
                            HapticFeedback.lightImpact();
                            Navigator.pop(ctx);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ==========================================
  // SHARE DISEASE ONTO RADAR PALETTE
  // Bottom palette allowing farmers to report >80% verified outbreaks on OpenStreetMap radar
  // ==========================================
  Widget _buildShareToRadarPalette(bool isHi) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF81C784), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: colorPrimary.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.radar_rounded, color: colorPrimary, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isHi ? 'समुदाय रडार पर रोग साझा करें' : 'Share Outbreak on Radar',
                        style: const TextStyle(
                          color: colorStone,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        isHi
                            ? 'क्षेत्रीय रडार पर साथी किसानों को सचेत करें'
                            : 'Alert local farmers on regional radar',
                        style: const TextStyle(color: colorStoneMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'LIVE RADAR',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: colorPrimary,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isHi
                ? 'यदि आपकी किसी फसल में रोग (>80% पुष्टि) है, तो रकबा व स्थान चुनकर रडार पर साझा करें। यह जानकारी तुरंत कृषि रडार व प्रांतीय समाचार बुलेटिन में दिखेगी।'
                : 'Share verified crop disease (>80% confidence) with spread area and location. It will immediately appear on regional radar and news bulletin.',
            style: const TextStyle(fontSize: 11.5, color: colorStoneMuted, height: 1.35),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.share_location_rounded, size: 18),
              label: Text(
                isHi ? '+ रोग रडार पर साझा करें (+ Share Outbreak)' : '+ Share Outbreak on Radar',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: () => _showShareOutbreakBottomSheet(context, isHi),
            ),
          ),
          if (_mySharedReports.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isHi
                      ? 'आपके द्वारा रडार पर साझा किए गए रोग (${_mySharedReports.length})'
                      : 'Your Active Radar Reports (${_mySharedReports.length})',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: colorStone,
                  ),
                ),
                Text(
                  isHi ? 'हटाने हेतु 🗑️ दबाएं' : 'Tap 🗑️ to delete',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: colorStoneMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._mySharedReports.map((report) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade100),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.coronavirus_rounded, color: Color(0xFFD32F2F), size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  isHi ? report.diseaseNameHi : report.diseaseName,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                    color: colorStone,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  report.cropType,
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    color: colorStoneMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${report.spreadArea.toStringAsFixed(1)} ${report.spreadUnit} • ${report.farmerVillage}',
                            style: const TextStyle(fontSize: 10.5, color: colorStoneMuted),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: isHi ? 'रडार से हटाएं' : 'Delete from Radar',
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                      onPressed: () => _deleteSharedRadarReport(
                        report.id,
                        isHi ? report.diseaseNameHi : report.diseaseName,
                        isHi,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  // ==========================================
  // SHARE OUTBREAK BOTTOM SHEET
  // Filter >80% crops, click +, type spread area (feet/acres/bigha/hectare), select GPS/choose location
  // ==========================================
  void _showShareOutbreakBottomSheet(BuildContext context, bool isHi) {
    // Only crops with confidence > 80%
    final eligibleAlerts = _verifiedAlerts.where((a) => a.confidence > 0.80).toList();

    VerifiedFieldDiseaseAlert? selectedAlert =
        eligibleAlerts.isNotEmpty ? eligibleAlerts.first : null;

    String customCropName = 'गेहूं (Wheat)';
    String customDisease = 'Yellow Rust (पीला रतुआ)';
    double spreadArea = 2.0;
    String spreadUnit = 'Acres'; // 'Acres', 'Sq Feet', 'Bigha', 'Hectare'
    final TextEditingController areaController = TextEditingController(text: '2.0');
    final TextEditingController villageController = TextEditingController(text: 'मलिहाबाद, लखनऊ');

    String locationChoice = 'current'; // 'current' or 'custom'
    double targetLat = _userLat;
    double targetLon = _userLon;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final radiusMeters = CommunityRadarReport.calculateRadiusMeters(spreadArea, spreadUnit);

          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              top: 14,
              left: 20,
              right: 20,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag Handle
                  Center(
                    child: Container(
                      width: 44,
                      height: 4.5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isHi ? 'रडार पर रोग साझा करें' : 'Share Outbreak to Radar',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: colorStone,
                            ),
                          ),
                          Text(
                            isHi
                                ? 'कृषि रडार व प्रांतीय समाचार में तत्काल प्रसारण'
                                : 'Live broadcast to regional radar & news bulletin',
                            style: const TextStyle(fontSize: 11.5, color: colorStoneMuted),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: colorStoneMuted),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(height: 20),

                  // STEP 1: Select Crop Disease (>80% Confidence)
                  Text(
                    isHi ? '1. रोग ग्रस्त फसल चुनें (>80% AI पुष्टि):' : '1. Select Affected Crop (>80% Match):',
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: colorStone),
                  ),
                  const SizedBox(height: 8),

                  if (eligibleAlerts.isNotEmpty) ...[
                    ...eligibleAlerts.map((alert) {
                      final isSelected = selectedAlert?.id == alert.id;
                      final confPct = (alert.confidence * 100).toStringAsFixed(1);

                      return InkWell(
                        onTap: () {
                          setSheetState(() {
                            selectedAlert = alert;
                            customCropName = alert.cropType;
                            customDisease = alert.diseaseName;
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isSelected ? colorPrimarySoft : colorBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? colorPrimary : colorHairline,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSelected ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
                                color: isSelected ? colorPrimary : colorStoneMuted,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isHi ? alert.diseaseNameHi : alert.diseaseName,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w800,
                                        color: isSelected ? colorPrimaryDark : colorStone,
                                      ),
                                    ),
                                    Text(
                                      '${alert.cropType.toUpperCase()} · AI मैच: $confPct%',
                                      style: const TextStyle(fontSize: 10.5, color: colorStoneMuted),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: colorAlertSoft,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  '>80% AI',
                                  style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: colorAlert),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colorBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: colorHairline),
                      ),
                      child: Text(
                        isHi
                            ? 'आपके खेत की डिफ़ॉल्ट फसल: गेहूं (Yellow Rust 94.2% AI मैच)'
                            : 'Default Farm Outbreak: Wheat (Yellow Rust 94.2% AI Match)',
                        style: const TextStyle(fontSize: 11.5, color: colorStone),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),

                  // STEP 2: Spread Area Input (Type feet/acres/bigha/hectare + Stepper)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isHi ? '2. फैलाव क्षेत्र दर्ज करें (Spread Area):' : '2. Enter Spread Area:',
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: colorStone),
                      ),
                      Text(
                        '~${radiusMeters.toStringAsFixed(0)}m ${isHi ? "दायरा" : "Radius"}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: colorPrimary,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: colorHairline),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: 'घटाएं',
                          icon: const Icon(Icons.remove_circle_outline_rounded, color: colorStoneMuted, size: 24),
                          onPressed: () {
                            if (spreadArea > 0.5) {
                              setSheetState(() {
                                spreadArea = double.parse((spreadArea - (spreadUnit == 'Sq Feet' ? 500 : 0.5)).toStringAsFixed(1));
                                areaController.text = spreadArea.toStringAsFixed(1);
                              });
                            }
                          },
                        ),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IntrinsicWidth(
                                child: TextField(
                                  controller: areaController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: colorStone,
                                    fontFamily: 'monospace',
                                  ),
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                                    border: InputBorder.none,
                                  ),
                                  onChanged: (val) {
                                    final parsed = double.tryParse(val.trim());
                                    if (parsed != null && parsed > 0) {
                                      setSheetState(() => spreadArea = parsed);
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                spreadUnit,
                                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: colorStone),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'बढ़ाएं',
                          icon: const Icon(Icons.add_circle_outline_rounded, color: colorPrimary, size: 24),
                          onPressed: () {
                            setSheetState(() {
                              spreadArea = double.parse((spreadArea + (spreadUnit == 'Sq Feet' ? 500 : 0.5)).toStringAsFixed(1));
                              areaController.text = spreadArea.toStringAsFixed(1);
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Unit Selector Chips: Feet, Acres, Bigha, Hectare
                  Wrap(
                    spacing: 6,
                    children: [
                      {'key': 'Acres', 'labelHi': 'एकड़ (Acres)', 'val': 2.0},
                      {'key': 'Sq Feet', 'labelHi': 'वर्ग फीट (Sq Feet)', 'val': 15000.0},
                      {'key': 'Bigha', 'labelHi': 'बीघा (Bigha)', 'val': 3.0},
                      {'key': 'Hectare', 'labelHi': 'हेक्टेयर (Hectare)', 'val': 1.0},
                    ].map((u) {
                      final isSel = spreadUnit == u['key'];
                      return ChoiceChip(
                        label: Text(isHi ? u['labelHi'] as String : u['key'] as String),
                        selected: isSel,
                        onSelected: (_) {
                          setSheetState(() {
                            spreadUnit = u['key'] as String;
                            spreadArea = (u['val'] as num).toDouble();
                            areaController.text = spreadArea.toStringAsFixed(1);
                          });
                        },
                        selectedColor: colorPrimarySoft,
                        side: BorderSide(color: isSel ? colorPrimary : colorHairline),
                        labelStyle: TextStyle(
                          color: isSel ? colorPrimaryDark : colorStone,
                          fontSize: 10.5,
                          fontWeight: isSel ? FontWeight.w800 : FontWeight.w500,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // STEP 3: Location Selection: Current GPS vs Choose Location
                  Text(
                    isHi ? '3. प्रकोप का स्थान चुनें (Select Location):' : '3. Select Outbreak Location:',
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: colorStone),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          avatar: const Icon(Icons.my_location_rounded, size: 16, color: colorPrimary),
                          label: Text(isHi ? 'वर्तमान GPS स्थान' : 'Current GPS'),
                          selected: locationChoice == 'current',
                          onSelected: (_) {
                            setSheetState(() {
                              locationChoice = 'current';
                              targetLat = _userLat;
                              targetLon = _userLon;
                            });
                          },
                          selectedColor: colorPrimarySoft,
                          side: BorderSide(color: locationChoice == 'current' ? colorPrimary : colorHairline),
                          labelStyle: TextStyle(
                            fontSize: 11,
                            fontWeight: locationChoice == 'current' ? FontWeight.w800 : FontWeight.w500,
                            color: locationChoice == 'current' ? colorPrimaryDark : colorStone,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          avatar: const Icon(Icons.edit_location_alt_rounded, size: 16, color: colorStone),
                          label: Text(isHi ? 'स्थान दर्ज करें' : 'Custom Place'),
                          selected: locationChoice == 'custom',
                          onSelected: (_) {
                            setSheetState(() {
                              locationChoice = 'custom';
                              targetLat = _userLat + 0.015;
                              targetLon = _userLon + 0.012;
                            });
                          },
                          selectedColor: colorPrimarySoft,
                          side: BorderSide(color: locationChoice == 'custom' ? colorPrimary : colorHairline),
                          labelStyle: TextStyle(
                            fontSize: 11,
                            fontWeight: locationChoice == 'custom' ? FontWeight.w800 : FontWeight.w500,
                            color: locationChoice == 'custom' ? colorPrimaryDark : colorStone,
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (locationChoice == 'custom') ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: villageController,
                      decoration: InputDecoration(
                        labelText: isHi ? 'गाँव / ब्लॉक / तहसील दर्ज करें' : 'Enter Village / Block / District',
                        hintText: 'उदा. मलिहाबाद, लखनऊ',
                        prefixIcon: const Icon(Icons.place_rounded, size: 18, color: colorPrimary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),

                  // STEP 4: Action Buttons (Cancel & Done)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colorStone,
                            side: const BorderSide(color: colorHairline),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(isHi ? 'रद्द करें' : 'Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.send_rounded, size: 18),
                          label: Text(
                            isHi ? 'रडार पर भेजें व साझा करें' : 'Done & Share to Radar',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorPrimary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          onPressed: () async {
                            final alert = selectedAlert;
                            final dName = alert != null ? alert.diseaseName : customDisease;
                            final dNameHi = alert != null ? alert.diseaseNameHi : customDisease;
                            final cType = alert != null ? alert.cropType : customCropName;
                            final conf = alert != null ? alert.confidence : 0.942;
                            final village = locationChoice == 'custom'
                                ? (villageController.text.trim().isNotEmpty ? villageController.text.trim() : 'निकटवर्ती क्षेत्र')
                                : 'आपका खेत (${targetLat.toStringAsFixed(3)}°N, ${targetLon.toStringAsFixed(3)}°E)';

                            final scaffoldMessenger = ScaffoldMessenger.of(context);
                            final nav = Navigator.of(context);

                            await _sharedRadarService.addReport(
                              farmerName: 'आपका खेत (You / Current Farmer)',
                              farmerVillage: village,
                              diseaseName: dName,
                              diseaseNameHi: dNameHi,
                              cropType: cType,
                              confidence: conf,
                              spreadArea: spreadArea,
                              spreadUnit: spreadUnit,
                              lat: targetLat,
                              lon: targetLon,
                              curativeAdvice: alert != null
                                  ? alert.treatment
                                  : 'प्रोपीकोनाज़ोल 25% EC या 5% नीम तेल बायो-इमल्शन का छिड़काव करें।',
                            );

                            final myReports = await _sharedRadarService.getMyReports();
                            setState(() {
                              _mySharedReports = myReports;
                            });

                            HapticFeedback.mediumImpact();
                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                            }

                            if (!mounted) return;

                            scaffoldMessenger.clearSnackBars();
                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        isHi
                                            ? 'रोग कृषि रडार व प्रांतीय बुलेटिन पर प्रसारित हो गया!'
                                            : 'Outbreak broadcast to regional radar & news bulletin!',
                                      ),
                                    ),
                                  ],
                                ),
                                action: SnackBarAction(
                                  label: isHi ? 'नक्शे पर देखें' : 'View on Map',
                                  textColor: const Color(0xFFA5D6A7),
                                  onPressed: () {
                                    if (!mounted) return;
                                    nav.push(
                                      MaterialPageRoute(builder: (_) => const GisTelemetryScreen()),
                                    );
                                  },
                                ),
                                backgroundColor: colorPrimaryDark,
                                duration: const Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

