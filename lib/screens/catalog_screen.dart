import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import '../models/product.dart';
import '../services/product_service.dart';
import '../state/cart_controller.dart';
import '../widgets/product_card.dart';
import 'product_detail_screen.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  late Future<List<Product>> _productsFuture;
  late PageController _pageController;
  Timer? _bannerTimer;
  String _query = '';
  String _selectedCategory = 'Todos';
  int _activeBanner = 0;

  final List<_BannerInfo> _banners = const [
    _BannerInfo(
      title: 'Promociones de primavera',
      subtitle: 'Descubre prendas suaves y elegantes con envío gratis.',
      color: Color(0xFFBFE3DB),
    ),
    _BannerInfo(
      title: 'Nuevos lanzamientos',
      subtitle: 'Encuentra los mejores estilos con descuento exclusivo.',
      color: Color(0xFFF8D6D7),
    ),
    _BannerInfo(
      title: 'Carrito feliz',
      subtitle: 'Agrega tus favoritos y obtén una experiencia rápida.',
      color: Color(0xFFE4D0FF),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _productsFuture = context.read<ProductRepository>().fetchProducts();
    _startBannerAutoScroll();
  }

  void _startBannerAutoScroll() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted && _pageController.hasClients) {
        final nextPage = (_activeBanner + 1) % _banners.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartController = context.read<CartController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mercado Móvil'),
        actions: [
          IconButton(
            tooltip: 'Recargar',
            onPressed: () {
              setState(() {
                _productsFuture = context
                    .read<ProductRepository>()
                    .fetchProducts();
              });
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<List<Product>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _ErrorState(
              onRetry: () {
                setState(() {
                  _productsFuture = context
                      .read<ProductRepository>()
                      .fetchProducts();
                });
              },
            );
          }

          final products = snapshot.data ?? [];
          final categories = [
            'Todos',
            ...{
              for (final product in products)
                if (product.category.trim().isNotEmpty) product.category.trim(),
            }.toList()..sort(),
          ];

          final filteredProducts = products.where((product) {
            final productCategory = product.category.trim();
            final searchText =
                '${product.title} ${product.description} $productCategory'
                    .toLowerCase();
            final categoryMatch =
                _selectedCategory == 'Todos' ||
                productCategory == _selectedCategory;
            final searchMatch = searchText.contains(
              _query.trim().toLowerCase(),
            );
            return categoryMatch && searchMatch;
          }).toList();

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _productsFuture = context
                    .read<ProductRepository>()
                    .fetchProducts();
              });
              await _productsFuture;
            },
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      const SizedBox(height: 18),
                      SizedBox(
                        height: 150,
                        child: PageView.builder(
                          controller: _pageController,
                          onPageChanged: (index) {
                            setState(() => _activeBanner = index);
                          },
                          itemCount: _banners.length,
                          itemBuilder: (context, index) {
                            final item = _banners[index];
                            return Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color: item.color,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    item.subtitle,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyLarge,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _banners.length,
                          (index) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: _activeBanner == index ? 18 : 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: _activeBanner == index
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(
                                      context,
                                    ).colorScheme.primary.withAlpha(102),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TextField(
                          onChanged: (value) => setState(() => _query = value),
                          decoration: InputDecoration(
                            hintText: 'Buscar productos',
                            prefixIcon: const Icon(Icons.search),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 46,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          scrollDirection: Axis.horizontal,
                          itemCount: categories.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: 10),
                          itemBuilder: (context, index) {
                            final category = categories[index];
                            final selected = _selectedCategory == category;
                            return ChoiceChip(
                              label: Text(category),
                              selected: selected,
                              onSelected: (_) {
                                setState(() => _selectedCategory = category);
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
                if (filteredProducts.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.search_off_outlined, size: 56),
                          const SizedBox(height: 12),
                          const Text('No encontramos productos que coincidan.'),
                          const SizedBox(height: 14),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _query = '';
                                _selectedCategory = 'Todos';
                              });
                            },
                            child: const Text('Mostrar todo'),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    sliver: SliverGrid.builder(
                      itemCount: filteredProducts.length,
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 260,
                            mainAxisExtent: 306,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                          ),
                      itemBuilder: (context, index) {
                        final product = filteredProducts[index];
                        return ProductCard(
                          product: product,
                          onOpen: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    ProductDetailScreen(product: product),
                              ),
                            );
                          },
                          onAdd: () {
                            cartController.add(product);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Producto agregado al carrito'),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BannerInfo {
  const _BannerInfo({
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final String title;
  final String subtitle;
  final Color color;
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 44,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              'No pudimos cargar el catálogo.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Intentar de nuevo'),
            ),
          ],
        ),
      ),
    );
  }
}
