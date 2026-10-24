import 'package:flutter/material.dart';
import '../models/hotel.dart';
import '../theme/app_theme.dart';
import '../widgets/hotel_list_tile.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({
    super.key,
    required this.hotels,
    required this.onHotelTap,
    required this.onFavoriteTap,
    required this.onExplore,
  });

  final List<Hotel> hotels;
  final ValueChanged<Hotel> onHotelTap;
  final ValueChanged<Hotel> onFavoriteTap;
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 22, 20, 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your favorites', style: TextStyle(fontSize: 25,
                  fontWeight: FontWeight.w800, color: AppTheme.navy)),
              SizedBox(height: 5),
              Text('Hotels you want to come back to',
                  style: TextStyle(color: AppTheme.muted)),
            ],
          ),
        ),
        Expanded(
          child: hotels.isEmpty
              ? Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.favorite_border_rounded,
                            size: 67, color: AppTheme.muted),
                        const SizedBox(height: 12),
                        const Text('No favorites yet',
                            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 7),
                        const Text('Tap the heart on a hotel to save it here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppTheme.muted)),
                        const SizedBox(height: 17),
                        FilledButton(onPressed: onExplore, child: const Text('Explore hotels')),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                  itemCount: hotels.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final hotel = hotels[index];
                    return HotelListTile(
                      key: ValueKey(hotel.id),
                      hotel: hotel,
                      isFavorite: true,
                      onTap: () => onHotelTap(hotel),
                      onFavorite: () => onFavoriteTap(hotel),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
