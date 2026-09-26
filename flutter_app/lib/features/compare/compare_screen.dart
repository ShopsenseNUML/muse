import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shopsense/core/constants/sizes.dart';
import 'package:shopsense/core/theme/app_theme.dart';
import 'package:shopsense/core/widgets/primary_button.dart';
import 'package:shopsense/core/services/api_client.dart';

/// Side-by-side price comparison backed by the live backend
/// (`POST /search/comparison/text`).
///
/// Opens with an optional [query] (e.g. the product title from the
/// detail screen); the user can also type a product name directly.
class CompareScreen extends StatefulWidget {
  final String? query;

  const CompareScreen({super.key, this.query});

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  final ApiClient _api = ApiClient();
  final TextEditingController _queryController = TextEditingController();

  bool _isLoading = false;
  String? _error;
  ComparisonResponse? _comparison;

  @override
  void initState() {
    super.initState();
    if (widget.query != null && widget.query!.trim().isNotEmpty) {
      _queryController.text = widget.query!.trim();
      _runComparison(widget.query!.trim());
    }
  }

  @override
  void dispose() {
    _queryController.dispose();
    _api.dispose();
    super.dispose();
  }

  Future<void> _runComparison(String query) async {
    if (query.trim().isEmpty) return;
    setState(() {
      _isLoading = true;
      _error = null;
      _comparison = null;
    });
    try {
      final result = await _api.compareText(query.trim());
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (result.error != null) {
          _error = result.error;
        } else {
          _comparison = result;
        }
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.message;
      });
    }
  }

  Color _platformColor(String platform) {
    switch (platform.toLowerCase()) {
      case 'daraz':
        return Colors.blue;
      case 'telemart':
        return Colors.orange;
      case 'shophive':
        return Colors.purple;
      default:
        return Colors.teal;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compare Prices'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        children: [
          // Query input
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _queryController,
                  decoration: const InputDecoration(
                    hintText: 'Product name to compare...',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  onSubmitted: _runComparison,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed:
                    _isLoading ? null : () => _runComparison(_queryController.text),
                child: _isLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Compare'),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.paddingMedium),

          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_error != null)
            _buildError()
          else if (_comparison == null)
            _buildEmptyHint()
          else ...[
            if (_comparison!.wasTranslated &&
                _comparison!.translatedQuery != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Translated: "${_comparison!.translatedQuery}"',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.amber[700],
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ),
            _buildTableHeader(context),
            ..._comparison!.offers.map(
              (offer) => _buildComparisonItem(
                context,
                offer,
                offer.platform == _comparison!.bestPlatform,
              ),
            ),
            if (_comparison!.offers.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'No offers found for "${_comparison!.query}".',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
            const SizedBox(height: AppSizes.paddingLarge),
            if (_comparison!.bestPlatform != null) _buildBestDealCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyHint() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.compare_arrows,
              size: 56,
              color: Theme.of(context).hintColor,
            ),
            const SizedBox(height: 12),
            Text(
              'Enter a product name to compare prices across platforms.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).hintColor,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 56, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              text: 'Retry',
              onPressed: () => _runComparison(_queryController.text),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      decoration: const BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusMedium),
        ),
      ),
      child: const Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              'Platform',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'Price',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(width: 80),
        ],
      ),
    );
  }

  Widget _buildComparisonItem(
    BuildContext context,
    PriceOffer offer,
    bool isBestPrice,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _platformColor(offer.platform),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSizes.paddingSmall),
                Expanded(
                  child: Text(
                    offer.platform,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    offer.displayPrice,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isBestPrice ? AppTheme.successColor : null,
                      fontSize: isBestPrice ? 18 : 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isBestPrice) ...[
                  const SizedBox(width: AppSizes.paddingSmall),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.successColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'BEST',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(
            width: 70,
            child: OutlinedButton(
              onPressed: offer.url == null
                  ? null
                  : () {
                      Clipboard.setData(ClipboardData(text: offer.url!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Product link copied to clipboard.'),
                        ),
                      );
                    },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                side: const BorderSide(color: AppTheme.primaryColor),
              ),
              child: const Text(
                'View',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBestDealCard() {
    final best = _comparison!.offers.firstWhere(
      (o) => o.platform == _comparison!.bestPlatform,
      orElse: () => _comparison!.offers.first,
    );
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingLarge),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.successColor,
            AppTheme.successColor.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.check_circle,
            color: Colors.white,
            size: 40,
          ),
          const SizedBox(height: AppSizes.paddingSmall),
          Text(
            'Best Deal',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            '${best.platform} offers the best price at ${best.displayPrice}',
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
