import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/cart_controller.dart';
import 'checkout_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cartController = context.watch<CartController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Carrito')),
      body: cartController.items.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.shopping_bag_outlined, size: 72),
                    const SizedBox(height: 16),
                    const Text(
                      'Tu carrito está vacío',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Busca productos, agrégalos al carrito y vuelve cuando estés listo para pagar.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: cartController.items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = cartController.items[index];
                return Card(
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox.square(
                            dimension: 72,
                            child: Image.network(
                              item.product.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                child: const Icon(Icons.image_not_supported, size: 32),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.product.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Precio unitario: \$${item.product.price.toStringAsFixed(2)}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  IconButton(
                                    tooltip: 'Disminuir cantidad',
                                    onPressed: () => cartController.removeOne(item.product.id),
                                    icon: const Icon(Icons.remove_circle_outline),
                                  ),
                                  Text(
                                    item.quantity.toString(),
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  IconButton(
                                    tooltip: 'Aumentar cantidad',
                                    onPressed: () => cartController.add(item.product),
                                    icon: const Icon(Icons.add_circle_outline),
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    tooltip: 'Eliminar item',
                                    onPressed: () => cartController.removeProduct(item.product.id),
                                    icon: const Icon(Icons.delete_outline),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Subtotal: \$${item.subtotal.toStringAsFixed(2)}',
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('Resumen del pedido', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 14),
                          _SummaryRow(label: 'Subtotal', value: cartController.subtotal),
                          const SizedBox(height: 8),
                          _SummaryRow(label: 'IVA (16%)', value: cartController.tax),
                          const SizedBox(height: 8),
                          _SummaryRow(label: 'Envío', value: cartController.shipping),
                          if (cartController.shipping == 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                'Envío gratis por compras mayores a \$120.00',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          const Divider(height: 28),
                          _SummaryRow(
                            label: 'Total',
                            value: cartController.total,
                            valueStyle: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: cartController.isCheckingOut
                        ? null
                        : () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => CheckoutScreen(cartController: cartController),
                              ),
                            );
                          },
                    icon: cartController.isCheckingOut
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.lock_outline),
                    label: const Text('Proceder al pago'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Esta acción simula una compra y reserva tu pedido.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueStyle,
  });

  final String label;
  final double value;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label),
        const Spacer(),
        Text(
          '\$${value.toStringAsFixed(2)}',
          style: valueStyle ?? const TextStyle(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
