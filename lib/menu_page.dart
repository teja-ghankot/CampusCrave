import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:canteen_app/OrderPage.dart';

class MenuPage1 extends StatefulWidget {
  const MenuPage1({super.key});

  @override
  State<MenuPage1> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage1> {
  List<MenuItem> items = [];
  bool isLoading = true;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    fetchMenu();
  }

  Future<void> fetchMenu() async {
    final url = Uri.parse('http://10.0.2.2:3000/menu'); // Change if needed
    try {
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        setState(() {
          items = List<MenuItem>.from(
            data.map((item) => MenuItem(name: item['name'])),
          );
          isLoading = false;
        });
      } else {
        throw Exception("Failed to load menu");
      }
    } catch (e) {
      print("Error fetching menu: $e");
      setState(() => isLoading = false);
    }
  }

  void _submitMenu() async {
    final selectedItems = items
        .where((e) => e.isSelected)
        .map((e) => {
      "name": e.name,
      "quantity": e.quantity,
    })
        .toList();

    final response = await http.patch(
      Uri.parse('http://10.0.2.2:3000/menu/availability'), // ⚠️ Replace with your backend IP
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'items': selectedItems}),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Menu updated")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update menu")),
      );
    }
  }

  // Handle Bottom Navigation Bar item selection
  void _onNavItemTapped(int index) {
    if (index == 1) {
      // Navigate to OrdersPage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OrdersPage()),
      );
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Update Menu"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // Notification action (if any)
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            "Today's Menu",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Checkbox(
                    value: item.isSelected,
                    onChanged: (val) {
                      setState(() => item.isSelected = val!);
                    },
                  ),
                  Expanded(
                      child: Text(item.name,
                          style: const TextStyle(fontSize: 16))),
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: item.quantity > 0
                        ? () => setState(() => item.quantity--)
                        : null,
                  ),
                  Text(item.quantity.toString(),
                      style: const TextStyle(fontSize: 16)),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () =>
                        setState(() => item.quantity++),
                  ),
                ],
              ),
            ),
          )),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _submitMenu,
            icon: const Icon(Icons.check_circle_outline),
            label: const Text("Add to Menu"),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              textStyle: const TextStyle(fontSize: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavItemTapped,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.menu),
            label: 'Menu',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class MenuItem {
  final String name;
  bool isSelected;
  int quantity;

  MenuItem({required this.name, this.isSelected = false, this.quantity = 0});
}
