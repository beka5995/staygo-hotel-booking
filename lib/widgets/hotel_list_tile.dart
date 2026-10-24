import 'package:flutter/material.dart';
import '../models/hotel.dart';
import '../theme/app_theme.dart';
import 'hotel_image.dart';

class HotelListTile extends StatelessWidget {
  const HotelListTile({
    super.key,
    required this.hotel,
    required this.isFavorite,
    required this.onTap,
    required this.onFavorite,
  });

  final Hotel hotel;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: HotelImage(url: hotel.imageUrl, width: 94, height: 98),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(hotel.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text('${hotel.category} • ${hotel.city}', maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Color(0xFFFFB547), size: 17),
                        Text(' ${hotel.rating}', style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text('\$${hotel.pricePerNight} / night',
                        style: const TextStyle(color: AppTheme.teal, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              IconButton(
                tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
                onPressed: onFavorite,
                icon: Icon(isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: isFavorite ? Colors.redAccent : AppTheme.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
