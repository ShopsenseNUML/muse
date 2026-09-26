import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:shopsense/core/theme/app_theme.dart';
import 'package:shopsense/core/widgets/shimmer_loader.dart';

class ProductCard extends StatefulWidget {
  final String imageUrl;
  final String title;
  final String price;
  final String? source;
  final double? rating;
  final VoidCallback? onTap;
  final VoidCallback? onSaveTap;
  final bool isSaved;
  final String productId;

  const ProductCard({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.price,
    this.source,
    this.rating,
    this.onTap,
    this.onSaveTap,
    this.isSaved = false,
    required this.productId,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1200;

    // Responsive image height
    double imageHeight = isMobile ? 160 : (isTablet ? 180 : 200);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        transform: _isHovered && !isMobile
            ? Matrix4.translationValues(0, -4, 0)
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: isDark
              ? AppTheme.darkSurfaceColor.withValues(alpha: 0.6)
              : AppTheme.lightSurfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? AppTheme.darkDividerColor.withValues(
                    alpha: _isHovered ? 0.6 : 0.3,
                  )
                : AppTheme.lightDividerColor.withValues(
                    alpha: _isHovered ? 0.3 : 0.05,
                  ),
            width: 1,
          ),
          boxShadow: isDark
              ? [
                  BoxShadow(
                    color: AppTheme.darkCardShadowColor.withValues(alpha: 0.4),
                    blurRadius: 32,
                    offset: const Offset(0, 8),
                  ),
                  if (_isHovered)
                    BoxShadow(
                      color: AppTheme.darkPrimaryColor.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 0),
                    ),
                ]
              : [
                  BoxShadow(
                    color: AppTheme.lightCardShadowColor.withValues(
                      alpha: 0.05,
                    ),
                    blurRadius: 25,
                    offset: const Offset(0, 10),
                  ),
                  if (_isHovered)
                    BoxShadow(
                      color: AppTheme.lightCardShadowColor.withValues(
                        alpha: 0.08,
                      ),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                ],
        ),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image with Glassmorphism effect in dark mode
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Stack(
                  children: [
                    CachedNetworkImage(
                      imageUrl: widget.imageUrl,
                      height: imageHeight,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => ShimmerLoader(
                        height: imageHeight,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: imageHeight,
                        color: isDark
                            ? AppTheme.darkSurfaceColor
                            : Colors.grey[200],
                        child: Icon(
                          Icons.image_not_supported,
                          color: isDark
                              ? AppTheme.darkTextHintColor
                              : Colors.grey[400],
                          size: 40,
                        ),
                      ),
                    ),
                    // Glass overlay in dark mode
                    if (isDark)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.transparent,
                                AppTheme.darkSurfaceColor.withValues(
                                  alpha: 0.3,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    // Platform Badge
                    if (widget.source != null)
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppTheme.darkSurfaceColor.withValues(
                                    alpha: 0.8,
                                  )
                                : Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(6),
                            border: isDark
                                ? Border.all(
                                    color: AppTheme.darkDividerColor.withValues(
                                      alpha: 0.3,
                                    ),
                                  )
                                : null,
                            backgroundBlendMode: isDark
                                ? BlendMode.srcOver
                                : null,
                          ),
                          child: Text(
                            widget.source!,
                            style: TextStyle(
                              color: isDark
                                  ? AppTheme.darkTextPrimaryColor
                                  : Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    // Save Button with glass effect in dark mode
                    Positioned(
                      top: 8,
                      right: 8,
                      child: MouseRegion(
                        child: GestureDetector(
                          onTap: () {
                            // Saving is local to the device — no login needed.
                            widget.onSaveTap?.call();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppTheme.darkSurfaceColor.withValues(
                                      alpha: 0.6,
                                    )
                                  : Colors.white.withValues(alpha: 0.9),
                              shape: BoxShape.circle,
                              border: isDark
                                  ? Border.all(
                                      color: AppTheme.darkDividerColor
                                          .withValues(alpha: 0.3),
                                    )
                                  : null,
                              boxShadow: isDark
                                  ? [
                                      BoxShadow(
                                        color: AppTheme.darkCardShadowColor
                                            .withValues(alpha: 0.3),
                                        blurRadius: 8,
                                      ),
                                    ]
                                  : [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.05,
                                        ),
                                        blurRadius: 8,
                                      ),
                                    ],
                            ),
                            child: Icon(
                              widget.isSaved
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: widget.isSaved
                                  ? AppTheme.lightDangerColor
                                  : (isDark
                                        ? AppTheme.darkTextSecondaryColor
                                        : Colors.grey[600]),
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Details with proper spacing
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      widget.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                        fontSize: isMobile ? 12 : 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Rating
                    if (widget.rating != null) ...[
                      Row(
                        children: [
                          RatingBarIndicator(
                            rating: widget.rating!,
                            itemBuilder: (context, index) => Icon(
                              Icons.star,
                              color: AppTheme.lightWarningColor,
                              size: isMobile ? 12 : 13,
                            ),
                            itemCount: 5,
                            itemSize: isMobile ? 12 : 13,
                            direction: Axis.horizontal,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.rating!.toStringAsFixed(1),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  fontSize: isMobile ? 10 : 11,
                                  color: isDark
                                      ? AppTheme.darkTextSecondaryColor
                                      : AppTheme.lightTextSecondaryColor,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                    // Price and Stock
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            widget.price,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: isDark
                                      ? AppTheme.darkPrimaryColor
                                      : AppTheme.lightPrimaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: isMobile ? 14 : 16,
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
