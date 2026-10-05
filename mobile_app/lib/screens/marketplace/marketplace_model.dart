// -*- coding: utf-8 -*-
/// Krishi-Saarthi OS — Crop Marketplace Data Models & 40 Curated Products
/// Supporting Curing Products, Bio-Fertilizers, Pesticides, Seeds & Farm Tools
library;

enum ProductCategory {
  all,
  fungicides,
  insecticides,
  fertilizers,
  bioSolutions,
  farmTools,
  seeds,
}

extension ProductCategoryExt on ProductCategory {
  String get displayName {
    switch (this) {
      case ProductCategory.all:
        return 'All Products';
      case ProductCategory.fungicides:
        return 'Fungicides & Cures';
      case ProductCategory.insecticides:
        return 'Insecticides & Sprays';
      case ProductCategory.fertilizers:
        return 'Fertilizers & Nutri';
      case ProductCategory.bioSolutions:
        return 'Bio & Organic Cures';
      case ProductCategory.farmTools:
        return 'Tools & Equipment';
      case ProductCategory.seeds:
        return 'Certified Seeds';
    }
  }

  String get hindiName {
    switch (this) {
      case ProductCategory.all:
        return 'सभी उत्पाद';
      case ProductCategory.fungicides:
        return 'फफूंदनाशक व रोग दवा';
      case ProductCategory.insecticides:
        return 'कीटनाशक व स्प्रे';
      case ProductCategory.fertilizers:
        return 'खाद व पोषण';
      case ProductCategory.bioSolutions:
        return 'जैविक उपचार';
      case ProductCategory.farmTools:
        return 'कृषि औजार व मशीनें';
      case ProductCategory.seeds:
        return 'प्रमाणित बीज';
    }
  }
}

class ProductItem {
  final String id;
  final String title;
  final String scientificName;
  final String brand;
  final ProductCategory category;
  final String imageAsset;
  final double price;
  final double mrp;
  final String packSize;
  final double rating;
  final int reviewCount;
  final bool isAssured;
  final bool isSponsored;
  final bool isBestSeller;
  final List<String> targetDiseases;
  final List<String> suitableCrops;
  final String dosage;
  final String description;
  final String specialTag;
  final int boughtLastMonth;
  final bool inStock;

  const ProductItem({
    required this.id,
    required this.title,
    required this.scientificName,
    required this.brand,
    required this.category,
    required this.imageAsset,
    required this.price,
    required this.mrp,
    required this.packSize,
    required this.rating,
    required this.reviewCount,
    this.isAssured = true,
    this.isSponsored = false,
    this.isBestSeller = false,
    required this.targetDiseases,
    required this.suitableCrops,
    required this.dosage,
    required this.description,
    required this.specialTag,
    required this.boughtLastMonth,
    this.inStock = true,
  });

  int get discountPercent => (((mrp - price) / mrp) * 100).round();
}

class CartItem {
  final ProductItem product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get totalPrice => product.price * quantity;

  Map<String, dynamic> toJson() => {
    'productId': product.id,
    'quantity': quantity,
  };
}

enum OrderStatus {
  confirmed,
  packed,
  dispatched,
  outForDelivery,
  delivered,
  cancelled,
}

extension OrderStatusExt on OrderStatus {
  String get displayName {
    switch (this) {
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.packed:
        return 'Packed';
      case OrderStatus.dispatched:
        return 'Dispatched';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get label {
    switch (this) {
      case OrderStatus.confirmed:
        return 'Order Confirmed (पुष्टि हो गई)';
      case OrderStatus.packed:
        return 'Packed by Dealer (पैकिंग पूर्ण)';
      case OrderStatus.dispatched:
        return 'Dispatched via Krishi Logistics';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery to Farm (डिलीवरी जारी)';
      case OrderStatus.delivered:
        return 'Delivered Successfully (सफलतापूर्वक प्राप्त)';
      case OrderStatus.cancelled:
        return 'Order Cancelled (आदेश रद्द)';
    }
  }

  int get stepIndex {
    switch (this) {
      case OrderStatus.confirmed:
        return 0;
      case OrderStatus.packed:
        return 1;
      case OrderStatus.dispatched:
        return 2;
      case OrderStatus.outForDelivery:
        return 3;
      case OrderStatus.delivered:
        return 4;
      case OrderStatus.cancelled:
        return -1;
    }
  }
}

class OrderItemRecord {
  final String productId;
  final String title;
  final String brand;
  final String packSize;
  final double price;
  final int quantity;
  final String imageAsset;

  const OrderItemRecord({
    required this.productId,
    required this.title,
    required this.brand,
    required this.packSize,
    required this.price,
    required this.quantity,
    required this.imageAsset,
  });

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'title': title,
    'brand': brand,
    'packSize': packSize,
    'price': price,
    'quantity': quantity,
    'imageAsset': imageAsset,
  };

  factory OrderItemRecord.fromJson(Map<String, dynamic> json) => OrderItemRecord(
    productId: json['productId'] ?? '',
    title: json['title'] ?? '',
    brand: json['brand'] ?? '',
    packSize: json['packSize'] ?? '',
    price: (json['price'] as num?)?.toDouble() ?? 0.0,
    quantity: (json['quantity'] as num?)?.toInt() ?? 1,
    imageAsset: json['imageAsset'] ?? '',
  );
}

class MarketplaceOrder {
  final String orderId;
  final DateTime orderDate;
  final List<OrderItemRecord> items;
  final String recipientName;
  final String recipientPhone;
  final String deliveryAddress;
  final String deliveryPincode;
  final String paymentMethod;
  final String paymentStatus;
  final double subtotal;
  final double deliveryFee;
  final double marketplaceFee;
  final double subsidy;
  final double couponDiscount;
  final double totalPaid;
  final int diamondsEarned;
  final OrderStatus status;
  final String deliveryOtp;
  final String trackingNumber;
  final String? couponCode;
  final String? instructions;

  String get id => orderId;
  double get totalPayable => totalPaid;
  String get deliveryName => recipientName;
  String get deliveryPhone => recipientPhone;
  String get placedDateFormatted => '${orderDate.day}/${orderDate.month}/${orderDate.year}';
  String get estimatedDelivery => '${orderDate.add(const Duration(days: 4)).day} Oct 2026';
  String get checksum => 'KS-SHA256-${orderId.hashCode.abs().toRadixString(16).padLeft(16, "0")}';

  MarketplaceOrder({
    required this.orderId,
    required this.orderDate,
    required this.items,
    required this.recipientName,
    required this.recipientPhone,
    required this.deliveryAddress,
    required this.deliveryPincode,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.subtotal,
    required this.deliveryFee,
    required this.marketplaceFee,
    required this.subsidy,
    required this.couponDiscount,
    required this.totalPaid,
    required this.diamondsEarned,
    this.status = OrderStatus.confirmed,
    required this.deliveryOtp,
    required this.trackingNumber,
    this.couponCode,
    this.instructions,
  });

