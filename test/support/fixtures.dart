import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:final_project_android_hotelbooking/models/hotel.dart';
import 'package:final_project_android_hotelbooking/services/hotel_places_service.dart';

// Test data only. The application does not import this file or use offline seeds.
Hotel hotelFixture(int i, {double price = 90}) => Hotel(
  id: 'g293974-d${100 + i}',
  name: 'Test Stay $i',
  city: 'Istanbul',
  pricePerNight: price,
  rating: 4.5,
  reviewCount: 25,
  imageUrl: 'assets/stays/heritage_1.jpg',
  description: 'A test stay.',
  category: 'Hotel',
  amenities: const ['Breakfast included'],
  photos: const ['assets/stays/heritage_1.jpg'],
  assetPhotos: const [
    'assets/stays/heritage_2.jpg',
    'assets/stays/heritage_3.jpg',
  ],
);
final fixtureHotels = List.generate(8, hotelFixture);
Map<String, dynamic> hotelJson(int i) => {
  'key': 'g293974-d${100 + i}',
  'name': 'Test Stay $i',
  'review_summary': {'rating': 4.5, 'count': 25},
  'image': '',
  'accommodation_type': 'Hotel',
  'merchandising_labels': ['Breakfast included'],
};
http.Response resultResponse(Map<String, dynamic> result) =>
    http.Response(jsonEncode({'error': null, 'result': result}), 200);
HotelPlacesService fixtureService({bool Function()? offline}) =>
    HotelPlacesService(
      client: MockClient((request) async {
        if (offline?.call() ?? false) throw http.ClientException('offline');
        if (request.url.path.endsWith('/rates')) {
          return resultResponse({
            'currency': 'USD',
            'rates': [
              {'rate': 90},
            ],
          });
        }
        return resultResponse({'list': List.generate(8, hotelJson)});
      }),
    );
