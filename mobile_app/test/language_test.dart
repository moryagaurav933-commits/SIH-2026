import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:krishi_saarthi/localization/app_language.dart';
import 'package:krishi_saarthi/localization/app_translations.dart';
import 'package:krishi_saarthi/providers/language_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppLanguage Enum & Helpers', () {
    test('fromCode maps strings accurately with safe default', () {
      expect(AppLanguage.fromCode('hinglish'), AppLanguage.hinglish);
      expect(AppLanguage.fromCode('hi'), AppLanguage.hi);
      expect(AppLanguage.fromCode('en'), AppLanguage.en);
      expect(AppLanguage.fromCode('bn'), AppLanguage.bn);
      expect(AppLanguage.fromCode('gu'), AppLanguage.gu);
      expect(AppLanguage.fromCode('mr'), AppLanguage.mr);
      expect(AppLanguage.fromCode('te'), AppLanguage.te);
      expect(AppLanguage.fromCode('ta'), AppLanguage.ta);
      expect(AppLanguage.fromCode('ur'), AppLanguage.ur);
      expect(AppLanguage.fromCode('kn'), AppLanguage.kn);
      expect(AppLanguage.fromCode('unknown'), AppLanguage.hinglish);
      expect(AppLanguage.fromCode(null), AppLanguage.hinglish);
    });

    test('Locales match standard platform specs', () {
      expect(AppLanguage.hinglish.locale.languageCode, 'hi');
      expect(AppLanguage.hinglish.locale.countryCode, 'IN');
      expect(AppLanguage.hi.locale.languageCode, 'hi');
      expect(AppLanguage.en.locale.languageCode, 'en');
      expect(AppLanguage.bn.locale.languageCode, 'bn');
      expect(AppLanguage.gu.locale.languageCode, 'gu');
      expect(AppLanguage.mr.locale.languageCode, 'mr');
      expect(AppLanguage.te.locale.languageCode, 'te');
      expect(AppLanguage.ta.locale.languageCode, 'ta');
      expect(AppLanguage.ur.locale.languageCode, 'ur');
      expect(AppLanguage.kn.locale.languageCode, 'kn');
    });
  });

  group('AppTranslations Dictionary', () {
    test('returns accurate translations across all 10 languages', () {
      // 1. Tool Crop Doctor Title
      expect(
        AppTranslations.get('tool_crop_doctor_title', AppLanguage.hinglish),
        'AI Fasal Doctor',
      );
      expect(
        AppTranslations.get('tool_crop_doctor_title', AppLanguage.hi),
        'AI फसल डॉक्टर',
      );
      expect(
        AppTranslations.get('tool_crop_doctor_title', AppLanguage.en),
        'AI Crop Doctor',
      );
      expect(
        AppTranslations.get('tool_crop_doctor_title', AppLanguage.bn),
        'এআই ফসল ডাক্তার',
      );
      expect(
        AppTranslations.get('tool_crop_doctor_title', AppLanguage.gu),
        'AI પાક ડૉક્ટર',
      );
      expect(
        AppTranslations.get('tool_crop_doctor_title', AppLanguage.mr),
        'AI पीक डॉक्टर',
      );
      expect(
        AppTranslations.get('tool_crop_doctor_title', AppLanguage.te),
        'AI పంట డాక్టర్',
      );
      expect(
        AppTranslations.get('tool_crop_doctor_title', AppLanguage.ta),
        'AI பயிர் மருத்துவர்',
      );
      expect(
        AppTranslations.get('tool_crop_doctor_title', AppLanguage.ur),
        'اے آئی فصل ڈاکٹر',
      );
      expect(
        AppTranslations.get('tool_crop_doctor_title', AppLanguage.kn),
        'AI ಬೆಳೆ ವೈದ್ಯ',
      );

      // 2. Daily Essential Tools Subtitle
      expect(
        AppTranslations.get('daily_tools_sub', AppLanguage.hinglish),
        'Daily Essential Tools',
      );
      expect(
        AppTranslations.get('daily_tools_sub', AppLanguage.hi),
        'दैनिक उपयोगी सेवाएं',
      );
      expect(
        AppTranslations.get('daily_tools_sub', AppLanguage.en),
        'Daily Essential Tools',
      );

      // 3. Dock Bottom Nav
      expect(
        AppTranslations.get('dock_mandi', AppLanguage.hinglish),
        'Mandi',
      );
      expect(
        AppTranslations.get('dock_mandi', AppLanguage.hi),
        'मंडी',
      );
      expect(
        AppTranslations.get('dock_mandi', AppLanguage.en),
        'Mandi',
      );

      // 4. Drawer Feature
      expect(
        AppTranslations.get('drawer_f1_title', AppLanguage.hinglish),
        'AI Leaf Disease Scanner',
      );
      expect(
        AppTranslations.get('drawer_f1_title', AppLanguage.hi),
        'AI पत्ती रोग स्कैनर',
      );
      expect(
        AppTranslations.get('drawer_f1_title', AppLanguage.en),
        'AI Leaf Disease Scanner',
      );
    });
  });

  group('LanguageProvider State Management', () {
    test('switches language and persists preference in SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({'user_selected_language': 'en'});
      final provider = LanguageProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(provider.currentLanguage, AppLanguage.en);
      expect(provider.code, 'en');

      // Switch to Hindi
      bool notified = false;
      provider.addListener(() => notified = true);
      await provider.setLanguage(AppLanguage.hi);

      expect(provider.currentLanguage, AppLanguage.hi);
      expect(provider.code, 'hi');
      expect(notified, isTrue);

      // Switch to Hinglish
      notified = false;
      await provider.setLanguage(AppLanguage.hinglish);

      expect(provider.currentLanguage, AppLanguage.hinglish);
      expect(provider.code, 'hinglish');
      expect(notified, isTrue);
    });
  });
}
