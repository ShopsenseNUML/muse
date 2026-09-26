import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shopsense/core/constants/sizes.dart';
import 'package:shopsense/core/theme/app_theme.dart';
import 'package:shopsense/core/providers/theme_provider.dart';
import 'package:shopsense/core/providers/auth_provider.dart';
import 'package:shopsense/core/providers/product_provider.dart';
import 'package:shopsense/features/saved/saved_screen.dart';
import 'package:shopsense/features/history/history_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final productProvider = Provider.of<ProductProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              themeProvider.toggleTheme();
            },
            tooltip: 'Toggle Theme',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        child: Column(
          children: [
            // Profile Header
            Container(
              padding: const EdgeInsets.all(AppSizes.paddingLarge),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [
                          AppTheme.darkPrimaryColor,
                          AppTheme.darkPrimaryColor.withValues(alpha: 0.7),
                        ]
                      : [
                          AppTheme.lightPrimaryColor,
                          AppTheme.lightPrimaryColor.withValues(alpha: 0.7),
                        ],
                ),
                borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: isDark
                        ? AppTheme.darkSurfaceColor
                        : Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: isDark
                          ? AppTheme.darkPrimaryColor
                          : AppTheme.lightPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: AppSizes.paddingMedium),
                  Text(
                    authProvider.isAuthenticated
                        ? authProvider.displayName
                        : 'Guest User',
                    style: TextStyle(
                      color: isDark
                          ? AppTheme.darkTextPrimaryColor
                          : Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    authProvider.isAuthenticated
                        ? (authProvider.userEmail ?? '')
                        : 'Not logged in',
                    style: TextStyle(
                      color: isDark
                          ? AppTheme.darkTextSecondaryColor
                          : Colors.white70,
                    ),
                  ),
                  if (!authProvider.isAuthenticated) ...[
                    const SizedBox(height: AppSizes.paddingMedium),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/login');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.lightPrimaryColor,
                      ),
                      child: const Text('Login'),
                    ),
                  ],
                  const SizedBox(height: AppSizes.paddingMedium),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        context,
                        '${productProvider.savedProducts.length}',
                        'Saved Items',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SavedScreen(),
                          ),
                        ),
                      ),
                      _buildStatItem(
                        context,
                        '${productProvider.searchHistory.length}',
                        'Searches',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HistoryScreen(),
                          ),
                        ),
                      ),
                      _buildStatItem(
                        context,
                        '${productProvider.products.length}',
                        'Products',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.paddingLarge),

            // Menu Items
            _buildMenuItem(context, 'Saved Items', Icons.favorite, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SavedScreen()),
              );
            }),
            _buildMenuItem(
              context,
              'Search History',
              Icons.history,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistoryScreen()),
              ),
            ),
            _buildMenuItem(
              context,
              'Theme',
              isDark ? Icons.light_mode : Icons.dark_mode,
              () {
                themeProvider.toggleTheme();
              },
              trailing: Text(
                isDark ? 'Dark' : 'Light',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
              ),
            ),
            _buildMenuItem(
              context,
              'Language',
              Icons.language,
              () => _showLanguageSheet(context),
              trailing: Text(
                'English + Roman Urdu',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
              ),
            ),
            _buildMenuItem(
              context,
              'Help & Support',
              Icons.help,
              () => _showHelpSheet(context),
            ),
            _buildMenuItem(
              context,
              'About ShopSense',
              Icons.info_outline,
              () => _showAboutDialog(context),
            ),
            const SizedBox(height: AppSizes.paddingMedium),

            // Logout Button
            if (authProvider.isAuthenticated)
              OutlinedButton.icon(
                onPressed: () {
                  _showLogoutDialog(context);
                },
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.red),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String value,
    String label, {
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final content = Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: isDark ? AppTheme.darkTextPrimaryColor : Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: isDark ? AppTheme.darkTextSecondaryColor : Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
    if (onTap == null) return content;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: content,
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap, {
    Widget? trailing,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingSmall),
      child: ListTile(
        leading: Icon(
          icon,
          color: isDark
              ? AppTheme.darkPrimaryColor
              : AppTheme.lightPrimaryColor,
        ),
        title: Text(title),
        trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  void _showLanguageSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingLarge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Language',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'ShopSense understands both English and Roman Urdu. '
                'Try searching for "sasta mobile", "joota", or "kapray" — '
                'your query is translated automatically before searching.',
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: const Text('English + Roman Urdu'),
                subtitle: const Text('Automatic detection and translation'),
                contentPadding: EdgeInsets.zero,
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHelpSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingLarge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Help & Support',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _helpItem(
                context,
                'How does visual search work?',
                'Take a photo or pick one from your gallery. ShopSense compares '
                    'it against the product catalog using AI image embeddings '
                    'and shows the most similar items.',
              ),
              _helpItem(
                context,
                'Can I search in Roman Urdu?',
                'Yes! Type queries like "sasta smart watch" and ShopSense '
                    'translates them to English automatically.',
              ),
              _helpItem(
                context,
                'How do price comparisons work?',
                'Open the Compare tab, enter a product name, and ShopSense '
                    'checks prices across Pakistani platforms like Daraz, '
                    'Telemart, and Shophive side by side.',
              ),
              _helpItem(
                context,
                'Where are my saved items stored?',
                'On this device only. Logging out does not delete them.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _helpItem(BuildContext context, String question, String answer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            answer,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).hintColor,
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About ShopSense'),
        content: const Text(
          'ShopSense is an AI-powered visual search and price intelligence '
          'app for Pakistani e-commerce.\n\n'
          'Snap a photo to find similar products, search in Roman Urdu, '
          'and compare prices across platforms.\n\n'
          'Version 0.1.0 — NUML Final Year Project.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Provider.of<AuthProvider>(context, listen: false).logout();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
