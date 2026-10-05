// -*- coding: utf-8 -*-
import 'package:flutter/material.dart';
import 'marketplace_model.dart';
import 'marketplace_cart_service.dart';
import 'marketplace_filter_sheet.dart';
import 'marketplace_search_overlay.dart';
import 'product_detail_screen.dart';
import 'checkout_screen.dart';
import 'watchlist_screen.dart';
import 'my_orders_screen.dart';

enum SortOption {
  relevance,
  popularity,
  priceLowHigh,
  priceHighLow,
  newestFirst,
}

extension SortOptionExt on SortOption {
  String get label {
    switch (this) {
      case SortOption.relevance:
        return 'Relevance';
      case SortOption.popularity:
        return 'Popularity';
      case SortOption.priceLowHigh:
        return 'Price -- Low to High';
      case SortOption.priceHighLow:
        return 'Price -- High to Low';
      case SortOption.newestFirst:
        return 'Newest First';
    }
  }
}

/// Krishi Marketplace Main Screen matching Image 1:
/// - Top Search Bar with quick suggestions
/// - Horizontal "Sort By: Relevance | Popularity | Price -- Low to High | Price -- High to Low | Newest First" tabs
/// - Filter bottom sheet (Image 2) with active badge
/// - 2-Column Product Grid with exact cards:
///     * Wishlist heart icon
///     * Sponsored chip
///     * Packshot product photo
///     * Title, pack size
///     * Rating green pill + Assured badge
///     * Price (Bold, MRP strikethrough, discount %)
///     * Special offer tag ('Big Billion Days Price', 'Kisan Mela Offer', 'Only few left')
/// - Floating Bottom Cart Bar
class MarketplaceScreen extends StatefulWidget {
  final ProductCategory? initialCategory;
  final String? initialSearch;

