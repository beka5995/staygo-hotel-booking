import 'package:flutter/foundation.dart';

import '../models/hotel.dart';
import '../models/trip_item.dart';

class CartProvider extends ChangeNotifier {
  final Map<String, TripItem> _items = {};
  CartProvider({List<TripItem> initialItems = const []}) {
    for (final item in initialItems) {
      _items[item.hotel.id] = item;
    }
  }

  List<TripItem> get items => List.unmodifiable(_items.values);
  int get itemCount => _items.length;
  int get unpricedCount => _items.values.where((i) => !i.hotel.hasPrice).length;
  double get totalPrice => _items.values.fold<double>(
    0,
    (sum, item) => sum + item.hotel.pricePerNight * item.nights,
  );
  bool containsHotel(String id) => _items.containsKey(id);
  void toggleHotel(Hotel hotel) {
    if (_items.containsKey(hotel.id)) {
      _items.remove(hotel.id);
    } else {
      _items[hotel.id] = TripItem(hotel: hotel);
    }
    notifyListeners();
  }

  void updateHotels(Map<String, Hotel> hotels) {
    var changed = false;
    for (final id in _items.keys.toList()) {
      final updated = hotels[id];
      final item = _items[id]!;
      if (updated != null && !identical(updated, item.hotel)) {
        _items[id] = TripItem(hotel: updated, nights: item.nights);
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  void removeHotel(String id) {
    if (_items.remove(id) != null) notifyListeners();
  }

  void changeNights(String id, int difference) {
    final item = _items[id];
    if (item == null) return;
    final next = item.nights + difference;
    if (next < 1 || next > 30 || next == item.nights) return;
    _items[id] = item.withNights(next);
    notifyListeners();
  }

  void clear() {
    if (_items.isEmpty) return;
    _items.clear();
    notifyListeners();
  }
}
