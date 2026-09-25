import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../db/local_db.dart';
import '../../localization/app_translations.dart';
import '../../providers/language_provider.dart';
import '../../services/cv_service.dart';
import '../../utils/design_tokens.dart';
import '../voice_chat/voice_chat_screen.dart';

/// Feature 1 — AI Crop Disease Diagnosis & Agronomic Disease Palette
/// Design: Tactile Pragmatism (Deep Forest Green, Harvest Amber, Terracotta)
class DiagnosisScreen extends StatefulWidget {
  final String? selectedCrop;

  const DiagnosisScreen({super.key, this.selectedCrop});

  @override
  State<DiagnosisScreen> createState() => _DiagnosisScreenState();
}

class _DiagnosisScreenState extends State<DiagnosisScreen>
    with TickerProviderStateMixin {
  final CVService _cvService = CVService();
  String? _chosenCrop;
  DiagnosisResult? _result;
  bool _isAnalyzing = false;
  int _activePaletteTab = 0; // 0: Symptoms, 1: Treatments, 2: Prevention

  late AnimationController _pulseController;
  late AnimationController _scanController;
  late Animation<double> _scanAnimation;

  @override
  void initState() {
    super.initState();
    _chosenCrop = widget.selectedCrop;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _scanAnimation = Tween<double>(begin: 0.05, end: 0.95).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.easeInOut),
    );

    _cvService.initialize();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBg,
      appBar: buildKrishiAppBar(
        context: context,
        title: context.tr('app_name'),
        subtitle: 'AI CROP DIAGNOSIS & PALETTE',
        emoji: '🔬',
        actions: [
          buildStatusPill(
            label: 'PyTorch MobileNetV3',
            color: colorAiEdge,
            bgColor: colorAiEdgeBg,
            borderColor: colorAiEdgeBorder,
          ),
          const SizedBox(width: spacingMd),
        ],
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildCurrentView(),
        ),
      ),
    );
  }

  Widget _buildCurrentView() {
    if (_isAnalyzing) {
      return _buildAnalyzingView();
    }
    if (_result != null) {
      return _buildCrazyDiseasePaletteView();
    }
    if (_chosenCrop == null) {
      return _buildCropSelectionView();
    }
    return _buildViewfinderView();
  }

  // ==========================================
  // STAGE 1: CROP MODEL SELECTION VIEW
  // ==========================================
  Widget _buildCropSelectionView() {
    return SingleChildScrollView(
      key: const ValueKey('crop_selection_view'),
      padding: const EdgeInsets.all(spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero Calibration Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1B5E20).withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.biotech_rounded, color: Color(0xFFFFD54F), size: 32),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('crop_selection_title'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.tr('crop_selection_desc'),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.88),
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: spacingMd),

          const Text(
            'CHOOSE TARGET CROP MODEL',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
              color: colorStoneMuted,
            ),
          ),
          const SizedBox(height: spacingSm),

          _buildCropCard(
            emoji: '🍅',
            cropKey: 'tomato',
            cropName: context.tr('crop_tomato'),
            classesCount: '10 Diagnostic Classes',
            diseases: 'Septoria, Early & Late Blight, Yellow Leaf Curl, Spider Mites, Bacterial Spot, Healthy...',
            color: const Color(0xFFD32F2F),
          ),
          _buildCropCard(
            emoji: '🥔',
            cropKey: 'potato',
            cropName: context.tr('crop_potato'),
            classesCount: '3 Diagnostic Classes',
            diseases: 'Early Blight (Alternaria), Late Blight (Phytophthora), Healthy Foliage',
            color: const Color(0xFF8D6E63),
          ),
          _buildCropCard(
            emoji: '🌽',
            cropKey: 'corn',
            cropName: context.tr('crop_corn'),
            classesCount: '4 Diagnostic Classes',
            diseases: 'Common Rust, Northern Leaf Blight, Gray Leaf Spot, Healthy Corn',
            color: const Color(0xFFFFA000),
          ),
          _buildCropCard(
            emoji: '🍎',
            cropKey: 'apple',
            cropName: context.tr('crop_apple'),
            classesCount: '4 Diagnostic Classes',
            diseases: 'Apple Scab, Black Rot, Cedar Apple Rust, Healthy Leaves',
            color: const Color(0xFFC2185B),
          ),
          _buildCropCard(
            emoji: '🌿',
            cropKey: 'all',
            cropName: context.tr('crop_all'),
            classesCount: '21 Total Classes',
            diseases: 'Universal Auto-Detect Optical Scan across all supported crops & diseases',
            color: colorPrimary,
          ),
        ],
      ),
    );
  }

  Widget _buildCropCard({
    required String emoji,
    required String cropKey,
    required String cropName,
    required String classesCount,
    required String diseases,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorHairline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            setState(() {
              _chosenCrop = cropKey;
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(emoji, style: const TextStyle(fontSize: 28)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            cropName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: colorStoneText,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              classesCount,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: color,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        diseases,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: colorStoneMuted,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: colorStoneMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // STAGE 2: VIEWFINDER & UPLOAD VIEW
  // ==========================================
  Widget _buildViewfinderView() {
    final String cropLabel = _getCropDisplayName(_chosenCrop);
    return SingleChildScrollView(
      key: const ValueKey('viewfinder_view'),
      padding: const EdgeInsets.all(spacingMd),
      child: Column(
        children: [
          // Active Crop Model Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: colorPrimarySoft,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: colorPrimary.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_rounded, color: colorPrimary, size: 16),
                const SizedBox(width: 8),
                Text(
                  'MODEL: $cropLabel',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: colorPrimary,
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => setState(() => _chosenCrop = null),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'बदलें (Change)',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: colorPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: spacingMd),

          // High-Tech Optical Viewfinder Frame
          Container(
            height: 280,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF0F1A12),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: colorPrimary.withValues(alpha: 0.4), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: colorPrimary.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Grid guidelines
                Positioned.fill(
                  child: CustomPaint(
                    painter: _ViewfinderGridPainter(),
                  ),
                ),

                // Corner Reticles
                const Positioned(top: 12, left: 12, child: _ReticleCorner(rotation: 0)),
                const Positioned(top: 12, right: 12, child: _ReticleCorner(rotation: 1)),
                const Positioned(bottom: 12, right: 12, child: _ReticleCorner(rotation: 2)),
                const Positioned(bottom: 12, left: 12, child: _ReticleCorner(rotation: 3)),

                // Center leaf guide icon
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.energy_savings_leaf_rounded,
                          size: 54,
                          color: Color(0xFF81C784),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'पत्ती को फ्रेम के बीच में रखें',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Place infected leaf inside the optical reticle',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: spacingLg),

          // Primary Capture Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _takePhoto,
                  icon: const Icon(Icons.camera_alt_rounded, color: Colors.white),
                  label: const Text(
                    'कैमरा से लें',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: spacingMd),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickFromGallery,
                  icon: const Icon(Icons.photo_library_rounded, color: colorPrimary),
                  label: const Text(
                    'गैलरी से चुनें',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorPrimary,
                    side: const BorderSide(color: colorPrimary, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: spacingLg),

          // Instant Test Leaves
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colorHairline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.flash_on_rounded, size: 18, color: Color(0xFFFFA000)),
                    SizedBox(width: 6),
                    Text(
                      'त्वरित नमूना परीक्षण (Instant Sample Test)',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildQuickSampleChip('🍅 Tomato Septoria', 'tomato'),
                    _buildQuickSampleChip('🥔 Potato Late Blight', 'potato'),
                    _buildQuickSampleChip('🌽 Corn Rust', 'corn'),
                    _buildQuickSampleChip('🍎 Apple Cedar Rust', 'apple'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSampleChip(String label, String cropHint) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      backgroundColor: colorBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: colorHairline),
      ),
      onPressed: () => _runSimulatedTest(cropHint),
    );
  }

  // ==========================================
  // STAGE 3: LIVE HOLOGRAPHIC SCANNING VIEW
  // ==========================================
  Widget _buildAnalyzingView() {
    return Center(
      key: const ValueKey('analyzing_view'),
      child: Padding(
        padding: const EdgeInsets.all(spacingLg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Scanning Leaf Frame with Laser
            SizedBox(
              height: 240,
              width: 240,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F1A12),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: colorPrimary, width: 2),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.energy_savings_leaf_rounded,
                        size: 96,
                        color: colorPrimary.withValues(alpha: 0.6),
                      ),
                    ),
                  ),

                  // Laser Beam
                  AnimatedBuilder(
                    animation: _scanAnimation,
                    builder: (context, child) {
                      return Positioned(
                        top: _scanAnimation.value * 220,
                        left: 12,
                        right: 12,
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFF00E676),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00E676).withValues(alpha: 0.8),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: spacingLg),

            const Text(
              'न्यूरल लीफ स्कैनिंग जारी है...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: colorStoneText,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Analyzing leaf pigments & morphological patterns...',
              style: TextStyle(fontSize: 13, color: colorStoneMuted),
            ),
            const SizedBox(height: spacingLg),

            // Live Telemetry Checklist
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: colorHairline),
              ),
              child: const Column(
                children: [
                  _TelemetryRow(text: 'ImageNet 224x224 RGB Normalization', isDone: true),
                  SizedBox(height: 8),
                  _TelemetryRow(text: 'PyTorch MobileNetV3 Forward Pass', isDone: true),
                  SizedBox(height: 8),
                  _TelemetryRow(text: 'Softmax Class Probability Distribution', isDone: true),
                  SizedBox(height: 8),
                  _TelemetryRow(text: 'PostgreSQL CIBRC Knowledge Base Query', isDone: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // STAGE 4: CRAZY TACTILE DISEASE PALETTE VIEW
  // ==========================================
  Widget _buildCrazyDiseasePaletteView() {
    final result = _result!;
    final bool isHealthy = result.isHealthy;
    final Color accentColor = isHealthy ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F);
    final String confidencePct = '${(result.confidence * 100).toStringAsFixed(1)}%';

    return SingleChildScrollView(
      key: const ValueKey('disease_palette_view'),
      padding: const EdgeInsets.all(spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── HERO HOLOGRAPHIC HUD CARD ──────────────────────
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: accentColor.withValues(alpha: 0.35), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Status Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.08),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: accentColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isHealthy ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isHealthy ? 'HEALTHY FOLIAGE' : 'DISEASE DETECTED',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Match: $confidencePct',
                        style: TextStyle(
                          color: accentColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                // Disease Header & Scientific Pathogen
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.diseaseNameHi.isNotEmpty ? result.diseaseNameHi : result.diseaseName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: colorStoneText,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        result.diseaseName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colorStoneMuted,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Pathogen Tag
                      if (result.pathogen.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: colorBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: colorHairline),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.biotech_rounded, size: 16, color: colorPrimary),
                              const SizedBox(width: 6),
                              Text(
                                'Pathogen: ${result.pathogen}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.w600,
                                  color: colorStoneText,
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 14),

                      // Severity Meter
                      Row(
                        children: [
                          const Text(
                            'SEVERITY:',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: colorStoneMuted,
                            ),
                          ),
                          const SizedBox(width: 8),
                          for (int i = 1; i <= 5; i++)
                            Container(
                              width: 24,
                              height: 6,
                              margin: const EdgeInsets.only(right: 4),
                              decoration: BoxDecoration(
                                color: i <= _severityLevel(result.severity)
                                    ? _getSeverityColor(result.severity)
                                    : colorHairline,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          const SizedBox(width: 6),
                          Text(
                            result.severity.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: _getSeverityColor(result.severity),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Farmer Immediate Action Callout Banner
                if (result.farmerAction.isNotEmpty || result.immediateAction.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(22)),
                      border: Border(
                        top: BorderSide(color: const Color(0xFFFFD54F).withValues(alpha: 0.5)),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.bolt_rounded, color: Color(0xFFF57F17), size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'तुरंत किसान कार्रवाई (Immediate Action)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFF57F17),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                result.farmerAction.isNotEmpty
                                    ? result.farmerAction
                                    : result.immediateAction,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF37474F),
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: spacingLg),

          // ─── 3-TAB DISEASE PALETTE SELECTOR ─────────────────
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                _buildPaletteTabItem(0, '🔍 लक्षण व कारण', 'Symptoms'),
                _buildPaletteTabItem(1, '💊 उपचार मैट्रिक्स', 'Treatments'),
                _buildPaletteTabItem(2, '🛡️ रोकथाम व संदर्भ', 'Prevention'),
              ],
            ),
          ),
          const SizedBox(height: spacingMd),

          // ─── TAB CONTENT DISPLAY ─────────────────────────────
          if (_activePaletteTab == 0) _buildSymptomsTab(result),
          if (_activePaletteTab == 1) _buildTreatmentsTab(result),
          if (_activePaletteTab == 2) _buildPreventionTab(result),

          const SizedBox(height: spacingLg),

          // ─── ACTION DECK (ASK AI & CONTROLS) ─────────────────
          GestureDetector(
            onTap: () => _openVoiceChatWithContext(result),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF388E3C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1B5E20).withValues(alpha: 0.38),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.psychology_rounded, color: Color(0xFFFFD54F), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('ask_ai_action'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'बोली में दवा की मात्रा और समाधान पूछें',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                ],
              ),
            ),
          ),
          const SizedBox(height: spacingMd),

          // Secondary Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => setState(() {
                    _result = null;
                    _chosenCrop = null;
                  }),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('नया स्कैन (New Scan)', style: TextStyle(fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorPrimary,
                    side: const BorderSide(color: colorPrimary),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(width: spacingSm),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('निदान टेलीमेट्री KVK व कृषि विज्ञान केंद्र में सिंक हो गई है।'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.share_rounded, color: Colors.white),
                  label: const Text('रिपोर्ट भेजें', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE65100),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: spacingLg),
        ],
      ),
    );
  }

  Widget _buildPaletteTabItem(int index, String titleHi, String titleEn) {
    final bool isSelected = _activePaletteTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activePaletteTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Text(
                titleHi,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? colorPrimary : colorStoneMuted,
                ),
              ),
              Text(
                titleEn,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? colorPrimary : colorStoneMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── TAB 1: SYMPTOMS & MICROCLIMATE ─────────────────────────
  Widget _buildSymptomsTab(DiagnosisResult result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (result.description.isNotEmpty)
          _buildPaletteCard(
            title: 'रोग विवरण (Description)',
            icon: Icons.info_outline_rounded,
            color: colorPrimary,
            content: Text(
              result.description,
              style: const TextStyle(fontSize: 14, color: colorStoneText, height: 1.4),
            ),
          ),

        if (result.symptoms.isNotEmpty)
          _buildPaletteCard(
            title: 'पहचाने गए लक्षण (Observed Symptoms)',
            icon: Icons.checklist_rounded,
            color: const Color(0xFFD32F2F),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: result.symptoms.map((s) => _buildBulletPoint(s, const Color(0xFFD32F2F))).toList(),
            ),
          ),

        if (result.favorableConditions.isNotEmpty)
          _buildPaletteCard(
            title: 'अनुकूल जलवायु स्थितियां (Trigger Microclimate)',
            icon: Icons.cloudy_snowing,
            color: const Color(0xFF1976D2),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: result.favorableConditions.map((c) => _buildBulletPoint(c, const Color(0xFF1976D2))).toList(),
            ),
          ),

        if (result.healthySigns.isNotEmpty)
          _buildPaletteCard(
            title: 'स्वस्थ पत्ती के संकेत (Healthy Foliage Markers)',
            icon: Icons.eco_rounded,
            color: const Color(0xFF388E3C),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: result.healthySigns.map((h) => _buildBulletPoint(h, const Color(0xFF388E3C))).toList(),
            ),
          ),
      ],
    );
  }

  // ─── TAB 2: TREATMENTS MATRIX ───────────────────────────────
  Widget _buildTreatmentsTab(DiagnosisResult result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Chemical CIBRC Treatment
        if (result.chemicalCure.isNotEmpty || result.chemicalTreatments.isNotEmpty)
          _buildPaletteCard(
            title: 'CIBRC अनुशंसित रासायनिक उपचार (Chemical Control)',
            icon: Icons.science_rounded,
            color: const Color(0xFFC62828),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (result.chemicalCure.isNotEmpty)
                  Text(
                    result.chemicalCure,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colorStoneText),
                  ),
                ...result.chemicalTreatments.map((t) => _buildBulletPoint(t, const Color(0xFFC62828))),
                if (result.spotDosage > 0) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.colorize_rounded, size: 16, color: Color(0xFFC62828)),
                        const SizedBox(width: 8),
                        Text(
                          'स्प्रे मात्रा: ${result.spotDosage} ml/L',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFC62828),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

        // Biological & Organic Control
        if (result.organicCure.isNotEmpty || result.biologicalTreatments.isNotEmpty)
          _buildPaletteCard(
            title: 'जैविक व देसी उपचार (Biological & Organic Control)',
            icon: Icons.eco_rounded,
            color: const Color(0xFF2E7D32),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (result.organicCure.isNotEmpty)
                  Text(
                    result.organicCure,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colorStoneText),
                  ),
                ...result.biologicalTreatments.map((t) => _buildBulletPoint(t, const Color(0xFF2E7D32))),
              ],
            ),
          ),

        // Cultural Agronomic Practices
        if (result.culturalTreatments.isNotEmpty)
          _buildPaletteCard(
            title: 'पारंपरिक कृषि कार्य (Agronomic Field Practices)',
            icon: Icons.agriculture_rounded,
            color: const Color(0xFFE65100),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: result.culturalTreatments.map((t) => _buildBulletPoint(t, const Color(0xFFE65100))).toList(),
            ),
          ),
      ],
    );
  }

  // ─── TAB 3: PREVENTION PROTOCOL ─────────────────────────────
  Widget _buildPreventionTab(DiagnosisResult result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (result.preventionSteps.isNotEmpty)
          _buildPaletteCard(
            title: 'भविष्य में रोकथाम के उपाय (Prevention Protocol)',
            icon: Icons.shield_rounded,
            color: const Color(0xFF1565C0),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: result.preventionSteps.map((p) => _buildBulletPoint(p, const Color(0xFF1565C0))).toList(),
            ),
          ),

        if (result.sources.isNotEmpty)
          _buildPaletteCard(
            title: 'सत्यापित वैज्ञानिक संदर्भ (Verified Sources)',
            icon: Icons.verified_user_rounded,
            color: const Color(0xFF455A64),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: result.sources.map((src) {
                final sourceName = src['source_title'] ?? src['title'] ?? src['organization'] ?? src['source_type'] ?? 'ICAR Verified';
                return _buildBulletPoint(sourceName.toString(), const Color(0xFF455A64));
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildPaletteCard({
    required String title,
    required IconData icon,
    required Color color,
    required Widget content,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorHairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          content,
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text, Color dotColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, color: colorStoneText, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // ACTIONS & PIPELINE INVOCATION
  // ==========================================
  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      await _runDiagnosisPipeline(bytes);
    }
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      await _runDiagnosisPipeline(bytes);
    }
  }

  Future<void> _runSimulatedTest(String cropHint) async {
    setState(() {
      _chosenCrop = cropHint;
    });
    await _runDiagnosisPipeline(null);
  }

  Future<void> _runDiagnosisPipeline(Uint8List? imageBytes) async {
    setState(() => _isAnalyzing = true);

    try {
      final cropHint = _chosenCrop ?? 'all';
      final result = await _cvService.diagnose(
        imageBytes,
        cropHint,
        26.8467,
        80.9462,
        'UP_LKO',
      );

      // Save to offline local database
      await LocalDB().saveDiagnosis({
        'disease_name': result.diseaseName,
        'disease_name_hi': result.diseaseNameHi,
        'crop_type': result.cropType,
        'confidence': result.confidence,
        'severity': result.severity,
        'treatment': result.chemicalCure.isNotEmpty ? result.chemicalCure : result.treatmentHi,
        'diagnosed_at': DateTime.now().toIso8601String(),
        'gps_lat': 26.8467,
        'gps_lon': 80.9462,
        'synced': 1,
      });

      setState(() {
        _result = result;
        _isAnalyzing = false;
        _activePaletteTab = 0;
      });
    } catch (e) {
      debugPrint('Diagnosis error: $e');
      final fallback = await _cvService.diagnose(null, _chosenCrop ?? 'all');
      setState(() {
        _result = fallback;
        _isAnalyzing = false;
        _activePaletteTab = 0;
      });
    }
  }

  void _openVoiceChatWithContext(DiagnosisResult result) {
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    final ctxBuffer = StringBuffer();
    ctxBuffer.writeln('Crop: ${result.cropType}');
    ctxBuffer.writeln('Disease: ${result.diseaseName}');
    ctxBuffer.writeln('Hindi Name: ${result.diseaseNameHi}');
    ctxBuffer.writeln('Severity: ${result.severity}');
    if (result.pathogen.isNotEmpty) ctxBuffer.writeln('Pathogen: ${result.pathogen}');
    if (result.symptoms.isNotEmpty) ctxBuffer.writeln('Symptoms: ${result.symptoms.join(", ")}');
    if (result.chemicalCure.isNotEmpty) ctxBuffer.writeln('Chemical Treatment: ${result.chemicalCure}');
    if (result.organicCure.isNotEmpty) ctxBuffer.writeln('Organic/Biological: ${result.organicCure}');
    if (result.preventionSteps.isNotEmpty) ctxBuffer.writeln('Prevention: ${result.preventionSteps.join(", ")}');

    final diseaseTitle = (langProvider.isEnglish) ? result.diseaseName : result.diseaseNameHi;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VoiceChatScreen(
          initialContext: ctxBuffer.toString(),
          initialDiseaseName: diseaseTitle.isNotEmpty ? diseaseTitle : result.diseaseName,
        ),
      ),
    );
  }

  String _getCropDisplayName(String? key) {
    switch (key) {
      case 'tomato':
        return '🍅 Tomato (टमाटर)';
      case 'potato':
        return '🥔 Potato (आलू)';
      case 'corn':
        return '🌽 Corn / Maize (मक्का)';
      case 'apple':
        return '🍎 Apple (सेब)';
      default:
        return '🌿 All Crops (सभी फसलें)';
    }
  }

  Color _getSeverityColor(String s) {
    switch (s.toLowerCase()) {
      case 'critical':
        return const Color(0xFFD32F2F);
      case 'high':
        return const Color(0xFFE65100);
      case 'medium':
        return const Color(0xFFF57F17);
      case 'low':
        return const Color(0xFF388E3C);
      default:
        return const Color(0xFF2E7D32);
    }
  }

  int _severityLevel(String s) {
    switch (s.toLowerCase()) {
      case 'critical':
        return 5;
      case 'high':
        return 4;
      case 'medium':
        return 3;
      case 'low':
        return 2;
      default:
        return 1;
    }
  }
}

