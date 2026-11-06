
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/sample_hotels.dart';
import '../database/local_auth.dart';
import '../models/hotel.dart';
import '../models/user_profile.dart';
import '../providers/cart_provider.dart';
import '../services/hotel_places_service.dart';

import 'discover_screen.dart';
import 'favorites_screen.dart';
import 'hotel_screen.dart';
import 'profile_screen.dart';
import 'registration_screen.dart';
import 'trip_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.initialHotelId});

  final String? initialHotelId;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTab = 0;
  int _newHotelCounter = 0;

  List<Hotel> _hotels = List.of(sampleHotels);
  final Set<String> _favoriteIds = {};
  final HotelPlacesService _placesService = HotelPlacesService();
  final Map<String, Hotel> _knownHotels = {};
  List<Hotel> _liveHotels = [];
  final Map<String, List<Hotel>> _cityCache = {};
  final Map<String, DateTime> _cityCacheTime = {};
  bool _onlineMode = false;
  bool _onlineLoading = false;
  String? _onlineError;
  HotelCity _selectedCity = hotelCities.first;
  int _searchToken = 0;

  UserProfile? _profile;

  @override
  void initState() {
    super.initState();
    _restoreProfile();
    if (widget.initialHotelId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        for (final hotel in sampleHotels) {
          if (hotel.id == widget.initialHotelId) {
            _openHotel(hotel);
            return;
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _placesService.dispose();
    super.dispose();
  }

  List<Hotel> _featuredForCity(HotelCity city) {
    final name = city.name.toLowerCase();
    return _hotels.where((hotel) {
      return hotel.city.toLowerCase().contains(name);
    }).toList();
  }

  List<Hotel> get _displayedHotels {
    if (!_onlineMode) return _hotels;
    final result = _featuredForCity(_selectedCity);
    final names = result.map((hotel) => hotel.name.toLowerCase().trim()).toSet();
    for (final hotel in _liveHotels) {
      if (names.add(hotel.name.toLowerCase().trim())) result.add(hotel);
    }
    return result;
  }

  void _showFeatured() {
    ++_searchToken;
    setState(() {
      _onlineMode = false;
      _onlineLoading = false;
      _onlineError = null;
    });
  }

  Future<void> _browseCity(HotelCity city, {bool force = false}) async {
    final cached = _cityCache[city.name];
    final refreshedAt = _cityCacheTime[city.name];
    final isFresh = refreshedAt != null &&
        DateTime.now().difference(refreshedAt) < const Duration(minutes: 5);
    if (!force && _onlineMode && _selectedCity.name == city.name &&
        _onlineLoading) {
      return;
    }

    final token = ++_searchToken;
    setState(() {
      _onlineMode = true;
      _selectedCity = city;
      _onlineLoading = cached == null || force || !isFresh;
      _onlineError = null;
      _liveHotels = cached == null ? [] : List.of(cached);
    });
    if (!force && isFresh && cached != null) return;

    try {
      final hotels = await _placesService.findHotels(city);
      if (!mounted || token != _searchToken) return;
      setState(() {
        _liveHotels = hotels;
        _cityCache[city.name] = List.of(hotels);
        _cityCacheTime[city.name] = DateTime.now();
        _knownHotels.addEntries(hotels.map((h) => MapEntry(h.id, h)));
        _onlineLoading = false;
      });
    } on HotelPlacesException catch (error) {
      if (!mounted || token != _searchToken) return;
      setState(() {
        _onlineError = error.message;
        _onlineLoading = false;
      });
    }
  }

  Future<void> _reloadCity() => _browseCity(_selectedCity, force: true);

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
    final currentHotels = _onlineMode && _liveHotels.any((item) => item.id == hotel.id)
        ? _liveHotels
        : _hotels;
    final originalIndex = currentHotels.indexWhere(
          (item) => item.id == hotel.id,
    );

    if (originalIndex < 0) return;

    setState(() {
      currentHotels.removeAt(originalIndex);
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
                if (!currentHotels.any(
                      (item) => item.id == hotel.id,
                )) {
                  final index = originalIndex
                      .clamp(0, currentHotels.length)
                      .toInt();

                  currentHotels.insert(index, hotel);
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
    final favoriteHotels = <String, Hotel>{
      for (final hotel in _hotels) hotel.id: hotel,
      ..._knownHotels,
    }.values.where((hotel) => _favoriteIds.contains(hotel.id)).toList();

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
              hotels: _displayedHotels,
              onlineMode: _onlineMode,
              onlineLoading: _onlineLoading,
              onlineError: _onlineError,
              selectedCity: _selectedCity,
              onBrowseCity: _browseCity,
              onShowFeatured: _showFeatured,
              favoriteIds: _favoriteIds,
              onHotelTap: _openHotel,
              onFavoriteTap: (hotel) =>
                  _toggleFavorite(hotel.id),
              onRefresh: _onlineMode
                  ? _reloadCity
                  : _refreshHotels,
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
