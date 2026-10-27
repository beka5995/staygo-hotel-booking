import 'package:flutter/foundation.dart';

import '../models/hotel.dart';
import '../models/trip_item.dart';

class CartProvider extends ChangeNotifier {
  final Map<String, TripItem> _items = {};

  List<TripItem> get items => List.unmodifiable(_items.values);
  int get itemCount => _items.length;
  int get totalPrice =>
      _items.values.fold(0, (sum, item) => sum + item.totalPrice);

  bool containsHotel(String hotelId) => _items.containsKey(hotelId);

  void addHotel(Hotel hotel) {
    if (containsHotel(hotel.id)) return;
    _items[hotel.id] = TripItem(hotel: hotel, nights: 1);
    notifyListeners();
  }

  void toggleHotel(Hotel hotel) {
    if (containsHotel(hotel.id)) {
      removeHotel(hotel.id);
    } else {
      addHotel(hotel);
    }
  }

  void removeHotel(String hotelId) {
    if (_items.remove(hotelId) != null) notifyListeners();
  }

  void changeNights(String hotelId, int difference) {
    final item = _items[hotelId];
    if (item == null) return;
    final next = item.nights + difference;
    if (next < 1) return;
    _items[hotelId] = item.withNights(next);
    notifyListeners();
  }

  void clear() {
    if (_items.isEmpty) return;
    _items.clear();
    notifyListeners();
  }
}
