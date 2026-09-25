import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/weather_mandi_service.dart';
import '../../utils/design_tokens.dart';

/// Feature 6B — Agmarknet Live Mandi Market Prices
/// Official Agmarknet integration, closest mandi proximity detection,
/// interactive mandi switcher palette, top crop filters, and quantity-by-price cards.
class MandiScreen extends StatefulWidget {
  const MandiScreen({super.key});

  @override
  State<MandiScreen> createState() => _MandiScreenState();
}

class _MandiScreenState extends State<MandiScreen> {
  final MandiService _mandiService = MandiService();
  
  MandiLocation? _currentMandi;
  List<MandiLocation> _allMandis = [];
  List<MandiPrice> _prices = [];
  
  bool _isLoading = true;
  bool _isLocationLoading = false;
  String _searchQuery = '';
  String _selectedCropFilter = 'ALL';
  
  double? _userLat;
  double? _userLon;
  
  final TextEditingController _searchController = TextEditingController();

  static const List<Map<String, String>> _cropFilterCategories = [
    {'key': 'ALL', 'label': 'सभी', 'sub': 'All Crops', 'icon': '🌾'},
    {'key': 'Wheat', 'label': 'गेहूं', 'sub': 'Wheat', 'icon': '🌾'},
    {'key': 'Paddy / Rice', 'label': 'धान / चावल', 'sub': 'Rice', 'icon': '🍚'},
    {'key': 'Maize', 'label': 'मक्का', 'sub': 'Maize', 'icon': '🌽'},
    {'key': 'Mustard', 'label': 'सरसों', 'sub': 'Mustard', 'icon': '🟡'},
    {'key': 'Soybean', 'label': 'सोयाबीन', 'sub': 'Soybean', 'icon': '🌱'},
    {'key': 'Cotton', 'label': 'कपास', 'sub': 'Cotton', 'icon': '☁️'},
    {'key': 'Gram / Chana', 'label': 'चना', 'sub': 'Chana', 'icon': '🟤'},
    {'key': 'Tomato', 'label': 'टमाटर', 'sub': 'Tomato', 'icon': '🍅'},
    {'key': 'Onion', 'label': 'प्याज', 'sub': 'Onion', 'icon': '🧅'},
    {'key': 'Potato', 'label': 'आलू', 'sub': 'Potato', 'icon': '🥔'},
    {'key': 'Garlic', 'label': 'लहसुन', 'sub': 'Garlic', 'icon': '🧄'},
    {'key': 'Sugarcane', 'label': 'गन्ना', 'sub': 'Sugarcane', 'icon': '🎋'},
  ];

