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
    final date = hotel.rateDate?.toIso8601String().substring(0, 10);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hotel details'),
        actions: [
          IconButton(
            tooltip: 'Share hotel',
            icon: const Icon(Icons.ios_share_rounded),
            onPressed: () => showHotelShareSheet(context, hotel),
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
                  Stack(
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
                  const SizedBox(height: 22),
                  Text(
                    hotel.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.navy,
                    ),
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
                          style: const TextStyle(color: AppTheme.muted),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 16,
                    runSpacing: 10,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        hotel.hasPrice
                            ? '${hotel.priceLabel} / night'
                            : hotel.priceLabel,
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.teal,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Color(0xFFFFB547),
                            size: 20,
                          ),
                          Text(
                            hotel.hasRating
                                ? ' ${hotel.rating.toStringAsFixed(1)}${hotel.reviewCount > 0 ? ' (${hotel.reviewCount} reviews)' : ''}'
                                : ' No ratings yet',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    date == null
                        ? 'Rates are not available for this stay yet. You can still add it to your trip.'
                        : 'Indicative USD rate for one night on $date. Your trip budget is an estimate; final rates depend on dates and availability.',
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: AppTheme.muted,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'What makes it special',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _tag(hotel.category),
                      ...hotel.amenities.map(_tag),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'About this hotel',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    hotel.description,
                    style: const TextStyle(height: 1.55, color: AppTheme.muted),
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
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(18, 9, 18, 12),
        child: Consumer<CartProvider>(
          builder: (context, cart, _) => Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: () => cart.toggleHotel(hotel),
                    icon: Icon(
                      cart.containsHotel(hotel.id)
                          ? Icons.check_circle_outline
                          : Icons.add_circle_outline,
                    ),
                    label: Text(
                      cart.containsHotel(hotel.id)
                          ? 'Remove from Trip'
                          : 'Add to Trip',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tag(String text) => Chip(
    label: Text(text, softWrap: true),
    avatar: const Icon(
      Icons.check_circle_outline,
      size: 16,
      color: AppTheme.teal,
    ),
    backgroundColor: const Color(0xFFE9F3F1),
    side: BorderSide.none,
  );
}
