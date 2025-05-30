import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';


class WalletCoinsPage extends StatefulWidget {
  const WalletCoinsPage({Key? key}) : super(key: key);

  @override
  State<WalletCoinsPage> createState() => _WalletCoinsPageState();
}

class _WalletCoinsPageState extends State<WalletCoinsPage> {
  late Razorpay _razorpay;
  int currentBalance = 0; // Will be fetched from backend
  String baseUrl = "https://campcrave-backend.onrender.com"; // Replace with your server URL
  bool isLoading = false;
  bool isBalanceLoading = true; // For initial balance loading
  int? selectedPackageCoins; // Store selected package coins for payment success

  // Coin packages
  final List<CoinPackage> coinPackages = [
    CoinPackage(coins: 100, price: 100, popular: false),
    CoinPackage(coins: 250, price: 225, popular: true),
    CoinPackage(coins: 500, price: 450, popular: false),
    CoinPackage(coins: 1000, price: 850, popular: false),
    CoinPackage(coins: 2000, price: 1600, popular: false),
    CoinPackage(coins: 5000, price: 3750, popular: false),
  ];

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    // Fetch current balance on init
    _fetchCurrentBalance();
  }

  @override
  void dispose() {
    super.dispose();
    _razorpay.clear();
  }

  // Fetch current balance from backend
  Future<void> _fetchCurrentBalance() async {
    try {
      final _storage = const FlutterSecureStorage();
      String? userId = await _storage.read(key: 'userId');

      if (userId == null) {
        Fluttertoast.showToast(
          msg: "User not logged in",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
        return;
      }

      final response = await http.get(
        Uri.parse('$baseUrl/wallet?userId=$userId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          setState(() {
            currentBalance = data['data']['balance'] ?? 0;
            isBalanceLoading = false;
          });
        } else {
          setState(() {
            currentBalance = 0;
            isBalanceLoading = false;
          });
        }
      } else {
        print('Failed to fetch balance: ${response.body}');
        setState(() {
          currentBalance = 0;
          isBalanceLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching balance: $e');
      setState(() {
        currentBalance = 0;
        isBalanceLoading = false;
      });

      Fluttertoast.showToast(
        msg: "Failed to load balance",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    // Show loading state
    setState(() {
      isLoading = true;
    });

    try {
      // Get coins from selected package
      int coinsToAdd = selectedPackageCoins ?? 100;

      // Update wallet on server
      bool success = await _updateWalletOnServer(coinsToAdd);

      if (success) {
        setState(() {
          isLoading = false;
        });

        // Refresh balance from server to ensure accuracy
        await _fetchCurrentBalance();

        Fluttertoast.showToast(
          msg: "Payment Successful! $coinsToAdd coins added to your wallet",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
      } else {
        setState(() {
          isLoading = false;
        });

        Fluttertoast.showToast(
          msg: "Payment successful but failed to update wallet. Please contact support.",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.orange,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      Fluttertoast.showToast(
        msg: "Error updating wallet: $e",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      // Clear selected package
      selectedPackageCoins = null;
    }
  }

  Future<bool> _updateWalletOnServer(int amount) async {
    try {
      final _storage = const FlutterSecureStorage();
      String? userId = await _storage.read(key: 'userId');
      final response = await http.post(
        Uri.parse('$baseUrl/wallet/add'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'userId': userId,
          'amount': amount,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          // Update local balance with server response if provided
          if (data['data'] != null && data['data']['newBalance'] != null) {
            setState(() {
              currentBalance = data['data']['newBalance'];
            });
          }
          return true;
        }
      }

      print('Server error: ${response.body}');
      return false;
    } catch (e) {
      print('Network error: $e');
      return false;
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    // Clear selected package on error
    selectedPackageCoins = null;

    Fluttertoast.showToast(
      msg: "Payment Failed: ${response.message}",
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.red,
      textColor: Colors.white,
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    Fluttertoast.showToast(
      msg: "External Wallet: ${response.walletName}",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  void _startPayment(CoinPackage package) {
    if (isLoading) return; // Prevent multiple payments

    // Store selected package coins for use in payment success
    selectedPackageCoins = package.coins;

    var options = {
      'key': 'rzp_test_1DP5mmOlF5G5ag', // Replace with your test key
      'amount': package.price * 100, // Amount in paise
      'name': 'Canteen App',
      'description': '${package.coins} Wallet Coins',
      'retry': {'enabled': true, 'max_count': 1},
      'send_sms_hash': true,
      'prefill': {
        'contact': '9876543210',
        'email': 'user@example.com'
      },
      'external': {
        'wallets': ['paytm']
      },
      'notes': {
        'coins': package.coins.toString(), // Store coin amount for reference
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error: $e');
      selectedPackageCoins = null; // Clear on error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Wallet Coins',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.orange[600],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: isBalanceLoading ? null : () {
              setState(() {
                isBalanceLoading = true;
              });
              _fetchCurrentBalance();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Current Balance Card
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange[600]!, Colors.orange[800]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.account_balance_wallet,
                    color: Colors.white,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Current Balance',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (isBalanceLoading)
                    const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.monetization_on,
                          color: Colors.white,
                          size: 32,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$currentBalance',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            // Coin Packages
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Choose Coin Package',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Add coins to your wallet and enjoy seamless canteen experience',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 20),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.85,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: coinPackages.length,
                    itemBuilder: (context, index) {
                      return CoinPackageCard(
                        package: coinPackages[index],
                        isLoading: isLoading,
                        onTap: () => _startPayment(coinPackages[index]),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Payment Info
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue[600],
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Secure Payment',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Powered by Razorpay. Your payment information is secure and encrypted.',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class CoinPackage {
  final int coins;
  final int price;
  final bool popular;

  CoinPackage({
    required this.coins,
    required this.price,
    required this.popular,
  });

  int get savings => (coins - price);
  double get savingsPercentage => ((savings / coins) * 100);
}

class CoinPackageCard extends StatelessWidget {
  final CoinPackage package;
  final VoidCallback onTap;
  final bool isLoading;

  const CoinPackageCard({
    Key? key,
    required this.package,
    required this.onTap,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: isLoading ? null : onTap, // Disable tap when loading
        child: Opacity(
          opacity: isLoading ? 0.6 : 1.0, // Dim when loading
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: package.popular
                  ? Border.all(color: Colors.green, width: 2)
                  : Border.all(color: Colors.grey[300]!, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Popular Badge
                if (package.popular)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(16),
                          bottomLeft: Radius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'POPULAR',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Coin Icon
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.orange[100],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.monetization_on,
                          color: Colors.orange[600],
                          size: 28,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Coins
                      Text(
                        '${package.coins}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),

                      const Text(
                        'Coins',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),

                      const SizedBox(height: 6),

                      // Price
                      Text(
                        '₹${package.price}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[600],
                        ),
                      ),

                      // Savings
                      if (package.savings > 0)
                        Text(
                          'Save ₹${package.savings}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.green[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ));
  }
}