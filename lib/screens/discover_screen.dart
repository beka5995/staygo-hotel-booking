import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/hotel.dart';
import '../providers/cart_provider.dart';
import '../services/hotel_places_service.dart';
import '../state/hotel_store.dart';
import '../widgets/hotel_card.dart';
import '../widgets/hotel_list_tile.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({
    super.key,
    required this.store,
    required this.onHotelTap,
  });
  final HotelStore store;
  final ValueChanged<Hotel> onHotelTap;
  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  bool _showGrid = true;
  bool _refreshing = false;
  String _category = 'All';
  String _query = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    try {
      await widget.store.refresh();
      if (!mounted) return;
      _searchController.clear();
      setState(() {
        _query = '';
        _category = 'All';
      });
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  void _dismiss(Hotel hotel) {
    final index = widget.store.hotels.indexWhere((h) => h.id == hotel.id);
    if (index < 0) return;
    final revision = widget.store.revision;
    widget.store.remove(hotel);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('${hotel.name} removed'),
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: () {
              if (widget.store.revision == revision) {
                widget.store.restore(hotel, index);
              }
            },
          ),
        ),
      );
  }

  Widget _cities() => SizedBox(
    height: 46,
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: hotelCities
            .map(
              (city) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(city.name),
                  selected: widget.store.city.locationKey == city.locationKey,
                  onSelected: _refreshing
                      ? null
                      : (_) {
                          _searchController.clear();
                          setState(() {
                            _query = '';
                            _category = 'All';
                          });
                          widget.store.browseCity(city);
                        },
                ),
              ),
            )
            .toList(),
      ),
    ),
  );

  Widget _message(
    IconData icon,
    String title,
    String message,
    String action,
    VoidCallback onPressed,
  ) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 54, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 9),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.refresh),
            label: Text(action),
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    return AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) {
        final state = widget.store.state;
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1080),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: LayoutBuilder(
                builder: (context, size) {
                  if (state == HotelLoadState.initial ||
                      (state == HotelLoadState.loading &&
                          !widget.store.isRefreshing)) {
                    return Column(
                      children: [
                        _cities(),
                        const Expanded(
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 16),
                                Text('Finding your next stay…'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                  if (state == HotelLoadState.error) {
                    return Column(
                      children: [
                        _cities(),
                        Expanded(
                          child: _message(
                            Icons.wifi_off_rounded,
                            'Unable to load hotels',
                            widget.store.error ??
                                'Check your connection and try again.',
                            'Retry Connection',
                            () => widget.store.load(),
                          ),
                        ),
                      ],
                    );
                  }
                  final all = widget.store.hotels;
                  if (all.isEmpty) {
                    return _message(
                      Icons.hotel_outlined,
                      'Catalog is Empty',
                      'Find your next stay with a fresh search.',
                      'Reset Catalog',
                      () => widget.store.reset(),
                    );
                  }
                  final types = all.map((h) => h.category).toSet().toList()
                    ..sort();
                  final categories = ['All', ...types];
                  final hotels = all.where((hotel) {
                    final q = _query.trim().toLowerCase();
                    return (_category == 'All' ||
                            hotel.category == _category) &&
                        (q.isEmpty ||
                            hotel.name.toLowerCase().contains(q) ||
                            hotel.city.toLowerCase().contains(q));
                  }).toList();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (size.maxHeight >= 530)
                        Container(
                          height: size.maxWidth < 600 ? 165 : 190,
                          margin: const EdgeInsets.only(top: 8, bottom: 12),
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.asset(
                                'assets/branding/staygo_hero.png',
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => ColoredBox(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              const DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomLeft,
                                    end: Alignment.topRight,
                                    colors: [
                                      Color(0xB317334A),
                                      Color(0x0017334A),
                                    ],
                                  ),
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.all(20),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'A LITTLE FURTHER, A LITTLE FREER',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 10,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      'Find a place to unwind',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (size.maxHeight >= 160) _cities(),
                      SizedBox(
                        height: 46,
                        child: TextField(
                          controller: _searchController,
                          enabled: !_refreshing,
                          onChanged: (value) => setState(() => _query = value),
                          decoration: const InputDecoration(
                            hintText: 'Search hotels or destinations',
                            isDense: true,
                            prefixIcon: Icon(Icons.search),
                          ),
                        ),
                      ),
                      if (size.maxHeight >= 360)
                        SizedBox(
                          height: 45,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: categories
                                  .map(
                                    (category) => Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: ChoiceChip(
                                        label: Text(category),
                                        selected: _category == category,
                                        onSelected: _refreshing
                                            ? null
                                            : (_) => setState(
                                                () => _category = category,
                                              ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ),
                      if (size.maxHeight >= 160)
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Places to stay (${hotels.length})',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Refresh hotels',
                              onPressed: _refreshing ? null : _refresh,
                              icon: const Icon(Icons.refresh_rounded),
                            ),
                            IconButton(
                              tooltip: 'List view',
                              onPressed: _refreshing
                                  ? null
                                  : () => setState(() => _showGrid = false),
                              icon: Icon(
                                Icons.view_list_rounded,
                                color: !_showGrid
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Grid view',
                              onPressed: _refreshing
                                  ? null
                                  : () => setState(() => _showGrid = true),
                              icon: Icon(
                                Icons.grid_view_rounded,
                                color: _showGrid
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      Expanded(
                        key: const ValueKey('hotel-catalog-body'),
                        child: hotels.isEmpty
                            ? RefreshIndicator(
                                onRefresh: _refresh,
                                child: ListView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.all(20),
                                      child: Text(
                                        'No stays match your search.',
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() {
                                          _category = 'All';
                                          _query = '';
                                        });
                                      },
                                      child: const Text('Clear filters'),
                                    ),
                                  ],
                                ),
                              )
                            : _showGrid
                            ? _grid(hotels, cart)
                            : _list(hotels, cart),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _tripButton(Hotel hotel, CartProvider cart) => SizedBox(
    width: double.infinity,
    height: 34,
    child: TextButton.icon(
      onPressed: () => cart.toggleHotel(hotel),
      icon: Icon(
        cart.containsHotel(hotel.id)
            ? Icons.check_circle_outline
            : Icons.add_circle_outline,
        size: 17,
      ),
      label: Text(
        cart.containsHotel(hotel.id) ? 'Remove from Trip' : 'Add to Trip',
        maxLines: 1,
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        textStyle: const TextStyle(fontSize: 11),
      ),
    ),
  );

  Widget _grid(List<Hotel> hotels, CartProvider cart) => RefreshIndicator(
    onRefresh: _refresh,
    triggerMode: RefreshIndicatorTriggerMode.anywhere,
    child: GridView.builder(
      key: const PageStorageKey('hotel-grid'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 18),
      itemCount: hotels.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
        final hotel = hotels[index];
        return Column(
          children: [
            Expanded(
              child: HotelCard(
                key: ValueKey(hotel.id),
                hotel: hotel,
                isPriceLoading: widget.store.isRateLoading(hotel.id),
                isFavorite: widget.store.isFavorite(hotel.id),
                onTap: () => widget.onHotelTap(hotel),
                onFavorite: () => widget.store.toggleFavorite(hotel),
              ),
            ),
            _tripButton(hotel, cart),
          ],
        );
      },
    ),
  );

  Widget _list(List<Hotel> hotels, CartProvider cart) => RefreshIndicator(
    onRefresh: _refresh,
    triggerMode: RefreshIndicatorTriggerMode.anywhere,
    child: ListView.separated(
      key: const PageStorageKey('hotel-list'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 18),
      itemCount: hotels.length,
      separatorBuilder: (_, _) => const Divider(height: 12),
      itemBuilder: (context, index) {
        final hotel = hotels[index];
        return Dismissible(
          key: ValueKey(hotel.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            color: Colors.redAccent,
            padding: const EdgeInsets.only(right: 24),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) => _dismiss(hotel),
          child: Column(
            children: [
              HotelListTile(
                hotel: hotel,
                isPriceLoading: widget.store.isRateLoading(hotel.id),
                isFavorite: widget.store.isFavorite(hotel.id),
                onTap: () => widget.onHotelTap(hotel),
                onFavorite: () => widget.store.toggleFavorite(hotel),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: SizedBox(width: 170, child: _tripButton(hotel, cart)),
              ),
            ],
          ),
        );
      },
    ),
  );
}
