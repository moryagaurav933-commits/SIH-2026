import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../localization/app_language.dart';
import '../localization/app_translations.dart';

/// Global provider managing app language state across all screens.
class LanguageProvider extends ChangeNotifier {
  static const String _prefKey = 'user_selected_language';

  AppLanguage _currentLanguage = AppLanguage.hinglish;
  bool _isInitialized = false;

  LanguageProvider() {
    Future.microtask(() => _loadFromPrefs());
  }

  AppLanguage get currentLanguage => _currentLanguage;
  bool get isInitialized => _isInitialized;

  String get code => _currentLanguage.code;
  String get displayName => _currentLanguage.displayName;
  String get subTitle => _currentLanguage.subTitle;
  String get badge => _currentLanguage.badge;
  Locale get locale => _currentLanguage.locale;

  bool get isHinglish => _currentLanguage == AppLanguage.hinglish;
  bool get isHindi => _currentLanguage == AppLanguage.hi;
  bool get isEnglish => _currentLanguage == AppLanguage.en;
  bool get isBengali => _currentLanguage == AppLanguage.bn;
  bool get isGujarati => _currentLanguage == AppLanguage.gu;
  bool get isMarathi => _currentLanguage == AppLanguage.mr;
  bool get isTelugu => _currentLanguage == AppLanguage.te;
  bool get isTamil => _currentLanguage == AppLanguage.ta;
  bool get isUrdu => _currentLanguage == AppLanguage.ur;
  bool get isKannada => _currentLanguage == AppLanguage.kn;

  /// Translates a key using the active language
  String t(String key) {
    return AppTranslations.get(key, _currentLanguage);
  }

  /// Sets the active language and persists the choice to SharedPreferences
  Future<void> setLanguage(AppLanguage language) async {
    if (_currentLanguage == language) return;
    _currentLanguage = language;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, language.code);
    } catch (_) {
      // Graceful fallback if SharedPreferences fails
    }
  }

  /// Loads saved language preference from SharedPreferences
  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCode = prefs.getString(_prefKey);
      if (savedCode != null) {
        _currentLanguage = AppLanguage.fromCode(savedCode);
      }
    } catch (_) {
      // Default to Hinglish on any read error
      _currentLanguage = AppLanguage.hinglish;
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }
}
