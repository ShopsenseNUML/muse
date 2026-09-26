import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shopsense/core/constants/sizes.dart';
import 'package:shopsense/core/providers/product_provider.dart';
import 'package:shopsense/core/widgets/product_card.dart';
import 'package:shopsense/features/results/product_detail.dart';

/// Wishlist, backed by [ProductProvider.savedProducts] (local to the device).
class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final saved = productProvider.savedProducts;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Items'),
        actions: [
          if (saved.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Clear all saved items',
              onPressed: () => _showClearSavedDialog(context, productProvider),
            ),
        ],
      ),
      body: saved.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 64,
                    color: Theme.of(context).hintColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No saved items yet',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the heart icon on any product to save it here',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).hintColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(AppSizes.paddingMedium),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppSizes.paddingMedium,
                mainAxisSpacing: AppSizes.paddingMedium,
                childAspectRatio: 0.72,
              ),
              itemCount: saved.length,
              itemBuilder: (context, index) {
                final product = saved[index];
                final productId = product['id'].toString();
                return ProductCard(
                  productId: productId,
                  imageUrl: (product['imageUrl'] ?? '').toString(),
                  title: (product['name'] ?? 'Untitled').toString(),
                  price: 'PKR ${(product['price'] as num?)?.round() ?? 0}',
                  source: (product['source'] ?? '').toString().isEmpty
                      ? null
                      : product['source'].toString(),
                  rating: (product['rating'] as num?)?.toDouble(),
                  isSaved: true,
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
                    productProvider.toggleSavedProduct(productId, product);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Removed from saved items.'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  void _showClearSavedDialog(
    BuildContext context,
    ProductProvider productProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Saved Items'),
        content: const Text('Are you sure you want to remove all saved items?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              productProvider.clearSavedProducts();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Saved items cleared.')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
