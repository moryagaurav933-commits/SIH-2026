import 'package:flutter/foundation.dart';

/// Global API & Network Configuration for Krishi-Saarthi.
/// Ensures mobile devices, desktop runners, web browsers, and emulators
/// all connect smoothly to the unified FastAPI backend.
class ApiConfig {
  static String? _customBaseUrl;

  static void setCustomBaseUrl(String url) {
    _customBaseUrl = url.trim();
  }

  static String get baseUrl {
    if (_customBaseUrl != null && _customBaseUrl!.isNotEmpty) {
      return _customBaseUrl!;
    }
    // Web: Connect directly to current host / localhost on port 8000
    if (kIsWeb) {
      return 'http://localhost:8000/api/v1';
    }
    // Android Emulator
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000/api/v1';
    }
    // iOS Simulator, macOS, Windows, Linux
    return 'http://localhost:8000/api/v1';
  }

  // AI & Agronomy Endpoints
  static String get aiBaseUrl => '$baseUrl/ai';
  static String get chatUrl => '$baseUrl/ai/chat';
  static String get diagnoseUrl => '$baseUrl/ai/diagnose';
  static String get diagnoseEndpoint => '$baseUrl/diagnose';
  static String get keyStatusUrl => '$baseUrl/ai/key-status';
  static String get configureKeyUrl => '$baseUrl/ai/configure-key';

  // Core Service Endpoints
  static String get diagnosesUrl => '$baseUrl/diagnoses/';
  static String get weatherForecastUrl => '$baseUrl/weather/forecast';
  static String get mandiPricesUrl => '$baseUrl/mandi/prices';
  static String get mandisUrl => '$baseUrl/mandi/mandis';
  static String get closestMandiUrl => '$baseUrl/mandi/closest';
  static String get dashboardStatsUrl => '$baseUrl/dashboard/stats';
  static String get fertilizerVerifyUrl => '$baseUrl/fertilizer/verify';
  static String get insuranceClaimsUrl => '$baseUrl/insurance/claims';
}
