import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shopsense/core/constants/strings.dart';
import 'package:shopsense/core/models/product.dart';
import 'package:shopsense/core/services/api_client.dart';

/// Search state backed by the live ShopSense backend.
///
/// Text, image, and hybrid searches hit the FastAPI API; recent searches
/// stay local. Any [ApiException] is surfaced via [errorMessage] so the
/// UI can show a friendly error instead of crashing.
class SearchProvider extends ChangeNotifier {
  final ApiClient _api;

  List<String> _recentSearches = [];
  bool _isSearching = false;
  List<Product> _results = [];
  String? _errorMessage;
  String? _translatedQuery;

  List<String> get recentSearches => _recentSearches;
  bool get isSearching => _isSearching;
  List<Product> get results => _results;
  String? get errorMessage => _errorMessage;
  String? get translatedQuery => _translatedQuery;

  SearchProvider({ApiClient? api}) : _api = api ?? ApiClient() {
    _loadRecentSearches();
  }

  void _loadRecentSearches() {
    // TODO: Load from local storage
    _recentSearches = [
      'Kurta Shalwar',
      'Sneakers',
      'Smartphone',
      'Sunglasses',
    ];
  }

  void addRecentSearch(String query) {
    if (query.isNotEmpty) {
      _recentSearches.remove(query);
      _recentSearches.insert(0, query);
      if (_recentSearches.length > 10) {
        _recentSearches.removeLast();
      }
      notifyListeners();
    }
  }

  /// Local Roman Urdu keyword mapping (the backend also translates).
  String translateRomanUrdu(String query) {
    final lowerQuery = query.toLowerCase();
    for (var entry in AppStrings.romanUrduMap.entries) {
      if (lowerQuery.contains(entry.key)) {
        return query.replaceAll(entry.key, entry.value);
      }
    }
    return query;
  }

  void setSearching(bool value) {
    _isSearching = value;
    notifyListeners();
  }

  void clearRecentSearches() {
    _recentSearches.clear();
    notifyListeners();
  }

  void clearResults() {
    _results = [];
    _errorMessage = null;
    _translatedQuery = null;
    notifyListeners();
  }

  void _beginSearch() {
    _isSearching = true;
    _errorMessage = null;
    _translatedQuery = null;
    notifyListeners();
  }

  void _failSearch(Object e) {
    _isSearching = false;
    _results = [];
    _errorMessage = e is ApiException
        ? e.message
        : 'Search failed. Please try again.';
    notifyListeners();
  }

  /// POST /search/text
  Future<void> searchText(String query) async {
    if (query.trim().isEmpty) return;
    _beginSearch();
    try {
      final response = await _api.textSearch(query.trim());
      _results = response.products;
      _translatedQuery = response.translatedQuery;
      _isSearching = false;
      addRecentSearch(query.trim());
      notifyListeners();
    } catch (e) {
      _failSearch(e);
    }
  }

  /// POST /search/image
  Future<void> searchImage(XFile image) async {
    _beginSearch();
    try {
      _results = await _api.imageSearch(image);
      _isSearching = false;
      notifyListeners();
    } catch (e) {
      _failSearch(e);
    }
  }

  /// POST /search/hybrid (image + text query)
  Future<void> searchHybrid(XFile image, String query) async {
    _beginSearch();
    try {
      _results = await _api.hybridSearch(image, query);
      _isSearching = false;
      if (query.trim().isNotEmpty) {
        addRecentSearch(query.trim());
      }
      notifyListeners();
    } catch (e) {
      _failSearch(e);
    }
  }
}
