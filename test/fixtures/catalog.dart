import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:final_project/models/product.dart';
import 'package:final_project/services/product_service.dart';
import 'package:final_project/state/store_controller.dart';

Map<String, dynamic> productJson(int id, {String category = 'mens-shoes'}) => {
      'id': id,
      'title': 'Pair $id',
      'brand': id.isEven ? 'Brand A' : 'Brand B',
      'category': category,
      'description': 'Comfortable shoes.',
      'price': 100 + id / 100,
      'rating': 4.5,
      'stock': 30,
      'images': <String>[],
    };

// Fixtures exist only in tests; the application has no seeded catalog.
final sampleProducts = List.generate(
  6,
  (i) => Product.fromJson(productJson(i + 1)),
);

ProductService serviceWithCatalog({http.Client? client}) => ProductService(
      client: client ??
          MockClient((request) async {
            if (request.url.path.endsWith('category/mens-shoes')) {
              return http.Response(
                jsonEncode({
                  'products': List.generate(5, (i) => productJson(i + 1)),
                }),
                200,
              );
            }
            if (request.url.path.endsWith('category/womens-shoes')) {
              return http.Response(
                jsonEncode({
                  'products': List.generate(
                    5,
                    (i) => productJson(i + 6, category: 'womens-shoes'),
                  ),
                }),
                200,
              );
            }
            final id = int.tryParse(request.url.pathSegments.last);
            return id == null
                ? http.Response('', 404)
                : http.Response(jsonEncode(productJson(id)), 200);
          }),
    );

StoreController testStore({http.Client? client}) => StoreController(
      service: serviceWithCatalog(client: client),
      refreshDelay: Duration.zero,
    );
