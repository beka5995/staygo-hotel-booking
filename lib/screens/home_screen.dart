
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/sample_hotels.dart';
import '../database/local_auth.dart';
import '../models/hotel.dart';
import '../models/user_profile.dart';
import '../providers/cart_provider.dart';

import 'discover_screen.dart';
import 'favorites_screen.dart';
import 'hotel_screen.dart';
import 'profile_screen.dart';
import 'registration_screen.dart';
import 'trip_list_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _restoreProfile();
  }

  Future<void> _restoreProfile() async {
    try {
      final saved = await LocalAuth.instance.currentProfile();

      if (!mounted) return;

      setState(() => _profile = saved);
    } catch (e) {
      debugPrint('Session restore failed: $e');
    }
  }

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

  void _openTripList() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const TripListScreen(),
      ),
    );
  }

  Future<void> _refreshHotels() async {
    await Future<void>.delayed(
      const Duration(milliseconds: 1500),
    );

    if (!mounted) return;

    setState(() {
      _newHotelCounter++;

      final seed = sampleHotels[
      (_newHotelCounter - 1) % sampleHotels.length];

      _hotels.insert(
        0,
        seed.copyWith(
          id: 'new-$_newHotelCounter',
          name: '${seed.name} • New',
        ),
      );
    });
  }

  void _removeHotel(Hotel hotel) {
    final originalIndex = _hotels.indexWhere(
          (item) => item.id == hotel.id,
    );

    if (originalIndex < 0) return;

    setState(() {
      _hotels.removeAt(originalIndex);
    });

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('${hotel.name} removed from catalog'),
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: () {
              setState(() {
                if (!_hotels.any(
                      (item) => item.id == hotel.id,
                )) {
                  final index = originalIndex
                      .clamp(0, _hotels.length)
                      .toInt();

                  _hotels.insert(index, hotel);
                }
              });
            },
          ),
        ),
      );
  }

  void _resetCatalog() {
    setState(() {
      _hotels = List.of(sampleHotels);
      _newHotelCounter = 0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Catalog restored')),
    );
  }

  Future<void> _openAuth(bool register) async {
    final result = await Navigator.of(context).push<UserProfile>(
      MaterialPageRoute(
        builder: (_) => RegistrationScreen(
          initialRegister: register,
        ),
      ),
    );

    if (!mounted || result == null) return;

    setState(() => _profile = result);
  }

  Future<void> _signOut() async {
    try {
      await LocalAuth.instance.logout();

      if (!mounted) return;

      setState(() => _profile = null);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signed out')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not sign out')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final favoriteHotels = _hotels
        .where((hotel) => _favoriteIds.contains(hotel.id))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedTab == 0
              ? 'Explore stays'
              : _selectedTab == 1
              ? 'Saved stays'
              : 'Account',
        ),
        actions: [
          Consumer<CartProvider>(
            builder: (context, cart, _) {
              return Badge(
                isLabelVisible: cart.itemCount > 0,
                label: Text('${cart.itemCount}'),
                child: IconButton(
                  tooltip: 'Trip List',
                  onPressed: _openTripList,
                  icon: const Icon(
                    Icons.luggage_outlined,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _selectedTab,
          children: [
            DiscoverScreen(
              hotels: _hotels,
              favoriteIds: _favoriteIds,
              onHotelTap: _openHotel,
              onFavoriteTap: (hotel) =>
                  _toggleFavorite(hotel.id),
              onRefresh: _refreshHotels,
              onDismiss: _removeHotel,
              onReset: _resetCatalog,
            ),
            FavoritesScreen(
              hotels: favoriteHotels,
              onHotelTap: _openHotel,
              onFavoriteTap: (hotel) =>
                  _toggleFavorite(hotel.id),
              onExplore: () {
                setState(() => _selectedTab = 0);
              },
            ),
            ProfileScreen(
              profile: _profile,
              onRegister: () => _openAuth(true),
              onLogin: () => _openAuth(false),
              onSignOut: () => _signOut(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab,
        onDestinationSelected: (index) {
          setState(() => _selectedTab = index);
        },
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
