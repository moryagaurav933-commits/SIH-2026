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
    // Web requests: When hosted on Vercel or any public domain, route API calls
    // through the same-origin reverse proxy to prevent Mixed-Content (HTTPS/HTTP) blocks.
    if (kIsWeb) {
      if (!Uri.base.host.contains('localhost') && !Uri.base.host.contains('127.0.0.1')) {
        return Uri.base.resolve('/api/v1').toString().replaceAll(RegExp(r'/+$'), '');
      }
      if (Uri.base.port == 8080) {
        return Uri.base.resolve('/api/v1').toString().replaceAll(RegExp(r'/+$'), '');
      }
      return 'http://127.0.0.1:8000/api/v1';
    }
    // Android Emulator
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000/api/v1';
    }
    // iOS Simulator, macOS, Windows, Linux
    return 'http://127.0.0.1:8000/api/v1';
  }

  // AI & Agronomy Endpoints
  static String get aiBaseUrl => '$baseUrl/ai';
  static String get chatUrl => '$baseUrl/ai/chat';
  static String get diagnoseUrl => '$baseUrl/ai/diagnose';
  static String get diagnoseEndpoint => '$baseUrl/diagnose';
  static String get keyStatusUrl => '$baseUrl/ai/key-status';
  static String get configureKeyUrl => '$baseUrl/ai/configure-key';
  static String get speakUrl => '$baseUrl/ai/speak';
  static String get ttsUrl => '$baseUrl/ai/tts';
  static String get stopSpeakUrl => '$baseUrl/ai/stop-speak';
  static String get voiceRecordStartUrl => '$baseUrl/ai/voice/record-start';
  static String get voiceRecordStopUrl => '$baseUrl/ai/voice/record-stop';
  static String get voiceRecordStatusUrl => '$baseUrl/ai/voice/record-status';
  static String get voiceAnalyzeUrl => '$baseUrl/ai/voice/analyze';
  static String get voiceTranscribeUrl => '$baseUrl/ai/voice/transcribe';

  // Core Service Endpoints
  static String get diagnosesUrl => '$baseUrl/diagnoses/';
  static String get weatherForecastUrl => '$baseUrl/weather/forecast';
  static String get mandiPricesUrl => '$baseUrl/mandi/prices';
  static String get mandisUrl => '$baseUrl/mandi/mandis';
  static String get closestMandiUrl => '$baseUrl/mandi/closest';
  static String get dashboardStatsUrl => '$baseUrl/dashboard/stats';
  static String get fertilizerVerifyUrl => '$baseUrl/fertilizer/verify';
  static String get insuranceClaimsUrl => '$baseUrl/insurance/claims';

  // Krishi Marketplace Endpoints
  static String get marketplaceProductsUrl => '$baseUrl/marketplace/products';
  static String get marketplaceOrdersUrl => '$baseUrl/marketplace/orders';
  static String get marketplaceCouponsValidateUrl => '$baseUrl/marketplace/coupons/validate';
  static String get marketplaceVerifyOtpUrl => '$baseUrl/marketplace/orders/verify-otp';
}
