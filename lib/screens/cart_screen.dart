import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../state/cart_bloc.dart';
import '../utils/price.dart';
import '../widgets/product_image.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<CartBloc, CartState>(builder: _buildCart);

  Widget _buildCart(BuildContext context, CartState cart) {
    final bloc = context.read<CartBloc>();
    final items = cart.items;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping bag'),
        actions: [
          if (items.isNotEmpty)
            TextButton(
              onPressed: () => bloc.add(const ClearCartEvent()),
              child: const Text('Clear All'),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: items.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.shopping_bag_outlined,
                        size: 56,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 12),
                      Text('Your bag is empty'),
                      SizedBox(height: 4),
                      Text(
                        'Add your favorite sneakers to start shopping.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 22),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Row(
                      children: [
                        ProductImage(
                          url: item.product.imageUrl,
                          width: 78,
                          height: 88,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.product.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'EU ${item.size}',
                                style: const TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(height: 4),
                              Text(formatPrice(item.product.price)),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            IconButton(
                              tooltip: 'Remove item',
                              onPressed: () => bloc.add(
                                RemoveProductEvent(
                                  item.product.id,
                                  size: item.size,
                                ),
                              ),
                              icon: const Icon(Icons.delete_outline),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Decrease quantity',
                                  onPressed: () =>
                                      bloc.add(ChangeQuantityEvent(item, -1)),
                                  icon: const Icon(Icons.remove_circle_outline),
                                ),
                                Text('${item.quantity}'),
                                IconButton(
                                  tooltip: 'Increase quantity',
                                  onPressed: () =>
                                      bloc.add(ChangeQuantityEvent(item, 1)),
                                  icon: const Icon(Icons.add_circle_outline),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
        ),
      ),
      bottomNavigationBar: items.isEmpty
          ? null
          : SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total', style: TextStyle(fontSize: 17)),
                      Text(
                        formatPrice(cart.totalPrice),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      onPressed: () {
                        showDialog<void>(
                          context: context,
                          builder: (dialogContext) => AlertDialog(
                            title: const Text('Checkout'),
                            content: const Text(
                              'Online checkout is not available yet. Your selected pairs will stay in your bag.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(dialogContext),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                onPressed: () {
                                  Navigator.pop(dialogContext);
                                },
                                child: const Text('Got it'),
                              ),
                            ],
                          ),
                        );
                      },
                      child: const Text('Checkout'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
