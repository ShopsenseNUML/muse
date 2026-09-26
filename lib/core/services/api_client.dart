import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shopsense/core/constants/api_constants.dart';
import 'package:shopsense/core/models/product.dart';

/// Thrown for any backend communication problem, with a message
/// suitable for showing directly in the UI.
class ApiException implements Exception {
  final String message;
  const ApiException(this.message);

  @override
  String toString() => message;
}

/// Single place where the app talks to the ShopSense FastAPI backend.
///
/// Every method throws [ApiException] on failure (unreachable backend,
/// non-2xx status, or malformed response) so providers can surface a
/// friendly error state instead of crashing.
class ApiClient {
  final String baseUrl;
  final http.Client _http;

  ApiClient({String? baseUrl, http.Client? httpClient})
      : baseUrl = baseUrl ?? ApiConstants.baseUrl,
        _http = httpClient ?? http.Client();

  void dispose() => _http.close();

  Never _unreachable(Object e) {
    throw ApiException(
      'Could not reach the ShopSense backend at $baseUrl. '
      'Make sure the server is running and the base URL is correct.',
    );
  }

  dynamic _decode(http.Response res, String what) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException(
        'Backend error ($what): HTTP ${res.statusCode}.',
      );
    }
    try {
      return json.decode(res.body);
    } catch (_) {
      throw ApiException('Backend returned an unreadable response ($what).');
    }
  }

  List<Product> _parseResults(dynamic decoded) {
    final results = (decoded as Map<String, dynamic>)['results'];
    if (results is! List) return [];
    return results
        .whereType<Map<String, dynamic>>()
        .map(Product.fromJson)
        .toList();
  }

  // ----------------------------------------------------------
  // Search
  // ----------------------------------------------------------

  /// POST /search/text  {query} -> {query, analysis, count, results}
  Future<TextSearchResponse> textSearch(String query) async {
    final uri = Uri.parse('$baseUrl/search/text');
    late http.Response res;
    try {
      res = await _http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'query': query}),
          )
          .timeout(ApiConstants.requestTimeout);
    } on TimeoutException {
      throw const ApiException('Search timed out. Please try again.');
    } on SocketException catch (e) {
      _unreachable(e);
    } on http.ClientException catch (e) {
      _unreachable(e);
    }

    final decoded = _decode(res, 'text search') as Map<String, dynamic>;
    return TextSearchResponse(
      query: decoded['query']?.toString() ?? query,
      translatedQuery:
          (decoded['analysis'] as Map<String, dynamic>?)?['translated_query']
              ?.toString(),
      products: _parseResults(decoded),
    );
  }

  /// POST /search/image  multipart(file) -> {query, count, results}
  Future<List<Product>> imageSearch(XFile image) async {
    final uri = Uri.parse('$baseUrl/search/image');
    try {
      final request = http.MultipartRequest('POST', uri);
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          await image.readAsBytes(),
          filename: image.name.isNotEmpty ? image.name : 'query.jpg',
        ),
      );
      final streamed = await request.send().timeout(
            ApiConstants.uploadTimeout,
          );
      final res = await http.Response.fromStream(streamed);
      return _parseResults(_decode(res, 'image search'));
    } on TimeoutException {
      throw const ApiException('Image search timed out. Please try again.');
    } on SocketException catch (e) {
      _unreachable(e);
    } on http.ClientException catch (e) {
      _unreachable(e);
    }
  }

  /// POST /search/hybrid  multipart(file, query) -> {query, analysis, count, results}
  Future<List<Product>> hybridSearch(XFile image, String query) async {
    final uri = Uri.parse('$baseUrl/search/hybrid');
    try {
      final request = http.MultipartRequest('POST', uri)
        ..fields['query'] = query;
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          await image.readAsBytes(),
          filename: image.name.isNotEmpty ? image.name : 'query.jpg',
        ),
      );
      final streamed = await request.send().timeout(
            ApiConstants.uploadTimeout,
          );
      final res = await http.Response.fromStream(streamed);
      return _parseResults(_decode(res, 'hybrid search'));
    } on TimeoutException {
      throw const ApiException('Hybrid search timed out. Please try again.');
    } on SocketException catch (e) {
      _unreachable(e);
    } on http.ClientException catch (e) {
      _unreachable(e);
    }
  }

  // ----------------------------------------------------------
  // Catalog
  // ----------------------------------------------------------

  /// GET /products/?limit= -> {count, products}
  Future<List<Product>> getProducts({int limit = 20}) async {
    final uri = Uri.parse('$baseUrl/products/').replace(
      queryParameters: {'limit': limit.toString()},
    );
    late http.Response res;
    try {
      res = await _http.get(uri).timeout(ApiConstants.requestTimeout);
    } on TimeoutException {
      throw const ApiException('Could not load the catalog. Please try again.');
    } on SocketException catch (e) {
      _unreachable(e);
    } on http.ClientException catch (e) {
      _unreachable(e);
    }

    final decoded = _decode(res, 'product catalog') as Map<String, dynamic>;
    final products = decoded['products'];
    if (products is! List) return [];
    return products
        .whereType<Map<String, dynamic>>()
        .map(Product.fromJson)
        .toList();
  }

  /// GET /products/{id} -> product JSON or {"error": ...}
  Future<Product?> getProduct(String id) async {
    final uri = Uri.parse('$baseUrl/products/${Uri.encodeComponent(id)}');
    late http.Response res;
    try {
      res = await _http.get(uri).timeout(ApiConstants.requestTimeout);
    } on TimeoutException {
      throw const ApiException('Could not load the product. Please try again.');
    } on SocketException catch (e) {
      _unreachable(e);
    } on http.ClientException catch (e) {
      _unreachable(e);
    }

    final decoded = _decode(res, 'product detail');
    if (decoded is Map<String, dynamic> && decoded.containsKey('error')) {
      return null;
    }
    return Product.fromJson(decoded as Map<String, dynamic>);
  }

  // ----------------------------------------------------------
  // Price comparison
  // ----------------------------------------------------------

  /// POST /search/comparison/text {query} ->
  /// {query, translated_query, was_translated, comparison}
  Future<ComparisonResponse> compareText(String query) async {
    final uri = Uri.parse('$baseUrl/search/comparison/text');
    late http.Response res;
    try {
      res = await _http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'query': query}),
          )
          .timeout(ApiConstants.uploadTimeout);
    } on TimeoutException {
      throw const ApiException('Price comparison timed out. Please try again.');
    } on SocketException catch (e) {
      _unreachable(e);
    } on http.ClientException catch (e) {
      _unreachable(e);
    }

    final decoded = _decode(res, 'price comparison') as Map<String, dynamic>;
    return ComparisonResponse.fromJson(decoded, fallbackQuery: query);
  }

  /// POST /search/comparison/image multipart(file) ->
  /// {matched_product, comparison} or {error}
  Future<ComparisonResponse> compareImage(XFile image) async {
    final uri = Uri.parse('$baseUrl/search/comparison/image');
    try {
      final request = http.MultipartRequest('POST', uri);
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          await image.readAsBytes(),
          filename: image.name.isNotEmpty ? image.name : 'query.jpg',
        ),
      );
      final streamed = await request.send().timeout(
            ApiConstants.uploadTimeout,
          );
      final res = await http.Response.fromStream(streamed);
      final decoded = _decode(res, 'image price comparison');
      return ComparisonResponse.fromJson(
        decoded as Map<String, dynamic>,
        fallbackQuery: '',
      );
    } on TimeoutException {
      throw const ApiException('Price comparison timed out. Please try again.');
    } on SocketException catch (e) {
      _unreachable(e);
    } on http.ClientException catch (e) {
      _unreachable(e);
    }
  }
}

