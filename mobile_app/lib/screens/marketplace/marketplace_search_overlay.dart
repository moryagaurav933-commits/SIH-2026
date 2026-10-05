// -*- coding: utf-8 -*-
import 'package:flutter/material.dart';
import 'marketplace_model.dart';
import 'product_detail_screen.dart';

/// Krishi Marketplace Search Overlay matching Image 3:
/// - Search input with search icon & clear button
/// - Live auto-suggestions with product thumbnails & category breadcrumbs
/// - Keyword query suggestions with search icon
/// - Quick search tags & recent searches
class MarketplaceSearchOverlay extends StatefulWidget {
  final String initialQuery;
  final Function(String query)? onQuerySelected;

  const MarketplaceSearchOverlay({
    super.key,
    this.initialQuery = '',
    this.onQuerySelected,
  });

  @override
  State<MarketplaceSearchOverlay> createState() => _MarketplaceSearchOverlayState();
}

class _MarketplaceSearchOverlayState extends State<MarketplaceSearchOverlay> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  String _searchQuery = '';

  static const List<String> _popularQueries = [
    'agriculture related product',
    'agriculture product in Lawn and Gardening',
    'equipment for agriculture products',
    'agriculture related product in hindi',
    'agriculture related product book',
    'agriculture related product kit',
    'fungicide for tomato early blight',
    'urea and DAP fertilizer',
    'neem oil organic spray',
    'weeding rake garden tools',
    'cotton bollworm insecticide',
    'certified wheat seeds',
  ];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
    _searchQuery = widget.initialQuery;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  List<ProductItem> get _matchedProducts {
    if (_searchQuery.trim().isEmpty) return [];
    return MarketplaceCatalog.searchProducts(_searchQuery).take(8).toList();
  }

  List<String> get _matchedQueries {
    if (_searchQuery.trim().isEmpty) return _popularQueries.take(6).toList();
    final q = _searchQuery.toLowerCase();
    final matches = _popularQueries.where((s) => s.toLowerCase().contains(q)).toList();
    if (matches.isEmpty) {
      return [
        _searchQuery,
        '$_searchQuery in fungicides',
        '$_searchQuery fertilizer',
        '$_searchQuery curing medicine',
      ];
    }
    return matches;
  }

  void _submitSearch(String query) {
    if (widget.onQuerySelected != null) {
      widget.onQuerySelected!(query);
    }
    Navigator.of(context).pop(query);
  }

  void _openProduct(ProductItem product) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(product: product),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final matchedProds = _matchedProducts;
    final matchedQ = _matchedQueries;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: SafeArea(
          child: Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xFF1B381E)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F4F1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF2874F0).withValues(alpha: 0.4), width: 1.2),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            focusNode: _focusNode,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF111827),
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Search for crops, medicines, fertilizers...',
                              hintStyle: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onChanged: (val) {
                              setState(() {
                                _searchQuery = val;
                              });
                            },
                            onSubmitted: _submitSearch,
                          ),
                        ),
                        if (_searchQuery.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _controller.clear();
                              setState(() => _searchQuery = '');
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4),
                              child: Icon(Icons.close, size: 18, color: Color(0xFF6B7280)),
                            ),
                          ),
                        GestureDetector(
                          onTap: () => _submitSearch(_controller.text),
                          child: const Icon(Icons.search, color: Color(0xFF2874F0), size: 22),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // Section 1: Thumbnail product suggestions (Exact Match from Image 3)
          if (matchedProds.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Text(
                'PRODUCTS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
            ...matchedProds.map((prod) => _buildProductSuggestionTile(prod)),
            Divider(color: Colors.grey.shade200, height: 16),
          ],

          // Section 2: Query suggestions matching Image 3 with magnifying glass
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Text(
              _searchQuery.isEmpty ? 'POPULAR SEARCHES' : 'RELATED SEARCHES',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: Colors.grey.shade500,
              ),
            ),
          ),
          ...matchedQ.map((query) => _buildQuerySuggestionTile(query)),

          const SizedBox(height: 16),

          // Quick category tag buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildQuickChip('🌾 Crop Medicines'),
                _buildQuickChip('🧪 Fungicides'),
                _buildQuickChip('🌱 Organic Fertilizer'),
                _buildQuickChip('🚜 Farm Tools'),
                _buildQuickChip('🌿 Bio-Pesticides'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductSuggestionTile(ProductItem product) {
    return InkWell(
      onTap: () => _openProduct(product),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                product.imageAsset,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 44,
                  height: 44,
                  color: const Color(0xFFE8F5E9),
                  child: const Icon(Icons.eco, color: Color(0xFF2E7D32)),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'in ${product.category.displayName}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF2874F0),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '₹${product.price.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF16A34A),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_forward_ios, size: 12, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuerySuggestionTile(String query) {
    return InkWell(
      onTap: () => _submitSearch(query),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
        ),
        child: Row(
          children: [
            const Icon(Icons.search, size: 20, color: Color(0xFF64748B)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                query,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
            const Icon(Icons.north_west, size: 14, color: Color(0xFFCBD5E1)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickChip(String label) {
    return ActionChip(
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1E3A1E),
        ),
      ),
      backgroundColor: const Color(0xFFEDF7EE),
      side: BorderSide(color: const Color(0xFF4CAF50).withValues(alpha: 0.3)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onPressed: () => _submitSearch(label.replaceAll(RegExp(r'[^\w\s]'), '').trim()),
    );
  }
}
