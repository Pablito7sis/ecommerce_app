import 'package:flutter/material.dart';

import '../state/cart_controller.dart';
import 'checkout_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key, required this.cartController});

  final CartController cartController;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: cartController,
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(title: const Text('Carrito')),
          body: cartController.items.isEmpty
              ? const Center(child: Text('Tu carrito esta vacio.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: cartController.items.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = cartController.items[index];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            SizedBox.square(
                              dimension: 72,
                              child: Image.network(
                                item.product.imageUrl,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.image),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.product.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleSmall,
                                  ),
                                  const SizedBox(height: 6),
                                  Text('\$${item.subtotal.toStringAsFixed(2)}'),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Quitar uno',
                              onPressed: () =>
                                  cartController.removeOne(item.product.id),
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                            Text('${item.quantity}'),
                            IconButton(
                              tooltip: 'Agregar uno',
                              onPressed: () => cartController.add(item.product),
                              icon: const Icon(Icons.add_circle_outline),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          bottomNavigationBar: cartController.items.isEmpty
              ? null
              : SafeArea(
                  minimum: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Total',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const Spacer(),
                          Text(
                            '\$${cartController.total.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: cartController.isCheckingOut
                              ? null
                              : () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => CheckoutScreen(
                                        cartController: cartController,
                                      ),
                                    ),
                                  );
                                },
                          icon: cartController.isCheckingOut
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.lock_outline),
                          label: const Text('Continuar compra'),
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}
