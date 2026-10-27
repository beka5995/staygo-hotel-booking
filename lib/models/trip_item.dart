
import 'hotel.dart';

class TripItem {
  final Hotel hotel;
  final int nights;

  const TripItem({
    required this.hotel,
    this.nights = 1,
  });

  TripItem withNights(int value) {
    return TripItem(hotel: hotel, nights: value);
  }
}
