import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/weather_mandi_service.dart';
import '../db/local_db.dart';
import '../localization/app_language.dart';

/// Global Weather Provider managing live GPS weather, searched cities,
/// offline cached telemetry, and cross-screen synchronisation between
/// HomeScreen and WeatherScreen.
class WeatherProvider extends ChangeNotifier {
  static const String _prefKeyLocation = 'krishi_weather_location';
  static const String _prefKeyLat = 'krishi_weather_lat';
  static const String _prefKeyLon = 'krishi_weather_lon';
  static const String _prefKeyIsGps = 'krishi_weather_is_gps';

  final WeatherService _weatherService;
  final LocalDB _db;

  Map<String, dynamic>? _weather;
  String _locationLabel = 'Sonipat, Haryana';
  double? _currentLat;
  double? _currentLon;
  bool _isLoading = false;
  bool _isGpsLoading = false;
  bool _isGpsLocation = false;
  bool _isInitialized = false;
  String? _errorMessage;

  WeatherProvider({WeatherService? weatherService, LocalDB? db})
      : _db = db ?? LocalDB(),
        _weatherService = weatherService ?? WeatherService(db ?? LocalDB()) {
    initWeather();
  }

  WeatherService get weatherService => _weatherService;
  Map<String, dynamic>? get weather => _weather;
  String get locationLabel => _locationLabel;
  double? get currentLat => _currentLat;
  double? get currentLon => _currentLon;
  bool get isLoading => _isLoading;
  bool get isGpsLoading => _isGpsLoading;
  bool get isGpsLocation => _isGpsLocation;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;

  /// Returns current temperature in Celsius
  int get currentTemp {
    if (_weather != null && _weather!['current'] != null) {
      final temp = _weather!['current']['temp_c'];
      if (temp is num) return temp.round();
    }
    return 31;
  }

  /// Returns relative humidity / moisture percentage
  int get currentHumidity {
    if (_weather != null && _weather!['current'] != null) {
      final hum = _weather!['current']['humidity'];
      if (hum is num) return hum.round();
    }
    return 42;
  }

  /// Returns meteorological weather icon (e.g. ☀️, ⛅, 🌧️)
  String get currentIcon {
    if (_weather != null && _weather!['current'] != null) {
      return _weather!['current']['icon'] as String? ?? '🌤️';
    }
    return '🌤️';
  }

  /// Wind speed in km/h
  int get currentWind {
    if (_weather != null && _weather!['current'] != null) {
      final wind = _weather!['current']['wind_kmh'] ?? _weather!['current']['wind_speed_kmh'];
      if (wind is num) return wind.round();
    }
    return 12;
  }

  /// Rain probability percentage (0-100)
  int get currentRainProb {
    if (_weather != null && _weather!['current'] != null) {
      final rain = _weather!['current']['rain_prob'];
      if (rain is num) return rain.round();
    }
    return 20;
  }

  /// Day minimum temperature
  int get minTemp {
    if (_weather != null && _weather!['forecast_5day'] != null && (_weather!['forecast_5day'] as List).isNotEmpty) {
      final today = _weather!['forecast_5day'][0];
      if (today['low'] != null) return (today['low'] as num).round();
    }
    return currentTemp - 5;
  }

  /// Day maximum temperature
  int get maxTemp {
    if (_weather != null && _weather!['forecast_5day'] != null && (_weather!['forecast_5day'] as List).isNotEmpty) {
      final today = _weather!['forecast_5day'][0];
      if (today['high'] != null) return (today['high'] as num).round();
    }
    return currentTemp + 3;
  }

  /// Indicates if the weather data is served from local offline cache
  bool get isOffline => _weather?['is_cached'] as bool? ?? false;

  /// Localized condition string based on active app language
  String getCondition(AppLanguage lang) {
    if (_weather != null && _weather!['current'] != null) {
      final curr = _weather!['current'];
      switch (lang) {
        case AppLanguage.en:
          return (curr['condition_en'] ?? curr['condition'] ?? 'Clear Sky') as String;
        case AppLanguage.hi:
          return (curr['condition_hi'] ?? curr['condition'] ?? 'साफ मौसम') as String;
        case AppLanguage.hinglish:
          return (curr['condition_hinglish'] ?? curr['condition_hi'] ?? 'Saaf Mausam') as String;
        default:
          return (curr['condition_en'] ?? curr['condition'] ?? 'Clear Sky') as String;
      }
    }
    switch (lang) {
      case AppLanguage.en:
        return 'Clear Sky';
      case AppLanguage.hi:
        return 'साफ मौसम';
      case AppLanguage.hinglish:
        return 'Saaf Mausam';
      default:
        return 'Clear Sky';
    }
  }

  /// Localized rain and agricultural forecast snippet
  String getRainForecast(AppLanguage lang) {
    if (_weather != null) {
      final curr = _weather!['current'] as Map<String, dynamic>?;
      final rain = (curr?['rainfall_mm'] as num?)?.toDouble() ?? 0.0;
      final rainProb = (curr?['rain_prob'] as num?)?.toInt() ?? 0;

      if (rain > 1.0 || rainProb > 50) {
        switch (lang) {
          case AppLanguage.en:
            return 'Rain expected soon';
          case AppLanguage.hi:
            return 'बारिश की संभावना';
          case AppLanguage.hinglish:
            return 'Barish expected';
          default:
            return 'Rain expected';
        }
      } else {
        switch (lang) {
          case AppLanguage.en:
            return 'Clear & Favorable';
          case AppLanguage.hi:
            return 'मौसम अनुकूल';
          case AppLanguage.hinglish:
            return 'Mausam anukool';
          default:
            return 'Favorable';
        }
      }
    }
    switch (lang) {
      case AppLanguage.en:
        return '4h rain expected';
      case AppLanguage.hi:
        return '4 घंटे में बारिश';
      case AppLanguage.hinglish:
        return '4 ghante mein barish';
      default:
        return 'Rain expected';
    }
  }

