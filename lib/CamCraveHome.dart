import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:canteen_app/checkout_page.dart';
import 'models/menu_item.dart';
import 'previous_orders.dart';
import 'wallet.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class RecommendationItem {
  final String itemId;
  final double score;

  RecommendationItem({required this.itemId, required this.score});

  factory RecommendationItem.fromJson(Map<String, dynamic> json) {
    return RecommendationItem(
      itemId: json['itemId'],
      score: json['score'].toDouble(),
    );
  }
}

class CamCraveHome extends StatefulWidget {
  @override
  _CamCraveHomeState createState() => _CamCraveHomeState();
}

class _CamCraveHomeState extends State<CamCraveHome> {
  List<RecommendationItem> recommendations = [];
  bool isLoadingRecommendations = true;
  String? userId;
  // final _storage1 =const FlutterSecureStorage();
  Future<void> getUserId() async {
    // Get userId from  your storage or user session
    // This is just an example - replace with your actual user ID retrieval logic
    userId=await _storage.read(key:'userId');
  }
  Future<void> fetchRecommendations() async {
    if (userId == null) return;
    if (!mounted) return;
    setState(() {
      isLoadingRecommendations = true;
    });

    try {
      final response = await http.get(
        Uri.parse('https://campuscrave-python.onrender.com/recommend/$userId'),
        headers: {'Content-Type': 'application/json'},
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        setState(() {
          recommendations = (data['recommendations'] as List)
              .map((item) => RecommendationItem.fromJson(item))
              .toList();
          isLoadingRecommendations = false;
        });
      } else {
        setState(() {
          recommendations = [];
          isLoadingRecommendations = false;
        });
      }
    } catch (error) {
      print('Error fetching recommendations: $error');
      if (!mounted) return;
      setState(() {
        recommendations = [];
        isLoadingRecommendations = false;
      });
    }
  }

