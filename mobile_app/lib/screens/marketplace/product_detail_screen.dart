// -*- coding: utf-8 -*-
import 'package:flutter/material.dart';
import 'marketplace_model.dart';
import 'marketplace_cart_service.dart';
import 'checkout_screen.dart';
import 'watchlist_screen.dart';

/// Product Detail Screen matching Image 4:
/// - Photo gallery with thumbnail carousel
/// - "Ask Rufus / Ask Kisan AI" quick chips with dynamic answers
/// - Brand store link, rating, best seller badge, bought in past month
/// - Pricing (-45% ₹549 M.R.P. ₹999), offers card, diamonds reward
/// - Delivery to Gaurav - Solan 173212, In Stock status
/// - Add to Cart & Buy Now buttons
/// - Target diseases, suitable crops, and dosage specs
class ProductDetailScreen extends StatefulWidget {
  final ProductItem product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final MarketplaceCartService _cart = MarketplaceCartService();
  int _selectedImageIndex = 0;
  int _selectedQuantity = 1;

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

  void _showKisanAiAnswer(String question, String answer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kisan AI Agronomy Assistant',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                        ),
                        Text(
                          'Verified Curing & Safety Guide',
                          style: TextStyle(fontSize: 12, color: Color(0xFF16A34A), fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const Divider(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F8F1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFC8E6C9)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.help_outline, size: 18, color: Color(0xFF2E7D32)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        question,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1B381E)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                answer,
                style: const TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF374151)),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(ctx).pop(),
                  icon: const Icon(Icons.check_circle_outline, size: 18, color: Colors.white),
                  label: const Text('Understood (समझ गया)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleAskChip(String topic) {
    final p = widget.product;
    String q = '';
    String a = '';

    if (topic.contains('weed') || topic.contains('cure') || topic.contains('disease')) {
      q = 'Which crop diseases and pests does ${p.title} cure?';
      a = '${p.title} by ${p.brand} is scientifically engineered to eliminate: ${p.targetDiseases.join(", ")}.\n\nIt is specifically recommended for ${p.suitableCrops.join(", ")}. It halts fungal mycelium reproduction and establishes a protective barrier on leaves and stems within 2 to 4 hours of spray.';
    } else if (topic.contains('made of') || topic.contains('composition')) {
      q = 'What is the active chemical composition of ${p.title}?';
      a = 'Active Ingredient: ${p.scientificName}.\n\nFormulation Grade: Certified agricultural grade with surfactant wetting agents for maximum leaf retention during heavy monsoon rains and high temperatures.';
    } else if (topic.contains('dosage') || topic.contains('how to use')) {
      q = 'What is the recommended dosage and spray method?';
      a = 'Recommended Dosage: ${p.dosage}.\n\nApplication Guide: Dissolve in clean water using a battery or knapsack sprayer. Spray during morning (7-10 AM) or evening (4-6 PM) when wind speed is low and leaves are dry. Always wear protective gloves and mask.';
    } else if (topic.contains('gardening') || topic.contains('crops')) {
      q = 'Is this product suitable for kitchen gardens and field crops?';
      a = 'Yes! It is highly effective for both commercial farm fields and domestic kitchen gardens cultivating ${p.suitableCrops.join(", ")}. Pack size of ${p.packSize} covers approximately 0.5 to 1.5 acres depending on crop foliage density.';
    } else {
      q = 'Specialist Agronomist Advice on ${p.title}';
      a = '${p.description}\n\nManufactured by ${p.brand}, tested under Indian agricultural ICAR field trials. Assured genuine with zero counterfeit risk.';
    }

    _showKisanAiAnswer(q, a);
  }

  void _addToCart() {
    _cart.addToCart(widget.product, quantity: _selectedQuantity);
    final shortTitle = widget.product.title.length > 25 ? '${widget.product.title.substring(0, 22)}...' : widget.product.title;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${_selectedQuantity}x $shortTitle to Cart!'),
        backgroundColor: const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
          label: 'VIEW CART',
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
  }

