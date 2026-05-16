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
  static const Set<String> _clothingCategories = {
    "men's clothing",
    "women's clothing",
  };
  static const List<String> _nonClothingKeywords = [
    'backpack',
    'bag',
    'purse',
    'wallet',
  ];

  @override
  Future<List<Product>> fetchProducts() async {
    final data = await _apiClient.get('/products');

    if (data is! List) {
      throw const FormatException('La respuesta de productos no es una lista.');
    }

    return data
        .whereType<Map<String, dynamic>>()
        .map(Product.fromJson)
        .where(_isClothingProduct)
        .toList();
  }

  bool _isClothingProduct(Product product) {
    final title = product.title.toLowerCase();
    final category = product.category.toLowerCase();

    return _clothingCategories.contains(category) &&
        !_nonClothingKeywords.any(title.contains);
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
