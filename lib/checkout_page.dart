import 'package:flutter/material.dart';
import 'models/menu_item.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class CheckoutPage extends StatefulWidget {
  final Map<String, int> selectedQuantities;
  final List<MenuItem> availableItems;
  final String canteenName;

  const CheckoutPage({
    Key? key,
    required this.selectedQuantities,
    required this.availableItems,
    required this.canteenName,
  }) : super(key: key);

  @override
  _CheckoutPageState createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
  late Razorpay _razorpay;

  late Map<String, int> quantities;
  List<MenuItem> selectedItems = [];
  double subtotal = 0;
  final double deliveryFee = 20.0;
  final double platformFee = 5.0;
  String selectedPaymentMethod = 'Online Payment'; // 'Online Payment' or 'Wallet'
  String deliveryLocation = 'Seating near tree';
  bool isProcessing = false;
  double walletBalance = 0.0;
  bool isLoadingWallet = false;

  @override
  void initState() {
    super.initState();
    // Create a copy of the quantities map to modify locally
    quantities = Map.from(widget.selectedQuantities);

    // Filter only selected items
    selectedItems = widget.availableItems
        .where((item) => quantities[item.name]! > 0)
        .toList();

    // Calculate initial subtotal
    calculateSubtotal();

    // Initialize Razorpay
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    // Load wallet balance
    _loadWalletBalance();
  }

  @override
  void dispose() {
    super.dispose();
    _razorpay.clear();
  }

  void calculateSubtotal() {
    subtotal = selectedItems.fold(
        0, (sum, item) => sum + (item.price * quantities[item.name]!));
  }

  void updateQuantity(String itemName, int newQuantity) {
    if (newQuantity <= 0) {
      // Remove item if quantity is 0
      setState(() {
        quantities[itemName] = 0;
        selectedItems.removeWhere((item) => item.name == itemName);
        calculateSubtotal();
      });
    } else {
      setState(() {
        quantities[itemName] = newQuantity;
        calculateSubtotal();
      });
    }
  }

  Future<void> _loadWalletBalance() async {
    setState(() {
      isLoadingWallet = true;
    });

    try {
      String? userId = await secureStorage.read(key: 'userId');
      if (userId == null) {
        throw Exception('User ID not found');
      }

      final response = await http.get(
        Uri.parse('https://campcrave-backend.onrender.com/wallet?userId=$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        setState(() {
          walletBalance = (userData['data']['balance']).toDouble();
        });
      }
      print(walletBalance);
    } catch (e) {
      print('Error loading wallet balance: $e');
    } finally {
      setState(() {
        isLoadingWallet = false;
      });
    }
  }

  Future<void> _deductFromWallet(double amount) async {
    try {
      String? userId = await secureStorage.read(key: 'userId');
      if (userId == null) {
        throw Exception('User ID not found');
      }

      final response = await http.post(
        Uri.parse('https://campcrave-backend.onrender.com/wallet/deduct'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'amount': amount,
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['success']) {
        // Wallet deduction successful, place order
        await _placeOrderAfterPayment(null, isWalletPayment: true);

        // Update local wallet balance
        setState(() {
          walletBalance = responseData['data']['newBalance'].toDouble();
        });
      } else {
        // Handle wallet deduction error
        throw Exception(responseData['message'] ?? 'Wallet deduction failed');
      }
    } catch (e) {
      setState(() {
        isProcessing = false;
      });

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.error, color: Colors.red, size: 28),
              SizedBox(width: 12),
              Text('Wallet Payment Failed'),
            ],
          ),
          content: Text('$e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    // Payment successful, now place the order
    print("Payment Success: ${response.paymentId}");
    _placeOrderAfterPayment(response.paymentId);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() {
      isProcessing = false;
    });
    print("Payment Error: ${response.code} - ${response.message}");

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.error, color: Colors.red, size: 28),
              SizedBox(width: 12),
              Text('Payment Failed'),
            ],
          ),
          content: Text('Payment was unsuccessful. Please try again.\n\nError: ${response.message ?? 'Unknown error'}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    print("External Wallet: ${response.walletName}");
  }

  void _startPayment() async {
    try {
      String? customerPhone = await secureStorage.read(key: 'phonenumber');
      String? userId = await secureStorage.read(key: 'userId');

      if (userId == null || customerPhone == null) {
        throw Exception('User information not found. Please log in again.');
      }

      final double total = subtotal + deliveryFee + platformFee;

      var options = {
        'key': 'rzp_test_1DP5mmOlF5G5ag', // Replace with your actual Razorpay key
        'amount': (total * 100).toInt(), // Amount in paise
        'name': widget.canteenName,
        'description': 'Food Order Payment',
        'retry': {'enabled': true, 'max_count': 1},
        'send_sms_hash': true,
        'prefill': {
          'contact': customerPhone,
          'email': 'customer@example.com' // You might want to store email too
        },
        'external': {
          'wallets': ['paytm']
        }
      };

      _razorpay.open(options);
    } catch (e) {
      setState(() {
        isProcessing = false;
      });
      print('Payment initiation error: $e');
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.error, color: Colors.red, size: 28),
              SizedBox(width: 12),
              Text('Payment Error'),
            ],
          ),
          content: Text('Failed to initiate payment. Please try again.\n\nError: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _placeOrderAfterPayment(String? paymentId, {bool isWalletPayment = false}) async {
    try {
      // Fetch userId from secure storage
      String? userId = await secureStorage.read(key: 'userId');
      String? customerPhone = await secureStorage.read(key: 'phonenumber');

      if (userId == null) {
        throw Exception('User ID not found. Please log in again.');
      }

      final orderData = {
        'customerName': customerPhone,
        'userId': userId,
        'items': selectedItems
            .expand((item) => List.filled(quantities[item.name]!, item.name))
            .toList(),
        'total': subtotal + deliveryFee + platformFee,
        'deliveryLocation': deliveryLocation,
        'status': 'Preparing',
        'paymentId': paymentId,
        'paymentStatus': 'completed',
        'paymentMethod': isWalletPayment ? 'wallet' : 'razorpay',
      };

      final response = await http.post(
        Uri.parse('https://campcrave-backend.onrender.com/orders'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(orderData),
      );

      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 201) {
        if (mounted) {
          setState(() {
            isProcessing = false;
          });

          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 28),
                  SizedBox(width: 12),
                  Text('Order Placed!'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your order has been successfully placed and will be prepared shortly.'),
                  SizedBox(height: 12),
                  Text(
                    isWalletPayment
                        ? 'Payment Method: Wallet'
                        : 'Payment ID: $paymentId',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontFamily: 'monospace',
                    ),
                  ),
                  if (isWalletPayment) ...[
                    SizedBox(height: 4),
                    Text(
                      'Remaining Balance: ₹${walletBalance.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: Text('Back to Home', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
        }
      } else {
        setState(() {
          isProcessing = false;
        });
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.error, color: Colors.red, size: 28),
                SizedBox(width: 12),
                Text('Order Failed'),
              ],
            ),
            content: Text('Payment successful but order creation failed. Please contact support.\n\nError: ${response.body}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() {
        isProcessing = false;
      });
      print('Order creation exception: $e');
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.error, color: Colors.red, size: 28),
              SizedBox(width: 12),
              Text('Order Failed'),
            ],
          ),
          content: Text('Payment successful but order creation failed. Please contact support.\n\nError: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void placeOrder() async {
    setState(() {
      isProcessing = true;
    });

    final double total = subtotal + deliveryFee + platformFee;

    if (selectedPaymentMethod == 'Wallet') {
      // Check if wallet has sufficient balance
      if (walletBalance < total) {
        setState(() {
          isProcessing = false;
        });
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.account_balance_wallet, color: Colors.orange, size: 28),
                SizedBox(width: 12),
                Text('Insufficient Balance'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your wallet balance is insufficient for this order.'),
                SizedBox(height: 12),
                Text('Order Total: ₹${total.toStringAsFixed(0)}'),
                Text('Wallet Balance: ₹${walletBalance.toStringAsFixed(0)}'),
                Text('Required: ₹${(total - walletBalance).toStringAsFixed(0)}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Add Money'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    selectedPaymentMethod = 'Online Payment';
                  });
                },
                child: Text('Use Online Payment'),
              ),
            ],
          ),
        );
        return;
      }

      // Proceed with wallet payment
      await _deductFromWallet(total);
    } else {
      // Start Razorpay payment
      _startPayment();
    }
  }

  @override
  Widget build(BuildContext context) {
    final double total = subtotal + deliveryFee + platformFee;

    return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Container(
        margin: EdgeInsets.all(8),
    decoration: BoxDecoration(
    color: Colors.grey[100],
    borderRadius: BorderRadius.circular(12),
    ),
    child: IconButton(
    icon: Icon(Icons.arrow_back_ios_new, color: Colors.black87),
    onPressed: () => Navigator.pop(context),
    ),
    ),
    title: Text(
    'Checkout',
    style: TextStyle(
    color: Colors.black87,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    ),
    ),
    centerTitle: true,
    ),
    body: selectedItems.isEmpty
    ? Center(
    child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
    Container(
    padding: EdgeInsets.all(24),
    decoration: BoxDecoration(
    color: Colors.orange[50],
    borderRadius: BorderRadius.circular(50),
    ),
    child: Icon(Icons.shopping_cart_outlined, size: 60, color: Colors.orange),
    ),
    SizedBox(height: 24),
    Text(
    'Your cart is empty',
    style: TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: Colors.black87,
    ),
    ),
    SizedBox(height: 8),
    Text(
    'Add some delicious items to get started',
    style: TextStyle(
    fontSize: 14,
    color: Colors.grey[600],
    ),
    ),
    SizedBox(height: 24),
    ElevatedButton(
    onPressed: () => Navigator.pop(context),
    style: ElevatedButton.styleFrom(
    backgroundColor: Colors.orange,
    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
    shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(25),
    ),
    ),
    child: Text(
    'Continue Shopping',
    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
    ),
    ),
    ],
    ),
    )
        : SingleChildScrollView(
    child: Column(
    children: [
    // Restaurant info card
    Container(
    margin: EdgeInsets.all(16),
    padding: EdgeInsets.all(20),
    decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
    BoxShadow(
    color: Colors.black.withOpacity(0.05),
    blurRadius: 10,
    offset: Offset(0, 2),
    ),
    ],
    ),
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Row(
    children: [
    Container(
    padding: EdgeInsets.all(12),
    decoration: BoxDecoration(
    color: Colors.orange[50],
    borderRadius: BorderRadius.circular(12),
    ),
    child: Icon(Icons.restaurant, color: Colors.orange, size: 24),
    ),
    SizedBox(width: 16),
    Expanded(
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Text(
    widget.canteenName,
    style: TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: Colors.black87,
    ),
    ),
    SizedBox(height: 4),
    Row(
    children: [
    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
    SizedBox(width: 4),
    Text(
    'Campus Canteen',
    style: TextStyle(
    color: Colors.grey[600],
    fontSize: 14,
    ),
    ),
    ],
    ),
    ],
    ),
    ),
    Container(
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
    color: Colors.green[50],
    borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
    Icon(Icons.star, size: 14, color: Colors.green),
    SizedBox(width: 4),
    Text(
    '4.1',
    style: TextStyle(
    color: Colors.green,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    ),
    ),
    ],
    ),
    ),
    ],
    ),
    ],
    ),
    ),

    // Selected items card
    Container(
    margin: EdgeInsets.symmetric(horizontal: 16),
    padding: EdgeInsets.all(20),
    decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
    BoxShadow(
    color: Colors.black.withOpacity(0.05),
    blurRadius: 10,
    offset: Offset(0, 2),
    ),
    ],
    ),
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Row(
    children: [
    Icon(Icons.shopping_bag_outlined, color: Colors.orange, size: 20),
    SizedBox(width: 8),
    Text(
    'Your Order (${selectedItems.length} items)',
    style: TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.black87,
    ),
    ),
    ],
    ),
    SizedBox(height: 16),
    ListView.separated(
    shrinkWrap: true,
    physics: NeverScrollableScrollPhysics(),
    itemCount: selectedItems.length,
    separatorBuilder: (context, index) => Divider(height: 24),
    itemBuilder: (context, index) {
    final item = selectedItems[index];
    final quantity = quantities[item.name]!;

    return Row(
    children: [
    Container(
    width: 60,
    height: 60,
    decoration: BoxDecoration(
    color: Colors.orange[50],
    borderRadius: BorderRadius.circular(12),
    ),
    child: Icon(Icons.fastfood, color: Colors.orange, size: 24),
    ),
    SizedBox(width: 12),
    Expanded(
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Text(
    item.name,
    style: TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.black87,
    ),
    ),
    SizedBox(height: 4),
    Text(
    '₹${item.price}',
    style: TextStyle(
    fontSize: 14,
    color: Colors.grey[600],
    ),
    ),
    ],
    ),
    ),
    Container(
    decoration: BoxDecoration(
    color: Colors.grey[100],
    borderRadius: BorderRadius.circular(25),
    ),
    child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
    IconButton(
    icon: Icon(Icons.remove, size: 18),
    onPressed: () => updateQuantity(item.name, quantity - 1),
    constraints: BoxConstraints(minWidth: 32, minHeight: 32),
    ),
    Container(
    padding: EdgeInsets.symmetric(horizontal: 12),
    child: Text(
    '$quantity',
    style: TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    ),
    ),
    ),
    IconButton(
    icon: Icon(Icons.add, size: 18),
    onPressed: () => updateQuantity(item.name, quantity + 1),
    constraints: BoxConstraints(minWidth: 32, minHeight: 32),
    ),
    ],
    ),
    ),
    SizedBox(width: 12),
    Text(
    '₹${(item.price * quantity).toStringAsFixed(0)}',
    style: TextStyle(
    fontWeight: FontWeight.w700,
    fontSize: 16,
    color: Colors.black87,
    ),
    ),
    ],
    );
    },
    ),
    ],
    ),
    ),

    SizedBox(height: 16),

    // Delivery location card
    Container(
    margin: EdgeInsets.symmetric(horizontal: 16),
    padding: EdgeInsets.all(20),
    decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
    BoxShadow(
    color: Colors.black.withOpacity(0.05),
    blurRadius: 10,
    offset: Offset(0, 2),
    ),
    ],
    ),
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Row(
    children: [
    Icon(Icons.location_on, color: Colors.orange, size: 20),
    SizedBox(width: 8),
    Text(
    'Delivery Location',
    style: TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.black87,
    ),
    ),
    ],
    ),
    SizedBox(height: 12),
    InkWell(
    onTap: () {
    showModalBottomSheet(
    context: context,
    shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => Container(
    padding: EdgeInsets.all(24),
    child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
    Container(
    width: 40,
    height: 4,
    decoration: BoxDecoration(
    color: Colors.grey[300],
    borderRadius: BorderRadius.circular(2),
    ),
    ),
    SizedBox(height: 20),
    Text(
    'Select Delivery Location',
    style: TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    ),
    ),
    SizedBox(height: 20),
    _buildLocationOption('Seating near tree', Icons.park),
    _buildLocationOption('Library entrance', Icons.local_library),
    _buildLocationOption('Hostel area', Icons.home),
    ],
    ),
    ),
    );
    },
    child: Container(
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(
    color: Colors.grey[50],
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: Colors.grey[200]!),
    ),
    child: Row(
    children: [
    Icon(Icons.location_on, color: Colors.green, size: 20),
    SizedBox(width: 12),
    Expanded(
    child: Text(
    deliveryLocation,
    style: TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    ),
    ),
    ),
    Icon(Icons.keyboard_arrow_down, color: Colors.grey),
    ],
    ),
    ),
    ),
    ],
    ),
    ),

    SizedBox(height: 16),

    // Payment method card
    Container(
    margin: EdgeInsets.symmetric(horizontal: 16),
    padding: EdgeInsets.all(20),
    decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
    BoxShadow(
    color: Colors.black.withOpacity(0.05),
    blurRadius: 10,
    offset: Offset(0, 2),
    ),
    ],
    ),
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Row(
    children: [
    Icon(Icons.payment, color: Colors.orange, size: 20),
    SizedBox(width: 8),
    Text(
    'Payment Method',
    style: TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.black87,
    ),
    ),
    ],
    ),
    SizedBox(height: 16),

    // Wallet Payment Option
    InkWell(
    onTap: () {
    setState(() {
    selectedPaymentMethod = 'Wallet';
    });
    },
    child: Container(
    padding: EdgeInsets.all(16),
    margin: EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
    color: selectedPaymentMethod == 'Wallet' ? Colors.green[50] : Colors.grey[50],
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
    color: selectedPaymentMethod == 'Wallet' ? Colors.green[200]! : Colors.grey[200]!,
    ),
    ),
    child: Row(
    children: [
    Icon(
    Icons.account_balance_wallet,
    color: selectedPaymentMethod == 'Wallet' ? Colors.green : Colors.grey[600],
    ),
    SizedBox(width: 12),
    Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Wallet Payment',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: selectedPaymentMethod == 'Wallet' ? Colors.green[800] : Colors.black87,
            ),
          ),
          SizedBox(height: 4),
          isLoadingWallet
              ? Text(
            'Loading balance...',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          )
              : Text(
            'Balance: ₹${walletBalance}',
            style: TextStyle(
              fontSize: 12,
              color: selectedPaymentMethod == 'Wallet' ? Colors.green[600] : Colors.grey[600],
            ),
          ),
        ],
      ),
    ),
      if (selectedPaymentMethod == 'Wallet')
        Icon(Icons.check_circle, color: Colors.green, size: 20),
    ],
    ),
    ),
    ),

      // Online Payment Option
      InkWell(
        onTap: () {
          setState(() {
            selectedPaymentMethod = 'Online Payment';
          });
        },
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selectedPaymentMethod == 'Online Payment' ? Colors.blue[50] : Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selectedPaymentMethod == 'Online Payment' ? Colors.blue[200]! : Colors.grey[200]!,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.credit_card,
                color: selectedPaymentMethod == 'Online Payment' ? Colors.blue : Colors.grey[600],
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Online Payment',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: selectedPaymentMethod == 'Online Payment' ? Colors.blue[800] : Colors.black87,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Pay via UPI, Card, or Net Banking',
                      style: TextStyle(
                        fontSize: 12,
                        color: selectedPaymentMethod == 'Online Payment' ? Colors.blue[600] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (selectedPaymentMethod == 'Online Payment')
                Icon(Icons.check_circle, color: Colors.blue, size: 20),
            ],
          ),
        ),
      ),
    ],
    ),
    ),

      SizedBox(height: 16),

      // Bill details card
      Container(
        margin: EdgeInsets.symmetric(horizontal: 16),
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt_long, color: Colors.orange, size: 20),
                SizedBox(width: 8),
                Text(
                  'Bill Details',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            _buildBillRow('Subtotal', '₹${subtotal.toStringAsFixed(0)}'),
            _buildBillRow('Delivery Fee', '₹${deliveryFee.toStringAsFixed(0)}'),
            _buildBillRow('Platform Fee', '₹${platformFee.toStringAsFixed(0)}'),
            Divider(height: 24),
            _buildBillRow(
              'Total Amount',
              '₹${total.toStringAsFixed(0)}',
              isTotal: true,
            ),
          ],
        ),
      ),

      SizedBox(height: 100), // Space for bottom button
    ],
    ),
    ),
      bottomNavigationBar: selectedItems.isEmpty
          ? null
          : Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '₹${total.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    'Total amount',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 16),
            ElevatedButton(
              onPressed: isProcessing ? null : placeOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                elevation: 0,
              ),
              child: isProcessing
                  ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
                  : Text(
                'Place Order',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationOption(String location, IconData icon) {
    return InkWell(
      onTap: () {
        setState(() {
          deliveryLocation = location;
        });
        Navigator.pop(context);
      },
      child: Container(
        padding: EdgeInsets.all(16),
        margin: EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: deliveryLocation == location ? Colors.orange[50] : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: deliveryLocation == location ? Colors.orange[200]! : Colors.grey[200]!,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: deliveryLocation == location ? Colors.orange : Colors.grey[600],
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                location,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: deliveryLocation == location ? Colors.orange[800] : Colors.black87,
                ),
              ),
            ),
            if (deliveryLocation == location)
              Icon(Icons.check_circle, color: Colors.orange, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildBillRow(String label, String amount, {bool isTotal = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
              color: isTotal ? Colors.black87 : Colors.grey[700],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
              color: isTotal ? Colors.black87 : Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }
}