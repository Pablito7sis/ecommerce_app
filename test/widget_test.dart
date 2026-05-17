import 'package:ecommerce_app/models/cart_item.dart';
import 'package:ecommerce_app/models/order.dart';
import 'package:ecommerce_app/models/product.dart';
import 'package:ecommerce_app/screens/catalog_screen.dart';
import 'package:ecommerce_app/services/product_service.dart';
import 'package:ecommerce_app/state/cart_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('shows catalog products from the REST repository', (
    WidgetTester tester,
  ) async {
    final repository = _FakeProductRepository();
    final cartController = CartController(repository);

    await tester.pumpWidget(
      MaterialApp(
        home: MultiProvider(
          providers: [
            Provider<ProductRepository>.value(value: repository),
            ChangeNotifierProvider<CartController>.value(value: cartController),
          ],
          child: const CatalogScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Mercado Móvil'), findsOneWidget);
    expect(find.text('Chaqueta urbana'), findsOneWidget);

    await tester.tap(find.byTooltip('Agregar al carrito').first);
    await tester.pump();

    expect(find.text('1'), findsOneWidget);
  });
}

class _FakeProductRepository implements ProductRepository {
  @override
  Future<List<Product>> fetchProducts() async {
    return const [
      Product(
        id: 1,
        title: 'Chaqueta urbana',
        description: 'Chaqueta de prueba para el catálogo.',
        price: 49.9,
        category: "men's clothing",
        imageUrl: '',
        rating: 4.7,
      ),
    ];
  }

  @override
  Future<void> createOrder(List<CartItem> items) async {}

  @override
  Future<List<Order>> fetchOrders() async => const [];
}
