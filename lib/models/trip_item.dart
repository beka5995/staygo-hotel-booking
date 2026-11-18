import 'package:equatable/equatable.dart';

import '../utils/stored_json.dart';
import 'hotel.dart';

class TripItem extends Equatable {
  final Hotel hotel;
  final int nights;

  const TripItem({required this.hotel, this.nights = 1});

  TripItem withNights(int value) {
    return TripItem(hotel: hotel, nights: value);
  }

  @override
  List<Object?> get props => [hotel, nights];

  Map<String, dynamic> toSavedJson() => {
    'hotel': hotel.toSavedJson(),
    'nights': nights,
  };
  factory TripItem.fromSavedJson(Map<String, dynamic> json) => TripItem(
    hotel: Hotel.fromSavedJson(StoredJson.object(json, 'hotel')),
    nights: StoredJson.integer(json, 'nights', minimum: 1, maximum: 30),
  );
}
