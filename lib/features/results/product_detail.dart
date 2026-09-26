import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:shopsense/core/constants/sizes.dart';
import 'package:shopsense/core/theme/app_theme.dart';
import 'package:shopsense/core/widgets/primary_button.dart';
import 'package:shopsense/features/compare/compare_screen.dart';

class ProductDetailScreen extends StatelessWidget {
  final Map<String, dynamic>? product;

  const ProductDetailScreen({super.key, this.product});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    // Use provided product or fallback to default
    final displayProduct = product ??
        {
          'id': 1,
          'name': 'Premium Cotton Kurta Shalwar',
          'price': 2499,
          'originalPrice': 3999,
          'category': 'Clothing',
          'source': 'Daraz',
          'rating': 4.5,
          'imageUrl':
              'https://via.placeholder.com/600x400/6C63FF/FFFFFF?text=Product',
          'description':
              'This premium cotton kurta shalwar features traditional embroidery with modern design. Made from high-quality fabric, perfect for casual and formal occasions.',
          'brand': 'Premium Wear',
          'fabric': 'Cotton',
          'color': 'White, Blue, Black',
          'size': 'S, M, L, XL, XXL',
          'occasion': 'Casual, Formal',
        };

    return Scaffold(
      backgroundColor:
          isDark ? AppTheme.darkBackgroundStart : AppTheme.lightBackgroundColor,
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
                            AppTheme.darkSurfaceColor.withOpacity(0.8),
                            AppTheme.darkBackgroundStart,
                          ]
                        : [
                            AppTheme.lightPrimaryColor.withOpacity(0.1),
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
                                color: AppTheme.darkCardShadowColor
                                    .withOpacity(0.4),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: AppTheme.lightCardShadowColor
                                    .withOpacity(0.08),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        displayProduct['imageUrl'],
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
                  Icons.favorite_border,
                  color: isDark
                      ? AppTheme.darkTextPrimaryColor
                      : AppTheme.lightTextPrimaryColor,
                ),
                onPressed: () {},
              ),
              IconButton(
                icon: Icon(
                  Icons.share,
                  color: isDark
                      ? AppTheme.darkTextPrimaryColor
                      : AppTheme.lightTextPrimaryColor,
                ),
                onPressed: () {},
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.darkSurfaceColor.withOpacity(0.6)
                    : AppTheme.lightSurfaceColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? AppTheme.darkDividerColor.withOpacity(0.3)
                        : AppTheme.lightDividerColor.withOpacity(0.5),
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    displayProduct['name'],
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: screenWidth < 600 ? 20 : 24,
                        ),
                  ),
                  const SizedBox(height: 8),
                  // Rating
                  Row(
                    children: [
                      RatingBarIndicator(
                        rating: (displayProduct['rating'] as num?)
                                ?.toDouble() ??
                            0.0,
                        itemBuilder: (context, index) => const Icon(
                          Icons.star,
                          color: AppTheme.lightWarningColor,
                        ),
                        itemCount: 5,
                        itemSize: 20,
                        direction: Axis.horizontal,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${displayProduct['rating'] ?? 'No rating'} (120 reviews)',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isDark
                                  ? AppTheme.darkTextSecondaryColor
                                  : AppTheme.lightTextSecondaryColor,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Price
                  Row(
                    children: [
                      Text(
                        'PKR ${(displayProduct['price'] as num?)?.round() ?? 0}',
                        style:
                            Theme.of(context).textTheme.displayMedium?.copyWith(
                                  color: isDark
                                      ? AppTheme.darkPrimaryColor
                                      : AppTheme.lightPrimaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: screenWidth < 600 ? 24 : 28,
                                ),
                      ),
                      if (displayProduct['originalPrice'] != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          'PKR ${displayProduct['originalPrice']}',
                          style: TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: isDark
                                ? AppTheme.darkTextHintColor
                                : AppTheme.lightTextHintColor,
                            fontSize: screenWidth < 600 ? 14 : 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.lightSuccessColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '37% OFF',
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
                  // Buttons with Glass effect in dark mode
                  Container(
                    decoration: isDark
                        ? BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.darkDividerColor.withOpacity(0.3),
                            ),
                          )
                        : null,
                    child: Column(
                      children: [
                        PrimaryButton(
                          text: 'Buy Now on ${displayProduct['source']}',
                          icon: Icons.shopping_bag,
                          onPressed: () {},
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
                                  query: displayProduct['name']?.toString(),
                                ),
                              ),
                            );
                          },
                          isOutlined: true,
                        ),
                      ],
                    ),
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
                    displayProduct['description'] ?? 'No description available',
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
                          ? AppTheme.darkSurfaceColor.withOpacity(0.3)
                          : AppTheme.lightBackgroundColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? AppTheme.darkDividerColor.withOpacity(0.3)
                            : AppTheme.lightDividerColor.withOpacity(0.5),
                      ),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      children: [
                        _buildSpecItem(
                            'Brand', displayProduct['brand'] ?? 'N/A', isDark),
                        _buildDivider(isDark),
                        _buildSpecItem('Fabric',
                            displayProduct['fabric'] ?? 'N/A', isDark),
                        _buildDivider(isDark),
                        _buildSpecItem(
                            'Color', displayProduct['color'] ?? 'N/A', isDark),
                        _buildDivider(isDark),
                        _buildSpecItem(
                            'Size', displayProduct['size'] ?? 'N/A', isDark),
                        _buildDivider(isDark),
                        _buildSpecItem('Occasion',
                            displayProduct['occasion'] ?? 'N/A', isDark),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Similar Products
                  Text(
                    'Similar Products',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontSize: screenWidth < 600 ? 16 : 18,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 220,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildSimilarProduct('PKR 1,999', '4.0', isDark),
                        _buildSimilarProduct('PKR 2,199', '4.2', isDark),
                        _buildSimilarProduct('PKR 2,899', '4.8', isDark),
                        _buildSimilarProduct('PKR 1,799', '3.9', isDark),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
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
          ? AppTheme.darkDividerColor.withOpacity(0.3)
          : AppTheme.lightDividerColor.withOpacity(0.5),
    );
  }

  Widget _buildSimilarProduct(String price, String rating, bool isDark) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.darkSurfaceColor.withOpacity(0.4)
            : AppTheme.lightSurfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? AppTheme.darkDividerColor.withOpacity(0.3)
              : AppTheme.lightDividerColor.withOpacity(0.5),
        ),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: AppTheme.darkCardShadowColor.withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: AppTheme.lightCardShadowColor.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurfaceColor : Colors.grey[200],
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.image,
                  size: 40,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Product Name',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppTheme.darkTextSecondaryColor
                        : AppTheme.lightTextSecondaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  price,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isDark
                        ? AppTheme.darkPrimaryColor
                        : AppTheme.lightPrimaryColor,
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.star,
                        size: 12, color: AppTheme.lightWarningColor),
                    const SizedBox(width: 2),
                    Text(
                      rating,
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark
                            ? AppTheme.darkTextSecondaryColor
                            : AppTheme.lightTextSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
