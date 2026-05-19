import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/api_client.dart';
import 'screens/home_shell.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'services/product_service.dart';
import 'state/auth_controller.dart';
import 'state/cart_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  final sharedPreferences = await SharedPreferences.getInstance();
  final apiClient = ApiClient(baseUrl: apiBaseUrl);
  final authService = AuthService(apiClient);
  final authController = AuthController(
    authService,
    sharedPreferences,
    apiClient,
  );
  await authController.restoreSession();

  final productService = ProductService(apiClient);
  final cartController = CartController(productService);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authController),
        ChangeNotifierProvider.value(value: cartController),
        Provider<ProductRepository>.value(value: productService),
      ],
      child: const ShopApp(),
    ),
  );
}

class ShopApp extends StatelessWidget {
  const ShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mercado Movil',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7EC8C9),
          background: const Color(0xFFFCF7F0),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFFCF7F0),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          surfaceTintColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black87),
        ),
        cardTheme: const CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthController>(
      builder: (context, auth, child) {
        if (auth.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (auth.isAuthenticated) {
          return const HomeShell();
        }

        return const LoginScreen();
      },
    );
  }
}
