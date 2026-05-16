import 'package:ecommerce_app/main.dart';
import 'package:ecommerce_app/models/cart_item.dart';
import 'package:ecommerce_app/models/product.dart';
import 'package:ecommerce_app/services/product_service.dart';
import 'package:ecommerce_app/state/cart_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows catalog products from the REST repository', (
    WidgetTester tester,
  ) async {
    final repository = _FakeProductRepository();

    await tester.pumpWidget(
      ShopApp(
        productService: repository,
        cartController: CartController(repository),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mercado Movil'), findsOneWidget);
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
        description: 'Chaqueta de prueba para el catalogo.',
        price: 49.9,
        category: "men's clothing",
        imageUrl: '',
        rating: 4.7,
      ),
    ];
  }

  @override
  Future<void> createOrder(List<CartItem> items) async {}
}
