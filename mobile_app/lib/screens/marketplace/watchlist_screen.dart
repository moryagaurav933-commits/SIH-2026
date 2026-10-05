// -*- coding: utf-8 -*-
import 'package:flutter/material.dart';
import 'marketplace_model.dart';
import 'marketplace_cart_service.dart';
import 'product_detail_screen.dart';
import 'checkout_screen.dart';

/// Shopping List / Watchlist Screen matching Image 1:
/// - "Shopping List" with "Private" tag
/// - Header buttons: "+ Invite", "Add item", Share, "..."
/// - View switcher (Grid / List)
/// - "Search this list" input
/// - Dropdown filters: "Show: Unpurchased", "Sort by: Most recently added"
/// - Cards matching Image 1:
///     * "Best seller" orange tag
///     * Packshot image
///     * Title, brand, ratings
///     * Price + Fulfilled + FREE Delivery
///     * "Item added 1 October 2026"
///     * "Add to Cart" yellow pill button
///     * "Add a note" button (with real note dialog)
///     * "Move v", Share, Delete
class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  final MarketplaceCartService _cart = MarketplaceCartService();
  String _searchFilter = '';
  String _showFilter = 'Unpurchased';
  String _sortBy = 'Most recently added';
  bool _isListView = true;

  @override
  void initState() {
    super.initState();
    _cart.addListener(_onCartChanged);
  }

  @override
  void dispose() {
    _cart.removeListener(_onCartChanged);
    super.dispose();
  }

  void _onCartChanged() {
    if (mounted) setState(() {});
  }

  List<ProductItem> get _watchlistProducts {
    final ids = _cart.wishlistIds;
    var list = MarketplaceCatalog.allProducts.where((p) => ids.contains(p.id)).toList();

    if (_searchFilter.trim().isNotEmpty) {
      final q = _searchFilter.toLowerCase();
      list = list.where((p) => p.title.toLowerCase().contains(q) || p.brand.toLowerCase().contains(q)).toList();
    }

    if (_sortBy == 'Price: Low to High') {
      list.sort((a, b) => a.price.compareTo(b.price));
    } else if (_sortBy == 'Price: High to Low') {
      list.sort((a, b) => b.price.compareTo(a.price));
    } else if (_sortBy == 'Title A-Z') {
      list.sort((a, b) => a.title.compareTo(b.title));
    }

    return list;
  }

  void _showAddNoteDialog(ProductItem product) {
    final existingNote = _cart.getNote(product.id) ?? '';
    final controller = TextEditingController(text: existingNote);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            existingNote.isEmpty ? 'Add note for ${product.brand}' : 'Edit Note',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 3,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'e.g., Spray on North Paddy field on Tuesday, dosage 2ml/L',
                  hintStyle: const TextStyle(fontSize: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          actions: [
            if (existingNote.isNotEmpty)
              TextButton(
                onPressed: () {
                  _cart.setNote(product.id, '');
                  Navigator.of(ctx).pop();
                },
                child: const Text('Delete Note', style: TextStyle(color: Colors.red)),
              ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _cart.setNote(product.id, controller.text.trim());
                Navigator.of(ctx).pop();
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
              child: const Text('Save Note', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showMoveMenu(ProductItem product) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Move to another list', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.bookmark_outline, color: Color(0xFF2E7D32)),
                title: const Text('Save for Next Kharif Season'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Moved to Kharif Season planning list!'),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.inventory_2_outlined, color: Colors.blue),
                title: const Text('Farm Tubewell & Tools List'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Moved to Farm Tools list!'),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.shopping_cart_outlined, color: Colors.orange),
                title: const Text('Move directly to Cart'),
                onTap: () {
                  _cart.addToCart(product);
                  _cart.toggleWishlist(product.id);
                  Navigator.of(ctx).pop();
                  final shortTitle = product.title.length > 25 ? '${product.title.substring(0, 22)}...' : product.title;
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Moved $shortTitle to Cart!'),
                      backgroundColor: const Color(0xFF2E7D32),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final products = _watchlistProducts;

    return Scaffold(
      backgroundColor: Colors.white,
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
            Row(
              children: [
                const Text(
                  'Shopping List',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F1111),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Private',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Invite button (Image 1)
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            child: OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Share this list link with farm helpers or family!'),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              },
              icon: const Icon(Icons.add, size: 14, color: Color(0xFF0F1111)),
              label: const Text('Invite', style: TextStyle(color: Color(0xFF0F1111), fontSize: 12, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Add item button (Image 1)
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF3F4F6),
                foregroundColor: const Color(0xFF0F1111),
                elevation: 0,
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: const Text('Add item', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Color(0xFF0F1111), size: 20),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_horiz, color: Color(0xFF0F1111)),
            onPressed: () {},
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Subheader matching Image 1: View toggle, Search list, Show dropdown, Sort dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // Grid / List toggle (Image 1)
                    Row(
                      children: [
                        InkWell(
                          onTap: () => setState(() => _isListView = false),
                          child: Icon(Icons.grid_view, size: 20, color: !_isListView ? const Color(0xFFC45500) : Colors.grey),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => setState(() => _isListView = true),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.view_agenda_outlined, size: 20, color: _isListView ? const Color(0xFFC45500) : Colors.grey),
                              if (_isListView)
                                Container(
                                  margin: const EdgeInsets.only(top: 2),
                                  height: 2,
                                  width: 18,
                                  color: const Color(0xFFC45500),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),

                    // Search this list input (Image 1)
                    Expanded(
                      child: Container(
                        height: 36,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search, size: 16, color: Colors.grey),
                            const SizedBox(width: 6),
                            Expanded(
                              child: TextField(
                                style: const TextStyle(fontSize: 13),
                                decoration: const InputDecoration(
                                  hintText: 'Search this list',
                                  hintStyle: TextStyle(fontSize: 12, color: Colors.grey),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onChanged: (val) => setState(() => _searchFilter = val),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Filters row (Image 1)
                Row(
                  children: [
                    // Show: Unpurchased dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: DropdownButton<String>(
                        value: _showFilter,
                        underline: const SizedBox(),
                        isDense: true,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF0F1111)),
                        items: ['Unpurchased', 'Purchased', 'All items'].map((val) {
                          return DropdownMenuItem(value: val, child: Text('Show: $val'));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _showFilter = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Sort by: Most recently added
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: DropdownButton<String>(
                          value: _sortBy,
                          isExpanded: true,
                          underline: const SizedBox(),
                          isDense: true,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF0F1111)),
                          items: [
                            'Most recently added',
                            'Title A-Z',
                            'Price: Low to High',
                            'Price: High to Low',
                          ].map((val) {
                            return DropdownMenuItem(value: val, child: Text('Sort by: $val', overflow: TextOverflow.ellipsis));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _sortBy = val);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Product Items List / Grid
          Expanded(
            child: products.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                        const SizedBox(height: 12),
                        const Text('Your Shopping List is empty', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        const Text('Tap the heart icon on any crop product to save it here.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
                          child: const Text('Explore Krishi Marketplace', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    itemCount: products.length,
                    separatorBuilder: (_, __) => const Divider(height: 24),
                    itemBuilder: (context, index) {
                      return _buildWatchlistCard(products[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// Watchlist Card exactly matching Image 1:
  /// - "Best seller" orange tag
  /// - Product image
  /// - Title, by Brand
  /// - Rating stars & count
  /// - Price, Fulfilled, FREE Delivery
  /// - Colour / Pack size
  /// - "Item added 1 October 2026"
  /// - Add to Cart button, Add a note button, Move v, Share, Delete
  Widget _buildWatchlistCard(ProductItem product) {
    final note = _cart.getNote(product.id);
    final dateAdded = _cart.getAddedDate(product.id);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image container with Best seller badge
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      width: 110,
                      height: 110,
                      color: const Color(0xFFF9FAFB),
                      child: Image.asset(
                        product.imageAsset,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(Icons.eco, color: Color(0xFF2E7D32), size: 40),
                      ),
                    ),
                  ),
                  if (product.isBestSeller)
                    Positioned(
                      top: 0,
                      left: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: const BoxDecoration(
                          color: Color(0xFFC45500),
                          borderRadius: BorderRadius.only(
                            bottomRight: Radius.circular(6),
                          ),
                        ),
                        child: const Text(
                          'Best seller',
                          style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),

              // Product Info matching Image 1
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
                        );
                      },
                      child: Text(
                        product.title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF007185),
                          height: 1.25,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),

                    // by Brand
                    Text(
                      'by ${product.brand} (Certified)',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 4),

                    // Star rating (Image 1)
                    Row(
                      children: [
                        Row(
                          children: List.generate(5, (i) {
                            return Icon(
                              i < product.rating.floor() ? Icons.star : Icons.star_border,
                              color: const Color(0xFFDE7921),
                              size: 14,
                            );
                          }),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.keyboard_arrow_down, size: 14, color: Colors.grey),
                        const SizedBox(width: 2),
                        Text(
                          '${product.reviewCount}',
                          style: const TextStyle(color: Color(0xFF007185), fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Price + Fulfilled (Image 1)
                    Row(
                      children: [
                        Text(
                          '₹${product.price.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F1111)),
                        ),
                        const SizedBox(width: 6),
                        if (product.isAssured)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2874F0),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: const Text('Fulfilled', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Text('FREE Delivery. ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F1111))),
                        Text('Details', style: TextStyle(fontSize: 11, color: Colors.blue.shade700)),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Variant info (Image 1)
                    Text(
                      'Colour / Size : ${product.packSize}',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.unfold_more, size: 18, color: Colors.grey),
            ],
          ),

          const SizedBox(height: 8),

          // Date added (Image 1)
          Text(
            'Item added $dateAdded',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),

          // Farmer's Note (if added)
          if (note != null && note.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.edit_note, size: 16, color: Color(0xFFD97706)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Note: $note',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF92400E), fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Action Buttons matching Image 1: Add to Cart, Add a note, Move v, Share, Delete
          Row(
            children: [
              // Add to Cart yellow button (Image 1)
              ElevatedButton(
                onPressed: () {
                  _cart.addToCart(product);
                  final shortTitle = product.title.length > 25 ? '${product.title.substring(0, 22)}...' : product.title;
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Added $shortTitle to Cart!'),
                      backgroundColor: const Color(0xFF2E7D32),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      action: SnackBarAction(
                        label: 'CHECKOUT',
                        textColor: Colors.yellow,
                        onPressed: () {
                          if (!mounted) return;
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                          );
                        },
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD814),
                  foregroundColor: const Color(0xFF0F1111),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: const Text('Add to Cart', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),

              // Add a note button (Image 1)
              OutlinedButton(
                onPressed: () => _showAddNoteDialog(product),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: Text(
                  note != null && note.isNotEmpty ? 'Edit note' : 'Add a note',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF0F1111)),
                ),
              ),
              const SizedBox(width: 8),

              // Move v button (Image 1)
              OutlinedButton(
                onPressed: () => _showMoveMenu(product),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
                child: const Row(
                  children: [
                    Text('Move', style: TextStyle(fontSize: 12, color: Color(0xFF0F1111))),
                    SizedBox(width: 2),
                    Icon(Icons.keyboard_arrow_down, size: 14, color: Colors.grey),
                  ],
                ),
              ),
              const Spacer(),

              // Share Icon
              IconButton(
                icon: const Icon(Icons.share_outlined, size: 18, color: Colors.grey),
                onPressed: () {
                  final shortTitle = product.title.length > 25 ? '${product.title.substring(0, 22)}...' : product.title;
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Sharing $shortTitle link...'),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                },
              ),

              // Delete Icon (Image 1)
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                onPressed: () {
                  _cart.toggleWishlist(product.id);
                  final shortTitle = product.title.length > 25 ? '${product.title.substring(0, 22)}...' : product.title;
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Removed $shortTitle from Shopping List'),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      action: SnackBarAction(
                        label: 'UNDO',
                        textColor: const Color(0xFF81C784),
                        onPressed: () => _cart.toggleWishlist(product.id),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
