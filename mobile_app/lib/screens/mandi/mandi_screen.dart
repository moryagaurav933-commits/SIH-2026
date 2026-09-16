import 'package:flutter/material.dart';
import '../../services/weather_mandi_service.dart';
import '../../utils/design_tokens.dart';

/// Feature 6B — Mandi Price Screen
/// Live Agmarknet + backend mandi prices with Green & White theme
class MandiScreen extends StatefulWidget {
  const MandiScreen({super.key});

  @override
  State<MandiScreen> createState() => _MandiScreenState();
}

class _MandiScreenState extends State<MandiScreen> {
  final MandiService _mandiService = MandiService();
  List<MandiPrice> _prices = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadPrices();
  }

  Future<void> _loadPrices() async {
    setState(() => _isLoading = true);
    final prices = await _mandiService.getPrices();
    if (mounted) {
      setState(() {
        _prices = prices;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _searchQuery.isEmpty
        ? _prices
        : _prices.where((p) =>
            p.cropNameHi.contains(_searchQuery) ||
            p.cropName.toLowerCase().contains(_searchQuery.toLowerCase())
          ).toList();

    return Scaffold(
      backgroundColor: colorBg,
      appBar: buildKrishiAppBar(
        context: context,
        title: 'मंडी भाव लाइव',
        subtitle: 'MANDI MARKET PRICES (LIVE API)',
        emoji: '💰',
        actions: [
          IconButton(
            onPressed: _loadPrices,
            icon: const Icon(Icons.refresh_rounded, color: colorPrimary, size: 20),
            tooltip: 'Refresh Prices',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar with Green & White theme
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              style: const TextStyle(color: colorStoneText, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'फसल खोजें (गेहूं, चावल, टमाटर, कपास...)...',
                hintStyle: const TextStyle(color: colorStoneMuted, fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, color: colorPrimary, size: 20),
                filled: true,
                fillColor: colorCard,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: colorHairline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: colorPrimary, width: 1.5),
                ),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),

          // Subheader & refresh status
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Row(
              children: [
                const Icon(Icons.verified_rounded, size: 14, color: colorPrimary),
                const SizedBox(width: 6),
                const Text(
                  'लाइव ई-मंडी भाव • ₹ प्रति क्विंटल',
                  style: TextStyle(fontSize: 12, color: colorStoneMuted, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Text(
                  'कुल ${filtered.length} फसलें',
                  style: const TextStyle(fontSize: 12, color: colorPrimary, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),

          // Price list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: colorPrimary))
                : RefreshIndicator(
                    color: colorPrimary,
                    onRefresh: _loadPrices,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
                      itemCount: filtered.length,
                      itemBuilder: (context, i) => _priceCard(filtered[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _priceCard(MandiPrice price) {
    final bool isUp = price.trend == 'up';
    final bool isDown = price.trend == 'down';
    final Color trendColor = isUp ? colorPrimary : (isDown ? colorEarthAlert : colorStoneMuted);
    final Color badgeBg = isUp ? colorPrimarySoft : (isDown ? const Color(0xFFFFEBEE) : colorSurface);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorCard,
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
      child: Row(
        children: [
          // Crop icon avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colorPrimarySoft,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorHairline),
            ),
            child: const Center(
              child: Text('🌾', style: TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 14),

          // Crop info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  price.cropNameHi,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: colorStoneText),
                ),
                const SizedBox(height: 2),
                Text(
                  price.cropName,
                  style: const TextStyle(fontSize: 12, color: colorStoneMuted, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),

          // Price & trend
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${price.price.toInt()}',
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: colorPrimaryDeep),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(price.trendEmoji, style: const TextStyle(fontSize: 11)),
                    const SizedBox(width: 3),
                    Text(
                      '${price.change > 0 ? '+' : ''}${price.change}%',
                      style: TextStyle(color: trendColor, fontSize: 11, fontWeight: FontWeight.w700),
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
}
