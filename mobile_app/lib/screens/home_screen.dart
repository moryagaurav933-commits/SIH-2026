import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../localization/app_language.dart';
import '../localization/app_translations.dart';
import '../providers/language_provider.dart';
import '../providers/weather_provider.dart';
import 'diagnosis/diagnosis_screen.dart';
import 'weather/weather_screen.dart';
import 'mandi/mandi_screen.dart';
import 'mesh/mesh_screen.dart';
import 'voice_chat/voice_chat_screen.dart';
import 'counterfeit/counterfeit_screen.dart';
import 'ar_spray/ar_spray_screen.dart';
import 'soil_test/soil_test_screen.dart';
import 'insurance/insurance_screen.dart';
import 'dashboard/dashboard_screen.dart';
import 'settings/settings_screen.dart';
import 'telecom/ussd_sms_screen.dart';

/// Krishi-Saarthi OS — Editorial Field Sanctuary Design System
/// Implemented directly from Google Stitch architecture & design palette
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  // Design Tokens — Green + White + Red/Black/Yellow Theme
  static const Color colorBg = Color(0xFFF5F9F5);
  static const Color colorSurface = Color(0xFFF8FBF8);
  static const Color colorCard = Color(0xFFFFFFFF);
  static const Color colorPrimary = Color(0xFF2E7D32);
  static const Color colorPrimaryForest = Color(0xFF1B5E20);
  static const Color colorPrimaryDeep = Color(0xFF0A3D0A);
  static const Color colorPrimaryLight = Color(0xFF4CAF50);
  static const Color colorPrimarySoft = Color(0xFFE8F5E9);
  static const Color colorSecondary = Color(0xFF1B5E20);
  static const Color colorBronze = Color(0xFFFFC107);          // Yellow accent
  static const Color colorBronzeLight = Color(0xFFFFD54F);     // Light yellow
  static const Color colorEarthAlert = Color(0xFFD32F2F);      // Red accent
  static const Color colorOchre = Color(0xFFFFA000);           // Deep yellow
  static const Color colorOchreLight = Color(0xFFFFF8E1);      // Light yellow bg
  static const Color colorStoneText = Color(0xFF1A1A1A);       // Black text
  static const Color colorStoneMuted = Color(0xFF6B8F6B);      // Muted green
  static const Color colorHairline = Color(0xFFE0E8E0);        // Green-tinted border

  String get _currentLanguage {
    try {
      return Provider.of<LanguageProvider>(context, listen: true).displayName;
    } catch (_) {
      return 'Hinglish';
    }
  }
  AnimationController? _waveController;

  AnimationController get waveController {
    _waveController ??= AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1200),
      )..repeat(reverse: true);
    return _waveController!;
  }

  @override
  void initState() {
    super.initState();
    waveController;
  }

  @override
  void dispose() {
    _waveController?.dispose();
    super.dispose();
  }

  void _navigateTo(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBg,
      body: Stack(
        children: [
          // Scrollable Page Content
          CustomScrollView(
            slivers: [
              _buildStitchHeader(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeroCard(),
                      const SizedBox(height: 18),
                      _buildAlertAndWeatherGrid(),
                      const SizedBox(height: 24),
                      _buildDailyEssentialTools(),
                      const SizedBox(height: 20),
                      _buildVoiceSaarthiLiveBanner(),
                      const SizedBox(height: 20),
                      _buildGaonMeshNotes(),
                      const SizedBox(height: 24),
                      _buildSpecializedAgronomySuite(),
                      const SizedBox(height: 100), // Space for floating bottom dock
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Floating Bottom Navigation Dock
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: _buildFloatingBottomDock(),
          ),

          // Kisan AI Floating Action Button
          Positioned(
            right: 16,
            bottom: 90,
            child: _buildKisanAiFab(),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 1. STITCH HEADER
  // ==========================================
  Widget _buildStitchHeader() {
    return SliverAppBar(
      pinned: true,
      elevation: 0,
      backgroundColor: colorBg.withValues(alpha: 0.95),
      surfaceTintColor: Colors.transparent,
      titleSpacing: 16,
      toolbarHeight: 64,
      title: Row(
        children: [
          Text(
            context.tr('app_name'),
            style: const TextStyle(
              color: colorPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 22,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.spa_rounded, color: Color(0xFF2D6A4F), size: 19),
          const SizedBox(width: 4),
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: Color(0xFF10B981),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
      actions: [
        // Language Selector Pill Button
        InkWell(
          onTap: _showLanguagePicker,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: colorSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colorHairline),
            ),
            child: Row(
              children: [
                Text(
                  _currentLanguage,
                  style: const TextStyle(
                    color: colorPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.expand_more_rounded, size: 16, color: colorStoneMuted),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),

        // 13 Features Menu Button
        InkWell(
          onTap: _showFeaturesDrawer,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colorSurface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colorHairline),
            ),
            child: const Icon(Icons.menu_rounded, size: 20, color: colorStoneText),
          ),
        ),
        const SizedBox(width: 8),

        // Google Profile Avatar
        InkWell(
          onTap: _showProfileModal,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFFF59E0B), Color(0xFFEF4444), Color(0xFF3B82F6)],
              ),
            ),
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text(
                  'RS',
                  style: TextStyle(
                    color: colorPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  // ==========================================
  // 2. ATMOSPHERIC HERO VIGNETTE & TELEMETRY
  // ==========================================
  Widget _buildHeroCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 275,
        decoration: BoxDecoration(
          color: colorPrimaryDeep,
          border: Border.all(color: colorHairline),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Authentic Farmer Portrait Image
            Image.asset(
              'assets/images/farmer_portrait.jpg',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              errorBuilder: (context, error, stackTrace) {
                return Image.network(
                  'https://lh3.googleusercontent.com/aida/AEtjO1WYcoQNGHoFRLDscuKY3iCLESkUWdPip4Nxaw3WAVcE31lVwXSmkxYvOubgX8z6TzGRZ4WA_gYAbOGpX64cTjsebSwb_ZBkqZMGsVZfdFMkUbQXZqfWCJY3gbvdbjy1UB2Y6-OqrQhUd-IQB1qmaS4TMLfhv1eZLUKNJCCkIiEfSD61NhUIZLgYvb6mrEhAh_NIJ3SGPcDpCuNpqWuoGIk4xNRKDRR4wRVkfua2-axcpQBQxCQYchHYGJ0',
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF081810), Color(0xFF153324), Color(0xFF1B4332)],
                        ),
                      ),
                    );
                  },
                );
              },
            ),

            // Editorial Contrast Gradients
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.25),
                    colorPrimaryForest.withValues(alpha: 0.65),
                    colorPrimaryDeep.withValues(alpha: 0.96),
                  ],
                ),
              ),
            ),

            // Card Content
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top Row: Telemetry Badges
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: colorBronzeLight,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              context.tr('hero_badge_telemetry'),
                              style: const TextStyle(
                                color: Color(0xFFEADBCE),
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'monospace',
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                        ),
                        child: Text(
                          context.tr('hero_badge_season'),
                          style: const TextStyle(
                            color: Color(0xFFFDE68A),
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'monospace',
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Middle: Editorial Greeting & Microclimate Info
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('hero_main_title'),
                        style: const TextStyle(
                          color: Color(0xFFFAF8F5),
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.tr('hero_main_sub'),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Refined Tri-Metric Glass Bar
                      Consumer<WeatherProvider>(
                        builder: (context, weatherProv, _) {
                          return Row(
                            children: [
                              Expanded(
                                child: _buildTriMetricPill(
                                  value: '${weatherProv.currentHumidity}%',
                                  label: context.tr('tri_moisture_label'),
                                  sublabel: context.tr('tri_moisture_sub'),
                                  onTap: () => _navigateTo(const DashboardScreen()),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildTriMetricPill(
                                  value: '${weatherProv.currentTemp}°C',
                                  label: context.tr('tri_temp_label'),
                                  sublabel: context.tr('tri_temp_sub'),
                                  onTap: () => _navigateTo(const WeatherScreen()),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildTriMetricPill(
                                  value: '0.78',
                                  label: context.tr('tri_canopy_label'),
                                  sublabel: context.tr('tri_canopy_sub'),
                                  onTap: () => _navigateTo(const DashboardScreen()),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTriMetricPill({
    required String value,
    required String label,
    required String sublabel,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.38),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFFC2A268),
                fontSize: 8.5,
                fontWeight: FontWeight.w700,
                fontFamily: 'monospace',
                letterSpacing: 0.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              sublabel,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 3. SECTION 01 / VECTOR INTELLIGENCE & TELEMETRY
  // ==========================================
  Widget _buildAlertAndWeatherGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text(
                  '01 / ',
                  style: TextStyle(
                    color: colorBronze,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
                Text(
                  context.tr('alert_section_title'),
                  style: const TextStyle(
                    color: colorStoneText,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
            const Text(
              'Spatiotemporal Drift',
              style: TextStyle(
                color: colorStoneMuted,
                fontSize: 9.5,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Vector Alert Card (Earth-Alert Strip)
        InkWell(
          onTap: () => _navigateTo(const DiagnosisScreen()),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colorHairline),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Terracotta red left accent border
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 4,
                    decoration: const BoxDecoration(
                      color: colorEarthAlert,
                      borderRadius: BorderRadius.horizontal(left: Radius.circular(18)),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: colorEarthAlert,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                context.tr('alert_card_badge'),
                                style: const TextStyle(
                                  color: colorEarthAlert,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'monospace',
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const Icon(Icons.warning_amber_rounded, size: 16, color: colorEarthAlert),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        context.tr('alert_card_title'),
                        style: const TextStyle(
                          color: colorStoneText,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.tr('alert_card_sub'),
                        style: const TextStyle(
                          color: colorStoneMuted,
                          fontSize: 11.5,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Divider(color: colorHairline, height: 1),
                      const SizedBox(height: 8),

                      // Calibrated Action Line
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Recommended: 5% Neem Bio-Emulsion',
                            style: TextStyle(
                              color: colorBronze,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'monospace',
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                context.tr('alert_view_rx'),
                                style: const TextStyle(
                                  color: colorPrimary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'monospace',
                                ),
                              ),
                              SizedBox(width: 4),
                              Text(
                                '→',
                                style: TextStyle(
                                  color: colorPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Dynamic Weather & Soil Telemetry Section with Quick City Selector
        Consumer<WeatherProvider>(
          builder: (context, weatherProv, _) {
            final lang = context.currentLanguage;
            final condition = weatherProv.getCondition(lang);
            final forecast = weatherProv.getRainForecast(lang);
            final location = weatherProv.locationLabel;
            final temp = '${weatherProv.currentTemp}°C';
            final humidity = '${weatherProv.currentHumidity}%';
            final isGps = weatherProv.isGpsLocation;
            final isOffline = weatherProv.isOffline;
            final icon = weatherProv.currentIcon;

            final quickCities = [
              'Sonipat',
              'Pune',
              'Lucknow',
              'Indore',
              'Jaipur',
              'Patna',
              'Varanasi',
              'Nagpur',
              'Bhopal',
              'Ludhiana',
            ];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Quick Location Switcher Pills Carousel
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      // Live GPS Button Chip
                      _buildQuickLocationChip(
                        label: context.tr('weather_gps_chip'),
                        icon: Icons.my_location_rounded,
                        isSelected: isGps,
                        isLoading: weatherProv.isGpsLoading,
                        onTap: () async {
                          final ok = await weatherProv.fetchWeatherForGps();
                          if (!ok && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(context.tr('weather_gps_denied')),
                                backgroundColor: colorEarthAlert,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          } else if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('📍 Live GPS: ${weatherProv.locationLabel}'),
                                backgroundColor: colorPrimary,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                      ),
                      const SizedBox(width: 8),

                      // Popular Agricultural Hubs Chips
                      ...quickCities.map((city) {
                        final isSelected = !isGps &&
                            location.toLowerCase().contains(city.toLowerCase());
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _buildQuickLocationChip(
                            label: city,
                            icon: Icons.location_city_rounded,
                            isSelected: isSelected,
                            isLoading: false,
                            onTap: () {
                              weatherProv.fetchWeatherForCity(city);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('🌤️ Loading weather for $city...'),
                                  backgroundColor: colorPrimary,
                                  duration: const Duration(milliseconds: 1200),
                                ),
                              );
                            },
                          ),
                        );
                      }),

                      // Search City Button Chip
                      _buildQuickLocationChip(
                        label: context.currentLanguage == AppLanguage.hi
                            ? 'अन्य शहर खोजें 🔍'
                            : (context.currentLanguage == AppLanguage.hinglish
                                ? 'City Khojein 🔍'
                                : 'Search City 🔍'),
                        icon: Icons.search_rounded,
                        isSelected: false,
                        isLoading: false,
                        isAccent: true,
                        onTap: () => _showLocationPickerSheet(weatherProv),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // 2. Interactive Weather & Soil Telemetry Card
                InkWell(
                  onTap: () => _navigateTo(const WeatherScreen()),
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: colorHairline),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Weather Icon Container
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: colorPrimarySoft,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: colorPrimary.withValues(alpha: 0.2)),
                              ),
                              child: Center(
                                child: Text(
                                  icon,
                                  style: const TextStyle(fontSize: 22),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Center Content: Location, Temp, Condition, Forecast
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Location Title + Dropdown Caret + Status Badge
                                  Row(
                                    children: [
                                      Flexible(
                                        child: InkWell(
                                          onTap: () => _showLocationPickerSheet(weatherProv),
                                          borderRadius: BorderRadius.circular(6),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  location,
                                                  style: const TextStyle(
                                                    color: colorStoneText,
                                                    fontSize: 13.5,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 2),
                                              const Icon(
                                                Icons.arrow_drop_down_rounded,
                                                color: colorPrimary,
                                                size: 18,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 5),

                                      // Status Badge (Live GPS / Selected City / Offline)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isOffline
                                              ? const Color(0xFFFFF3E0)
                                              : (isGps ? colorPrimarySoft : const Color(0xFFE3F2FD)),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: isOffline
                                                ? const Color(0xFFFFB74D)
                                                : (isGps ? colorPrimary.withValues(alpha: 0.2) : const Color(0xFF90CAF9)),
                                            width: 0.5,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (weatherProv.isLoading || weatherProv.isGpsLoading)
                                              const Padding(
                                                padding: EdgeInsets.only(right: 3),
                                                child: SizedBox(
                                                  width: 7,
                                                  height: 7,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 1.5,
                                                    color: colorPrimary,
                                                  ),
                                                ),
                                              ),
                                            Text(
                                              isOffline
                                                  ? 'Offline'
                                                  : (isGps ? 'Live GPS' : 'Selected City'),
                                              style: TextStyle(
                                                color: isOffline
                                                    ? const Color(0xFFE65100)
                                                    : (isGps ? colorPrimary : const Color(0xFF1565C0)),
                                                fontSize: 8.5,
                                                fontWeight: FontWeight.w700,
                                                fontFamily: 'monospace',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),

                                  // Temperature & High / Low Range
                                  Row(
                                    children: [
                                      Text(
                                        temp,
                                        style: const TextStyle(
                                          color: colorStoneText,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'H: ${weatherProv.maxTemp}° · L: ${weatherProv.minTemp}°',
                                        style: const TextStyle(
                                          color: colorStoneMuted,
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),

                                  // Condition & Rain Forecast
                                  Text(
                                    '$condition · $forecast',
                                    style: const TextStyle(color: colorStoneMuted, fontSize: 11),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (weatherProv.currentRainProb > 0)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        '💧 ${weatherProv.currentRainProb}% barish sambhavna',
                                        style: const TextStyle(
                                          color: Color(0xFF1976D2),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 8),

                            // Telemetry Column (Mitti Nami + Wind + Refresh button)
                            Container(
                              padding: const EdgeInsets.only(left: 10),
                              decoration: const BoxDecoration(
                                border: Border(left: BorderSide(color: colorHairline)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text(
                                    'Mitti Nami:',
                                    style: TextStyle(
                                      color: colorStoneMuted,
                                      fontSize: 9.5,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF10B981),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        humidity,
                                        style: const TextStyle(
                                          color: colorPrimary,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '💨 ${weatherProv.currentWind} km/h',
                                        style: const TextStyle(
                                          color: colorStoneMuted,
                                          fontSize: 9.5,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      IconButton(
                                        iconSize: 16,
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
                                        tooltip: 'Refresh Weather',
                                        icon: (weatherProv.isLoading || weatherProv.isGpsLoading)
                                            ? const SizedBox(
                                                width: 12,
                                                height: 12,
                                                child: CircularProgressIndicator(strokeWidth: 1.5, color: colorPrimary),
                                              )
                                            : const Icon(
                                                Icons.refresh_rounded,
                                                color: colorStoneMuted,
                                                size: 16,
                                              ),
                                        onPressed: (weatherProv.isLoading || weatherProv.isGpsLoading)
                                            ? null
                                            : () => weatherProv.refresh(),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Card Footer Line
                        Container(
                          padding: const EdgeInsets.only(top: 8),
                          decoration: const BoxDecoration(
                            border: Border(top: BorderSide(color: colorHairline, width: 0.5)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.wb_sunny_outlined, size: 12, color: colorPrimary),
                                  const SizedBox(width: 4),
                                  Text(
                                    context.currentLanguage == AppLanguage.hi
                                        ? '5-दिवसीय कृषि मौसम पूर्वानुमान व सलाह'
                                        : (context.currentLanguage == AppLanguage.hinglish
                                            ? '5-Day Krishi Mausam & Advisory'
                                            : '5-Day Agro Weather Forecast & Advisory'),
                                    style: const TextStyle(
                                      color: colorPrimary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                size: 12,
                                color: colorPrimary,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  // ==========================================
  // LOCATION SELECTOR & CHIP HELPERS
  // ==========================================
  Widget _buildQuickLocationChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required bool isLoading,
    required VoidCallback onTap,
    bool isAccent = false,
  }) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? colorPrimary
              : (isAccent ? colorPrimarySoft : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? colorPrimary
                : (isAccent ? colorPrimary.withValues(alpha: 0.3) : colorHairline),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colorPrimary.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              const Padding(
                padding: EdgeInsets.only(right: 5),
                child: SizedBox(
                  width: 11,
                  height: 11,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.8,
                    color: colorPrimary,
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(
                  icon,
                  size: 13,
                  color: isSelected
                      ? Colors.white
                      : (isAccent ? colorPrimary : colorStoneMuted),
                ),
              ),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : (isAccent ? colorPrimaryForest : colorStoneText),
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLocationPickerSheet(WeatherProvider weatherProv) {
    final searchController = TextEditingController();
    final quickLocations = [
      {'name': 'Sonipat', 'state': 'Haryana'},
      {'name': 'Karnal', 'state': 'Haryana'},
      {'name': 'Pune', 'state': 'Maharashtra'},
      {'name': 'Nashik', 'state': 'Maharashtra'},
      {'name': 'Nagpur', 'state': 'Maharashtra'},
      {'name': 'Lucknow', 'state': 'Uttar Pradesh'},
      {'name': 'Varanasi', 'state': 'Uttar Pradesh'},
      {'name': 'Indore', 'state': 'Madhya Pradesh'},
      {'name': 'Bhopal', 'state': 'Madhya Pradesh'},
      {'name': 'Jaipur', 'state': 'Rajasthan'},
      {'name': 'Kota', 'state': 'Rajasthan'},
      {'name': 'Patna', 'state': 'Bihar'},
      {'name': 'Muzaffarpur', 'state': 'Bihar'},
      {'name': 'Ludhiana', 'state': 'Punjab'},
      {'name': 'Bhatinda', 'state': 'Punjab'},
      {'name': 'Surat', 'state': 'Gujarat'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.82,
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            top: 16,
            left: 18,
            right: 18,
          ),
          decoration: const BoxDecoration(
            color: colorSurface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, color: colorPrimary, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        context.currentLanguage == AppLanguage.hi
                            ? 'स्थान या शहर चुनें'
                            : (context.currentLanguage == AppLanguage.hinglish
                                ? 'Location ya City Chunein'
                                : 'Select or Search Location'),
                        style: const TextStyle(
                          color: colorStoneText,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: colorStoneMuted, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                context.currentLanguage == AppLanguage.hi
                    ? 'लाइव जीपीएस या अपने जिले का चयन करें ताकि होम पेज पर सही डेटा दिखे।'
                    : (context.currentLanguage == AppLanguage.hinglish
                        ? 'Live GPS ya apna district chunein taaki home page par sahi mausam dikhe.'
                        : 'Pick live GPS or your district to view accurate weather on Home Page.'),
                style: const TextStyle(color: colorStoneMuted, fontSize: 11.5),
              ),
              const SizedBox(height: 14),

              // 1. Live GPS Action Button
              InkWell(
                onTap: () async {
                  Navigator.pop(ctx);
                  final ok = await weatherProv.fetchWeatherForGps();
                  if (!ok && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(context.tr('weather_gps_denied')),
                        backgroundColor: colorEarthAlert,
                      ),
                    );
                  } else if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('📍 Live GPS Synced: ${weatherProv.locationLabel}'),
                        backgroundColor: colorPrimary,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: colorPrimarySoft,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: colorPrimary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorPrimary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.my_location_rounded, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('weather_gps_chip'),
                              style: const TextStyle(
                                color: colorPrimaryForest,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              context.currentLanguage == AppLanguage.hi
                                  ? 'वर्तमान जीपीएस स्थान से स्वचालित डेटा लाएं'
                                  : (context.currentLanguage == AppLanguage.hinglish
                                      ? 'Current GPS coordinates se live data load karein'
                                      : 'Auto-detect live coordinates & micro-climate'),
                              style: const TextStyle(color: colorStoneMuted, fontSize: 10.5),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: colorPrimary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // 2. City Search Bar
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (val) {
                        if (val.trim().isNotEmpty) {
                          Navigator.pop(ctx);
                          weatherProv.fetchWeatherForCity(val.trim());
                        }
                      },
                      decoration: InputDecoration(
                        hintText: context.tr('weather_search_hint'),
                        hintStyle: const TextStyle(color: colorStoneMuted, fontSize: 13),
                        prefixIcon: const Icon(Icons.search_rounded, color: colorPrimary, size: 20),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: colorHairline),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: colorHairline),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: colorPrimary, width: 1.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      final val = searchController.text.trim();
                      if (val.isNotEmpty) {
                        Navigator.pop(ctx);
                        weatherProv.fetchWeatherForCity(val);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('Go', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 3. Popular Farming Districts Header
              Text(
                context.currentLanguage == AppLanguage.hi
                    ? 'प्रमुख कृषि जिले (1-टैप चयन)'
                    : (context.currentLanguage == AppLanguage.hinglish
                        ? 'Pramukh Krishi Districts (1-Tap Selection)'
                        : 'Top Agricultural Districts (1-Tap Selection)'),
                style: const TextStyle(
                  color: colorStoneText,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),

              // 4. Wrap of District Chips
              Expanded(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: quickLocations.map((loc) {
                      final cityName = loc['name']!;
                      final stateName = loc['state']!;
                      final isSelected = !weatherProv.isGpsLocation &&
                          weatherProv.locationLabel.toLowerCase().contains(cityName.toLowerCase());

                      return InkWell(
                        onTap: () {
                          Navigator.pop(ctx);
                          weatherProv.fetchWeatherForCity(cityName);
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(
                            color: isSelected ? colorPrimary : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? colorPrimary : colorHairline,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.location_city_rounded,
                                size: 13,
                                color: isSelected ? Colors.white : colorStoneMuted,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '$cityName ($stateName)',
                                style: TextStyle(
                                  color: isSelected ? Colors.white : colorStoneText,
                                  fontSize: 11.5,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // 4. SECTION 02 / THE ESSENTIAL PROTOCOLS (2x2 GRID)
  // ==========================================
  Widget _buildDailyEssentialTools() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text(
                  '02 / ',
                  style: TextStyle(
                    color: colorBronze,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
                Text(
                  context.tr('daily_tools_title'),
                  style: const TextStyle(
                    color: colorStoneText,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
            Text(
              context.tr('daily_tools_sub'),
              style: const TextStyle(
                color: colorStoneMuted,
                fontSize: 9.5,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Grid of 4 Physical Cards
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.85,
          children: [
            _buildDailyToolCard(
              indexNum: '01',
              tag: 'MobileNetV4 · ONNX',
              title: context.tr('tool_crop_doctor_title'),
              subtitle: context.tr('tool_crop_doctor_sub'),
              actionLabel: context.tr('tool_crop_doctor_action'),
              icon: Icons.psychology_outlined,
              iconBg: colorPrimarySoft,
              iconColor: colorPrimary,
              onTap: () => _navigateTo(const DiagnosisScreen()),
            ),
            _buildDailyToolCard(
              indexNum: '02',
              tag: 'Dialect · Sherpa-STT',
              title: context.tr('tool_voice_title'),
              subtitle: context.tr('tool_voice_sub'),
              actionLabel: context.tr('tool_voice_action'),
              icon: Icons.record_voice_over_outlined,
              iconBg: const Color(0xFFFBF5EE),
              iconColor: colorSecondary,
              onTap: () => _navigateTo(const VoiceChatScreen()),
            ),
            _buildDailyToolCard(
              indexNum: '03',
              tag: 'MSP & Spot · USSD',
              title: context.tr('tool_mandi_title'),
              subtitle: context.tr('tool_mandi_sub'),
              actionLabel: context.tr('tool_mandi_action'),
              icon: Icons.candlestick_chart_outlined,
              iconBg: const Color(0xFFF4F6F4),
              iconColor: colorPrimary,
              onTap: () => _navigateTo(const MandiScreen()),
            ),
            _buildDailyToolCard(
              indexNum: '04',
              tag: 'Hologram · Bloom Filter',
              title: context.tr('tool_fertilizer_title'),
              subtitle: context.tr('tool_fertilizer_sub'),
              actionLabel: context.tr('tool_fertilizer_action'),
              icon: Icons.verified_outlined,
              iconBg: colorOchreLight,
              iconColor: colorOchre,
              onTap: () => _navigateTo(const CounterfeitScreen()),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDailyToolCard({
    required String indexNum,
    required String tag,
    required String title,
    required String subtitle,
    required String actionLabel,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colorHairline),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top: Index Number & Icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      indexNum,
                      style: const TextStyle(
                        color: colorBronze,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'monospace',
                      ),
                    ),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: iconBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: iconColor, size: 17),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: const TextStyle(
                    color: colorStoneText,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  tag.toUpperCase(),
                  style: const TextStyle(
                    color: colorStoneMuted,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: colorStoneMuted,
                    fontSize: 10.5,
                    height: 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      actionLabel,
                      style: const TextStyle(
                        color: colorPrimary,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const Text(
                      '→',
                      style: TextStyle(
                        color: colorPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 5. SECTION 03 / NATURAL DIALECT SYNTHESIS
  // ==========================================
  Widget _buildVoiceSaarthiLiveBanner() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text(
                  '03 / ',
                  style: TextStyle(
                    color: colorBronze,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
                Text(
                  context.tr('voice_section_header'),
                  style: const TextStyle(
                    color: colorStoneText,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
            const Text(
              'NPU Low-Latency',
              style: TextStyle(
                color: colorStoneMuted,
                fontSize: 9.5,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Deep Monolith Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0D2418), Color(0xFF153324)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colorBronze.withValues(alpha: 0.35)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: colorBronzeLight,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        context.tr('voice_badge_listening'),
                        style: const TextStyle(
                          color: Color(0xFFEADBCE),
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'monospace',
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Zero Latency',
                      style: TextStyle(
                        color: Color(0xFFD1FAE5),
                        fontSize: 8.5,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                context.tr('banner_quote'),
                style: const TextStyle(
                  color: Color(0xFFFAF8F5),
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                context.tr('banner_hint'),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Delicate Sound Bar Visualizer
                  AnimatedBuilder(
                    animation: waveController,
                    builder: (context, child) {
                      return Row(
                        children: [
                          _buildWaveBar(10 + (waveController.value * 12)),
                          const SizedBox(width: 4),
                          _buildWaveBar(18 - (waveController.value * 10)),
                          const SizedBox(width: 4),
                          _buildWaveBar(8 + (waveController.value * 16)),
                          const SizedBox(width: 4),
                          _buildWaveBar(20 - (waveController.value * 12)),
                          const SizedBox(width: 4),
                          _buildWaveBar(12 + (waveController.value * 8)),
                          const SizedBox(width: 4),
                          _buildWaveBar(6 + (waveController.value * 10)),
                        ],
                      );
                    },
                  ),

                  // Live Talk Pill Button
                  ElevatedButton.icon(
                    onPressed: () => _navigateTo(const VoiceChatScreen()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: colorPrimaryDeep,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      elevation: 0,
                    ),
                    icon: Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    label: Text(
                      context.tr('banner_btn'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                        fontFamily: 'monospace',
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWaveBar(double height) {
    return Container(
      width: 3,
      height: height.clamp(4.0, 22.0),
      decoration: BoxDecoration(
        color: colorBronzeLight,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  // ==========================================
  // 6. SECTION 04 / GAON MESH TELEMETRY & NOTES
  // ==========================================
  Widget _buildGaonMeshNotes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text(
                  '04 / ',
                  style: TextStyle(
                    color: colorBronze,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
                Text(
                  context.tr('mesh_section_header'),
                  style: const TextStyle(
                    color: colorStoneText,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
            Text(
              context.tr('mesh_p2p_relay'),
              style: const TextStyle(
                color: colorStoneMuted,
                fontSize: 9.5,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Dispatches Container
        InkWell(
          onTap: () => _navigateTo(const MeshScreen()),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colorHairline),
            ),
            child: Column(
              children: [
                // Dispatch 1
                Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                context.tr('mesh_dispatch_1_author'),
                                style: const TextStyle(
                                  color: colorPrimary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'monospace',
                                ),
                              ),
                              const Text(' / ', style: TextStyle(color: colorStoneMuted)),
                              Text(
                                context.tr('mesh_dispatch_1_sector'),
                                style: const TextStyle(
                                  color: colorStoneMuted,
                                  fontSize: 9.5,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                          Text(
                            context.tr('mesh_dispatch_1_time'),
                            style: const TextStyle(
                              color: colorStoneMuted,
                              fontSize: 9,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        context.tr('mesh_dispatch_1_text'),
                        style: const TextStyle(
                          color: colorStoneText,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                      SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            'PLOT: 3.8 ACRES',
                            style: TextStyle(
                              color: colorStoneMuted,
                              fontSize: 9,
                              fontFamily: 'monospace',
                            ),
                          ),
                          Text('  •  ', style: TextStyle(color: colorStoneMuted)),
                          Text(
                            'MOISTURE: OPTIMAL (44%)',
                            style: TextStyle(
                              color: colorBronze,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Divider(color: colorHairline, height: 1),

                // Dispatch 2
                Padding(
                  padding: EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                'MUKESH SHARMA',
                                style: TextStyle(
                                  color: colorPrimary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'monospace',
                                ),
                              ),
                              Text(' / ', style: TextStyle(color: colorStoneMuted)),
                              Text(
                                'RAI MANDI ZONE',
                                style: TextStyle(
                                  color: colorStoneMuted,
                                  fontSize: 9.5,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '1 HR AGO',
                            style: TextStyle(
                              color: colorStoneMuted,
                              fontSize: 9,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Rai mandi mein sarson ka bhav ₹5,450/qtl mila aaj. Kisaan bhai dhyan dein.',
                        style: TextStyle(
                          color: colorStoneText,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                      SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            'COMMODITY: MUSTARD',
                            style: TextStyle(
                              color: colorStoneMuted,
                              fontSize: 9,
                              fontFamily: 'monospace',
                            ),
                          ),
                          Text('  •  ', style: TextStyle(color: colorStoneMuted)),
                          Text(
                            '₹5,450 / QTL SPOT',
                            style: TextStyle(
                              color: colorBronze,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Divider(color: colorHairline, height: 1),

                // Footer
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tap to open village mesh radar & notes',
                        style: TextStyle(
                          color: colorStoneMuted,
                          fontSize: 10,
                          fontFamily: 'monospace',
                        ),
                      ),
                      Text(
                        'Mesh Relay →',
                        style: TextStyle(
                          color: colorPrimary,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // 6. SECTION 05 / SPECIALIZED AGRONOMY SUITE (FULL 13 SUITE)
  // ==========================================
  Widget _buildSpecializedAgronomySuite() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text(
                  '05 / ',
                  style: TextStyle(
                    color: colorBronze,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
                Text(
                  context.tr('suite_section_header'),
                  style: const TextStyle(
                    color: colorStoneText,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
            const Text(
              'Extended Operations',
              style: TextStyle(
                color: colorStoneMuted,
                fontSize: 9.5,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Grid of 6 Specialized Tools
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.85,
          children: [
            _buildDailyToolCard(
              indexNum: '05',
              tag: 'Geofence · NDVI',
              title: context.tr('suite_geofencing_title'),
              subtitle: context.tr('suite_geofencing_sub'),
              actionLabel: context.tr('suite_geofencing_action'),
              icon: Icons.satellite_alt_outlined,
              iconBg: const Color(0xFFE8F5E9),
              iconColor: const Color(0xFF2E7D32),
              onTap: () => _navigateTo(const DashboardScreen()),
            ),
            _buildDailyToolCard(
              indexNum: '06',
              tag: 'PMFBY · Satellite',
              title: context.tr('suite_insurance_title'),
              subtitle: context.tr('suite_insurance_sub'),
              actionLabel: context.tr('suite_insurance_action'),
              icon: Icons.security_outlined,
              iconBg: const Color(0xFFEFF6FF),
              iconColor: const Color(0xFF1D4ED8),
              onTap: () => _navigateTo(const InsuranceScreen()),
            ),
            _buildDailyToolCard(
              indexNum: '07',
              tag: 'KVK · NPK Ratio',
              title: context.tr('suite_soil_title'),
              subtitle: context.tr('suite_soil_sub'),
              actionLabel: context.tr('suite_soil_action'),
              icon: Icons.science_outlined,
              iconBg: const Color(0xFFFDF2F8),
              iconColor: const Color(0xFFBE185D),
              onTap: () => _navigateTo(const SoilTestScreen()),
            ),
            _buildDailyToolCard(
              indexNum: '08',
              tag: 'AR Guided · Nozzle',
              title: context.tr('suite_ar_title'),
              subtitle: context.tr('suite_ar_sub'),
              actionLabel: context.tr('suite_ar_action'),
              icon: Icons.view_in_ar_outlined,
              iconBg: const Color(0xFFF5F3FF),
              iconColor: const Color(0xFF6D28D9),
              onTap: () => _navigateTo(const ArSprayScreen()),
            ),
            _buildDailyToolCard(
              indexNum: '09',
              tag: '*99# · SMS Bridge',
              title: context.tr('suite_ussd_title'),
              subtitle: context.tr('suite_ussd_sub'),
              actionLabel: context.tr('suite_ussd_action'),
              icon: Icons.cell_tower_outlined,
              iconBg: const Color(0xFFFFFBEB),
              iconColor: const Color(0xFFB45309),
              onTap: () => _navigateTo(const UssdSmsScreen()),
            ),
            _buildDailyToolCard(
              indexNum: '10',
              tag: 'Ledger · Drone Hub',
              title: context.tr('suite_hub_title'),
              subtitle: context.tr('suite_hub_sub'),
              actionLabel: context.tr('suite_hub_action'),
              icon: Icons.precision_manufacturing_outlined,
              iconBg: const Color(0xFFF1F5F9),
              iconColor: const Color(0xFF334155),
              onTap: () => _navigateTo(const SettingsScreen()),
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================
  // 7. FLOATING BOTTOM NAVIGATION DOCK
  // ==========================================
  Widget _buildFloatingBottomDock() {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: colorHairline),
        boxShadow: [
          BoxShadow(
            color: colorPrimary.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // 1. Home
          _buildDockItem(
            icon: Icons.yard_rounded,
            label: context.tr('dock_home'),
            isActive: true,
            onTap: () {},
          ),

          // 2. Mandi
          _buildDockItem(
            icon: Icons.storefront_rounded,
            label: context.tr('dock_mandi'),
            isActive: false,
            onTap: () => _navigateTo(const MandiScreen()),
          ),

          // 3. Center Elevated AI Scan Button
          GestureDetector(
            onTap: () => _navigateTo(const DiagnosisScreen()),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.translate(
                  offset: const Offset(0, -12),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [colorPrimary, colorPrimaryLight],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colorPrimary.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: Colors.white, width: 2.5),
                    ),
                    child: const Icon(Icons.document_scanner_rounded, color: Color(0xFFFDE68A), size: 22),
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -8),
                  child: Text(
                    context.tr('dock_ai_scan'),
                    style: const TextStyle(
                      color: colorPrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 4. Mesh
          _buildDockItem(
            icon: Icons.hub_rounded,
            label: context.tr('dock_mesh'),
            isActive: false,
            onTap: () => _navigateTo(const MeshScreen()),
          ),

          // 5. More Features Menu
          _buildDockItem(
            icon: Icons.grid_view_rounded,
            label: context.tr('dock_13_features'),
            isActive: false,
            onTap: _showFeaturesDrawer,
          ),
        ],
      ),
    );
  }

  Widget _buildDockItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive ? colorPrimary : colorStoneMuted,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: isActive ? colorPrimary : colorStoneMuted,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 7. KISAN AI FLOATING BUTTON (FAB)
  // ==========================================
  Widget _buildKisanAiFab() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorPrimary.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: _showKisanAiModal,
        style: ElevatedButton.styleFrom(
          backgroundColor: colorPrimary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: const Color(0xFFFDE68A).withValues(alpha: 0.4)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          elevation: 0,
        ),
        icon: Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFFFDE68A), size: 16),
        ),
        label: const Text(
          'Kisan AI ✨',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ),
    );
  }

  // ==========================================
  // 8. 13 FEATURES OFF-CANVAS SHEET
  // ==========================================
  void _showFeaturesDrawer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.88,
          decoration: const BoxDecoration(
            color: colorBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: const BoxDecoration(
                  color: colorSurface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border(bottom: BorderSide(color: colorHairline)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: colorPrimarySoft,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.grid_view_rounded, color: colorPrimary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('drawer_title'),
                              style: const TextStyle(
                                color: colorPrimary,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              context.tr('drawer_sub'),
                              style: const TextStyle(color: colorStoneMuted, fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: colorStoneMuted),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Feature List
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildFeatureTile(
                      code: 'F-01',
                      title: context.tr('drawer_f1_title'),
                      desc: context.tr('drawer_f1_desc'),
                      onTap: () {
                        Navigator.pop(context);
                        _navigateTo(const DiagnosisScreen());
                      },
                    ),
                    _buildFeatureTile(
                      code: 'F-02',
                      title: context.tr('drawer_f2_title'),
                      desc: context.tr('drawer_f2_desc'),
                      onTap: () {
                        Navigator.pop(context);
                        _navigateTo(const VoiceChatScreen());
                      },
                    ),
                    _buildFeatureTile(
                      code: 'F-03',
                      title: context.tr('drawer_f3_title'),
                      desc: context.tr('drawer_f3_desc'),
                      onTap: () {
                        Navigator.pop(context);
                        _navigateTo(const VoiceChatScreen());
                      },
                    ),
                    _buildFeatureTile(
                      code: 'F-04',
                      title: context.tr('drawer_f4_title'),
                      desc: context.tr('drawer_f4_desc'),
                      onTap: () {
                        Navigator.pop(context);
                        _navigateTo(const MeshScreen());
                      },
                    ),
                    _buildFeatureTile(
                      code: 'F-05',
                      title: context.tr('drawer_f5_title'),
                      desc: context.tr('drawer_f5_desc'),
                      onTap: () {
                        Navigator.pop(context);
                        _navigateTo(const DashboardScreen());
                      },
                    ),
                    _buildFeatureTile(
                      code: 'F-06',
                      title: context.tr('drawer_f6_title'),
                      desc: context.tr('drawer_f6_desc'),
                      onTap: () {
                        Navigator.pop(context);
                        _navigateTo(const MandiScreen());
                      },
                    ),
                    _buildFeatureTile(
                      code: 'F-07',
                      title: context.tr('drawer_f7_title'),
                      desc: context.tr('drawer_f7_desc'),
                      onTap: () {
                        Navigator.pop(context);
                        _navigateTo(const CounterfeitScreen());
                      },
                    ),
                    _buildFeatureTile(
                      code: 'F-08',
                      title: context.tr('drawer_f8_title'),
                      desc: context.tr('drawer_f8_desc'),
                      onTap: () {
                        Navigator.pop(context);
                        _navigateTo(const InsuranceScreen());
                      },
                    ),
                    _buildFeatureTile(
                      code: 'F-09',
                      title: context.tr('drawer_f9_title'),
                      desc: context.tr('drawer_f9_desc'),
                      onTap: () {
                        Navigator.pop(context);
                        _navigateTo(const DashboardScreen());
                      },
                    ),
                    _buildFeatureTile(
                      code: 'F-10',
                      title: context.tr('drawer_f10_title'),
                      desc: context.tr('drawer_f10_desc'),
                      onTap: () {
                        Navigator.pop(context);
                        _navigateTo(const SoilTestScreen());
                      },
                    ),
                    _buildFeatureTile(
                      code: 'F-11',
                      title: context.tr('drawer_f11_title'),
                      desc: context.tr('drawer_f11_desc'),
                      onTap: () {
                        Navigator.pop(context);
                        _navigateTo(const ArSprayScreen());
                      },
                    ),
                    _buildFeatureTile(
                      code: 'F-12',
                      title: context.tr('drawer_f12_title'),
                      desc: context.tr('drawer_f12_desc'),
                      onTap: () {
                        Navigator.pop(context);
                        _navigateTo(const UssdSmsScreen());
                      },
                    ),
                    _buildFeatureTile(
                      code: 'F-13',
                      title: context.tr('drawer_f13_title'),
                      desc: context.tr('drawer_f13_desc'),
                      onTap: () {
                        Navigator.pop(context);
                        _navigateTo(const SettingsScreen());
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFeatureTile({
    required String code,
    required String title,
    required String desc,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: colorCard,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorHairline),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: colorPrimarySoft,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    code,
                    style: const TextStyle(
                      color: colorPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: colorStoneText,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        desc,
                        style: const TextStyle(
                          color: colorStoneMuted,
                          fontSize: 11,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: colorStoneMuted, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 9. LANGUAGE PICKER MODAL
  // ==========================================
  void _showLanguagePicker() {
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: colorSurface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.language_rounded, color: colorPrimary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        context.tr('choose_language'),
                        style: const TextStyle(
                          color: colorStoneText,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: colorStoneMuted),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: AppLanguage.values
                      .map((l) => _buildLangOption(l, langProvider))
                      .toList(),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLangOption(AppLanguage lang, LanguageProvider langProvider) {
    final bool isSelected = langProvider.currentLanguage == lang;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isSelected ? colorPrimarySoft : Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            langProvider.setLanguage(lang);
            Navigator.pop(context);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isSelected ? colorPrimary : colorHairline),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colorHairline),
                  ),
                  child: Center(
                    child: Text(
                      lang.badge,
                      style: const TextStyle(
                        color: colorPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lang.displayName,
                        style: const TextStyle(
                          color: colorStoneText,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        lang.subTitle,
                        style: const TextStyle(color: colorStoneMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle_rounded, color: colorPrimary, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 10. GOOGLE PROFILE MODAL
  // ==========================================
  void _showProfileModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: colorSurface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: colorPrimarySoft,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text(
                        'RS',
                        style: TextStyle(
                          color: colorPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rameshwar Singh',
                          style: TextStyle(
                            color: colorStoneText,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'rameshwar.kisan@gmail.com',
                          style: TextStyle(color: colorStoneMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: colorStoneMuted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: colorHairline),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.place_rounded, color: colorPrimary),
                title: const Text('Kisan Profile', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                subtitle: const Text('Murthal, Sonipat · 4.2 Acres Gehu', style: TextStyle(fontSize: 11)),
                onTap: () {
                  Navigator.pop(context);
                  _navigateTo(const DashboardScreen());
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.history_edu_rounded, color: colorSecondary),
                title: const Text('Activity History', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                subtitle: const Text('18 Leaf Scans · 6 Mandi alerts · 3 Mesh transfers', style: TextStyle(fontSize: 11)),
                onTap: () {
                  Navigator.pop(context);
                  _navigateTo(const InsuranceScreen());
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.settings_rounded, color: colorStoneMuted),
                title: const Text('Account & Offline Settings', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                onTap: () {
                  Navigator.pop(context);
                  _navigateTo(const SettingsScreen());
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // 11. KISAN AI CHATBOT MODAL
  // ==========================================
  void _showKisanAiModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return const _KisanAiSheet();
      },
    );
  }
}

/// Interactive Kisan AI Assistant Modal Sheet
class _KisanAiSheet extends StatefulWidget {
  const _KisanAiSheet();

  @override
  State<_KisanAiSheet> createState() => _KisanAiSheetState();
}

class _KisanAiSheetState extends State<_KisanAiSheet> {
  final TextEditingController _textController = TextEditingController();
  final List<Map<String, String>> _messages = [
    {
      'role': 'user',
      'text': 'गेहूं में पीला रतुआ (Yellow Rust) के लक्षण दिखे तो बिना इंटरनेट क्या तुरंत उपाय करें?',
    },
    {
      'role': 'ai',
      'text':
          'रामेश्वर जी, मुरथल क्षेत्र में आर्द्रता 42% है। पीला रतुआ के लिए प्रोपिकोनाज़ोल 25% EC (200 मिली प्रति 200 ली पानी) या 5% नीम तेल का छिड़काव दोपहर 3 बजे से पहले करें।',
    },
  ];

  void _sendMessage(String query) {
    if (query.trim().isEmpty) return;
    setState(() {
      _messages.add({'role': 'user', 'text': query.trim()});
      _messages.add({
        'role': 'ai',
        'text':
            'रामेश्वर जी, आपके प्रश्न पर परामर्श: खेत में नमी 42% है। अगले 4 घंटे में बारिश होने की संभावना है, इसलिए कीटनाशक या यूरिया का छिड़काव बारिश थमने तक स्थगित रखें। अधिक जानकारी के लिए "लाइव बात करें" टैप करें।',
      });
    });
    _textController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Color(0xFFF8F7F4),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFFDFBF7),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(bottom: BorderSide(color: Color(0xFFE7E4DC))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.psychology_rounded, color: Color(0xFF1B4332), size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Kisan AI Assistant',
                      style: TextStyle(
                        color: Color(0xFF1B4332),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const VoiceChatScreen()),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFF59E0B)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.mic_rounded, size: 14, color: Color(0xFF92400E)),
                            SizedBox(width: 4),
                            Text(
                              'Live Talk',
                              style: TextStyle(
                                color: Color(0xFF92400E),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF6E756F)),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Suggestion Chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildChip('🌾 पीला रतुआ लक्षण', () {
                    _sendMessage('पीला रतुआ (Yellow Rust) के शुरुआती लक्षण क्या हैं?');
                  }),
                  const SizedBox(width: 8),
                  _buildChip('💧 गेहूं में दूसरी सिंचाई', () {
                    _sendMessage('गेहूं में दूसरी सिंचाई कब करनी चाहिए?');
                  }),
                  const SizedBox(width: 8),
                  _buildChip('💰 आज का मंडी भाव', () {
                    _sendMessage('सोनीपत मंडी में आज गेहूं और सरसों का क्या भाव है?');
                  }),
                ],
              ),
            ),
          ),

          // Message Stream
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isUser ? const Color(0xFF1B4332) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: isUser ? null : Border.all(color: const Color(0xFFE7E4DC)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isUser) ...[
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Kisan AI Saarthi',
                                style: TextStyle(
                                  color: Color(0xFF1B4332),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                '⚡ Local AI INT4',
                                style: TextStyle(
                                  color: Color(0xFF6E756F),
                                  fontSize: 9,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                        ],
                        Text(
                          msg['text']!,
                          style: TextStyle(
                            color: isUser ? Colors.white : const Color(0xFF1E2420),
                            fontSize: 13,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Input Form
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFFFDFBF7),
              border: Border(top: BorderSide(color: Color(0xFFE7E4DC))),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.photo_camera_rounded, color: Color(0xFF6E756F)),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const DiagnosisScreen()),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.mic_rounded, color: Color(0xFF6E756F)),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const VoiceChatScreen()),
                    );
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: 'अपनी बोली में पूछें / Ask offline...',
                      hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF6E756F)),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: Color(0xFFE7E4DC)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: Color(0xFFE7E4DC)),
                      ),
                    ),
                    onSubmitted: _sendMessage,
                  ),
                ),
                const SizedBox(width: 6),
                IconButton.filled(
                  icon: const Icon(Icons.send_rounded, size: 18),
                  style: IconButton.styleFrom(backgroundColor: const Color(0xFF1B4332)),
                  onPressed: () => _sendMessage(_textController.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFFDFBF7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE7E4DC)),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF1E2420)),
        ),
      ),
    );
  }
}
