import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/hotel.dart';
import '../state/cart_bloc.dart';
import '../state/hotel_store.dart';

class AddHotelSheet extends StatefulWidget {
  const AddHotelSheet({super.key, required this.hotels, required this.store});

  final List<Hotel> hotels;
  final HotelStore store;

  @override
  State<AddHotelSheet> createState() => _AddHotelSheetState();
}

class _AddHotelSheetState extends State<AddHotelSheet> {
  late Hotel _hotel = widget.hotels.first;
  bool _trip = true;
  bool _favorite = false;

  void _apply() {
    final store = widget.store;
    final hotel = store.knownHotel(_hotel.id) ?? _hotel;
    if (_trip) {
      context.read<CartBloc>().add(AddProductEvent(hotel));
      store.loadRateIfNeeded(hotel);
    }
    if (_favorite) store.saveFavorite(hotel);
    final destination = _trip && _favorite
        ? 'Trip List and Favorites'
        : _trip
        ? 'Trip List'
        : 'Favorites';
    Navigator.pop(context, '${hotel.name} saved to $destination');
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Add a stay', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          if (widget.hotels.isEmpty)
            const Text('Hotels are unavailable right now.')
          else ...[
            DropdownButtonFormField<Hotel>(
              initialValue: _hotel,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Hotel'),
              items: [
                for (final hotel in widget.hotels)
                  DropdownMenuItem(
                    value: hotel,
                    child: Text(hotel.name, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (hotel) {
                if (hotel != null) setState(() => _hotel = hotel);
              },
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _trip,
              onChanged: (value) => setState(() => _trip = value ?? false),
              title: const Text('Add to Trip List'),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _favorite,
              onChanged: (value) => setState(() => _favorite = value ?? false),
              title: const Text('Save to Favorites'),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            FilledButton(
              onPressed: _trip || _favorite ? _apply : null,
              child: const Text('Add selected'),
            ),
          ],
        ],
      ),
    ),
  );
}
