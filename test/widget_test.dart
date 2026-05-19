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
    expect(find.text('Pantalones'), findsWidgets);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Pantalones'));
    await tester.pumpAndSettle();

    expect(find.text('Pantalón denim'), findsOneWidget);
    expect(find.text('Chaqueta urbana'), findsNothing);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -350));
    await tester.pumpAndSettle();

    final addButton = find.byTooltip('Agregar al carrito').first;
    await tester.tap(addButton);
    await tester.pump();

    expect(cartController.totalItems, 1);
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
        category: 'Abrigos',
        imageUrl: '',
        rating: 4.7,
      ),
      Product(
        id: 2,
        title: 'Pantalón denim',
        description: 'Pantalón de prueba para filtrar el catálogo.',
        price: 39.9,
        category: 'Pantalones',
        imageUrl: '',
        rating: 4.5,
      ),
    ];
  }

  @override
  Future<void> createOrder(List<CartItem> items) async {}

  @override
  Future<List<Order>> fetchOrders() async => const [];
}
