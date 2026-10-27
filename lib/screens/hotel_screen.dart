
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/hotel.dart';
import '../providers/cart_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/hotel_image.dart';

class HotelScreen extends StatefulWidget {
  const HotelScreen({
    super.key,
    required this.hotel,
    required this.isFavorite,
    required this.onToggleFavorite,
  });

  final Hotel hotel;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;

  @override
  State<HotelScreen> createState() => _HotelScreenState();
}

class _HotelScreenState extends State<HotelScreen> {
  late bool _isFavorite;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.isFavorite;
  }

  void _toggleFavorite() {
    setState(() => _isFavorite = !_isFavorite);
    widget.onToggleFavorite();
  }

  void _showBookingPreview() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your stay',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.hotel.name,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${widget.hotel.city} • \$${widget.hotel.pricePerNight} per night',
                style: const TextStyle(
                  color: AppTheme.muted,
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                'Online reservations will be available soon. '
                    'For now, you can explore and save your favorite hotels.',
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  child: const Text('Got it'),
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
    final hotel = widget.hotel;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hotel details'),
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 5, 18, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SizedBox(
                  height: 260,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      HotelImage(url: hotel.imageUrl),
                      Positioned(
                        top: 14,
                        right: 14,
                        child: IconButton.filled(
                          tooltip: _isFavorite
                              ? 'Remove from favorites'
                              : 'Save hotel',
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white,
                          ),
                          onPressed: _toggleFavorite,
                          icon: Icon(
                            _isFavorite
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_border_rounded,
                            color: _isFavorite
                                ? AppTheme.teal
                                : AppTheme.navy,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 22),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      hotel.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.navy,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${hotel.pricePerNight}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.teal,
                        ),
                      ),
                      const Text(
                        'per night',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.muted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 9),

              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 18,
                    color: AppTheme.teal,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      hotel.city,
                      style: const TextStyle(
                        color: AppTheme.muted,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  const Icon(
                    Icons.star_rounded,
                    color: Color(0xFFFFB547),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${hotel.rating}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      '(${hotel.reviewCount} reviews)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.muted,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              const Text(
                'What makes it special',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.navy,
                ),
              ),

              const SizedBox(height: 10),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _featureTag(
                    hotel.category,
                    Icons.sell_outlined,
                  ),
                  ...hotel.amenities.map(
                        (amenity) => _featureTag(
                      amenity,
                      Icons.check_circle_outline,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              const Text(
                'About this hotel',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.navy,
                ),
              ),

              const SizedBox(height: 9),

              Text(
                hotel.description,
                style: const TextStyle(
                  height: 1.55,
                  color: AppTheme.muted,
                ),
              ),

              const SizedBox(height: 14),

              TextButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Back to hotels'),
              ),
            ],
          ),
        ),
      ),

      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(18, 9, 18, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Consumer<CartProvider>(
              builder: (context, cart, _) {
                final inCart = cart.containsHotel(hotel.id);

                return SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      cart.toggleHotel(hotel);
                    },
                    icon: Icon(
                      inCart
                          ? Icons.check_circle_outline
                          : Icons.add_circle_outline,
                    ),
                    label: Text(
                      inCart
                          ? 'Remove from Trip'
                          : 'Add to Trip',
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: _showBookingPreview,
                icon: const Icon(
                  Icons.calendar_month_outlined,
                ),
                label: const Text('Book now'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _featureTag(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 9,
        horizontal: 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFE9F3F1),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: AppTheme.teal,
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              color: AppTheme.teal,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
