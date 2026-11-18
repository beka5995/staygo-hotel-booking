import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart'
    show MultiProvider, ChangeNotifierProvider;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'database/local_auth.dart';
import 'state/cart_bloc.dart';
import 'models/product.dart';
import 'models/cart_item.dart';
import 'state/preferences_store.dart';
import 'screens/home_shell.dart';
import 'screens/product_detail_screen.dart';
import 'services/product_links.dart';
import 'state/store_controller.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) databaseFactory = databaseFactoryFfiWeb;
  final preferences = await PreferencesStore.load();
  runApp(SneakersApp(preferences: preferences));
}

class SneakersApp extends StatefulWidget {
  final PreferencesStore preferences;
  final StoreController? store;
  final bool enablePlatformServices;
  const SneakersApp({
    super.key,
    required this.preferences,
    this.store,
    this.enablePlatformServices = true,
  });
  @override
  State<SneakersApp> createState() => _SneakersAppState();
}

class _SneakersAppState extends State<SneakersApp> with WidgetsBindingObserver {
  late final StoreController _store;
  late final CartBloc _cart;
  late final StreamSubscription<CartState> _cartSubscription;
  final _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<Uri>? _linkSubscription;
  StreamSubscription<List<ConnectivityResult>>? _networkSubscription;
  Timer? _connectionTimer;
  String? _lastLink;
  DateTime? _lastLinkTime;

  @override
  void initState() {
    super.initState();
    _store = widget.store ?? StoreController();
    _store.restoreFavorites(
      widget.preferences.readItems(
        'saved_favorites_json',
        Product.fromSavedJson,
      ),
    );
    _cart = CartBloc(
      initialItems: widget.preferences.readItems(
        'saved_cart_json',
        CartItem.fromSavedJson,
      ),
    );
    _store.rememberItems(
      _cart.state.items.map((item) => item.product).toList(),
    );
    _store.addListener(_syncSelections);
    _cartSubscription = _cart.stream.listen(_saveCart);

    _store.loadCatalog();
    if (widget.enablePlatformServices) {
      WidgetsBinding.instance.addObserver(this);
      _restoreUser();
      _watchNetwork();
      _startConnectionChecks();
      if (!kIsWeb) _listenToLinks();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkNetwork();
      _store.verifyConnection();
      _startConnectionChecks();
    } else {
      _connectionTimer?.cancel();
    }
  }

  void _startConnectionChecks() {
    _connectionTimer?.cancel();
    _connectionTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) _store.verifyConnection();
    });
  }

  void _applyNetwork(List<ConnectivityResult> results) {
    if (!mounted) return;
    _store.setNetworkAvailable(
      results.any((r) => r != ConnectivityResult.none),
    );
  }

  Future<void> _checkNetwork() async {
    try {
      final results = await Connectivity().checkConnectivity();
      _applyNetwork(results);
      // Wi-Fi availability alone is not proof of internet; retry uses real HTTP.
      if (mounted &&
          _store.status == CatalogStatus.error &&
          results.any((r) => r != ConnectivityResult.none)) {
        _store.loadCatalog();
      }
    } catch (error) {
      debugPrint('Network status unavailable: $error');
    }
  }

  Future<void> _watchNetwork() async {
    try {
      _networkSubscription = Connectivity().onConnectivityChanged.listen(
        _applyNetwork,
        onError: (Object e) => debugPrint('Network status: $e'),
      );
      await _checkNetwork();
    } catch (error) {
      debugPrint('Network monitoring unavailable: $error');
    }
  }

  Future<void> _restoreUser() async {
    try {
      final account = await LocalAuth.instance.currentAccount();
      if (mounted && account != null) _store.register(account);
    } catch (error) {
      debugPrint('Could not restore session: $error');
    }
  }

  Future<void> _listenToLinks() async {
    try {
      final links = AppLinks();
      _linkSubscription = links.uriLinkStream.listen(
        _openLink,
        onError: (Object e) => debugPrint('Link error: $e'),
      );
      final uri = await links.getInitialLink();
      if (!mounted || uri == null) return;
      if (_navigatorKey.currentState != null) {
        _openLink(uri);
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _openLink(uri);
        });
        WidgetsBinding.instance.ensureVisualUpdate();
      }
    } catch (error) {
      debugPrint('Unable to initialize links: $error');
    }
  }

  void _openLink(Uri uri) {
    if (!mounted) return;
    final link = ProductLink.parse(uri);
    final navigator = _navigatorKey.currentState;
    if (link == null || navigator == null) return;
    final now = DateTime.now();
    if (_lastLink == uri.toString() &&
        _lastLinkTime != null &&
        now.difference(_lastLinkTime!) < const Duration(seconds: 2)) {
      return;
    }
    _lastLink = uri.toString();
    _lastLinkTime = now;
    navigator.push(
      MaterialPageRoute<void>(
        builder: (_) =>
            ProductLinkScreen(productId: link.sneakerId, store: _store),
      ),
    );
  }

  void _saveCart(CartState state) {
    unawaited(
      widget.preferences.saveItems(
        'saved_cart_json',
        state.items.map((item) => item.toSavedJson()).toList(),
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
    if (_store.status == CatalogStatus.ready) {
      _cart.add(UpdateProductsEvent(_store.knownProducts));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _linkSubscription?.cancel();
    _store.removeListener(_syncSelections);
    unawaited(_cartSubscription.cancel());
    unawaited(_cart.close());
    _networkSubscription?.cancel();
    _connectionTimer?.cancel();
    if (widget.store == null) _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      BlocProvider<CartBloc>.value(value: _cart),
      ChangeNotifierProvider<PreferencesStore>.value(value: widget.preferences),
    ],
    child: AnimatedBuilder(
      animation: widget.preferences,
      builder: (context, _) => MaterialApp(
        navigatorKey: _navigatorKey,
        debugShowCheckedModeBanner: false,
        title: 'SneakShop',
        scrollBehavior: const MaterialScrollBehavior().copyWith(
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
            PointerDeviceKind.trackpad,
            PointerDeviceKind.stylus,
            PointerDeviceKind.invertedStylus,
            PointerDeviceKind.unknown,
          },
        ),
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: widget.preferences.darkMode
            ? ThemeMode.dark
            : ThemeMode.light,
        home: HomeShell(store: _store),
        onGenerateRoute: (settings) {
          final link = ProductLink.parse(
            Uri.tryParse(settings.name ?? '') ?? Uri(),
          );
          if (link == null) return null;
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) =>
                ProductLinkScreen(productId: link.sneakerId, store: _store),
          );
        },
      ),
    ),
  );
}
