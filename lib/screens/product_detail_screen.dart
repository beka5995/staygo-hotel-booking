import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/product.dart';
import '../state/cart_bloc.dart';
import '../state/store_controller.dart';
import '../services/product_links.dart';
import '../utils/price.dart';
import '../widgets/photo_gallery.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  final StoreController store;

  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.store,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int? _selectedSize;

  void _share() {
    final link = ProductLink.forSneaker(widget.product.id);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Share this pair',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(widget.product.name),
              const SizedBox(height: 18),
              SelectableText(link, style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy link'),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: link));
                    if (!sheetContext.mounted) return;
                    Navigator.pop(sheetContext);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Link copied')),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    return Scaffold(
      appBar: AppBar(
        title: const Text('SneakShop'),
        actions: [
          IconButton(
            tooltip: 'Share',
            onPressed: _share,
            icon: const Icon(Icons.ios_share_outlined),
          ),
          const SizedBox(width: 7),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    PhotoGallery(
                      key: ValueKey(product.id),
                      photos: product.photos.isEmpty
                          ? [product.imageUrl]
                          : product.photos,
                      heroTag: 'sneaker_image_${product.id}',
                    ),
                    Positioned(
                      top: 14,
                      left: 14,
                      child: AnimatedBuilder(
                        animation: widget.store,
                        builder: (context, _) => IconButton.filledTonal(
                          tooltip: 'Favorite',
                          onPressed: () =>
                              widget.store.toggleFavorite(product.id),
                          icon: Icon(
                            widget.store.isFavorite(product.id)
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: widget.store.isFavorite(product.id)
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context)
                                      .colorScheme
                                      .onSecondaryContainer,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  product.brand.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    letterSpacing: 1.4,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 7),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      formatPrice(product.price),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Color(0xFFF2AA40),
                      size: 20,
                    ),
                    Text(
                      ' ${product.rating.toStringAsFixed(1)}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 12),
                    Chip(label: Text(product.category)),
                    if (product.isNew)
                      const Padding(
                        padding: EdgeInsets.only(left: 6),
                        child: Chip(label: Text('New arrival')),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'About this pair',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(product.description, style: const TextStyle(height: 1.5)),
                const SizedBox(height: 22),
                const Text(
                  'Choose size (EU)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 7,
                  children: product.sizes
                      .map(
                        (size) => ChoiceChip(
                          label: Text('$size'),
                          selected: _selectedSize == size,
                          onSelected: (_) =>
                              setState(() => _selectedSize = size),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back to catalog'),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.shopping_bag_outlined),
                    label: const Text('Add to Cart'),
                    onPressed: () {
                      if (_selectedSize == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Choose your size first'),
                          ),
                        );
                        return;
                      }
                      context.read<CartBloc>().add(
                        AddProductEvent(product, size: _selectedSize!),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${product.name} added to your bag'),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProductLinkScreen extends StatefulWidget {
  final String productId;
  final StoreController store;
  const ProductLinkScreen({
    super.key,
    required this.productId,
    required this.store,
  });
  @override
  State<ProductLinkScreen> createState() => _ProductLinkScreenState();
}

class _ProductLinkScreenState extends State<ProductLinkScreen> {
  late Future<Product> _future;
  @override
  void initState() {
    super.initState();
    _future = widget.store.productById(widget.productId);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Product>(
    future: _future,
    builder: (context, snapshot) {
      if (snapshot.hasData) {
        return ProductDetailScreen(
          product: snapshot.requireData,
          store: widget.store,
        );
      }
      return Scaffold(
        appBar: AppBar(title: const Text('SneakShop')),
        body: Center(
          child: snapshot.connectionState != ConnectionState.done
              ? const CircularProgressIndicator()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wifi_off_rounded, size: 48),
                      const SizedBox(height: 14),
                      const Text(
                        'Unable to open this pair',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text('${snapshot.error}', textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => setState(() {
                          _future = widget.store.productById(widget.productId);
                        }),
                        child: const Text('Retry Connection'),
                      ),
                    ],
                  ),
                ),
        ),
      );
    },
  );
}
