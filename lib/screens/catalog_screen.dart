import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/product.dart';
import '../state/cart_bloc.dart';
import '../state/store_controller.dart';
import '../widgets/product_card.dart';
import '../widgets/product_list_tile.dart';
import 'product_detail_screen.dart';

class CatalogScreen extends StatefulWidget {
  final StoreController store;
  const CatalogScreen({super.key, required this.store});
  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  bool _showGrid = true;
  bool _refreshing = false;
  String _category = 'All';
  String _search = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Product> _visibleProducts(List<Product> products) =>
      products.where((product) {
        final query = _search.trim().toLowerCase();
        return (_category == 'All' || product.category == _category) &&
            (query.isEmpty ||
                product.name.toLowerCase().contains(query) ||
                product.brand.toLowerCase().contains(query));
      }).toList();

  void _openProduct(Product product) => Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) =>
          ProductDetailScreen(product: product, store: widget.store),
    ),
  );

  Future<void> _refreshProducts() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    try {
      await widget.store.refreshCatalog();
      if (!mounted) return;
      _searchController.clear();
      setState(() {
        _category = 'All';
        _search = '';
      });
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  void _removeWithUndo(Product product) {
    final index = widget.store.products.indexWhere((p) => p.id == product.id);
    if (index < 0) return;
    final revision = widget.store.revision;
    widget.store.removeProduct(product.id);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('${product.name} removed'),
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: () {
              if (widget.store.revision == revision) {
                widget.store.restoreProduct(product, index);
              }
            },
          ),
        ),
      );
  }

  Widget _message({
    required IconData icon,
    required String title,
    required String message,
    required String button,
    required VoidCallback onPressed,
  }) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 54, color: const Color(0xFFE25448)),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.refresh),
            label: Text(button),
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartBloc>().state;
    return AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) {
        final status = widget.store.status;
        if (status == CatalogStatus.initial ||
            (status == CatalogStatus.loading && !widget.store.isRefreshing)) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 18),
                Text('Loading collection…'),
              ],
            ),
          );
        }
        if (status == CatalogStatus.error) {
          return _message(
            icon: Icons.wifi_off_rounded,
            title: 'Unable to load sneakers',
            message: widget.store.error ?? 'Check your internet and try again.',
            button: 'Retry Connection',
            onPressed: () => widget.store.loadCatalog(),
          );
        }
        final allProducts = widget.store.products;
        if (allProducts.isEmpty) {
          return _message(
            icon: Icons.inventory_2_outlined,
            title: 'Catalog is Empty',
            message:
                'Your collection is empty. Bring back your favorite pairs.',
            button: 'Reset Catalog',
            onPressed: () {
              _searchController.clear();
              setState(() {
                _category = 'All';
                _search = '';
              });
              widget.store.resetCatalog();
            },
          );
        }
        final visible = _visibleProducts(allProducts);
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: LayoutBuilder(
                builder: (context, size) {
                  final compact = size.maxHeight < 480;
                  final veryCompact = size.maxHeight < 260;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!compact)
                        Container(
                          padding: const EdgeInsets.all(18),
                          margin: const EdgeInsets.only(top: 8, bottom: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF272A31),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'FIND YOUR NEXT PAIR',
                                style: TextStyle(
                                  color: Color(0xFFFFB9AC),
                                  fontSize: 11,
                                  letterSpacing: 1.4,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Made for your everyday',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 23,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                'Fresh styles. Familiar comfort.',
                                style: TextStyle(
                                  color: Color(0xFFC8C8CB),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      SizedBox(
                        height: 46,
                        child: TextField(
                          controller: _searchController,
                          enabled: !_refreshing,
                          onChanged: (value) => setState(() => _search = value),
                          decoration: const InputDecoration(
                            hintText: 'Search sneakers...',
                            prefixIcon: Icon(Icons.search),
                            isDense: true,
                          ),
                        ),
                      ),
                      if (!veryCompact) ...[
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: ['All', 'Men', 'Women']
                                .map(
                                  (name) => Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: ChoiceChip(
                                      label: Text(name),
                                      selected: _category == name,
                                      onSelected: _refreshing
                                          ? null
                                          : (_) => setState(
                                              () => _category = name,
                                            ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ],
                      if (size.maxHeight >= 150)
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Discover (${visible.length})',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Refresh',
                              onPressed: _refreshing ? null : _refreshProducts,
                              icon: const Icon(Icons.refresh_rounded),
                            ),
                            IconButton(
                              tooltip: 'List view',
                              onPressed: _refreshing
                                  ? null
                                  : () => setState(() => _showGrid = false),
                              icon: Icon(
                                Icons.view_list_rounded,
                                color: !_showGrid
                                    ? const Color(0xFFE25448)
                                    : Colors.grey,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Grid view',
                              onPressed: _refreshing
                                  ? null
                                  : () => setState(() => _showGrid = true),
                              icon: Icon(
                                Icons.grid_view_rounded,
                                color: _showGrid
                                    ? const Color(0xFFE25448)
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      Expanded(
                        key: const ValueKey('catalog-body'),
                        child: visible.isEmpty
                            ? RefreshIndicator(
                                triggerMode:
                                    RefreshIndicatorTriggerMode.anywhere,
                                onRefresh: _refreshProducts,
                                child: ListView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.all(20),
                                      child: Text(
                                        'No sneakers found. Try another search.',
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() {
                                          _category = 'All';
                                          _search = '';
                                        });
                                      },
                                      child: const Text('Clear filters'),
                                    ),
                                  ],
                                ),
                              )
                            : _showGrid
                            ? _grid(visible, cart)
                            : _list(visible, cart),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _grid(List<Product> products, CartState cart) => RefreshIndicator(
    triggerMode: RefreshIndicatorTriggerMode.anywhere,
    onRefresh: _refreshProducts,
    child: GridView.builder(
      key: const PageStorageKey('catalog-grid'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 20),
      itemCount: products.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
        final product = products[index];
        return ProductCard(
          key: ValueKey(product.id),
          product: product,
          favorite: widget.store.isFavorite(product.id),
          inCart: cart.containsProduct(product.id),
          onCartToggle: () => context.read<CartBloc>().add(
            cart.containsProduct(product.id)
                ? RemoveProductEvent(product.id)
                : AddProductEvent(product),
          ),
          onTap: () => _openProduct(product),
          onFavorite: () => widget.store.toggleFavorite(product.id),
        );
      },
    ),
  );

  Widget _list(List<Product> products, CartState cart) => RefreshIndicator(
    triggerMode: RefreshIndicatorTriggerMode.anywhere,
    onRefresh: _refreshProducts,
    child: ListView.separated(
      key: const PageStorageKey('catalog-list'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 20),
      itemCount: products.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final product = products[index];
        return Dismissible(
          key: ValueKey(product.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            color: const Color(0xFFD94141),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) => _removeWithUndo(product),
          child: ProductListTile(
            product: product,
            favorite: widget.store.isFavorite(product.id),
            inCart: cart.containsProduct(product.id),
            onCartToggle: () => context.read<CartBloc>().add(
              cart.containsProduct(product.id)
                  ? RemoveProductEvent(product.id)
                  : AddProductEvent(product),
            ),
            onTap: () => _openProduct(product),
            onFavorite: () => widget.store.toggleFavorite(product.id),
          ),
        );
      },
    ),
  );
}
