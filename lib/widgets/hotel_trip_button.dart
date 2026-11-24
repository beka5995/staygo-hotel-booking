import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/hotel.dart';
import '../state/cart_bloc.dart';

class HotelTripButton extends StatelessWidget {
  const HotelTripButton({
    super.key,
    required this.hotel,
    required this.inTrip,
    this.onAdded,
  });

  final Hotel hotel;
  final bool inTrip;
  final VoidCallback? onAdded;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 34,
    child: TextButton.icon(
      onPressed: () {
        context.read<CartBloc>().add(
          inTrip ? RemoveProductEvent(hotel.id) : AddProductEvent(hotel),
        );
        if (!inTrip) onAdded?.call();
      },
      icon: Icon(
        inTrip ? Icons.check_circle_outline : Icons.add_circle_outline,
        size: 17,
      ),
      label: Text(inTrip ? 'Remove from Trip' : 'Add to Trip', maxLines: 1),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        textStyle: const TextStyle(fontSize: 11),
      ),
    ),
  );
}
