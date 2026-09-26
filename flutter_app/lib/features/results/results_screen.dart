import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shopsense/core/constants/sizes.dart';
import 'package:shopsense/core/providers/product_provider.dart';
import 'package:shopsense/core/widgets/product_card.dart';
import 'package:shopsense/features/results/product_detail.dart';

enum _SortOption { relevance, priceLowToHigh, priceHighToLow }

/// Reusable search-results page driven by real data.
///
/// Shows [products] (UI maps from [ProductProvider.toUiMaps]) with working
/// sort (relevance / price ↑ / price ↓) and platform filter chips, plus an
/// optional picked-image header for image searches.
class ResultsScreen extends StatefulWidget {
  final List<Map<String, dynamic>> products;
  final String title;
  final Uint8List? imageBytes;
  final String? translatedQuery;

  const ResultsScreen({
    super.key,
    required this.products,
    required this.title,
    this.imageBytes,
    this.translatedQuery,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  _SortOption _sort = _SortOption.relevance;
  String _platformFilter = 'All';

  List<String> get _platforms {
    final set = <String>{};
    for (final p in widget.products) {
      final source = (p['source'] ?? '').toString();
      if (source.isNotEmpty) set.add(source);
    }
    return ['All', ...set.toList()..sort()];
  }

  List<Map<String, dynamic>> get _visibleProducts {
    var list = widget.products.where((p) {
      if (_platformFilter == 'All') return true;
      return (p['source'] ?? '').toString() == _platformFilter;
    }).toList();
    switch (_sort) {
      case _SortOption.priceLowToHigh:
        list.sort((a, b) => _priceOf(a).compareTo(_priceOf(b)));
        break;
      case _SortOption.priceHighToLow:
        list.sort((a, b) => _priceOf(b).compareTo(_priceOf(a)));
        break;
      case _SortOption.relevance:
        break;
    }
    return list;
  }

  double _priceOf(Map<String, dynamic> p) =>
      (p['price'] as num?)?.toDouble() ?? double.infinity;

  String get _sortLabel {
    switch (_sort) {
      case _SortOption.relevance:
        return 'Relevance';
      case _SortOption.priceLowToHigh:
        return 'Price: Low to High';
      case _SortOption.priceHighToLow:
        return 'Price: High to Low';
    }
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final visible = _visibleProducts;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, overflow: TextOverflow.ellipsis),
        actions: [
          PopupMenuButton<_SortOption>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort',
            initialValue: _sort,
            onSelected: (option) => setState(() => _sort = option),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: _SortOption.relevance,
                child: Text('Relevance'),
              ),
              const PopupMenuItem(
                value: _SortOption.priceLowToHigh,
                child: Text('Price: Low to High'),
              ),
              const PopupMenuItem(
                value: _SortOption.priceHighToLow,
                child: Text('Price: High to Low'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image-search summary header
          if (widget.imageBytes != null)
            Container(
              padding: const EdgeInsets.all(AppSizes.paddingMedium),
              margin: const EdgeInsets.fromLTRB(
                AppSizes.paddingMedium,
                AppSizes.paddingMedium,
                AppSizes.paddingMedium,
                0,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                    child: Image.memory(
                      widget.imageBytes!,
                      height: 60,
                      width: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 60,
                        width: 60,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image, color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSizes.paddingMedium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Searched by image',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          'Found ${widget.products.length} similar products',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Translation note
          if (widget.translatedQuery != null &&
              widget.translatedQuery!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.paddingMedium,
                12,
                AppSizes.paddingMedium,
                0,
              ),
              child: Row(
                children: [
                  const Icon(Icons.translate, size: 16, color: Colors.amber),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Translated: "${widget.translatedQuery}"',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.amber[700],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Platform filter chips
          if (_platforms.length > 2)
            SizedBox(
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.paddingMedium,
                  12,
                  AppSizes.paddingMedium,
                  4,
                ),
                itemCount: _platforms.length,
                itemBuilder: (context, index) {
                  final platform = _platforms[index];
                  final selected = platform == _platformFilter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(platform),
                      selected: selected,
                      onSelected: (_) =>
                          setState(() => _platformFilter = platform),
                    ),
                  );
                },
              ),
            ),

          // Count + active sort
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.paddingMedium,
              vertical: 8,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${visible.length} result${visible.length == 1 ? '' : 's'} found',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  _sortLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),

          // Results grid / empty state
          Expanded(
            child: visible.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Theme.of(context).hintColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No products found',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try a different filter or search again',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Theme.of(context).hintColor),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(AppSizes.paddingMedium),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: AppSizes.paddingMedium,
                          mainAxisSpacing: AppSizes.paddingMedium,
                          childAspectRatio: 0.72,
                        ),
                    itemCount: visible.length,
                    itemBuilder: (context, index) {
                      final product = visible[index];
                      return ProductCard(
                        productId: product['id'].toString(),
                        imageUrl: product['imageUrl'] ?? '',
                        title: product['name'] ?? 'Untitled product',
                        price:
                            'PKR ${(product['price'] as num?)?.round() ?? 0}',
                        source: (product['source'] ?? '').toString().isEmpty
                            ? null
                            : product['source'].toString(),
                        rating: (product['rating'] as num?)?.toDouble(),
                        isSaved: productProvider.isProductSaved(
                          product['id'].toString(),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ProductDetailScreen(product: product),
                            ),
                          );
                        },
                        onSaveTap: () {
                          productProvider.toggleSavedProduct(
                            product['id'].toString(),
                            product,
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
