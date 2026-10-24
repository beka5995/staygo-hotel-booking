import 'package:flutter/material.dart';
import '../data/sample_hotels.dart';
import '../models/hotel.dart';
import '../models/user_profile.dart';
import 'discover_screen.dart';
import 'favorites_screen.dart';
import 'hotel_screen.dart';
import 'profile_screen.dart';
import 'registration_screen.dart';

// The tab shell owns catalog and favorites so changing screens keeps their state.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTab = 0;
  int _newHotelCounter = 0;
  List<Hotel> _hotels = List.of(sampleHotels);
  final Set<String> _favoriteIds = {};
  UserProfile? _profile;

  void _toggleFavorite(String id) {
    setState(() {
      if (!_favoriteIds.add(id)) {
        _favoriteIds.remove(id);
      }
    });
  }

  void _openHotel(Hotel hotel) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HotelScreen(
          hotel: hotel,
          isFavorite: _favoriteIds.contains(hotel.id),
          onToggleFavorite: () => _toggleFavorite(hotel.id),
        ),
      ),
    );
  }

  Future<void> _refreshHotels() async {
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    setState(() {
      _newHotelCounter++;
      final seed = sampleHotels[(_newHotelCounter - 1) % sampleHotels.length];
      _hotels.insert(
        0,
        seed.copyWith(id: 'new-$_newHotelCounter', name: '${seed.name} • New'),
      );
    });
  }

  void _removeHotel(Hotel hotel) {
    final originalIndex = _hotels.indexWhere((item) => item.id == hotel.id);
    if (originalIndex < 0) return;
    setState(() => _hotels.removeAt(originalIndex));
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('${hotel.name} removed from catalog'),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () {
            setState(() {
              if (!_hotels.any((item) => item.id == hotel.id)) {
                final index = originalIndex.clamp(0, _hotels.length).toInt();
                _hotels.insert(index, hotel);
              }
            });
          },
        ),
      ),
    );
  }

  void _resetCatalog() {
    setState(() => _hotels = List.of(sampleHotels));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Catalog restored')),
    );
  }

  Future<void> _openRegistration() async {
    final profile = await Navigator.of(context).push<UserProfile>(
      MaterialPageRoute(builder: (_) => const RegistrationScreen()),
    );
    if (!mounted || profile == null) return;
    setState(() => _profile = profile);
  }

  @override
  Widget build(BuildContext context) {
    final favoriteHotels = _hotels
        .where((hotel) => _favoriteIds.contains(hotel.id))
        .toList();

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _selectedTab,
          children: [
            DiscoverScreen(
              hotels: _hotels,
              favoriteIds: _favoriteIds,
              onHotelTap: _openHotel,
              onFavoriteTap: (hotel) => _toggleFavorite(hotel.id),
              onRefresh: _refreshHotels,
              onDismiss: _removeHotel,
              onReset: _resetCatalog,
            ),
            FavoritesScreen(
              hotels: favoriteHotels,
              onHotelTap: _openHotel,
              onFavoriteTap: (hotel) => _toggleFavorite(hotel.id),
              onExplore: () => setState(() => _selectedTab = 0),
            ),
            ProfileScreen(profile: _profile, onRegister: _openRegistration),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab,
        onDestinationSelected: (index) => setState(() => _selectedTab = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore_rounded),
            label: 'Explore',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border_rounded),
            selectedIcon: Icon(Icons.favorite_rounded),
            label: 'Favorites',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
