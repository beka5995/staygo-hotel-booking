import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:final_project/services/product_service.dart';
import 'package:final_project/state/store_controller.dart';

import 'fixtures/catalog.dart';

void main() {
  test(
    'real server failure hides cards even without a platform offline event',
    () async {
      var online = true;
      final store = testStore(
        client: MockClient((request) async {
          if (!online) throw http.ClientException('Network disconnected');
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
      online = false;
      await store.verifyConnection();
      expect(store.status, CatalogStatus.error);
      expect(store.products, isEmpty);
      // Retry must not restore local/cached cards while the server remains unreachable.
      await store.loadCatalog();
      expect(store.status, CatalogStatus.error);
      expect(store.products, isEmpty);
      online = true;
      await store.verifyConnection();
      expect(store.status, CatalogStatus.ready);
      expect(store.products.length, 6);
      store.dispose();
    },
  );

  test(
    'connection checks have fresh URLs and request only a minimal response',
    () async {
      final urls = <String>[];
      final service = ProductService(
        client: MockClient((request) async {
          urls.add(request.url.toString());
          expect(request.url.queryParameters['limit'], '1');
          expect(request.url.queryParameters['select'], 'id');
          return http.Response('{"products":[{"id":88}]}', 200);
        }),
      );
      await service.checkConnection();
      await service.checkConnection();
      expect(urls[0], isNot(urls[1]));
    },
  );

  test(
    'stale background check cannot overwrite a successful manual request',
    () async {
      final pending = Completer<http.Response>();
      final store = testStore(
        client: MockClient((request) async {
          if (request.url.queryParameters['select'] == 'id') {
            return pending.future;
          }
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
      final checking = store.verifyConnection();
      await store.refreshCatalog();
      pending.complete(http.Response('', 503));
      await checking;
      expect(store.status, CatalogStatus.ready);
      expect(store.products.length, 7);
      store.dispose();
    },
  );
}
