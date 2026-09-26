import 'package:flutter/material.dart';
import 'package:shopsense/core/constants/sizes.dart';
import 'package:shopsense/core/widgets/product_card.dart';
import 'package:shopsense/features/results/product_detail.dart';

class ResultsScreen extends StatelessWidget {
  final String? query;
  final String? imagePath;
  final bool isImageSearch;

  const ResultsScreen({
    super.key,
    this.query,
    this.imagePath,
    required this.isImageSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isImageSearch ? 'Image Results' : 'Results for "$query"'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: Implement filter
            },
          ),
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () {
              // TODO: Implement sort
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Summary
          if (isImageSearch && imagePath != null)
            Container(
              padding: const EdgeInsets.all(AppSizes.paddingMedium),
              margin: const EdgeInsets.all(AppSizes.paddingMedium),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                border: Border.all(
                  color: Theme.of(context).dividerColor,
                ),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                    child: Image.asset(
                      imagePath!,
                      height: 60,
                      width: 60,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: AppSizes.paddingMedium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Searching by image',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          'Found 12 similar products',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),

          // Results Count
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.paddingMedium,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '12 results found',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  'Showing 1-12',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.paddingMedium),

          // Results Grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(AppSizes.paddingMedium),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppSizes.paddingMedium,
                mainAxisSpacing: AppSizes.paddingMedium,
                childAspectRatio: 0.75,
              ),
              itemCount: 12,
              itemBuilder: (context, index) {
                return ProductCard(
                  productId: 'result-${index + 1}',
                  imageUrl: 'https://via.placeholder.com/300x400',
                  title: 'Product ${index + 1}',
                  price: 'PKR ${(1000 + index * 500).toString()}',
                  source: [
                    'Daraz',
                    'Shoppers',
                    'Meesho',
                    'AliExpress'
                  ][index % 4],
                  rating: 4.0 + (index % 2) * 0.5,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProductDetailScreen(),
                      ),
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
