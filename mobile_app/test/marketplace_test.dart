// -*- coding: utf-8 -*-
import 'package:flutter_test/flutter_test.dart';
import 'package:krishi_saarthi/screens/marketplace/marketplace_model.dart';
import 'package:krishi_saarthi/screens/marketplace/marketplace_cart_service.dart';

import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('Krishi Marketplace Catalog & Model Tests', () {
    test('Catalog contains 40 authentic products', () {
      expect(MarketplaceCatalog.allProducts.length, equals(40));
    });

    test('All 40 products have valid curing specs, prices, and assets', () {
      for (final p in MarketplaceCatalog.allProducts) {
        expect(p.id.isNotEmpty, isTrue);
        expect(p.title.isNotEmpty, isTrue);
        expect(p.scientificName.isNotEmpty, isTrue);
        expect(p.brand.isNotEmpty, isTrue);
        expect(p.price, greaterThan(0));
        expect(p.mrp, greaterThanOrEqualTo(p.price));
        expect(p.discountPercent, greaterThanOrEqualTo(0));
        expect(p.imageAsset.startsWith('assets/images/prod_'), isTrue);
        expect(p.targetDiseases.isNotEmpty, isTrue);
        expect(p.suitableCrops.isNotEmpty, isTrue);
        expect(p.dosage.isNotEmpty, isTrue);
      }
    });

    test('Filter products by category returns correct subsets', () {
      final filterFungicides = FilterState(category: ProductCategory.fungicides);
      final fungicides = MarketplaceCatalog.filterProducts(filterFungicides);
      expect(fungicides.isNotEmpty, isTrue);
      for (final item in fungicides) {
        expect(item.category, equals(ProductCategory.fungicides));
      }

      final filterTools = FilterState(category: ProductCategory.farmTools);
      final tools = MarketplaceCatalog.filterProducts(filterTools);
      expect(tools.isNotEmpty, isTrue);
      for (final item in tools) {
        expect(item.category, equals(ProductCategory.farmTools));
      }
    });

    test('Filter products by brand and assured status', () {
      final filterBrand = FilterState(
        selectedBrands: {'Syngenta'},
        assuredOnly: true,
      );
      final syngentaProds = MarketplaceCatalog.filterProducts(filterBrand);
      expect(syngentaProds.isNotEmpty, isTrue);
      for (final item in syngentaProds) {
        expect(item.brand, equals('Syngenta'));
        expect(item.isAssured, isTrue);
      }
    });
  });

  group('Marketplace Cart & Wishlist Service Tests', () {
    late MarketplaceCartService cart;

    setUp(() {
      cart = MarketplaceCartService();
      cart.clearCart();
    });

    test('Adding products updates quantity and subtotal', () {
      final p1 = MarketplaceCatalog.allProducts[0];
      final p2 = MarketplaceCatalog.allProducts[1];

      cart.addToCart(p1, quantity: 2);
      expect(cart.totalItemCount, equals(2));
      expect(cart.subtotal, equals(p1.price * 2));

      cart.addToCart(p2, quantity: 1);
      expect(cart.totalItemCount, equals(3));
      expect(cart.subtotal, equals(p1.price * 2 + p2.price));
      expect(cart.items.length, equals(2));
    });

    test('Quantity increment, decrement, and removal', () {
      final p1 = MarketplaceCatalog.allProducts[0];
      cart.addToCart(p1, quantity: 2);

      cart.updateQuantity(p1.id, 5);
      expect(cart.totalItemCount, equals(5));

      cart.updateQuantity(p1.id, 0); // Should remove from cart
      expect(cart.totalItemCount, equals(0));
      expect(cart.items.isEmpty, isTrue);
    });

    test('Kisan Subsidy and Free Delivery threshold', () {
      final pLow = MarketplaceCatalog.allProducts.firstWhere((p) => p.price < 300);
      cart.addToCart(pLow, quantity: 1);

      // Under ₹300: no subsidy, delivery fee applies
      expect(cart.subtotal, equals(pLow.price));
      expect(cart.deliveryFee, equals(40.0));
      expect(cart.kisanSubsidy, equals(0.0));

      // Over ₹300: ₹40 Kisan subsidy applies
      final pHigh = MarketplaceCatalog.allProducts.firstWhere((p) => p.price >= 300);
      cart.clearCart();
      cart.addToCart(pHigh, quantity: 1);
      expect(cart.subtotal, greaterThanOrEqualTo(300.0));
      expect(cart.kisanSubsidy, equals(40.0));
    });

    test('Wishlist toggling persists state', () {
      const prodId = 'prod_05';
      final initial = cart.isInWishlist(prodId);
      cart.toggleWishlist(prodId);
      expect(cart.isInWishlist(prodId), equals(!initial));
      cart.toggleWishlist(prodId);
      expect(cart.isInWishlist(prodId), equals(initial));
    });

    test('Address updating preserves Gaurav Morya Solan details', () {
      cart.updateAddress(name: 'Gaurav Morya', address: 'Solan HP 173212');
      expect(cart.deliveryName, equals('Gaurav Morya'));
      expect(cart.deliveryAddress, contains('Solan'));
    });

    test('Shopping list notes and date tracking', () {
      const prodId = 'prod_01';
      cart.setNote(prodId, 'Need for apple orchard spray');
      expect(cart.getNote(prodId), equals('Need for apple orchard spray'));
      expect(cart.getAddedDate(prodId).isNotEmpty, isTrue);
    });

    test('Order placement generates tamper-proof OTP and persists record', () async {
      cart.clearCart();
      final product = MarketplaceCatalog.allProducts.first;
      cart.addToCart(product, quantity: 1);

      final initialWallet = cart.kccWalletBalance;
      final order = await cart.placeOrder(
        paymentMethod: 'KCC Digital Card (₹$initialWallet)',
      );

      expect(order.items.length, equals(1));
      expect(order.deliveryOtp.length, equals(4));
      expect(order.status, equals(OrderStatus.confirmed));
      expect(cart.orders.contains(order), isTrue);
      expect(cart.items.isEmpty, isTrue); // Cart cleared after checkout
    });
  });

  group('Marketplace Multi-Token & Popular Search Intent Tests', () {
    test('Search for specific product "Saaf" finds Carbendazim WP', () {
      final results = MarketplaceCatalog.searchProducts('Saaf');
      expect(results.isNotEmpty, isTrue);
      expect(results.any((p) => p.title.toLowerCase().contains('saaf')), isTrue);
    });

    test('Popular query "Lawn and Gardening" finds farm tools and weeders', () {
      final results = MarketplaceCatalog.searchProducts('Lawn and Gardening');
      expect(results.isNotEmpty, isTrue);
      expect(results.any((p) => p.category == ProductCategory.farmTools || p.category == ProductCategory.bioSolutions), isTrue);
    });

    test('Query "agriculture related product in Lawn and Gardening" resolves gracefully', () {
      final results = MarketplaceCatalog.searchProducts('agriculture related product in Lawn and Gardening');
      expect(results.isNotEmpty, isTrue);
    });

    test('Scientific name search for "Azoxystrobin" finds Amistar Top', () {
      final results = MarketplaceCatalog.searchProducts('Azoxystrobin');
      expect(results.isNotEmpty, isTrue);
      expect(results.any((p) => p.scientificName.contains('Azoxystrobin')), isTrue);
    });

    test('Crop-specific search "Apple scab" finds matching cures', () {
      final results = MarketplaceCatalog.searchProducts('Apple');
      expect(results.isNotEmpty, isTrue);
      expect(results.any((p) => p.suitableCrops.any((c) => c.toLowerCase().contains('apple'))), isTrue);
    });
  });
}
