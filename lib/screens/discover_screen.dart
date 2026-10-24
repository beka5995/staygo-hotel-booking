import 'package:flutter/material.dart';
import '../models/hotel.dart';
import '../theme/app_theme.dart';
import '../widgets/hotel_card.dart';
import '../widgets/hotel_list_tile.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({
    super.key,
    required this.hotels,
    required this.favoriteIds,
    required this.onHotelTap,
    required this.onFavoriteTap,
    required this.onRefresh,
    required this.onDismiss,
    required this.onReset,
  });

  final List<Hotel> hotels;
  final Set<String> favoriteIds;
  final ValueChanged<Hotel> onHotelTap;
  final ValueChanged<Hotel> onFavoriteTap;
  final Future<void> Function() onRefresh;
  final ValueChanged<Hotel> onDismiss;
  final VoidCallback onReset;

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  bool _showGrid = true;
  String _category = 'All';
  String _query = '';
  final TextEditingController _searchController = TextEditingController();

  static const categories = ['All', 'Beach', 'Resort', 'City', 'Nature'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Hotel> get _visibleHotels => widget.hotels.where((hotel) {
        final categoryMatch = _category == 'All' || hotel.category == _category;
        final q = _query.trim().toLowerCase();
        final searchMatch = q.isEmpty ||
            hotel.name.toLowerCase().contains(q) ||
            hotel.city.toLowerCase().contains(q);
        return categoryMatch && searchMatch;
      }).toList();

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _query = '';
      _category = 'All';
    });
  }

  @override
  Widget build(BuildContext context) {
    final hotels = _visibleHotels;
    final noCatalog = widget.hotels.isEmpty;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.hotel_class_rounded, color: AppTheme.teal, size: 26),
                  const SizedBox(width: 6),
                  const Text('StayGo', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900,
                      color: AppTheme.navy, letterSpacing: -0.6)),
                  const Spacer(),
                  const Icon(Icons.location_on_outlined, size: 17, color: AppTheme.teal),
                  const SizedBox(width: 3),
                  const Flexible(
                    child: Text('Explore the world', maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: AppTheme.muted, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              const Text('Find your next stay',
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800, color: AppTheme.navy)),
              const SizedBox(height: 4),
              const Text('Great places, good memories.',
                  style: TextStyle(color: AppTheme.muted, fontSize: 13)),
              const SizedBox(height: 15),
              TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  hintText: 'Search hotels or destinations',
                  prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.teal),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(onPressed: _clearFilters,
                          tooltip: 'Clear search', icon: const Icon(Icons.close_rounded))
                      : null,
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
        SizedBox(
          height: 37,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final item = categories[index];
              final selected = item == _category;
              return ChoiceChip(
                label: Text(item),
                selected: selected,
                showCheckmark: false,
                onSelected: (_) => setState(() => _category = item),
                selectedColor: const Color(0xFFDCF1EE),
                labelStyle: TextStyle(
                  color: selected ? AppTheme.teal : AppTheme.muted,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 12,
                ),
                side: BorderSide(color: selected ? AppTheme.teal : const Color(0xFFE0E7E9)),
                padding: const EdgeInsets.symmetric(horizontal: 3),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 5),
          child: Row(
            children: [
              Expanded(
                child: Text('Places to stay (${hotels.length})',
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
                        color: AppTheme.navy)),
              ),
              IconButton(
                tooltip: 'List view',
                onPressed: () => setState(() => _showGrid = false),
                icon: Icon(Icons.view_list_rounded,
                    color: _showGrid ? AppTheme.muted : AppTheme.teal),
              ),
              IconButton(
                tooltip: 'Grid view',
                onPressed: () => setState(() => _showGrid = true),
                icon: Icon(Icons.grid_view_rounded,
                    color: _showGrid ? AppTheme.teal : AppTheme.muted),
              ),
            ],
          ),
        ),
        Expanded(
          child: noCatalog
              ? _buildEmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: 'Catalog is Empty',
                  message: 'All hotels have been removed.',
                  button: 'Reset Catalog',
                  onPressed: widget.onReset,
                )
              : hotels.isEmpty
                  ? _buildEmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'No hotels found',
                      message: 'Try another name or category.',
                      button: 'Clear filters',
                      onPressed: _clearFilters,
                    )
                  : _showGrid ? _buildGrid(hotels) : _buildList(hotels),
        ),
      ],
    );
  }

  Widget _buildGrid(List<Hotel> hotels) {
    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 7, 16, 20),
        itemCount: hotels.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.72,
        ),
        itemBuilder: (context, index) {
          final hotel = hotels[index];
          return HotelCard(
            key: ValueKey(hotel.id),
            hotel: hotel,
            isFavorite: widget.favoriteIds.contains(hotel.id),
            onTap: () => widget.onHotelTap(hotel),
            onFavorite: () => widget.onFavoriteTap(hotel),
          );
        },
      ),
    );
  }

  Widget _buildList(List<Hotel> hotels) {
    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
        itemCount: hotels.length,
        separatorBuilder: (_, _) => const Divider(color: Color(0xFFE3EAEC), height: 12),
        itemBuilder: (context, index) {
          final hotel = hotels[index];
          return Dismissible(
            key: ValueKey(hotel.id),
            direction: DismissDirection.endToStart,
            background: Container(
              decoration: BoxDecoration(color: const Color(0xFFC83F47),
                  borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.only(right: 24),
              alignment: Alignment.centerRight,
              child: const Icon(Icons.delete_rounded, color: Colors.white, size: 28),
            ),
            onDismissed: (_) => widget.onDismiss(hotel),
            child: HotelListTile(
              hotel: hotel,
              isFavorite: widget.favoriteIds.contains(hotel.id),
              onTap: () => widget.onHotelTap(hotel),
              onFavorite: () => widget.onFavoriteTap(hotel),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
    required String button,
    required VoidCallback onPressed,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: AppTheme.muted),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontSize: 20,
                fontWeight: FontWeight.w800, color: AppTheme.navy)),
            const SizedBox(height: 6),
            Text(message, textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.muted)),
            const SizedBox(height: 18),
            FilledButton(onPressed: onPressed, child: Text(button)),
          ],
        ),
      ),
    );
  }
}
