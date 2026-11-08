import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/hotel_image.dart';

class TripListScreen extends StatelessWidget {
  const TripListScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final items = cart.items;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip List'),
        actions: [
          if (items.isNotEmpty)
            TextButton(onPressed: cart.clear, child: const Text('Clear All')),
        ],
      ),
      body: items.isEmpty
          ? const Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.luggage_outlined,
                      size: 65,
                      color: AppTheme.muted,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Your trip list is empty',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 7),
                    Text('Add hotels from Explore.'),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                final hotel = item.hotel;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: HotelImage(
                                url: hotel.imageUrl,
                                width: 62,
                                height: 72,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    hotel.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(hotel.city),
                                  Text(
                                    hotel.hasPrice
                                        ? '${hotel.priceLabel} / night'
                                        : hotel.priceLabel,
                                    style: const TextStyle(
                                      color: AppTheme.teal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Remove item',
                              onPressed: () => cart.removeHotel(hotel.id),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                        const Divider(),
                        Wrap(
                          spacing: 12,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Text('Nights'),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Decrease nights',
                                  onPressed: item.nights > 1
                                      ? () => cart.changeNights(hotel.id, -1)
                                      : null,
                                  icon: const Icon(Icons.remove_circle_outline),
                                ),
                                Text('${item.nights}'),
                                IconButton(
                                  tooltip: 'Increase nights',
                                  onPressed: item.nights < 30
                                      ? () => cart.changeNights(hotel.id, 1)
                                      : null,
                                  icon: const Icon(Icons.add_circle_outline),
                                ),
                              ],
                            ),
                            Text(
                              hotel.hasPrice
                                  ? '\$${(hotel.pricePerNight * item.nights).toStringAsFixed(2)}'
                                  : 'Rate pending',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: items.isEmpty
          ? null
          : SafeArea(
              minimum: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Estimated total',
                          style: TextStyle(fontSize: 17),
                        ),
                      ),
                      Text(
                        '\$${cart.totalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 23,
                          color: AppTheme.teal,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    cart.unpricedCount > 0
                        ? '${cart.unpricedCount} stays awaiting rates; excluded from total.'
                        : 'USD estimate. Final rates depend on dates and availability.',
                    style: const TextStyle(fontSize: 11, color: AppTheme.muted),
                  ),
                ],
              ),
            ),
    );
  }
}
