import 'dart:async';
import 'dart:ui' show PointerDeviceKind;

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/cart_provider.dart';
import 'services/staygo_links.dart';
import 'screens/home_screen.dart';
import 'screens/hotel_link_screen.dart';
import 'state/hotel_store.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, this.store, this.enablePlatformServices = true});
  final HotelStore? store;
  final bool enablePlatformServices;
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _navigator = GlobalKey<NavigatorState>();
  late final HotelStore _store;
  StreamSubscription<Uri>? _links;
  String? _lastLink;
  DateTime? _lastOpened;

  @override
  void initState() {
    super.initState();
    _store = widget.store ?? HotelStore();
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

  @override
  void dispose() {
    _links?.cancel();
    if (widget.store == null) _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider<CartProvider>(
    create: (_) => CartProvider(),
    child: MaterialApp(
      navigatorKey: _navigator,
      title: 'StayGo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
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
  );
}
