import '../core/api_client.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import '../models/product.dart';

abstract class ProductRepository {
  Future<List<Product>> fetchProducts();
  Future<void> createOrder(List<CartItem> items);
  Future<List<Order>> fetchOrders();
}

class ProductService implements ProductRepository {
  ProductService(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<List<Product>> fetchProducts() async {
    final data = await _apiClient.get('/products');

    if (data is! List) {
      throw const FormatException('La respuesta de productos no es una lista.');
    }

    return data
        .whereType<Map<String, dynamic>>()
        .map(Product.fromJson)
        .toList();
  }

  @override
  Future<void> createOrder(List<CartItem> items) async {
    final subtotal = items.fold<double>(0, (sum, item) => sum + item.subtotal);
    final tax = subtotal * 0.16;
    final shipping = subtotal > 120 ? 0.0 : 8.99;

    final payload = {
      'date': DateTime.now().toIso8601String(),
      'subtotal': subtotal,
      'tax': tax,
      'shipping': shipping,
      'total': subtotal + tax + shipping,
      'products': items
          .map(
            (item) => {
              'product_id': item.product.id,
              'quantity': item.quantity,
              'price': item.product.price,
            },
          )
          .toList(),
    };

    await _apiClient.post('/orders', payload);
  }

  @override
  Future<List<Order>> fetchOrders() async {
    final data = await _apiClient.get('/orders');

    if (data is! List) {
      throw const FormatException('La respuesta de pedidos no es una lista.');
    }

    return data
        .whereType<Map<String, dynamic>>()
        .map(Order.fromJson)
        .toList();
  }
}
