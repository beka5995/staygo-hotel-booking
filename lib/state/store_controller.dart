import 'package:flutter/foundation.dart';

import '../models/account.dart';
import '../models/product.dart';
import '../services/product_service.dart';

enum CatalogStatus { initial, loading, ready, error }

class StoreController extends ChangeNotifier {
  StoreController({
    ProductService? service,
    this.refreshDelay = const Duration(milliseconds: 1500),
  })  : _service = service ?? ProductService(),
        _ownsService = service == null;

  final ProductService _service;
  final bool _ownsService;
  final Duration refreshDelay;
  final List<Product> _products = [];
  final Map<String, Product> _known = {};
  final Set<String> _favoriteIds = {};
  final Set<String> _dismissedIds = {};
  Account? _account;
  CatalogStatus _status = CatalogStatus.initial;
  String? _error;
  int _request = 0;
  int _revision = 0;
  bool _disposed = false;
  bool _offline = false;
  bool _refreshing = false;
  bool _checkingConnection = false;

  List<Product> get products => List.unmodifiable(_products);
  Account? get account => _account;
  CatalogStatus get status => _status;
  bool get isRefreshing => _refreshing;
  String? get error => _error;
  int get revision => _revision;
  List<Product> get favorites => List.unmodifiable(
        _favoriteIds.map((id) => _known[id]).whereType<Product>(),
      );
  bool isFavorite(String id) => _favoriteIds.contains(id);

  Map<String, Product> get knownProducts => Map.unmodifiable(_known);
  void rememberItems(List<Product> items) {
    for (final item in items) {
      _known.putIfAbsent(item.id, () => item);
    }
  }

  void restoreFavorites(List<Product> products) {
    for (final product in products) {
      _known.putIfAbsent(product.id, () => product);
      _favoriteIds.add(product.id);
    }
  }

  void toggleFavorite(String id) {
    if (!_favoriteIds.add(id)) _favoriteIds.remove(id);
    notifyListeners();
  }

  Future<void> loadCatalog({bool prepend = false, bool reset = false}) async {
    if (_disposed || _status == CatalogStatus.loading) return;
    final token = ++_request;
    final previous = List<Product>.of(_products);
    _refreshing = prepend && previous.isNotEmpty;
    _status = CatalogStatus.loading;
    _error = null;
    notifyListeners();
    try {
      // Refresh keeps LAB 8's minimum 1.5-second wait alongside the real request.
      final results = await Future.wait<Object>([
        _service.fetchCatalog(),
        if (prepend)
          Future<void>.delayed(refreshDelay).then<Object>((_) => true),
      ]);
      if (_disposed || token != _request) return;
      if (_offline) {
        throw const ProductServiceException(
          'You are offline. Connect to the internet and try again.',
        );
      }
      final fetched = results.first as List<Product>;
      _known.addEntries(fetched.map((p) => MapEntry(p.id, p)));
      if (reset) _dismissedIds.clear();
      final available =
          fetched.where((p) => !_dismissedIds.contains(p.id)).toList();
      final byId = {for (final product in available) product.id: product};
      _products.clear();
      if (prepend && previous.isNotEmpty) {
        final existingIds = previous.map((p) => p.id).toSet();
        final unseen = available.where((p) => !existingIds.contains(p.id));
        if (unseen.isNotEmpty) _products.add(unseen.first);
        for (final product in previous) {
          final updated = byId[product.id];
          if (updated != null) _products.add(updated);
        }
      } else {
        _products.addAll(available.take(6));
      }
      _revision++;
      _refreshing = false;
      _status = CatalogStatus.ready;
    } catch (error) {
      if (_disposed || token != _request) return;
      _products.clear();
      _refreshing = false;
      _status = CatalogStatus.error;
      _error = error is ProductServiceException
          ? error.message
          : 'Could not load the collection. Please try again.';
    }
    if (!_disposed && token == _request) notifyListeners();
  }

  Future<void> refreshCatalog() => loadCatalog(prepend: true);
  Future<void> resetCatalog() => loadCatalog(reset: true);

  void setNetworkAvailable(bool available) {
    if (_disposed) return;
    final wasOffline = _offline;
    _offline = !available;
    if (!available) {
      ++_request; // In-flight responses cannot bring cards back while offline.
      _products.clear();
      _refreshing = false;
      _status = CatalogStatus.error;
      _error = 'You are offline. Connect to the internet and try again.';
      notifyListeners();
    } else if (wasOffline) {
      loadCatalog();
    }
  }

  Future<void> verifyConnection() async {
    if (_disposed || _checkingConnection || _status == CatalogStatus.loading) {
      return;
    }
    _checkingConnection = true;
    final token = _request;
    try {
      await _service.checkConnection();
      if (_disposed || token != _request || _status == CatalogStatus.loading) {
        return;
      }
      _offline = false;
      if (_status == CatalogStatus.error) await loadCatalog();
    } catch (error) {
      if (_disposed || token != _request || _status == CatalogStatus.loading) {
        return;
      }
      _products.clear();
      _refreshing = false;
      _status = CatalogStatus.error;
      _error =
          'Cannot reach the store. Check your internet connection and try again.';
      notifyListeners();
    } finally {
      _checkingConnection = false;
    }
  }

  void removeProduct(String id) {
    _dismissedIds.add(id);
    _products.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  void restoreProduct(Product product, int originalIndex) {
    if (_status != CatalogStatus.ready ||
        _products.any((p) => p.id == product.id)) {
      return;
    }
    _dismissedIds.remove(product.id);
    _products.insert(originalIndex.clamp(0, _products.length).toInt(), product);
    notifyListeners();
  }

  Future<Product> productById(String id) async {
    // Deep links are also verified over the network, including after restart.
    final product = await _service.fetchProduct(id);
    if (!_disposed) _known[product.id] = product;
    return product;
  }

  void register(Account account) {
    _account = account;
    notifyListeners();
  }

  void signOut() {
    _account = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    ++_request;
    if (_ownsService) _service.dispose();
    super.dispose();
  }
}
