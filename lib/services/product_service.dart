import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/product.dart';

class ProductServiceException implements Exception {
  final String message;
  const ProductServiceException(this.message);
  @override
  String toString() => message;
}

class ProductService {
  static final Uri defaultBaseUrl = Uri.parse(
    const String.fromEnvironment(
      'SNEAKSHOP_API_URL',
      defaultValue: 'https://dummyjson.com/products',
    ),
  );
  final Uri baseUrl;
  final Duration timeout;
  final http.Client _client;
  final bool _ownsClient;
  int _nonce = 0;

  ProductService({
    http.Client? client,
    Uri? baseUrl,
    this.timeout = const Duration(seconds: 10),
  })  : _client = client ?? http.Client(),
        _ownsClient = client == null,
        baseUrl = baseUrl ?? defaultBaseUrl;

  Uri _uri(String suffix) => baseUrl.replace(
        path: '${baseUrl.path.replaceFirst(RegExp(r'/$'), '')}/$suffix',
        queryParameters: {
          ...baseUrl.queryParameters,
          '_request': '${DateTime.now().microsecondsSinceEpoch}_${_nonce++}',
        },
      );

  Future<Object?> _get(Uri uri, {Duration? requestTimeout}) async {
    try {
      final response =
          await _client.get(uri).timeout(requestTimeout ?? timeout);
      switch (response.statusCode) {
        case 200:
          return jsonDecode(utf8.decode(response.bodyBytes));
        case 404:
          throw const ProductServiceException(
            'This item is no longer available.',
          );
        case 429:
          throw const ProductServiceException(
            'Please wait a moment and try again.',
          );
        default:
          throw ProductServiceException(
            response.statusCode >= 500
                ? 'The store is temporarily unavailable. Please try again.'
                : 'Could not load the collection. Please try again.',
          );
      }
    } on TimeoutException {
      throw const ProductServiceException(
        'Connection timed out. Check your internet and try again.',
      );
    } on http.ClientException {
      throw const ProductServiceException(
        'Could not connect. Check your internet and try again.',
      );
    } on FormatException {
      throw const ProductServiceException(
        'Could not read the collection. Please try again.',
      );
    } on ProductServiceException {
      rethrow;
    } catch (_) {
      throw const ProductServiceException(
        'Could not connect. Check your internet and try again.',
      );
    }
  }

  Future<void> checkConnection() async {
    final uri = _uri('category/mens-shoes');
    final response = await _get(
      uri.replace(
        queryParameters: {...uri.queryParameters, 'limit': '1', 'select': 'id'},
      ),
      requestTimeout: const Duration(seconds: 3),
    );
    if (response is! Map<String, dynamic> || response['products'] is! List) {
      throw const ProductServiceException(
        'The store is unreachable. Please try again.',
      );
    }
  }

  Future<List<Product>> fetchCatalog() async {
    final responses = await Future.wait([
      _get(_uri('category/mens-shoes')),
      _get(_uri('category/womens-shoes')),
    ]);
    try {
      final products = <Product>[];
      final ids = <String>{};
      for (final response in responses) {
        if (response is! Map<String, dynamic> ||
            response['products'] is! List) {
          throw const FormatException('Invalid catalog');
        }
        for (final entry in response['products'] as List) {
          if (entry is! Map<String, dynamic>) {
            throw const FormatException('Invalid item');
          }
          final product = Product.fromJson(entry);
          if (!ids.add(product.id)) {
            throw const FormatException('Duplicate product');
          }
          products.add(product);
        }
      }
      // Put casual footwear first while preserving the API's product identities.
      products.sort((a, b) {
        int rank(Product p) => p.category == 'Men'
            ? 0
            : p.name.toLowerCase().contains('pampi')
                ? 1
                : 2;
        final order = rank(a).compareTo(rank(b));
        return order != 0 ? order : a.id.compareTo(b.id);
      });
      return products;
    } on FormatException {
      throw const ProductServiceException(
        'Could not read the collection. Please try again.',
      );
    }
  }

  Future<Product> fetchProduct(String id) async {
    final match = RegExp(r'^api_([1-9][0-9]{0,8})$').firstMatch(id);
    if (match == null) {
      throw const ProductServiceException('Product not found.');
    }
    final response = await _get(_uri(match.group(1)!));
    try {
      if (response is! Map<String, dynamic>) {
        throw const FormatException('Invalid product');
      }
      final product = Product.fromJson(response);
      if (product.id != id) throw const FormatException('Unexpected product');
      return product;
    } on FormatException {
      throw const ProductServiceException(
        'Could not read this product. Please try again.',
      );
    }
  }

  void dispose() {
    if (_ownsClient) _client.close();
  }
}
