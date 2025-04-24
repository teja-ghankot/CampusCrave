import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class MenuItem {
  final String name;
  final String category;
  final double price;
  final bool availability;
  final int quantity;

  MenuItem({
    required this.name,
    required this.category,
    required this.price,
    required this.availability,
    required this.quantity,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      availability: json['availability'] ?? false,
      quantity: json['quantity'] ?? 0,
    );
  }
}

class CamCraveHome extends StatelessWidget {
  final List<Map<String, String>> canteens = [
    {"name": "XYZ Canteen", "image": "assets/food_image.jpg"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.favorite_border), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: ''),
        ],
        onTap: (index) {
          if (index == 4) {
            // Show logout button when person icon is tapped
            showModalBottomSheet(
              context: context,
              builder: (context) => Container(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: ListTile(
                  leading: Icon(Icons.logout, color: Colors.red),
                  title: Text('Logout', style: TextStyle(fontSize: 16)),
                  onTap: () {
                    // Close bottom sheet
                    Navigator.pop(context);

                    // Navigate to login page (replace with your actual login page)
                    Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/login', // Use your actual route name
                            (route) => false
                    );

                    // If you don't use named routes, use this instead:
                    /*
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => LoginPage()),
                      (route) => false
                    );
                    */
                  },
                ),
              ),
            );
          }
        },
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Location and Notification Row
              Row(
                children: const [
                  Icon(Icons.location_on_outlined),
                  SizedBox(width: 8),
                  Text("Seating near tree"),
                  Icon(Icons.keyboard_arrow_down),
                  Spacer(),
                  Icon(Icons.notifications_none),
                ],
              ),
              const SizedBox(height: 16),

              // Search bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[200],
                ),
                child: const TextField(
                  decoration: InputDecoration(
                    icon: Icon(Icons.search),
                    hintText: "Search CamCrave",
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Categories
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: const [
                  Text("🥟"),
                  Text("🍱"),
                  Text("🍛"),
                  Text("🥡"),
                  Text("🧆"),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: const [
                  Text("Puri"),
                  Text("Meals"),
                  Text("Rice"),
                  Text("Chinese"),
                  Text("Chaat"),
                ],
              ),
              const SizedBox(height: 16),

              // Featured Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    "Featured on CamCrave",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
              const SizedBox(height: 12),

              // Vertical list of canteens
              ...canteens.map(
                    (canteen) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _canteenCard(
                    context,
                    canteen["image"]!,
                    canteen["name"]!,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _canteenCard(BuildContext context, String imagePath, String name) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => MenuPage(canteenName: name)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[100],
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            // Image at the top
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.asset(
                imagePath,
                width: double.infinity,
                height: 150,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: double.infinity,
                    height: 150,
                    color: Colors.grey[300],
                    child: Icon(Icons.image_not_supported),
                  );
                },
              ),
            ),
            // Canteen name
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Menu Page
class MenuPage extends StatefulWidget {
  final String canteenName;

  const MenuPage({Key? key, required this.canteenName}) : super(key: key);

  @override
  _MenuPageState createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  List<MenuItem> availableItems = [];
  bool isLoading = true;
  String errorMessage = '';

  // Function to fetch menu items from the backend based on canteen selection
  Future<void> fetchMenu(String canteenName) async {
    // Use your actual API URL - if using a real device, use your computer's actual IP address
    // Example: 'http://192.168.1.100:3000/menu'
    final String url = 'http://10.0.2.2:3000/menu';

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      print('Fetching menu from: $url');
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('Parsed data length: ${data.length}');

        setState(() {
          availableItems = data
              .map((item) => MenuItem.fromJson(item))
              .where((item) => item.availability)
              .toList();
          isLoading = false;
          print('Available items: ${availableItems.length}');
        });
      } else {
        throw Exception('Server responded with status code: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching menu: $error');
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load menu: $error';
        // For debugging purposes, add some mock data
        if (availableItems.isEmpty) {
          availableItems = [
            MenuItem(
              name: "Test Dosa",
              category: "South Indian",
              price: 80.0,
              availability: true,
              quantity: 15,
            ),
            MenuItem(
              name: "Test Biryani",
              category: "Main Course",
              price: 120.0,
              availability: true,
              quantity: 8,
            ),
          ];
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchMenu(widget.canteenName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.canteenName} Menu'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => fetchMenu(widget.canteenName),
          ),
        ],
      ),
      body: isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading menu items...'),
          ],
        ),
      )
          : errorMessage.isNotEmpty && availableItems.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            SizedBox(height: 16),
            Text(
              'Error loading menu',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                errorMessage,
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => fetchMenu(widget.canteenName),
              child: Text('Try Again'),
            ),
          ],
        ),
      )
          : availableItems.isEmpty
          ? Center(
        child: Text('No menu items available'),
      )
          : ListView.separated(
        itemCount: availableItems.length,
        separatorBuilder: (context, index) => Divider(),
        itemBuilder: (context, index) {
          final item = availableItems[index];
          return ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Text(
              item.name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 4),
                Text(item.category),
                SizedBox(height: 4),
                Text(
                  '₹${item.price.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Available: ${item.quantity}'),
                SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    // Add to cart functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Added ${item.name} to cart'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Text('Add'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            isThreeLine: true,
          );
        },
      ),
    );
  }
}