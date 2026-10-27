import 'hotel.dart';

class TripItem {
  final Hotel hotel;
  final int nights;

  const TripItem({required this.hotel, required this.nights});

  int get totalPrice => hotel.pricePerNight * nights;

  TripItem withNights(int value) => TripItem(hotel: hotel, nights: value);
}
