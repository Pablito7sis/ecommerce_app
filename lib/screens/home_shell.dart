//home
import 'package:flutter/material.dart';

import '../services/product_service.dart';
import '../state/cart_controller.dart';
import 'cart_screen.dart';
import 'catalog_screen.dart';
import 'profile_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.productService,
    required this.cartController,
  });

  final ProductRepository productService;
  final CartController cartController;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      CatalogScreen(
        productService: widget.productService,
        cartController: widget.cartController,
      ),
      CartScreen(cartController: widget.cartController),
      const ProfileScreen(),
    ];

    return AnimatedBuilder(
      animation: widget.cartController,
      builder: (context, child) {
        return Scaffold(
          body: IndexedStack(index: _currentIndex, children: screens),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() => _currentIndex = index);
            },
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.storefront_outlined),
                selectedIcon: Icon(Icons.storefront),
                label: 'Tienda',
              ),
              NavigationDestination(
                icon: Badge.count(
                  count: widget.cartController.totalItems,
                  isLabelVisible: widget.cartController.totalItems > 0,
                  child: const Icon(Icons.shopping_bag_outlined),
                ),
                selectedIcon: Badge.count(
                  count: widget.cartController.totalItems,
                  isLabelVisible: widget.cartController.totalItems > 0,
                  child: const Icon(Icons.shopping_bag),
                ),
                label: 'Carrito',
              ),
              const NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Perfil',
              ),
            ],
          ),
        );
      },
    );
  }
}
