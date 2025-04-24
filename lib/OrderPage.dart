import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:canteen_app/menu_page.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool isLoading = true;
  List<Order> orders = [];
  int _selectedIndex = 1; // Orders tab selected

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    fetchOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> fetchOrders() async {
    setState(() => isLoading = true);

    try {
      final url = Uri.parse('http://10.0.2.2:3000/orders');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          orders = List<Order>.from(data.map((item) => Order.fromJson(item)));
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load orders');
      }
    } catch (e) {
      print('Error fetching orders: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      final url = Uri.parse('http://10.0.2.2:3000/orders/$orderId/status');
      final response = await http.patch(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({"status": newStatus}),
      );

      if (response.statusCode == 200) {
        fetchOrders(); // Refresh the order list after updating the status
      } else {
        throw Exception('Failed to update order status');
      }
    } catch (e) {
      print('Error updating order status: $e');
    }
  }

  // Handle Bottom Navigation Bar item selection
  void _onNavItemTapped(int index) {
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MenuPage1()),
      );
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  // Unified _buildOrdersTab method for all tab states
  Widget _buildOrdersTab(String status) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Filter orders by the provided status
    final filteredOrders = orders.where((order) => order.status.toLowerCase() == status.toLowerCase()).toList();

    if (filteredOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/cooking.png', // Replace with your cooking image
              width: 120,
              height: 120,
            ),
            const SizedBox(height: 20),
            const Text(
              'NO ORDERS!!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Orders with status "$status" will be shown here.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredOrders.length,
      itemBuilder: (context, index) {
        final order = filteredOrders[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order #${order.id}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text('Customer: ${order.customerName}'),
                const SizedBox(height: 4),
                Text('Items: ${order.items.join(', ')}'),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total: ₹${order.total.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (status == 'Preparing') {
                          updateOrderStatus(order.id, 'Ready');
                        } else if (status == 'Ready') {
                          updateOrderStatus(order.id, 'Pickup');
                        }
                      },
                      child: Text(status == 'Preparing'
                          ? 'Mark Ready'
                          : status == 'Ready'
                          ? 'Mark Picked Up'
                          : 'Archive'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // Notification action
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Preparing'),
            Tab(text: 'Ready'),
            Tab(text: 'Pickup'),
          ],
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.black,
          indicatorColor: Colors.blue,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrdersTab('Preparing'), // Preparing Tab
          _buildOrdersTab('Ready'), // Ready Tab
          _buildOrdersTab('Pickup'), // Pickup Tab
        ],
      ),
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

class Order {
  final String id;
  final String customerName;
  final List<String> items;
  final double total;
  final String status;

  Order({
    required this.id,
    required this.customerName,
    required this.items,
    required this.total,
    required this.status,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['_id'],
      customerName: json['customerName'],
      items: List<String>.from(json['items']),
      total: json['total'].toDouble(),
      status: json['status'],
    );
  }
}