  /// Initialize weather on startup: checks GPS permissions, restores saved choices,
  /// or falls back cleanly.
  Future<void> initWeather() async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLocation = prefs.getString(_prefKeyLocation);
      final savedLat = prefs.getDouble(_prefKeyLat);
      final savedLon = prefs.getDouble(_prefKeyLon);
      final savedIsGps = prefs.getBool(_prefKeyIsGps);

      // 1. If user previously selected a specific city, restore that city
      if (savedLocation != null && savedLocation.isNotEmpty && savedIsGps == false) {
        _locationLabel = savedLocation;
        _currentLat = savedLat;
        _currentLon = savedLon;
        _isGpsLocation = false;
        _weather = await _weatherService.getWeather(
          lat: savedLat,
          lon: savedLon,
          districtCode: savedLocation,
          locationName: savedLocation,
        );
        _isLoading = false;
        _isInitialized = true;
        notifyListeners();
        return;
      }

      // 2. Try fetching live GPS location
      final pos = await _weatherService.getCurrentLocation();
      if (pos != null) {
        _currentLat = pos.latitude;
        _currentLon = pos.longitude;
        final resolved = await _weatherService.reverseGeocode(pos.latitude, pos.longitude);
        _locationLabel = resolved;
        _isGpsLocation = true;
        _weather = await _weatherService.getWeather(
          lat: pos.latitude,
          lon: pos.longitude,
          locationName: resolved,
        );
        _isLoading = false;
        _isInitialized = true;
        notifyListeners();
        _persistState();
        return;
      }

      // 3. If GPS not granted or unavailable, check if saved city exists
      if (savedLocation != null && savedLocation.isNotEmpty) {
        _locationLabel = savedLocation;
        _currentLat = savedLat;
        _currentLon = savedLon;
        _isGpsLocation = false;
        _weather = await _weatherService.getWeather(
          lat: savedLat,
          lon: savedLon,
          districtCode: savedLocation,
          locationName: savedLocation,
        );
        _isLoading = false;
        _isInitialized = true;
        notifyListeners();
        return;
      }

      // 4. Default fallback: Sonipat, Haryana (until user selects city or allows GPS)
      _locationLabel = 'Sonipat, Haryana';
      _currentLat = 28.9931;
      _currentLon = 77.0151;
      _isGpsLocation = false;
      _weather = await _weatherService.getWeather(
        districtCode: 'HR001',
        locationName: 'Sonipat, Haryana',
      );
    } catch (e) {
      debugPrint('WeatherProvider initWeather error: $e');
      _locationLabel = 'Sonipat, Haryana';
      _weather = await _weatherService.getWeather(
        districtCode: 'HR001',
        locationName: 'Sonipat, Haryana',
      );
    } finally {
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Request user GPS position and update weather everywhere
  Future<bool> fetchWeatherForGps() async {
    _isGpsLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final pos = await _weatherService.getCurrentLocation();
      if (pos != null) {
        _currentLat = pos.latitude;
        _currentLon = pos.longitude;
        final resolved = await _weatherService.reverseGeocode(pos.latitude, pos.longitude);
        _locationLabel = resolved;
        _isGpsLocation = true;
        _isGpsLoading = false;
        _isLoading = true;
        notifyListeners();

        _weather = await _weatherService.getWeather(
          lat: pos.latitude,
          lon: pos.longitude,
          locationName: resolved,
        );
        _isLoading = false;
        notifyListeners();
        _persistState();
        return true;
      } else {
        _isGpsLoading = false;
        _errorMessage = 'Location access not granted or unavailable';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isGpsLoading = false;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Search city or district by name and update across the app
  Future<void> fetchWeatherForCity(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final geo = await _weatherService.searchLocation(cleanQuery);
      if (geo != null) {
        final name = geo['name'] as String;
        final lat = geo['lat'] as double;
        final lon = geo['lon'] as double;
        _currentLat = lat;
        _currentLon = lon;
        _locationLabel = name;
        _isGpsLocation = false;

        _weather = await _weatherService.getWeather(
          lat: lat,
          lon: lon,
          locationName: name,
        );
      } else {
        _locationLabel = cleanQuery;
        _isGpsLocation = false;
        _weather = await _weatherService.getWeather(
          districtCode: cleanQuery,
          locationName: cleanQuery,
        );
      }
      _persistState();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh weather data for the current location
  Future<void> refresh() async {
    if (_currentLat != null && _currentLon != null) {
      _isLoading = true;
      notifyListeners();
      try {
        _weather = await _weatherService.getWeather(
          lat: _currentLat,
          lon: _currentLon,
          locationName: _locationLabel,
        );
      } catch (_) {}
      _isLoading = false;
      notifyListeners();
    } else {
      await fetchWeatherForCity(_locationLabel);
    }
  }

  Future<void> _persistState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeyLocation, _locationLabel);
      if (_currentLat != null) await prefs.setDouble(_prefKeyLat, _currentLat!);
      if (_currentLon != null) await prefs.setDouble(_prefKeyLon, _currentLon!);
      await prefs.setBool(_prefKeyIsGps, _isGpsLocation);
    } catch (_) {}
  }
}
