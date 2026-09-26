import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shopsense/core/constants/sizes.dart';
import 'package:shopsense/core/constants/strings.dart';
import 'package:shopsense/core/providers/theme_provider.dart';
import 'package:shopsense/core/theme/app_theme.dart';
import 'package:shopsense/core/widgets/custom_textfield.dart';
import 'package:shopsense/core/widgets/product_card.dart';
import 'package:shopsense/core/providers/product_provider.dart';
import 'package:shopsense/core/providers/search_provider.dart';

/// Visual + text search backed by the live backend.
///
/// Text queries go to `POST /search/text` (with Roman Urdu translation),
/// images to `POST /search/image`, and image + query to `POST /search/hybrid`.
/// The picked image is previewed with a clear button; results carry
/// similarity badges for visual searches.
class SearchScreen extends StatefulWidget {
  /// When set, the screen runs a text search for this query on open
  /// (used by the history screen's "search again" flow).
  final String? initialQuery;

  const SearchScreen({super.key, this.initialQuery});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  final ImagePicker _picker = ImagePicker();
  List<Map<String, dynamic>> _searchResults = [];
  bool _hasSearched = false;
  bool _isLoading = false;
  bool _lastWasImageSearch = false;
  String? _translatedQuery;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
      // Run after the first frame so providers are available.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _performSearch(
          Provider.of<SearchProvider>(context, listen: false),
          Provider.of<ProductProvider>(context, listen: false),
        );
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final productProvider = Provider.of<ProductProvider>(context);
    final searchProvider = Provider.of<SearchProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Products'),
        backgroundColor: isDark
            ? AppTheme.darkBackgroundColor
            : AppTheme.lightPrimaryColor,
        foregroundColor: isDark ? AppTheme.darkTextPrimaryColor : Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
            },
            tooltip: 'Toggle theme',
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
                              _translatedQuery = null;
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
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusMedium,
                          ),
                        ),
                        padding: const EdgeInsets.all(AppSizes.paddingMedium),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
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
                // Translation chip (Roman Urdu -> English)
                if (_translatedQuery != null && _translatedQuery!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.translate,
                          size: 14,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Translated: "$_translatedQuery"',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.amber[700],
                              fontStyle: FontStyle.italic,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          // Image picker row + picked-image preview
          Padding(
            padding: const EdgeInsets.all(AppSizes.paddingMedium),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _pickImageFromCamera,
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
                        onPressed: _isLoading ? null : _pickImageFromGallery,
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Gallery'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_selectedImage != null) ...[
                  const SizedBox(height: AppSizes.paddingSmall),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(
                        AppSizes.radiusMedium,
                      ),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusSmall,
                          ),
                          child: _selectedImageBytes == null
                              ? Container(
                                  height: 56,
                                  width: 56,
                                  color: Colors.grey[300],
                                  child: const Icon(
                                    Icons.image,
                                    color: Colors.grey,
                                  ),
                                )
                              : Image.memory(
                                  _selectedImageBytes!,
                                  height: 56,
                                  width: 56,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    height: 56,
                                    width: 56,
                                    color: Colors.grey[300],
                                    child: const Icon(
                                      Icons.image,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Image selected — searching for visually similar products',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          tooltip: 'Remove image',
                          onPressed: () {
                            setState(() {
                              _selectedImage = null;
                              _selectedImageBytes = null;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Results
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _hasSearched
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
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Try different keywords or use image search',
                                style: Theme.of(context).textTheme.bodyMedium
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
                                crossAxisCount: 2,
                                crossAxisSpacing: AppSizes.paddingSmall,
                                mainAxisSpacing: AppSizes.paddingSmall,
                                childAspectRatio: 0.72,
                              ),
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final product = _searchResults[index];
                            return Stack(
                              children: [
                                ProductCard(
                                  productId: product['id'].toString(),
                                  imageUrl: (product['imageUrl'] ?? '')
                                      .toString(),
                                  title: (product['name'] ?? 'Untitled')
                                      .toString(),
                                  price:
                                      'PKR ${(product['price'] as num?)?.round() ?? 0}',
                                  source:
                                      (product['source'] ?? '')
                                          .toString()
                                          .isEmpty
                                      ? null
                                      : product['source'].toString(),
                                  rating: (product['rating'] as num?)
                                      ?.toDouble(),
                                  isSaved: productProvider.isProductSaved(
                                    product['id'].toString(),
                                  ),
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/product-detail',
                                      arguments: product,
                                    );
                                  },
                                  onSaveTap: () {
                                    productProvider.toggleSavedProduct(
                                      product['id'].toString(),
                                      product,
                                    );
                                  },
                                ),
                                // Similarity badge for visual searches
                                if (_lastWasImageSearch &&
                                    product['similarity'] is num)
                                  Positioned(
                                    top: 8,
                                    left: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.lightAccentColor,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${((product['similarity'] as num).toDouble() * 100).round()}% match',
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        )
                : _buildIdleState(context, searchProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildIdleState(BuildContext context, SearchProvider searchProvider) {
    final recent = searchProvider.recentSearches;
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Theme.of(context).hintColor),
            const SizedBox(height: 16),
            Text(
              'Search for products',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Type a product name or upload an image',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).hintColor,
              ),
            ),
            if (recent.isNotEmpty) ...[
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent searches',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    TextButton(
                      onPressed: searchProvider.clearRecentSearches,
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  children: recent
                      .map(
                        (q) => ActionChip(
                          label: Text(q),
                          avatar: const Icon(Icons.history, size: 16),
                          onPressed: () {
                            _searchController.text = q;
                            _performSearch(
                              searchProvider,
                              Provider.of<ProductProvider>(
                                context,
                                listen: false,
                              ),
                            );
                          },
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _performSearch(
    SearchProvider searchProvider,
    ProductProvider productProvider,
  ) async {
    if (_searchController.text.isNotEmpty) {
      setState(() {
        _isLoading = true;
      });

      final query = _searchController.text.trim();

      // Image + text -> hybrid; image only is handled by the picker flow.
      if (_selectedImage != null) {
        await _performImageSearch(_selectedImage!, query);
        return;
      }

      await searchProvider.searchText(query);

      if (!mounted) return;

      if (searchProvider.errorMessage != null) {
        setState(() {
          _searchResults = [];
          _hasSearched = true;
          _isLoading = false;
          _translatedQuery = null;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(searchProvider.errorMessage!)));
        return;
      }

      setState(() {
        _searchResults = ProductProvider.toUiMaps(searchProvider.results);
        _hasSearched = true;
        _isLoading = false;
        _lastWasImageSearch = false;
        final translated = searchProvider.translatedQuery;
        _translatedQuery =
            (translated != null &&
                translated.toLowerCase() != query.toLowerCase())
            ? translated
            : null;
      });

      if (_searchResults.isNotEmpty) {
        productProvider.addSearchHistory(query);
      }
    } else if (_selectedImage != null) {
      await _performImageSearch(_selectedImage!, '');
    }
  }

  Future<void> _pickImageFromCamera() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedImage = image;
        _selectedImageBytes = bytes;
      });
      _performImageSearch(image, _searchController.text.trim());
    }
  }

  Future<void> _pickImageFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedImage = image;
        _selectedImageBytes = bytes;
      });
      _performImageSearch(image, _searchController.text.trim());
    }
  }

  Future<void> _performImageSearch(XFile image, String query) async {
    setState(() {
      _isLoading = true;
    });

    final searchProvider = Provider.of<SearchProvider>(context, listen: false);
    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );

    // If the user also typed a query, use hybrid (image + text) search.
    if (query.isNotEmpty) {
      await searchProvider.searchHybrid(image, query);
    } else {
      await searchProvider.searchImage(image);
    }

    if (!mounted) return;

    if (searchProvider.errorMessage != null) {
      setState(() {
        _searchResults = [];
        _hasSearched = true;
        _isLoading = false;
        _translatedQuery = null;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(searchProvider.errorMessage!)));
      return;
    }

    setState(() {
      _searchResults = ProductProvider.toUiMaps(searchProvider.results);
      _hasSearched = true;
      _isLoading = false;
      _lastWasImageSearch = true;
      _translatedQuery = null;
    });

    if (_searchResults.isNotEmpty && query.isNotEmpty) {
      productProvider.addSearchHistory(query);
    }
  }
}
