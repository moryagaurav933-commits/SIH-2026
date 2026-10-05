import 'dart:io' show Process;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

/// Unified Hardware Device Permission Service for Krishi-Saarthi OS.
/// Bridges native Apple AVFoundation on macOS desktop, and permission_handler + geolocator
/// on Android, iOS, and Web.
class DevicePermissionService {
  static const MethodChannel _macChannel =
      MethodChannel('krishi_saarthi/permissions');

  static bool get isMacOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;

  /// Check Camera Permission
  static Future<bool> checkCamera() async {
    if (isMacOS) {
      try {
        final bool? res = await _macChannel.invokeMethod<bool>('checkCamera');
        if (res != null) return res;
      } catch (e) {
        debugPrint('macOS native checkCamera error: $e');
      }
    }
    try {
      final status = await Permission.camera.status;
      return status.isGranted;
    } catch (_) {
      return false;
    }
  }

  /// Request Camera Permission
  static Future<bool> requestCamera() async {
    if (isMacOS) {
      try {
        final bool? res =
            await _macChannel.invokeMethod<bool>('requestCamera');
        if (res != null) return res;
      } catch (e) {
        debugPrint('macOS native requestCamera error: $e');
      }
    }
    try {
      final status = await Permission.camera.request();
      return status.isGranted;
    } catch (_) {
      return false;
    }
  }

  /// Check Microphone Permission
  static Future<bool> checkMicrophone() async {
    if (isMacOS) {
      try {
        final bool? res =
            await _macChannel.invokeMethod<bool>('checkMicrophone');
        if (res != null) return res;
      } catch (e) {
        debugPrint('macOS native checkMicrophone error: $e');
      }
    }
    try {
      final status = await Permission.microphone.status;
      return status.isGranted;
    } catch (_) {
      return false;
    }
  }

  /// Request Microphone Permission
  static Future<bool> requestMicrophone() async {
    if (isMacOS) {
      try {
        final bool? res =
            await _macChannel.invokeMethod<bool>('requestMicrophone');
        if (res != null) return res;
      } catch (e) {
        debugPrint('macOS native requestMicrophone error: $e');
      }
    }
    try {
      final status = await Permission.microphone.request();
      return status.isGranted;
    } catch (_) {
      return false;
    }
  }

  /// Check Location Permission
  static Future<bool> checkLocation() async {
    try {
      final loc = await Geolocator.checkPermission();
      return (loc == LocationPermission.whileInUse ||
          loc == LocationPermission.always);
    } catch (_) {
      return false;
    }
  }

  /// Request Location Permission
  static Future<bool> requestLocation() async {
    try {
      LocationPermission loc = await Geolocator.checkPermission();
      if (loc == LocationPermission.denied) {
        loc = await Geolocator.requestPermission();
      }
      return (loc == LocationPermission.whileInUse ||
          loc == LocationPermission.always);
    } catch (_) {
      return false;
    }
  }

  /// Check if all hardware permissions are granted
  static Future<bool> areAllGranted() async {
    final cam = await checkCamera();
    final mic = await checkMicrophone();
    final loc = await checkLocation();
    return cam && mic && loc;
  }

  /// Request all permissions sequentially
  static Future<Map<String, bool>> requestAll() async {
    final cam = await requestCamera();
    final mic = await requestMicrophone();
    final loc = await requestLocation();
    return {
      'camera': cam,
      'microphone': mic,
      'location': loc,
    };
  }

  /// Open System Settings (reliable across macOS System Settings and mobile platforms)
  static Future<bool> openSettings() async {
    if (isMacOS) {
      try {
        final bool? res =
            await _macChannel.invokeMethod<bool>('openSettings');
        if (res == true) return true;
      } catch (_) {}

      try {
        final res = await Process.run('open', [
          'x-apple.systempreferences:com.apple.preference.security?Privacy'
        ]);
        if (res.exitCode == 0) return true;
      } catch (_) {}

      try {
        final uri = Uri.parse(
            'x-apple.systempreferences:com.apple.preference.security?Privacy');
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
          return true;
        }
      } catch (_) {}

      try {
        final res = await Process.run('open', ['-a', 'System Settings']);
        if (res.exitCode == 0) return true;
      } catch (_) {}
    }

    try {
      return await openAppSettings();
    } catch (_) {
      return false;
    }
  }
}
