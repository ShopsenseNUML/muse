import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shopsense/features/auth/login_screen.dart';
import 'package:shopsense/features/compare/compare_screen.dart';
import 'package:shopsense/features/history/history_screen.dart';
import 'package:shopsense/features/home/home_screen.dart';
import 'package:shopsense/features/profile/profile_screen.dart';
import 'package:shopsense/features/results/product_detail.dart';
import 'package:shopsense/features/results/results_screen.dart';
import 'package:shopsense/features/search/search_screen.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/splash_screen.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/search_provider.dart';
import 'core/providers/product_provider.dart';
import 'core/providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(ShopSenseApp(prefs: prefs));
}

class ShopSenseApp extends StatelessWidget {
  final SharedPreferences prefs;
  const ShopSenseApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider(prefs)),
        ChangeNotifierProvider(create: (_) => AuthProvider(prefs)),
        ChangeNotifierProvider(create: (_) => SearchProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'ShopSense',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.themeMode == ThemeMode.light
                ? AppTheme.lightTheme
                : AppTheme.darkTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const SplashScreen(),
            routes: {
              '/home': (context) => const HomeScreen(),
              '/search': (context) => const SearchScreen(),
              '/compare': (context) {
                final args = ModalRoute.of(context)?.settings.arguments;
                return CompareScreen(query: args is String ? args : null);
              },
              '/history': (context) => const HistoryScreen(),
              '/profile': (context) => const ProfileScreen(),
              '/results': (context) =>
                  const ResultsScreen(isImageSearch: false),
              '/product-detail': (context) {
                final args = ModalRoute.of(context)?.settings.arguments;
                return ProductDetailScreen(
                  product: args is Map<String, dynamic> ? args : null,
                );
              },
              '/login': (context) => const LoginScreen(),
            },
          );
        },
      ),
    );
  }
}
