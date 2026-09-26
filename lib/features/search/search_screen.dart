import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shopsense/core/constants/sizes.dart';
import 'package:shopsense/core/constants/strings.dart';
import 'package:shopsense/core/providers/theme_provider.dart';
import 'package:shopsense/core/theme/app_theme.dart';
import 'package:shopsense/core/widgets/custom_textfield.dart';
import 'package:shopsense/core/widgets/upload_card.dart';
import 'package:shopsense/core/widgets/product_card.dart';
import 'package:shopsense/core/providers/product_provider.dart';
import 'package:shopsense/core/providers/search_provider.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  List<Map<String, dynamic>> _searchResults = [];
  bool _hasSearched = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final productProvider = Provider.of<ProductProvider>(context);
    final searchProvider = Provider.of<SearchProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Products'),
        backgroundColor:
            isDark ? AppTheme.darkBackgroundColor : AppTheme.lightPrimaryColor,
        foregroundColor: isDark ? AppTheme.darkTextPrimaryColor : Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode : Icons.dark_mode,
            ),
            onPressed: () {
              Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Input
          Container(
            padding: const EdgeInsets.all(AppSizes.paddingMedium),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        hint: 'Search products...',
                        controller: _searchController,
                        prefixIcon: const Icon(Icons.search),
                        onEditingComplete: () {
                          _performSearch(searchProvider, productProvider);
                        },
                        onChanged: (value) {
                          if (value.isEmpty && _hasSearched) {
                            setState(() {
                              _searchResults = [];
                              _hasSearched = false;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: AppSizes.paddingSmall),
                    ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              _performSearch(searchProvider, productProvider);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark
                            ? AppTheme.darkPrimaryColor
                            : AppTheme.lightPrimaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusMedium),
                        ),
                        padding: const EdgeInsets.all(AppSizes.paddingMedium),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.search, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.paddingSmall),
                Text(
                  AppStrings.searchRomanUrdu,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.amber[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Image Upload Section
          Padding(
            padding: const EdgeInsets.all(AppSizes.paddingMedium),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickImageFromCamera,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.paddingMedium),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickImageFromGallery,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Results
          Expanded(
            child: _hasSearched
                ? _searchResults.isEmpty
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
                              'Try different keywords or use image search',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context).hintColor,
                                  ),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(AppSizes.paddingSmall),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: AppSizes.paddingSmall,
                          mainAxisSpacing: AppSizes.paddingSmall,
                          childAspectRatio: 0.7,
                        ),
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final product = _searchResults[index];
                          return ProductCard(
                            productId: product['id'].toString(),
                            imageUrl: product['imageUrl'],
                            title: product['name'],
                            price: 'PKR ${product['price'].toString()}',
                            source: product['source'],
                            rating: product['rating'],
                            isSaved: productProvider
                                .isProductSaved(product['id'].toString()),
                            onTap: () {
                              Navigator.pushNamed(context, '/product-detail');
                            },
                            onSaveTap: () {
                              productProvider.toggleSavedProduct(
                                product['id'].toString(),
                                product,
                              );
                            },
                          );
                        },
                      )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search,
                          size: 64,
                          color: Theme.of(context).hintColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Search for products',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Type a product name or upload an image',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).hintColor,
                                  ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _performSearch(
      SearchProvider searchProvider, ProductProvider productProvider) {
    if (_searchController.text.isNotEmpty) {
      setState(() {
        _isLoading = true;
      });

      // Simulate search delay
      Future.delayed(const Duration(milliseconds: 500), () {
        final query = _searchController.text;
        final translatedQuery = searchProvider.translateRomanUrdu(query);
        final results = productProvider.searchProducts(translatedQuery);

        setState(() {
          _searchResults = results;
          _hasSearched = true;
          _isLoading = false;
        });

        if (results.isNotEmpty) {
          searchProvider.addRecentSearch(query);
          productProvider.addSearchHistory(query);
        }
      });
    }
  }

  Future<void> _pickImageFromCamera() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        _selectedImage = image.path;
      });
      _performImageSearch(image.path);
    }
  }

  Future<void> _pickImageFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = image.path;
      });
      _performImageSearch(image.path);
    }
  }

  void _performImageSearch(String imagePath) {
    // Simulate image search with mock results
    setState(() {
      _isLoading = true;
    });

    final productProvider =
        Provider.of<ProductProvider>(context, listen: false);

    Future.delayed(const Duration(seconds: 1), () {
      // Return some random products as image search results
      final allProducts = productProvider.products;
      final randomResults = (allProducts..shuffle()).take(6).toList();

      setState(() {
        _searchResults = randomResults;
        _hasSearched = true;
        _isLoading = false;
      });
    });
  }
}