  void _buyNow() {
    _cart.addToCart(widget.product, quantity: _selectedQuantity);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CheckoutScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final isWish = _cart.isInWishlist(p.id);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Color(0xFF1E293B)),
            onPressed: () {
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Sharing product link with farming community...'),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(
              isWish ? Icons.favorite : Icons.favorite_border,
              color: isWish ? const Color(0xFFE11D48) : const Color(0xFF1E293B),
            ),
            tooltip: 'Shopping List / Watchlist',
            onPressed: () {
              _cart.toggleWishlist(p.id);
              final nowWish = _cart.isInWishlist(p.id);
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    nowWish ? 'Added to your Shopping List' : 'Removed from your Shopping List',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  backgroundColor: const Color(0xFF1B381E),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  action: nowWish
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
            },
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined, color: Color(0xFF1E293B)),
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
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        children: [
          // 1. Large Product Packshot & Carousel (Image 4)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          p.imageAsset,
                          height: 280,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Container(
                            height: 280,
                            color: const Color(0xFFF1F8F1),
                            child: const Icon(Icons.eco, size: 80, color: Color(0xFF2E7D32)),
                          ),
                        ),
                      ),
                    ),
                    // Click to see full view text
                    Positioned(
                      bottom: 4,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Text(
                          'Click to see full view',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Thumbnails row matching Image 4 ([1] [2] [3] [4] [5] +3)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final isSel = _selectedImageIndex == index;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedImageIndex = index),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSel ? const Color(0xFF007185) : Colors.grey.shade300,
                            width: isSel ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: Image.asset(
                            p.imageAsset,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  })..add(
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        '+3',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Ask Rufus / Ask Kisan AI section (Exact Match from Image 4)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE07A5F),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.auto_awesome, color: Colors.white, size: 14),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Ask Kisan AI',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Agronomist Instant Response',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF15803D)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildAiQuestionChip('Can it be used for weeding/cure?'),
                    _buildAiQuestionChip('What is it made of?'),
                    _buildAiQuestionChip('Recommended dosage?'),
                    _buildAiQuestionChip('Suitable crops?'),
                    _buildAiQuestionChip('Ask something else', isPrimary: true),
                  ],
                ),
              ],
            ),
          ),

          // 3. Product Title, Brand Store, Rating (Image 4)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                    color: Color(0xFF0F1111),
                  ),
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () {
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Opening ${p.brand} Official Authorized Agri-Store...'),
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  },
                  child: Text(
                    'Visit the ${p.brand} Store',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF007185),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Rating & Bestseller row
                Row(
                  children: [
                    Text(
                      '${p.rating}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(width: 4),
                    Row(
                      children: List.generate(5, (i) {
                        return Icon(
                          i < p.rating.floor()
                              ? Icons.star
                              : (i < p.rating ? Icons.star_half : Icons.star_border),
                          color: const Color(0xFFDE7921),
                          size: 16,
                        );
                      }),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '(${p.reviewCount})',
                      style: const TextStyle(color: Color(0xFF007185), fontSize: 13),
                    ),
                    const SizedBox(width: 10),
                    const Text('|', style: TextStyle(color: Colors.grey)),
                    const SizedBox(width: 10),
                    const Text('Search this page', style: TextStyle(color: Color(0xFF007185), fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: const BoxDecoration(
                        color: Color(0xFFC45500),
                        borderRadius: BorderRadius.all(Radius.circular(3)),
                      ),
                      child: Text(
                        '#1 Best Seller in ${p.category.displayName}',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${p.boughtLastMonth}+ bought in past month',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),

          const Divider(height: 24),

          // 4. Pricing & Discount Block (Exact match from Image 4)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '-${p.discountPercent}%',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFFCC0C39),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      '₹',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F1111)),
                    ),
                    Text(
                      p.price.toStringAsFixed(0),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F1111),
                      ),
                    ),
                    const Text(
                      ' 00',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0F1111)),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEBF8FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFBEE3F8)),
                      ),
                      child: const Text(
                        'Price history',
                        style: TextStyle(fontSize: 11, color: Color(0xFF2B6CB0), fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'M.R.P.: ₹${p.mrp.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (p.isAssured)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2874F0),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.verified, color: Colors.amber, size: 12),
                            SizedBox(width: 2),
                            Text(
                              'Assured',
                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Inclusive of all taxes',
                  style: TextStyle(fontSize: 12, color: Color(0xFF565959)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 5. Offers Card (Image 4)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.local_offer_outlined, size: 16, color: Color(0xFFC45500)),
                    SizedBox(width: 6),
                    Text('Offers', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Buy for ₹${p.price.toStringAsFixed(0)} + cashback',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Kisan Credit Card (KCC) UPI Flat ₹16 Off',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                  ],
                ),
                const Divider(height: 16),
                const Text(
                  'See all offers & discounts >',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF007185)),
                ),
              ],
            ),
          ),

          // 6. Diamonds Reward Card (Image 4)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.diamond_outlined, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Get ${(p.price * 0.1).round()} diamonds worth ₹${(p.price * 0.01).toStringAsFixed(1)} on this item',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
              ],
            ),
          ),

          // 7. Trust Value Badges (Image 4)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTrustIcon(Icons.local_shipping_outlined, 'Free Delivery'),
                _buildTrustIcon(Icons.payments_outlined, 'Pay on Delivery'),
                _buildTrustIcon(Icons.replay, '10 days\nReplacement'),
                _buildTrustIcon(Icons.security, 'Top Brand\nGuarantee'),
              ],
            ),
          ),

          const Divider(height: 24),

          // 8. Pack Size / Colour Selection Row (Image 4)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Colour / Size: ', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    Text(p.packSize, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFF007185), width: 1.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.asset(p.imageAsset, width: 36, height: 36, fit: BoxFit.cover),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.packSize, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              Text('₹${p.price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: Color(0xFF007185))),
                            ],
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 24),

          // 9. Delivery location & Stock (Image 4)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 18, color: Color(0xFF007185)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Deliver to ${_cart.deliveryName} - ${_cart.deliveryPincode.isNotEmpty ? "PIN ${_cart.deliveryPincode}" : "Live Location Selected"}',
                        style: const TextStyle(color: Color(0xFF007185), fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'In stock',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF007600)),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDF7EE),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Up to ₹60 cash back ₹20 per unit on buying 2+',
                    style: TextStyle(fontSize: 12, color: Color(0xFF1E3A1E), fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 12),

                // Quantity selector (Image 4)
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F2F2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFD5D9D9)),
                      ),
                      child: Row(
                        children: [
                          const Text('Quantity: ', style: TextStyle(fontSize: 13)),
                          DropdownButton<int>(
                            value: _selectedQuantity,
                            underline: const SizedBox(),
                            isDense: true,
                            items: List.generate(10, (i) => i + 1).map((qty) {
                              return DropdownMenuItem<int>(
                                value: qty,
                                child: Text('$qty', style: const TextStyle(fontWeight: FontWeight.bold)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedQuantity = val);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Yellow Add to Cart Button (Image 4)
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _addToCart,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD814),
                      foregroundColor: const Color(0xFF0F1111),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                    ),
                    child: const Text(
                      'Add to cart',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Orange Buy Now Button (Image 4)
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _buyNow,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFA41C),
                      foregroundColor: const Color(0xFF0F1111),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                    ),
                    child: const Text(
                      'Buy Now',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Ships from & Sold by details (Image 4)
                _buildInfoLine('Ships from', 'Krishi Saarthi Fulfillment'),
                _buildInfoLine('Sold by', '${p.brand} Official Dealer'),
                _buildInfoLine('Gift options', 'Available at checkout'),
                _buildInfoLine('Payment', 'Secure transaction'),
              ],
            ),
          ),

          const Divider(height: 28),

          // 10. Agronomy Curing Guide & Target Crop Specs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Curing & Agronomy Specifications',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F1111)),
                ),
                const SizedBox(height: 10),
                _buildSpecRow('Active Ingredient', p.scientificName),
                _buildSpecRow('Category', p.category.displayName),
                _buildSpecRow('Dosage per Acre', p.dosage),
                _buildSpecRow('Target Diseases', p.targetDiseases.join(', ')),
                _buildSpecRow('Suitable Crops', p.suitableCrops.join(', ')),
                const SizedBox(height: 12),
                const Text(
                  'Product Description',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F1111)),
                ),
                const SizedBox(height: 4),
                Text(
                  p.description,
                  style: const TextStyle(fontSize: 13, height: 1.5, color: Color(0xFF333333)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildAiQuestionChip(String text, {bool isPrimary = false}) {
    return InkWell(
      onTap: () => _handleAskChip(text.toLowerCase()),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isPrimary ? const Color(0xFF1E3A1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPrimary ? const Color(0xFF1E3A1E) : const Color(0xFF86EFAC),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isPrimary ? Colors.white : const Color(0xFF166534),
          ),
        ),
      ),
    );
  }

  Widget _buildTrustIcon(IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Icon(icon, color: const Color(0xFF374151), size: 22),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, color: Color(0xFF007185), height: 1.2),
        ),
      ],
    );
  }

  Widget _buildInfoLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF0F1111))),
        ],
      ),
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4B5563))),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 12, color: Color(0xFF111827))),
          ),
        ],
      ),
    );
  }
}
