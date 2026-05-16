import 'package:flutter/foundation.dart';

import '../models/cart_item.dart';
import '../models/product.dart';
import '../services/product_service.dart';

class CartController extends ChangeNotifier {
  CartController(this._productService);

  final ProductRepository _productService;
  final Map<int, CartItem> _items = {};
  bool _isCheckingOut = false;

  List<CartItem> get items => _items.values.toList(growable: false);
  bool get isCheckingOut => _isCheckingOut;
  int get totalItems =>
      _items.values.fold(0, (sum, item) => sum + item.quantity);
  double get total => _items.values.fold(0, (sum, item) => sum + item.subtotal);

  void add(Product product) {
    final current = _items[product.id];
    _items[product.id] = current == null
        ? CartItem(product: product, quantity: 1)
        : current.copyWith(quantity: current.quantity + 1);
    notifyListeners();
  }

  void removeOne(int productId) {
    final current = _items[productId];
    if (current == null) {
      return;
    }

    if (current.quantity == 1) {
      _items.remove(productId);
    } else {
      _items[productId] = current.copyWith(quantity: current.quantity - 1);
    }

    notifyListeners();
  }

  void removeProduct(int productId) {
    _items.remove(productId);
    notifyListeners();
  }

  Future<void> checkout() async {
    if (_items.isEmpty || _isCheckingOut) {
      return;
    }

    _isCheckingOut = true;
    notifyListeners();

    try {
      await _productService.createOrder(items);
      _items.clear();
    } finally {
      _isCheckingOut = false;
      notifyListeners();
    }
  }
}
