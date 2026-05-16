import 'package:flutter/material.dart';

import '../models/product.dart';
import '../state/cart_controller.dart';

class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.cartController,
  });

  final Product product;
  final CartController cartController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Image.network(
                  product.imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.image_not_supported),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            product.category.toUpperCase(),
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 8),
          Text(product.title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.star, color: Color(0xFFE9B44C), size: 20),
              const SizedBox(width: 4),
              Text(product.rating.toStringAsFixed(1)),
              const Spacer(),
              Text(
                '\$${product.price.toStringAsFixed(2)}',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            product.description,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: FilledButton.icon(
          onPressed: () {
            cartController.add(product);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Producto agregado al carrito')),
            );
          },
          icon: const Icon(Icons.add_shopping_cart),
          label: const Text('Agregar al carrito'),
        ),
      ),
    );
  }
}
