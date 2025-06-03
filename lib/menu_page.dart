import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:canteen_app/OrderPage.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Add this import
import 'main.dart';

class MenuPage1 extends StatefulWidget {
  const MenuPage1({super.key});

  @override
  State<MenuPage1> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage1> {
  List<MenuItem> items = [];
  bool isLoading = true;
  int _selectedIndex = 0;
  late IO.Socket socket;

  @override
  void initState() {
    super.initState();
    _initSocket();
    fetchMenu();
  }

  void _initSocket() {
    socket = IO.io('https://campcrave-backend.onrender.com', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket.connect();

    socket.onConnect((_) {
      print('✅ Connected to socket server');
    });

    socket.onDisconnect((_) => print('❌ Disconnected from socket server'));
  }

  Future<void> fetchMenu() async {
    final url = Uri.parse('https://campcrave-backend.onrender.com/menu');
    try {
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = json.decode(res.body) as List;
        setState(() {
          items = data.map((item) => MenuItem.fromJson(item)).toList();
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
    final localizations = AppLocalizations.of(context)!;
    final selectedItems = items
        .where((e) => e.isSelected)
        .map((e) => {
      "name": e.name,
      "quantity": e.quantity,
    })
        .toList();

    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.noItemsSelected)),
      );
      return;
    }

    final response = await http.patch(
      Uri.parse('https://campcrave-backend.onrender.com/menu/availability'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'items': selectedItems}),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.menuUpdated)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.failedToUpdateMenu)),
      );
    }
  }

  void _showLanguageDialog() {
    final localizations = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.language,
                color: const Color(0xFF1B73A9),
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Select Language', // You can add this to your localizations
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLanguageOption('English', 'en', Icons.language),
              const SizedBox(height: 8),
              _buildLanguageOption('हिंदी', 'hi', Icons.language),
              const SizedBox(height: 8),
              _buildLanguageOption('తెలుగు', 'te', Icons.language),
              // Add more languages as needed
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                localizations.cancel,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLanguageOption(String languageName, String languageCode, IconData icon) {
    return InkWell(
      onTap: () {
        Navigator.of(context).pop();
        _changeLanguage(languageCode);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: const Color(0xFF0DB6EA),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                languageName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
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
    );
  }

  void _changeLanguage(String languageCode) async {
    // You'll need to implement this method based on your app's localization setup
    // This typically involves updating the app's locale and rebuilding the UI

    // Example implementation (you may need to adjust based on your setup):
    // 1. Save the selected language to SharedPreferences
    // 2. Update the app's locale
    // 3. Rebuild the UI
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', languageCode);
    MyApp.setLocale(context, Locale(languageCode));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_getLanguageChangeMessage(languageCode)),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );

    // You might need to restart the app or update the locale context
    // Example: MyApp.setLocale(context, Locale(languageCode));
  }
  String _getLanguageChangeMessage(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'भाषा हिंदी में बदल गई';
      case 'te':
        return 'భాష తెలుగులోకి మార్చబడింది';
      default:
        return 'Language changed to English';
    }
  }

  void _showProfileBottomSheet() {
    final localizations = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Profile Header
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Color(0xFF0DB6EA),
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            localizations.canteenAccount,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            localizations.canteenAccount,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Language Option
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.language,
                    color: Color(0xFF2196F3),
                    size: 20,
                  ),
                ),
                title: Text(
                  'Language', // Add this to your localizations
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                onTap: () {
                  Navigator.pop(context);
                  _showLanguageDialog();
                },
              ),

              // Profile Options - Logout
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.logout,
                    color: Color(0xFFF44336),
                    size: 20,
                  ),
                ),
                title: Text(
                  localizations.logout,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFF44336),
                  ),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFFF44336)),
                onTap: () {
                  Navigator.pop(context);
                  _showLogoutDialog();
                },
              ),

              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _showLogoutDialog() {
    final localizations = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            localizations.logout,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            localizations.logoutConfirmation,
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                localizations.cancel,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _performLogout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF44336),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                localizations.logout,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        );
      },
    );
  }

  void _performLogout() {
    final localizations = AppLocalizations.of(context)!;

    // Clean up socket connection
    socket.disconnect();
    socket.dispose();

    // Clear any stored user data here
    // Example: SharedPreferences, secure storage, etc.

    // Navigate to login page and clear the navigation stack
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/login', // Replace with your login route
          (Route<dynamic> route) => false,
    );

    // Show logout success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(localizations.loggedOutSuccessfully),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _onNavItemTapped(int index) {
    if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OrdersPage()),
      );
    } else if (index == 2) {
      // Profile tab - show profile bottom sheet
      _showProfileBottomSheet();
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  int get selectedItemsCount {
    return items.where((item) => item.isSelected).length;
  }

  @override
  void dispose() {
    socket.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          localizations.updateMenu,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.black87),
            onPressed: () {},
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Canteen Header Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Container(
                //   width: 50,
                //   height: 50,
                //   decoration: BoxDecoration(
                //     color: const Color(0xFFFFF3E0),
                //     borderRadius: BorderRadius.circular(12),
                //   ),
                //   // child: const Icon(
                //   //   Icons.restaurant,
                //   //   color: Color(0xFFFF9800),
                //   //   size: 24,
                //   // ),
                // ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localizations.campusCanteen,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      // const SizedBox(height: 2),
                      // Text(
                      //   localizations.campusCanteen,
                      //   style: const TextStyle(
                      //     fontSize: 14,
                      //     color: Colors.grey,
                      //   ),
                      // ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, color: Color(0xFF4CAF50), size: 14),
                      SizedBox(width: 2),
                      Text(
                        "4.1",
                        style: TextStyle(
                          color: Color(0xFF4CAF50),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Menu Items Section
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.shopping_bag_outlined, color: Color(
                          0xFF2A6FF5), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        localizations.menuItemsCount(items.length),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: item.isSelected
                                  ? const Color(0xFF0DB6EA).withOpacity(0.3)
                                  : Colors.transparent,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF3E0),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.fastfood,
                                  color: Color(0xFF0DB6EA),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "${localizations.rupeeSymbol}${(item.quantity * 15).toStringAsFixed(0)}",
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.remove, size: 18),
                                      onPressed: item.quantity > 0
                                          ? () => setState(() => item.quantity--)
                                          : null,
                                      padding: const EdgeInsets.all(4),
                                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                    ),
                                  ),
                                  Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 12),
                                    child: Text(
                                      item.quantity.toString(),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.add, size: 18),
                                      onPressed: () => setState(() => item.quantity++),
                                      padding: const EdgeInsets.all(4),
                                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 8),
                              Checkbox(
                                value: item.isSelected,
                                onChanged: (val) {
                                  setState(() => item.isSelected = val!);
                                },
                                activeColor: const Color(0xFF0DB6EA),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Action Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitMenu,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0DB6EA),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.shopping_cart, size: 20,
                      color: Colors.black,),


                      const SizedBox(width: 8),
                      Text(
                        localizations.addToMenuWithCount(selectedItemsCount),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavItemTapped,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF0DB6EA),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.restaurant_menu),
            label: localizations.menu,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.receipt_long),
            label: localizations.orders,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.account_circle_outlined),
            label: localizations.profile,
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

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      name: json['name'],
      isSelected: json['availability'] ?? false,
      quantity: json['quantity'] ?? 0,
    );
  }
}