  MarketplaceOrder copyWith({
    String? orderId,
    DateTime? orderDate,
    List<OrderItemRecord>? items,
    String? recipientName,
    String? recipientPhone,
    String? deliveryAddress,
    String? deliveryPincode,
    String? paymentMethod,
    String? paymentStatus,
    double? subtotal,
    double? deliveryFee,
    double? marketplaceFee,
    double? subsidy,
    double? couponDiscount,
    double? totalPaid,
    int? diamondsEarned,
    OrderStatus? status,
    String? deliveryOtp,
    String? trackingNumber,
    String? couponCode,
    String? instructions,
  }) {
    return MarketplaceOrder(
      orderId: orderId ?? this.orderId,
      orderDate: orderDate ?? this.orderDate,
      items: items ?? this.items,
      recipientName: recipientName ?? this.recipientName,
      recipientPhone: recipientPhone ?? this.recipientPhone,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      deliveryPincode: deliveryPincode ?? this.deliveryPincode,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      subtotal: subtotal ?? this.subtotal,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      marketplaceFee: marketplaceFee ?? this.marketplaceFee,
      subsidy: subsidy ?? this.subsidy,
      couponDiscount: couponDiscount ?? this.couponDiscount,
      totalPaid: totalPaid ?? this.totalPaid,
      diamondsEarned: diamondsEarned ?? this.diamondsEarned,
      status: status ?? this.status,
      deliveryOtp: deliveryOtp ?? this.deliveryOtp,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      couponCode: couponCode ?? this.couponCode,
      instructions: instructions ?? this.instructions,
    );
  }

  Map<String, dynamic> toJson() => {
    'orderId': orderId,
    'orderDate': orderDate.toIso8601String(),
    'items': items.map((i) => i.toJson()).toList(),
    'recipientName': recipientName,
    'recipientPhone': recipientPhone,
    'deliveryAddress': deliveryAddress,
    'deliveryPincode': deliveryPincode,
    'paymentMethod': paymentMethod,
    'paymentStatus': paymentStatus,
    'subtotal': subtotal,
    'deliveryFee': deliveryFee,
    'marketplaceFee': marketplaceFee,
    'subsidy': subsidy,
    'couponDiscount': couponDiscount,
    'totalPaid': totalPaid,
    'diamondsEarned': diamondsEarned,
    'status': status.name,
    'deliveryOtp': deliveryOtp,
    'trackingNumber': trackingNumber,
    'couponCode': couponCode,
    'instructions': instructions,
  };

  factory MarketplaceOrder.fromJson(Map<String, dynamic> json) => MarketplaceOrder(
    orderId: json['orderId'] ?? '',
    orderDate: DateTime.tryParse(json['orderDate'] ?? '') ?? DateTime.now(),
    items: (json['items'] as List<dynamic>? ?? [])
        .map((i) => OrderItemRecord.fromJson(i as Map<String, dynamic>))
        .toList(),
    recipientName: json['recipientName'] ?? '',
    recipientPhone: json['recipientPhone'] ?? '',
    deliveryAddress: json['deliveryAddress'] ?? '',
    deliveryPincode: json['deliveryPincode'] ?? '',
    paymentMethod: json['paymentMethod'] ?? '',
    paymentStatus: json['paymentStatus'] ?? '',
    subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
    deliveryFee: (json['deliveryFee'] as num?)?.toDouble() ?? 0.0,
    marketplaceFee: (json['marketplaceFee'] as num?)?.toDouble() ?? 0.0,
    subsidy: (json['subsidy'] as num?)?.toDouble() ?? 0.0,
    couponDiscount: (json['couponDiscount'] as num?)?.toDouble() ?? 0.0,
    totalPaid: (json['totalPaid'] as num?)?.toDouble() ?? 0.0,
    diamondsEarned: (json['diamondsEarned'] as num?)?.toInt() ?? 0,
    status: OrderStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => OrderStatus.confirmed,
    ),
    deliveryOtp: json['deliveryOtp'] ?? '4921',
    trackingNumber: json['trackingNumber'] ?? 'KS-EXP-7729',
    couponCode: json['couponCode'],
    instructions: json['instructions'],
  );
}

class FilterState {
  ProductCategory category;
  double minPrice;
  double maxPrice;
  bool assuredOnly;
  Set<String> selectedBrands;
  double minRating;
  Set<String> selectedOffers;
  int minDiscount;

  FilterState({
    this.category = ProductCategory.all,
    this.minPrice = 50,
    this.maxPrice = 5000,
    this.assuredOnly = false,
    Set<String>? selectedBrands,
    this.minRating = 0.0,
    Set<String>? selectedOffers,
    this.minDiscount = 0,
  })  : selectedBrands = selectedBrands ?? {},
        selectedOffers = selectedOffers ?? {};

  FilterState copyWith({
    ProductCategory? category,
    double? minPrice,
    double? maxPrice,
    bool? assuredOnly,
    Set<String>? selectedBrands,
    double? minRating,
    Set<String>? selectedOffers,
    int? minDiscount,
  }) {
    return FilterState(
      category: category ?? this.category,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      assuredOnly: assuredOnly ?? this.assuredOnly,
      selectedBrands: selectedBrands ?? Set.from(this.selectedBrands),
      minRating: minRating ?? this.minRating,
      selectedOffers: selectedOffers ?? Set.from(this.selectedOffers),
      minDiscount: minDiscount ?? this.minDiscount,
    );
  }

  void reset() {
    category = ProductCategory.all;
    minPrice = 50;
    maxPrice = 5000;
    assuredOnly = false;
    selectedBrands.clear();
    minRating = 0.0;
    selectedOffers.clear();
    minDiscount = 0;
  }

  bool get isDefault =>
      category == ProductCategory.all &&
      minPrice == 50 &&
      maxPrice == 5000 &&
      !assuredOnly &&
      selectedBrands.isEmpty &&
      minRating == 0.0 &&
      selectedOffers.isEmpty &&
      minDiscount == 0;

  int get activeFilterCount {
    int count = 0;
    if (category != ProductCategory.all) count++;
    if (minPrice > 50 || maxPrice < 5000) count++;
    if (assuredOnly) count++;
    if (selectedBrands.isNotEmpty) count += selectedBrands.length;
    if (minRating > 0) count++;
    if (selectedOffers.isNotEmpty) count += selectedOffers.length;
    if (minDiscount > 0) count++;
    return count;
  }
}

