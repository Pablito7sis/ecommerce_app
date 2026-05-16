import 'package:flutter/material.dart';

import 'core/api_client.dart';
import 'screens/home_shell.dart';
import 'services/product_service.dart';
import 'state/cart_controller.dart';

void main() {
  const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://fakestoreapi.com',
  );

  final apiClient = ApiClient(baseUrl: apiBaseUrl);
  final productService = ProductService(apiClient);
  final cartController = CartController(productService);

  runApp(
    ShopApp(productService: productService, cartController: cartController),
  );
}

class ShopApp extends StatelessWidget {
  const ShopApp({
    super.key,
    required this.productService,
    required this.cartController,
  });

  final ProductRepository productService;
  final CartController cartController;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mercado Movil',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0E7C7B),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F5F0),
        appBarTheme: const AppBarTheme(centerTitle: false),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      home: HomeShell(
        productService: productService,
        cartController: cartController,
      ),
    );
  }
}
