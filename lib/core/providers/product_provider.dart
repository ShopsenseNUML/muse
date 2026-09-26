import 'package:flutter/material.dart';
import 'package:shopsense/core/models/product.dart';
import 'package:shopsense/core/services/api_client.dart';

/// Product catalog backed by the live ShopSense backend.
///
/// The catalog is loaded from `GET /products/` on startup. The exposed
/// maps keep the exact key shape the existing UI expects
/// (`id`, `name`, `price`, `imageUrl`, `source`, `rating`, `brand`,
/// `category`, `description`, ...), so no screen needs to change.
/// Saved products and search history stay local to the device.
class ProductProvider extends ChangeNotifier {
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
    notifyListeners();
  }

  void addSearchHistory(String query) {
    _searchHistory.insert(0, {'query': query, 'timestamp': DateTime.now()});
    if (_searchHistory.length > 20) {
      _searchHistory.removeLast();
    }
    notifyListeners();
  }

  void clearSearchHistory() {
    _searchHistory.clear();
    notifyListeners();
  }

  List<Map<String, dynamic>> getProductsByCategory(String category) {
    if (category == 'All') {
      return _products;
    }
    return _products.where((p) => p['category'] == category).toList();
  }

  /// Local filter over the loaded catalog (the backend search endpoints
  /// live in [SearchProvider]).
  List<Map<String, dynamic>> searchProducts(String query) {
    final lowerQuery = query.toLowerCase();
    return _products.where((product) {
      final name = (product['name'] ?? '').toString().toLowerCase();
      final category = (product['category'] ?? '').toString().toLowerCase();
      final brand = (product['brand'] ?? '').toString().toLowerCase();
      return name.contains(lowerQuery) ||
          category.contains(lowerQuery) ||
          brand.contains(lowerQuery);
    }).toList();
  }

  /// Convert raw backend [Product]s to the UI map shape.
  static List<Map<String, dynamic>> toUiMaps(List<Product> products) =>
      products.map((p) => p.toUiMap()).toList();
}
