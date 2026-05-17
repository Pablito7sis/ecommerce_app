import 'package:flutter/material.dart';

import '../state/cart_controller.dart';
import 'pickup_map_screen.dart';

enum DeliveryMethod { homeDelivery, storePickup }

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key, required this.cartController});

  final CartController cartController;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  DeliveryMethod _deliveryMethod = DeliveryMethod.homeDelivery;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.cartController,
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(title: const Text('Metodo de entrega')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _DeliveryOption(
                title: 'Enviar a domicilio',
                subtitle: 'Recibe el pedido en tu direccion.',
                icon: Icons.local_shipping_outlined,
                selected: _deliveryMethod == DeliveryMethod.homeDelivery,
                onTap: () {
                  setState(() => _deliveryMethod = DeliveryMethod.homeDelivery);
                },
              ),
              const SizedBox(height: 12),
              _DeliveryOption(
                title: 'Recoger en tienda',
                subtitle: 'Mira en el mapa la ruta desde tu ubicacion.',
                icon: Icons.store_mall_directory_outlined,
                selected: _deliveryMethod == DeliveryMethod.storePickup,
                onTap: () {
                  setState(() => _deliveryMethod = DeliveryMethod.storePickup);
                },
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Resumen',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text('Productos'),
                          const Spacer(),
                          Text('${widget.cartController.totalItems}'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text('Subtotal'),
                          const Spacer(),
                          Text('\$${widget.cartController.subtotal.toStringAsFixed(2)}'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text('IVA'),
                          const Spacer(),
                          Text('\$${widget.cartController.tax.toStringAsFixed(2)}'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text('Envío'),
                          const Spacer(),
                          Text('\$${widget.cartController.shipping.toStringAsFixed(2)}'),
                        ],
                      ),
                      const Divider(height: 26),
                      Row(
                        children: [
                          const Text('Total'),
                          const Spacer(),
                          Text(
                            '\$${widget.cartController.total.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            minimum: const EdgeInsets.all(16),
            child: FilledButton.icon(
              onPressed: widget.cartController.isCheckingOut
                  ? null
                  : () => _continueCheckout(context),
              icon: widget.cartController.isCheckingOut
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      _deliveryMethod == DeliveryMethod.storePickup
                          ? Icons.map_outlined
                          : Icons.lock_outline,
                    ),
              label: Text(
                _deliveryMethod == DeliveryMethod.storePickup
                    ? 'Ver ruta a la tienda'
                    : 'Confirmar pedido',
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _continueCheckout(BuildContext context) async {
    if (_deliveryMethod == DeliveryMethod.storePickup) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              PickupMapScreen(cartController: widget.cartController),
        ),
      );
      return;
    }

    try {
      await widget.cartController.checkout();
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Pedido enviado')));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo enviar el pedido')),
        );
      }
    }
  }
}

class _DeliveryOption extends StatelessWidget {
  const _DeliveryOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: selected ? colorScheme.primary : null),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: selected ? colorScheme.primary : colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
