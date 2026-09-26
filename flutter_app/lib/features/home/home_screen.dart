import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shopsense/core/constants/sizes.dart';
import 'package:shopsense/core/constants/strings.dart';
import 'package:shopsense/core/theme/app_theme.dart';
import 'package:shopsense/core/widgets/product_card.dart';
import 'package:shopsense/features/search/search_screen.dart';
import 'package:shopsense/features/history/history_screen.dart';
import 'package:shopsense/features/profile/profile_screen.dart';
import 'package:shopsense/features/compare/compare_screen.dart';
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

  final List<Widget> _screens = [
    const HomeContent(),
    const SearchScreen(),
    const CompareScreen(),
    const HistoryScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
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
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Clothing',
    'Shoes',
    'Electronics',
    'Fashion',
    'Accessories',
    'Bags',
  ];

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final productProvider = Provider.of<ProductProvider>(context);
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
    final filteredProducts = _selectedCategory == 'All'
        ? productProvider.products
        : productProvider.products
            .where((product) => product['category'] == _selectedCategory)
            .toList();

    return Scaffold(
      backgroundColor:
          isDark ? AppTheme.darkBackgroundStart : AppTheme.lightBackgroundColor,
      appBar: AppBar(
        title: const Text('ShopSense'),
        backgroundColor: isDark
            ? AppTheme.darkBackgroundStart.withOpacity(0.8)
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              Text(
                '${AppStrings.welcome} Guest!',
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
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SearchScreen(),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
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
                              color:
                                  AppTheme.darkCardShadowColor.withOpacity(0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: AppTheme.lightCardShadowColor
                                  .withOpacity(0.05),
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
                          color: (isDark
                                  ? AppTheme.darkPrimaryColor
                                  : AppTheme.lightPrimaryColor)
                              .withOpacity(isDark ? 0.15 : 0.1),
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
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final isSelected = _selectedCategory == category;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(
                          category,
                          style: TextStyle(
                            fontSize: screenWidth < 600 ? 12 : 13,
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategory = selected ? category : 'All';
                          });
                        },
                        backgroundColor: isDark
                            ? AppTheme.darkSurfaceColor.withOpacity(0.4)
                            : AppTheme.lightSurfaceColor,
                        selectedColor: isDark
                            ? AppTheme.darkPrimaryColor.withOpacity(0.2)
                            : AppTheme.lightPrimaryColor.withOpacity(0.1),
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
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                        side: BorderSide(
                          color: isSelected
                              ? (isDark
                                  ? AppTheme.darkPrimaryColor
                                  : AppTheme.lightPrimaryColor)
                              : (isDark
                                  ? AppTheme.darkDividerColor.withOpacity(0.3)
                                  : AppTheme.lightDividerColor
                                      .withOpacity(0.5)),
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
                    price: 'PKR ${product['price'].toString()}',
                    source: product['source'],
                    rating: product['rating'],
                    isSaved: productProvider
                        .isProductSaved(product['id'].toString()),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductDetailScreen(
                            product: product,
                          ),
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
        ),
      ),
    );
  }
}
