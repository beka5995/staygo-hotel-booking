import 'package:shared_preferences/shared_preferences.dart';
import 'package:final_project/state/preferences_store.dart';

import 'dart:async';
import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:final_project/main.dart';

import 'fixtures/catalog.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });
  for (final grid in [true, false]) {
    for (final device in [PointerDeviceKind.touch, PointerDeviceKind.mouse]) {
      testWidgets(
        'pull refresh keeps ${grid ? 'grid' : 'list'} mounted for $device',
        (tester) async {
          var requests = 0;
          final refreshGate = Completer<void>();
          final store = testStore(
            client: MockClient((request) async {
              requests++;
              if (requests > 2) await refreshGate.future;
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
          if (!grid) {
            await tester.tap(find.byTooltip('List view'));
            await tester.pumpAndSettle();
          }
          final first = store.products.first.id;
          final indicator = tester.state<RefreshIndicatorState>(
            find.byType(RefreshIndicator),
          );
          final scrollable =
              grid ? find.byType(GridView) : find.byType(ListView);
          final rect = tester.getRect(scrollable.first);
          final gesture = await tester.startGesture(
            Offset(rect.center.dx, rect.top + 35),
            kind: device,
          );
          await gesture.moveBy(const Offset(0, 60));
          await tester.pump();
          await gesture.moveBy(const Offset(0, 300));
          await tester.pump();
          await gesture.up();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));
          expect(
            requests,
            4,
            reason: 'One refresh makes exactly one request per category',
          );
          expect(store.isRefreshing, isTrue);
          expect(store.products.length, 6);
          expect(scrollable, findsOneWidget);
          expect(
            identical(
              tester.state<RefreshIndicatorState>(
                find.byType(RefreshIndicator),
              ),
              indicator,
            ),
            isTrue,
          );
          expect(find.text('Loading collection…'), findsNothing);
          refreshGate.complete();
          await tester.pumpAndSettle();
          expect(store.isRefreshing, isFalse);
          expect(store.products.length, 7);
          expect(store.products[1].id, first);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
          store.dispose();
        },
      );
    }
  }
}
