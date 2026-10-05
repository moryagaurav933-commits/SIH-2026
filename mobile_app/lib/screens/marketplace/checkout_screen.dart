import 'package:flutter/material.dart';
import 'marketplace_model.dart';
import 'marketplace_cart_service.dart';
import 'my_orders_screen.dart';

enum PaymentOption {
  kccWallet,
  cards,
  netBanking,
  upiScan,
  emi,
  cashOnDelivery,
}

/// Checkout Screen matching Image 5:
/// - Delivering to Gaurav Morya, Solan HP with change option & instructions
/// - Payment methods: KCC balance, Cards, Net Banking, Scan & Pay with UPI, COD
/// - Arriving by 5 Oct 2026 preview with product thumbnail
/// - Price Breakdown (Items, Delivery, Marketplace Fee, Kisan Subsidy, Order Total, Diamonds)
/// - Interactive UPI QR Code dialog & Order Placement Confirmation
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final MarketplaceCartService _cart = MarketplaceCartService();
  PaymentOption _selectedPayment = PaymentOption.upiScan;
  String _selectedBank = 'State Bank of India (SBI)';
  final TextEditingController _couponController = TextEditingController();
  final TextEditingController _instructionController = TextEditingController();
  bool _couponApplied = false;
  double _couponDiscount = 0.0;
  bool _showInstructionsField = false;

  final List<String> _bankOptions = [
    'State Bank of India (SBI)',
    'Punjab National Bank (PNB)',
    'HDFC Bank',
    'ICICI Bank',
    'Bank of Baroda',
    'Himachal Pradesh State Cooperative Bank',
  ];

  @override
  void initState() {
    super.initState();
    _cart.addListener(_onCartChanged);
    // If cart is empty, add a default product so the screen matches Image 5 right away
    if (_cart.items.isEmpty && MarketplaceCatalog.allProducts.isNotEmpty) {
      _cart.addToCart(MarketplaceCatalog.allProducts.first, quantity: 1);
    }
    // Automatically detect and set live location in address section
    _cart.detectAndSetLiveLocation();
  }

  @override
  void dispose() {
    _cart.removeListener(_onCartChanged);
    _couponController.dispose();
    _instructionController.dispose();
    super.dispose();
  }

  void _onCartChanged() {
    if (mounted) setState(() {});
  }

  double get _finalPayable => (_cart.finalTotal - _couponDiscount).clamp(0.0, 999999.0);

  Future<void> _applyCoupon() async {
    final code = _couponController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    final result = await _cart.validateCouponOnline(code, _cart.subtotal);
    if (!mounted) return;

    if (result['valid'] == true) {
      final discount = (result['discount_amount'] as num?)?.toDouble() ?? 50.0;
      final msg = result['message'] as String? ?? 'Coupon applied successfully!';
      setState(() {
        _couponApplied = true;
        _couponDiscount = discount;
      });
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 $msg'),
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else {
      final msg = result['message'] as String? ?? 'Invalid coupon code. Try KISAN50 or SIH2026.';
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _showUpiQrModal() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDF7EE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.qr_code_scanner, color: Color(0xFF2E7D32), size: 24),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('Scan & Pay via UPI', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Scan with any UPI App (GPay, PhonePe, Paytm, BHIM, KCC UPI)',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Container(
                width: 200,
                height: 200,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(Icons.qr_code_2, size: 140, color: Colors.grey.shade800),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Color(0xFF2E7D32),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.agriculture, color: Colors.white, size: 20),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Paying: ₹${_finalPayable.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 4),
              const Text(
                'UPI ID: krishisaarthi@sbi',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF007185)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _placeOrder();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Simulate UPI Approved', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showChangeAddressDialog() {
    final nameCtrl = TextEditingController(text: _cart.deliveryName);
    final phoneCtrl = TextEditingController(text: _cart.deliveryPhone);
    final pincodeCtrl = TextEditingController(text: _cart.deliveryPincode);
    final addrCtrl = TextEditingController(text: _cart.deliveryAddress);
    String? errorText;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.edit_location_alt, color: Color(0xFF2E7D32), size: 22),
                  SizedBox(width: 8),
                  Text('Edit Delivery Address', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (errorText != null)
                      Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFDC2626)),
                        ),
                        child: Text(errorText!, style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              setModalState(() => errorText = null);
                              final ok = await _cart.detectAndSetLiveLocation(force: true);
                              if (ok) {
                                nameCtrl.text = _cart.deliveryName;
                                phoneCtrl.text = _cart.deliveryPhone;
                                pincodeCtrl.text = _cart.deliveryPincode;
                                addrCtrl.text = _cart.deliveryAddress;
                                setModalState(() {});
                              } else {
                                setModalState(() => errorText = 'Location unavailable or permission denied. Please allow GPS or choose a random farm address.');
                              }
                            },
                            icon: _cart.isDetectingLocation
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2E7D32)),
                                  )
                                : const Icon(Icons.my_location, size: 16, color: Color(0xFF2E7D32)),
                            label: const Text('Live GPS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF2E7D32)),
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              _cart.setRandomAddress();
                              nameCtrl.text = _cart.deliveryName;
                              phoneCtrl.text = _cart.deliveryPhone;
                              pincodeCtrl.text = _cart.deliveryPincode;
                              addrCtrl.text = _cart.deliveryAddress;
                              setModalState(() {});
                            },
                            icon: const Icon(Icons.shuffle, size: 16, color: Color(0xFF007185)),
                            label: const Text('Random Farm', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF007185))),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF007185)),
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Farmer / Recipient Full Name',
                        prefixIcon: Icon(Icons.person_outline, size: 20),
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: '10-Digit Mobile Number (For Delivery OTP)',
                        prefixIcon: Icon(Icons.phone_outlined, size: 20),
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: pincodeCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '6-Digit Postal PIN Code',
                        prefixIcon: Icon(Icons.pin_drop_outlined, size: 20),
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: addrCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Farm Address / Village / Tehsil',
                        prefixIcon: Icon(Icons.home_outlined, size: 20),
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    final phone = phoneCtrl.text.trim();
                    final pin = pincodeCtrl.text.trim();
                    final addr = addrCtrl.text.trim();

                    if (name.isEmpty) {
                      setModalState(() => errorText = 'Please enter recipient name');
                      return;
                    }
                    if (phone.length < 10) {
                      setModalState(() => errorText = 'Please enter a valid 10-digit mobile number');
                      return;
                    }
                    if (pin.length < 6) {
                      setModalState(() => errorText = 'Please enter a valid 6-digit postal PIN code');
                      return;
                    }
                    if (addr.isEmpty) {
                      setModalState(() => errorText = 'Please enter full farm or village address');
                      return;
                    }

                    _cart.updateAddress(
                      name: name,
                      address: addr,
                      phone: phone,
                      pincode: pin,
                    );
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Delivery address saved successfully!'),
                        backgroundColor: const Color(0xFF2E7D32),
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Save Address', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _placeOrder() async {
    if (_cart.items.isEmpty) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Your cart is empty!'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    // Check KCC balance
    if (_selectedPayment == PaymentOption.kccWallet && _cart.kccWalletBalance < _finalPayable) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.account_balance_wallet_outlined, color: Color(0xFFD97706)),
              SizedBox(width: 8),
              Text('KCC Balance Low', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            'Your KCC Wallet balance is ₹${_cart.kccWalletBalance.toStringAsFixed(2)}, but order total is ₹${_finalPayable.toStringAsFixed(2)}.\n\nWould you like to top up your Kisan Credit Card wallet by ₹2,000 via DBT / Jan Dhan Account?',
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                _cart.topUpKccWallet(2000.0);
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('KCC Wallet credited ₹2,000! Proceeding with payment.'),
                    backgroundColor: const Color(0xFF2E7D32),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
                _placeOrder();
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
              child: const Text('Top Up ₹2,000 & Pay', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      return;
    }

    // Place real persistent order in SharedPreferences
    final order = await _cart.placeOrder(
      paymentMethod: _selectedPayment.name,
      paymentStatus: _selectedPayment == PaymentOption.cashOnDelivery ? 'PENDING_COD' : 'PAID',
      couponCode: _couponApplied ? _couponController.text.trim().toUpperCase() : null,
      couponDiscount: _couponDiscount,
      instructions: _instructionController.text.trim(),
    );

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.all(22),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: const BoxDecoration(
                  color: Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 50),
              ),
              const SizedBox(height: 14),
              const Text(
                'Order Placed Successfully!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
              ),
              const SizedBox(height: 4),
              Text(
                'Order ID: #${order.id}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF007185)),
              ),
              const SizedBox(height: 12),
              // Farm Delivery OTP Security Banner
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFF59E0B)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.security, color: Color(0xFFB45309), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Delivery Security OTP', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF92400E))),
                          Text('Share only upon physical inspection', style: TextStyle(fontSize: 10, color: Colors.brown.shade700)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
                      child: Text(
                        order.deliveryOtp,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Color(0xFF92400E)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Amount Paid:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text('₹${order.totalPayable.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Estimated Delivery:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text(order.estimatedDelivery, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Delivery To:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Expanded(
                          child: Text(
                            '${order.deliveryName} (${order.deliveryPhone})',
                            textAlign: TextAlign.right,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock, size: 12, color: Color(0xFF16A34A)),
                  SizedBox(width: 4),
                  Text(
                    '256-Bit Encrypted • Saved in SharedPreferences DB',
                    style: TextStyle(fontSize: 10.5, color: Color(0xFF16A34A), fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        Navigator.of(context).pop();
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Continue Shopping', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => MyOrdersScreen(highlightOrderId: order.id)),
                        );
                      },
                      icon: const Icon(Icons.local_shipping, size: 16, color: Colors.white),
                      label: const Text('Track Order', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _cart.items;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Checkout & Payment',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined, color: Color(0xFF1E293B)),
            tooltip: 'My Orders & Tracking',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
              );
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 12),
                  const Text('Your cart is empty', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
                    child: const Text('Browse Marketplace', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              children: [
                // 1. Delivering to Gaurav Morya card (Exact match from Image 5)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(Icons.location_on, color: Color(0xFF2874F0), size: 18),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'Delivering to ${_cart.deliveryName}',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF111827),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (_cart.isLiveLocation) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDCFCE7),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: const Color(0xFF86EFAC)),
                                    ),
                                    child: const Text(
                                      'LIVE GPS',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF15803D),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_cart.isDetectingLocation)
                                const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2874F0)),
                                )
                              else
                                InkWell(
                                  onTap: () async {
                                    await _cart.detectAndSetLiveLocation(force: true);
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: const Padding(
                                    padding: EdgeInsets.all(4.0),
                                    child: Icon(Icons.my_location, size: 16, color: Color(0xFF2874F0)),
                                  ),
                                ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: _showChangeAddressDialog,
                                child: const Text(
                                  'Change',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF007185),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _cart.deliveryAddress,
                        style: TextStyle(fontSize: 13, height: 1.4, color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 10),
                      InkWell(
                        onTap: () {
                          setState(() {
                            _showInstructionsField = !_showInstructionsField;
                          });
                        },
                        child: Text(
                          _showInstructionsField ? '- Hide delivery instructions' : '+ Add delivery instructions',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF007185)),
                        ),
                      ),
                      if (_showInstructionsField) ...[
                        const SizedBox(height: 8),
                        TextField(
                          controller: _instructionController,
                          decoration: InputDecoration(
                            hintText: 'e.g. Leave with security / near farm tubewell',
                            hintStyle: const TextStyle(fontSize: 12),
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // 2. Payment Method Card (Exact match from Image 5)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Payment method',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                      ),
                      const SizedBox(height: 14),

                      // Box 1: Your available balance (Image 5)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Your available balance',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                            ),
                            const Divider(height: 16),
                            InkWell(
                              onTap: () {
                                setState(() => _selectedPayment = PaymentOption.kccWallet);
                              },
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildRadioCircle(_selectedPayment == PaymentOption.kccWallet),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 10),
                                      Text(
                                        'Kisan Credit Card (KCC) / Wallet (₹${_cart.kccWalletBalance.toStringAsFixed(2)})',
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          const Icon(Icons.info_outline, size: 14, color: Color(0xFF007185)),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Insufficient balance. ',
                                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                          ),
                                          const Text(
                                            'Add money & get rewarded',
                                            style: TextStyle(fontSize: 11, color: Color(0xFF007185), fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),

                            // Enter Code / Coupon Apply (Image 5)
                            Row(
                              children: [
                                const Text('+ ', style: TextStyle(fontSize: 16, color: Colors.grey)),
                                Expanded(
                                  child: SizedBox(
                                    height: 36,
                                    child: TextField(
                                      controller: _couponController,
                                      decoration: InputDecoration(
                                        hintText: _couponApplied ? 'KISAN50 (Applied ₹50 Off)' : 'Enter Code (e.g. KISAN50)',
                                        hintStyle: const TextStyle(fontSize: 12),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  height: 36,
                                  child: OutlinedButton(
                                    onPressed: _applyCoupon,
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: Colors.grey),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                    ),
                                    child: const Text('Apply', style: TextStyle(color: Color(0xFF111827), fontSize: 13)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Box 2: Another payment method (Image 5)
                      const Text(
                        'Another payment method',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                      ),
                      const SizedBox(height: 8),

                      // 1. Credit or Debit card
                      _buildPaymentRadioTile(
                        option: PaymentOption.cards,
                        title: 'Credit or debit card',
                        subtitleWidget: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Wrap(
                            spacing: 6,
                            children: [
                              _buildCardBrandChip('VISA', const Color(0xFF1A1F71)),
                              _buildCardBrandChip('MC', const Color(0xFFEB001B)),
                              _buildCardBrandChip('RuPay', const Color(0xFF097939)),
                              _buildCardBrandChip('Maestro', const Color(0xFF0061A8)),
                            ],
                          ),
                        ),
                      ),
                      const Divider(height: 1),

                      // 2. Net Banking
                      _buildPaymentRadioTile(
                        option: PaymentOption.netBanking,
                        title: 'Net Banking',
                        subtitleWidget: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: DropdownButton<String>(
                              value: _selectedBank,
                              isExpanded: true,
                              underline: const SizedBox(),
                              isDense: true,
                              items: _bankOptions.map((bank) {
                                return DropdownMenuItem(value: bank, child: Text(bank, style: const TextStyle(fontSize: 12)));
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedBank = val);
                              },
                            ),
                          ),
                        ),
                      ),
                      const Divider(height: 1),

                      // 3. Scan and Pay with UPI (Selected by default, matching Image 5)
                      _buildPaymentRadioTile(
                        option: PaymentOption.upiScan,
                        title: 'Scan and Pay with UPI',
                        trailingWidget: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDF7EE),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('UPI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF2E7D32))),
                        ),
                        subtitleWidget: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.info_outline, size: 14, color: Color(0xFF007185)),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'You will need to Scan the QR code on the payment page to complete the payment.',
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: _showUpiQrModal,
                              icon: const Icon(Icons.qr_code, size: 16, color: Color(0xFF007185)),
                              label: const Text('Show QR Code to Scan', style: TextStyle(fontSize: 12, color: Color(0xFF007185))),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF007185)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),

                      // 4. EMI Unavailable
                      _buildPaymentRadioTile(
                        option: PaymentOption.emi,
                        title: 'EMI Unavailable Why?',
                        enabled: false,
                      ),
                      const Divider(height: 1),

                      // 5. Cash on Delivery / Pay on Delivery
                      _buildPaymentRadioTile(
                        option: PaymentOption.cashOnDelivery,
                        title: 'Cash on Delivery/Pay on Delivery',
                        subtitleWidget: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            'Cash, UPI and Cards accepted. Know more.',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Yellow Use this payment method button (Image 5)
                      SizedBox(
                        width: double.infinity,
                        height: 40,
                        child: ElevatedButton(
                          onPressed: _selectedPayment == PaymentOption.upiScan ? _showUpiQrModal : _placeOrder,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFD814),
                            foregroundColor: const Color(0xFF0F1111),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          child: const Text(
                            'Use this payment method',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // 3. Arriving by 5 Oct 2026 & Review Order (Exact match from Image 5)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Arriving by 5 Oct 2026',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                          ),
                          InkWell(
                            onTap: () {},
                            child: const Text(
                              'Review Order',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF007185)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...items.map((cartItem) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.asset(
                                  cartItem.product.imageAsset,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 60,
                                    height: 60,
                                    color: const Color(0xFFEDF7EE),
                                    child: const Icon(Icons.eco, color: Color(0xFF2E7D32)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      cartItem.product.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F1111)),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text('Qty: ${cartItem.quantity}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                        const SizedBox(width: 8),
                                        Text('₹${cartItem.totalPrice.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // Remove / Qty stepper
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, size: 18, color: Colors.grey),
                                    onPressed: () => _cart.updateQuantity(cartItem.product.id, cartItem.quantity - 1),
                                  ),
                                  Text('${cartItem.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline, size: 18, color: Color(0xFF2E7D32)),
                                    onPressed: () => _cart.updateQuantity(cartItem.product.id, cartItem.quantity + 1),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // 4. Order Price Details (Exact match from Image 5)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      _buildPriceRow('Items:', '₹${_cart.subtotal.toStringAsFixed(2)}'),
                      _buildPriceRow('Delivery:', '₹${_cart.deliveryFee.toStringAsFixed(2)}'),
                      _buildPriceRow('Marketplace Fee:', '₹${_cart.marketplaceFee.toStringAsFixed(2)}'),
                      _buildPriceRow('Total:', '₹${(_cart.subtotal + _cart.deliveryFee + _cart.marketplaceFee).toStringAsFixed(2)}'),
                      _buildPriceRow(
                        'FREE Delivery / Kisan Subsidy:',
                        '-₹${_cart.kisanSubsidy.toStringAsFixed(2)}',
                        isDiscount: true,
                      ),
                      if (_couponApplied)
                        _buildPriceRow(
                          'Kisan Coupon Subsidy:',
                          '-₹${_couponDiscount.toStringAsFixed(2)}',
                          isDiscount: true,
                        ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Order Total:',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                          ),
                          Text(
                            '₹${_finalPayable.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF111827)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.diamond, color: Colors.blue, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'Diamonds earned: ${_cart.diamondsEarned}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4B5563)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Bottom Place Order Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _placeOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFA41C),
                      foregroundColor: const Color(0xFF0F1111),
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    child: Text(
                      'Place Order & Pay ₹${_finalPayable.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
    );
  }

  Widget _buildRadioCircle(bool isSelected, {bool enabled = true}) {
    return Container(
      width: 20,
      height: 20,
      margin: const EdgeInsets.only(top: 8, right: 12),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: !enabled
              ? Colors.grey.shade300
              : (isSelected ? const Color(0xFF2874F0) : Colors.grey.shade400),
          width: isSelected ? 2 : 1.5,
        ),
        color: Colors.white,
      ),
      child: isSelected
          ? Center(
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF2874F0),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildPaymentRadioTile({
    required PaymentOption option,
    required String title,
    Widget? subtitleWidget,
    Widget? trailingWidget,
    bool enabled = true,
  }) {
    final isSelected = _selectedPayment == option;
    return InkWell(
      onTap: enabled
          ? () {
              setState(() => _selectedPayment = option);
            }
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRadioCircle(isSelected, enabled: enabled),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: enabled ? const Color(0xFF1F2937) : Colors.grey,
                      ),
                    ),
                    if (trailingWidget != null) ...[
                      const SizedBox(width: 8),
                      trailingWidget,
                    ],
                  ],
                ),
                if (subtitleWidget != null) subtitleWidget,
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildCardBrandChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: isDiscount ? const Color(0xFF16A34A) : Colors.grey.shade700)),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isDiscount ? FontWeight.bold : FontWeight.w500,
              color: isDiscount ? const Color(0xFF16A34A) : const Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }
}
