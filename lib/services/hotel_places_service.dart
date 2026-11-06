import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/hotel.dart';

class HotelCity {
  const HotelCity(this.name, this.boundingBox);

  final String name;
  final String boundingBox;
}

const hotelCities = <HotelCity>[
  HotelCity('Almaty', '43.18,76.82,43.31,77.05'),
  HotelCity('Istanbul', '40.98,28.91,41.10,29.12'),
  HotelCity('Dubai', '25.13,55.19,25.29,55.40'),
  HotelCity('Phuket', '7.82,98.28,7.96,98.42'),
];

class HotelPlacesException implements Exception {
  const HotelPlacesException(this.message);
  final String message;

  @override
  String toString() => message;
}

class HotelPlacesService {
  HotelPlacesService({http.Client? client, this.timeout = const Duration(seconds: 10)})
      : _client = client ?? http.Client(),
        _ownsClient = client == null;

  final http.Client _client;
  final bool _ownsClient;
  final Duration timeout;

  Uri requestUri(HotelCity city) {
    final box = city.boundingBox;
    final query = '[out:json][timeout:9];'
        '(node["tourism"="hotel"]["name"]($box);'
        'way["tourism"="hotel"]["name"]($box);'
        'relation["tourism"="hotel"]["name"]($box););'
        'out center 18;';
    return Uri.https('overpass.private.coffee', '/api/interpreter', {'data': query});
  }

  Future<List<Hotel>> findHotels(HotelCity city) async {
    try {
      final response = await _client.get(requestUri(city)).timeout(timeout);
      if (response.statusCode == 404) {
        throw const HotelPlacesException('Hotels could not be found right now.');
      }
      if (response.statusCode == 429) {
        throw const HotelPlacesException('Too many requests. Please try again later.');
      }
      if (response.statusCode >= 500) {
        throw const HotelPlacesException('The hotel directory is unavailable. Try again later.');
      }
      if (response.statusCode != 200) {
        throw const HotelPlacesException('Could not load hotels. Please try again.');
      }
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic> || decoded['elements'] is! List) {
        throw const FormatException('Unexpected response format');
      }
      final hotels = <Hotel>[];
      final ids = <String>{};
      for (final entry in decoded['elements'] as List) {
        if (entry is! Map<String, dynamic>) continue;
        final hotel = hotelFromOpenStreetMap(entry, city.name);
        if (hotel != null && ids.add(hotel.id)) hotels.add(hotel);
      }
      return hotels;
    } on HotelPlacesException {
      rethrow;
    } on TimeoutException {
      throw const HotelPlacesException('Connection timed out. Check your internet and try again.');
    } on FormatException {
      throw const HotelPlacesException('Hotel information is temporarily unavailable.');
    } on Exception {
      throw const HotelPlacesException('Could not connect. Check your internet and try again.');
    }
  }

  void dispose() {
    if (_ownsClient) _client.close();
  }
}

Hotel? hotelFromOpenStreetMap(Map<String, dynamic> data, String city) {
  final tags = data['tags'];
  final rawId = data['id'];
  final type = data['type'];
  if (tags is! Map || rawId is! num ||
      (type != 'node' && type != 'way' && type != 'relation')) {
    return null;
  }
  final title = tags['name:en'] ?? tags['name'];
  if (title is! String || title.trim().isEmpty) return null;
  final street = tags['addr:street'];
  final number = tags['addr:housenumber'];
  final addressParts = <String>[
    if (street is String && street.trim().isNotEmpty) street.trim(),
    if (number is String && number.trim().isNotEmpty) number.trim(),
  ];
  final address = addressParts.isEmpty ? null : addressParts.join(', ');
  const destinationArtwork = <String, String>{
    'Almaty': 'alpine',
    'Istanbul': 'heritage',
    'Dubai': 'city',
    'Phuket': 'palm',
  };
  final theme = destinationArtwork[city] ?? 'ocean';
  final rotation = rawId.toInt() % 3;
  final scenicViews = List<String>.generate(
    3,
    (index) => 'assets/stays/${theme}_${(index + rotation) % 3 + 1}.jpg',
  );
  final sourceUrl = 'https://www.openstreetmap.org/$type/${rawId.toInt()}';
  return Hotel(
    id: 'osm-$type-${rawId.toInt()}',
    name: title.trim(),
    city: city,
    pricePerNight: 0,
    rating: 0,
    reviewCount: 0,
    imageUrl: '',
    assetPhotos: scenicViews,
    description: address == null
        ? 'Discover this hotel in $city. Explore its location and save it for later.'
        : 'Find this hotel at $address, $city.',
    category: 'Hotel',
    amenities: const [],
    address: address,
    sourceUrl: sourceUrl,
  );
}
