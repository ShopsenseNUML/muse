import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shopsense/core/providers/product_provider.dart';
import 'package:shopsense/core/theme/app_theme.dart';
import 'package:shopsense/core/widgets/primary_button.dart';
import 'package:shopsense/core/widgets/product_card.dart';
import 'package:shopsense/features/compare/compare_screen.dart';
import 'package:url_launcher/url_launcher.dart';

/// Full product page backed by real data.
///
/// [product] is a UI map (see [ProductProvider.toUiMaps]). The favorite
/// button toggles the local wishlist, "Buy Now" opens the product URL, the
/// share button shares the listing, and "Similar Products" shows other
/// items from the same category.
class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic>? product;

  const ProductDetailScreen({super.key, this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  Future<void> _openProductUrl(BuildContext context, String? url) async {
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No purchase link is available for this product.'),
        ),
      );
      return;
    }
    final uri = Uri.tryParse(url);
    if (uri == null ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the product link.')),
        );
      }
    }
  }

  void _shareProduct(Map<String, dynamic> product) {
    final name = product['name'] ?? 'Product';
    final price = 'PKR ${(product['price'] as num?)?.round() ?? 0}';
    final url = (product['source_url'] ?? '').toString();
    Share.share(
      'Check out this product on ShopSense!\n\n$name\n$price'
      '${url.isNotEmpty ? '\n$url' : ''}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    if (product == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Product')),
        body: const Center(child: Text('Product not found.')),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final productProvider = Provider.of<ProductProvider>(context);
    final productId = product['id'].toString();
    final isSaved = productProvider.isProductSaved(productId);
    final category = (product['category'] ?? '').toString();
    final similar = category.isEmpty
        ? <Map<String, dynamic>>[]
        : productProvider.products
              .where(
                (p) =>
                    p['category'] == category &&
                    p['id'].toString() != productId,
              )
              .take(8)
              .toList();

    final originalPrice = (product['originalPrice'] as num?)?.toDouble();
    final price = (product['price'] as num?)?.toDouble() ?? 0;
    final discountPct = originalPrice != null && originalPrice > price
        ? ((originalPrice - price) / originalPrice * 100).round()
        : null;

    return Scaffold(
      backgroundColor: isDark
          ? AppTheme.darkBackgroundStart
          : AppTheme.lightBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: screenWidth < 600 ? 250 : 350,
            pinned: true,
            backgroundColor: isDark
                ? AppTheme.darkBackgroundStart
                : AppTheme.lightBackgroundColor,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isDark
                        ? [
                            AppTheme.darkSurfaceColor.withValues(alpha: 0.8),
                            AppTheme.darkBackgroundStart,
                          ]
                        : [
                            AppTheme.lightPrimaryColor.withValues(alpha: 0.1),
                            AppTheme.lightBackgroundColor,
                          ],
                  ),
                ),
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: isDark
                          ? [
                              BoxShadow(
                                color: AppTheme.darkCardShadowColor.withValues(
                                  alpha: 0.4,
                                ),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: AppTheme.lightCardShadowColor.withValues(
                                  alpha: 0.08,
                                ),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        (product['imageUrl'] ?? '').toString(),
                        height: double.infinity,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: isDark
                              ? AppTheme.darkSurfaceColor
                              : Colors.grey[200],
                          child: Icon(
                            Icons.image_not_supported,
                            size: 60,
                            color: isDark
                                ? AppTheme.darkTextHintColor
                                : Colors.grey[400],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  isSaved ? Icons.favorite : Icons.favorite_border,
                  color: isSaved
                      ? AppTheme.lightDangerColor
                      : (isDark
                            ? AppTheme.darkTextPrimaryColor
                            : AppTheme.lightTextPrimaryColor),
                ),
                tooltip: isSaved ? 'Remove from wishlist' : 'Save to wishlist',
                onPressed: () {
                  productProvider.toggleSavedProduct(productId, product);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isSaved
                            ? 'Removed from your wishlist.'
                            : 'Saved to your wishlist.',
                      ),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              ),
              IconButton(
                icon: Icon(
                  Icons.share,
                  color: isDark
                      ? AppTheme.darkTextPrimaryColor
                      : AppTheme.lightTextPrimaryColor,
                ),
                tooltip: 'Share',
                onPressed: () => _shareProduct(product),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.darkSurfaceColor.withValues(alpha: 0.6)
                    : AppTheme.lightSurfaceColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? AppTheme.darkDividerColor.withValues(alpha: 0.3)
                        : AppTheme.lightDividerColor.withValues(alpha: 0.5),
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    (product['name'] ?? 'Untitled product').toString(),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: screenWidth < 600 ? 20 : 24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Source + rating
                  Row(
                    children: [
                      if ((product['source'] ?? '').toString().isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                (isDark
                                        ? AppTheme.darkPrimaryColor
                                        : AppTheme.lightPrimaryColor)
                                    .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            product['source'].toString(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppTheme.darkPrimaryColor
                                  : AppTheme.lightPrimaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if ((product['rating'] as num?) != null) ...[
                        RatingBarIndicator(
                          rating:
                              (product['rating'] as num?)?.toDouble() ?? 0.0,
                          itemBuilder: (context, index) => const Icon(
                            Icons.star,
                            color: AppTheme.lightWarningColor,
                          ),
                          itemCount: 5,
                          itemSize: 18,
                          direction: Axis.horizontal,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          (product['rating'] as num?)!.toStringAsFixed(1),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: isDark
                                    ? AppTheme.darkTextSecondaryColor
                                    : AppTheme.lightTextSecondaryColor,
                              ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Price
                  Row(
                    children: [
                      Text(
                        'PKR ${price.round()}',
                        style: Theme.of(context).textTheme.displayMedium
                            ?.copyWith(
                              color: isDark
                                  ? AppTheme.darkPrimaryColor
                                  : AppTheme.lightPrimaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: screenWidth < 600 ? 24 : 28,
                            ),
                      ),
                      if (originalPrice != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          'PKR ${originalPrice.round()}',
                          style: TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: isDark
                                ? AppTheme.darkTextHintColor
                                : AppTheme.lightTextHintColor,
                            fontSize: screenWidth < 600 ? 14 : 16,
                          ),
                        ),
                      ],
                      if (discountPct != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.lightSuccessColor.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '$discountPct% OFF',
                            style: TextStyle(
                              color: AppTheme.lightSuccessColor,
                              fontWeight: FontWeight.bold,
                              fontSize: screenWidth < 600 ? 10 : 12,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Action buttons
                  Column(
                    children: [
                      PrimaryButton(
                        text:
                            'Buy Now${(product['source'] ?? '').toString().isNotEmpty ? ' on ${product['source']}' : ''}',
                        icon: Icons.shopping_bag,
                        onPressed: () => _openProductUrl(
                          context,
                          (product['source_url'] ?? '').toString(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      PrimaryButton(
                        text: 'Compare Prices',
                        icon: Icons.compare_arrows,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CompareScreen(
                                query: product['name']?.toString(),
                              ),
                            ),
                          );
                        },
                        isOutlined: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Product Details
                  Text(
                    'Product Details',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontSize: screenWidth < 600 ? 16 : 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    (product['description'] ?? '').toString().isNotEmpty
                        ? product['description'].toString()
                        : 'No description available.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.6,
                      color: isDark
                          ? AppTheme.darkTextSecondaryColor
                          : AppTheme.lightTextSecondaryColor,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Specifications
                  Text(
                    'Specifications',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontSize: screenWidth < 600 ? 16 : 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppTheme.darkSurfaceColor.withValues(alpha: 0.3)
                          : AppTheme.lightBackgroundColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? AppTheme.darkDividerColor.withValues(alpha: 0.3)
                            : AppTheme.lightDividerColor.withValues(alpha: 0.5),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Column(
                      children: [
                        _buildSpecItem(
                          'Brand',
                          (product['brand'] ?? '').toString().isNotEmpty
                              ? product['brand'].toString()
                              : 'N/A',
                          isDark,
                        ),
                        _buildDivider(isDark),
                        _buildSpecItem(
                          'Category',
                          (product['category'] ?? '').toString().isNotEmpty
                              ? product['category'].toString()
                              : 'N/A',
                          isDark,
                        ),
                        _buildDivider(isDark),
                        _buildSpecItem(
                          'Platform',
                          (product['source'] ?? '').toString().isNotEmpty
                              ? product['source'].toString()
                              : 'N/A',
                          isDark,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Similar Products (real, from the same category)
                  if (similar.isNotEmpty) ...[
                    Text(
                      'Similar Products',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontSize: screenWidth < 600 ? 16 : 18,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 250,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: similar.length,
                        itemBuilder: (context, index) {
                          final item = similar[index];
                          final itemId = item['id'].toString();
                          return Container(
                            width: 160,
                            margin: const EdgeInsets.only(right: 12),
                            child: ProductCard(
                              productId: itemId,
                              imageUrl: (item['imageUrl'] ?? '').toString(),
                              title: (item['name'] ?? 'Untitled').toString(),
                              price:
                                  'PKR ${(item['price'] as num?)?.round() ?? 0}',
                              source: (item['source'] ?? '').toString(),
                              rating: (item['rating'] as num?)?.toDouble(),
                              isSaved: productProvider.isProductSaved(itemId),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ProductDetailScreen(product: item),
                                  ),
                                );
                              },
                              onSaveTap: () {
                                productProvider.toggleSavedProduct(
                                  itemId,
                                  item,
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecItem(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isDark
                    ? AppTheme.darkTextSecondaryColor
                    : AppTheme.lightTextSecondaryColor,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isDark
                    ? AppTheme.darkTextPrimaryColor
                    : AppTheme.lightTextPrimaryColor,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 0,
      color: isDark
          ? AppTheme.darkDividerColor.withValues(alpha: 0.3)
          : AppTheme.lightDividerColor.withValues(alpha: 0.5),
    );
  }
}
