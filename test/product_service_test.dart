import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:final_project/models/product.dart';
import 'package:final_project/services/product_service.dart';

import 'fixtures/catalog.dart';

void main() {
  test('model accepts integer and double prices without losing decimals', () {
    expect(Product.fromJson({...productJson(1), 'price': 150}).price, 150.0);
    expect(
      Product.fromJson({...productJson(1), 'price': 149.99}).price,
      149.99,
    );
    for (final value in [-1, double.infinity, double.nan, null, 'bad']) {
      expect(
        () => Product.fromJson({...productJson(1), 'price': value}),
        throwsFormatException,
      );
    }
  });

  test(
    'catalog fetches both categories and uses uncached request URLs',
    () async {
      final paths = <String>[];
      final service = serviceWithCatalog(
        client: MockClient((request) async {
          paths.add(request.url.path);
          expect(request.url.queryParameters['_request'], isNotNull);
          final women = request.url.path.contains('womens');
          return http.Response(
            jsonEncode({
              'products': [
                productJson(
                  women ? 2 : 1,
                  category: women ? 'womens-shoes' : 'mens-shoes',
                ),
              ],
            }),
            200,
          );
        }),
      );
      expect((await service.fetchCatalog()).length, 2);
      expect(paths.length, 2);
    },
  );

  test('404, 500 and offline requests fail without a local fallback', () async {
    for (final status in [404, 500]) {
      final service = ProductService(
        client: MockClient((_) async => http.Response('', status)),
      );
      await expectLater(
        service.fetchCatalog(),
        throwsA(isA<ProductServiceException>()),
      );
    }
    final service = ProductService(
      client: MockClient((_) async => throw http.ClientException('offline')),
    );
    await expectLater(
      service.fetchCatalog(),
      throwsA(isA<ProductServiceException>()),
    );
  });

  test('timeouts and malformed JSON become readable errors', () async {
    final timeout = ProductService(
      timeout: const Duration(milliseconds: 1),
      client: MockClient((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return http.Response('{}', 200);
      }),
    );
    await expectLater(
      timeout.fetchCatalog(),
      throwsA(isA<ProductServiceException>()),
    );
    final invalid = ProductService(
      client: MockClient((_) async => http.Response('{bad', 200)),
    );
    await expectLater(
      invalid.fetchCatalog(),
      throwsA(isA<ProductServiceException>()),
    );
  });

  test('deep links fetch the complete product on a fresh launch', () async {
    final product = await serviceWithCatalog().fetchProduct('api_8');
    expect(product.id, 'api_8');
    expect(product.name, 'Pair 8');
    await expectLater(
      serviceWithCatalog().fetchProduct('bad'),
      throwsA(isA<ProductServiceException>()),
    );
  });
}
