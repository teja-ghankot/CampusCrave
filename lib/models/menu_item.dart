class MenuItem {
  final String name;
  final String category;
  final double price;
  final bool availability;
  int quantity;

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