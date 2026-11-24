import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/hotel.dart';
import '../state/cart_bloc.dart';
import 'hotel_list_tile.dart';
import 'hotel_trip_button.dart';

class HotelResultTile extends StatelessWidget {
  const HotelResultTile({
    super.key,
    required this.hotel,
    required this.isFavorite,
    this.isPriceLoading = false,
    required this.onTap,
    required this.onFavorite,
    this.onTripAdd,
  });

  final Hotel hotel;
  final bool isFavorite;
  final bool isPriceLoading;
  final VoidCallback onTap;
  final VoidCallback onFavorite;
  final VoidCallback? onTripAdd;

  @override
  Widget build(BuildContext context) {
    final inTrip = context.select(
      (CartBloc bloc) => bloc.state.containsHotel(hotel.id),
    );
    return Column(
      children: [
        HotelListTile(
          hotel: hotel,
          isFavorite: isFavorite,
          isPriceLoading: isPriceLoading,
          onTap: onTap,
          onFavorite: onFavorite,
        ),
        Align(
          alignment: Alignment.centerRight,
          child: SizedBox(
            width: 170,
            child: HotelTripButton(
              hotel: hotel,
              inTrip: inTrip,
              onAdded: onTripAdd,
            ),
          ),
        ),
      ],
    );
  }
}
