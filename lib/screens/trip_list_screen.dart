
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
            TextButton(
              onPressed: cart.clear,
              child: const Text('Clear All'),
            ),
        ],
      ),
      body: items.isEmpty
          ? const Center(
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
      )
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, _) =>
        const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = items[index];

          return Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius:
                        BorderRadius.circular(10),
                        child: HotelImage(
                          url: item.hotel.imageUrl,
                          width: 80,
                          height: 80,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.hotel.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(item.hotel.city),
                            Text(
                              '\$${item.hotel.pricePerNight} / night',
                              style: const TextStyle(
                                color: AppTheme.teal,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Remove item',
                        onPressed: () =>
                            cart.removeHotel(item.hotel.id),
                        icon: const Icon(
                          Icons.delete_outline,
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  Row(
                    children: [
                      const Text('Nights'),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Decrease nights',
                        onPressed: () => cart.changeNights(
                          item.hotel.id,
                          -1,
                        ),
                        icon: const Icon(
                          Icons.remove_circle_outline,
                        ),
                      ),
                      Text('${item.nights}'),
                      IconButton(
                        tooltip: 'Increase nights',
                        onPressed: () => cart.changeNights(
                          item.hotel.id,
                          1,
                        ),
                        icon: const Icon(
                          Icons.add_circle_outline,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '\$${item.hotel.pricePerNight * item.nights}',
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
        child: Row(
          children: [
            const Text(
              'Total',
              style: TextStyle(fontSize: 19),
            ),
            const Spacer(),
            Text(
              '\$${cart.totalPrice}',
              style: const TextStyle(
                fontSize: 23,
                color: AppTheme.teal,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
