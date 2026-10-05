import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:camera_macos/camera_macos.dart' as macos_cam;
import 'package:image_picker/image_picker.dart';
import '../../services/device_permission_service.dart';

/// Interactive Live Camera Module Sheet for Krishi Copilot.
/// Provides live viewfinder, hardware camera switching, shutter snap,
/// and fallback to gallery / sample photo.
class CameraCaptureSheet extends StatefulWidget {
  const CameraCaptureSheet({super.key});

  @override
  State<CameraCaptureSheet> createState() => _CameraCaptureSheetState();
}

class _CameraCaptureSheetState extends State<CameraCaptureSheet> {
  CameraController? _controller;
  macos_cam.CameraMacOSController? _macController;
  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = 0;
  bool _isInitializing = true;
  String? _errorMessage;
  FlashMode _flashMode = FlashMode.auto;

  Uint8List? _capturedBytes;
  bool _isCapturing = false;

  bool get _isMacOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    setState(() {
      _isInitializing = true;
      _errorMessage = null;
    });

    try {
      // Proactively request camera permission across mobile and desktop
      final granted = await DevicePermissionService.requestCamera();
      if (!granted) {
        if (mounted) {
          setState(() {
            _isInitializing = false;
            _errorMessage = 'कैमरा अनुमति अस्वीकृत है। कृपया सेटिंग्स में अनुमति दें या फाइल से फोटो चुनें।';
          });
        }
        return;
      }

      // On macOS desktop, CameraMacOSView handles its own native AVFoundation initialization
      if (_isMacOS) {
        if (mounted) {
          setState(() {
            _isInitializing = false;
            _errorMessage = null;
          });
        }
        return;
      }

      final cameras = await availableCameras();
      _cameras = cameras;

      if (cameras.isEmpty) {
        if (mounted) {
          setState(() {
            _isInitializing = false;
            _errorMessage = 'कोई सक्रिय कैमरा नहीं मिला। कृपया गैलरी से फोटो चुनें।';
          });
        }
        return;
      }

      if (_selectedCameraIndex >= cameras.length) {
        _selectedCameraIndex = 0;
      }

      final cam = cameras[_selectedCameraIndex];
      await _controller?.dispose();

      final controller = CameraController(
        cam,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await controller.initialize();

      if (mounted) {
        setState(() {
          _controller = controller;
          _isInitializing = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      debugPrint('Camera initialization error: $e');
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _errorMessage = 'कैमरा शुरू करने में त्रुटि: $e';
        });
      }
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length <= 1) return;
    setState(() {
      _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    });
    await _initializeCamera();
  }