  const MarketplaceScreen({
    super.key,
    this.initialCategory,
    this.initialSearch,
  });

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final MarketplaceCartService _cart = MarketplaceCartService();
  SortOption _selectedSort = SortOption.relevance;
  FilterState _filter = FilterState();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null) {
      _filter.category = widget.initialCategory!;
    }
    if (widget.initialSearch != null) {
      _searchQuery = widget.initialSearch!;
    }
    _cart.addListener(_onCartChanged);
  }

  @override
  void dispose() {
    _cart.removeListener(_onCartChanged);
    super.dispose();
  }

  void _onCartChanged() {
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    }
  }

  List<ProductItem> get _filteredAndSortedProducts {
    List<ProductItem> list;

    if (_searchQuery.trim().isNotEmpty) {
      list = MarketplaceCatalog.searchProducts(
        _searchQuery,
        filter: _filter.isDefault ? null : _filter,
      );
    } else {
      list = MarketplaceCatalog.filterProducts(_filter);
    }

    // Apply Sort (Matching Image 1)
    switch (_selectedSort) {
      case SortOption.relevance:
        break;
      case SortOption.popularity:
        list.sort((a, b) => b.boughtLastMonth.compareTo(a.boughtLastMonth));
        break;
      case SortOption.priceLowHigh:
        list.sort((a, b) => a.price.compareTo(b.price));
        break;
      case SortOption.priceHighLow:
        list.sort((a, b) => b.price.compareTo(a.price));
        break;
      case SortOption.newestFirst:
        list.sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
        break;
    }

    return list;
  }

  void _openSearchOverlay() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => MarketplaceSearchOverlay(initialQuery: _searchQuery),
      ),
    );
    if (result != null) {
      setState(() {
        _searchQuery = result;
        if (_searchQuery.trim().isNotEmpty && _filter.category != ProductCategory.all) {
          final testResults = MarketplaceCatalog.searchProducts(_searchQuery, filter: _filter);
          if (testResults.isEmpty) {
            _filter.category = ProductCategory.all;
          }
        }
      });
    }
  }

  void _toggleWishlist(ProductItem product) {
    _cart.toggleWishlist(product.id);
    final isWish = _cart.isInWishlist(product.id);
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isWish ? Icons.favorite : Icons.favorite_border, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isWish ? 'Added to your Shopping List' : 'Removed from your Shopping List',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1B381E),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: isWish
            ? SnackBarAction(
                label: 'VIEW LIST',
                textColor: const Color(0xFFFFD814),
                onPressed: () {
                  if (!mounted) return;
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const WatchlistScreen()),
                  );
                },
              )
            : null,
      ),
    );
  }

  void _openFilterSheet() async {
    final newFilter = await showModalBottomSheet<FilterState>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MarketplaceFilterSheet(initialFilter: _filter),
    );
    if (newFilter != null) {
      setState(() {
        _filter = newFilter;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final products = _filteredAndSortedProducts;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F2F4),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Krishi Marketplace',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1B381E),
              ),
            ),
            Row(
              children: [
                const Icon(Icons.location_on, size: 11, color: Color(0xFF2874F0)),
                const SizedBox(width: 2),
                Text(
                  _cart.deliveryPincode.isNotEmpty ? 'PIN ${_cart.deliveryPincode}' : 'Live Farm GPS',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                ),
                const SizedBox(width: 6),
                const Text('• 40 Verified Products', style: TextStyle(fontSize: 10, color: Color(0xFF16A34A), fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: Color(0xFF1E293B)),
            tooltip: 'Filter Products',
            onPressed: _openFilterSheet,
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.favorite_outline, color: Color(0xFF1E293B)),
                tooltip: 'Shopping List / Watchlist',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const WatchlistScreen()),
                  );
                },
              ),
              if (_cart.wishlistIds.isNotEmpty)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE11D48),
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    child: Text(
                      '${_cart.wishlistIds.length}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined, color: Color(0xFF1E293B)),
            tooltip: 'My Orders & Tracking',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
              );
            },
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined, color: Color(0xFF1E293B)),
                tooltip: 'Cart & Checkout',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                  );
                },
              ),
              if (_cart.totalItemCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFDC2626),
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    child: Text(
                      '${_cart.totalItemCount}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Column(
        children: [
          // 1. Search Bar (Tapping opens search overlay with auto-suggest like Image 3)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: InkWell(
              onTap: _openSearchOverlay,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F4F1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Color(0xFF2874F0), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _searchQuery.isEmpty ? 'agriculture related product' : _searchQuery,
                        style: TextStyle(
                          fontSize: 14,
                          color: _searchQuery.isEmpty ? Colors.grey.shade600 : const Color(0xFF111827),
                          fontWeight: _searchQuery.isEmpty ? FontWeight.normal : FontWeight.w600,
                        ),
                      ),
                    ),
                    if (_searchQuery.isNotEmpty)
                      GestureDetector(
                        onTap: () => setState(() => _searchQuery = ''),
                        child: const Icon(Icons.close, size: 18, color: Colors.grey),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // 2. Horizontal Sort Bar matching Image 1
          // "Sort By: Relevance | Popularity | Price -- Low to High | Price -- High to Low | Newest First"
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const Text(
                    'Sort By',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ...SortOption.values.map((sort) {
                    final isSel = _selectedSort == sort;
                    return InkWell(
                      onTap: () => setState(() => _selectedSort = sort),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: isSel ? const Color(0xFF2874F0) : Colors.transparent,
                              width: 2.5,
                            ),
                          ),
                        ),
                        child: Text(
                          sort.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                            color: isSel ? const Color(0xFF2874F0) : const Color(0xFF4B5563),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          // 3. Category Filter Chips Strip
          Container(
            color: Colors.white,
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                // Filter Button with badge
                ActionChip(
                  avatar: const Icon(Icons.filter_list, size: 16, color: Color(0xFF1B381E)),
                  label: Text(
                    'Filters${_filter.activeFilterCount > 0 ? ' (${_filter.activeFilterCount})' : ''}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1B381E)),
                  ),
                  backgroundColor: _filter.activeFilterCount > 0 ? const Color(0xFFDCFCE7) : const Color(0xFFF3F4F6),
                  side: BorderSide(
                    color: _filter.activeFilterCount > 0 ? const Color(0xFF16A34A) : Colors.grey.shade300,
                  ),
                  onPressed: _openFilterSheet,
                ),
                const SizedBox(width: 8),

                // Category chips
                ...ProductCategory.values.map((cat) {
                  final isSel = _filter.category == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      selected: isSel,
                      showCheckmark: false,
                      label: Text(cat.displayName, style: TextStyle(fontSize: 12, fontWeight: isSel ? FontWeight.bold : FontWeight.w500)),
                      selectedColor: const Color(0xFF2874F0),
                      labelStyle: TextStyle(color: isSel ? Colors.white : const Color(0xFF374151)),
                      backgroundColor: const Color(0xFFF9FAFB),
                      side: BorderSide(color: isSel ? const Color(0xFF2874F0) : Colors.grey.shade300),
                      onSelected: (val) {
                        setState(() {
                          _filter.category = cat;
                        });
                      },
                    ),
                  );
                }),
              ],
            ),
          ),

          // 4. Product Catalog Grid matching Image 1
          Expanded(
            child: products.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off, size: 60, color: Colors.grey),
                        const SizedBox(height: 12),
                        const Text('No products match your filters', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _filter.reset();
                              _searchQuery = '';
                            });
                          },
                          child: const Text('Reset All Filters'),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.655,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      return _buildProductCard(products[index]);
                    },
                  ),
          ),

          // 5. Floating Bottom Cart Bar (if items in cart)
          if (_cart.totalItemCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1B381E),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, -2)),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFF2E7D32),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${_cart.totalItemCount} items | ₹${_cart.finalTotal.toStringAsFixed(0)}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const Text(
                            'Kisan Subsidy & Free Delivery applied',
                            style: TextStyle(color: Color(0xFF86EFAC), fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD814),
                        foregroundColor: const Color(0xFF0F1111),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: const Row(
                        children: [
                          Text('Checkout', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_ios, size: 12),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Product Card faithfully matching Image 2 layout:
  /// - Top wishlist heart icon with feedback toast & link to Shopping List
  /// - Packshot image (properly bounded, BoxFit.contain)
  /// - Title (bold, 2 lines max, exact spacing)
  /// - Pack size / measurement
  /// - Rating green badge + Assured badge
  /// - Price: bold price, strikethrough MRP, discount %
  /// - Special tag ('Big Kisan Days Price', 'Same Day Dispatch', 'Seed & Soil Ready')
  Widget _buildProductCard(ProductItem product) {
    final isWish = _cart.isInWishlist(product.id);

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: product),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Image Area with Heart (Matching Image 2)
            Stack(
              children: [
                Container(
                  height: 135,
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  color: Colors.white,
                  child: Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.asset(
                        product.imageAsset,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFFF1F8F1),
                          child: const Icon(Icons.eco, size: 48, color: Color(0xFF2E7D32)),
                        ),
                      ),
                    ),
                  ),
                ),
                // Wishlist Heart Icon (Top Right)
                Positioned(
                  top: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap: () => _toggleWishlist(product),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                      child: Icon(
                        isWish ? Icons.favorite : Icons.favorite_border,
                        size: 18,
                        color: isWish ? const Color(0xFFE11D48) : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Content Area matching Image 2
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 2, 10, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title (2 lines max)
                  Text(
                    product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 2),

                  // Pack size (e.g. 500 g, 200 ml)
                  Text(
                    product.packSize,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 5),

                  // Rating pill & Assured badge (Image 2)
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: product.rating >= 4.0 ? const Color(0xFF388E3C) : const Color(0xFFF57C00),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${product.rating}',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 2),
                            const Icon(Icons.star, color: Colors.white, size: 9),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${product.reviewCount})',
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                      ),
                      const Spacer(),
                      if (product.isAssured)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2874F0),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.shield, color: Colors.amber, size: 9),
                              SizedBox(width: 2),
                              Text(
                                'Assured',
                                style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 5),

                  // Price line (Bold price, strikethrough MRP, discount %)
                  Row(
                    children: [
                      Text(
                        '₹${product.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '₹${product.mrp.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${product.discountPercent}% off',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF388E3C),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),

                  // Special tag (Big Kisan Days Price, Same Day Dispatch, etc.)
                  if (product.specialTag.isNotEmpty)
                    Text(
                      product.specialTag,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: product.specialTag.contains('Only few')
                            ? const Color(0xFFDC2626)
                            : (product.specialTag.contains('Same Day')
                                ? const Color(0xFF15803D)
                                : const Color(0xFF6B21A8)),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
