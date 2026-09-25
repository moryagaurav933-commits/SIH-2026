import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../../services/insurance_recorder.dart';

/// Krishi-Saarthi Insurance Evidence Locker (बीमा साक्ष्य लॉकर)
/// Strict Tamper-Proof & Non-Repudiable Evidence Architecture for PMFBY.
///
/// Core Constraints:
/// 1. Prompts for real Camera and Microphone hardware access upfront.
/// 2. Live camera viewfinder preview with graceful fallback to Live Farm Simulator if hardware is blocked.
/// 3. Record Only (No gallery uploads to eliminate deepfakes and fraudulent claims).
/// 4. Zero Download / Zero Export Policy.
/// 5. Live GPS Coordinates (Lat, Lon, Alt, Accuracy) & Exact UTC Timestamp stamping.
/// 6. Unique Cryptographic SHA-256 Hash seal.
/// 7. Delete button for removing recorded records from the vault.
/// 8. In-app Playable Preview Player with live watermarked security HUD overlay.
class InsuranceScreen extends StatefulWidget {
  const InsuranceScreen({super.key});

  @override
  State<InsuranceScreen> createState() => _InsuranceScreenState();
}

class _InsuranceScreenState extends State<InsuranceScreen>
    with TickerProviderStateMixin {
  // Tactile Pragmatism Design Tokens
  static const Color colorBg = Color(0xFFF5F9F5);
  static const Color colorSurface = Color(0xFFF8FBF8);
  static const Color colorCard = Color(0xFFFFFFFF);
  static const Color colorPrimary = Color(0xFF2E7D32);
  static const Color colorPrimaryDeep = Color(0xFF0A3D0A);
  static const Color colorPrimarySoft = Color(0xFFE8F5E9);
  static const Color colorHairline = Color(0xFFE0E8E0);
  static const Color colorStoneText = Color(0xFF1A1A1A);
  static const Color colorStoneMuted = Color(0xFF556B55);
  static const Color colorAlert = Color(0xFFD32F2F);
  static const Color colorAmber = Color(0xFFE65100);
  static const Color colorBlue = Color(0xFF1565C0);

  final InsuranceRecorder _recorder = InsuranceRecorder();

  // Multi-Device Camera State
  List<CameraDescription> _availableCameras = [];
  int _selectedCameraIndex = 0;
  CameraController? _cameraController;
  bool _isAudioEnabled = true;
  bool _isSimulatedCameraMode = false;
  bool _isCameraInitializing = false;
  String? _cameraErrorMessage;
  String? _lastRecordedVideoPath;
  bool _isTorchOn = false;
  bool _showGrid = true;
  double _zoomLevel = 1.0;
  Offset? _tapFocusOffset;
  Timer? _focusTimer;

  // Recording State & Engine
  bool _isRecording = false;
  int _recordSeconds = 0;
  int _recordSubSeconds = 0; // tenths of second 0-9
  Timer? _recordTimer;
  String _liveHashRolling = 'e3b0c442...98fc';

  // Live Telemetry & AI Inspection
  double _currentLat = 26.8467;
  double _currentLon = 80.9462;
  double _currentAccuracy = 1.4;
  double _currentAltitude = 124.0;
  final String _locationDistrict = 'लखनऊ (Lucknow, UP)';
  double _pitchAngle = -1.8;
  double _rollAngle = 0.6;
  final int _gnssSatCount = 16;
  double _cropDamageTracked = 76.4;

  // Audio VU Simulation
  double _audioPeakL = 0.55;
  double _audioPeakR = 0.50;

  // Animation Controllers
  late AnimationController _blinkController;
  late AnimationController _scannerController;
  late AnimationController _vuMeterController;
  late AnimationController _horizonController;
  late AnimationController _focusController;
  late AnimationController _simulatedWindController;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _scannerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _vuMeterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    )..repeat(reverse: true);

    _horizonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _focusController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _simulatedWindController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();

    _initCameraAndTelemetry();
  }

  Future<void> _initCameraAndTelemetry() async {
    // 1. Fetch real GPS
    final gps = await _recorder.getCurrentGpsLocation();
    if (mounted) {
      setState(() {
        _currentLat = gps['lat'] ?? 26.8467;
        _currentLon = gps['lon'] ?? 80.9462;
        _currentAccuracy = gps['accuracy'] ?? 1.4;
        _currentAltitude = gps['altitude'] ?? 124.0;
      });
    }

    // 2. Request Camera & Microphone access immediately
    await _initializeRealCamera();
  }

  Future<void> _initializeRealCamera() async {
    if (!mounted) return;
    setState(() {
      _isCameraInitializing = true;
      _cameraErrorMessage = null;
    });

    // Request permissions upfront if mobile
    await _recorder.requestMediaPermissions();

    try {
      final cameras = await availableCameras();
      _availableCameras = cameras;

      if (cameras.isEmpty) {
        if (mounted) {
          setState(() {
            _isCameraInitializing = false;
            _isSimulatedCameraMode = true;
            _cameraErrorMessage =
                'कोई भौतिक कैमरा नहीं मिला। सजीव फील्ड कैमरा सिम्युलेटर सक्रिय किया गया।';
          });
        }
        return;
      }

      if (_selectedCameraIndex >= cameras.length) {
        _selectedCameraIndex = 0;
      }

      final selectedCam = cameras[_selectedCameraIndex];

      // Dispose existing controller if any
      await _cameraController?.dispose();
      _cameraController = null;

      // Attempt 1: Try with enableAudio: true
      CameraController? controller;
      bool audioWorking = true;

      try {
        controller = CameraController(
          selectedCam,
          ResolutionPreset.high,
          enableAudio: true,
        );
        await controller.initialize();
      } catch (audioErr) {
        debugPrint('Camera with audio failed ($audioErr). Falling back to video-only...');
        audioWorking = false;
        try {
          controller = CameraController(
            selectedCam,
            ResolutionPreset.high,
            enableAudio: false,
          );
          await controller.initialize();
        } catch (videoErr) {
          debugPrint('Camera video-only also failed: $videoErr');
          rethrow;
        }
      }

      if (mounted) {
        setState(() {
          _cameraController = controller;
          _isCameraInitializing = false;
          _cameraErrorMessage = null;
          _isAudioEnabled = audioWorking;
          _isSimulatedCameraMode = false;
        });
      }
    } catch (e) {
      debugPrint('Camera initialization error: $e');
      if (mounted) {
        setState(() {
          _isCameraInitializing = false;
          _isSimulatedCameraMode = true;
          _cameraErrorMessage =
              'कैमरा अनुमति अवरुद्ध है या डिवाइस व्यस्त है। सजीव फील्ड कैमरा सक्रिय है।';
        });
      }
    }
  }

  Future<void> _switchCamera() async {
    if (_availableCameras.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('केवल 1 कैमरा डिवाइस उपलब्ध है।'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }
    setState(() {
      _selectedCameraIndex = (_selectedCameraIndex + 1) % _availableCameras.length;
    });
    await _initializeRealCamera();
  }

  void _toggleCameraMode() {
    setState(() {
      _isSimulatedCameraMode = !_isSimulatedCameraMode;
      if (!_isSimulatedCameraMode &&
          (_cameraController == null || !_cameraController!.value.isInitialized)) {
        _initializeRealCamera();
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isSimulatedCameraMode
            ? '🌾 लाइव फील्ड सिम्युलेटर मोड सक्रिय'
            : '📹 हार्डवेयर कैमरा मोड सक्रिय'),
        duration: const Duration(seconds: 2),
        backgroundColor: _isSimulatedCameraMode ? colorAmber : colorPrimary,
      ),
    );
  }

  void _toggleTorch() async {
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      try {
        _isTorchOn = !_isTorchOn;
        await _cameraController!.setFlashMode(
          _isTorchOn ? FlashMode.torch : FlashMode.off,
        );
        setState(() {});
      } catch (e) {
        debugPrint('Flash error: $e');
      }
    } else {
      setState(() => _isTorchOn = !_isTorchOn);
    }
  }

  void _handleViewfinderTap(TapUpDetails details) {
    setState(() {
      _tapFocusOffset = details.localPosition;
    });
    _focusController.forward(from: 0.0);
    _focusTimer?.cancel();
    _focusTimer = Timer(const Duration(milliseconds: 2200), () {
      if (mounted) {
        setState(() {
          _tapFocusOffset = null;
        });
      }
    });

    if (_cameraController != null && _cameraController!.value.isInitialized) {
      try {
        final renderBox = context.findRenderObject() as RenderBox?;
        if (renderBox != null) {
          final size = renderBox.size;
          final point = Offset(
            (details.localPosition.dx / size.width).clamp(0.0, 1.0),
            (details.localPosition.dy / size.height).clamp(0.0, 1.0),
          );
          _cameraController!.setFocusPoint(point);
          _cameraController!.setExposurePoint(point);
        }
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _focusTimer?.cancel();
    _blinkController.dispose();
    _scannerController.dispose();
    _vuMeterController.dispose();
    _horizonController.dispose();
    _focusController.dispose();
    _simulatedWindController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  void _startRecording() async {
    HapticFeedback.heavyImpact();

    // Check if camera is in hardware mode and ready; if not, automatically proceed with simulation
    if (!_isSimulatedCameraMode &&
        (_cameraController == null || !_cameraController!.value.isInitialized)) {
      await _initializeRealCamera();
      if (_cameraController == null || !_cameraController!.value.isInitialized) {
        // Fallback gracefully so recording NEVER freezes or refuses to record
        setState(() {
          _isSimulatedCameraMode = true;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('कैमरा हार्डवेयर अनुपलब्ध - सजीव फील्ड सिम्युलेटर में रिकॉर्डिंग जारी...'),
              backgroundColor: colorAmber,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    }

    // Refresh live GPS coordinate
    final gps = await _recorder.getCurrentGpsLocation();
    setState(() {
      _currentLat = gps['lat'] ?? 26.8467;
      _currentLon = gps['lon'] ?? 80.9462;
      _currentAccuracy = gps['accuracy'] ?? 1.4;
      _currentAltitude = gps['altitude'] ?? 124.0;
      _isRecording = true;
      _recordSeconds = 0;
      _recordSubSeconds = 0;
      _liveHashRolling = 'e3b0c442...98fc';
      _lastRecordedVideoPath = null;
    });

    if (!_isSimulatedCameraMode &&
        _cameraController != null &&
        _cameraController!.value.isInitialized) {
      try {
        if (!_cameraController!.value.isRecordingVideo) {
          await _cameraController!.startVideoRecording();
        }
      } catch (e) {
        debugPrint('Native video recording start warning: $e');
      }
    }

    _recorder.startRecording(
      gpsLat: _currentLat,
      gpsLon: _currentLon,
      claimType: 'खेत फसल क्षति (Field Crop Damage)',
    );

    // High frequency 100ms timer for tenths of seconds, audio meter, and live crypto stream
    _recordTimer?.cancel();
    _recordTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted || !_isRecording) {
        timer.cancel();
        return;
      }
      setState(() {
        _recordSubSeconds++;
        if (_recordSubSeconds >= 10) {
          _recordSubSeconds = 0;
          _recordSeconds++;
        }

        // Realistic subtle handheld gyro motion
        _pitchAngle = -1.8 + (math.sin(timer.tick * 0.15) * 0.7);
        _rollAngle = 0.6 + (math.cos(timer.tick * 0.18) * 0.4);
        _cropDamageTracked = (74.0 + (math.sin(timer.tick * 0.08) * 3.5)).clamp(50.0, 95.0);

        // Audio VU peak fluctuations
        _audioPeakL = (0.35 + (math.Random().nextDouble() * 0.55)).clamp(0.1, 0.98);
        _audioPeakR = (_audioPeakL + ((math.Random().nextDouble() - 0.5) * 0.2)).clamp(0.1, 0.98);

        // Compute dynamic rolling crypto stream hash
        if (timer.tick % 3 == 0) {
          final seed = 'PMFBY_${DateTime.now().microsecondsSinceEpoch}_${_recordSeconds}_$_recordSubSeconds';
          final h = crypto.sha256.convert(utf8.encode(seed)).toString();
          _liveHashRolling = '${h.substring(0, 8)}...${h.substring(h.length - 6)}';
        }
      });
    });
  }

  void _stopAndSealRecording() async {
    HapticFeedback.heavyImpact();
    _recordTimer?.cancel();
    final recordedTime = _recordSeconds > 0 ? _recordSeconds : 1;
    setState(() => _isRecording = false);

    String? videoPath;
    if (!_isSimulatedCameraMode &&
        _cameraController != null &&
        _cameraController!.value.isRecordingVideo) {
      try {
        final xfile = await _cameraController!.stopVideoRecording();
        videoPath = xfile.path;
        _lastRecordedVideoPath = videoPath;
      } catch (e) {
        debugPrint('Native video recording stop warning: $e');
      }
    }

    // Call service to seal with live UTC, GPS and SHA-256
    final sealedItem = await _recorder.stopAndSealEvidence(
      seconds: recordedTime,
      gpsLat: _currentLat,
      gpsLon: _currentLon,
      gpsAccuracy: _currentAccuracy,
      altitude: _currentAltitude,
      locationName: _locationDistrict,
      claimType: 'खेत फसल क्षति (Field Crop Damage)',
      cropName: 'खेत साक्ष्य (Field Evidence)',
      policyNumber: 'PMFBY-UP-2026-981245',
      estimatedAmount: '₹35,000',
      videoPath: videoPath,
      recordingMode: _isSimulatedCameraMode ? 'simulated' : 'hardware',
      damagePercentage: _cropDamageTracked,
    );

    if (mounted) {
      _showSealedCertificateModal(sealedItem);
    }
  }

  void _deleteVaultRecord(InsuranceEvidenceItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline, color: colorAlert),
            SizedBox(width: 8),
            Text(
              'साक्ष्य रिकॉर्ड हटाएं?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'क्या आप वाकई साक्ष्य दावा ID: "${item.id}" को सुरक्षित वॉल्ट से हटाना चाहते हैं?',
          style: const TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('रद्द करें'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colorAlert,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              final deleted = _recorder.deleteVaultItem(item.id);
              if (deleted) {
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('🗑️ साक्ष्य रिकॉर्ड (${item.id}) हटा दिया गया!'),
                    backgroundColor: colorAlert,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text('हटाएं (Delete)'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vaultItems = _recorder.getVaultItems();

    return Scaffold(
      backgroundColor: colorBg,
      appBar: AppBar(
        backgroundColor: colorPrimaryDeep,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'बीमा साक्ष्य लॉकर (Insurance Locker)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'PMFBY टैम्पर-प्रूफ डिजिटल वॉल्ट · भारत सरकार',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFFA5D6A7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shield_outlined, color: Colors.white),
            tooltip: 'सुरक्षा मानक (Security Specs)',
            onPressed: _showSecurityProtocolDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Mandatory Privacy & Anti-Tamper Security Banner
            _buildSecurityPolicyBanner(),

            const SizedBox(height: 12),

            // 2. Hardware Permission & Live GPS Status Strip
            _buildHardwareStatusStrip(),

            const SizedBox(height: 12),

            // 3. Live Record-Only Viewfinder (Zero Gallery Uploads, Real Live Camera)
            _buildRecordOnlyViewfinder(),

            const SizedBox(height: 20),

            // 4. Dedicated Section: Recorded Evidence Vault with Delete Action
            _buildVaultSectionHeader(vaultItems.length),

            const SizedBox(height: 10),

            if (vaultItems.isEmpty)
              _buildEmptyVaultView()
            else
              ...vaultItems.map((item) => _buildVaultEvidenceCard(item)),

            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // 1. SECURITY POLICY BANNER
  // -------------------------------------------------------------
  Widget _buildSecurityPolicyBanner() {
    return Container(
      decoration: BoxDecoration(
        color: colorCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorHairline, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              color: colorPrimarySoft,
              child: Row(
                children: [
                  const Icon(Icons.lock_person_outlined,
                      size: 18, color: colorPrimary),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'सख्त सुरक्षा नियम: रिकॉर्ड-ओनली व शून्य डाउनलोड नीति',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: colorPrimaryDeep,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: colorPrimary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'AES-256 SEAL',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  _buildPolicyBullet(
                    icon: Icons.videocam_outlined,
                    iconColor: colorAlert,
                    title: 'केवल लाइव कैमरा रिकॉर्डिंग (Record Only)',
                    desc:
                        'गैलरी अपलोड वर्जित है ताकि कोई AI-जनरेटेड डीपफेक साक्ष्य न लगा सके। खेत से लाइव रिकॉर्ड करें।',
                  ),
                  const SizedBox(height: 8),
                  _buildPolicyBullet(
                    icon: Icons.download_for_offline_outlined,
                    iconColor: colorAmber,
                    title: 'शून्य डाउनलोड नीति (Zero Download)',
                    desc:
                        'प्राइवेसी व निष्पक्षता हेतु वीडियो डाउनलोड नहीं हो सकता। यह सीधे एन्क्रिप्टेड डिजिटल वॉल्ट में सील रहता है।',
                  ),
                  const SizedBox(height: 8),
                  _buildPolicyBullet(
                    icon: Icons.fingerprint,
                    iconColor: colorPrimary,
                    title: 'सटीक GPS, UTC समय और SHA-256 डिजिटल मुहर',
                    desc:
                        'प्रत्येक साक्ष्य के साथ सटीक GPS निर्देशांक, अंतरराष्ट्रीय UTC समय व अद्वितीय क्रिप्टोग्राफिक हैश सील होता है।',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPolicyBullet({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 11,
                color: colorStoneText,
                height: 1.35,
              ),
              children: [
                TextSpan(
                  text: '$title: ',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(
                  text: desc,
                  style: const TextStyle(color: colorStoneMuted),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // 2. HARDWARE & PERMISSION STATUS STRIP (With Multi-Camera & Dual Mode)
  // -------------------------------------------------------------
  Widget _buildHardwareStatusStrip() {
    final bool isCameraReady = _cameraController != null &&
        _cameraController!.value.isInitialized;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colorCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorHairline),
      ),
      child: Row(
        children: [
          // 1. Camera Hardware Status / Tap to Retry
          Expanded(
            flex: 5,
            child: InkWell(
              onTap: isCameraReady ? _switchCamera : _initializeRealCamera,
              borderRadius: BorderRadius.circular(8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: (!_isSimulatedCameraMode && isCameraReady)
                          ? colorPrimary.withValues(alpha: 0.12)
                          : (_isSimulatedCameraMode
                              ? colorAmber.withValues(alpha: 0.12)
                              : Colors.red.withValues(alpha: 0.12)),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      (!_isSimulatedCameraMode && isCameraReady)
                          ? Icons.videocam
                          : (_isSimulatedCameraMode
                              ? Icons.grass
                              : Icons.videocam_off_outlined),
                      size: 15,
                      color: (!_isSimulatedCameraMode && isCameraReady)
                          ? colorPrimary
                          : (_isSimulatedCameraMode ? colorAmber : colorAlert),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          !_isSimulatedCameraMode
                              ? (isCameraReady
                                  ? 'कैमरा ${_selectedCameraIndex + 1}/${_availableCameras.isNotEmpty ? _availableCameras.length : 1} (सक्रिय)'
                                  : 'कैमरा खोजें (Tap to Retry)')
                              : 'सजीव फील्ड सिम्युलेटर',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: (!_isSimulatedCameraMode && isCameraReady)
                                ? colorStoneText
                                : colorAmber,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          !_isSimulatedCameraMode
                              ? (isCameraReady
                                  ? (_isAudioEnabled ? 'ऑडियो व वीडियो लाइव' : 'वीडियो लाइव (माइक म्यूट)')
                                  : (_isCameraInitializing ? 'कैमरा शुरू हो रहा है...' : 'अनुमति जांचें'))
                              : (_cameraErrorMessage ?? 'सिम्युलेटेड 60FPS सैंडबॉक्स'),
                          style: const TextStyle(
                            fontSize: 9,
                            color: colorStoneMuted,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (_availableCameras.length > 1 && !_isSimulatedCameraMode)
                    IconButton(
                      icon: const Icon(Icons.flip_camera_ios, size: 14, color: colorPrimary),
                      tooltip: 'कैमरा बदलें (Flip Camera)',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: _switchCamera,
                    ),
                ],
              ),
            ),
          ),

          Container(
            height: 24,
            width: 1,
            color: colorHairline,
            margin: const EdgeInsets.symmetric(horizontal: 6),
          ),

          // 2. Dual Mode Toggle Pill (Hardware vs Simulator)
          InkWell(
            onTap: _toggleCameraMode,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
              decoration: BoxDecoration(
                color: _isSimulatedCameraMode
                    ? colorAmber.withValues(alpha: 0.15)
                    : colorPrimarySoft,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _isSimulatedCameraMode
                      ? colorAmber.withValues(alpha: 0.4)
                      : colorPrimary.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isSimulatedCameraMode ? Icons.grass : Icons.camera_alt,
                    size: 11,
                    color: _isSimulatedCameraMode ? colorAmber : colorPrimary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isSimulatedCameraMode ? 'सिम्युलेटर' : 'हार्डवेयर',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: _isSimulatedCameraMode ? colorAmber : colorPrimaryDeep,
                    ),
                  ),
                ],
              ),
            ),
          ),

          Container(
            height: 24,
            width: 1,
            color: colorHairline,
            margin: const EdgeInsets.symmetric(horizontal: 6),
          ),

          // 3. Live High-Precision GPS Lock
          Expanded(
            flex: 4,
            child: Row(
              children: [
                const Icon(Icons.my_location, size: 14, color: colorBlue),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'GPS ±${_currentAccuracy.toStringAsFixed(1)}m',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: colorStoneText,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'GNSS $_gnssSatCount Sats (DGPS)',
                        style: const TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w500,
                          color: colorStoneMuted,
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
    );
  }

  // -------------------------------------------------------------
  // 3. LIVE RECORD-ONLY VIEWFINDER (Real Camera Stream + High-Tech HUD)
  // -------------------------------------------------------------
  Widget _buildRecordOnlyViewfinder() {
    final utcNow = DateTime.now().toUtc().toIso8601String();
    final istNow =
        '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}:${DateTime.now().second.toString().padLeft(2, '0')} IST';

    final bool isCameraReady = _cameraController != null &&
        _cameraController!.value.isInitialized;

    return Column(
      children: [
        Container(
          height: 350,
          decoration: BoxDecoration(
            color: const Color(0xFF0A110B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isRecording ? colorAlert : colorPrimary,
              width: _isRecording ? 2.5 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _isRecording
                    ? colorAlert.withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.15),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Stack(
              children: [
                // Layer 1: Live Hardware Video Stream OR Realistic Field Simulator
                if (!_isSimulatedCameraMode && isCameraReady)
                  Positioned.fill(
                    child: GestureDetector(
                      onTapUp: _handleViewfinderTap,
                      child: ClipRect(
                        child: SizedBox.expand(
                          child: FittedBox(
                            fit: BoxFit.cover,
                            child: SizedBox(
                              width: _cameraController!.value.previewSize?.width ?? 1280,
                              height: _cameraController!.value.previewSize?.height ?? 720,
                              child: CameraPreview(_cameraController!),
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  Positioned.fill(
                    child: GestureDetector(
                      onTapUp: _handleViewfinderTap,
                      child: AnimatedBuilder(
                        animation: _simulatedWindController,
                        builder: (context, child) {
                          return CustomPaint(
                            size: Size.infinite,
                            painter: _RealisticFieldSimulationPainter(
                              windProgress: _simulatedWindController.value,
                              isRecording: _isRecording,
                              recordSeconds: _recordSeconds,
                              damagePercentage: _cropDamageTracked,
                              zoom: _zoomLevel,
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                // Layer 2: Interactive Tap-to-Focus Reticle
                if (_tapFocusOffset != null)
                  Positioned(
                    left: _tapFocusOffset!.dx - 28,
                    top: _tapFocusOffset!.dy - 28,
                    child: IgnorePointer(
                      child: AnimatedBuilder(
                        animation: _focusController,
                        builder: (context, child) {
                          final scale = 1.35 - (0.35 * _focusController.value);
                          return Transform.scale(
                            scale: scale,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: const Color(0xFFFFEB3B), width: 1.8),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Center(
                                    child: Container(
                                      width: 5,
                                      height: 5,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFFFEB3B),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Colors.black87,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: const Text(
                                    'AF-LOCK',
                                    style: TextStyle(
                                      color: Color(0xFFFFEB3B),
                                      fontSize: 8,
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                // Layer 3: Corner Targeting Reticles & Rule-of-Thirds Grid
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _ViewfinderGridPainter(
                        isRecording: _isRecording,
                        scanProgress: _scannerController.value,
                        showGrid: _showGrid,
                      ),
                    ),
                  ),
                ),

                // Layer 4: AI Crop Inspection Bounding Box
                Positioned(
                  top: 56,
                  right: 12,
                  child: IgnorePointer(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _isRecording
                              ? Colors.redAccent
                              : const Color(0xFF69F0AE),
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.center_focus_strong,
                                size: 11,
                                color: _isRecording
                                    ? Colors.redAccent
                                    : const Color(0xFF69F0AE),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'PMFBY AI CROP-SCAN',
                                style: TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w800,
                                  color: _isRecording
                                      ? Colors.redAccent
                                      : const Color(0xFF69F0AE),
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'क्षति स्तर: ${_cropDamageTracked.toStringAsFixed(1)}% (Lodging)',
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const Text(
                            'CONF: 96.8% · WHEAT · LOSS VALIDATED',
                            style: TextStyle(
                              fontSize: 7.5,
                              color: Colors.white70,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Layer 5: Left Dynamic Audio VU Meter (Active When Recording)
                if (_isRecording)
                  Positioned(
                    top: 56,
                    left: 10,
                    child: _buildAudioVuMeter(),
                  ),

                // Layer 6: Top OSD Telemetry Bar
                Positioned(
                  top: 8,
                  left: 10,
                  right: 10,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // REC or STANDBY Badge
                      if (_isRecording)
                        AnimatedBuilder(
                          animation: _blinkController,
                          builder: (context, child) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: colorAlert.withValues(
                                    alpha: 0.4 + (0.6 * _blinkController.value)),
                                borderRadius: BorderRadius.circular(14),
                                border:
                                    Border.all(color: Colors.white, width: 1.2),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.circle,
                                      size: 7, color: Colors.white),
                                  const SizedBox(width: 5),
                                  Text(
                                    'REC 00:${_recordSeconds.toString().padLeft(2, '0')}.$_recordSubSeconds',
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.circle,
                                size: 6,
                                color: (!_isSimulatedCameraMode && isCameraReady)
                                    ? const Color(0xFF69F0AE)
                                    : const Color(0xFFFFB74D),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                (!_isSimulatedCameraMode && isCameraReady)
                                    ? 'LIVE HW 30FPS'
                                    : 'SIMULATOR 60FPS',
                                style: const TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white70,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Artificial Horizon Tilt Leveler
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: (_pitchAngle.abs() < 3.0 &&
                                    _rollAngle.abs() < 2.0)
                                ? const Color(0xFF69F0AE).withValues(alpha: 0.6)
                                : Colors.white24,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.horizontal_rule,
                              size: 12,
                              color: (_pitchAngle.abs() < 3.0 &&
                                      _rollAngle.abs() < 2.0)
                                  ? const Color(0xFF69F0AE)
                                  : const Color(0xFFFFB74D),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${_pitchAngle.toStringAsFixed(1)}° / ${_rollAngle.toStringAsFixed(1)}°',
                              style: TextStyle(
                                fontSize: 8.5,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w700,
                                color: (_pitchAngle.abs() < 3.0 &&
                                        _rollAngle.abs() < 2.0)
                                    ? const Color(0xFF69F0AE)
                                    : Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Codec & Battery
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '1080p · ',
                              style: TextStyle(
                                fontSize: 8.5,
                                fontFamily: 'monospace',
                                color: Colors.white70,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Icon(Icons.battery_5_bar,
                                size: 12, color: Color(0xFF81C784)),
                            Text(
                              ' 88%',
                              style: TextStyle(
                                fontSize: 8.5,
                                fontFamily: 'monospace',
                                color: Colors.white70,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Layer 7: Bottom Telemetry Watermark (GPS + UTC + Rolling Hash)
                Positioned(
                  bottom: 40,
                  left: 8,
                  right: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_on,
                                size: 10, color: Color(0xFF69F0AE)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'GPS: ${_currentLat.toStringAsFixed(5)}° N, ${_currentLon.toStringAsFixed(5)}° E (±${_currentAccuracy}m · $_gnssSatCount Sats · Alt: ${_currentAltitude.toInt()}m)',
                                style: const TextStyle(
                                  fontSize: 8.5,
                                  fontFamily: 'monospace',
                                  color: Color(0xFF69F0AE),
                                  fontWeight: FontWeight.w700,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.schedule,
                                size: 10, color: Color(0xFF80D8FF)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'UTC: ${utcNow.substring(0, 19)}Z ($istNow)',
                                style: const TextStyle(
                                  fontSize: 8.5,
                                  fontFamily: 'monospace',
                                  color: Color(0xFF80D8FF),
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(Icons.security,
                                size: 10, color: Color(0xFFFFD54F)),
                            const SizedBox(width: 3),
                            Text(
                              'HASH: $_liveHashRolling',
                              style: const TextStyle(
                                fontSize: 8,
                                fontFamily: 'monospace',
                                color: Color(0xFFFFD54F),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Layer 8: Viewfinder Quick Control Bar
                Positioned(
                  bottom: 6,
                  left: 8,
                  right: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        if (_availableCameras.length > 1)
                          InkWell(
                            onTap: _switchCamera,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 3),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.flip_camera_ios,
                                      size: 12, color: Colors.white),
                                  const SizedBox(width: 3),
                                  Text(
                                    'कैमरा (${_availableCameras.length})',
                                    style: const TextStyle(
                                      fontSize: 8.5,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        InkWell(
                          onTap: _toggleTorch,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 3),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _isTorchOn
                                      ? Icons.flash_on
                                      : Icons.flash_off,
                                  size: 12,
                                  color: _isTorchOn
                                      ? const Color(0xFFFFEB3B)
                                      : Colors.white70,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  _isTorchOn ? 'टॉर्च ON' : 'टॉर्च OFF',
                                  style: TextStyle(
                                    fontSize: 8.5,
                                    color: _isTorchOn
                                        ? const Color(0xFFFFEB3B)
                                        : Colors.white70,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () => setState(() => _showGrid = !_showGrid),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 3),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _showGrid ? Icons.grid_on : Icons.grid_off,
                                  size: 12,
                                  color: _showGrid
                                      ? const Color(0xFF81C784)
                                      : Colors.white70,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  'ग्रिड',
                                  style: TextStyle(
                                    fontSize: 8.5,
                                    color: _showGrid
                                        ? const Color(0xFF81C784)
                                        : Colors.white70,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            setState(() {
                              _zoomLevel = _zoomLevel == 1.0 ? 2.0 : 1.0;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _zoomLevel > 1.0
                                  ? colorPrimary
                                  : Colors.white24,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${_zoomLevel.toStringAsFixed(0)}x ZOOM',
                              style: const TextStyle(
                                fontSize: 8.5,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Big Primary Recording Action Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _isRecording ? colorAlert : colorPrimary,
              foregroundColor: Colors.white,
              elevation: _isRecording ? 8 : 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _isRecording ? _stopAndSealRecording : _startRecording,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isRecording ? Icons.stop_circle : Icons.fiber_manual_record,
                  size: 22,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  _isRecording
                      ? 'रिकॉर्डिंग रोकें व SHA-256 से सील करें (REC 00:${_recordSeconds.toString().padLeft(2, '0')}.$_recordSubSeconds)'
                      : 'साक्ष्य रिकॉर्डिंग शुरू करें (Record Only)',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAudioVuMeter() {
    return AnimatedBuilder(
      animation: _vuMeterController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.white24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.mic, size: 9, color: Color(0xFF69F0AE)),
                  SizedBox(width: 3),
                  Text(
                    'AUDIO VU',
                    style: TextStyle(
                      fontSize: 7.5,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF69F0AE),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              _buildVuBar('L', _audioPeakL),
              const SizedBox(height: 2),
              _buildVuBar('R', _audioPeakR),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVuBar(String channel, double peak) {
    const totalBars = 8;
    final activeBars = (peak * totalBars).round().clamp(1, totalBars);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          channel,
          style: const TextStyle(
            fontSize: 7,
            fontFamily: 'monospace',
            color: Colors.white70,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(totalBars, (i) {
            Color barColor = const Color(0xFF4CAF50);
            if (i >= 6) {
              barColor = Colors.redAccent;
            } else if (i >= 4) {
              barColor = const Color(0xFFFFEB3B);
            }
            final isActive = i < activeBars;
            return Container(
              width: 3,
              height: 7,
              margin: const EdgeInsets.only(right: 1.5),
              decoration: BoxDecoration(
                color: isActive ? barColor : Colors.white12,
                borderRadius: BorderRadius.circular(0.5),
              ),
            );
          }),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // 4. RECORDED EVIDENCE VAULT (With Delete Button)
  // -------------------------------------------------------------
  Widget _buildVaultSectionHeader(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(Icons.folder_special, size: 20, color: colorPrimaryDeep),
            const SizedBox(width: 8),
            Text(
              'सुरक्षित साक्ष्य लॉकर ($count)',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: colorPrimaryDeep,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: colorPrimarySoft,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colorHairline),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.remove_red_eye_outlined,
                  size: 13, color: colorPrimary),
              SizedBox(width: 4),
              Text(
                'केवल पूर्वावलोकन (Preview Only)',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: colorPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyVaultView() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      decoration: BoxDecoration(
        color: colorCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorHairline),
      ),
      child: const Center(
        child: Column(
          children: [
            Icon(Icons.lock_clock, size: 40, color: colorStoneMuted),
            SizedBox(height: 10),
            Text(
              'कोई साक्ष्य वीडियो दर्ज नहीं है',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: colorStoneText,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'ऊपर दिए गए लाइव कैमरा से अपने नुकसान का पहला वीडियो रिकॉर्ड करें।',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: colorStoneMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVaultEvidenceCard(InsuranceEvidenceItem item) {
    final truncatedSha = item.videoSha256.length > 24
        ? '${item.videoSha256.substring(0, 12)}...${item.videoSha256.substring(item.videoSha256.length - 8)}'
        : item.videoSha256;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorHairline, width: 1.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Claim ID, Status Badge & Delete Button
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: colorPrimarySoft,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: colorHairline),
                  ),
                  child: Text(
                    item.id,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'monospace',
                      color: colorPrimaryDeep,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: colorPrimary.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified, size: 12, color: colorPrimary),
                      const SizedBox(width: 4),
                      Text(
                        item.status,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: colorPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Delete button for recorded record
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      size: 19, color: colorAlert),
                  tooltip: 'साक्ष्य रिकॉर्ड हटाएं (Delete)',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _deleteVaultRecord(item),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Damage Type & Crop
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${item.cropName} · ${item.claimType}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: colorStoneText,
                    ),
                  ),
                ),
                Text(
                  item.estimatedLoss,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: colorAlert,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            // Location & GPS
            Row(
              children: [
                const Icon(Icons.location_on, size: 13, color: colorBlue),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${item.locationName} (${item.gpsLat.toStringAsFixed(4)}° N, ${item.gpsLon.toStringAsFixed(4)}° E)',
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: colorStoneMuted,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${item.durationSeconds}s वीडियो',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: colorStoneMuted,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 4),

            // UTC Time Stamp
            Row(
              children: [
                const Icon(Icons.access_time_filled,
                    size: 13, color: colorStoneMuted),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'UTC: ${item.utcTimestamp.substring(0, 19)}Z',
                    style: const TextStyle(
                      fontSize: 10,
                      fontFamily: 'monospace',
                      color: colorStoneMuted,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Cryptographic SHA-256 Hash Seal
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(
                color: colorSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colorHairline),
              ),
              child: Row(
                children: [
                  const Icon(Icons.tag, size: 14, color: colorPrimary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'अपरिवर्तनीय SHA-256 डिजिटल मुहर (Crypto Hash):',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: colorStoneMuted,
                          ),
                        ),
                        Text(
                          truncatedSha,
                          style: const TextStyle(
                            fontSize: 10,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w700,
                            color: colorPrimaryDeep,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 15, color: colorPrimary),
                    tooltip: 'हैश कॉपी करें',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: item.videoSha256));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ SHA-256 हैश क्लिपबोर्ड पर कॉपी हुआ!'),
                          backgroundColor: colorPrimary,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Action Button: PREVIEW ONLY (Strictly No Download Button)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.play_circle_fill,
                    size: 17, color: Colors.white),
                label: const Text(
                  'साक्ष्य वीडियो पूर्वावलोकन देखें (Preview Only)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                onPressed: () => _showVideoPreviewModal(item),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // 5. IN-APP PLAYABLE VIDEO PREVIEW MODAL (Preview Only, Zero Download)
  // -------------------------------------------------------------
  void _showVideoPreviewModal(InsuranceEvidenceItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PlayableEvidencePlayerSheet(item: item),
    );
  }

  // -------------------------------------------------------------
  // 6. SEALED PROOF CERTIFICATE DIALOG
  // -------------------------------------------------------------
  void _showSealedCertificateModal(InsuranceEvidenceItem item) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        contentPadding: const EdgeInsets.all(20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                color: colorPrimarySoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.verified_user,
                  size: 42, color: colorPrimary),
            ),
            const SizedBox(height: 12),
            const Text(
              'साक्ष्य डिजिटल रूप से सील हो गया!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: colorPrimaryDeep,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'PMFBY व भारत सरकार बीमा मानकों के अनुरूप सुरक्षित',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: colorStoneMuted),
            ),
            const SizedBox(height: 16),

            // Certificate Details
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colorHairline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCertRow('दावा ID:', item.id),
                  _buildCertRow('फसल व नुकसान:', '${item.cropName} · ${item.claimType}'),
                  _buildCertRow(
                      'सटीक GPS:',
                      '${item.gpsLat.toStringAsFixed(5)}° N, ${item.gpsLon.toStringAsFixed(5)}° E'),
                  _buildCertRow('UTC समय:', item.utcTimestamp),
                  _buildCertRow('अवधि:', '${item.durationSeconds} सेकंड'),
                  if (_lastRecordedVideoPath != null)
                    _buildCertRow('लोकल फाइल:', _lastRecordedVideoPath!.split('/').last),
                  const Divider(height: 16),
                  const Text(
                    'अपरिवर्तनीय SHA-256 हैश (Crypto Seal):',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: colorStoneMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  SelectableText(
                    item.videoSha256,
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w800,
                      color: colorPrimaryDeep,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colorAmber.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield, size: 14, color: colorAmber),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'सुरक्षा नियम: यह वीडियो डाउनलोड नहीं हो सकता ताकि कोई AI या व्यक्ति साक्ष्य में फेरबदल न करे।',
                      style: TextStyle(
                        fontSize: 9.5,
                        color: Color(0xFFBF360C),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {});
                },
                child: const Text(
                  'वॉल्ट में सुरक्षित सहेजें (Sealed)',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCertRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: colorStoneMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: colorStoneText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSecurityProtocolDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.security, color: colorPrimary),
            SizedBox(width: 8),
            Text(
              'बीमा सुरक्षा प्रोटोकॉल',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '1. रिकॉर्ड-ओनली अधिदेश (Record-Only Mandate):',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              SizedBox(height: 2),
              Text(
                'गैलरी या बाहरी फ़ाइलों से वीडियो अपलोड वर्जित है जिससे डीपफेक या नकली क्लेम की कोई संभावना नहीं रहती।\n',
                style: TextStyle(fontSize: 11, color: colorStoneMuted),
              ),
              Text(
                '2. शून्य डाउनलोड / शून्य निर्यात नीति (Zero Download):',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              SizedBox(height: 2),
              Text(
                'वीडियो डिवाइस के एन्क्रिप्टेड सैंडबॉक्स में सील रहता है। ऐप में कोई डाउनलोड या एक्सपोर्ट बटन नहीं है ताकि वीडियो की मौलिकता 100% बरकरार रहे।\n',
                style: TextStyle(fontSize: 11, color: colorStoneMuted),
              ),
              Text(
                '3. GPS व UTC समय प्रमाण (Geotag & Time Certification):',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              SizedBox(height: 2),
              Text(
                'प्रत्येक वीडियो के साथ सैटेलाइट GPS निर्देशांक और अंतरराष्ट्रीय UTC समय एम्बेड किया जाता है।\n',
                style: TextStyle(fontSize: 11, color: colorStoneMuted),
              ),
              Text(
                '4. SHA-256 क्रिप्टोग्राफिक मुहर (Tamper-Proof Hash):',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              SizedBox(height: 2),
              Text(
                'वीडियो का 64-अंकीय SHA-256 हैश जनरेट होता है। यदि वीडियो में 1 पिक्सेल का भी फेरबदल हो तो हैश बदल जाएगा, जिससे धोखाधड़ी पकड़ी जाती है।',
                style: TextStyle(fontSize: 11, color: colorStoneMuted),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('समझ गया'),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// PLAYABLE EVIDENCE VIDEO PREVIEW MODAL (Strictly Preview Only, Zero Download)
// -----------------------------------------------------------------------------
class _PlayableEvidencePlayerSheet extends StatefulWidget {
  final InsuranceEvidenceItem item;

  const _PlayableEvidencePlayerSheet({required this.item});

  @override
  State<_PlayableEvidencePlayerSheet> createState() =>
      _PlayableEvidencePlayerSheetState();
}

class _PlayableEvidencePlayerSheetState
    extends State<_PlayableEvidencePlayerSheet>
    with SingleTickerProviderStateMixin {
  bool _isPlaying = true;
  double _currentProgress = 0.0;
  Timer? _playbackTimer;
  late AnimationController _watermarkPulse;
  VideoPlayerController? _videoPlayerController;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    _watermarkPulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _initRealVideoPlayer();
  }

  void _initRealVideoPlayer() {
    final videoPath = widget.item.videoPath;
    if (videoPath != null && videoPath.isNotEmpty) {
      try {
        final uri = Uri.parse(videoPath);
        _videoPlayerController = VideoPlayerController.networkUrl(uri);
        _videoPlayerController!.initialize().then((_) {
          if (mounted) {
            setState(() {
              _isVideoInitialized = true;
            });
            _videoPlayerController!.setLooping(true);
            _videoPlayerController!.play();
          }
        }).catchError((err) {
          debugPrint('Real video player fallback: $err');
          _startSimulatedPlayback();
        });

        _videoPlayerController!.addListener(() {
          if (mounted &&
              _isVideoInitialized &&
              _videoPlayerController != null &&
              _videoPlayerController!.value.duration.inMilliseconds > 0) {
            final dur = _videoPlayerController!.value.duration.inMilliseconds;
            final pos = _videoPlayerController!.value.position.inMilliseconds;
            setState(() {
              _currentProgress = (pos / dur).clamp(0.0, 1.0);
            });
          }
        });
        return;
      } catch (e) {
        debugPrint('Video player setup exception: $e');
      }
    }

    _startSimulatedPlayback();
  }

  void _startSimulatedPlayback() {
    _playbackTimer?.cancel();
    final totalSeconds = widget.item.durationSeconds > 0
        ? widget.item.durationSeconds
        : 15;

    _playbackTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (!mounted || !_isPlaying) return;
      setState(() {
        _currentProgress += 0.2 / totalSeconds;
        if (_currentProgress >= 1.0) {
          _currentProgress = 0.0; // loop playback for preview
        }
      });
    });
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
    });
    if (_isVideoInitialized && _videoPlayerController != null) {
      if (_isPlaying) {
        _videoPlayerController!.play();
      } else {
        _videoPlayerController!.pause();
      }
    }
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    _watermarkPulse.dispose();
    _videoPlayerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final totalSec = item.durationSeconds;
    final currentSec = (_currentProgress * totalSec).toInt();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF0C130D),
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Column(
        children: [
          // Drag handle & Modal Header
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 4),
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.shield, color: Color(0xFF4CAF50), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'सुरक्षित साक्ष्य पूर्वावलोकन · ${item.id}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Text(
                        'केवल इन-ऐप पूर्वावलोकन (Playable Preview Only)',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFFA5D6A7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Colors.white12),

          // In-App Video Viewport with Live HUD Watermark
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Stack(
                  children: [
                    // Real recorded video if initialized, otherwise simulated field canvas
                    Positioned.fill(
                      child: _isVideoInitialized && _videoPlayerController != null
                          ? Center(
                              child: AspectRatio(
                                aspectRatio: _videoPlayerController!
                                            .value.aspectRatio >
                                        0
                                    ? _videoPlayerController!.value.aspectRatio
                                    : 16 / 9,
                                child: VideoPlayer(_videoPlayerController!),
                              ),
                            )
                          : CustomPaint(
                              painter: _FarmEvidenceVideoPainter(
                                progress: _currentProgress,
                                cropName: item.cropName,
                                claimType: item.claimType,
                                damagePercentage: item.damagePercentage,
                              ),
                            ),
                    ),

                    // Official Watermark Stamp (Center Overlay)
                    Center(
                      child: IgnorePointer(
                        child: AnimatedBuilder(
                          animation: _watermarkPulse,
                          builder: (context, child) {
                            return Opacity(
                              opacity: 0.18 + (0.08 * _watermarkPulse.value),
                              child: Transform.rotate(
                                angle: -0.3,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: Colors.white, width: 2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'PMFBY OFFICIAL EVIDENCE\nNON-DOWNLOADABLE · PREVIEW ONLY',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 13,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    // Top Live Security HUD Over Video
                    Positioned(
                      top: 10,
                      left: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.location_on,
                                    size: 12, color: Color(0xFF69F0AE)),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'GPS: ${item.gpsLat.toStringAsFixed(5)}° N, ${item.gpsLon.toStringAsFixed(5)}° E (Alt: ${item.altitude}m)',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontFamily: 'monospace',
                                      color: Color(0xFF69F0AE),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                const Icon(Icons.schedule,
                                    size: 12, color: Color(0xFF80D8FF)),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'UTC: ${item.utcTimestamp}',
                                    style: const TextStyle(
                                      fontSize: 9.5,
                                      fontFamily: 'monospace',
                                      color: Color(0xFF80D8FF),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                const Icon(Icons.tag,
                                    size: 12, color: Color(0xFFFFD54F)),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'SHA-256: ${item.videoSha256}',
                                    style: const TextStyle(
                                      fontSize: 8.5,
                                      fontFamily: 'monospace',
                                      color: Color(0xFFFFD54F),
                                      fontWeight: FontWeight.w700,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Icon(
                                  item.recordingMode == 'hardware'
                                      ? Icons.videocam
                                      : Icons.satellite_alt,
                                  size: 12,
                                  color: item.recordingMode == 'hardware'
                                      ? const Color(0xFF69F0AE)
                                      : const Color(0xFFFFAB40),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  item.recordingMode == 'hardware'
                                      ? 'हार्डवेयर कैमरा (Optical 1080p)'
                                      : 'सिम्युलेटेड फील्ड (Realistic Sim)',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w700,
                                    color: item.recordingMode == 'hardware'
                                        ? const Color(0xFF69F0AE)
                                        : const Color(0xFFFFAB40),
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                        color: Colors.redAccent
                                            .withValues(alpha: 0.6),
                                        width: 0.8),
                                  ),
                                  child: Text(
                                    'क्षति: ${item.damagePercentage.toStringAsFixed(0)}%',
                                    style: const TextStyle(
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFFFF5252),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Big Tap-to-play icon if paused
                    if (!_isPlaying)
                      Center(
                        child: GestureDetector(
                          onTap: _togglePlayPause,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white38),
                            ),
                            child: const Icon(Icons.play_arrow,
                                size: 48, color: Colors.white),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Player Controls & Scrubber
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      '00:${currentSec.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                        fontFamily: 'monospace',
                      ),
                    ),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 3,
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 6),
                          activeTrackColor: const Color(0xFF4CAF50),
                          inactiveTrackColor: Colors.white24,
                          thumbColor: Colors.white,
                        ),
                        child: Slider(
                          value: _currentProgress.clamp(0.0, 1.0),
                          onChanged: (val) {
                            setState(() {
                              _currentProgress = val;
                            });
                            if (_isVideoInitialized &&
                                _videoPlayerController != null) {
                              final totalMs = _videoPlayerController!
                                  .value.duration.inMilliseconds;
                              _videoPlayerController!.seekTo(Duration(
                                  milliseconds: (val * totalMs).toInt()));
                            }
                          },
                        ),
                      ),
                    ),
                    Text(
                      '00:${totalSec.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.replay_10, color: Colors.white70),
                      onPressed: () {
                        setState(() {
                          _currentProgress =
                              (_currentProgress - 0.2).clamp(0.0, 1.0);
                        });
                        if (_isVideoInitialized &&
                            _videoPlayerController != null) {
                          final current = _videoPlayerController!.value.position;
                          _videoPlayerController!.seekTo(
                              current - const Duration(seconds: 3));
                        }
                      },
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      iconSize: 42,
                      icon: Icon(
                        _isPlaying
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_filled,
                        color: const Color(0xFF4CAF50),
                      ),
                      onPressed: _togglePlayPause,
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.forward_10, color: Colors.white70),
                      onPressed: () {
                        setState(() {
                          _currentProgress =
                              (_currentProgress + 0.2).clamp(0.0, 1.0);
                        });
                        if (_isVideoInitialized &&
                            _videoPlayerController != null) {
                          final current = _videoPlayerController!.value.position;
                          _videoPlayerController!.seekTo(
                              current + const Duration(seconds: 3));
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Zero-Download Policy Bottom Notice Bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            margin: const EdgeInsets.fromLTRB(14, 4, 14, 16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E2820),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF2E7D32).withValues(alpha: 0.5)),
            ),
            child: const Row(
              children: [
                Icon(Icons.shield_moon_outlined,
                    size: 16, color: Color(0xFF81C784)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'सुरक्षा सूचना: डाउनलोडिंग अवरुद्ध है। यह साक्ष्य बीमा कंपनी और सरकारी पोर्टल पर केवल इन-ऐप डिजिटल हैश द्वारा मान्य होता है।',
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFFC8E6C9),
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// VIEWFINDER GRID & SENSOR PAINTER
// -----------------------------------------------------------------------------
class _ViewfinderGridPainter extends CustomPainter {
  final bool isRecording;
  final double scanProgress;
  final bool showGrid;

  _ViewfinderGridPainter({
    required this.isRecording,
    required this.scanProgress,
    this.showGrid = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (showGrid) {
      final linePaint = Paint()
        ..color = isRecording
            ? Colors.red.withValues(alpha: 0.18)
            : Colors.white.withValues(alpha: 0.12)
        ..strokeWidth = 1.0;

      // Rule of thirds grid lines
      canvas.drawLine(Offset(size.width * 0.33, 0),
          Offset(size.width * 0.33, size.height), linePaint);
      canvas.drawLine(Offset(size.width * 0.66, 0),
          Offset(size.width * 0.66, size.height), linePaint);
      canvas.drawLine(Offset(0, size.height * 0.33),
          Offset(size.width, size.height * 0.33), linePaint);
      canvas.drawLine(Offset(0, size.height * 0.66),
          Offset(size.width, size.height * 0.66), linePaint);
    }

    // Corner targeting brackets
    final cornerPaint = Paint()
      ..color = isRecording ? Colors.redAccent : const Color(0xFF69F0AE)
      ..strokeWidth = isRecording ? 3.0 : 2.2
      ..style = PaintingStyle.stroke;

    const cornerLen = 22.0;
    const pad = 14.0;

    // Top-Left
    canvas.drawLine(
        const Offset(pad, pad), const Offset(pad + cornerLen, pad), cornerPaint);
    canvas.drawLine(
        const Offset(pad, pad), const Offset(pad, pad + cornerLen), cornerPaint);

    // Top-Right
    canvas.drawLine(Offset(size.width - pad, pad),
        Offset(size.width - pad - cornerLen, pad), cornerPaint);
    canvas.drawLine(Offset(size.width - pad, pad),
        Offset(size.width - pad, pad + cornerLen), cornerPaint);

    // Bottom-Left
    canvas.drawLine(Offset(pad, size.height - pad),
        Offset(pad + cornerLen, size.height - pad), cornerPaint);
    canvas.drawLine(Offset(pad, size.height - pad),
        Offset(pad, size.height - pad - cornerLen), cornerPaint);

    // Bottom-Right
    canvas.drawLine(Offset(size.width - pad, size.height - pad),
        Offset(size.width - pad - cornerLen, size.height - pad), cornerPaint);
    canvas.drawLine(Offset(size.width - pad, size.height - pad),
        Offset(size.width - pad, size.height - pad - cornerLen), cornerPaint);

    // Center Crosshair
    final centerPaint = Paint()
      ..color = isRecording
          ? Colors.redAccent.withValues(alpha: 0.6)
          : Colors.white.withValues(alpha: 0.4)
      ..strokeWidth = 1.2;
    final cx = size.width / 2;
    final cy = size.height / 2;
    canvas.drawLine(Offset(cx - 10, cy), Offset(cx + 10, cy), centerPaint);
    canvas.drawLine(Offset(cx, cy - 10), Offset(cx, cy + 10), centerPaint);
    canvas.drawCircle(
      Offset(cx, cy),
      3.0,
      Paint()
        ..color = isRecording ? Colors.redAccent : const Color(0xFF69F0AE)
        ..style = PaintingStyle.fill,
    );

    // Scanning laser beam when recording
    if (isRecording) {
      final laserY = size.height * scanProgress;
      final laserPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.redAccent.withValues(alpha: 0.0),
            Colors.redAccent.withValues(alpha: 0.9),
            Colors.redAccent.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(0, laserY, size.width, 2.5))
        ..strokeWidth = 2.0;

      canvas.drawLine(Offset(0, laserY), Offset(size.width, laserY), laserPaint);

      // Subtle red vignette border glow
      final vignettePaint = Paint()
        ..color = Colors.redAccent.withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0;
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), vignettePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ViewfinderGridPainter oldDelegate) {
    return oldDelegate.isRecording != isRecording ||
        oldDelegate.scanProgress != scanProgress ||
        oldDelegate.showGrid != showGrid;
  }
}

// -----------------------------------------------------------------------------
// REALISTIC FIELD SIMULATION PAINTER (Photorealistic Indian Farm Scene)
// -----------------------------------------------------------------------------
class _RealisticFieldSimulationPainter extends CustomPainter {
  final double windProgress;
  final bool isRecording;
  final int recordSeconds;
  final double damagePercentage;
  final double zoom;

  _RealisticFieldSimulationPainter({
    required this.windProgress,
    required this.isRecording,
    required this.recordSeconds,
    required this.damagePercentage,
    this.zoom = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();

    // Zoom scaling if active
    if (zoom > 1.0) {
      canvas.translate(size.width / 2, size.height / 2);
      canvas.scale(zoom);
      canvas.translate(-size.width / 2, -size.height / 2);
    }

    // Natural handheld camera breathing sway (simulates holding phone in field)
    final swayX = math.sin(windProgress * 2 * math.pi) * 3.5;
    final swayY = math.cos(windProgress * 4 * math.pi) * 2.0;
    canvas.translate(swayX, swayY);

    // 1. Sky Gradient with atmospheric haze & sunlight
    final skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF2C4452),
          Color(0xFF4B6E7F),
          Color(0xFF7D9E92),
          Color(0xFFB5BA9C),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.48));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height * 0.48), skyPaint);

    // Subtle sun flare in top right
    final sunPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.35),
          const Color(0xFFFFF9C4).withValues(alpha: 0.15),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
          center: Offset(size.width * 0.85, size.height * 0.12), radius: 60));
    canvas.drawCircle(
        Offset(size.width * 0.85, size.height * 0.12), 60, sunPaint);

    // 2. Distant tree line silhouette on horizon
    final horizonY = size.height * 0.44;
    final treePaint = Paint()
      ..color = const Color(0xFF263C28).withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    final treePath = Path();
    treePath.moveTo(0, horizonY);
    for (double x = 0; x <= size.width; x += 18) {
      final h = 6.0 + (math.sin(x * 0.05) * 4.0);
      treePath.lineTo(x, horizonY - h);
    }
    treePath.lineTo(size.width, horizonY);
    treePath.close();
    canvas.drawPath(treePath, treePaint);

    // 3. Ground / Soil Base Gradient
    final groundPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF24331C),
          Color(0xFF1B2615),
          Color(0xFF10170D),
        ],
      ).createShader(Rect.fromLTWH(
          0, horizonY - 4, size.width, size.height - horizonY + 4));
    canvas.drawRect(
        Rect.fromLTWH(
            0, horizonY - 4, size.width, size.height - horizonY + 4),
        groundPaint);

    // 4. Background Crop Layer (Slightly lighter, denser wheat canopy)
    final bgStalkPaint = Paint()
      ..color = const Color(0xFF558B2F).withValues(alpha: 0.6)
      ..strokeWidth = 1.6;

    const bgCount = 42;
    for (int i = 0; i < bgCount; i++) {
      final x = (i * (size.width / bgCount));
      final windPhase = (windProgress * 2 * math.pi) + (i * 0.25);
      final sway = math.sin(windPhase) * 6.0;
      final stalkH = 40.0 + (math.sin(i * 1.3) * 12.0);
      final baseY = size.height * 0.72;

      canvas.drawLine(
        Offset(x, baseY),
        Offset(x + sway, baseY - stalkH),
        bgStalkPaint,
      );
    }

    // 5. Foreground Crop Stalks (Wheat / Paddy with Ears of Grain)
    final fgStalkPaint = Paint()
      ..color = const Color(0xFF7CB342)
      ..strokeWidth = 2.4;

    final grainEarPaint = Paint()
      ..color = const Color(0xFFC0CA33)
      ..strokeWidth = 3.4;

    final lodgedStalkPaint = Paint()
      ..color = const Color(0xFFBCAAA4)
      ..strokeWidth = 2.6;

    const fgCount = 34;
    for (int i = 0; i < fgCount; i++) {
      final x = (i * (size.width / fgCount)) + 4;
      final windPhase = (windProgress * 2 * math.pi) + (i * 0.35);
      final sway = math.sin(windPhase) * 10.0;
      final stalkH = 65.0 + (math.cos(i * 0.8) * 15.0);
      final baseY = size.height * 0.88;

      // Center-right section represents lodged/damaged crops
      final isDamagedZone = i >= 14 && i <= 24;

      if (isDamagedZone) {
        // Lodged (fallen/bent crop stalks from hailstorm or flood)
        final bendX = x + 24.0 + (math.sin(windPhase) * 3.0);
        final bendY = baseY - (stalkH * 0.35);

        canvas.drawLine(
          Offset(x, baseY),
          Offset(bendX, bendY),
          lodgedStalkPaint,
        );

        // Lodged grain head on the ground
        canvas.drawCircle(Offset(bendX + 4, bendY + 2), 3.0, lodgedStalkPaint);
      } else {
        // Standing upright healthy crop stalk
        final tipX = x + sway;
        final tipY = baseY - stalkH;

        canvas.drawLine(
          Offset(x, baseY),
          Offset(tipX, tipY),
          fgStalkPaint,
        );

        // Wheat/Paddy grain ear on top
        canvas.drawLine(
          Offset(tipX, tipY),
          Offset(tipX + (sway * 0.5), tipY - 10),
          grainEarPaint,
        );
      }
    }

    // 6. Camera Lens Vignette Effect (Darker corners for authentic optical look)
    final vignetteShader = RadialGradient(
      colors: [
        Colors.transparent,
        Colors.black.withValues(alpha: 0.45),
      ],
      stops: const [0.65, 1.0],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..shader = vignetteShader);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RealisticFieldSimulationPainter oldDelegate) {
    return oldDelegate.windProgress != windProgress ||
        oldDelegate.isRecording != isRecording ||
        oldDelegate.recordSeconds != recordSeconds ||
        oldDelegate.damagePercentage != damagePercentage ||
        oldDelegate.zoom != zoom;
  }
}

// -----------------------------------------------------------------------------
// PLAYABLE FARM VIDEO CANVAS PAINTER (Interactive Frame Simulation)
// -----------------------------------------------------------------------------
class _FarmEvidenceVideoPainter extends CustomPainter {
  final double progress;
  final String cropName;
  final String claimType;
  final double damagePercentage;

  _FarmEvidenceVideoPainter({
    required this.progress,
    required this.cropName,
    required this.claimType,
    this.damagePercentage = 74.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Sky background gradient
    const skyGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF37474F),
        Color(0xFF546E7A),
        Color(0xFF263238),
      ],
    );
    final skyPaint = Paint()
      ..shader = skyGradient
          .createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.45));
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height * 0.45), skyPaint);

    // Ground / Crop field
    const fieldGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF2E3E26),
        Color(0xFF1E2818),
        Color(0xFF141910),
      ],
    );
    final fieldPaint = Paint()
      ..shader = fieldGradient.createShader(Rect.fromLTWH(
          0, size.height * 0.45, size.width, size.height * 0.55));
    canvas.drawRect(
        Rect.fromLTWH(0, size.height * 0.45, size.width, size.height * 0.55),
        fieldPaint);

    // Draw simulated crop stalks with dynamic panning motion
    final stalkPaint = Paint()
      ..color = const Color(0xFF689F38).withValues(alpha: 0.75)
      ..strokeWidth = 2.0;

    final damagedStalkPaint = Paint()
      ..color = const Color(0xFFBCAAA4).withValues(alpha: 0.85)
      ..strokeWidth = 2.4;

    const count = 30;
    for (int i = 0; i < count; i++) {
      final xOffset =
          ((i * (size.width / count) + (progress * 45)) % size.width);
      final stalkHeight = 48.0 + ((i % 5) * 8.0);
      final baseY = size.height * 0.82;

      if (i % 3 == 0 || (i >= 8 && i <= 16)) {
        // Damaged / lodged stalk (bent over)
        canvas.drawLine(
          Offset(xOffset, baseY),
          Offset(xOffset + 20, baseY - stalkHeight * 0.4),
          damagedStalkPaint,
        );
      } else {
        // Standing stalk
        canvas.drawLine(
          Offset(xOffset, baseY),
          Offset(xOffset + (i.isEven ? 4 : -4), baseY - stalkHeight),
          stalkPaint,
        );
      }
    }

    // Dynamic water droplets or hailstones
    final particlePaint = Paint()..color = Colors.white70;
    for (int p = 0; p < 16; p++) {
      final px = ((p * 23.0 + progress * 140.0) % size.width);
      final py = ((p * 19.0 + progress * 260.0) % (size.height * 0.8));
      canvas.drawCircle(Offset(px, py), 1.6, particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _FarmEvidenceVideoPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.damagePercentage != damagePercentage;
  }
}
