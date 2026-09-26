import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shopsense/core/constants/sizes.dart';
import 'package:shopsense/core/theme/app_theme.dart';
import 'package:shopsense/core/providers/theme_provider.dart';
import 'package:shopsense/core/providers/auth_provider.dart';
import 'package:shopsense/features/saved/saved_screen.dart';
import 'package:shopsense/features/history/history_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode : Icons.dark_mode,
            ),
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
                          AppTheme.darkPrimaryColor.withValues(alpha: 0.7)
                        ]
                      : [
                          AppTheme.lightPrimaryColor,
                          AppTheme.lightPrimaryColor.withValues(alpha: 0.7)
                        ],
                ),
                borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor:
                        isDark ? AppTheme.darkSurfaceColor : Colors.white,
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
                    authProvider.isAuthenticated ? 'Ahmad Khan' : 'Guest User',
                    style: TextStyle(
                      color:
                          isDark ? AppTheme.darkTextPrimaryColor : Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    authProvider.isAuthenticated
                        ? 'ahmad@email.com'
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
                      _buildStatItem(context, '12', 'Saved Items'),
                      _buildStatItem(context, '45', 'Searches'),
                      _buildStatItem(context, '3', 'Comparisons'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.paddingLarge),

            // Menu Items
            _buildMenuItem(
              context,
              'Saved Items',
              Icons.favorite,
              () {
                if (!authProvider.isAuthenticated) {
                  _showLoginRequiredDialog(context);
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SavedScreen(),
                    ),
                  );
                }
              },
            ),
            _buildMenuItem(
              context,
              'Search History',
              Icons.history,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HistoryScreen(),
                ),
              ),
            ),
            _buildMenuItem(
              context,
              'Settings',
              Icons.settings,
              () {},
            ),
            _buildMenuItem(
              context,
              'Theme',
              isDark ? Icons.light_mode : Icons.dark_mode,
              () {
                themeProvider.toggleTheme();
              },
            ),
            _buildMenuItem(
              context,
              'Language',
              Icons.language,
              () {},
            ),
            _buildMenuItem(
              context,
              'Help & Support',
              Icons.help,
              () {},
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

  Widget _buildStatItem(BuildContext context, String value, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
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
  }

  Widget _buildMenuItem(
      BuildContext context, String title, IconData icon, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingSmall),
      child: ListTile(
        leading: Icon(
          icon,
          color:
              isDark ? AppTheme.darkPrimaryColor : AppTheme.lightPrimaryColor,
        ),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  void _showLoginRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Login Required'),
        content: const Text(
          'Please login to access this feature.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/login');
            },
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.lightPrimaryColor,
            ),
            child: const Text('Login'),
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
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
