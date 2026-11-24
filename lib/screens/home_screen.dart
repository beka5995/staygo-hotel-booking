import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../database/local_auth.dart';
import '../models/hotel.dart';
import '../models/user_profile.dart';
import '../state/cart_bloc.dart';
import '../state/hotel_store.dart';
import '../state/photo_journal_store.dart';
import '../state/preferences_store.dart';
import 'add_hotel_sheet.dart';
import 'discover_screen.dart';
import 'explore_screen.dart';
import 'favorites_screen.dart';
import 'hotel_screen.dart';
import 'hotel_link_screen.dart';
import 'profile_screen.dart';
import 'registration_screen.dart';
import 'trip_list_screen.dart';
import 'notes_screen.dart';
import 'photo_journal_screen.dart';

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
  bool _journalVisited = false;
  final _journal = PhotoJournalStore();
  static const _titles = [
    'StayGo',
    'Explore',
    '',
    'Photo Journal',
    'My profile',
  ];
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

  void _openHotel(Hotel hotel) {
    _store.loadRateIfNeeded(hotel);
    Navigator.push(
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
  }

  void _select(int index) {
    FocusScope.of(context).unfocus();
    setState(() {
      _selectedTab = index;
      if (index == 3) _journalVisited = true;
    });
  }

  void _showFavorites() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (routeContext) => Scaffold(
          appBar: AppBar(title: const Text('Favorites')),
          body: ListenableBuilder(
            listenable: _store,
            builder: (context, _) => FavoritesScreen(
              hotels: _store.favorites,
              onHotelTap: _openHotel,
              onFavoriteTap: _store.toggleFavorite,
              onTripAdd: _store.loadRateIfNeeded,
              onExplore: () {
                Navigator.pop(routeContext);
                _select(1);
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showAdd() async {
    final hotels = {
      for (final hotel in _store.availableHotels) hotel.id: hotel,
      for (final hotel in _store.favorites) hotel.id: hotel,
    }.values.toList();
    final message = await showModalBottomSheet<String>(
      isScrollControlled: true,
      showDragHandle: true,
      context: context,
      builder: (_) => AddHotelSheet(hotels: hotels, store: _store),
    );
    if (!mounted || message == null) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  Future<void> _openAuth(bool register) async {
    final preferences = context.read<PreferencesStore>();
    final profile = await Navigator.push<UserProfile>(
      context,
      MaterialPageRoute<UserProfile>(
        builder: (_) => RegistrationScreen(
          initialRegister: register,
          rememberedEmail: preferences.lastSignInEmail,
        ),
      ),
    );
    if (!mounted || profile == null) return;
    if (profile.email != preferences.lastSignInEmail) {
      await preferences.rememberSignInEmail(profile.email);
    }
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _selectedTab = 0;
    });
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Welcome to StayGo!')));
  }

  Future<void> _signOut() async {
    final preferences = context.read<PreferencesStore>();
    final email = _profile?.email;
    try {
      await LocalAuth.instance.logout();
      // Covers accounts whose active session was created before email prefill.
      if (email != null && email != preferences.lastSignInEmail) {
        await preferences.rememberSignInEmail(email);
      }
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
    _journal.dispose();
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
            _titles[_selectedTab],
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
          tooltip: 'Favorites',
          icon: const Icon(Icons.favorite_border),
          onPressed: _showFavorites,
        ),
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

        BlocBuilder<CartBloc, CartState>(
          builder: (context, cart) => Badge(
            isLabelVisible: cart.count > 0,
            label: Text('${cart.count}'),
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
            child: ExploreScreen(store: _store, onHotelTap: _openHotel),
          ),
          const SizedBox.shrink(),
          _journalVisited
              ? PhotoJournalScreen(journal: _journal)
              : const SizedBox.shrink(),
          ProfileScreen(
            profile: _profile,
            journal: _journal,
            onOpenJournal: () => _select(3),
            onRegister: () => _openAuth(true),
            onLogin: () => _openAuth(false),
            onSignOut: _signOut,
          ),
        ],
      ),
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: _selectedTab,
      onDestinationSelected: (index) {
        if (index == 2) {
          _showAdd();
        } else {
          _select(index);
        }
      },
      destinations: [
        const NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        const NavigationDestination(
          icon: Icon(Icons.search_rounded),
          label: 'Explore',
        ),
        NavigationDestination(
          icon: Icon(
            Icons.add_circle,
            color: Theme.of(context).colorScheme.primary,
          ),
          label: 'Add',
        ),
        const NavigationDestination(
          icon: Icon(Icons.photo_library_outlined),
          selectedIcon: Icon(Icons.photo_library),
          label: 'Journal',
          tooltip: 'Photo Journal',
        ),
        const NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    ),
  );
}
