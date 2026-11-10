import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../database/local_auth.dart';
import '../models/hotel.dart';
import '../models/user_profile.dart';
import '../providers/cart_provider.dart';
import '../state/hotel_store.dart';
import 'discover_screen.dart';
import 'favorites_screen.dart';
import 'hotel_screen.dart';
import 'hotel_link_screen.dart';
import 'profile_screen.dart';
import 'registration_screen.dart';
import 'trip_list_screen.dart';
import 'notes_screen.dart';
import '../state/preferences_store.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.store,
    this.initialHotelId,
    this.enablePlatformServices = true,
  });
  final HotelStore? store;
  final String? initialHotelId;
  final bool enablePlatformServices;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late final HotelStore _store;
  UserProfile? _profile;
  int _selectedTab = 0;
  StreamSubscription<List<ConnectivityResult>>? _network;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _store = widget.store ?? HotelStore();
    _store.load();
    if (widget.enablePlatformServices) {
      WidgetsBinding.instance.addObserver(this);
      _restoreProfile();
      _watchNetwork();
      _startTimer();
    }
    if (widget.initialHotelId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => HotelLinkScreen(
                hotelId: widget.initialHotelId!,
                store: _store,
              ),
            ),
          );
        }
      });
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (mounted) _store.verifyConnection();
    });
  }

  void _applyNetwork(List<ConnectivityResult> result) {
    if (mounted) {
      _store.setNetworkAvailable(
        result.any((r) => r != ConnectivityResult.none),
      );
    }
  }

  Future<void> _checkNetwork() async {
    try {
      _applyNetwork(await Connectivity().checkConnectivity());
    } catch (error) {
      debugPrint('Network status unavailable: $error');
    }
  }

  Future<void> _watchNetwork() async {
    try {
      _network = Connectivity().onConnectivityChanged.listen(
        _applyNetwork,
        onError: (Object e) => debugPrint('Network status: $e'),
      );
      await _checkNetwork();
    } catch (error) {
      debugPrint('Network monitoring unavailable: $error');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkNetwork();
      _store.verifyConnection();
      _startTimer();
    } else {
      _timer?.cancel();
    }
  }

  Future<void> _restoreProfile() async {
    try {
      final profile = await LocalAuth.instance.currentProfile();
      if (mounted) setState(() => _profile = profile);
    } catch (error) {
      debugPrint('Session restore failed: $error');
    }
  }

  void _openHotel(Hotel hotel) => Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) => HotelScreen(
        hotel: hotel,
        store: _store,
        isFavorite: _store.isFavorite(hotel.id),
        onToggleFavorite: () => _store.toggleFavorite(hotel),
      ),
    ),
  );

  Future<void> _openAuth(bool register) async {
    final profile = await Navigator.push<UserProfile>(
      context,
      MaterialPageRoute<UserProfile>(
        builder: (_) => RegistrationScreen(initialRegister: register),
      ),
    );
    if (!mounted || profile == null) return;
    setState(() => _profile = profile);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Welcome to StayGo!')));
  }

  Future<void> _signOut() async {
    try {
      await LocalAuth.instance.logout();
      if (mounted) setState(() => _profile = null);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not sign out. Try again.')),
        );
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _network?.cancel();
    _timer?.cancel();
    if (widget.store == null) _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _selectedTab == 0
                ? 'StayGo'
                : _selectedTab == 1
                ? 'Saved stays'
                : 'Account',
          ),
          Text(
            context.watch<PreferencesStore>().displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Notes',
          icon: const Icon(Icons.edit_note_rounded),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => Scaffold(
                appBar: AppBar(title: const Text('Notes')),
                body: const NotesScreen(),
              ),
            ),
          ),
        ),

        Consumer<CartProvider>(
          builder: (context, cart, _) => Badge(
            isLabelVisible: cart.itemCount > 0,
            label: Text('${cart.itemCount}'),
            child: IconButton(
              tooltip: 'Trip List',
              icon: const Icon(Icons.luggage_outlined),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(builder: (_) => const TripListScreen()),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
      ],
    ),
    body: SafeArea(
      child: IndexedStack(
        index: _selectedTab,
        children: [
          HeroMode(
            enabled: _selectedTab == 0,
            child: DiscoverScreen(store: _store, onHotelTap: _openHotel),
          ),
          HeroMode(
            enabled: _selectedTab == 1,
            child: AnimatedBuilder(
              animation: _store,
              builder: (context, _) => FavoritesScreen(
                hotels: _store.favorites,
                onHotelTap: _openHotel,
                onFavoriteTap: _store.toggleFavorite,
                onExplore: () => setState(() => _selectedTab = 0),
              ),
            ),
          ),
          ProfileScreen(
            profile: _profile,
            onRegister: () => _openAuth(true),
            onLogin: () => _openAuth(false),
            onSignOut: _signOut,
          ),
        ],
      ),
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: _selectedTab,
      onDestinationSelected: (i) => setState(() => _selectedTab = i),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.explore_outlined),
          label: 'Explore',
        ),
        NavigationDestination(
          icon: Icon(Icons.favorite_border),
          label: 'Favorites',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          label: 'Profile',
        ),
      ],
    ),
  );
}
