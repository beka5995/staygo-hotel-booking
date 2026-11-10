import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/hotel.dart';
import '../services/hotel_places_service.dart';

enum HotelLoadState { initial, loading, ready, error }

class HotelStore extends ChangeNotifier {
  HotelStore({
    HotelPlacesService? service,
    this.refreshDelay = const Duration(milliseconds: 1500),
  }) : _service = service ?? HotelPlacesService(),
       _ownsService = service == null;
  final HotelPlacesService _service;
  final bool _ownsService;
  final Duration refreshDelay;
  HotelCity _city = hotelCities.first;
  final List<Hotel> _hotels = [];
  final Map<String, Hotel> _known = {};
  final Set<String> _favorites = {};
  final Set<String> _dismissed = {};
  HotelLoadState _state = HotelLoadState.initial;
  String? _error;
  bool _refreshing = false;
  bool _offline = false;
  bool _disposed = false;
  bool _checking = false;
  int _token = 0;
  int _revision = 0;
  final Set<String> _pricing = {};
  Future<void> _rates = Future<void>.value();
  bool isRateLoading(String id) => _pricing.contains(id);
  Future<void> get ratesSettled => _rates;

  List<Hotel> get hotels => List.unmodifiable(_hotels);
  Map<String, Hotel> get knownHotels => Map.unmodifiable(_known);
  List<Hotel> get favorites =>
      _favorites.map((id) => _known[id]).whereType<Hotel>().toList();
  Set<String> get favoriteIds => Set.unmodifiable(_favorites);
  HotelCity get city => _city;
  HotelLoadState get state => _state;
  String? get error => _error;
  bool get isRefreshing => _refreshing;
  int get revision => _revision;
  bool isFavorite(String id) => _favorites.contains(id);

  void rememberItems(List<Hotel> items) {
    for (final item in items) {
      _known.putIfAbsent(item.id, () => item);
    }
  }

  void restoreFavorites(List<Hotel> hotels) {
    for (final hotel in hotels) {
      _known.putIfAbsent(hotel.id, () => hotel);
      _favorites.add(hotel.id);
    }
  }

  void toggleFavorite(Hotel hotel) {
    _known.putIfAbsent(hotel.id, () => hotel);
    if (!_favorites.add(hotel.id)) _favorites.remove(hotel.id);
    notifyListeners();
  }

