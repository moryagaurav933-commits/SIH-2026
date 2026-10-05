import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/weather_provider.dart';
import '../../utils/design_tokens.dart';
import '../../localization/app_language.dart';
import '../../localization/app_translations.dart';

/// Feature 6 — Weather Forecast & Agricultural Advisory
/// Live GPS + Multi-Source Weather Engine + 100% Trilingual Dynamic UI.
/// Rebuilt to reactively reflect Home Page language selection and shared WeatherProvider state.
class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<String> _getQuickDistricts(BuildContext context) {
    final lang = context.currentLanguage;
    return [
      context.tr('weather_gps_chip'),
      lang == AppLanguage.en ? 'Lucknow' : (lang == AppLanguage.hi ? 'लखनऊ' : 'Lucknow'),
      lang == AppLanguage.en ? 'Sonipat' : (lang == AppLanguage.hi ? 'सोनीपत' : 'Sonipat'),
      lang == AppLanguage.en ? 'Indore' : (lang == AppLanguage.hi ? 'इंदौर' : 'Indore'),
      lang == AppLanguage.en ? 'Pune' : (lang == AppLanguage.hi ? 'पुणे' : 'Pune'),
      lang == AppLanguage.en ? 'Varanasi' : (lang == AppLanguage.hi ? 'वाराणसी' : 'Varanasi'),
      lang == AppLanguage.en ? 'Patna' : (lang == AppLanguage.hi ? 'पटना' : 'Patna'),
      lang == AppLanguage.en ? 'Jaipur' : (lang == AppLanguage.hi ? 'जयपुर' : 'Jaipur'),
    ];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Trigger GPS location search when user taps GPS button.
  Future<void> _handleGpsTap(BuildContext context, WeatherProvider weatherProv) async {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.tr('weather_gps_fetching')),
        duration: const Duration(seconds: 2),
        backgroundColor: colorPrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    final success = await weatherProv.fetchWeatherForGps();
    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('weather_gps_denied')),
          backgroundColor: colorWarning,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  /// Handle location search by text query.
  Future<void> _handleSearch(String query, WeatherProvider weatherProv) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return;
    await weatherProv.fetchWeatherForCity(cleanQuery);
  }

  @override
  Widget build(BuildContext context) {
    final weatherProv = Provider.of<WeatherProvider>(context);

    return Scaffold(
      backgroundColor: colorBg,
      appBar: buildKrishiAppBar(
        context: context,
        title: context.tr('weather_title'),
        subtitle: context.tr('weather_subtitle'),
        emoji: '🌤️',
        actions: [
          IconButton(
            onPressed: () => weatherProv.refresh(),
            icon: const Icon(Icons.refresh_rounded, color: colorPrimary, size: 20),
            tooltip: 'Refresh Weather',
          ),
        ],
      ),
      body: weatherProv.isLoading && weatherProv.weather == null
          ? _buildLoadingState()
          : RefreshIndicator(
              color: colorPrimary,
              onRefresh: () => weatherProv.refresh(),
              child: _buildWeatherUI(context, weatherProv),
            ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: colorPrimary, strokeWidth: 2.5),
          const SizedBox(height: 16),
          Text(
            context.tr('weather_loading'),
            style: const TextStyle(fontFamily: 'NotoSansDevanagari', fontSize: 14, color: colorStoneText),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherUI(BuildContext context, WeatherProvider weatherProv) {
    final lang = context.currentLanguage;
    final weather = weatherProv.weather;
    final locationLabel = weatherProv.locationLabel;
    final current = weather?['current'] as Map<String, dynamic>? ?? {};
    final forecast = weather?['forecast_5day'] as List? ?? [];

    final conditionText = lang == AppLanguage.en
        ? (current['condition_en'] ?? current['condition'] ?? 'Clear Sky')
        : (lang == AppLanguage.hi
            ? (current['condition_hi'] ?? current['condition'] ?? 'साफ आसमान')
            : (current['condition_hinglish'] ?? current['condition_hi'] ?? current['condition'] ?? 'Saaf Aasman'));

    final advisoryText = lang == AppLanguage.en
        ? (weather?['advisory_en'] ?? weather?['advisory_hi'] ?? '')
        : (lang == AppLanguage.hi
            ? (weather?['advisory_hi'] ?? weather?['advisory_en'] ?? '')
            : (weather?['advisory_hinglish'] ?? weather?['advisory_hi'] ?? weather?['advisory_en'] ?? ''));

    final hoursLeft = (weather?['hours_left_in_cache'] as num?)?.toDouble() ?? 12.0;
    final isOffline = weather?['is_cached'] as bool? ?? false;
    final icon = current['icon'] as String? ?? '🌤️';
    final quickDistricts = _getQuickDistricts(context);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Live vs Offline Badge Banner
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isOffline ? colorWarningBg : const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isOffline ? colorWarning : colorPrimary,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isOffline ? Icons.offline_bolt_rounded : Icons.satellite_alt_rounded,
                      size: 14,
                      color: isOffline ? colorWarning : colorPrimary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isOffline
                          ? '${context.tr('weather_offline_badge')} (${hoursLeft.toStringAsFixed(1)}h)'
                          : context.tr('weather_live_badge'),
                      style: TextStyle(
                        fontFamily: 'NotoSansDevanagari',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isOffline ? colorWarning : colorPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              const Text(
                'High-Res GPS Model',
                style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 10, color: colorStoneMuted),
              ),
            ],
          ),
          const SizedBox(height: spacingSm),

          // Search bar & GPS Action Button
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: colorCard,
              borderRadius: BorderRadius.circular(radiusMd),
              border: Border.all(color: colorHairline),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                const Icon(Icons.search_rounded, color: colorStoneMuted, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: tsHeadlineSm.copyWith(fontSize: 14),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: context.tr('weather_search_hint'),
                      hintStyle: const TextStyle(fontFamily: 'NotoSansDevanagari', fontSize: 13, color: colorStoneMuted),
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onSubmitted: (v) => _handleSearch(v, weatherProv),
                  ),
                ),
                // Clear button if text entered
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 16, color: colorStoneMuted),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                  ),
                // Search Submit Button
                GestureDetector(
                  onTap: () => _handleSearch(_searchController.text, weatherProv),
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: colorPrimary, borderRadius: BorderRadius.circular(radiusSm)),
                    child: Text(
                      context.tr('weather_search_btn'),
                      style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                ),
                // GPS Location Button
                IconButton(
                  onPressed: weatherProv.isGpsLoading ? null : () => _handleGpsTap(context, weatherProv),
                  icon: weatherProv.isGpsLoading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: colorPrimary))
                      : const Icon(Icons.my_location_rounded, color: colorPrimary, size: 20),
                  tooltip: 'Get Current GPS Location',
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Quick District Selection Chips
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: quickDistricts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final d = quickDistricts[index];
                final isGps = index == 0;
                return ActionChip(
                  label: Text(
                    d,
                    style: TextStyle(
                      fontFamily: 'NotoSansDevanagari',
                      fontSize: 11,
                      fontWeight: isGps ? FontWeight.w700 : FontWeight.w500,
                      color: isGps ? Colors.white : colorStoneText,
                    ),
                  ),
                  backgroundColor: isGps ? colorPrimary : colorCard,
                  side: BorderSide(color: isGps ? colorPrimary : colorHairline),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                  onPressed: () {
                    if (isGps) {
                      _handleGpsTap(context, weatherProv);
                    } else {
                      _searchController.text = d;
                      _handleSearch(d, weatherProv);
                    }
                  },
                );
              },
            ),
          ),
          const SizedBox(height: spacingMd),

          // Current Weather Hero Card
          buildSectionHeader('01', context.tr('weather_current_sec')),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(spacingLg),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)],
              ),
              borderRadius: BorderRadius.circular(radiusLg),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1B4332).withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${current['temp_c'] ?? 28}°',
                      style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 54, fontWeight: FontWeight.w800, color: Colors.white, height: 1),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(icon, style: const TextStyle(fontSize: 22)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  conditionText,
                                  style: const TextStyle(fontFamily: 'NotoSansDevanagari', fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 14, color: Color(0xFF81C784)),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  locationLabel,
                                  style: const TextStyle(fontFamily: 'NotoSansDevanagari', fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(color: Colors.white24, height: 1),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _weatherStat('💧', '${current['humidity'] ?? current['humidity_pct'] ?? 65}%', context.tr('weather_stat_humidity')),
                    _weatherStat('💨', '${current['wind_kmh'] ?? current['wind_speed_kmh'] ?? 12} km/h', context.tr('weather_stat_wind')),
                    _weatherStat('🌧️', '${current['rain_prob'] ?? 20}%', context.tr('weather_stat_rain')),
                    _weatherStat('☀️', '${current['uv_index'] ?? 7}', context.tr('weather_stat_uv')),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: spacingLg),

          // 5-Day Agro-Forecast
          buildSectionHeader('02', context.tr('weather_forecast_sec')),
          buildCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                if (forecast.isEmpty)
                  ..._buildDefaultForecast(context)
                else
                  ...forecast.asMap().entries.map((e) => _buildForecastRow(context, Map<String, dynamic>.from(e.value), e.key, forecast.length)),
              ],
            ),
          ),
          const SizedBox(height: spacingLg),

          // Agricultural Advisory
          if (advisoryText.isNotEmpty) ...[
            buildSectionHeader('03', context.tr('weather_advisory_sec')),
            buildCard(
              bgColor: colorPrimarySoft,
              borderColor: colorPrimaryContainer,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.agriculture_rounded, color: colorPrimary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        context.tr('weather_advisory_title'),
                        style: const TextStyle(fontFamily: 'NotoSansDevanagari', fontSize: 14, fontWeight: FontWeight.w700, color: colorPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    advisoryText,
                    style: tsBody.copyWith(color: colorPrimaryDeep, height: 1.45, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _weatherStat(String emoji, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
          Text(label, style: const TextStyle(fontFamily: 'NotoSansDevanagari', fontSize: 10, color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildForecastRow(BuildContext context, Map<String, dynamic> day, int index, int total) {
    final lang = context.currentLanguage;
    final isLast = index == total - 1;

    final dayLabel = lang == AppLanguage.en
        ? (day['day_en'] ?? day['date'] ?? 'Day ${index + 1}')
        : (lang == AppLanguage.hi
            ? (day['day_hi'] ?? day['date'] ?? 'दिन ${index + 1}')
            : (day['day_hinglish'] ?? day['day_hi'] ?? day['date'] ?? 'Din ${index + 1}'));

    final cond = lang == AppLanguage.en
        ? (day['condition_en'] ?? day['condition'] ?? 'Clear')
        : (lang == AppLanguage.hi
            ? (day['condition_hi'] ?? day['condition'] ?? 'साफ')
            : (day['condition_hinglish'] ?? day['condition_hi'] ?? day['condition'] ?? 'Saaf'));

    final icon = day['icon'] ?? '⛅';
    final high = day['high'] ?? day['max_c'] ?? 30;
    final low = day['low'] ?? day['min_c'] ?? 20;
    final rainMm = (day['rain_mm'] as num?)?.toDouble() ?? 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: spacingMd, vertical: 12),
      decoration: BoxDecoration(
        border: !isLast ? const Border(bottom: BorderSide(color: colorHairline, width: 1)) : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 75,
            child: Text(
              dayLabel,
              style: const TextStyle(fontFamily: 'NotoSansDevanagari', fontSize: 13, fontWeight: FontWeight.w700, color: colorStoneText),
            ),
          ),
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cond, style: tsBodySm.copyWith(fontWeight: FontWeight.w500)),
                if (rainMm > 0)
                  Text(
                    '🌧️ ${rainMm.toStringAsFixed(1)} mm',
                    style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 10, color: colorPrimary, fontWeight: FontWeight.w600),
                  ),
              ],
            ),
          ),
          Text(
            '$high° / $low°',
            style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 13, fontWeight: FontWeight.w700, color: colorStoneText),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDefaultForecast(BuildContext context) {
    final days = [
      {
        'day_en': 'Today',
        'day_hi': 'आज',
        'day_hinglish': 'Aaj',
        'condition_en': 'Partly Cloudy',
        'condition_hi': 'आंशिक बादल',
        'condition_hinglish': 'Aanshik Badal',
        'icon': '🌤️',
        'high': 31,
        'low': 21,
        'rain_mm': 0.0,
      },
      {
        'day_en': 'Tomorrow',
        'day_hi': 'कल',
        'day_hinglish': 'Kal',
        'condition_en': 'Light Rain',
        'condition_hi': 'हल्की बारिश',
        'condition_hinglish': 'Halki Barish',
        'icon': '🌧️',
        'high': 27,
        'low': 19,
        'rain_mm': 4.5,
      },
      {
        'day_en': 'Day 3',
        'day_hi': 'परसों',
        'day_hinglish': 'Parson',
        'condition_en': 'Moderate Rain',
        'condition_hi': 'मध्यम बारिश',
        'condition_hinglish': 'Madhyam Barish',
        'icon': '⛈️',
        'high': 25,
        'low': 18,
        'rain_mm': 8.0,
      },
      {
        'day_en': 'Day 4',
        'day_hi': 'दिन 4',
        'day_hinglish': 'Din 4',
        'condition_en': 'Cloudy',
        'condition_hi': 'बादल छाए रहेंगे',
        'condition_hinglish': 'Badal',
        'icon': '☁️',
        'high': 29,
        'low': 20,
        'rain_mm': 1.0,
      },
      {
        'day_en': 'Day 5',
        'day_hi': 'दिन 5',
        'day_hinglish': 'Din 5',
        'condition_en': 'Clear',
        'condition_hi': 'धूप एवं साफ',
        'condition_hinglish': 'Dhoop Saaf',
        'icon': '☀️',
        'high': 33,
        'low': 22,
        'rain_mm': 0.0,
      },
    ];
    return days.asMap().entries.map((e) => _buildForecastRow(context, e.value, e.key, days.length)).toList();
  }
}
