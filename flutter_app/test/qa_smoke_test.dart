/// ShopSense QA smoke tests — full submission-readiness pass.
///
/// These are INTEGRATION tests: they drive the real Flutter UI against the
/// real FastAPI backend (http://127.0.0.1:8000). The backend must be running
/// with a seeded database before running this file:
///   python -m backend.scripts.init_db
///   python -m backend.scripts.seed_sample_products
///   uvicorn backend.main:app --host 127.0.0.1 --port 8000
///
/// IMPORTANT: `testWidgets` runs in a FakeAsync zone where real sockets and
/// timers never complete. Every real network call therefore runs inside
/// `tester.runAsync()` (the real async zone); UI pumping and assertions stay
/// outside it. `HttpOverrides.global = null` is still needed because the
/// test binding otherwise returns fake HTTP 400s.
///
/// They assert real end-to-end behavior (catalog loads, product detail
/// renders, text search returns results, compare screen builds) and would
/// catch any framework "Unexpected null value" style crash during
/// build/layout.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shopsense/core/providers/auth_provider.dart';
import 'package:shopsense/core/providers/product_provider.dart';
import 'package:shopsense/core/providers/search_provider.dart';
import 'package:shopsense/core/providers/theme_provider.dart';
import 'package:shopsense/core/theme/app_theme.dart';
import 'package:shopsense/features/compare/compare_screen.dart';
import 'package:shopsense/features/home/home_screen.dart';
import 'package:shopsense/features/results/product_detail.dart';
import 'package:shopsense/features/search/search_screen.dart';

class _Providers {
  late ThemeProvider theme;
  late AuthProvider auth;
  late SearchProvider search;
  // Set inside tester.runAsync by loadCatalogReal. Never constructed in the
  // fake zone: the constructor auto-starts loadCatalog(), whose HTTP timeout
  // timer would outlive the test and fail the binding's timer invariant.
  ProductProvider? product;
}

/// Creates the real providers. The ProductProvider is NOT created here: its
/// constructor auto-starts loadCatalog(), and real sockets only work inside
/// tester.runAsync. Use loadCatalogReal() instead.
Future<_Providers> makeProviders() async {
  HttpOverrides.global = null; // allow real HTTP to 127.0.0.1:8000
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return _Providers()
    ..theme = ThemeProvider(prefs)
    ..auth = AuthProvider(prefs)
    ..search = SearchProvider();
}

/// Constructs the ProductProvider and loads the catalog over real HTTP.
/// Must be called inside tester.runAsync.
Future<void> loadCatalogReal(_Providers p) async {
  p.product = ProductProvider(); // ctor kicks off loadCatalog()
  await _waitForReal(() => !p.product!.isCatalogLoading);
}

Widget _wrap(_Providers p, Widget child) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: p.theme),
      ChangeNotifierProvider.value(value: p.auth),
      ChangeNotifierProvider.value(value: p.search),
      ChangeNotifierProvider.value(value: p.product!),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: child,
    ),
  );
}

/// Pumps a bounded number of frames. We can't use pumpAndSettle() because
/// product-card image placeholders run an infinite shimmer animation while
/// their (fake-zone) image requests hang.
Future<void> pumpFrames(WidgetTester tester, [int n = 30]) async {
  for (var i = 0; i < n; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Real-time wait (for use INSIDE runAsync only).
Future<void> _waitForReal(
  bool Function() done, {
  Duration timeout = const Duration(seconds: 45),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!done() && DateTime.now().isBefore(deadline)) {
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }
}

void main() {
  testWidgets('Home renders real catalog products without crashing', (
    tester,
  ) async {
    final p = await makeProviders();
    // ProductProvider() starts loadCatalog() in its constructor; construct
    // it in the real zone so the HTTP request can actually complete.
    await tester.runAsync(() => loadCatalogReal(p));
    await tester.pumpWidget(_wrap(p, const HomeScreen()));
    await pumpFrames(tester);

    expect(
      p.product!.catalogError,
      isNull,
      reason: 'catalog failed: ${p.product!.catalogError}',
    );
    expect(
      p.product!.products,
      isNotEmpty,
      reason: 'backend returned no products',
    );

    // Every product title must be rendered as text somewhere.
    for (final prod in p.product!.products) {
      expect(
        find.text(prod['name'].toString(), findRichText: true),
        findsWidgets,
      );
    }
  });

  testWidgets('Product detail renders a real product without crashing', (
    tester,
  ) async {
    final p = await makeProviders();
    await tester.runAsync(() => loadCatalogReal(p));
    expect(p.product!.products, isNotEmpty);
    final product = p.product!.products.first;

    await tester.pumpWidget(_wrap(p, ProductDetailScreen(product: product)));
    await pumpFrames(tester);
    expect(
      find.text(product['name'].toString(), findRichText: true),
      findsWidgets,
    );
    expect(find.textContaining('Buy Now'), findsOneWidget);
  });

  testWidgets('Text search returns real results without crashing', (
    tester,
  ) async {
    final p = await makeProviders();
    await tester.runAsync(() => loadCatalogReal(p));
    await tester.pumpWidget(_wrap(p, const SearchScreen()));
    await tester.pump();

    // Type the query (pure UI, no network yet).
    final field = find.byType(TextField);
    expect(field, findsWidgets);
    await tester.enterText(field.first, 'watch');
    await tester.pump();
    expect(find.text('watch'), findsOneWidget);

    // Tap the search button INSIDE the real async zone, so the screen's
    // _performSearch -> SearchProvider.searchText -> real HTTP all run with
    // real sockets/timers instead of hanging in FakeAsync.
    await tester.runAsync(() async {
      await tester.tap(find.widgetWithIcon(ElevatedButton, Icons.search));
      await _waitForReal(() => !p.search.isSearching);
    });
    await pumpFrames(tester);

    expect(
      p.search.errorMessage,
      isNull,
      reason: 'search failed: ${p.search.errorMessage}',
    );
    expect(p.search.results, isNotEmpty, reason: 'search returned no results');
    // Results render as product cards on the screen.
    expect(find.textContaining('watch', findRichText: true), findsWidgets);
  });

  testWidgets('Compare screen builds without crashing', (tester) async {
    final p = await makeProviders();
    await tester.runAsync(() => loadCatalogReal(p));
    // No query -> no live comparison call; just verifies the screen builds.
    await tester.pumpWidget(_wrap(p, const CompareScreen()));
    await pumpFrames(tester);
    expect(find.text('Compare'), findsWidgets);
  });
}
