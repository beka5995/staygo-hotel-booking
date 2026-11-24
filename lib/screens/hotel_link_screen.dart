import 'package:flutter/material.dart';

import '../models/hotel.dart';
import '../state/hotel_store.dart';
import 'hotel_screen.dart';

class HotelLinkScreen extends StatefulWidget {
  const HotelLinkScreen({
    super.key,
    required this.hotelId,
    required this.store,
  });
  final String hotelId;
  final HotelStore store;
  @override
  State<HotelLinkScreen> createState() => _HotelLinkScreenState();
}

class _HotelLinkScreenState extends State<HotelLinkScreen> {
  late Future<Hotel> _hotel;
  @override
  void initState() {
    super.initState();
    _hotel = widget.store.findById(widget.hotelId);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Hotel>(
    future: _hotel,
    builder: (context, snapshot) {
      if (snapshot.hasData) {
        final hotel = snapshot.data!;
        return HotelScreen(
          hotel: hotel,
          store: widget.store,
          isFavorite: widget.store.isFavorite(hotel.id),
          onToggleFavorite: () => widget.store.toggleFavorite(hotel),
        );
      }
      return Scaffold(
        appBar: AppBar(title: const Text('Hotel details')),
        body: Center(
          child: snapshot.hasError
              ? SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wifi_off_rounded, size: 48),
                      const SizedBox(height: 12),
                      Text('${snapshot.error}', textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => setState(
                          () => _hotel = widget.store.findById(widget.hotelId),
                        ),
                        child: const Text('Retry Connection'),
                      ),
                    ],
                  ),
                )
              : const CircularProgressIndicator(),
        ),
      );
    },
  );
}
