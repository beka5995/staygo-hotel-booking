import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:final_project/main.dart';
import 'package:final_project/state/preferences_store.dart';
import 'package:final_project/state/cart_bloc.dart';
import 'package:final_project/models/product.dart';
import 'package:final_project/models/cart_item.dart';

import 'fixtures/catalog.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('Saved objects preserve fields and item options and reject corrupt quantities', () {
    final item = CartItem(product: sampleProducts.first, size: 41, quantity: 2);
    final restored = CartItem.fromSavedJson(
      jsonDecode(jsonEncode(item.toSavedJson())) as Map<String, dynamic>,
    );
    expect(restored.toSavedJson(), item.toSavedJson());
    expect(
      () => CartItem.fromSavedJson({...item.toSavedJson(), 'quantity': 0}),
      throwsFormatException,
    );
  });

  test('Malformed selection entries are skipped without losing valid saved objects', () async {
    final model = sampleProducts.first;
    SharedPreferences.setMockInitialValues({
      'saved_favorites_json': jsonEncode([
        model.toSavedJson(),
        {'id': 'broken'},
      ]),
    });
    final local = await PreferencesStore.load();
    expect(
      local.readItems('saved_favorites_json', Product.fromSavedJson),
      hasLength(1),
    );
    expect(local.error, isNotNull);
    local.dispose();
  });

  test('Rapid save then removal persists an empty list rather than resurrecting items', () async {
    final local = await PreferencesStore.load();
    await Future.wait([
      local.saveItems('saved_favorites_json', [
        (sampleProducts.first).toSavedJson(),
      ]),
      local.saveItems('saved_favorites_json', []),
    ]);
    final restored = await PreferencesStore.load();
    expect(
      restored.readItems('saved_favorites_json', Product.fromSavedJson),
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
      final store = testStore();
      await tester.pumpWidget(
        SneakersApp(
          preferences: local,
          store: store,
          enablePlatformServices: false,
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<BottomNavigationBar>(find.byType(BottomNavigationBar))
            .items
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
        tester
            .widget<BottomNavigationBar>(find.byType(BottomNavigationBar))
            .currentIndex,
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
      var store = testStore();
      await tester.pumpWidget(
        SneakersApp(
          preferences: local,
          store: store,
          enablePlatformServices: false,
        ),
      );
      await tester.pumpAndSettle();
      final model = store.products.first;
      store.toggleFavorite(model.id);
      var cart = tester.element(find.byType(Scaffold).first).read<CartBloc>();
      cart.add(AddProductEvent(model, size: 41));
      cart.add(AddProductEvent(model, size: 41));
      cart.add(AddProductEvent(model, size: 42));
      await tester.pumpAndSettle();
      await local.pendingWrites;
      final disk = await SharedPreferences.getInstance();
      final snapshot = {for (final key in disk.getKeys()) key: disk.get(key)!};
      await tester.pumpWidget(const SizedBox());
      store.dispose();
      local.dispose();
      SharedPreferences.setMockInitialValues(snapshot);
      local = await PreferencesStore.load();
      store = testStore(
        client: MockClient((_) async => throw http.ClientException('offline')),
      );
      await tester.pumpWidget(
        SneakersApp(
          preferences: local,
          store: store,
          enablePlatformServices: false,
        ),
      );
      await tester.pumpAndSettle();
      cart = tester.element(find.byType(Scaffold).first).read<CartBloc>();
      expect(store.products, isEmpty);
      expect(store.favorites.single.id, model.id);
      expect(cart.state.count, 3);
      expect(cart.state.items.map((i) => i.size), [41, 42]);
      expect(cart.state.items.first.quantity, 2);
      cart.add(const ClearCartEvent());
      store.toggleFavorite(model.id);
      await tester.pumpAndSettle();
      await local.pendingWrites;
      expect(
        local.readItems('saved_cart_json', CartItem.fromSavedJson),
        isEmpty,
      );
      expect(
        local.readItems('saved_favorites_json', Product.fromSavedJson),
        isEmpty,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      store.dispose();
      local.dispose();
    },
  );
}