  @override
  void initState() {
    super.initState();
    _initializeMandiData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeMandiData() async {
    setState(() {
      _isLoading = true;
      _isLocationLoading = true;
    });

    // 1. Try to acquire GPS location for closest mandi calculation
    try {
      final hasPermission = await _checkLocationPermission();
      if (hasPermission) {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 4),
          ),
        );
        _userLat = position.latitude;
        _userLon = position.longitude;
      }
    } catch (e) {
      debugPrint('Mandi GPS location fallback: $e');
    }

    if (mounted) {
      setState(() => _isLocationLoading = false);
    }

    // 2. Fetch Mandis list sorted by distance
    final mandis = await _mandiService.getMandis(lat: _userLat, lon: _userLon);
    final closest = mandis.isNotEmpty ? mandis.first : MandiService.defaultMandis.first;

    if (mounted) {
      setState(() {
        _allMandis = mandis;
        _currentMandi = closest;
      });
      await _loadPrices(mandiId: closest.id);
    }
  }

  Future<bool> _checkLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    return permission != LocationPermission.deniedForever;
  }

  Future<void> _loadPrices({String? mandiId}) async {
    setState(() => _isLoading = true);
    final targetId = mandiId ?? _currentMandi?.id ?? 'UP_LUCKNOW';
    
    final prices = await _mandiService.getPrices(
      mandiId: targetId,
      lat: _userLat,
      lon: _userLon,
    );

    if (mounted) {
      setState(() {
        _prices = prices;
        _isLoading = false;
      });
    }
  }

  void _switchMandi(MandiLocation mandi) {
    setState(() {
      _currentMandi = mandi;
    });
    _loadPrices(mandiId: mandi.id);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _getFilteredPrices();

    return Scaffold(
      backgroundColor: colorBg,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // 1. Closest Mandi Hero Switcher Banner
          _buildClosestMandiBanner(),

          // 2. Search Bar
          _buildSearchBar(),

          // 3. Top Common Crop Filter Chips
          _buildCropFilterChips(),

          // 4. Status Strip
          _buildStatusStrip(filtered.length),

          // 5. Commodity Price Cards List (Quantity by Price)
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: colorPrimary),
                        SizedBox(height: 12),
                        Text(
                          'Agmarknet लाइव भाव प्राप्त हो रहे हैं...',
                          style: TextStyle(color: colorStoneMuted, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  )
                : filtered.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        color: colorPrimary,
                        onRefresh: () => _loadPrices(mandiId: _currentMandi?.id),
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          itemCount: filtered.length,
                          itemBuilder: (context, i) => _buildCommodityPriceCard(filtered[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      titleSpacing: 16,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: colorStoneText, size: 20),
        onPressed: () => Navigator.maybePop(context),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: colorPrimarySoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text('💰', style: TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'मंडी भाव लाइव',
                style: TextStyle(
                  color: colorStoneText,
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
              Row(
                children: [
                  Text(
                    'AGMARKNET • भारत सरकार कृषि विपणन',
                    style: TextStyle(
                      color: colorPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                      letterSpacing: 0.2,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.verified_rounded, size: 12, color: colorPrimary),
                ],
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () => _loadPrices(mandiId: _currentMandi?.id),
          icon: const Icon(Icons.refresh_rounded, color: colorPrimary, size: 22),
          tooltip: 'रिफ्रेश करें',
        ),
        const SizedBox(width: 6),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: colorHairline, height: 1),
      ),
    );
  }

  // ==========================================
  // 1. CLOSEST MANDI HERO SWITCHER BANNER
  // ==========================================
  Widget _buildClosestMandiBanner() {
    final mandi = _currentMandi ?? MandiService.defaultMandis.first;
    final hasDist = mandi.distanceKm != null;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorHairline),
        boxShadow: [
          BoxShadow(
            color: colorPrimary.withValues(alpha: 0.05),
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
              // Distance / Closest Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colorPrimarySoft,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colorPrimary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isLocationLoading)
                      const Padding(
                        padding: EdgeInsets.only(right: 4),
                        child: SizedBox(
                          width: 10,
                          height: 10,
                          child: CircularProgressIndicator(strokeWidth: 1.5, color: colorPrimary),
                        ),
                      )
                    else ...[
                      const Icon(Icons.near_me_rounded, color: colorPrimary, size: 12),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      _isLocationLoading
                          ? 'निकटतम मंडी खोजी जा रही है...'
                          : (hasDist ? '${mandi.distanceKm} km • निकटतम मंडी' : 'चयनित मंडी'),
                      style: const TextStyle(
                        color: colorPrimaryDeep,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),

              // Switch Mandi Button (Opens Palette)
              InkWell(
                onTap: _openMandiSwitcherPalette,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: colorBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorHairline),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.swap_horiz_rounded, size: 15, color: colorPrimary),
                      SizedBox(width: 4),
                      Text(
                        'मंडी बदलें',
                        style: TextStyle(
                          color: colorPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Mandi Name & State
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colorPrimarySoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.storefront_rounded, color: colorPrimary, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mandi.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: colorStoneText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${mandi.district}, ${mandi.state} • ${mandi.marketType}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: colorStoneMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 2. SEARCH BAR
  // ==========================================
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: colorStoneText, fontSize: 13),
        decoration: InputDecoration(
          hintText: 'फसल या किस्म खोजें (उदा. गेहूं, बासमती, सरसों, आलू)...',
          hintStyle: const TextStyle(color: colorStoneMuted, fontSize: 12),
          prefixIcon: const Icon(Icons.search_rounded, color: colorPrimary, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, color: colorStoneMuted, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: colorHairline),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: colorPrimary, width: 1.5),
          ),
        ),
        onChanged: (v) => setState(() => _searchQuery = v),
      ),
    );
  }

  // ==========================================
  // 3. TOP CROP FILTER CHIPS
  // ==========================================
  Widget _buildCropFilterChips() {
    return Container(
      height: 38,
      margin: const EdgeInsets.only(bottom: 6),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _cropFilterCategories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final cat = _cropFilterCategories[i];
          final isSelected = _selectedCropFilter == cat['key'];

          return InkWell(
            onTap: () {
              setState(() {
                _selectedCropFilter = cat['key']!;
              });
            },
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? colorPrimary : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? colorPrimary : colorHairline,
                  width: isSelected ? 1.4 : 1.0,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: colorPrimary.withValues(alpha: 0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(cat['icon']!, style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 5),
                  Text(
                    cat['label']!,
                    style: TextStyle(
                      color: isSelected ? Colors.white : colorStoneText,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ==========================================
  // 4. STATUS STRIP
  // ==========================================
  Widget _buildStatusStrip(int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.hub_rounded, size: 13, color: colorPrimary),
          const SizedBox(width: 5),
          const Text(
            'आधिकारिक Agmarknet पोर्टल • लाइव दरें',
            style: TextStyle(fontSize: 11, color: colorStoneMuted, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: colorPrimarySoft,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'कुल $count फसलें',
              style: const TextStyle(fontSize: 11, color: colorPrimaryDeep, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 5. COMMODITY PRICE CARD (QUANTITY BY PRICE)
  // ==========================================
  Widget _buildCommodityPriceCard(MandiPrice item) {
    final bool isUp = item.trend == 'up';
    final bool isDown = item.trend == 'down';
    final Color trendColor = isUp ? colorPrimary : (isDown ? colorEarthAlert : colorStoneMuted);
    final Color badgeBg = isUp ? colorPrimarySoft : (isDown ? const Color(0xFFFFEBEE) : colorBg);

    // Calculate position for visual price range gauge
    final double spread = (item.maxPrice - item.minPrice).abs();
    final double progress = spread > 0 ? ((item.price - item.minPrice) / spread).clamp(0.0, 1.0) : 0.5;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorHairline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showPriceDetailModal(item),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Crop Name, Variety & Trend
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: colorPrimarySoft,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colorHairline),
                      ),
                      child: Center(
                        child: Text(
                          _getCropEmoji(item.cropName),
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.cropNameHi,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: colorStoneText,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                item.cropName,
                                style: const TextStyle(fontSize: 12, color: colorStoneMuted, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: colorBg,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: colorHairline),
                                ),
                                child: Text(
                                  item.variety,
                                  style: const TextStyle(fontSize: 10, color: colorStoneText, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Trend Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(item.trendEmoji, style: const TextStyle(fontSize: 11)),
                          const SizedBox(width: 3),
                          Text(
                            '${item.change > 0 ? '+' : ''}${item.change}%',
                            style: TextStyle(color: trendColor, fontSize: 11, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                Container(height: 1, color: colorHairline.withValues(alpha: 0.6)),
                const SizedBox(height: 12),

                // Middle: Quantity by Price Focus
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Modal Price (मॉडल भाव)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'मॉडल भाव (Modal Rate)',
                          style: TextStyle(fontSize: 11, color: colorStoneMuted, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '₹${item.modalPrice.toInt()}',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: colorPrimaryDeep,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              '/ क्विंटल',
                              style: TextStyle(fontSize: 12, color: colorStoneMuted, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF8E1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '₹${item.pricePerKg.toStringAsFixed(1)}/kg',
                                style: const TextStyle(fontSize: 10, color: Color(0xFFB45309), fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Daily Arrival Quantity (दैनिक आवक)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: colorPrimarySoft,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: colorPrimary.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.inventory_2_outlined, size: 12, color: colorPrimary),
                              SizedBox(width: 4),
                              Text(
                                'दैनिक आवक',
                                style: TextStyle(fontSize: 10, color: colorPrimary, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          const SizedBox(height: 1),
                          Text(
                            item.formattedArrival,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: colorPrimaryDeep,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Price Range Gauge (Min to Max)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        height: 5,
                        color: colorHairline,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return Stack(
                              children: [
                                Positioned(
                                  left: 0,
                                  width: constraints.maxWidth * progress,
                                  top: 0,
                                  bottom: 0,
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [Color(0xFF81C784), colorPrimary],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'न्यूनतम: ₹${item.minPrice.toInt()}',
                          style: const TextStyle(fontSize: 10, color: colorStoneMuted, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'अधिकतम: ₹${item.maxPrice.toInt()}',
                          style: const TextStyle(fontSize: 10, color: colorStoneMuted, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 8),
                // Footer
                Row(
                  children: [
                    const Icon(Icons.apartment_rounded, size: 11, color: colorStoneMuted),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        item.marketName,
                        style: const TextStyle(fontSize: 10, color: colorStoneMuted, fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Text(
                      'विवरण देखें ›',
                      style: TextStyle(fontSize: 11, color: colorPrimary, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // SWITCH MANDI MODAL PALETTE
  // ==========================================
  void _openMandiSwitcherPalette() {
    String paletteSearch = '';
    String selectedState = 'All';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            final filteredMandis = _allMandis.where((m) {
              final matchesQuery = paletteSearch.isEmpty ||
                  m.name.toLowerCase().contains(paletteSearch.toLowerCase()) ||
                  (m.nameHi ?? '').toLowerCase().contains(paletteSearch.toLowerCase()) ||
                  m.district.toLowerCase().contains(paletteSearch.toLowerCase()) ||
                  m.state.toLowerCase().contains(paletteSearch.toLowerCase());

              final matchesState = selectedState == 'All' ||
                  (selectedState == 'Nearby' && (m.distanceKm ?? 999) < 150) ||
                  m.state.toLowerCase().contains(selectedState.toLowerCase());

              return matchesQuery && matchesState;
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.82,
              decoration: const BoxDecoration(
                color: colorBg,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Grab handle
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

                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'मंडी बदलें (Switch Mandi)',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: colorStoneText,
                              ),
                            ),
                            Text(
                              'निकटतम या किसी भी राज्य की मंडी के भाव देखें',
                              style: TextStyle(fontSize: 11, color: colorStoneMuted),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: colorStoneMuted),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),

                  // Search bar in Palette
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: TextField(
                      style: const TextStyle(fontSize: 13, color: colorStoneText),
                      decoration: InputDecoration(
                        hintText: 'मंडी, जिला या राज्य खोजें (उदा. आज़ादपुर, इंदौर, करनाल)...',
                        hintStyle: const TextStyle(color: colorStoneMuted, fontSize: 12),
                        prefixIcon: const Icon(Icons.search_rounded, color: colorPrimary, size: 20),
                        filled: true,
                        fillColor: Colors.white,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: colorHairline),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: colorPrimary, width: 1.5),
                        ),
                      ),
                      onChanged: (v) {
                        setModalState(() => paletteSearch = v);
                      },
                    ),
                  ),

                  // State Filter Chips in Palette
                  Container(
                    height: 34,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      children: [
                        _paletteStateChip('All', 'सभी Mandis', selectedState, (s) {
                          setModalState(() => selectedState = s);
                        }),
                        _paletteStateChip('Nearby', '📍 निकटतम', selectedState, (s) {
                          setModalState(() => selectedState = s);
                        }),
                        _paletteStateChip('Uttar Pradesh', 'उत्तर प्रदेश', selectedState, (s) {
                          setModalState(() => selectedState = s);
                        }),
                        _paletteStateChip('Madhya Pradesh', 'मध्य प्रदेश', selectedState, (s) {
                          setModalState(() => selectedState = s);
                        }),
                        _paletteStateChip('Haryana', 'हरियाणा', selectedState, (s) {
                          setModalState(() => selectedState = s);
                        }),
                        _paletteStateChip('Punjab', 'पंजाब', selectedState, (s) {
                          setModalState(() => selectedState = s);
                        }),
                        _paletteStateChip('Maharashtra', 'महाराष्ट्र', selectedState, (s) {
                          setModalState(() => selectedState = s);
                        }),
                        _paletteStateChip('Rajasthan', 'राजस्थान', selectedState, (s) {
                          setModalState(() => selectedState = s);
                        }),
                        _paletteStateChip('Delhi', 'दिल्ली', selectedState, (s) {
                          setModalState(() => selectedState = s);
                        }),
                      ],
                    ),
                  ),

                  // Mandi list
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                      itemCount: filteredMandis.length,
                      itemBuilder: (modalCtx, idx) {
                        final m = filteredMandis[idx];
                        final isCurrent = m.id == _currentMandi?.id;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isCurrent ? colorPrimary : colorHairline,
                              width: isCurrent ? 1.8 : 1.0,
                            ),
                          ),
                          child: ListTile(
                            onTap: () {
                              Navigator.pop(ctx);
                              _switchMandi(m);
                            },
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                            leading: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: isCurrent ? colorPrimary : colorPrimarySoft,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.storefront_rounded,
                                color: isCurrent ? Colors.white : colorPrimary,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              m.name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w700,
                                color: isCurrent ? colorPrimaryDeep : colorStoneText,
                              ),
                            ),
                            subtitle: Text(
                              '${m.district}, ${m.state} • ${m.marketType}',
                              style: const TextStyle(fontSize: 11, color: colorStoneMuted),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (m.distanceKm != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: colorPrimarySoft,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${m.distanceKm} km',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: colorPrimaryDeep,
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 2),
                                if (isCurrent)
                                  const Icon(Icons.check_circle_rounded, color: colorPrimary, size: 16)
                                else
                                  const Text(
                                    'चुनें ›',
                                    style: TextStyle(fontSize: 11, color: colorPrimary, fontWeight: FontWeight.w600),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _paletteStateChip(String key, String label, String currentSelected, Function(String) onSelect) {
    final isSelected = currentSelected == key;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: () => onSelect(key),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? colorPrimary : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isSelected ? colorPrimary : colorHairline),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : colorStoneText,
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 6. PRICE DETAIL MODAL (RECEIPT / SLIP)
  // ==========================================
  void _showPriceDetailModal(MandiPrice item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorHairline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Row(
                children: [
                  Text(_getCropEmoji(item.cropName), style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${item.cropNameHi} (${item.cropName})',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: colorStoneText),
                        ),
                        Text(
                          'किस्म: ${item.variety} • ${item.marketName}',
                          style: const TextStyle(fontSize: 12, color: colorStoneMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: colorHairline),
              const SizedBox(height: 12),

              // Rate Conversion Table
              const Text(
                'मात्रा अनुसार भाव तालिका (Quantity by Rate)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: colorPrimaryDeep),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: colorBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorHairline),
                ),
                child: Column(
                  children: [
                    _slipRow('1 क्विंटल (100 किलो)', '₹${item.modalPrice.toInt()}'),
                    const Divider(height: 1, color: colorHairline),
                    _slipRow('1 किलो (Per Kg)', '₹${item.pricePerKg.toStringAsFixed(2)}'),
                    const Divider(height: 1, color: colorHairline),
                    _slipRow('1 मन / धड़ी (40 किलो)', '₹${(item.modalPrice * 0.4).toInt()}'),
                    const Divider(height: 1, color: colorHairline),
                    _slipRow('1 मीट्रिक टन (10 क्विंटल)', '₹${(item.modalPrice * 10).toInt()}'),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Agmarknet Bulletin Info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorPrimarySoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorPrimary.withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('दैनिक कुल आवक:', style: TextStyle(fontSize: 12, color: colorStoneText)),
                        Text(item.formattedArrival, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: colorPrimaryDeep)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('न्यूनतम - अधिकतम फैलाव:', style: TextStyle(fontSize: 12, color: colorStoneText)),
                        Text('₹${item.minPrice.toInt()} - ₹${item.maxPrice.toInt()}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: colorPrimaryDeep)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('आधिकारिक स्रोत:', style: TextStyle(fontSize: 11, color: colorStoneMuted)),
                        Text('agmarknet.gov.in', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: colorPrimary)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.check_rounded, color: Colors.white, size: 18),
                  label: const Text('ठीक है (Done)', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _slipRow(String unit, String rate) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(unit, style: const TextStyle(fontSize: 13, color: colorStoneText, fontWeight: FontWeight.w600)),
          Text(rate, style: const TextStyle(fontSize: 14, color: colorPrimaryDeep, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded, size: 48, color: colorStoneMuted),
            const SizedBox(height: 12),
            const Text(
              'कोई फसल नहीं मिली',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: colorStoneText),
            ),
            const SizedBox(height: 6),
            Text(
              '\'$_searchQuery\' या चुने गए फिल्टर में इस मंडी के लिए कोई भाव उपलब्ध नहीं है।',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: colorStoneMuted),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _searchQuery = '';
                  _selectedCropFilter = 'ALL';
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorPrimarySoft,
                foregroundColor: colorPrimary,
                elevation: 0,
              ),
              child: const Text('सभी फसलें देखें'),
            ),
          ],
        ),
      ),
    );
  }

  List<MandiPrice> _getFilteredPrices() {
    return _prices.where((p) {
      // 1. Crop Filter
      final matchesCrop = _selectedCropFilter == 'ALL' ||
          p.cropName.toLowerCase().contains(_selectedCropFilter.toLowerCase()) ||
          p.cropNameHi.contains(_selectedCropFilter);

      // 2. Search Query
      final q = _searchQuery.trim().toLowerCase();
      final matchesSearch = q.isEmpty ||
          p.cropName.toLowerCase().contains(q) ||
          p.cropNameHi.toLowerCase().contains(q) ||
          p.variety.toLowerCase().contains(q);

      return matchesCrop && matchesSearch;
    }).toList();
  }

  String _getCropEmoji(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('wheat')) return '🌾';
    if (lower.contains('rice') || lower.contains('paddy')) return '🍚';
    if (lower.contains('maize')) return '🌽';
    if (lower.contains('mustard')) return '🟡';
    if (lower.contains('soybean')) return '🌱';
    if (lower.contains('cotton')) return '☁️';
    if (lower.contains('chana') || lower.contains('gram')) return '🟤';
    if (lower.contains('potato')) return '🥔';
    if (lower.contains('onion')) return '🧅';
    if (lower.contains('tomato')) return '🍅';
    if (lower.contains('garlic')) return '🧄';
    if (lower.contains('sugarcane')) return '🎋';
    return '🌾';
  }
}