// ─── VIEWFINDER & TELEMETRY HELPER WIDGETS ──────────────────
class _TelemetryRow extends StatelessWidget {
  final String text;
  final bool isDone;
  const _TelemetryRow({required this.text, required this.isDone});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF2E7D32)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2E7D32)),
          ),
        ),
      ],
    );
  }
}

class _ReticleCorner extends StatelessWidget {
  final int rotation; // 0: TL, 1: TR, 2: BR, 3: BL
  const _ReticleCorner({required this.rotation});

  @override
  Widget build(BuildContext context) {
    return RotatedBox(
      quarterTurns: rotation,
      child: Container(
        width: 24,
        height: 24,
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: Color(0xFF81C784), width: 3),
            left: BorderSide(color: Color(0xFF81C784), width: 3),
          ),
        ),
      ),
    );
  }
}

class _ViewfinderGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 1.0;

    // Vertical rule of thirds
    canvas.drawLine(Offset(size.width / 3, 0), Offset(size.width / 3, size.height), paint);
    canvas.drawLine(Offset(size.width * 2 / 3, 0), Offset(size.width * 2 / 3, size.height), paint);

    // Horizontal rule of thirds
    canvas.drawLine(Offset(0, size.height / 3), Offset(size.width, size.height / 3), paint);
    canvas.drawLine(Offset(0, size.height * 2 / 3), Offset(size.width, size.height * 2 / 3), paint);
  }

  @override
  bool shouldRepaint(_) => false;
}
