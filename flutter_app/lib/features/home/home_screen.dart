import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shopsense/core/constants/strings.dart';
import 'package:shopsense/core/theme/app_theme.dart';
import 'package:shopsense/core/widgets/product_card.dart';
import 'package:shopsense/core/widgets/shimmer_loader.dart';
import 'package:shopsense/features/search/search_screen.dart';
import 'package:shopsense/features/history/history_screen.dart';
import 'package:shopsense/features/profile/profile_screen.dart';
import 'package:shopsense/features/compare/compare_screen.dart';
import 'package:shopsense/core/providers/auth_provider.dart';
import 'package:shopsense/core/providers/theme_provider.dart';
import 'package:shopsense/core/providers/product_provider.dart';
import 'package:shopsense/features/results/product_detail.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens = [
    HomeContent(onSearchTap: () => setState(() => _currentIndex = 1)),
    const SearchScreen(),
    const CompareScreen(),
    const HistoryScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: Theme.of(context).brightness == Brightness.dark
            ? AppTheme.darkPrimaryColor
            : AppTheme.lightPrimaryColor,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search_outlined),
            activeIcon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.compare_arrows_outlined),
            activeIcon: Icon(Icons.compare_arrows),
            label: 'Compare',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class HomeContent extends StatefulWidget {
  /// Called when the fake search bar is tapped — the parent switches to
  /// the Search tab instead of pushing a duplicate search screen.
  final VoidCallback onSearchTap;

  const HomeContent({super.key, required this.onSearchTap});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  String _selectedCategory = 'All';

  /// Categories derived from the live catalog (always includes 'All').
  List<String> _categoriesOf(List<Map<String, dynamic>> products) {
    final cats = <String>{};
    for (final p in products) {
      final c = (p['category'] ?? '').toString().trim();
      if (c.isNotEmpty) cats.add(c);
    }
    final sorted = cats.toList()..sort();
    return ['All', ...sorted];
  }

  /// "PKR 24,999" style formatting (no intl dependency needed).
  String _formatPrice(num? value) {
    final digits = (value ?? 0).round().toString();
    final withCommas = digits.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
    return 'PKR $withCommas';
  }

  /// Promotional hero for the AI visual search — near-black card with a
  /// lime accent, oversized headline, decorative shapes.
  Widget _buildHeroBanner(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF141414), Color(0xFF2E2E2A)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Decorative lime glow.
            Positioned(
              right: -50,
              top: -50,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.lightAccentColor.withValues(alpha: 0.22),
                ),
              ),
            ),
            // Watermark camera icon.
            const Positioned(
              right: 16,
              bottom: -28,
              child: Icon(
                Icons.camera_alt,
                size: 130,
                color: Color(0x14FFFFFF),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.lightAccentColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'AI VISUAL SEARCH',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Snap it.\nFind it. Compare it.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Point your camera at anything — we\'ll find it and '
                    'compare prices across Pakistan.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: widget.onSearchTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.lightAccentColor,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(180, 46),
                      shape: const StadiumBorder(),
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.camera_alt, size: 18),
                        SizedBox(width: 8),
                        Text('Try Camera Search'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final productProvider = Provider.of<ProductProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive grid settings
    int crossAxisCount = 3; // Default for desktop
    double childAspectRatio = 0.72;
    double crossAxisSpacing = 12;
    double mainAxisSpacing = 12;

    if (screenWidth < 600) {
      crossAxisCount = 2;
      childAspectRatio = 0.75;
      crossAxisSpacing = 8;
      mainAxisSpacing = 8;
    } else if (screenWidth >= 600 && screenWidth < 900) {
      crossAxisCount = 3;
      childAspectRatio = 0.72;
      crossAxisSpacing = 10;
      mainAxisSpacing = 10;
    }

    // Get filtered products based on category
    final categories = _categoriesOf(productProvider.products);
    if (!categories.contains(_selectedCategory)) {
      _selectedCategory = 'All';
    }
    final filteredProducts = _selectedCategory == 'All'
        ? productProvider.products
        : productProvider.products
              .where((product) => product['category'] == _selectedCategory)
              .toList();

    return Scaffold(
      backgroundColor: isDark
          ? AppTheme.darkBackgroundStart
          : AppTheme.lightBackgroundColor,
      appBar: AppBar(
        title: const Text('ShopSense'),
        backgroundColor: isDark
            ? AppTheme.darkBackgroundStart.withValues(alpha: 0.8)
            : AppTheme.lightBackgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode : Icons.dark_mode,
              color: isDark
                  ? AppTheme.darkTextPrimaryColor
                  : AppTheme.lightTextPrimaryColor,
            ),
            onPressed: () {
              themeProvider.toggleTheme();
            },
            tooltip: 'Toggle Theme',
          ),
        ],
      ),
      body: Container(
        decoration: isDark
            ? BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.darkBackgroundStart,
                    AppTheme.darkBackgroundEnd,
                  ],
                ),
              )
            : null,
        child: RefreshIndicator(
          onRefresh: () => productProvider.loadCatalog(),
          child: _buildBody(
            context,
            productProvider,
            authProvider,
            isDark,
            screenWidth,
            crossAxisCount,
            childAspectRatio,
            crossAxisSpacing,
            mainAxisSpacing,
            filteredProducts,
            categories,
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ProductProvider productProvider,
    AuthProvider authProvider,
    bool isDark,
    double screenWidth,
    int crossAxisCount,
    double childAspectRatio,
    double crossAxisSpacing,
    double mainAxisSpacing,
    List<Map<String, dynamic>> filteredProducts,
    List<String> categories,
  ) {
    // Loading state — shimmer grid.
    if (productProvider.isCatalogLoading && productProvider.products.isEmpty) {
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: crossAxisSpacing,
          mainAxisSpacing: mainAxisSpacing,
          childAspectRatio: childAspectRatio,
        ),
        itemCount: crossAxisCount * 3,
        itemBuilder: (context, index) => const ShimmerLoader(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      );
    }

    // Error state — retry button.
    if (productProvider.catalogError != null &&
        productProvider.products.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          Icon(Icons.cloud_off, size: 64, color: Theme.of(context).hintColor),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Could not load products',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              productProvider.catalogError!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).hintColor,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton.icon(
              onPressed: () => productProvider.loadCatalog(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ),
        ],
      );
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Section
          Text(
            '${AppStrings.welcome} ${authProvider.isAuthenticated ? authProvider.displayName : 'Guest'}!',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: screenWidth < 600 ? 20 : 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'What would you like to find today?',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? AppTheme.darkTextSecondaryColor
                  : AppTheme.lightTextSecondaryColor,
            ),
          ),
          const SizedBox(height: 16),

          // Search Bar with Glass effect in dark mode
          GestureDetector(
            onTap: widget.onSearchTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.darkSurfaceColor.withValues(alpha: 0.4)
                    : AppTheme.lightSurfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? AppTheme.darkDividerColor.withValues(alpha: 0.3)
                      : AppTheme.lightDividerColor.withValues(alpha: 0.5),
                ),
                boxShadow: isDark
                    ? [
                        BoxShadow(
                          color: AppTheme.darkCardShadowColor.withValues(
                            alpha: 0.3,
                          ),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: AppTheme.lightCardShadowColor.withValues(
                            alpha: 0.05,
                          ),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search,
                    color: isDark
                        ? AppTheme.darkTextHintColor
                        : AppTheme.lightTextHintColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppStrings.searchHint,
                      style: TextStyle(
                        color: isDark
                            ? AppTheme.darkTextHintColor
                            : AppTheme.lightTextHintColor,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color:
                          (isDark
                                  ? AppTheme.darkPrimaryColor
                                  : AppTheme.lightPrimaryColor)
                              .withValues(alpha: isDark ? 0.15 : 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      size: 20,
                      color: isDark
                          ? AppTheme.darkPrimaryColor
                          : AppTheme.lightPrimaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Hero banner — visual search promo (Dribbble-inspired)
          _buildHeroBanner(context),
          const SizedBox(height: 24),

          // Categories
          Text(
            AppStrings.categories,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontSize: screenWidth < 600 ? 16 : 18,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 36,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(
                      category,
                      style: TextStyle(fontSize: screenWidth < 600 ? 12 : 13),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = selected ? category : 'All';
                      });
                    },
                    backgroundColor: isDark
                        ? AppTheme.darkSurfaceColor.withValues(alpha: 0.4)
                        : AppTheme.lightSurfaceColor,
                    selectedColor: isDark
                        ? AppTheme.darkPrimaryColor.withValues(alpha: 0.2)
                        : AppTheme.lightPrimaryColor.withValues(alpha: 0.1),
                    checkmarkColor: isDark
                        ? AppTheme.darkPrimaryColor
                        : AppTheme.lightPrimaryColor,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? (isDark
                                ? AppTheme.darkPrimaryColor
                                : AppTheme.lightPrimaryColor)
                          : (isDark
                                ? AppTheme.darkTextSecondaryColor
                                : AppTheme.lightTextSecondaryColor),
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                    side: BorderSide(
                      color: isSelected
                          ? (isDark
                                ? AppTheme.darkPrimaryColor
                                : AppTheme.lightPrimaryColor)
                          : (isDark
                                ? AppTheme.darkDividerColor.withValues(
                                    alpha: 0.3,
                                  )
                                : AppTheme.lightDividerColor.withValues(
                                    alpha: 0.5,
                                  )),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // Product Grid Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${filteredProducts.length} Products',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppTheme.darkTextSecondaryColor
                      : AppTheme.lightTextSecondaryColor,
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedCategory = 'All';
                  });
                },
                style: TextButton.styleFrom(
                  foregroundColor: isDark
                      ? AppTheme.darkPrimaryColor
                      : AppTheme.lightPrimaryColor,
                ),
                child: Text(
                  AppStrings.viewAll,
                  style: TextStyle(
                    color: isDark
                        ? AppTheme.darkPrimaryColor
                        : AppTheme.lightPrimaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Product Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: crossAxisSpacing,
              mainAxisSpacing: mainAxisSpacing,
              childAspectRatio: childAspectRatio,
            ),
            itemCount: filteredProducts.length,
            itemBuilder: (context, index) {
              final product = filteredProducts[index];
              return ProductCard(
                productId: product['id'].toString(),
                imageUrl: product['imageUrl'],
                title: product['name'],
                price: _formatPrice(product['price'] as num?),
                source: product['source'],
                rating: product['rating'],
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
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
