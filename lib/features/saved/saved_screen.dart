import 'package:flutter/material.dart';
import 'package:shopsense/core/constants/sizes.dart';
import 'package:shopsense/core/widgets/product_card.dart';

class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Items'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              // TODO: Implement clear saved items
              _showClearSavedDialog(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Saved Items Grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(AppSizes.paddingMedium),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppSizes.paddingMedium,
                mainAxisSpacing: AppSizes.paddingMedium,
                childAspectRatio: 0.75,
              ),
              itemCount: 8,
              itemBuilder: (context, index) {
                return ProductCard(
                  productId: 'saved-${index + 1}',
                  imageUrl: 'https://via.placeholder.com/300x400',
                  title: 'Saved Product ${index + 1}',
                  price: 'PKR ${(1500 + index * 400).toString()}',
                  source: ['Daraz', 'Shoppers', 'Meesho'][index % 3],
                  rating: 4.0 + (index % 2) * 0.5,
                  isSaved: true,
                  onTap: () {
                    Navigator.pushNamed(context, '/product-detail');
                  },
                  onSaveTap: () {
                    // TODO: Implement remove from saved
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showClearSavedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Saved Items'),
        content: const Text(
          'Are you sure you want to remove all saved items?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement clear saved items
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
