import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CartItem {
  final String name;
  final double price;
  final String category;
  final int quantity;

  CartItem({
    required this.name,
    required this.price,
    required this.category,
    required this.quantity,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
      'category': category,
      'quantity': quantity,
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      name: json['name'],
      price: json['price'].toDouble(),
      category: json['category'],
      quantity: json['quantity'],
    );
  }
}

class CartService {
  static const _storage = FlutterSecureStorage();
  static const String _cartKey = 'user_cart';

  // Store cart items
  static Future<void> saveCart(List<CartItem> cartItems) async {
    List<Map<String, dynamic>> jsonList = cartItems.map((item) => item.toJson()).toList();
    String jsonString = jsonEncode(jsonList);
    await _storage.write(key: _cartKey, value: jsonString);
  }

  // Retrieve cart items
  static Future<List<CartItem>> getCart() async {
    String? jsonString = await _storage.read(key: _cartKey);
    if (jsonString != null && jsonString.isNotEmpty) {
      List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => CartItem.fromJson(json)).toList();
    }
    return [];
  }

  // Add item to cart
  static Future<void> addToCart(String name, double price, String category) async {
    List<CartItem> cartItems = await getCart();

    // Check if item already exists
    int existingIndex = cartItems.indexWhere((item) => item.name == name);

    if (existingIndex >= 0) {
      // Update quantity
      cartItems[existingIndex] = CartItem(
        name: name,
        price: price,
        category: category,
        quantity: cartItems[existingIndex].quantity + 1,
      );
    } else {
      // Add new item
      cartItems.add(CartItem(
        name: name,
        price: price,
        category: category,
        quantity: 1,
      ));
    }

    await saveCart(cartItems);
  }

  // Remove item from cart
  static Future<void> removeFromCart(String name) async {
    List<CartItem> cartItems = await getCart();

    int existingIndex = cartItems.indexWhere((item) => item.name == name);

    if (existingIndex >= 0) {
      if (cartItems[existingIndex].quantity > 1) {
        // Decrease quantity
        cartItems[existingIndex] = CartItem(
          name: cartItems[existingIndex].name,
          price: cartItems[existingIndex].price,
          category: cartItems[existingIndex].category,
          quantity: cartItems[existingIndex].quantity - 1,
        );
      } else {
        // Remove item completely
        cartItems.removeAt(existingIndex);
      }
    }

    await saveCart(cartItems);
  }

  // Get total items count
  static Future<int> getTotalItems() async {
    List<CartItem> cartItems = await getCart();
    return cartItems.fold<int>(0, (sum, item) => sum + item.quantity);
  }

// Get total price
  static Future<double> getTotalPrice() async {
    List<CartItem> cartItems = await getCart();
    return cartItems.fold<double>(0.0, (sum, item) => sum + (item.price * item.quantity));
  }

  // Clear cart
  static Future<void> clearCart() async {
    await _storage.delete(key: _cartKey);
  }

  // Convert cart items to the format expected by CheckoutPage
  static Future<Map<String, int>> getCartQuantities() async {
    List<CartItem> cartItems = await getCart();
    Map<String, int> quantities = {};

    for (CartItem item in cartItems) {
      quantities[item.name] = item.quantity;
    }

    return quantities;
  }
}