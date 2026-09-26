import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shopsense/core/models/product.dart';
import 'package:shopsense/core/services/api_client.dart';

/// Product catalog backed by the live ShopSense backend.
///
/// The catalog is loaded from `GET /products/` on startup. The exposed
/// maps keep the exact key shape the existing UI expects
/// (`id`, `name`, `price`, `imageUrl`, `source`, `rating`, `brand`,
/// `category`, `description`, ...), so no screen needs to change.
/// Saved products and search history stay local to the device and are
/// persisted with SharedPreferences.
class ProductProvider extends ChangeNotifier {
  static const _savedKey = 'saved_products';
  static const _historyKey = 'search_history';

  final ApiClient _api;

  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _savedProducts = [];
  List<Map<String, dynamic>> _searchHistory = [];

  bool _catalogLoading = false;
  String? _catalogError;

  List<Map<String, dynamic>> get products => _products;
  List<Map<String, dynamic>> get savedProducts => _savedProducts;
  List<Map<String, dynamic>> get searchHistory => _searchHistory;
  bool get isCatalogLoading => _catalogLoading;
  String? get catalogError => _catalogError;

  ProductProvider({ApiClient? api}) : _api = api ?? ApiClient() {
    _loadLocalData();
    loadCatalog();
  }

  /// GET /products/ — refresh the catalog from the backend.
  Future<void> loadCatalog({int limit = 100}) async {
    _catalogLoading = true;
    _catalogError = null;
    notifyListeners();
    try {
      final fetched = await _api.getProducts(limit: limit);
      _products = fetched.map((p) => p.toUiMap()).toList();
    } on ApiException catch (e) {
      _catalogError = e.message;
    } catch (_) {
      _catalogError = 'Could not load the product catalog.';
    } finally {
      _catalogLoading = false;
      notifyListeners();
    }
  }

  /// GET /products/{id} — full detail for one product, or null.
  Future<Map<String, dynamic>?> getProductById(String id) async {
    try {
      final product = await _api.getProduct(id);
      return product?.toUiMap();
    } on ApiException {
      return null;
    }
  }

  bool isProductSaved(String productId) {
    return _savedProducts.any((p) => p['id'].toString() == productId);
  }

  void toggleSavedProduct(String productId, Map<String, dynamic> product) {
    if (isProductSaved(productId)) {
      _savedProducts.removeWhere((p) => p['id'].toString() == productId);
    } else {
      _savedProducts.add(product);
    }
    _persistSavedProducts();
    notifyListeners();
  }

  void clearSavedProducts() {
    _savedProducts = [];
    _persistSavedProducts();
    notifyListeners();
  }

  void addSearchHistory(String query) {
    _searchHistory.insert(0, {'query': query, 'timestamp': DateTime.now()});
    if (_searchHistory.length > 20) {
      _searchHistory.removeLast();
    }
    _persistSearchHistory();
    notifyListeners();
  }

  void clearSearchHistory() {
    _searchHistory = [];
    _persistSearchHistory();
    notifyListeners();
  }

  Future<void> _loadLocalData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final savedJson = prefs.getString(_savedKey);
      if (savedJson != null) {
        final decoded = jsonDecode(savedJson);
        if (decoded is List) {
          _savedProducts = decoded
              .whereType<Map>()
              .map(_stringifyKeys)
              .toList();
        }
      }

      final historyJson = prefs.getString(_historyKey);
      if (historyJson != null) {
        final decoded = jsonDecode(historyJson);
        if (decoded is List) {
          _searchHistory = decoded
              .whereType<Map>()
              .map((e) => _stringifyKeys(e))
              .map(
                (m) => {
                  'query': (m['query'] ?? '').toString(),
                  'timestamp': m['timestamp'] is String
                      ? DateTime.tryParse(m['timestamp'] as String) ??
                            DateTime.now()
                      : DateTime.now(),
                },
              )
              .toList();
        }
      }
      notifyListeners();
    } catch (_) {
      // Local storage unavailable — keep the in-memory lists.
    }
  }

  Future<void> _persistSavedProducts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_savedKey, jsonEncode(_savedProducts));
    } catch (_) {
      // Non-fatal: wishlist still works for this session.
    }
  }

  Future<void> _persistSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encodable = _searchHistory
          .map(
            (e) => {
              'query': e['query'],
              'timestamp':
                  (e['timestamp'] as DateTime?)?.toIso8601String() ??
                  DateTime.now().toIso8601String(),
            },
          )
          .toList();
      await prefs.setString(_historyKey, jsonEncode(encodable));
    } catch (_) {
      // Non-fatal: history still works for this session.
    }
  }

  /// Normalizes a decoded JSON map to `Map<String, dynamic>`.
  static Map<String, dynamic> _stringifyKeys(Map m) =>
      m.map((k, v) => MapEntry(k.toString(), v));

  /// Convert raw backend [Product]s to the UI map shape.
  static List<Map<String, dynamic>> toUiMaps(List<Product> products) =>
      products.map((p) => p.toUiMap()).toList();
}
