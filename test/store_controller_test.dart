import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:final_project/state/store_controller.dart';

import 'fixtures/catalog.dart';

void main() {
  test('catalog starts empty, then six network products appear', () async {
    final store = testStore();
    expect(store.products, isEmpty);
    expect(store.status, CatalogStatus.initial);
    await store.loadCatalog();
    expect(store.status, CatalogStatus.ready);
    expect(store.products.length, 6);
    store.dispose();
  });

  test(
    'refresh prepends an unseen response item without duplicate IDs',
    () async {
      final store = testStore();
      await store.loadCatalog();
      final oldFirst = store.products.first.id;
      await store.refreshCatalog();
      expect(store.products.length, 7);
      expect(store.products[1].id, oldFirst);
      expect(store.products.map((p) => p.id).toSet().length, 7);
      await store.resetCatalog();
      expect(store.products.length, 6);
      store.dispose();
    },
  );

  test(
    'delete and undo restore the original index; reset requests again',
    () async {
      final store = testStore();
      await store.loadCatalog();
      final product = store.products[1];
      store.toggleFavorite(product.id);
      store.removeProduct(product.id);
      expect(store.favorites.single.id, product.id);
      store.restoreProduct(product, 1);
      expect(store.products[1].id, product.id);
      for (final item in store.products.toList()) {
        store.removeProduct(item.id);
      }
      expect(store.products, isEmpty);
      await store.resetCatalog();
      expect(store.products.length, 6);
      store.dispose();
    },
  );

  test(
    'a failed refresh hides previously loaded cards; retry restores them',
    () async {
      var offline = false;
      final store = testStore(
        client: MockClient((request) async {
          if (offline) throw http.ClientException('offline');
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
      await store.loadCatalog();
      expect(store.products.length, 6);
      offline = true;
      await store.refreshCatalog();
      expect(store.status, CatalogStatus.error);
      expect(store.products, isEmpty);
      offline = false;
      await store.loadCatalog();
      expect(store.products.length, 6);
      store.dispose();
    },
  );

  test('airplane mode rejects late network responses', () async {
    final pending = Completer<http.Response>();
    final store = testStore(client: MockClient((_) => pending.future));
    final loading = store.loadCatalog();
    store.setNetworkAvailable(false);
    pending.complete(
      http.Response(
        jsonEncode({
          'products': [productJson(1)],
        }),
        200,
      ),
    );
    await loading;
    expect(store.status, CatalogStatus.error);
    expect(store.products, isEmpty);
    store.dispose();
  });

  test('disposing during a request never notifies after disposal', () async {
    final pending = Completer<http.Response>();
    final store = testStore(client: MockClient((_) => pending.future));
    final loading = store.loadCatalog();
    store.dispose();
    pending.complete(http.Response(jsonEncode({'products': []}), 200));
    await expectLater(loading, completes);
  });
}
