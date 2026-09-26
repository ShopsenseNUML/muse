import 'package:flutter/material.dart';
import 'package:shopsense/core/constants/sizes.dart';
import 'package:shopsense/core/theme/app_theme.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              // TODO: Implement clear history
              _showClearHistoryDialog(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search History List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSizes.paddingMedium),
              itemCount: 5,
              itemBuilder: (context, index) {
                return _buildHistoryItem(
                  context,
                  'Premium Cotton Kurta Shalwar',
                  DateTime.now().subtract(Duration(hours: index + 1)),
                  'PKR 2,499',
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(
    BuildContext context,
    String product,
    DateTime date,
    String price,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingMedium),
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
            ),
            child: const Icon(
              Icons.image,
              color: Colors.grey,
            ),
          ),
          const SizedBox(width: AppSizes.paddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Searched ${_timeAgo(date)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  price,
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, size: 16),
            onPressed: () {
              Navigator.pushNamed(context, '/product-detail');
            },
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime date) {
    final difference = DateTime.now().difference(date);
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _showClearHistoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text(
          'Are you sure you want to clear all search history?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement clear history
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
