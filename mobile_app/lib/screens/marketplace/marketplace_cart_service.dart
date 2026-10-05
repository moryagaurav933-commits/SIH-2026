import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_config.dart';
import 'marketplace_model.dart';

class MarketplaceCartService extends ChangeNotifier {
  static final MarketplaceCartService _instance = MarketplaceCartService._internal();
  factory MarketplaceCartService() => _instance;
  MarketplaceCartService._internal() {
    _loadFromStorage();
  }

  static const String _kCartKey = 'ks_marketplace_cart_v1';
  static const String _kWishlistKey = 'ks_marketplace_wishlist_v1';
  static const String _kNotesKey = 'ks_marketplace_notes_v1';
  static const String _kDatesKey = 'ks_marketplace_dates_v1';
  static const String _kOrdersKey = 'ks_marketplace_orders_v1';
  static const String _kKccBalanceKey = 'ks_marketplace_kcc_balance_v1';
  static const String _kProfileKey = 'ks_marketplace_profile_v1';

  static const List<Map<String, String>> randomFarmingAddresses = [
    {
      'name': 'Kisan Vikas Seva Kendra',
      'phone': '+91 98765 43210',
      'pincode': '132001',
      'address': 'Plot No. 44, Kisan Mandi Yard, Near Krishi Bhavan, Karnal, Haryana, 132001, India',
    },
    {
      'name': 'Greenfield Organic Agri Farm',
      'phone': '+91 98123 45678',
      'pincode': '203202',
      'address': 'Farm Unit #8, Post Bilaspur, Greater Noida, Gautam Buddha Nagar, Uttar Pradesh, 203202, India',
    },
    {
      'name': 'Progressive Kisan Collective',
      'phone': '+91 98450 11223',
      'pincode': '141114',
      'address': 'VPO Samrala, Agro Industrial Corridor, District Ludhiana, Punjab, 141114, India',
    },
    {
      'name': 'Himachal High-Density Orchard',
      'phone': '+91 98160 55443',
      'pincode': '171001',
      'address': 'Block C, Model Horticulture Demonstration Zone, Shimla, Himachal Pradesh, 171001, India',
    },
    {
      'name': 'Krishi Vigyan Kendra Demonstration Farm',
      'phone': '+91 94140 88990',
      'pincode': '302017',
      'address': 'Kisan Training Complex, Tonk Road, Jaipur Rural, Rajasthan, 302017, India',
    },
  ];

  final List<CartItem> _items = [];
  final Set<String> _wishlistIds = {'prod_29', 'prod_01', 'prod_30'}; // 8-teeth rake, Saaf, Khurpi
  final Map<String, String> _notes = {};
  final Map<String, String> _dates = {
    'prod_29': '1 October 2026',
    'prod_01': '15 September 2026',
    'prod_30': '28 September 2026',
  };
  final List<MarketplaceOrder> _orders = [];
  double _kccWalletBalance = 2500.0;

  String deliveryName = 'Kisan Vikas Hub';
  String deliveryPhone = '+91 98765 43210';
  String deliveryPincode = '132001';
  String deliveryAddress =
      'Plot No. 44, Kisan Mandi Yard, Near Krishi Bhavan, Karnal, Haryana, 132001, India';
  bool isLiveLocation = false;
  bool isDetectingLocation = false;

  List<CartItem> get items => List.unmodifiable(_items);
  Set<String> get wishlistIds => Set.unmodifiable(_wishlistIds);
  List<MarketplaceOrder> get orders => List.unmodifiable(_orders);
  double get kccWalletBalance => _kccWalletBalance;

  int get totalItemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  double get subtotal => _items.fold(0.0, (sum, item) => sum + item.totalPrice);
  double get deliveryFee => subtotal > 499 || _items.isEmpty ? 0.0 : 40.0;
  double get marketplaceFee => _items.isEmpty ? 0.0 : 5.0;
  double get kisanSubsidy => subtotal >= 300 ? 40.0 : 0.0;
  double get finalTotal => (_items.isEmpty ? 0.0 : (subtotal + deliveryFee + marketplaceFee - kisanSubsidy)).clamp(0.0, 999999.0);
  int get diamondsEarned => (finalTotal * 0.1).round();

