import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:final_project_android_hotelbooking/services/hotel_places_service.dart';

void main() {
  const city = HotelCity('Almaty', '43.18,76.82,43.31,77.05');

  test('Builds a hotel-only query using the selected city', () {
    final service = HotelPlacesService(client: MockClient((_) async => http.Response('{}', 200)));
    final uri = service.requestUri(city);
    expect(uri.scheme, 'https');
    expect(uri.queryParameters['data'], contains('tourism'));
    expect(uri.queryParameters['data'], contains(city.boundingBox));
  });

  test('Parses real hotel names and keeps unverified prices empty', () async {
    final service = HotelPlacesService(client: MockClient((request) async {
      expect(request.url.host, 'overpass.private.coffee');
      return http.Response(jsonEncode({
        'elements': [
          {
            'type': 'node', 'id': 123,
            'tags': {
              'name': 'Hotel Grand',
              'addr:street': 'Abay Avenue',
              'addr:housenumber': '10',
            },
          },
          {'type': 'node', 'id': 124, 'tags': {'name': ''}},
          {'type': 'way', 'id': 125, 'tags': {'name': 'Another Hotel'}},
          {'type': 'way', 'id': 125, 'tags': {'name': 'Duplicate'}},
        ],
      }), 200);
    }));
    final hotels = await service.findHotels(city);
    expect(hotels, hasLength(2));
    expect(hotels.first.id, 'osm-node-123');
    expect(hotels.first.address, 'Abay Avenue, 10');
    expect(hotels.first.hasPrice, isFalse);
    expect(hotels.first.hasRating, isFalse);
    expect(hotels.first.gallery, hasLength(3));
    expect(hotels.first.gallery.toSet(), hasLength(3));
    expect(hotels.first.sourceUrl, 'https://www.openstreetmap.org/node/123');
  });

  test('Reports 404 and 500 as readable errors', () async {
    for (final status in [404, 500]) {
      final service = HotelPlacesService(
        client: MockClient((_) async => http.Response('Unavailable', status)),
      );
      await expectLater(
        service.findHotels(city),
        throwsA(isA<HotelPlacesException>()),
      );
    }
  });

  test('Handles invalid response and unexpected network errors', () async {
    final invalid = HotelPlacesService(
      client: MockClient((_) async => http.Response('{invalid', 200)),
    );
    await expectLater(invalid.findHotels(city), throwsA(isA<HotelPlacesException>()));
    final offline = HotelPlacesService(
      client: MockClient((_) async => throw Exception('offline')),
    );
    await expectLater(offline.findHotels(city), throwsA(isA<HotelPlacesException>()));
  });

  test('Converts request timeout to a connection message', () async {
    final service = HotelPlacesService(
      client: MockClient((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        return http.Response('ok', 200);
      }),
      timeout: const Duration(milliseconds: 1),
    );
    await expectLater(
      service.findHotels(city),
      throwsA(isA<HotelPlacesException>()),
    );
  });
}