/// 40 Curated Agricultural Curing Products, Fertilizers, Tools & Seeds
class MarketplaceCatalog {
  static ProductItem? findProductById(String id) {
    try {
      return allProducts.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  static List<ProductItem> filterProducts(FilterState filter) {
    return allProducts.where((p) {
      if (filter.category != ProductCategory.all && p.category != filter.category) {
        return false;
      }
      if (p.price < filter.minPrice || p.price > filter.maxPrice) {
        return false;
      }
      if (filter.assuredOnly && !p.isAssured) {
        return false;
      }
      if (filter.selectedBrands.isNotEmpty && !filter.selectedBrands.contains(p.brand)) {
        return false;
      }
      if (p.rating < filter.minRating) {
        return false;
      }
      if (filter.minDiscount > 0 && p.discountPercent < filter.minDiscount) {
        return false;
      }
      return true;
    }).toList();
  }

  static List<ProductItem> searchProducts(String query, {FilterState? filter}) {
    List<ProductItem> pool = filter != null ? filterProducts(filter) : allProducts;
    final cleanQ = query.trim().toLowerCase();
    if (cleanQ.isEmpty) return pool;

    // Check broad agricultural intent queries from search bar & popular searches
    final isGeneralAgriQuery = cleanQ == 'agriculture related product' ||
        cleanQ == 'agriculture product' ||
        cleanQ == 'agriculture related product in hindi' ||
        cleanQ == 'agriculture related product kit' ||
        cleanQ == 'agriculture related product book' ||
        cleanQ == 'agriculture products' ||
        cleanQ == 'kheti ke utpad' ||
        cleanQ == 'farming product';

    if (isGeneralAgriQuery) {
      return pool;
    }

    if (cleanQ.contains('lawn and gardening') || cleanQ.contains('lawn & gardening')) {
      final res = pool.where((p) => p.category == ProductCategory.farmTools || p.category == ProductCategory.seeds).toList();
      if (res.isNotEmpty) return res;
    }

    if (cleanQ.contains('equipment') || cleanQ.contains('tool') || cleanQ.contains('rake') || cleanQ.contains('khurpi')) {
      final res = pool.where((p) => p.category == ProductCategory.farmTools || p.title.toLowerCase().contains('tool') || p.title.toLowerCase().contains('rake')).toList();
      if (res.isNotEmpty) return res;
    }

    final stopWords = {'in', 'and', 'for', 'of', 'to', 'the', 'a', 'is', 'related', 'product', 'products'};
    final tokens = cleanQ
        .split(RegExp(r'[\s,]+'))
        .where((t) => t.isNotEmpty && !stopWords.contains(t))
        .toList();

    if (tokens.isEmpty) return pool;

    final scored = <ProductItem, int>{};

    for (final p in pool) {
      int score = 0;
      final titleLower = p.title.toLowerCase();
      final brandLower = p.brand.toLowerCase();
      final sciLower = p.scientificName.toLowerCase();
      final catLower = p.category.displayName.toLowerCase();
      final descLower = p.description.toLowerCase();
      final diseasesLower = p.targetDiseases.map((d) => d.toLowerCase()).join(' ');
      final cropsLower = p.suitableCrops.map((c) => c.toLowerCase()).join(' ');

      if (titleLower.contains(cleanQ)) score += 50;
      if (brandLower.contains(cleanQ)) score += 40;
      if (diseasesLower.contains(cleanQ)) score += 30;

      for (final t in tokens) {
        if (titleLower.contains(t)) score += 20;
        if (brandLower.contains(t)) score += 15;
        if (sciLower.contains(t)) score += 12;
        if (diseasesLower.contains(t)) score += 10;
        if (cropsLower.contains(t)) score += 8;
        if (catLower.contains(t)) score += 6;
        if (descLower.contains(t)) score += 4;
      }

      if (score > 0) {
        scored[p] = score;
      }
    }

    if (scored.isEmpty && filter != null && filter.category != ProductCategory.all) {
      // Fallback search across all products if current category had no match
      return searchProducts(query, filter: null);
    }

    final sortedList = scored.keys.toList()
      ..sort((a, b) => scored[b]!.compareTo(scored[a]!));
    return sortedList;
  }

  static final List<ProductItem> allProducts = [
    // ── 1. FUNGICIDES & CROP DISEASE CURES ──
    const ProductItem(
      id: 'prod_01',
      title: 'Saaf Fungicide (Carbendazim 12% + Mancozeb 63% WP)',
      scientificName: 'Carbendazim 12% + Mancozeb 63% WP',
      brand: 'UPL Agro',
      category: ProductCategory.fungicides,
      imageAsset: 'assets/images/prod_01.jpg',
      price: 240,
      mrp: 350,
      packSize: '500 g',
      rating: 4.8,
      reviewCount: 1420,
      isAssured: true,
      isBestSeller: true,
      targetDiseases: ['Leaf Blight', 'Anthracnose', 'Blast', 'Fruit Rot', 'Tikka'],
      suitableCrops: ['Tomato', 'Chilli', 'Potato', 'Groundnut', 'Paddy'],
      dosage: '2 g per litre of water (500 g per acre foliar spray)',
      description: 'Systemic and contact dual-action fungicide providing immediate curative and long-lasting preventive protection against severe fungal infections in fruit and vegetable crops.',
      specialTag: 'Big Kisan Days Price',
      boughtLastMonth: 540,
    ),
    const ProductItem(
      id: 'prod_02',
      title: 'Amistar Top (Azoxystrobin 18.2% + Difenoconazole 11.4% SC)',
      scientificName: 'Azoxystrobin 18.2% + Difenoconazole 11.4% SC',
      brand: 'Syngenta',
      category: ProductCategory.fungicides,
      imageAsset: 'assets/images/prod_02.jpg',
      price: 620,
      mrp: 850,
      packSize: '200 ml',
      rating: 4.9,
      reviewCount: 890,
      isAssured: true,
      isBestSeller: true,
      targetDiseases: ['Sheath Blight', 'Powdery Mildew', 'Alternaria Leaf Blight'],
      suitableCrops: ['Paddy', 'Tomato', 'Onion', 'Wheat', 'Chilli'],
      dosage: '1 ml per litre of water (200 ml per acre)',
      description: 'Broad-spectrum curative fungicide with translaminar movement for excellent control of sheath blight in paddy and yellow leaf spot in vegetable crops.',
      specialTag: 'Same Day Dispatch',
      boughtLastMonth: 410,
    ),
    const ProductItem(
      id: 'prod_03',
      title: 'Ridomil Gold (Metalaxyl-M 4% + Mancozeb 64% WP)',
      scientificName: 'Metalaxyl-M 4% + Mancozeb 64% WP',
      brand: 'Syngenta',
      category: ProductCategory.fungicides,
      imageAsset: 'assets/images/prod_03.jpg',
      price: 490,
      mrp: 680,
      packSize: '500 g',
      rating: 4.9,
      reviewCount: 2100,
      isAssured: true,
      isBestSeller: true,
      targetDiseases: ['Late Blight', 'Downy Mildew', 'White Rust'],
      suitableCrops: ['Potato', 'Tomato', 'Grapes', 'Mustard'],
      dosage: '2.5 g per litre of water (500 g per acre)',
      description: 'The global benchmark fungicide for stopping Late Blight in tomato and potato within 24 hours of application. Active uptake into new foliage.',
      specialTag: 'Krishi Verified Cure',
      boughtLastMonth: 890,
    ),
    const ProductItem(
      id: 'prod_04',
      title: 'Bavistin 50% WP (Carbendazim Systemic Fungicide)',
      scientificName: 'Carbendazim 50% WP',
      brand: 'Crystal Crop',
      category: ProductCategory.fungicides,
      imageAsset: 'assets/images/prod_04.jpg',
      price: 180,
      mrp: 260,
      packSize: '250 g',
      rating: 4.7,
      reviewCount: 950,
      isAssured: true,
      targetDiseases: ['Damping Off', 'Root Rot', 'Seedling Wilt', 'Smut'],
      suitableCrops: ['Cotton', 'Vegetables', 'Pulses', 'Oilseeds'],
      dosage: '2 g per kg seed treatment or 1.5 g per litre foliar spray',
      description: 'Cost-effective systemic fungicide ideal for seed treatment, root drenching, and preventive leaf wash against early-stage fungal damping off.',
      specialTag: 'Seed & Soil Ready',
      boughtLastMonth: 320,
    ),
    const ProductItem(
      id: 'prod_05',
      title: 'Blitox 50 WP (Copper Oxychloride 50% WP)',
      scientificName: 'Copper Oxychloride 50% WP',
      brand: 'Rallis India',
      category: ProductCategory.fungicides,
      imageAsset: 'assets/images/prod_05.jpg',
      price: 340,
      mrp: 450,
      packSize: '500 g',
      rating: 4.6,
      reviewCount: 620,
      isAssured: true,
      targetDiseases: ['Bacterial Leaf Spot', 'Citrus Canker', 'False Smut'],
      suitableCrops: ['Citrus', 'Apple', 'Tomato', 'Paddy', 'Potato'],
      dosage: '3 g per litre of water (600 g per acre)',
      description: 'Blue copper contact bactericide and fungicide forming a persistent protective shield over plant cuticle to stop bacterial entry.',
      specialTag: 'Anti-Bacterial Shield',
      boughtLastMonth: 280,
    ),
    const ProductItem(
      id: 'prod_06',
      title: 'Streptocycline 90:10 (Streptomycin + Tetracycline)',
      scientificName: 'Streptomycin Sulphate 90% + Tetracycline 10%',
      brand: 'Hindustan Antibiotics',
      category: ProductCategory.fungicides,
      imageAsset: 'assets/images/prod_06.jpg',
      price: 65,
      mrp: 95,
      packSize: '6 g x 5 Pcs',
      rating: 4.8,
      reviewCount: 3400,
      isAssured: true,
      targetDiseases: ['Bacterial Leaf Blight (BLB)', 'Black Arm', 'Canker'],
      suitableCrops: ['Paddy', 'Citrus', 'Pomegranate', 'Tomato'],
      dosage: '1 g per 10 litres of water with Copper Oxychloride',
      description: 'Potent agricultural antibiotic for eradication of severe bacterial infections and vein blackening across orchards and grain fields.',
      specialTag: 'Emergency BLB Cure',
      boughtLastMonth: 1250,
    ),
    const ProductItem(
      id: 'prod_07',
      title: 'Tilt 25% EC (Propiconazole Systemic Fungicide)',
      scientificName: 'Propiconazole 25% EC',
      brand: 'Syngenta',
      category: ProductCategory.fungicides,
      imageAsset: 'assets/images/prod_07.jpg',
      price: 380,
      mrp: 520,
      packSize: '250 ml',
      rating: 4.8,
      reviewCount: 1150,
      isAssured: true,
      targetDiseases: ['Yellow Rust', 'Brown Rust', 'Karnal Bunt', 'Tikka'],
      suitableCrops: ['Wheat', 'Paddy', 'Groundnut', 'Tea'],
      dosage: '1 ml per litre of water (200 ml per acre)',
      description: 'Specialist triazole fungicide recommended by ICAR for eradicating stripe rust in wheat and karnal bunt during heading stages.',
      specialTag: 'Wheat Rust Specialist',
      boughtLastMonth: 620,
    ),
    const ProductItem(
      id: 'prod_08',
      title: 'Nativo 75 WG (Tebuconazole 50% + Trifloxystrobin 25%)',
      scientificName: 'Tebuconazole 50% + Trifloxystrobin 25% WG',
      brand: 'Bayer CropScience',
      category: ProductCategory.fungicides,
      imageAsset: 'assets/images/prod_08.jpg',
      price: 720,
      mrp: 980,
      packSize: '100 g',
      rating: 4.9,
      reviewCount: 1840,
      isAssured: true,
      isBestSeller: true,
      targetDiseases: ['Neck Blast', 'Sheath Blight', 'Glume Blotch', 'Anthracnose'],
      suitableCrops: ['Paddy', 'Mango', 'Tomato', 'Grapes'],
      dosage: '0.8 g per litre of water (120 g per acre)',
      description: 'Advanced dual-systemic technology with greening effect that cures panicle blast and enhances grain shining and test weight.',
      specialTag: 'Premium Yield Booster',
      boughtLastMonth: 780,
    ),
    const ProductItem(
      id: 'prod_09',
      title: 'Aliette 80% WP (Fosetyl-Al Systemic Fungicide)',
      scientificName: 'Fosetyl-Al 80% WP',
      brand: 'Bayer CropScience',
      category: ProductCategory.fungicides,
      imageAsset: 'assets/images/prod_09.jpg',
      price: 430,
      mrp: 590,
      packSize: '250 g',
      rating: 4.7,
      reviewCount: 510,
      isAssured: true,
      targetDiseases: ['Phytophthora Foot Rot', 'Gummosis', 'Downy Mildew'],
      suitableCrops: ['Citrus', 'Cardamom', 'Grapes', 'Arecanut'],
      dosage: '2 g per litre of water or trunk paste',
      description: 'Unique two-way systemic action that travels both upwards and downwards to protect roots, crown, and stem from waterborne rot.',
      specialTag: 'Two-Way Systemic',
      boughtLastMonth: 210,
    ),
    const ProductItem(
      id: 'prod_10',
      title: 'Sultaf 80% WDG (Micronized Wettable Sulfur)',
      scientificName: 'Sulfur 80% WDG',
      brand: 'Rallis India',
      category: ProductCategory.fungicides,
      imageAsset: 'assets/images/prod_10.jpg',
      price: 210,
      mrp: 310,
      packSize: '1 kg',
      rating: 4.7,
      reviewCount: 830,
      isAssured: true,
      targetDiseases: ['Powdery Mildew', 'Red Spider Mites', 'Tikka'],
      suitableCrops: ['Grapes', 'Mango', 'Peas', 'Apple', 'Pulses'],
      dosage: '3 g per litre of water (600 g per acre)',
      description: 'Dual-action contact fungicide and acaricide that also feeds essential sulfur nutrient to oilseed and legume plants.',
      specialTag: 'Dual Mite & Mildew',
      boughtLastMonth: 440,
    ),

    // ── 2. INSECTICIDES & PEST CONTROL ──
    const ProductItem(
      id: 'prod_11',
      title: 'Coragen (Chlorantraniliprole 18.5% SC)',
      scientificName: 'Chlorantraniliprole 18.5% SC',
      brand: 'FMC Agro',
      category: ProductCategory.insecticides,
      imageAsset: 'assets/images/prod_11.jpg',
      price: 1120,
      mrp: 1490,
      packSize: '60 ml',
      rating: 4.9,
      reviewCount: 4200,
      isAssured: true,
      isBestSeller: true,
      targetDiseases: ['Stem Borer', 'Fruit Borer', 'Diamondback Moth (DBM)'],
      suitableCrops: ['Sugarcane', 'Rice', 'Tomato', 'Cabbage', 'Soybean'],
      dosage: '0.3 ml per litre of water (60 ml per acre)',
      description: 'Leading ryanodine receptor activator that stops insect feeding within minutes and provides up to 21 days of persistent borer control.',
      specialTag: 'Long-Lasting 21 Days',
      boughtLastMonth: 1400,
    ),
    const ProductItem(
      id: 'prod_12',
      title: 'Confidor 17.8% SL (Imidacloprid Systemic Insecticide)',
      scientificName: 'Imidacloprid 17.8% SL',
      brand: 'Bayer CropScience',
      category: ProductCategory.insecticides,
      imageAsset: 'assets/images/prod_12.jpg',
      price: 320,
      mrp: 450,
      packSize: '100 ml',
      rating: 4.8,
      reviewCount: 2900,
      isAssured: true,
      targetDiseases: ['Aphids', 'Jassids', 'Whiteflies', 'Thrips'],
      suitableCrops: ['Cotton', 'Chilli', 'Tomato', 'Okra', 'Paddy'],
      dosage: '0.5 ml per litre of water (100 ml per acre)',
      description: 'Fast systemic absorption controls sucking pests that transmit crop viral diseases like tomato leaf curl and chilli mosaic.',
      specialTag: 'Virus Vector Killer',
      boughtLastMonth: 950,
    ),
    const ProductItem(
      id: 'prod_13',
      title: 'Neem Baan Organic Bio-Pesticide (10,000 PPM)',
      scientificName: 'Cold Pressed Azadirachtin 10,000 PPM',
      brand: 'Multiplex Bio',
      category: ProductCategory.insecticides,
      imageAsset: 'assets/images/prod_13.jpg',
      price: 299,
      mrp: 450,
      packSize: '1 Litre',
      rating: 4.7,
      reviewCount: 1680,
      isAssured: true,
      targetDiseases: ['Whitefly', 'Leaf Miner', 'Caterpillar', 'Mites'],
      suitableCrops: ['Vegetables', 'Fruits', 'Cotton', 'Cereals'],
      dosage: '2.5 ml per litre of water',
      description: '100% natural cold-pressed neem seed extract. Disrupts insect molting and egg hatching without harming beneficial bees or soil flora.',
      specialTag: '100% Organic Certified',
      boughtLastMonth: 610,
    ),
    const ProductItem(
      id: 'prod_14',
      title: 'Hasper Organic Plant Guard & Protection Spray (Duo)',
      scientificName: 'Herbal Bio-Extract Botanical Pest Repellent',
      brand: 'Hasper Bio',
      category: ProductCategory.insecticides,
      imageAsset: 'assets/images/prod_14.jpg',
      price: 233,
      mrp: 499,
      packSize: '500 ml x 2 Pcs',
      rating: 4.6,
      reviewCount: 520,
      isAssured: true,
      isSponsored: true,
      targetDiseases: ['Mealybugs', 'Spider Mites', 'Aphids', 'Mildew'],
      suitableCrops: ['Kitchen Gardens', 'Vegetables', 'Greenhouse Plots'],
      dosage: 'Ready-to-spray dual spray bottle',
      description: 'Twin-pack botanical insect guard spray for instant eradication of garden pests, mealybugs and leaf curling insects.',
      specialTag: '53% Off Special Deal',
      boughtLastMonth: 380,
    ),
    const ProductItem(
      id: 'prod_15',
      title: 'Rogor 30% EC (Dimethoate Organophosphate)',
      scientificName: 'Dimethoate 30% EC',
      brand: 'FMC Chemicals',
      category: ProductCategory.insecticides,
      imageAsset: 'assets/images/prod_15.jpg',
      price: 190,
      mrp: 270,
      packSize: '250 ml',
      rating: 4.5,
      reviewCount: 890,
      isAssured: true,
      targetDiseases: ['Shoot Borer', 'Gall Midge', 'Leafhopper', 'Mites'],
      suitableCrops: ['Chilli', 'Mustard', 'Cotton', 'Vegetables'],
      dosage: '1.5 ml per litre of water',
      description: 'Trusted contact and systemic insecticide offering strong knockdown against resistant caterpillars and sucking insects.',
      specialTag: 'Fast Knockdown',
      boughtLastMonth: 310,
    ),
    const ProductItem(
      id: 'prod_16',
      title: 'Proclaim 5% SG (Emamectin Benzoate 5% SG)',
      scientificName: 'Emamectin Benzoate 5% SG',
      brand: 'Syngenta',
      category: ProductCategory.insecticides,
      imageAsset: 'assets/images/prod_16.jpg',
      price: 450,
      mrp: 620,
      packSize: '100 g',
      rating: 4.9,
      reviewCount: 1750,
      isAssured: true,
      isBestSeller: true,
      targetDiseases: ['Pod Borer (Helicoverpa)', 'Bollworm', 'Fall Armyworm'],
      suitableCrops: ['Gram', 'Pigeon Pea', 'Maize', 'Cotton', 'Tomato'],
      dosage: '0.5 g per litre of water (80 g per acre)',
      description: 'Advanced semi-synthetic caterpillar specialist. Quickly penetrates leaf tissue forming a toxic reservoir that kills borers on contact.',
      specialTag: 'Armyworm Terminator',
      boughtLastMonth: 720,
    ),

    // ── 3. FERTILIZERS & SOIL NUTRITION ──
    const ProductItem(
      id: 'prod_17',
      title: 'IFFCO Neem Coated Urea (46% Nitrogen Prills)',
      scientificName: 'Neem Coated Urea (46% N)',
      brand: 'IFFCO Kisan',
      category: ProductCategory.fertilizers,
      imageAsset: 'assets/images/prod_17.jpg',
      price: 266,
      mrp: 300,
      packSize: '45 kg Sack',
      rating: 4.9,
      reviewCount: 8900,
      isAssured: true,
      isBestSeller: true,
      targetDiseases: ['Nitrogen Deficiency', 'Stunted Growth', 'Leaf Yellowing'],
      suitableCrops: ['Wheat', 'Paddy', 'Sugarcane', 'Maize', 'All Crops'],
      dosage: '1 Bag per acre split into 2-3 top dressings',
      description: 'Neem oil coated urea slows down nitrification, preventing nitrogen leaching and boosting nitrogen use efficiency by 15-20%.',
      specialTag: 'Govt Controlled Rate',
      boughtLastMonth: 3100,
    ),
    const ProductItem(
      id: 'prod_18',
      title: 'IFFCO DAP 18:46:0 (Di-Ammonium Phosphate)',
      scientificName: 'Di-Ammonium Phosphate (18% N, 46% P2O5)',
      brand: 'IFFCO Kisan',
      category: ProductCategory.fertilizers,
      imageAsset: 'assets/images/prod_18.jpg',
      price: 1350,
      mrp: 1550,
      packSize: '50 kg Bag',
      rating: 4.9,
      reviewCount: 6400,
      isAssured: true,
      targetDiseases: ['Phosphorus Deficiency', 'Poor Rooting', 'Delayed Tillering'],
      suitableCrops: ['Wheat', 'Potato', 'Mustard', 'Pulses', 'Oilseeds'],
      dosage: '50 kg per acre as basal dose at sowing',
      description: 'High phosphate fertilizer essential for strong root proliferation, healthy seed germination, and early vegetative vigor.',
      specialTag: 'Basal Sowing Essential',
      boughtLastMonth: 2200,
    ),
    const ProductItem(
      id: 'prod_19',
      title: 'Mahafeed NPK 19-19-19 (100% Water Soluble)',
      scientificName: 'Balanced NPK 19:19:19 Micro-Crystals',
      brand: 'Mahafeed Fert',
      category: ProductCategory.fertilizers,
      imageAsset: 'assets/images/prod_19.jpg',
      price: 145,
      mrp: 220,
      packSize: '1 kg Pack',
      rating: 4.8,
      reviewCount: 2250,
      isAssured: true,
      targetDiseases: ['General Malnutrition', 'Slow Growth', 'Leaf Chlorosis'],
      suitableCrops: ['Vegetables', 'Fruits', 'Floriculture', 'Cereals'],
      dosage: '5 g per litre foliar spray or 3 kg per acre via drip',
      description: '100% water-soluble crystalline fertilizer with equal ratio of N-P-K. Fully absorbed through leaves within 4 hours.',
      specialTag: 'Drip & Spray Ready',
      boughtLastMonth: 1100,
    ),
    const ProductItem(
      id: 'prod_20',
      title: 'IFFCO Potash (Muriate of Potash MOP 0:0:60)',
      scientificName: 'Potassium Chloride (60% K2O)',
      brand: 'IFFCO Kisan',
      category: ProductCategory.fertilizers,
      imageAsset: 'assets/images/prod_20.jpg',
      price: 1650,
      mrp: 1900,
      packSize: '50 kg Bag',
      rating: 4.8,
      reviewCount: 3100,
      isAssured: true,
      targetDiseases: ['Potassium Deficiency', 'Weak Stems', 'Low Disease Defense'],
      suitableCrops: ['Paddy', 'Potato', 'Sugarcane', 'Cotton', 'Banana'],
      dosage: '25-50 kg per acre based on soil test report',
      description: 'Crucial for grain filling, disease resistance, drought resilience, and optimal sugar translocation into fruit bodies.',
      specialTag: 'Drought Defense',
      boughtLastMonth: 820,
    ),
    const ProductItem(
      id: 'prod_21',
      title: 'Aangi Plant Food Sticks / Nutrient Spikes (Pack of 30)',
      scientificName: 'Slow-Release NPK Micro-Nutrient Spike Tablets',
      brand: 'Aangienterprise',
      category: ProductCategory.fertilizers,
      imageAsset: 'assets/images/prod_21.jpg',
      price: 233,
      mrp: 499,
      packSize: 'Pack of 30',
      rating: 4.7,
      reviewCount: 740,
      isAssured: true,
      isSponsored: true,
      targetDiseases: ['Root Starvation', 'Pale Foliage', 'Slow Development'],
      suitableCrops: ['Potted Crops', 'Vegetable Plots', 'Nursery Beds'],
      dosage: 'Insert 2-4 sticks into soil near root perimeter every 60 days',
      description: 'Slow-release plant nutrient straightener sticks that feed nitrogen, phosphorus, and organic minerals steadily for 60 days without burning roots.',
      specialTag: '53% Off Special Deal',
      boughtLastMonth: 590,
    ),
    const ProductItem(
      id: 'prod_22',
      title: 'Chelated Zinc (Zn-EDTA 12% Micronutrient)',
      scientificName: 'Zinc EDTA 12% Chelate',
      brand: 'Aries Agro',
      category: ProductCategory.fertilizers,
      imageAsset: 'assets/images/prod_22.jpg',
      price: 175,
      mrp: 250,
      packSize: '500 g',
      rating: 4.8,
      reviewCount: 1340,
      isAssured: true,
      targetDiseases: ['Khaira Disease in Rice', 'Little Leaf', 'White Bud in Maize'],
      suitableCrops: ['Paddy', 'Maize', 'Citrus', 'Tomato', 'Wheat'],
      dosage: '1 g per litre of water (200 g per acre foliar spray)',
      description: 'Rapidly bioavailable chelated zinc formulation that prevents Khaira disease in paddy and cures stunted interveinal chlorosis.',
      specialTag: 'Khaira Disease Cure',
      boughtLastMonth: 680,
    ),
    const ProductItem(
      id: 'prod_23',
      title: 'Calcium Nitrate + Boron Granular Crop Nutrition',
      scientificName: 'Calcium Nitrate (18.8% Ca, 15.5% N) + 0.3% Boron',
      brand: 'YaraLiva',
      category: ProductCategory.fertilizers,
      imageAsset: 'assets/images/prod_23.jpg',
      price: 195,
      mrp: 280,
      packSize: '1 kg Pack',
      rating: 4.9,
      reviewCount: 1120,
      isAssured: true,
      targetDiseases: ['Blossom End Rot', 'Fruit Cracking', 'Poor Pollination'],
      suitableCrops: ['Tomato', 'Chilli', 'Pomegranate', 'Apple', 'Watermelon'],
      dosage: '4 g per litre of water during flowering and fruit setting',
      description: 'Strengthens plant cell walls, prevents bottom rot in tomato fruits, stops fruit skin cracking, and increases marketable shelf life.',
      specialTag: 'Fruit Cracking Cure',
      boughtLastMonth: 540,
    ),
    const ProductItem(
      id: 'prod_24',
      title: 'Humic Acid 98% (Super Potassium Humate Flakes)',
      scientificName: 'Potassium Humate 98% Bio-Stimulant',
      brand: 'Utkarsh Agro',
      category: ProductCategory.fertilizers,
      imageAsset: 'assets/images/prod_24.jpg',
      price: 320,
      mrp: 500,
      packSize: '1 kg Pack',
      rating: 4.8,
      reviewCount: 980,
      isAssured: true,
      targetDiseases: ['Hard Compact Soil', 'Weak Root Mass', 'Low Cation Exchange'],
      suitableCrops: ['All Field Crops', 'Vegetables', 'Orchards'],
      dosage: '1 g per litre of water or 1 kg per acre soil application',
      description: 'Unlocks fixed phosphorus in soil, stimulates massive white feeder root development, and enriches soil organic carbon index.',
      specialTag: 'Root Multiplier',
      boughtLastMonth: 460,
    ),

    // ── 4. BIO-FUNGICIDES & ORGANIC CURES ──
    const ProductItem(
      id: 'prod_25',
      title: 'Trichoderma Viride Bio-Fungicide (1% WP)',
      scientificName: 'Trichoderma viride 2x10^6 CFU/g',
      brand: 'Anand Agro',
      category: ProductCategory.bioSolutions,
      imageAsset: 'assets/images/prod_25.jpg',
      price: 160,
      mrp: 240,
      packSize: '1 kg Pack',
      rating: 4.8,
      reviewCount: 1520,
      isAssured: true,
      targetDiseases: ['Fusarium Wilt', 'Root Rot', 'Collar Rot', 'Rhizoctonia'],
      suitableCrops: ['Chilli', 'Tomato', 'Ginger', 'Turmeric', 'Pulses'],
      dosage: '5 g per kg seed treatment or 2 kg mixed with FYM per acre',
      description: 'Beneficial predatory fungus that aggressively colonizes plant roots, parasitizes harmful pathogenic fungi, and secretes natural chitinase enzymes.',
      specialTag: 'Soil Wilt Specialist',
      boughtLastMonth: 610,
    ),
    const ProductItem(
      id: 'prod_26',
      title: 'Pseudomonas Fluorescens Bio-Bactericide',
      scientificName: 'Pseudomonas fluorescens 1% WP',
      brand: 'IPL Biologicals',
      category: ProductCategory.bioSolutions,
      imageAsset: 'assets/images/prod_26.jpg',
      price: 170,
      mrp: 250,
      packSize: '1 kg Pack',
      rating: 4.7,
      reviewCount: 890,
      isAssured: true,
      targetDiseases: ['Bacterial Wilt (Ralstonia)', 'Sheath Rot', 'Canker'],
      suitableCrops: ['Brinjal', 'Tomato', 'Ginger', 'Banana', 'Paddy'],
      dosage: '10 g per litre for root dip or 2.5 kg per acre soil application',
      description: 'Eco-friendly biocontrol agent that secretes phenazine antibiotics, competing out Ralstonia bacterial wilt from rhizosphere zone.',
      specialTag: 'Anti-Wilt Bacteria',
      boughtLastMonth: 340,
    ),
    const ProductItem(
      id: 'prod_27',
      title: 'Seaweed Extract Bio-Stimulant (Kelp Supreme)',
      scientificName: 'Ascophyllum Nodosum Cold Enzymatic Extract',
      brand: 'Nature Bio',
      category: ProductCategory.bioSolutions,
      imageAsset: 'assets/images/prod_27.jpg',
      price: 380,
      mrp: 550,
      packSize: '1 Litre',
      rating: 4.9,
      reviewCount: 1230,
      isAssured: true,
      isBestSeller: true,
      targetDiseases: ['Frost Damage', 'Heat Stress', 'Flower Drop', 'Chlorosis'],
      suitableCrops: ['All Fruit Trees', 'Vegetables', 'Cotton', 'Wheat'],
      dosage: '2 ml per litre of water (400 ml per acre)',
      description: 'Cold-pressed natural plant growth regulator with cytokinins, auxins, and 60+ trace minerals to boost flower retention and frost immunity.',
      specialTag: 'Anti-Stress Tonic',
      boughtLastMonth: 690,
    ),
    const ProductItem(
      id: 'prod_28',
      title: 'Pure Organic Neem Cake Khali Granules',
      scientificName: 'De-oiled Azadirachta Indica Seed Cake',
      brand: 'Jaivik Kisan',
      category: ProductCategory.bioSolutions,
      imageAsset: 'assets/images/prod_28.jpg',
      price: 240,
      mrp: 360,
      packSize: '5 kg Sack',
      rating: 4.7,
      reviewCount: 1890,
      isAssured: true,
      targetDiseases: ['Termites (Dimak)', 'Root Nematodes', 'White Grubs'],
      suitableCrops: ['Potatoes', 'Vegetables', 'Orchards', 'Nurseries'],
      dosage: '100 kg per acre during field preparation',
      description: 'Natural soil amendment that deters underground termites and root-knot nematodes while slowly releasing nitrogen and organic carbon.',
      specialTag: 'Termite & Grub Deterrent',
      boughtLastMonth: 820,
    ),

    // ── 5. FARM TOOLS & EQUIPMENT ──
    const ProductItem(
      id: 'prod_29',
      title: 'Redbuild 8-Teeth Heavy Duty Weeding Rake (High Carbon Steel)',
      scientificName: '27cm High Carbon Forged Steel Multi-Tooth Weeder',
      brand: 'Redbuild Tools',
      category: ProductCategory.farmTools,
      imageAsset: 'assets/images/prod_29.jpg',
      price: 386,
      mrp: 1999,
      packSize: '27 cm Head',
      rating: 3.7,
      reviewCount: 470,
      isAssured: true,
      isSponsored: true,
      targetDiseases: ['Weed Infestation', 'Soil Crust', 'Poor Aeration'],
      suitableCrops: ['Field Beds', 'Kitchen Gardens', 'Orchard Basins'],
      dosage: 'Attach to standard wooden/iron pole for rapid manual weeding',
      description: 'Heavy gauge razor-sharp carbon steel rake head with 8 hardened teeth. Cuts through tough grass roots and loosens hardened topsoil in seconds.',
      specialTag: '80% Off Big Billion Deal',
      boughtLastMonth: 950,
    ),
    const ProductItem(
      id: 'prod_30',
      title: 'Kraft Seeds Garden Rake Head (8 Teeth) Heavy Duty Tool',
      scientificName: 'Forged Carbon Steel Garden Cleaning & Weeding Attachment',
      brand: 'Kraft Seeds',
      category: ProductCategory.farmTools,
      imageAsset: 'assets/images/prod_30.jpg',
      price: 549,
      mrp: 999,
      packSize: '8-Teeth Pro',
      rating: 4.8,
      reviewCount: 849,
      isAssured: true,
      isBestSeller: true,
      targetDiseases: ['Weeds', 'Fallen Leaves', 'Soil Clods', 'Compacted Beds'],
      suitableCrops: ['Terrace Gardens', 'Kitchen Plots', 'Field Lawns'],
      dosage: 'Fits standard 25mm pipe handle',
      description: '#1 Best Seller in agricultural rakes. Anti-rust powder coated steel teeth designed for heavy weeding, debris collection, and nursery seedbed leveling.',
      specialTag: '#1 Best Seller in Tools',
      boughtLastMonth: 1200,
    ),
    const ProductItem(
      id: 'prod_31',
      title: 'Green India Garden Khurpi for Medium Pots & Field',
      scientificName: 'Tempered Steel Hand Hoe with Ergonomic Handle',
      brand: 'Green India',
      category: ProductCategory.farmTools,
      imageAsset: 'assets/images/prod_31.jpg',
      price: 115,
      mrp: 249,
      packSize: '1 Tool',
      rating: 4.8,
      reviewCount: 1154,
      isAssured: true,
      targetDiseases: ['Root Weeds', 'Soil Compaction', 'Furrow Making'],
      suitableCrops: ['All Vegetable Plots', 'Nurseries', 'Field Borders'],
      dosage: 'Hand-operated tool for deep root extraction',
      description: 'Traditional heavy-duty tempered steel khurpi with seamless wooden grip. Perfect for inter-culture weeding between closely spaced crop rows.',
      specialTag: '53% Off Super Deal',
      boughtLastMonth: 1450,
    ),
    const ProductItem(
      id: 'prod_32',
      title: 'Green India 4-Piece Garden & Nursery Hand Tool Set',
      scientificName: 'Trowel + Cultivator + Transplanter + Weeding Fork Set',
      brand: 'Green India',
      category: ProductCategory.farmTools,
      imageAsset: 'assets/images/prod_32.jpg',
      price: 280,
      mrp: 599,
      packSize: '4 Tools Set',
      rating: 4.6,
      reviewCount: 890,
      isAssured: true,
      targetDiseases: ['Transplant Shock', 'Hard Soil', 'Seedling Handling'],
      suitableCrops: ['Nurseries', 'Greenhouses', 'Raised Beds'],
      dosage: 'Complete set for transplanting, soil aeration and digging',
      description: 'High visibility orange grip gardening kit with anti-corrosive powder finish. Ideal for delicate seedling transplantation and fertilizer mixing.',
      specialTag: 'Complete Nursery Kit',
      boughtLastMonth: 490,
    ),
    const ProductItem(
      id: 'prod_33',
      title: 'Neptune 16-Litre 12V Battery Knapsack Sprayer',
      scientificName: '16L Polypropylene Tank with 12V 8Ah Rechargeable Pump',
      brand: 'Neptune Agro',
      category: ProductCategory.farmTools,
      imageAsset: 'assets/images/prod_33.jpg',
      price: 2450,
      mrp: 3800,
      packSize: '16 Litres',
      rating: 4.8,
      reviewCount: 3120,
      isAssured: true,
      isBestSeller: true,
      targetDiseases: ['Inefficient Spraying', 'Manual Pumping Fatigue', 'Uneven Coverage'],
      suitableCrops: ['All Field Crops', 'Cotton', 'Orchards', 'Vegetables'],
      dosage: 'Sprays up to 25-30 tanks on a single 4-hour charge',
      description: 'Heavy duty pressure pump sprayer delivering steady atomized mist for uniform leaf coverage of fungicides and micronutrients without manual fatigue.',
      specialTag: 'Kisan Mechanization Star',
      boughtLastMonth: 610,
    ),
    const ProductItem(
      id: 'prod_34',
      title: 'Heavy Duty Climbing Plant Trellis Net (Creeper Support)',
      scientificName: 'UV Stabilized High Density Polyethylene Netting (2m x 10m)',
      brand: 'Agri Shield',
      category: ProductCategory.farmTools,
      imageAsset: 'assets/images/prod_34.jpg',
      price: 199,
      mrp: 450,
      packSize: '2m x 10m',
      rating: 4.5,
      reviewCount: 620,
      isAssured: true,
      targetDiseases: ['Fruit Ground Rot', 'Fungal Spoilage', 'Crooked Vegetables'],
      suitableCrops: ['Cucumber', 'Tomato', 'Bitter Gourd', 'Peas', 'Beans'],
      dosage: 'Mount vertically or horizontally on bamboo/iron poles',
      description: 'Trellis net keeps fruits off wet soil, dramatically reducing ground blight, improving sunlight exposure and doubling yield quality.',
      specialTag: '55% Off Harvest Booster',
      boughtLastMonth: 430,
    ),
    const ProductItem(
      id: 'prod_35',
      title: 'Digital 3-in-1 Soil pH, Moisture & Sunlight Meter',
      scientificName: 'Dual-Probe Analog Galvanic Soil Condition Sensor',
      brand: 'Krishi Tech',
      category: ProductCategory.farmTools,
      imageAsset: 'assets/images/prod_35.jpg',
      price: 349,
      mrp: 799,
      packSize: '1 Piece',
      rating: 4.4,
      reviewCount: 1430,
      isAssured: true,
      targetDiseases: ['Over-Watering', 'Acidic/Alkaline Soil', 'Nutrient Lockup'],
      suitableCrops: ['All Farm Soils', 'Greenhouse Substrates', 'Orchards'],
      dosage: 'Insert dual probes 4-6 inches into moist soil for instant dial readout',
      description: 'Battery-free scientific soil testing probe. Read instant soil pH from 3.5 to 8.0 and moisture level from 1 to 10 before irrigating or applying fertilizer.',
      specialTag: 'Smart Farm Sensor',
      boughtLastMonth: 780,
    ),
    const ProductItem(
      id: 'prod_36',
      title: 'Micro Drip Irrigation 50-Plant Starter Kit',
      scientificName: 'Complete Drip Kit with 16mm Mainline + 4mm Tubing + Drippers',
      brand: 'Jain Agro',
      category: ProductCategory.farmTools,
      imageAsset: 'assets/images/prod_36.jpg',
      price: 599,
      mrp: 1299,
      packSize: '50 Plants Set',
      rating: 4.7,
      reviewCount: 890,
      isAssured: true,
      targetDiseases: ['Water Wastage', 'Weed Germination in Furrows', 'Root Stress'],
      suitableCrops: ['Vegetables', 'Fruit Rows', 'Drip Plots'],
      dosage: 'Direct root zone slow dripping (up to 70% water savings)',
      description: 'Ready-to-install micro drip kit with pressure compensating drippers, tee connectors, and punch tool. Delivers water and liquid fertilizer straight to roots.',
      specialTag: '70% Water Saver',
      boughtLastMonth: 340,
    ),

    // ── 6. CERTIFIED HIGH-YIELD SEEDS ──
    const ProductItem(
      id: 'prod_37',
      title: 'Natural & Herbal Kitchen Garden Seeds (Okra / Bhindi)',
      scientificName: 'Abelmoschus esculentus High Yield Hybrid Seeds',
      brand: 'Natural Herbal',
      category: ProductCategory.seeds,
      imageAsset: 'assets/images/prod_37.jpg',
      price: 213,
      mrp: 299,
      packSize: '10 g Pack',
      rating: 4.5,
      reviewCount: 310,
      isAssured: true,
      targetDiseases: ['Yellow Vein Mosaic Virus (YVMV)', 'Enation Leaf Curl'],
      suitableCrops: ['Summer & Rainy Season Farms'],
      dosage: 'Sow at 45cm x 15cm spacing (1.5 - 2 kg per acre)',
      description: 'Certified dark green tender 5-ridged okra seeds with built-in genetic resistance to devastating Yellow Vein Mosaic Virus (YVMV).',
      specialTag: 'Only few left in stock',
      boughtLastMonth: 410,
    ),
    const ProductItem(
      id: 'prod_38',
      title: 'Syngenta Abhinav F1 Hybrid Tomato Seeds',
      scientificName: 'Solanum lycopersicum F1 Hybrid',
      brand: 'Syngenta Seeds',
      category: ProductCategory.seeds,
      imageAsset: 'assets/images/prod_38.jpg',
      price: 780,
      mrp: 950,
      packSize: '10 g (3000s)',
      rating: 4.9,
      reviewCount: 2410,
      isAssured: true,
      isBestSeller: true,
      targetDiseases: ['Tomato Leaf Curl Virus (ToLCV)', 'Bacterial Wilt'],
      suitableCrops: ['Rabi & Kharif Vegetable Belts'],
      dosage: '40-50 g nursery seeds per acre',
      description: 'Indias most trusted tomato hybrid. Produces firm, attractive red fruits (80-100g) with excellent long-distance transportability and 35+ tonne/acre potential.',
      specialTag: '#1 Market Tomato',
      boughtLastMonth: 1100,
    ),
    const ProductItem(
      id: 'prod_39',
      title: 'Mahyco F1 Hybrid Chilli Seeds (Teja 4)',
      scientificName: 'Capsicum annuum F1 Hybrid',
      brand: 'Mahyco Seeds',
      category: ProductCategory.seeds,
      imageAsset: 'assets/images/prod_39.jpg',
      price: 460,
      mrp: 580,
      packSize: '10 g Pack',
      rating: 4.8,
      reviewCount: 1790,
      isAssured: true,
      targetDiseases: ['Chilli Murda Virus', 'Thrips Attack', 'Powdery Mildew'],
      suitableCrops: ['Irrigated & Dryland Chilli Plots'],
      dosage: '80-100 g nursery seeds per acre',
      description: 'High pungency glossy dark red hybrid chilli. Outstanding tolerance to sucking pest leaf curl complexes with prolific continuous bearing.',
      specialTag: 'High Export Value',
      boughtLastMonth: 730,
    ),
    const ProductItem(
      id: 'prod_40',
      title: 'Bayer Arize 6444 Gold Hybrid Paddy (Rice) Seeds',
      scientificName: 'Oryza sativa Hybrid Rice (Arize Gold)',
      brand: 'Bayer Seeds',
      category: ProductCategory.seeds,
      imageAsset: 'assets/images/prod_40.jpg',
      price: 890,
      mrp: 1050,
      packSize: '3 kg Bag',
      rating: 4.9,
      reviewCount: 5200,
      isAssured: true,
      isBestSeller: true,
      targetDiseases: ['Bacterial Leaf Blight (BLB)', 'Blast', 'Stem Rot'],
      suitableCrops: ['Kharif & Boro Rice Ecosystems'],
      dosage: '6 kg seeds per acre',
      description: 'Gold-standard hybrid rice featuring dual gene BLB protection, vigorous tillering (20-25 tillers per hill), non-lodging thick stems, and 25-30% higher paddy yield.',
      specialTag: '25% Higher Harvest',
      boughtLastMonth: 1850,
    ),
  ];
}
