import 'package:flutter_test/flutter_test.dart';
import 'package:krishi_saarthi/localization/app_language.dart';
import 'package:krishi_saarthi/providers/weather_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('WeatherProvider Tests', () {
    test('Initializes with default or saved location', () async {
      final provider = WeatherProvider();
      expect(provider.locationLabel, isNotEmpty);
      expect(provider.currentTemp, isA<int>());
      expect(provider.currentHumidity, isA<int>());
      expect(provider.currentIcon, isNotEmpty);
    });

    test('Condition translations work for English, Hindi, Hinglish', () {
      final provider = WeatherProvider();
      expect(provider.getCondition(AppLanguage.en), isNotEmpty);
      expect(provider.getCondition(AppLanguage.hi), isNotEmpty);
      expect(provider.getCondition(AppLanguage.hinglish), isNotEmpty);
    });

    test('Searching a city updates location label and coordinates', () async {
      final provider = WeatherProvider();
      await provider.fetchWeatherForCity('Pune');
      expect(
        provider.locationLabel.contains('पुणे') || provider.locationLabel.toLowerCase().contains('pune'),
        isTrue,
      );
      expect(provider.isGpsLocation, isFalse);
    });
  });
}
