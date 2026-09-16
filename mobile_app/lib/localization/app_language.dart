import 'package:flutter/material.dart';

/// Supported application languages for Krishi-Saarthi OS
enum AppLanguage {
  hinglish,
  hi,
  en,
  bn,
  gu,
  mr,
  te,
  ta,
  ur,
  kn;

  static AppLanguage fromCode(String? code) {
    if (code == null) return AppLanguage.hinglish;
    final lower = code.toLowerCase().trim();
    if (lower == 'hi' || lower == 'hindi' || lower == 'हिन्दी') {
      return AppLanguage.hi;
    }
    if (lower == 'en' || lower == 'english') {
      return AppLanguage.en;
    }
    if (lower == 'bn' || lower == 'bengali' || lower == 'বাংলা') {
      return AppLanguage.bn;
    }
    if (lower == 'gu' || lower == 'gujarati' || lower == 'ગુજરાતી') {
      return AppLanguage.gu;
    }
    if (lower == 'mr' || lower == 'marathi' || lower == 'मराठी') {
      return AppLanguage.mr;
    }
    if (lower == 'te' || lower == 'telugu' || lower == 'తెలుగు') {
      return AppLanguage.te;
    }
    if (lower == 'ta' || lower == 'tamil' || lower == 'தமிழ்') {
      return AppLanguage.ta;
    }
    if (lower == 'ur' || lower == 'urdu' || lower == 'اردو') {
      return AppLanguage.ur;
    }
    if (lower == 'kn' || lower == 'kannada' || lower == 'ಕನ್ನಡ') {
      return AppLanguage.kn;
    }
    return AppLanguage.hinglish;
  }
}

extension AppLanguageExtension on AppLanguage {
  String get code {
    switch (this) {
      case AppLanguage.hinglish:
        return 'hinglish';
      case AppLanguage.hi:
        return 'hi';
      case AppLanguage.en:
        return 'en';
      case AppLanguage.bn:
        return 'bn';
      case AppLanguage.gu:
        return 'gu';
      case AppLanguage.mr:
        return 'mr';
      case AppLanguage.te:
        return 'te';
      case AppLanguage.ta:
        return 'ta';
      case AppLanguage.ur:
        return 'ur';
      case AppLanguage.kn:
        return 'kn';
    }
  }

  String get displayName {
    switch (this) {
      case AppLanguage.hinglish:
        return 'Hinglish';
      case AppLanguage.hi:
        return 'हिन्दी';
      case AppLanguage.en:
        return 'English';
      case AppLanguage.bn:
        return 'বাংলা';
      case AppLanguage.gu:
        return 'ગુજરાતી';
      case AppLanguage.mr:
        return 'मराठी';
      case AppLanguage.te:
        return 'తెలుగు';
      case AppLanguage.ta:
        return 'தமிழ்';
      case AppLanguage.ur:
        return 'اردو';
      case AppLanguage.kn:
        return 'ಕನ್ನಡ';
    }
  }

  String get subTitle {
    switch (this) {
      case AppLanguage.hinglish:
        return 'Hindi & English bolchal · Kisan youth';
      case AppLanguage.hi:
        return 'शुद्ध देवनागरी हिन्दी · पारम्परिक सलाह';
      case AppLanguage.en:
        return 'Standard English · Agronomy guide';
      case AppLanguage.bn:
        return 'বাংলা ভাষা · কৃষি ও আবহাওয়া পরামর্শ';
      case AppLanguage.gu:
        return 'ગુજરાતી ભાષા · ખેતી અને હવામાન સલાહ';
      case AppLanguage.mr:
        return 'मराठी भाषा · शेती व हवामान सल्ला';
      case AppLanguage.te:
        return 'తెలుగు భాష · వ్యవసాయ & వాతావరణ సలహాలు';
      case AppLanguage.ta:
        return 'தமிழ் மொழி · வேளாண் & வானிலை வழிகாட்டி';
      case AppLanguage.ur:
        return 'اردو زبان · زراعت اور موسم کی معلومات';
      case AppLanguage.kn:
        return 'ಕನ್ನಡ ಭಾಷೆ · ಕೃಷಿ & ಹವಾಮಾನ ಸಲಹೆಗಳು';
    }
  }

  String get badge {
    switch (this) {
      case AppLanguage.hinglish:
        return 'Hn';
      case AppLanguage.hi:
        return 'हिं';
      case AppLanguage.en:
        return 'EN';
      case AppLanguage.bn:
        return 'বাং';
      case AppLanguage.gu:
        return 'ગુજ';
      case AppLanguage.mr:
        return 'मरा';
      case AppLanguage.te:
        return 'తె';
      case AppLanguage.ta:
        return 'த';
      case AppLanguage.ur:
        return 'ارد';
      case AppLanguage.kn:
        return 'ಕ';
    }
  }

  Locale get locale {
    switch (this) {
      case AppLanguage.hinglish:
        return const Locale('hi', 'IN');
      case AppLanguage.hi:
        return const Locale('hi', 'IN');
      case AppLanguage.en:
        return const Locale('en', 'US');
      case AppLanguage.bn:
        return const Locale('bn', 'IN');
      case AppLanguage.gu:
        return const Locale('gu', 'IN');
      case AppLanguage.mr:
        return const Locale('mr', 'IN');
      case AppLanguage.te:
        return const Locale('te', 'IN');
      case AppLanguage.ta:
        return const Locale('ta', 'IN');
      case AppLanguage.ur:
        return const Locale('ur', 'IN');
      case AppLanguage.kn:
        return const Locale('kn', 'IN');
    }
  }
}
