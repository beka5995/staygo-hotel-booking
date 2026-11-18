import 'package:shared_preferences/shared_preferences.dart';
import 'package:final_project/state/preferences_store.dart';

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:final_project/main.dart';
import 'package:final_project/state/store_controller.dart';

import 'fixtures/catalog.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });
  testWidgets('main catalog loads, switches views and shares cart state', (
    tester,
  ) async {
    final store = testStore();
    await tester.pumpWidget(
      SneakersApp(
        preferences: await PreferencesStore.load(),
        store: store,
        enablePlatformServices: false,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('SneakShop'), findsOneWidget);
    expect(find.byType(GridView), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    await tester.tap(find.byTooltip('List view'));
    await tester.pumpAndSettle();
    expect(find.byType(Dismissible), findsWidgets);
    final add = find.widgetWithText(OutlinedButton, 'Add to Cart').first;
    await tester.ensureVisible(add);
    await tester.tap(add);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Shopping bag'));
    await tester.pumpAndSettle();
    expect(find.text('Clear All'), findsOneWidget);
    expect(find.text('Total'), findsOneWidget);
    await tester.tap(find.byTooltip('Remove item').first);
    await tester.pumpAndSettle();
    expect(find.text('Your bag is empty'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Add to Cart'), findsWidgets);
    await tester.pumpWidget(const SizedBox.shrink());
    store.dispose();
  });

  testWidgets(
    'offline hides cards and Retry returns through loading to success',
    (tester) async {
      var offline = false;
      Completer<http.Response>? pending;
      final store = testStore(
        client: MockClient((request) async {
          if (offline) throw http.ClientException('offline');
          if (pending != null) return pending.future;
          final women = request.url.path.contains('womens');
          return http.Response(
            jsonEncode({
              'products': List.generate(
                5,
                (i) => productJson(
                  i + (women ? 6 : 1),
                  category: women ? 'womens-shoes' : 'mens-shoes',
                ),
              ),
            }),
            200,
          );
        }),
      );
      await tester.pumpWidget(
        SneakersApp(
          preferences: await PreferencesStore.load(),
          store: store,
          enablePlatformServices: false,
        ),
      );
      await tester.pumpAndSettle();
      expect(store.products.length, 6);
      offline = true;
      store.setNetworkAvailable(false);
      await tester.pumpAndSettle();
      expect(find.text('Unable to load sneakers'), findsOneWidget);
      expect(find.byType(GridView), findsNothing);
      offline = false;
      pending = Completer<http.Response>();
      store.setNetworkAvailable(true);
      await tester.pump();
      expect(find.text('Loading collection…'), findsOneWidget);
      pending.complete(http.Response(jsonEncode({'products': []}), 200));
      await tester.pumpAndSettle();
      expect(find.text('Catalog is Empty'), findsOneWidget);
      pending = null;
      await tester.tap(find.text('Reset Catalog'));
      await tester.pumpAndSettle();
      expect(find.byType(GridView), findsOneWidget);
      expect(store.status, CatalogStatus.ready);
      // An HTTP failure while Wi-Fi is still available must also show Retry.
      offline = true;
      await tester.tap(find.byTooltip('Refresh'));
      await tester.pumpAndSettle();
      expect(find.text('Retry Connection'), findsOneWidget);
      offline = false;
      await tester.tap(find.text('Retry Connection'));
      await tester.pumpAndSettle();
      expect(find.byType(GridView), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      store.dispose();
    },
  );
}
