
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/hotel.dart';
import '../providers/cart_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/hotel_gallery.dart';
import '../services/staygo_links.dart';

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

  @override
  Widget build(BuildContext context) {
    final hotel = widget.hotel;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hotel details'),
        actions: [
          IconButton(
            tooltip: 'Share hotel',
            icon: const Icon(Icons.ios_share_rounded),
            onPressed: () => showHotelShareSheet(context, widget.hotel),
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 940),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 5, 18, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 820),
                      child: Stack(
                        children: [
                          HotelGallery(hotel: hotel),
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
                                color: _isFavorite ? AppTheme.teal : AppTheme.navy,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (!hotel.isLocalListing)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Destination illustrations',
                        style: TextStyle(fontSize: 11, color: AppTheme.muted),
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
                      if (hotel.hasPrice)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '\$${hotel.pricePerNight}',
                              style: const TextStyle(
                                fontSize: 22, fontWeight: FontWeight.w900,
                                color: AppTheme.teal,
                              ),
                            ),
                            const Text('per night',
                                style: TextStyle(fontSize: 12, color: AppTheme.muted)),
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

                  if (hotel.hasRating)
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Color(0xFFFFB547)),
                        const SizedBox(width: 4),
                        Text('${hotel.rating}',
                            style: const TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text('(${hotel.reviewCount} reviews)',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AppTheme.muted)),
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
        ),
      ),

      bottomNavigationBar: !hotel.hasPrice
          ? null
          : SafeArea(
              minimum: const EdgeInsets.fromLTRB(18, 9, 18, 12),
              child: Consumer<CartProvider>(
                builder: (context, cart, _) {
                  final inCart = cart.containsHotel(hotel.id);
                  return SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: () => cart.toggleHotel(hotel),
                      icon: Icon(inCart
                          ? Icons.check_circle_outline
                          : Icons.add_circle_outline),
                      label: Text(inCart ? 'Remove from Trip' : 'Add to Trip'),
                    ),
                  );
                },
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