  bool isInWishlist(String productId) => _wishlistIds.contains(productId);

  String? getNote(String productId) => _notes[productId];

  String getAddedDate(String productId) => _dates[productId] ?? '1 October 2026';

  void setNote(String productId, String note) {
    if (note.trim().isEmpty) {
      _notes.remove(productId);
    } else {
      _notes[productId] = note.trim();
    }
    _saveToStorage();
    notifyListeners();
  }

  bool toggleWishlist(String productId) {
    final wasIn = _wishlistIds.contains(productId);
    if (wasIn) {
      _wishlistIds.remove(productId);
      _dates.remove(productId);
      _notes.remove(productId);
    } else {
      _wishlistIds.add(productId);
      final now = DateTime.now();
      _dates[productId] = '${now.day} ${_monthName(now.month)} ${now.year}';
    }
    _saveToStorage();
    notifyListeners();
    return !wasIn;
  }

  void addToCart(ProductItem product, {int quantity = 1}) {
    final existingIndex = _items.indexWhere((item) => item.product.id == product.id);
    if (existingIndex >= 0) {
      _items[existingIndex].quantity += quantity;
    } else {
      _items.add(CartItem(product: product, quantity: quantity));
    }
    _saveToStorage();
    notifyListeners();
  }

  void updateQuantity(String productId, int quantity) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      if (quantity <= 0) {
        _items.removeAt(index);
      } else {
        _items[index].quantity = quantity;
      }
      _saveToStorage();
      notifyListeners();
    }
  }

  void removeFromCart(String productId) {
    _items.removeWhere((item) => item.product.id == productId);
    _saveToStorage();
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    _saveToStorage();
    notifyListeners();
  }

  void updateAddress({
    required String name,
    required String address,
    String? phone,
    String? pincode,
    bool isLive = false,
  }) {
    deliveryName = name;
    deliveryAddress = address;
    isLiveLocation = isLive;
    if (phone != null && phone.isNotEmpty) deliveryPhone = phone;
    if (pincode != null && pincode.isNotEmpty) deliveryPincode = pincode;
    _saveToStorage();
    notifyListeners();
  }

  void setRandomAddress() {
    final list = List<Map<String, String>>.from(randomFarmingAddresses)..shuffle();
    final rand = list.first;
    deliveryName = rand['name']!;
    deliveryPhone = rand['phone']!;
    deliveryPincode = rand['pincode']!;
    deliveryAddress = rand['address']!;
    isLiveLocation = false;
    _saveToStorage();
    notifyListeners();
  }

  Future<bool> detectAndSetLiveLocation({bool force = false}) async {
    if (isDetectingLocation) return false;
    if (isLiveLocation && !force) return true;

    isDetectingLocation = true;
    notifyListeners();

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        isDetectingLocation = false;
        notifyListeners();
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          isDetectingLocation = false;
          notifyListeners();
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        isDetectingLocation = false;
        notifyListeners();
        return false;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );

      final result = await _reverseGeocodeToAddress(pos.latitude, pos.longitude);
      if (result != null) {
        deliveryAddress = result['address'] ?? deliveryAddress;
        if (result['pincode'] != null && result['pincode']!.isNotEmpty) {
          deliveryPincode = result['pincode']!;
        }
        if (result['city'] != null && result['city']!.isNotEmpty) {
          deliveryName = 'Verified Farmer (${result['city']})';
        } else {
          deliveryName = 'Verified Farmer (Live GPS)';
        }
        isLiveLocation = true;
        _saveToStorage();
        isDetectingLocation = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      if (kDebugMode) print('detectAndSetLiveLocation error: $e');
    }

    isDetectingLocation = false;
    notifyListeners();
    return false;
  }

  Future<Map<String, String>?> _reverseGeocodeToAddress(double lat, double lon) async {
    // 1. BigDataCloud reverse geocode (Fast, reliable, CORS enabled for Web)
    try {
      final url = Uri.parse(
        'https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=$lat&longitude=$lon&localityLanguage=en',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final city = (data['city'] as String?)?.trim() ?? '';
        final locality = (data['locality'] as String?)?.trim() ?? '';
        final state = (data['principalSubdivision'] as String?)?.trim() ?? '';
        final country = (data['countryName'] as String?)?.trim() ?? 'India';
        final postcode = (data['postcode'] as String?)?.trim() ?? '';

        final List<String> parts = [];
        if (locality.isNotEmpty) parts.add(locality);
        if (city.isNotEmpty && !parts.contains(city)) parts.add(city);
        if (state.isNotEmpty && !parts.contains(state)) parts.add(state);
        if (postcode.isNotEmpty) parts.add(postcode);
        parts.add(country);

        final fullAddress = 'Farm Unit, ${parts.join(', ')}';
        return {
          'address': fullAddress,
          'city': city.isNotEmpty ? city : (locality.isNotEmpty ? locality : state),
          'pincode': postcode.isNotEmpty ? postcode : deliveryPincode,
        };
      }
    } catch (_) {}

    // 2. OpenStreetMap Nominatim fallback
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon&zoom=18&addressdetails=1',
      );
      final response = await http.get(
        url,
        headers: {'User-Agent': 'KrishiSaarthiApp/1.0 (kisan@krishisaarthi.in)'},
      ).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final addr = data['address'] as Map<String, dynamic>?;
        final displayName = (data['display_name'] as String?)?.trim() ?? '';
        final postcode = (addr?['postcode'] as String?)?.trim() ?? '';
        final city = (addr?['city'] ?? addr?['town'] ?? addr?['village'] ?? addr?['county'] ?? '').toString();

        if (displayName.isNotEmpty) {
          return {
            'address': 'Farm Premise, $displayName',
            'city': city,
            'pincode': postcode.isNotEmpty ? postcode : deliveryPincode,
          };
        }
      }
    } catch (_) {}

    return {
      'address': 'Farm GPS Position: ${lat.toStringAsFixed(4)}°N, ${lon.toStringAsFixed(4)}°E, India',
      'city': 'Regional Farm',
      'pincode': deliveryPincode,
    };
  }

  void topUpKccWallet(double amount) {
    _kccWalletBalance += amount;
    _saveToStorage();
    notifyListeners();
  }

  Future<MarketplaceOrder> placeOrder({
    required String paymentMethod,
    String paymentStatus = 'PAID',
    double couponDiscount = 0.0,
    String? couponCode,
    String? instructions,
  }) async {
    final orderId = 'KS-2026-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final trackingNumber = 'KSEXP-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
    final otp = '${(1000 + (DateTime.now().millisecond * 9) % 9000).toInt()}';

    final orderItems = _items.map((i) {
      return OrderItemRecord(
        productId: i.product.id,
        title: i.product.title,
        brand: i.product.brand,
        packSize: i.product.packSize,
        price: i.product.price,
        quantity: i.quantity,
        imageAsset: i.product.imageAsset,
      );
    }).toList();

    final paidAmount = (finalTotal - couponDiscount).clamp(0.0, 999999.0);

    if (paymentMethod.contains('KCC') || paymentMethod.contains('Wallet')) {
      if (_kccWalletBalance >= paidAmount) {
        _kccWalletBalance -= paidAmount;
      }
    }

    final newOrder = MarketplaceOrder(
      orderId: orderId,
      orderDate: DateTime.now(),
      items: orderItems,
      recipientName: deliveryName,
      recipientPhone: deliveryPhone,
      deliveryAddress: deliveryAddress,
      deliveryPincode: deliveryPincode,
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus,
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      marketplaceFee: marketplaceFee,
      subsidy: kisanSubsidy,
      couponDiscount: couponDiscount,
      totalPaid: paidAmount,
      diamondsEarned: diamondsEarned,
      status: OrderStatus.confirmed,
      deliveryOtp: otp,
      trackingNumber: trackingNumber,
      couponCode: couponCode,
      instructions: instructions,
    );

    _orders.insert(0, newOrder);
    _items.clear();
    await _saveToStorage();
    notifyListeners();

    // Asynchronous backend synchronization (persists to central PostgreSQL DB)
    _syncOrderToBackend(newOrder);

    return newOrder;
  }

  Future<void> _syncOrderToBackend(MarketplaceOrder order) async {
    try {
      final payload = {
        'items': order.items.map((i) => {
          'product_id': i.productId,
          'title': i.title,
          'brand': i.brand,
          'pack_size': i.packSize,
          'price': i.price,
          'quantity': i.quantity,
          'image_asset': i.imageAsset,
        }).toList(),
        'recipient_name': order.recipientName,
        'recipient_phone': order.recipientPhone,
        'delivery_address': order.deliveryAddress,
        'delivery_pincode': order.deliveryPincode,
        'payment_method': order.paymentMethod,
        'payment_status': order.paymentStatus,
        'coupon_code': order.couponCode,
        'instructions': order.instructions,
      };

      final res = await http.post(
        Uri.parse(ApiConfig.marketplaceOrdersUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode == 201) {
        final data = jsonDecode(res.body);
        final serverOtp = data['delivery_otp'] as String?;
        final serverTracking = data['tracking_number'] as String?;

        final idx = _orders.indexWhere((o) => o.orderId == order.orderId);
        if (idx != -1 && (serverOtp != null || serverTracking != null)) {
          _orders[idx] = _orders[idx].copyWith(
            deliveryOtp: serverOtp ?? _orders[idx].deliveryOtp,
            trackingNumber: serverTracking ?? _orders[idx].trackingNumber,
          );
          await _saveToStorage();
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Marketplace sync note: running in resilient local mode ($e)');
    }
  }

  Future<void> cancelOrder(String orderId) async {
    final idx = _orders.indexWhere((o) => o.orderId == orderId);
    if (idx != -1) {
      final old = _orders[idx];
      _orders[idx] = old.copyWith(status: OrderStatus.cancelled);
      if (old.paymentMethod.toLowerCase().contains('kcc') || old.paymentMethod.toLowerCase().contains('wallet')) {
        _kccWalletBalance += old.totalPaid;
      }
      await _saveToStorage();
      notifyListeners();

      // Sync cancellation to backend
      _syncCancelToBackend(orderId);
    }
  }

  Future<void> _syncCancelToBackend(String orderId) async {
    try {
      final uri = Uri.parse('${ApiConfig.marketplaceOrdersUrl}/$orderId/cancel');
      await http.post(uri).timeout(const Duration(seconds: 3));
    } catch (_) {}
  }

  /// Validates coupon online with backend, with offline fallback
  Future<Map<String, dynamic>> validateCouponOnline(String code, double orderAmount) async {
    try {
      final res = await http.post(
        Uri.parse(ApiConfig.marketplaceCouponsValidateUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'code': code.trim().toUpperCase(),
          'order_amount': orderAmount,
        }),
      ).timeout(const Duration(seconds: 3));

      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (_) {}

    // Offline / local fallback
    final c = code.trim().toUpperCase();
    if (c == 'KISAN50' && orderAmount >= 299) {
      final disc = (orderAmount * 0.15).clamp(0.0, 150.0);
      return {'valid': true, 'discount_amount': disc, 'message': '15% Kisan Subsidy applied (up to ₹150)'};
    } else if (c == 'SIH2026' && orderAmount >= 499) {
      return {'valid': true, 'discount_amount': 100.0, 'message': '₹100 SIH-2026 Mega Ag-Grant applied'};
    } else if (c == 'CROP2026' && orderAmount >= 399) {
      final disc = (orderAmount * 0.10).clamp(0.0, 200.0);
      return {'valid': true, 'discount_amount': disc, 'message': '10% Smart Crop Protection applied'};
    }
    return {'valid': false, 'discount_amount': 0.0, 'message': 'Invalid coupon code or minimum requirement not met'};
  }

  // ─── Local Database Persistence ───
  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // 1. Cart
      final cartJsonList = _items.map((i) => i.toJson()).toList();
      await prefs.setString(_kCartKey, jsonEncode(cartJsonList));

      // 2. Wishlist
      await prefs.setStringList(_kWishlistKey, _wishlistIds.toList());

      // 3. Notes & Dates
      await prefs.setString(_kNotesKey, jsonEncode(_notes));
      await prefs.setString(_kDatesKey, jsonEncode(_dates));

      // 4. Orders
      final ordersJson = _orders.map((o) => o.toJson()).toList();
      await prefs.setString(_kOrdersKey, jsonEncode(ordersJson));

      // 5. Wallet
      await prefs.setDouble(_kKccBalanceKey, _kccWalletBalance);

      // 6. Profile
      await prefs.setString(
        _kProfileKey,
        jsonEncode({
          'name': deliveryName,
          'phone': deliveryPhone,
          'address': deliveryAddress,
          'pincode': deliveryPincode,
          'isLive': isLiveLocation,
        }),
      );
    } catch (e) {
      if (kDebugMode) print('Storage save error: $e');
    }
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Wishlist
      final savedWish = prefs.getStringList(_kWishlistKey);
      if (savedWish != null && savedWish.isNotEmpty) {
        _wishlistIds.clear();
        _wishlistIds.addAll(savedWish);
      }

      // Notes
      final notesStr = prefs.getString(_kNotesKey);
      if (notesStr != null) {
        final decoded = jsonDecode(notesStr) as Map<String, dynamic>;
        _notes.clear();
        decoded.forEach((k, v) => _notes[k] = v.toString());
      }

      // Dates
      final datesStr = prefs.getString(_kDatesKey);
      if (datesStr != null) {
        final decoded = jsonDecode(datesStr) as Map<String, dynamic>;
        _dates.clear();
        decoded.forEach((k, v) => _dates[k] = v.toString());
      }

      // KCC Wallet
      final savedBal = prefs.getDouble(_kKccBalanceKey);
      if (savedBal != null) {
        _kccWalletBalance = savedBal;
      }

      // Profile
      final profStr = prefs.getString(_kProfileKey);
      if (profStr != null) {
        final d = jsonDecode(profStr) as Map<String, dynamic>;
        deliveryName = d['name'] ?? deliveryName;
        deliveryPhone = d['phone'] ?? deliveryPhone;
        deliveryAddress = d['address'] ?? deliveryAddress;
        deliveryPincode = d['pincode'] ?? deliveryPincode;
        isLiveLocation = d['isLive'] ?? false;
      }

      // Safety check: Purge any personal address traces from old cached storage
      if (deliveryAddress.toLowerCase().contains('osho') ||
          deliveryAddress.toLowerCase().contains('parwati') ||
          deliveryAddress.toLowerCase().contains('majhgaon') ||
          deliveryAddress.toLowerCase().contains('centa rosa')) {
        final rand = randomFarmingAddresses.first;
        deliveryName = rand['name']!;
        deliveryPhone = rand['phone']!;
        deliveryPincode = rand['pincode']!;
        deliveryAddress = rand['address']!;
        isLiveLocation = false;
        _saveToStorage();
      }

      // Orders
      final ordersStr = prefs.getString(_kOrdersKey);
      if (ordersStr != null) {
        final list = jsonDecode(ordersStr) as List<dynamic>;
        _orders.clear();
        for (final item in list) {
          _orders.add(MarketplaceOrder.fromJson(item as Map<String, dynamic>));
        }
      }

      // Cart
      final cartStr = prefs.getString(_kCartKey);
      if (cartStr != null) {
        final list = jsonDecode(cartStr) as List<dynamic>;
        _items.clear();
        for (final item in list) {
          final pid = item['productId'];
          final qty = (item['quantity'] as num?)?.toInt() ?? 1;
          final prod = MarketplaceCatalog.allProducts.firstWhere(
            (p) => p.id == pid,
            orElse: () => MarketplaceCatalog.allProducts.first,
          );
          _items.add(CartItem(product: prod, quantity: qty));
        }
      }
      notifyListeners();

      // Automatically detect and write live location into address
      detectAndSetLiveLocation();
    } catch (e) {
      if (kDebugMode) print('Storage load error: $e');
    }
  }

  String _monthName(int m) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[(m - 1).clamp(0, 11)];
  }
}
