import 'package:flutter/material.dart';

import '../models/hotel.dart';
import '../services/hotel_places_service.dart';
import '../services/staygo_links.dart';
import '../state/hotel_store.dart';
import '../widgets/hotel_result_tile.dart';
import 'hotel_link_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({
    super.key,
    required this.store,
    required this.onHotelTap,
  });

  final HotelStore store;
  final ValueChanged<Hotel> onHotelTap;

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  String _query = '';
  String? _linkError;

  void _submit(String input) {
    final query = input.trim();
    final id = hotelIdFromSearch(query);
    if (id != null) {
      FocusScope.of(context).unfocus();
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => HotelLinkScreen(hotelId: id, store: widget.store),
        ),
      );
    } else if (query.contains('://') || query.startsWith('/hotel/')) {
      setState(() => _linkError = 'Paste a hotel link copied from StayGo.');
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.store,
    builder: (context, _) {
      final store = widget.store;
      final id = hotelIdFromSearch(_query);
      final query = _query.trim().toLowerCase();
      final matches = store.availableHotels
          .where((hotel) => hotel.name.toLowerCase().contains(query))
          .toList();

      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                child: TextField(
                  textInputAction: TextInputAction.search,
                  onSubmitted: _submit,
                  onChanged: (value) => setState(() {
                    _query = value;
                    _linkError = null;
                  }),
                  decoration: InputDecoration(
                    labelText: 'Name or hotel link',
                    prefixIcon: const Icon(Icons.search),
                    errorText: _linkError,
                  ),
                ),
              ),
              Expanded(
                child: CustomScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  slivers: [
                    if (id != null)
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                        sliver: SliverToBoxAdapter(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: FilledButton.icon(
                              onPressed: () => _submit(_query),
                              icon: const Icon(Icons.link),
                              label: const Text('Open hotel'),
                            ),
                          ),
                        ),
                      )
                    else ...[
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                        sliver: SliverToBoxAdapter(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: DropdownButton<HotelCity>(
                              value: store.city,
                              items: [
                                for (final city in hotelCities)
                                  DropdownMenuItem(
                                    value: city,
                                    child: Text(city.name),
                                  ),
                              ],
                              onChanged: (city) {
                                if (city != null) store.browseCity(city);
                              },
                            ),
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        sliver: _results(store, matches),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );

  Widget _results(HotelStore store, List<Hotel> matches) {
    if (store.state == HotelLoadState.initial ||
        (store.state == HotelLoadState.loading && !store.isRefreshing)) {
      return const SliverToBoxAdapter(
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (store.state == HotelLoadState.error) {
      return SliverToBoxAdapter(
        child: Column(
          children: [
            Text(
              store.error ?? 'Unable to load hotels',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: store.load,
              child: const Text('Retry Connection'),
            ),
          ],
        ),
      );
    }
    if (matches.isEmpty) {
      return const SliverToBoxAdapter(
        child: Center(child: Text('No matching hotels')),
      );
    }
    return SliverList.separated(
      itemCount: matches.length,
      separatorBuilder: (_, _) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final hotel = matches[index];
        return HotelResultTile(
          key: ValueKey(hotel.id),
          hotel: hotel,
          isPriceLoading: store.isRateLoading(hotel.id),
          isFavorite: store.isFavorite(hotel.id),
          onFavorite: () => store.toggleFavorite(hotel),
          onTap: () => widget.onHotelTap(hotel),
          onTripAdd: () => store.loadRateIfNeeded(hotel),
        );
      },
    );
  }
}