  final List<Map<String, String>> allCanteens = [
    {"name": "XYZ Canteen", "image": "assets/food_image.jpg"}
  ];
  final _storage = const FlutterSecureStorage();
  Future<void> logout() async {
    await _storage.delete(key: 'token');
  }
  List<Map<String, String>> filteredCanteens = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    filteredCanteens = List.from(allCanteens);
    searchController.addListener(() {
      searchCanteens(searchController.text);
    });
    _initializeData();
  }
  Future<void> _initializeData() async {
    await getUserId();
    await fetchRecommendations();
  }

  void searchCanteens(String query) {
    if (query.isEmpty) {
      setState(() {
        filteredCanteens = List.from(allCanteens);
      });
    } else {
      setState(() {
        filteredCanteens = allCanteens
            .where((canteen) =>
            canteen["name"]!.toLowerCase().contains(query.toLowerCase()))
            .toList();
      });
      // getUserId().then((_) => fetchRecommendations());
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: 0,
          selectedItemColor: const Color(0xFF2E7D32),
          unselectedItemColor: Colors.grey[600],
          showSelectedLabels: false,
          showUnselectedLabels: false,
          backgroundColor: Colors.white,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded, size: 28),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart_rounded, size: 28),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded, size: 28),
              label: '',
            ),
          ],
          onTap: (index) {
            if (index == 2) {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                builder: (context) => Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
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
                      const SizedBox(height: 20),
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.history, color: Colors.blue),
                        ),
                        title: const Text('Previous Orders',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PreviousOrdersPage(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.logout, color: Colors.red),
                        ),
                        title: const Text('Logout',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {

                          logout();
                          Navigator.pop(context);
                          Navigator.pushNamedAndRemoveUntil(
                              context, '/login', (route) => false);

                        },
                      ),
                    ],
                  ),
                ),
              );
            } else if (index == 1) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CheckoutPage(
                    selectedQuantities: {},
                    availableItems: [],
                    canteenName: "XYZ Canteen",
                  ),
                ),
              );
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    // Location and Wallet Row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.location_on, color: Color(0xFF2E7D32), size: 18),
                              SizedBox(width: 4),
                              Text("Seating near tree",
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                              SizedBox(width: 4),
                              Icon(Icons.keyboard_arrow_down, size: 18),
                            ],
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => WalletCoinsPage(),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.account_balance_wallet, size: 24),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Search bar
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: const Color(0xFFF8F9FA),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search, color: Colors.grey),
                          hintText: "Search CamCrave",
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          suffixIcon: searchController.text.isNotEmpty
                              ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              searchController.clear();
                            },
                          )
                              : null,
                        ),
                        onChanged: searchCanteens,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Featured Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Featured on CamCrave",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.arrow_forward_ios, size: 16),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Canteen Cards
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: filteredCanteens.isEmpty
                    ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 60.0),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No canteens found",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Try searching with different keywords",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                    : Column(
                  children: filteredCanteens.map(
                        (canteen) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _modernCanteenCard(
                        context,
                        canteen["image"]!,
                        canteen["name"]!,
                      ),
                    ),
                  ).toList(),
                ),
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Your Recommendations",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.arrow_forward_ios, size: 16),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Recommendations List
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: isLoadingRecommendations
                    ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
                  ),
                )
                    : recommendations.isEmpty
                    ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40.0),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Icon(Icons.restaurant_menu, size: 48, color: Colors.grey[400]),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No recommendations yet",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Order more items to get personalized recommendations",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
                    : Container(
                  height: 200,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: recommendations.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final recommendation = recommendations[index];
                      return _recommendationCard(recommendation);
                    },
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
  Widget _recommendationCard(RecommendationItem recommendation) {
    return Container(
      width: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recommendation badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.thumb_up,
                    size: 12,
                    color: Color(0xFF2E7D32),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "${(recommendation.score * 10).toInt()}% match",
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Food icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.fastfood,
                color: Color(0xFFFF8F00),
                size: 24,
              ),
            ),
            const SizedBox(height: 12),

            // Item name
            Expanded(
              child: Text(
                recommendation.itemId,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF1A1A1A),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),

            // Action button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to menu page or add to cart
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MenuPage(canteenName: "XYZ Canteen"),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  elevation: 0,
                ),
                child: const Text(
                  'Try Now',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
  Widget _modernCanteenCard(BuildContext context, String imagePath, String name) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => MenuPage(canteenName: name)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Stack(
                children: [
                  Image.asset(
                    imagePath,
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: double.infinity,
                        height: 180,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.grey[200]!, Colors.grey[100]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Icon(Icons.restaurant, size: 48, color: Colors.grey[400]),
                      );
                    },
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.star, color: Colors.amber, size: 14),
                          SizedBox(width: 2),
                          Text(
                            "4.1",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.restaurant_menu,
                      color: Color(0xFFFF8F00),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Campus Canteen",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }



// Modern Menu Page
class MenuPage extends StatefulWidget {
  final String canteenName;

  const MenuPage({Key? key, required this.canteenName}) : super(key: key);

  @override
  _MenuPageState createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  List<MenuItem> availableItems = [];
  List<MenuItem> filteredItems = [];
  Map<String, int> selectedQuantities = {};
  bool isLoading = true;
  String errorMessage = '';
  late IO.Socket socket;
  TextEditingController searchController = TextEditingController();

  Future<void> fetchMenu(String canteenName) async {
    final String url = 'https://campcrave-backend.onrender.com/menu';
    if (!mounted) return;
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await http.get(Uri.parse(url), headers: {'Content-Type': 'application/json'});
      if (!mounted) return;
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        setState(() {
          availableItems = data
              .map((item) => MenuItem.fromJson(item))
              .where((item) => item.availability)
              .toList();

          filteredItems = List.from(availableItems);

          for (var item in availableItems) {
            if (!selectedQuantities.containsKey(item.name)) {
              selectedQuantities[item.name] = 0;
            }
          }

          isLoading = false;
        });
      } else {
        throw Exception('Server responded with status code: ${response.statusCode}');
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load menu: $error';
      });
    }
  }

  void searchMenu(String query) {
    if (!mounted) return;
    if (query.isEmpty) {
      setState(() {
        filteredItems = List.from(availableItems);
      });
    } else {
      setState(() {
        filteredItems = availableItems
            .where((item) =>
        item.name.toLowerCase().contains(query.toLowerCase()) ||
            item.category.toLowerCase().contains(query.toLowerCase()))
            .toList();
      });
    }
  }

  void incrementQuantity(String itemName) {
    setState(() {
      selectedQuantities[itemName] = (selectedQuantities[itemName] ?? 0) + 1;
    });

    if (selectedQuantities[itemName] == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added $itemName to cart'),
          duration: const Duration(seconds: 2),
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void decrementQuantity(String itemName) {
    if (selectedQuantities[itemName]! > 0) {
      setState(() {
        selectedQuantities[itemName] = selectedQuantities[itemName]! - 1;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchMenu(widget.canteenName);
    initializeSocket();
    searchController.addListener(() {
      searchMenu(searchController.text);
    });
  }

  void initializeSocket() {
    socket = IO.io('https://campcrave-backend.onrender.com', <String, dynamic>{
      'transports': ['websocket'],
    });

    socket.on('menu-updated', (data) {
      print('Menu updated: $data');
      if (!mounted) return; // Add this check
      setState(() {
        availableItems = (data as List).map((item) => MenuItem.fromJson(item)).toList();
        searchMenu(searchController.text);

        for (var item in availableItems) {
          if (!selectedQuantities.containsKey(item.name)) {
            selectedQuantities[item.name] = 0;
          }
        }
      });
    });

    socket.connect();
  }

  @override
  void dispose() {
    super.dispose();
    searchController.dispose();
    socket.disconnect();
    socket.dispose(); // Add this line

  }

  @override
  Widget build(BuildContext context) {
    int totalItems = selectedQuantities.values.fold(0, (sum, qty) => sum + qty);
    double totalPrice = availableItems
        .where((item) => selectedQuantities[item.name]! > 0)
        .fold(0, (sum, item) => sum + (item.price * (selectedQuantities[item.name] ?? 0)));

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${widget.canteenName} Menu',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: () => fetchMenu(widget.canteenName),
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_rounded, color: Colors.black),
                onPressed: () {
                  // Navigate to cart
                },
              ),
              if (totalItems > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$totalItems',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Section
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: const Color(0xFFF8F9FA),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  hintText: "Search menu items",
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  suffixIcon: searchController.text.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: () {
                      searchController.clear();
                    },
                  )
                      : null,
                ),
                onChanged: searchMenu,
              ),
            ),
          ),

          // Menu Items
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
                : errorMessage.isNotEmpty && filteredItems.isEmpty
                ? Center(child: Text(errorMessage))
                : filteredItems.isEmpty
                ? const Center(child: Text('No items found matching your search'))
                : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: filteredItems.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = filteredItems[index];
                final quantity = selectedQuantities[item.name] ?? 0;

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Item Icon
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.fastfood,
                            color: Color(0xFFFF8F00),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Item Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.category,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '₹${item.price}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Quantity Controls
                        quantity > 0
                            ? Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E7D32),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove, color: Colors.white, size: 20),
                                onPressed: () => decrementQuantity(item.name),
                                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  '$quantity',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add, color: Colors.white, size: 20),
                                onPressed: () => incrementQuantity(item.name),
                                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                              ),
                            ],
                          ),
                        )
                            : ElevatedButton(
                          onPressed: () => incrementQuantity(item.name),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          ),
                          child: const Text('Add', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),

      // Modern Checkout Button
      bottomNavigationBar: totalItems > 0
          ? Container(
        margin: const EdgeInsets.all(16),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF8F00),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            elevation: 0,
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CheckoutPage(
                  selectedQuantities: selectedQuantities,
                  availableItems: availableItems,
                  canteenName: widget.canteenName,
                ),
              ),
            );
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shopping_cart, size: 20),
              const SizedBox(width: 8),
              Text(
                'Place Order • ₹${totalPrice.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      )
          : null,
    );
  }

}
