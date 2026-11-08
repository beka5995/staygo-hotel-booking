import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:final_project_android_hotelbooking/models/hotel.dart';
import 'package:final_project_android_hotelbooking/services/hotel_places_service.dart';

import 'support/fixtures.dart';

void main() {
  final city = hotelCities.first;
  test(
    'JSON converts both integer and double ratings, never invents a USD price',
    () {
      for (final rating in [4, 4.5]) {
        final hotel = Hotel.fromJson({
          ...hotelJson(0),
          'review_summary': {'rating': rating, 'count': 32},
          'price_ranges': {'minimum': 75},
        }, city: 'Istanbul');
        expect(hotel.rating, rating.toDouble());
        expect(hotel.hasPrice, isFalse);
      }
      expect(
        () => Hotel.fromJson({'key': 'bad', 'name': 'Stay'}, city: 'Istanbul'),
        throwsFormatException,
      );
    },
  );
  test('No rating is different from a zero-star review', () {
    final hotel = Hotel.fromJson({
      ...hotelJson(0),
      'review_summary': null,
    }, city: 'Istanbul');
    expect(hotel.hasRating, isFalse);
    expect(hotel.reviewCount, 0);
  });
  test(
    'List request uses valid upstream parameters and removes duplicate IDs',
    () async {
      final service = HotelPlacesService(
        client: MockClient((r) async {
          expect(r.url.queryParameters['location_key'], city.locationKey);
          expect(r.url.queryParameters.containsKey('_request'), isFalse);
          expect(r.headers['Cache-Control'], 'no-cache');
          return resultResponse({
            'list': [hotelJson(0), hotelJson(0), hotelJson(1)],
          });
        }),
      );
      final hotels = await service.findHotels(city);
      expect(hotels, hasLength(2));
      expect(hotels.first.name, 'Test Stay 0');
    },
  );
  test('Rates use the lowest positive finite USD rate with integer/double conversion', () async {
    final service = HotelPlacesService(
      client: MockClient((r) async {
        expect(r.url.queryParameters['chk_in'], '2026-11-22');
        expect(r.url.queryParameters['currency'], 'USD');
        return resultResponse({
          'currency': 'USD',
          'rates': [
            {'rate': 120},
            {'rate': 97.5},
            {'rate': -1},
            {'rate': 'free'},
          ],
        });
      }),
    );
    final hotel = await service.withRate(
      hotelFixture(0, price: 0),
      date: DateTime(2026, 11, 22),
    );
    expect(hotel.pricePerNight, 97.5);
    expect(hotel.rateDate, DateTime(2026, 11, 22));
  });
  test('Unavailable tariffs stay unpriced, not free', () async {
    for (final currency in ['USD', 'EUR']) {
      final service = HotelPlacesService(
        client: MockClient(
          (_) async => resultResponse({'currency': currency, 'rates': []}),
        ),
      );
      final hotel = await service.withRate(hotelFixture(0, price: 0));
      expect(hotel.priceLabel, 'Price on request');
    }
  });
  test(
    'HTTP errors and invalid JSON do not silently return seed hotels',
    () async {
      for (final status in [404, 429, 500]) {
        final service = HotelPlacesService(
          client: MockClient((_) async => http.Response('Unavailable', status)),
        );
        await expectLater(
          service.findHotels(city),
          throwsA(isA<HotelPlacesException>()),
        );
      }
      final bad = HotelPlacesService(
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'error': {'message': 'bad query'},
              'result': null,
            }),
            200,
          ),
        ),
      );
      await expectLater(
        bad.findHotels(city),
        throwsA(isA<HotelPlacesException>()),
      );
      final timeout = HotelPlacesService(
        client: MockClient((_) async => throw TimeoutException('offline')),
      );
      await expectLater(
        timeout.findHotels(city),
        throwsA(isA<HotelPlacesException>()),
      );
    },
  );
}
