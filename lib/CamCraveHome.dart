import 'package:flutter/material.dart';
class CamCraveHome extends StatelessWidget {
  final List<Map<String, String>> canteens = [
    {"name": "XYZ Canteen", "image": "assets/food1.jpg"},
    {"name": "ABC Canteen", "image": "assets/food2.jpg"},
    {"name": "Campus Dhaba", "image": "assets/food3.jpg"},
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

// 🧾 Placeholder Menu Page
class MenuPage extends StatelessWidget {
  final String canteenName;

  const MenuPage({Key? key, required this.canteenName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$canteenName Menu'),
        backgroundColor: Colors.white,
      ),
      body: Center(
        child: Text(
          "Menu for $canteenName goes here!",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
