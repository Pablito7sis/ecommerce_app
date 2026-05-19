class OrderItem {
  const OrderItem({
    required this.productId,
    required this.quantity,
    required this.price,
  });

  final int productId;
  final int quantity;
  final double price;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: (json['product_id'] as num).toInt(),
      quantity: (json['quantity'] as num).toInt(),
      price: (json['price'] as num).toDouble(),
    );
  }
}

class Order {
  const Order({
    required this.id,
    required this.date,
    required this.status,
    required this.subtotal,
    required this.tax,
    required this.shipping,
    required this.total,
    required this.items,
  });

  final int id;
  final DateTime date;
  final String status;
  final double subtotal;
  final double tax;
  final double shipping;
  final double total;
  final List<OrderItem> items;

  factory Order.fromJson(Map<String, dynamic> json) {
    final itemList = json['items'];
    return Order(
      id: (json['id'] as num).toInt(),
      date: DateTime.parse(json['date'] as String),
      status: json['status'] as String? ?? 'En proceso',
      subtotal: (json['subtotal'] as num).toDouble(),
      tax: (json['tax'] as num).toDouble(),
      shipping: (json['shipping'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      items: itemList is List
          ? itemList
              .whereType<Map<String, dynamic>>()
              .map(OrderItem.fromJson)
              .toList()
          : const [],
    );
  }
}
