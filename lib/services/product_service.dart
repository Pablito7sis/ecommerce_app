import '../core/api_client.dart';
import '../models/cart_item.dart';
import '../models/product.dart';

abstract class ProductRepository {
  Future<List<Product>> fetchProducts();
  Future<void> createOrder(List<CartItem> items);
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
    final payload = {
      'userId': 1,
      'date': DateTime.now().toIso8601String(),
      'products': items
          .map(
            (item) => {'productId': item.product.id, 'quantity': item.quantity},
          )
          .toList(),
    };

    await _apiClient.post('/carts', payload);
  }
}