/// Result of POST /search/text.
class TextSearchResponse {
  final String query;
  final String? translatedQuery;
  final List<Product> products;

  const TextSearchResponse({
    required this.query,
    this.translatedQuery,
    required this.products,
  });
}

/// One row of the side-by-side price comparison.
class PriceOffer {
  final String platform;
  final double? price;
  final String? currency;
  final String? url;
  final String? title;

  const PriceOffer({
    required this.platform,
    this.price,
    this.currency,
    this.url,
    this.title,
  });

  factory PriceOffer.fromJson(Map<String, dynamic> json) {
    double? toDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    return PriceOffer(
      platform: json['platform']?.toString() ?? 'Unknown',
      price: toDouble(json['price']),
      currency: json['currency']?.toString(),
      url: json['url']?.toString(),
      title: json['title']?.toString(),
    );
  }

  String get displayPrice {
    if (price == null) return '—';
    final rounded = price!.round().toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
    return '${currency ?? 'PKR'} $rounded';
  }
}

/// Result of the price-comparison endpoints.
class ComparisonResponse {
  final String query;
  final String? translatedQuery;
  final bool wasTranslated;
  final Map<String, dynamic>? matchedProduct;
  final List<PriceOffer> offers;
  final double? minPrice;
  final double? maxPrice;
  final String? bestPlatform;
  final String? error;

  const ComparisonResponse({
    required this.query,
    this.translatedQuery,
    this.wasTranslated = false,
    this.matchedProduct,
    required this.offers,
    this.minPrice,
    this.maxPrice,
    this.bestPlatform,
    this.error,
  });

  factory ComparisonResponse.fromJson(
    Map<String, dynamic> json, {
    required String fallbackQuery,
  }) {
    if (json['error'] != null) {
      return ComparisonResponse(
        query: fallbackQuery,
        offers: const [],
        error: json['error'].toString(),
      );
    }

    final comparison = json['comparison'] as Map<String, dynamic>? ?? {};
    final prices = comparison['prices'];
    final offers = <PriceOffer>[];
    if (prices is List) {
      for (final p in prices.whereType<Map<String, dynamic>>()) {
        offers.add(PriceOffer.fromJson(p));
      }
    }

    final spread = comparison['spread'] as Map<String, dynamic>?;
    double? toDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    final best = comparison['best'] as Map<String, dynamic>?;

    return ComparisonResponse(
      query: json['query']?.toString() ?? fallbackQuery,
      translatedQuery: json['translated_query']?.toString(),
      wasTranslated: json['was_translated'] == true,
      matchedProduct: json['matched_product'] as Map<String, dynamic>?,
      offers: offers,
      minPrice: toDouble(spread?['min']),
      maxPrice: toDouble(spread?['max']),
      bestPlatform: best?['platform']?.toString(),
    );
  }
}
