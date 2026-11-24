import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:final_project_android_hotelbooking/main.dart';
import 'package:final_project_android_hotelbooking/state/preferences_store.dart';
import 'package:final_project_android_hotelbooking/state/hotel_store.dart';
import 'package:final_project_android_hotelbooking/services/hotel_places_service.dart';

import 'support/fixtures.dart';

HotelPlacesService delayedRates(Completer<http.Response> gate) =>
    HotelPlacesService(
      client: MockClient((request) async {
        if (request.url.path.endsWith('/rates')) return gate.future;
        return resultResponse({'list': List.generate(6, hotelJson)});
      }),
    );
http.Response rates() => resultResponse({
  'currency': 'USD',
  'rates': [
    {'rate': 77},
  ],
});

void main() {
  test('Directory becomes ready before rates; deleted cards stay removed and Undo uses the new price', () async {
    final gate = Completer<http.Response>();
    final store = HotelStore(service: delayedRates(gate));
    await store.load();
    expect(store.state, HotelLoadState.ready);
    expect(store.hotels, hasLength(6));
    final hotel = store.hotels[2];
    expect(store.isRateLoading(hotel.id), isTrue);
    store.remove(hotel);
    gate.complete(rates());
    await store.ratesSettled;
    expect(store.hotels, hasLength(5));
    expect(store.hotels.any((h) => h.id == hotel.id), isFalse);
    store.restore(hotel, 2);
    expect(store.hotels[2].pricePerNight, 77);
    store.dispose();
  });
  test('Late rates cannot revive the catalog after an offline event', () async {
    final gate = Completer<http.Response>();
    final store = HotelStore(service: delayedRates(gate));
    await store.load();
    store.setNetworkAvailable(false);
    gate.complete(rates());
    await store.ratesSettled;
    expect(store.state, HotelLoadState.error);
    expect(store.hotels, isEmpty);
    store.dispose();
  });
  testWidgets(
    'Cards and details render while a tariff request is still pending',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final local = await PreferencesStore.load();
      final gate = Completer<http.Response>();
      final store = HotelStore(service: delayedRates(gate));
      await tester.pumpWidget(
        MyApp(preferences: local, store: store, enablePlatformServices: false),
      );
      await tester.pumpAndSettle();
      expect(find.byType(GridView), findsOneWidget);
      expect(find.text('Checking price…'), findsWidgets);
      await tester.ensureVisible(find.text('Test Stay 0').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Test Stay 0').first);
      await tester.pumpAndSettle();
      expect(find.text('Hotel details'), findsOneWidget);
      expect(find.text('Checking price…'), findsOneWidget);
      gate.complete(rates());
      await tester.pumpAndSettle();
      expect(find.text('\$77.00 / night'), findsOneWidget);
      expect(find.text('Checking price…'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      store.dispose();
      local.dispose();
    },
  );
}
