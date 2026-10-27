
import 'package:flutter/foundation.dart';

import '../models/hotel.dart';
import '../models/trip_item.dart';

class CartProvider extends ChangeNotifier {
  final Map<String, TripItem> _items = {};

  List<TripItem> get items => List.unmodifiable(_items.values);

  int get itemCount => _items.length;

  int get totalPrice => _items.values.fold(
    0,
        (sum, item) =>
    sum + item.hotel.pricePerNight * item.nights,
  );

  bool containsHotel(String id) {
    return _items.containsKey(id);
  }

  void toggleHotel(Hotel hotel) {
    if (_items.containsKey(hotel.id)) {
      _items.remove(hotel.id);
    } else {
      _items[hotel.id] = TripItem(hotel: hotel);
    }
    notifyListeners();
  }

  void removeHotel(String id) {
    if (_items.remove(id) != null) {
      notifyListeners();
    }
  }

  void changeNights(String id, int difference) {
    final item = _items[id];
    if (item == null) return;

    final next = item.nights + difference;

    if (next < 1 || next > 30) return;

    _items[id] = item.withNights(next);
    notifyListeners();
  }

  void clear() {
    if (_items.isEmpty) return;

    _items.clear();
    notifyListeners();
  }
}
