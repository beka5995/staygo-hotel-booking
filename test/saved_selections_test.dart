import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:final_project_android_hotelbooking/main.dart';
import 'package:final_project_android_hotelbooking/state/preferences_store.dart';
import 'package:final_project_android_hotelbooking/providers/cart_provider.dart';
import 'package:final_project_android_hotelbooking/models/hotel.dart';
import 'package:final_project_android_hotelbooking/models/trip_item.dart';
import 'package:final_project_android_hotelbooking/state/hotel_store.dart';

import 'support/fixtures.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('Saved objects preserve fields and item options and reject corrupt quantities', () {
    final item = TripItem(hotel: hotelFixture(0), nights: 3);
    final restored = TripItem.fromSavedJson(
      jsonDecode(jsonEncode(item.toSavedJson())) as Map<String, dynamic>,
    );
    expect(restored.toSavedJson(), item.toSavedJson());
    expect(
      () => TripItem.fromSavedJson({...item.toSavedJson(), 'nights': 0}),
      throwsFormatException,
    );
  });

  test('Malformed selection entries are skipped without losing valid saved objects', () async {
    final model = hotelFixture(0);
    SharedPreferences.setMockInitialValues({
      'saved_favorites_json': jsonEncode([
        model.toSavedJson(),
        {'id': 'broken'},
      ]),
    });
    final local = await PreferencesStore.load();
    expect(
      local.readItems('saved_favorites_json', Hotel.fromSavedJson),
      hasLength(1),
    );
    expect(local.error, isNotNull);
    local.dispose();
  });

  test('Rapid save then removal persists an empty list rather than resurrecting items', () async {
    final local = await PreferencesStore.load();
    await Future.wait([
      local.saveItems('saved_favorites_json', [
        (hotelFixture(0)).toSavedJson(),
      ]),
      local.saveItems('saved_favorites_json', []),
    ]);
    final restored = await PreferencesStore.load();
    expect(
      restored.readItems('saved_favorites_json', Hotel.fromSavedJson),
      isEmpty,
    );
    local.dispose();
    restored.dispose();
  });

  testWidgets(
    'Notes is a top action, bottom menu has three tabs and Back retains Profile',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final local = await PreferencesStore.load();
      final store = HotelStore(service: fixtureService());
      await tester.pumpWidget(
        MyApp(preferences: local, store: store, enablePlatformServices: false),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<NavigationBar>(find.byType(NavigationBar))
            .destinations
            .length,
        3,
      );
      expect(find.byTooltip('Notes'), findsOneWidget);
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Notes'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('dark-mode-toggle')), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        2,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      store.dispose();
      local.dispose();
    },
  );

  testWidgets(
    'Cart and favorites restore offline with options and removal stays saved',
    (tester) async {
      var local = await PreferencesStore.load();
      var store = HotelStore(service: fixtureService());
      await tester.pumpWidget(
        MyApp(preferences: local, store: store, enablePlatformServices: false),
      );
      await tester.pumpAndSettle();
      final model = store.hotels.first;
      store.toggleFavorite(model);
      var cart = tester
          .element(find.byType(Scaffold).first)
          .read<CartProvider>();
      cart.toggleHotel(model);
      cart.changeNights(model.id, 2);
      await tester.pumpAndSettle();
      await local.pendingWrites;
      final disk = await SharedPreferences.getInstance();
      final snapshot = {for (final key in disk.getKeys()) key: disk.get(key)!};
      await tester.pumpWidget(const SizedBox());
      store.dispose();
      local.dispose();
      SharedPreferences.setMockInitialValues(snapshot);
      local = await PreferencesStore.load();
      store = HotelStore(service: fixtureService(offline: () => true));
      await tester.pumpWidget(
        MyApp(preferences: local, store: store, enablePlatformServices: false),
      );
      await tester.pumpAndSettle();
      cart = tester.element(find.byType(Scaffold).first).read<CartProvider>();
      expect(store.hotels, isEmpty);
      expect(store.favorites.single.id, model.id);
      expect(cart.itemCount, 1);
      expect(cart.items.single.nights, 3);
      cart.clear();
      store.toggleFavorite(store.favorites.single);
      await tester.pumpAndSettle();
      await local.pendingWrites;
      expect(
        local.readItems('saved_cart_json', TripItem.fromSavedJson),
        isEmpty,
      );
      expect(
        local.readItems('saved_favorites_json', Hotel.fromSavedJson),
        isEmpty,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      store.dispose();
      local.dispose();
    },
  );
}
