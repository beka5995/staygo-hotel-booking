import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'hotel_api_config.dart';
import '../models/hotel.dart';
import '../models/hotel_rate.dart';

class HotelCity {
  const HotelCity(this.name, this.locationKey, this.artwork);
  final String name;
  final String locationKey;
  final String artwork;
}

const hotelCities = <HotelCity>[
  HotelCity('Istanbul', 'g293974', 'heritage'),
  HotelCity('Astana', 'g293944', 'city'),
  HotelCity('Almaty', 'g298251', 'alpine'),
  HotelCity('Dubai', 'g295424', 'city'),
  HotelCity('Phuket', 'g293920', 'palm'),
];

class HotelPlacesException implements Exception {
  const HotelPlacesException(this.message);
  final String message;
  @override
  String toString() => message;
}

class HotelPlacesService {
  HotelPlacesService({
    http.Client? client,
    Uri? baseUrl,
    this.timeout = const Duration(seconds: 10),
  }) : _client = client ?? http.Client(),
       _ownsClient = client == null,
       baseUrl = baseUrl ?? Uri.parse(hotelApiBase);

  final http.Client _client;
  final bool _ownsClient;
  final Duration timeout;
  final Uri baseUrl;

  Uri _uri(String path, Map<String, String> query) => baseUrl.replace(
    path: '${baseUrl.path.replaceFirst(RegExp(r'/$'), '')}/$path',
    queryParameters: {...baseUrl.queryParameters, ...query},
  );

  Uri requestUri(HotelCity city, {int limit = 18}) => _uri('list', {
    'location_key': city.locationKey,
    'offset': '0',
    'limit': '$limit',
    'sort': 'best_value',
  });

  Future<Map<String, dynamic>> _get(Uri uri, {Duration? requestTimeout}) async {
    try {
      final response = await _client
          .get(
            uri,
            headers: const {'Cache-Control': 'no-cache', 'Pragma': 'no-cache'},
          )
          .timeout(requestTimeout ?? timeout);
      if (response.statusCode == 404) {
        throw const HotelPlacesException('This stay could not be found.');
      }
      if (response.statusCode == 429) {
        throw const HotelPlacesException('Please wait a moment and try again.');
      }
      if (response.statusCode >= 500) {
        throw const HotelPlacesException(
          'The hotel directory is temporarily unavailable.',
        );
      }
      if (response.statusCode != 200) {
        throw const HotelPlacesException(
          'Could not load hotels. Please try again.',
        );
      }
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic> ||
          decoded['error'] != null ||
          decoded['result'] is! Map<String, dynamic>) {
        throw const FormatException('Invalid hotel response');
      }
      return decoded['result'] as Map<String, dynamic>;
    } on HotelPlacesException {
      rethrow;
    } on TimeoutException {
      throw const HotelPlacesException(
        'Connection timed out. Check your internet and try again.',
      );
    } on FormatException {
      throw const HotelPlacesException(
        'Could not read hotel information. Please try again.',
      );
    } catch (_) {
      throw const HotelPlacesException(
        'Could not connect. Check your internet and try again.',
      );
    }
  }

  Future<List<Hotel>> findHotels(HotelCity city, {int limit = 18}) async {
    final result = await _get(requestUri(city, limit: limit));
    final list = result['list'];
    if (list is! List) {
      throw const HotelPlacesException('Could not read the hotel directory.');
    }
    final hotels = <Hotel>[];
    final ids = <String>{};
    try {
      for (final entry in list) {
        if (entry is! Map<String, dynamic>) {
          throw const FormatException('Invalid hotel');
        }
        final hotel = Hotel.fromJson(
          entry,
          city: city.name,
          inspirationPhotos: [
            'assets/stays/${city.artwork}_1.jpg',
            'assets/stays/${city.artwork}_2.jpg',
          ],
        );
        if (ids.add(hotel.id)) hotels.add(hotel);
      }
    } on FormatException {
      throw const HotelPlacesException('Could not read hotel information.');
    }
    return hotels;
  }

  Future<Hotel> withRate(Hotel hotel, {DateTime? date}) async {
    final now = DateTime.now();
    final checkIn =
        date ??
        DateTime(now.year, now.month, now.day).add(const Duration(days: 14));
    final checkOut = checkIn.add(const Duration(days: 1));
    String iso(DateTime d) => d.toIso8601String().substring(0, 10);
    // Missing rates do not invent a zero-dollar booking; UI shows Price on request.
    try {
      final result = await _get(
        _uri('rates', {
          'hotel_key': hotel.id,
          'chk_in': iso(checkIn),
          'chk_out': iso(checkOut),
          'currency': 'USD',
        }),
        requestTimeout: const Duration(seconds: 7),
      );
      final rates = result['rates'];
      if (result['currency'] != 'USD' || rates is! List) return hotel;
      final prices = <double>[];
      for (final rate in rates.whereType<Map<String, dynamic>>()) {
        try {
          prices.add(HotelRate.fromJson(rate).price);
        } on FormatException {
          continue;
        }
      }
      if (prices.isEmpty) return hotel;
      prices.sort();
      return hotel.copyWith(pricePerNight: prices.first, rateDate: checkIn);
    } on HotelPlacesException {
      return hotel;
    }
  }

  Future<void> checkConnection(HotelCity city) async {
    final result = await _get(
      requestUri(city, limit: 1),
      requestTimeout: const Duration(seconds: 4),
    );
    if (result['list'] is! List) {
      throw const HotelPlacesException('Cannot reach the hotel directory.');
    }
  }

  void dispose() {
    if (_ownsClient) _client.close();
  }
}