  Future<void> _toggleFlash() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    try {
      FlashMode nextMode;
      if (_flashMode == FlashMode.auto) {
        nextMode = FlashMode.always;
      } else if (_flashMode == FlashMode.always) {
        nextMode = FlashMode.off;
      } else {
        nextMode = FlashMode.auto;
      }
      await _controller!.setFlashMode(nextMode);
      setState(() {
        _flashMode = nextMode;
      });
    } catch (_) {}
  }

  Future<void> _takePhoto() async {
    if (_isCapturing) return;

    if (_isMacOS) {
      if (_macController == null) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('कैमरा शुरू हो रहा है, कृपया 1 सेकंड प्रतीक्षा करें...'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        return;
      }
      setState(() => _isCapturing = true);
      try {
        final macos_cam.CameraMacOSFile? photo = await _macController!.takePicture();
        if (photo?.bytes != null && mounted) {
          setState(() {
            _capturedBytes = photo!.bytes;
            _isCapturing = false;
          });
          return;
        } else {
          throw Exception('तस्वीर डेटा प्राप्त नहीं हुआ');
        }
      } catch (e) {
        debugPrint('macOS takePicture error: $e');
        if (mounted) {
          setState(() => _isCapturing = false);
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('तस्वीर खींचने में त्रुटि: $e'),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
        return;
      }
    }

    if (_controller == null || !_controller!.value.isInitialized) return;

    setState(() => _isCapturing = true);

    try {
      final XFile photo = await _controller!.takePicture();
      final bytes = await photo.readAsBytes();
      if (mounted) {
        setState(() {
          _capturedBytes = bytes;
          _isCapturing = false;
        });
      }
    } catch (e) {
      debugPrint('Error taking picture: $e');
      if (mounted) {
        setState(() => _isCapturing = false);
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('तस्वीर खींचने में त्रुटि: $e'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 85,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        if (mounted) {
          Navigator.pop(context, bytes);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('गैलरी से चयन में त्रुटि: $e'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  void _useSampleLeaf() {
    Navigator.pop(context, Uint8List.fromList([
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
      0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
      0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
      0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
      0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
      0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
      0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
      0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
      0x42, 0x60, 0x82
    ]));
  }

  @override
  void dispose() {
    _controller?.dispose();
    _macController?.destroy();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Container(
      constraints: BoxConstraints(
        maxHeight: size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF0C1A10),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 12, 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E4620),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF4ADE80), width: 1),
                    ),
                    child: const Icon(Icons.camera_alt_rounded,
                        color: Color(0xFF4ADE80), size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'कैमरा मॉड्यूल (Live Camera)',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'फसल या पत्ती की तस्वीर लें',
                          style: TextStyle(
                            color: Color(0xFFA5D6A7),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            const Divider(color: Colors.white12, height: 1),

            // Viewfinder / Preview Body
            Expanded(
              child: _buildCameraBody(),
            ),

            // Bottom Action Controls
            _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraBody() {
    // 1. Photo snapped preview state
    if (_capturedBytes != null) {
      return Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF4ADE80), width: 2),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          alignment: Alignment.center,
          fit: StackFit.expand,
          children: [
            Image.memory(_capturedBytes!, fit: BoxFit.cover),
            Positioned(
              top: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '📷 तस्वीर ली गई • क्या यह स्पष्ट है?',
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // 2. Initializing loader
    if (_isInitializing) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFF4ADE80)),
            SizedBox(height: 16),
            Text(
              'कैमरा सक्रिय किया जा रहा है...',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      );
    }

    // 3. Error or No Camera Available
    if (_errorMessage != null ||
        (!_isMacOS && (_controller == null || !_controller!.value.isInitialized))) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.videocam_off_rounded,
                color: Colors.orangeAccent,
                size: 48,
              ),
              const SizedBox(height: 14),
              Text(
                _errorMessage ?? 'हार्डवेयर कैमरा उपलब्ध नहीं है या अनुमति नहीं मिली।',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _pickFromGallery,
                icon: const Icon(Icons.photo_library_rounded, color: Colors.white),
                label: const Text('गैलरी / फाइल से फोटो चुनें'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: _useSampleLeaf,
                icon: const Icon(Icons.eco_rounded, color: Color(0xFF81C784), size: 18),
                label: const Text(
                  'सैंपल पत्ती फोटो से टेस्ट करें',
                  style: TextStyle(color: Color(0xFF81C784), fontSize: 12),
                ),
              ),
              const SizedBox(height: 6),
              OutlinedButton.icon(
                onPressed: () => DevicePermissionService.openSettings(),
                icon: const Icon(Icons.settings_rounded, size: 16, color: Color(0xFF81C784)),
                label: const Text(
                  'सिस्टम सेटिंग्स खोलें (Open Settings)',
                  style: TextStyle(color: Color(0xFF81C784), fontSize: 12),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF2E7D32)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 4. Live Camera Preview with Viewfinder Overlay
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_isMacOS)
            macos_cam.CameraMacOSView(
              fit: BoxFit.cover,
              cameraMode: macos_cam.CameraMacOSMode.photo,
              onCameraInizialized: (ctrl) {
                _macController = ctrl;
                if (mounted) setState(() {});
              },
              onCameraLoading: (_) => const Center(
                child: CircularProgressIndicator(color: Color(0xFF4ADE80)),
              ),
              onCameraDestroyed: () => Container(color: Colors.black),
            )
          else
            CameraPreview(_controller!),

          // Framing Guides (Corner Brackets)
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF4ADE80).withValues(alpha: 0.6), width: 2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 10,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'पत्ती को यहाँ केन्द्रित करें',
                          style: TextStyle(color: Color(0xFF86EFAC), fontSize: 11),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Top Camera Controls (Flash + Switch)
          Positioned(
            top: 12,
            right: 12,
            child: Row(
              children: [
                if (!_isMacOS) ...[
                  // Flash toggle
                  IconButton(
                    icon: Icon(
                      _flashMode == FlashMode.always
                          ? Icons.flash_on_rounded
                          : _flashMode == FlashMode.off
                              ? Icons.flash_off_rounded
                              : Icons.flash_auto_rounded,
                      color: Colors.white,
                    ),
                    onPressed: _toggleFlash,
                  ),
                  // Camera switch
                  if (_cameras.length > 1)
                    IconButton(
                      icon: const Icon(Icons.flip_camera_ios_rounded, color: Colors.white),
                      onPressed: _switchCamera,
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    // If captured photo preview is showing
    if (_capturedBytes != null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() => _capturedBytes = null);
                },
                icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
                label: const Text('पुनः लें (Retake)', style: TextStyle(color: Colors.white)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context, _capturedBytes);
                },
                icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
                label: const Text('उपयोग करें', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Shutter Controls
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Gallery pick button
          IconButton(
            icon: const Icon(Icons.photo_library_rounded, color: Color(0xFFA5D6A7), size: 28),
            tooltip: 'गैलरी से फोटो चुनें',
            onPressed: _pickFromGallery,
          ),

          // Main Shutter Button
          GestureDetector(
            onTap: _takePhoto,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF4ADE80), width: 4),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4ADE80).withValues(alpha: 0.45),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: _isCapturing
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF2E7D32)),
                      )
                    : Container(
                        width: 54,
                        height: 54,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF2E7D32),
                        ),
                        child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 28),
                      ),
              ),
            ),
          ),

          // Close button
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 28),
            tooltip: 'बंद करें',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
