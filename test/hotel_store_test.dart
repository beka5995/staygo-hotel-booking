import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:final_project_android_hotelbooking/state/hotel_store.dart';
import 'package:final_project_android_hotelbooking/services/hotel_places_service.dart';

import 'support/fixtures.dart';

void main() {
  test('Network catalog starts empty, loads six and prepends one real result on refresh', () async {
    final store = HotelStore(
      service: fixtureService(),
      refreshDelay: Duration.zero,
    );
    addTearDown(store.dispose);
    expect(store.hotels, isEmpty);
    await store.load();
    expect(store.hotels, hasLength(6));
    final first = store.hotels.first.id;
    await store.refresh();
    expect(store.hotels, hasLength(7));
    expect(store.hotels.first.id, 'g293974-d106');
    expect(store.hotels[1].id, first);
  });
  test('Swipe removal, undo at original index and empty reset', () async {
    final store = HotelStore(service: fixtureService());
    addTearDown(store.dispose);
    await store.load();
    final hotel = store.hotels[2];
    store.remove(hotel);
    expect(store.hotels, hasLength(5));
    store.restore(hotel, 2);
    expect(store.hotels[2].id, hotel.id);
    for (final h in store.hotels) {
      store.remove(h);
    }
    expect(store.hotels, isEmpty);
    await store.reset();
    expect(store.hotels, hasLength(6));
  });
  test(
    'Actual connection failure clears visible cards; Retry fetches them again',
    () async {
      var offline = false;
      final store = HotelStore(service: fixtureService(offline: () => offline));
      addTearDown(store.dispose);
      await store.load();
      store.toggleFavorite(store.hotels.first);
      offline = true;
      await store.verifyConnection();
      expect(store.state, HotelLoadState.error);
      expect(store.hotels, isEmpty);
      expect(store.favorites, hasLength(1));
      offline = false;
      await store.load();
      expect(store.state, HotelLoadState.ready);
      expect(store.hotels, hasLength(6));
    },
  );
  test('An offline event invalidates an in-flight response', () async {
    final response = Completer<http.Response>();
    final service = HotelPlacesService(
      client: MockClient((_) => response.future),
    );
    final store = HotelStore(service: service);
    addTearDown(store.dispose);
    final loading = store.load();
    store.setNetworkAvailable(false);
    response.complete(
      resultResponse({
        'list': [hotelJson(0)],
      }),
    );
    await loading;
    expect(store.state, HotelLoadState.error);
    expect(store.hotels, isEmpty);
  });
  test(
    'Retry can recover even if the OS never sends an online event',
    () async {
      final store = HotelStore(service: fixtureService());
      addTearDown(store.dispose);
      store.setNetworkAvailable(false);
      await store.load();
      expect(store.state, HotelLoadState.ready);
    },
  );
}