  Future<void> load({bool prepend = false, bool reset = false}) async {
    if (_disposed || _state == HotelLoadState.loading) return;
    final token = ++_token;
    _pricing.clear();
    final previous = List<Hotel>.of(_hotels);
    _refreshing = prepend && previous.isNotEmpty;
    _state = HotelLoadState.loading;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait<Object>([
        _service.findHotels(
          _city,
          limit: prepend
              ? (previous.length + _dismissed.length + 1).clamp(18, 100).toInt()
              : 18,
        ),
        if (prepend)
          Future<void>.delayed(refreshDelay).then<Object>((_) => true),
      ]);
      if (_disposed || token != _token) return;
      final fetched = results.first as List<Hotel>;
      if (reset) _dismissed.clear();
      final available = fetched
          .where((h) => !_dismissed.contains(h.id))
          .toList();
      final selected = <Hotel>[];
      if (prepend && previous.isNotEmpty) {
        final oldIds = previous.map((h) => h.id).toSet();
        final unseen = available.where((h) => !oldIds.contains(h.id));
        if (unseen.isNotEmpty) selected.add(unseen.first);
        final byId = {for (final h in available) h.id: h};
        selected.addAll(previous.map((h) => byId[h.id]).whereType<Hotel>());
      } else {
        selected.addAll(available.take(6));
      }
      // Publish directory results immediately; room rates resolve independently.
      final visible = selected.map((hotel) {
        final previous = _known[hotel.id];
        return previous != null && previous.hasPrice
            ? hotel.copyWith(
                pricePerNight: previous.pricePerNight,
                rateDate: previous.rateDate,
              )
            : hotel;
      }).toList();
      _offline = false;
      _known.addEntries(
        fetched.map((hotel) => MapEntry(hotel.id, _known[hotel.id] ?? hotel)),
      );
      _known.addEntries(visible.map((hotel) => MapEntry(hotel.id, hotel)));
      _hotels
        ..clear()
        ..addAll(visible);
      _pricing
        ..clear()
        ..addAll(selected.map((hotel) => hotel.id));
      _state = HotelLoadState.ready;
      _refreshing = false;
      _revision++;
      notifyListeners();
      _rates = _loadRates(selected, token);
    } catch (error) {
      if (_disposed || token != _token) return;
      _hotels.clear();
      _pricing.clear();
      _refreshing = false;
      _state = HotelLoadState.error;
      _error = error is HotelPlacesException
          ? error.message
          : 'Could not load stays. Please try again.';
    }
    if (!_disposed && token == _token) notifyListeners();
  }

  Future<void> _loadRates(List<Hotel> hotels, int token) async {
    await Future.wait(
      hotels.map((hotel) async {
        Hotel updated;
        try {
          updated = await _service.withRate(hotel);
        } catch (_) {
          updated = hotel;
        }
        if (_disposed || token != _token || _state != HotelLoadState.ready) {
          return;
        }
        _known[hotel.id] = updated;
        final index = _hotels.indexWhere((item) => item.id == hotel.id);
        if (index >= 0) _hotels[index] = updated;
        _pricing.remove(hotel.id);
        notifyListeners();
      }),
    );
  }

  Future<void> refresh() => load(prepend: true);
  Future<void> reset() => load(reset: true);
  Future<void> browseCity(HotelCity city) async {
    if (_city.locationKey == city.locationKey) return;
    ++_token;
    _city = city;
    _hotels.clear();
    _dismissed.clear();
    _state = HotelLoadState.initial;
    _refreshing = false;
    await load();
  }

  void remove(Hotel hotel) {
    _dismissed.add(hotel.id);
    _hotels.removeWhere((h) => h.id == hotel.id);
    notifyListeners();
  }

  void restore(Hotel hotel, int index) {
    if (_state != HotelLoadState.ready ||
        _hotels.any((h) => h.id == hotel.id)) {
      return;
    }
    _dismissed.remove(hotel.id);
    _hotels.insert(
      index.clamp(0, _hotels.length).toInt(),
      _known[hotel.id] ?? hotel,
    );
    notifyListeners();
  }

  void setNetworkAvailable(bool available) {
    if (_disposed) return;
    final wasOffline = _offline;
    _offline = !available;
    if (!available) {
      ++_token;
      _hotels.clear();
      _pricing.clear();
      _refreshing = false;
      _state = HotelLoadState.error;
      _error = 'You are offline. Connect to the internet and try again.';
      notifyListeners();
    } else if (wasOffline) {
      load();
    }
  }

  Future<void> verifyConnection() async {
    if (_disposed || _checking || _state == HotelLoadState.loading) return;
    _checking = true;
    final token = _token;
    try {
      await _service.checkConnection(_city);
      if (_disposed || token != _token) return;
      _offline = false;
      if (_state == HotelLoadState.error) await load();
    } catch (_) {
      if (_disposed || token != _token) return;
      _hotels.clear();
      _pricing.clear();
      _refreshing = false;
      _state = HotelLoadState.error;
      ++_token;
      _error = 'Cannot reach the hotel directory. Check your connection and try again.';
      notifyListeners();
    } finally {
      _checking = false;
    }
  }

  Future<Hotel> findById(String id) async {
    final match = RegExp(r'^(g[0-9]+)-d[0-9]+$').firstMatch(id);
    if (match == null) throw const HotelPlacesException('Hotel not found.');
    final candidates = hotelCities.where(
      (c) => c.locationKey == match.group(1),
    );
    if (candidates.isEmpty) {
      throw const HotelPlacesException('Destination not found.');
    }
    final hotels = await _service.findHotels(candidates.first, limit: 100);
    final found = hotels.where((h) => h.id == id);
    if (found.isEmpty) throw const HotelPlacesException('Hotel not found.');
    final hotel = await _service.withRate(found.first);
    if (!_disposed) _known[hotel.id] = hotel;
    return hotel;
  }

  @override
  void dispose() {
    _disposed = true;
    ++_token;
    if (_ownsService) _service.dispose();
    super.dispose();
  }
}
