/// Product as returned by the ShopSense backend.
///
/// Matches the JSON shapes of:
/// * `GET /products/` and `GET /products/{id}`
/// * result items of `POST /search/text`, `/search/image`, `/search/hybrid`
///   (which carry the same product fields plus scoring extras).
class Product {
  final String id;
  final String title;
  final String? brand;
  final String? category;
  final String? description;
  final double? price;
  final String? platform;
  final String? sourceUrl;
  final String? originalImageUrl;
  final String? localImagePath;

  /// Visual similarity / ranking extras present on search results.
  final double? similarity;
  final double? clipScore;
  final double? finalScore;
  final String? matchType;

  const Product({
    required this.id,
    required this.title,
    this.brand,
    this.category,
    this.description,
    this.price,
    this.platform,
    this.sourceUrl,
    this.originalImageUrl,
    this.localImagePath,
    this.similarity,
    this.clipScore,
    this.finalScore,
    this.matchType,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    double? toDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    return Product(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Untitled product',
      brand: json['brand']?.toString(),
      category: json['category']?.toString(),
      description: json['description']?.toString(),
      price: toDouble(json['price']),
      platform: json['platform']?.toString(),
      sourceUrl: json['source_url']?.toString(),
      originalImageUrl: json['original_image_url']?.toString(),
      localImagePath: json['local_image_path']?.toString(),
      similarity: toDouble(json['similarity']),
      clipScore: toDouble(json['clip_score']),
      finalScore: toDouble(json['final_score']),
      matchType: json['match_type']?.toString(),
    );
  }

  /// Best image URL the backend knows about for this product.
  String get displayImageUrl {
    final url = originalImageUrl;
    if (url != null && url.isNotEmpty) return url;
    return '';
  }

  /// Human-readable price, e.g. "PKR 2,499".
  String get displayPrice {
    if (price == null) return 'Price unavailable';
    final rounded = price!.round();
    final withCommas = rounded.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return 'PKR $withCommas';
  }

  /// Map in the shape the existing UI widgets expect
  /// (keys: id, name, price, imageUrl, source, rating, ...).
  ///
  /// This keeps every screen working unchanged while the data now
  /// comes from the backend instead of mock data.
  Map<String, dynamic> toUiMap() {
    return {
      'id': id,
      'name': title,
      'title': title,
      'price': price?.round() ?? 0,
      'brand': brand ?? '',
      'category': category ?? '',
      'description': description ?? '',
      'source': platform ?? '',
      'platform': platform ?? '',
      'imageUrl': displayImageUrl,
      'original_image_url': originalImageUrl ?? '',
      'source_url': sourceUrl ?? '',
      // The backend has no ratings; the UI treats null as "no stars".
      'rating': null,
      'match_type': matchType ?? '',
      'similarity': similarity,
      'final_score': finalScore,
    };
  }
}
