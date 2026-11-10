import 'dart:async';
import 'dart:ui' show PointerDeviceKind;

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/cart_provider.dart';
import 'models/hotel.dart';
import 'models/trip_item.dart';
import 'state/preferences_store.dart';
import 'services/staygo_links.dart';
import 'screens/home_screen.dart';
import 'screens/hotel_link_screen.dart';
import 'state/hotel_store.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await PreferencesStore.load();
  runApp(MyApp(preferences: preferences));
}

class MyApp extends StatefulWidget {
  final PreferencesStore preferences;
  const MyApp({
    super.key,
    required this.preferences,
    this.store,
    this.enablePlatformServices = true,
  });
  final HotelStore? store;
  final bool enablePlatformServices;
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _navigator = GlobalKey<NavigatorState>();
  late final HotelStore _store;
  late final CartProvider _cart;
  StreamSubscription<Uri>? _links;
  String? _lastLink;
  DateTime? _lastOpened;

  @override
  void initState() {
    super.initState();
    _store = widget.store ?? HotelStore();
    _store.restoreFavorites(
      widget.preferences.readItems('saved_favorites_json', Hotel.fromSavedJson),
    );
    _cart = CartProvider(
      initialItems: widget.preferences.readItems(
        'saved_cart_json',
        TripItem.fromSavedJson,
      ),
    );
    _store.rememberItems(_cart.items.map((item) => item.hotel).toList());
    _store.addListener(_syncSelections);
    _cart.addListener(_saveCart);

    if (widget.enablePlatformServices && !kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _watchLinks());
    }
  }

  void _openLink(Uri uri) {
    if (!mounted) return;
    final id = hotelIdFromLink(uri.toString());
    if (id == null) return;
    final now = DateTime.now();
    if (_lastLink == id &&
        _lastOpened != null &&
        now.difference(_lastOpened!) < const Duration(seconds: 2)) {
      return;
    }
    _lastLink = id;
    _lastOpened = now;
    _navigator.currentState?.push(
      MaterialPageRoute<void>(
        builder: (_) => HotelLinkScreen(hotelId: id, store: _store),
      ),
    );
  }

  Future<void> _watchLinks() async {
    try {
      final links = AppLinks();
      _links = links.uriLinkStream.listen(
        _openLink,
        onError: (Object e) => debugPrint('Link: $e'),
      );
      final initial = await links.getInitialLink();
      if (initial != null) _openLink(initial);
    } catch (e) {
      debugPrint('Links unavailable: $e');
    }
  }

  void _saveCart() {
    unawaited(
      widget.preferences.saveItems(
        'saved_cart_json',
        _cart.items.map((item) => item.toSavedJson()).toList(),
      ),
    );
  }

  void _syncSelections() {
    unawaited(
      widget.preferences.saveItems(
        'saved_favorites_json',
        _store.favorites.map((item) => item.toSavedJson()).toList(),
      ),
    );
    if (_store.state == HotelLoadState.ready) {
      _cart.updateHotels(_store.knownHotels);
    }
  }

  @override
  void dispose() {
    _links?.cancel();
    _store.removeListener(_syncSelections);
    _cart.removeListener(_saveCart);
    _cart.dispose();
    if (widget.store == null) _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      ChangeNotifierProvider<CartProvider>.value(value: _cart),
      ChangeNotifierProvider<PreferencesStore>.value(value: widget.preferences),
    ],
    child: AnimatedBuilder(
      animation: widget.preferences,
      builder: (context, _) => MaterialApp(
        navigatorKey: _navigator,
        title: 'StayGo',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: widget.preferences.darkMode
            ? ThemeMode.dark
            : ThemeMode.light,
        scrollBehavior: const MaterialScrollBehavior().copyWith(
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
            PointerDeviceKind.trackpad,
            PointerDeviceKind.stylus,
          },
        ),
        home: HomeScreen(
          store: _store,
          enablePlatformServices: widget.enablePlatformServices,
        ),
        onGenerateRoute: (settings) {
          final id = hotelIdFromLink(settings.name ?? '');
          if (id == null) return null;
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => HotelLinkScreen(hotelId: id, store: _store),
          );
        },
      ),
    ),
  );
}
