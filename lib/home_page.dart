import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  // Dummy menu items for the canteen
  final List<Map<String, String>> menuItems = const [
    {
      "title": "Veg Burger",
      "image": "assets/burger.png",
      "description": "Fresh & healthy",
      "price": "₹120"
    },
    {
      "title": "Chicken Wrap",
      "image": "assets/chicken_wrap.png",
      "description": "Spicy & tasty",
      "price": "₹150"
    },
    {
      "title": "Pizza Slice",
      "image": "assets/pizza.png",
      "description": "Cheesy delight",
      "price": "₹200"
    },
    {
      "title": "Sandwich",
      "image": "assets/sandwich.png",
      "description": "Quick bite",
      "price": "₹100"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        title: Row(
          children: [
            const Icon(Icons.person, color: Colors.black54),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.centerLeft,
                child: const Text("Select Pickup Point",
                    style: TextStyle(color: Colors.black54)),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.deepPurple[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text("₹Amount",
                  style: TextStyle(color: Colors.deepPurple)),
            ),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon:
                const Icon(Icons.search, color: Colors.deepPurple),
                suffixIcon: const Icon(Icons.mic, color: Colors.deepPurple),
                hintText: "Search for canteen items",
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 0, horizontal: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          // Categories horizontal list
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildCategoryChip("All", isSelected: true),
                _buildCategoryChip("Burgers"),
                _buildCategoryChip("Wraps"),
                _buildCategoryChip("Pizzas"),
                _buildCategoryChip("Sandwiches"),
                _buildCategoryChip("Drinks"),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Modern Menu Grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: GridView.builder(
                itemCount: menuItems.length,
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.75,
                ),
                itemBuilder: (context, index) {
                  final item = menuItems[index];
                  return _buildMenuCard(item, context);
                },
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long), label: "Orders"),
          BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart), label: "Cart"),
          BottomNavigationBarItem(
              icon: Icon(Icons.favorite), label: "Favorites"),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, {bool isSelected = false}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Chip(
        label: Text(label),
        backgroundColor:
        isSelected ? Colors.deepPurple : Colors.grey[300],
        labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.black87),
      ),
    );
  }

  Widget _buildMenuCard(Map<String, String> item, BuildContext context) {
    return Card(
      elevation: 4,
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () {
          // You can navigate to a detailed menu page here if needed
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image container with rounded corners
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    image: DecorationImage(
                      image: AssetImage(item["image"] ?? ""),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(item["title"] ?? "",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              Text(item["description"] ?? "",
                  style: const TextStyle(
                      fontSize: 12, color: Colors.grey, height: 1.2)),
              const SizedBox(height: 4),
              Text(item["price"] ?? "",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple)),
            ],
          ),
        ),
      ),
    );
  }
}
