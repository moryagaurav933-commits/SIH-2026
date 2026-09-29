import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../localization/app_language.dart';
import '../localization/app_translations.dart';
import '../providers/language_provider.dart';
import '../providers/weather_provider.dart';
import 'diagnosis/diagnosis_screen.dart';
import 'weather/weather_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'mandi/mandi_screen.dart';
import 'voice_chat/voice_chat_screen.dart';
import 'insurance/insurance_screen.dart';
import 'dashboard/dashboard_screen.dart';
import 'settings/settings_screen.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestStartupPermissions();
    });
  }

  Future<void> _requestStartupPermissions() async {
    if (kIsWeb) return;
    try {
      LocationPermission locPerm = await Geolocator.checkPermission();
      if (locPerm == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      await [
        Permission.camera,
        Permission.microphone,
        Permission.location,
      ].request();
    } catch (e) {
      debugPrint('Startup permissions notice: $e');
    }
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
          onTap: _showCropSelectionModal,
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
                              const SizedBox(width: 4),
                              const Text(
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

        // Grid of 2 Physical Cards
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.88,
          children: [
            _buildDailyToolCard(
              indexNum: '01',
              tag: 'MSP & Spot · Live',
              title: context.tr('tool_mandi_title'),
              subtitle: context.tr('tool_mandi_sub'),
              actionLabel: context.tr('tool_mandi_action'),
              icon: Icons.candlestick_chart_outlined,
              iconBg: const Color(0xFFF4F6F4),
              iconColor: colorPrimary,
              onTap: () => _navigateTo(const MandiScreen()),
            ),
            _buildDailyToolCard(
              indexNum: '02',
              tag: 'IMD · Agro Forecast',
              title: context.currentLanguage == AppLanguage.hi
                  ? 'मौसम एवं कृषि सलाह'
                  : (context.currentLanguage == AppLanguage.hinglish
                      ? 'Mausam Salah'
                      : 'Weather Advisory'),
              subtitle: context.currentLanguage == AppLanguage.hi
                  ? 'स्थानीय मौसम पूर्वानुमान और फसल चक्र परामर्श।'
                  : (context.currentLanguage == AppLanguage.hinglish
                      ? 'Hyperlocal mausam forecast aur fasal sifarish.'
                      : 'Hyperlocal forecast and crop cycle advisories.'),
              actionLabel: context.currentLanguage == AppLanguage.hi
                  ? 'मौसम देखें'
                  : (context.currentLanguage == AppLanguage.hinglish
                      ? 'Mausam Dekhein'
                      : 'View Weather'),
              icon: Icons.wb_sunny_outlined,
              iconBg: colorOchreLight,
              iconColor: colorOchre,
              onTap: () => _navigateTo(const WeatherScreen()),
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
  // 5. SECTION 03 / SPECIALIZED AGRONOMY SUITE
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
                  '03 / ',
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

        // Specialized Insurance Evidence Locker Card
        InkWell(
          onTap: () => _navigateTo(const InsuranceScreen()),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(16),
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
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.security_outlined,
                    color: Color(0xFF1D4ED8),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'PMFBY · SATELLITE & GPS',
                              style: TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'monospace',
                                color: Color(0xFF1D4ED8),
                              ),
                            ),
                          ),
                          const Spacer(),
                          const Text(
                            '03',
                            style: TextStyle(
                              color: colorStoneMuted,
                              fontSize: 11,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        context.tr('suite_insurance_title'),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: colorStoneText,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        context.tr('suite_insurance_sub'),
                        style: const TextStyle(
                          fontSize: 11,
                          color: colorStoneMuted,
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: colorPrimary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // 7. FLOATING BOTTOM NAVIGATION DOCK
  // ==========================================
  Widget _buildFloatingBottomDock() {
    return Container(
      height: 66,
      padding: const EdgeInsets.symmetric(horizontal: 4),
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
        children: [
          // 1. Home / Khet
          Expanded(
            child: _buildDockItem(
              icon: Icons.yard_rounded,
              label: context.tr('dock_home'),
              isActive: true,
              onTap: () {},
            ),
          ),

          // 2. Mandi
          Expanded(
            child: _buildDockItem(
              icon: Icons.storefront_rounded,
              label: context.tr('dock_mandi'),
              isActive: false,
              onTap: () => _navigateTo(const MandiScreen()),
            ),
          ),

          // 3. Center Elevated AI Scan Button
          SizedBox(
            width: 68,
            child: GestureDetector(
              onTap: _showCropSelectionModal,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Transform.translate(
                    offset: const Offset(0, -10),
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [colorPrimary, colorPrimaryLight],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
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
                      child: const Icon(Icons.document_scanner_rounded, color: Color(0xFFFDE68A), size: 21),
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(0, -7),
                    child: Text(
                      context.tr('dock_ai_scan'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: colorPrimary,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4. Community
          Expanded(
            child: _buildDockItem(
              icon: Icons.groups_rounded,
              label: context.tr('dock_community'),
              isActive: false,
              onTap: _showKrishiCommunityModal,
            ),
          ),

          // 5. More Features Menu
          Expanded(
            child: _buildDockItem(
              icon: Icons.grid_view_rounded,
              label: context.tr('dock_13_features'),
              isActive: false,
              onTap: _showFeaturesDrawer,
            ),
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
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive ? colorPrimary : colorStoneMuted,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isActive ? colorPrimary : colorStoneMuted,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: -0.1,
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
  // KRISHI COMMUNITY MODAL BOTTOM SHEET
  // ==========================================
  void _showKrishiCommunityModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.78,
          decoration: const BoxDecoration(
            color: colorBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Grab Handle
              const SizedBox(height: 10),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colorHairline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 10),

              // Modal Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: const BoxDecoration(
                  color: colorSurface,
                  border: Border(bottom: BorderSide(color: colorHairline)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: colorPrimarySoft,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: colorPrimary.withValues(alpha: 0.2)),
                          ),
                          child: const Icon(Icons.groups_rounded, color: colorPrimary, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('community_modal_title'),
                              style: const TextStyle(
                                color: colorPrimaryForest,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              context.tr('community_modal_sub'),
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

              // Content Body
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(18),
                  children: [
                    // Status Badge Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: colorHairline),
                        boxShadow: [
                          BoxShadow(
                            color: colorPrimary.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'KRISHI COMMUNITY HUB · READY',
                                style: TextStyle(
                                  color: colorPrimary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'monospace',
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            context.currentLanguage == AppLanguage.hi
                                ? 'कृषि कम्युनिटी हब सक्रिय है। आपके आगामी निर्देशों के लिए तैयार!'
                                : (context.currentLanguage == AppLanguage.hinglish
                                    ? 'Krishi Community Hub active hai! Aapke agle instructions ke liye tayyar.'
                                    : 'Krishi Community Hub is active! Standing by for your instructions.'),
                            style: const TextStyle(
                              color: colorStoneText,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            context.currentLanguage == AppLanguage.hi
                                ? 'यहाँ किसान भाई आपस में फसल अनुभव, मंडी भाव, रोग नियंत्रण और सामूहिक कृषि रणनीतियों पर परस्पर संवाद कर सकेंगे।'
                                : (context.currentLanguage == AppLanguage.hinglish
                                    ? 'Yahan kisaan bhai aapas mein fasal anubhav, mandi bhav, beemari roktham aur group advisory share kar sakenge.'
                                    : 'A dedicated interactive forum where farmers exchange field crop experiences, real-time APMC price insights, and pest management strategies.'),
                            style: const TextStyle(
                              color: colorStoneMuted,
                              fontSize: 11.5,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Feature Placeholders for upcoming instructions
                    _buildCommunityFeatureCard(
                      icon: Icons.forum_outlined,
                      iconBg: const Color(0xFFE8F5E9),
                      iconColor: colorPrimary,
                      title: context.currentLanguage == AppLanguage.hi
                          ? 'किसान संवाद चर्चा (Kisan Charcha)'
                          : (context.currentLanguage == AppLanguage.hinglish
                              ? 'Kisan Charcha • Open Discussions'
                              : 'Farmer Discussion Forum'),
                      subtitle: context.currentLanguage == AppLanguage.hi
                          ? 'स्थानीय किसानों से अपने गांव और क्षेत्र के सवाल-जवाब'
                          : (context.currentLanguage == AppLanguage.hinglish
                              ? 'Aapke gaon aur zila ke kisaano ke saath live prashn-uttar'
                              : 'Live Q&A and local farming queries across villages'),
                    ),
                    const SizedBox(height: 10),

                    _buildCommunityFeatureCard(
                      icon: Icons.trending_up_rounded,
                      iconBg: const Color(0xFFFFF8E1),
                      iconColor: colorOchre,
                      title: context.currentLanguage == AppLanguage.hi
                          ? 'मंडी व्यापार अनुभव (Peer Price Intel)'
                          : (context.currentLanguage == AppLanguage.hinglish
                              ? 'Mandi Vyapar • Peer Insights'
                              : 'Mandi Trade Intel & Feedback'),
                      subtitle: context.currentLanguage == AppLanguage.hi
                          ? 'किस मंडी में आज क्या रेट मिला, किसानों द्वारा सीधा अपडेट'
                          : (context.currentLanguage == AppLanguage.hinglish
                              ? 'Kis mandi mein sarson, gehu ka bhav kya mila direct farmer update'
                              : 'Verified real spot price reports directly from fellow farmers'),
                    ),
                    const SizedBox(height: 10),

                    _buildCommunityFeatureCard(
                      icon: Icons.support_agent_rounded,
                      iconBg: const Color(0xFFEFF6FF),
                      iconColor: const Color(0xFF1D4ED8),
                      title: context.currentLanguage == AppLanguage.hi
                          ? 'विशेषज्ञ परामर्श एवं सहायता'
                          : (context.currentLanguage == AppLanguage.hinglish
                              ? 'Krishi Salahkar & Expert Advice'
                              : 'Agronomist & Expert Helpdesk'),
                      subtitle: context.currentLanguage == AppLanguage.hi
                          ? 'कृषि वैज्ञानिकों व अग्रणी किसानों द्वारा सत्यापित समाधान'
                          : (context.currentLanguage == AppLanguage.hinglish
                              ? 'ICAR aur Krishi Vigyan Kendra ke verified crop protocols'
                              : 'Verified crop protocols backed by ICAR and agri experts'),
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

  Widget _buildCommunityFeatureCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorHairline),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
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
                  subtitle,
                  style: const TextStyle(
                    color: colorStoneMuted,
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
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
                        _showCropSelectionModal();
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
                      title: context.tr('drawer_f2_title'),
                      desc: context.tr('drawer_f2_desc'),
                      onTap: () {
                        Navigator.pop(context);
                        _navigateTo(const VoiceChatScreen());
                      },
                    ),
                    _buildFeatureTile(
                      code: 'F-04',
                      title: context.tr('dock_community'),
                      desc: context.tr('community_modal_sub'),
                      onTap: () {
                        Navigator.pop(context);
                        _showKrishiCommunityModal();
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
                      title: context.tr('drawer_f8_title'),
                      desc: context.tr('drawer_f8_desc'),
                      onTap: () {
                        Navigator.pop(context);
                        _navigateTo(const InsuranceScreen());
                      },
                    ),
                    _buildFeatureTile(
                      code: 'F-08',
                      title: context.tr('drawer_f9_title'),
                      desc: context.tr('drawer_f9_desc'),
                      onTap: () {
                        Navigator.pop(context);
                        _navigateTo(const DashboardScreen());
                      },
                    ),
                    _buildFeatureTile(
                      code: 'F-09',
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
  // 8.5 CROP SELECTION MODAL FOR AI SCAN
  // ==========================================
  void _showCropSelectionModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
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
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorPrimarySoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.biotech_rounded, color: colorPrimary, size: 24),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('crop_selection_title'),
                            style: const TextStyle(
                              color: colorStoneText,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Text(
                            'MobileNetV3 Neural Engine • 96.3% Acc',
                            style: TextStyle(
                              color: colorStoneMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: colorStoneMuted),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                context.tr('crop_selection_desc'),
                style: const TextStyle(color: colorStoneMuted, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    _buildCropOptionTile(
                      emoji: '🍅',
                      cropName: context.tr('crop_tomato'),
                      cropKey: 'tomato',
                      classesInfo: '10 Classes',
                      diseases: 'Septoria, Early/Late Blight, Yellow Curl, Spider Mites...',
                      accentColor: const Color(0xFFE53935),
                      onTap: () {
                        Navigator.pop(ctx);
                        _navigateTo(const DiagnosisScreen(selectedCrop: 'tomato'));
                      },
                    ),
                    _buildCropOptionTile(
                      emoji: '🥔',
                      cropName: context.tr('crop_potato'),
                      cropKey: 'potato',
                      classesInfo: '3 Classes',
                      diseases: 'Early Blight, Late Blight, Healthy Foliage',
                      accentColor: const Color(0xFF8D6E63),
                      onTap: () {
                        Navigator.pop(ctx);
                        _navigateTo(const DiagnosisScreen(selectedCrop: 'potato'));
                      },
                    ),
                    _buildCropOptionTile(
                      emoji: '🌽',
                      cropName: context.tr('crop_corn'),
                      cropKey: 'corn',
                      classesInfo: '4 Classes',
                      diseases: 'Common Rust, Northern Leaf Blight, Gray Leaf Spot...',
                      accentColor: const Color(0xFFF57F17),
                      onTap: () {
                        Navigator.pop(ctx);
                        _navigateTo(const DiagnosisScreen(selectedCrop: 'corn'));
                      },
                    ),
                    _buildCropOptionTile(
                      emoji: '🍎',
                      cropName: context.tr('crop_apple'),
                      cropKey: 'apple',
                      classesInfo: '4 Classes',
                      diseases: 'Apple Scab, Black Rot, Cedar Apple Rust, Healthy...',
                      accentColor: const Color(0xFFD32F2F),
                      onTap: () {
                        Navigator.pop(ctx);
                        _navigateTo(const DiagnosisScreen(selectedCrop: 'apple'));
                      },
                    ),
                    _buildCropOptionTile(
                      emoji: '🥜',
                      cropName: context.tr('crop_cashew'),
                      cropKey: 'cashew',
                      classesInfo: '3 Classes',
                      diseases: 'Leaf Miner, Red Rust, Healthy Leaves',
                      accentColor: const Color(0xFF8D6E63),
                      onTap: () {
                        Navigator.pop(ctx);
                        _navigateTo(const DiagnosisScreen(selectedCrop: 'cashew'));
                      },
                    ),
                    _buildCropOptionTile(
                      emoji: '🌿',
                      cropName: context.tr('crop_cassava'),
                      cropKey: 'cassava',
                      classesInfo: '3 Classes',
                      diseases: 'Cassava Mosaic (CMD), Brown Spot, Healthy',
                      accentColor: const Color(0xFF2E7D32),
                      onTap: () {
                        Navigator.pop(ctx);
                        _navigateTo(const DiagnosisScreen(selectedCrop: 'cassava'));
                      },
                    ),
                    _buildCropOptionTile(
                      emoji: '🌶️',
                      cropName: context.tr('crop_chilli'),
                      cropKey: 'chilli',
                      classesInfo: '3 Classes',
                      diseases: 'White Spot, Nutrient Deficit, Healthy Chilli',
                      accentColor: const Color(0xFFE53935),
                      onTap: () {
                        Navigator.pop(ctx);
                        _navigateTo(const DiagnosisScreen(selectedCrop: 'chilli'));
                      },
                    ),
                    _buildCropOptionTile(
                      emoji: '☁️',
                      cropName: context.tr('crop_cotton'),
                      cropKey: 'cotton',
                      classesInfo: '3 Classes',
                      diseases: 'Bacterial Blight, Leaf Curl (CLCuV), Healthy',
                      accentColor: const Color(0xFF546E7A),
                      onTap: () {
                        Navigator.pop(ctx);
                        _navigateTo(const DiagnosisScreen(selectedCrop: 'cotton'));
                      },
                    ),
                    _buildCropOptionTile(
                      emoji: '🍇',
                      cropName: context.tr('crop_grape'),
                      cropKey: 'grape',
                      classesInfo: '3 Classes',
                      diseases: 'Black Rot, Leaf Blight, Healthy Grape Vines',
                      accentColor: const Color(0xFF6A1B9A),
                      onTap: () {
                        Navigator.pop(ctx);
                        _navigateTo(const DiagnosisScreen(selectedCrop: 'grape'));
                      },
                    ),
                    _buildCropOptionTile(
                      emoji: '🥜',
                      cropName: context.tr('crop_groundnut'),
                      cropKey: 'groundnut',
                      classesInfo: '3 Classes',
                      diseases: 'Late Leaf Spot (Tikka), Iron Chlorosis, Healthy',
                      accentColor: const Color(0xFFFB8C00),
                      onTap: () {
                        Navigator.pop(ctx);
                        _navigateTo(const DiagnosisScreen(selectedCrop: 'groundnut'));
                      },
                    ),
                    _buildCropOptionTile(
                      emoji: '🍈',
                      cropName: context.tr('crop_papaya'),
                      cropKey: 'papaya',
                      classesInfo: '3 Classes',
                      diseases: 'Ring Spot Virus, Bacterial Spot, Healthy',
                      accentColor: const Color(0xFF43A047),
                      onTap: () {
                        Navigator.pop(ctx);
                        _navigateTo(const DiagnosisScreen(selectedCrop: 'papaya'));
                      },
                    ),
                    _buildCropOptionTile(
                      emoji: '🌱',
                      cropName: context.tr('crop_soybean'),
                      cropKey: 'soybean',
                      classesInfo: '3 Classes',
                      diseases: 'Defoliating Caterpillar, Leaf Beetle, Healthy',
                      accentColor: const Color(0xFF7CB342),
                      onTap: () {
                        Navigator.pop(ctx);
                        _navigateTo(const DiagnosisScreen(selectedCrop: 'soybean'));
                      },
                    ),
                    _buildCropOptionTile(
                      emoji: '🌾',
                      cropName: context.tr('crop_all'),
                      cropKey: 'all',
                      classesInfo: '45 Classes',
                      diseases: 'Universal Auto-Detect Optical Scan across all 12 crops (Dual V1+V2)',
                      accentColor: colorPrimary,
                      onTap: () {
                        Navigator.pop(ctx);
                        _navigateTo(const DiagnosisScreen(selectedCrop: 'all'));
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

  Widget _buildCropOptionTile({
    required String emoji,
    required String cropName,
    required String cropKey,
    required String classesInfo,
    required String diseases,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorHairline),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(emoji, style: const TextStyle(fontSize: 24)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            cropName,
                            style: const TextStyle(
                              color: colorStoneText,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              classesInfo,
                              style: TextStyle(
                                color: accentColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        diseases,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: colorStoneMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: colorStoneMuted),
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
  // 11. KISAN AI CHATBOT MODAL (KRISHI COPILOT)
  // ==========================================
  void _showKisanAiModal() {
    _navigateTo(const VoiceChatScreen());
  }
}


