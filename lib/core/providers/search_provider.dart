import 'package:flutter/material.dart';
import 'package:shopsense/core/constants/strings.dart';

class SearchProvider extends ChangeNotifier {
  List<String> _recentSearches = [];
  bool _isSearching = false;

  List<String> get recentSearches => _recentSearches;
  bool get isSearching => _isSearching;

  SearchProvider() {
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
}
