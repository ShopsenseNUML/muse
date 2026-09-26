import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shopsense/core/constants/sizes.dart';

class ShimmerLoader extends StatelessWidget {
  final double? height;
  final double? width;
  final BorderRadius? borderRadius;

  const ShimmerLoader({super.key, this.height, this.width, this.borderRadius});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
      child: Container(
        height: height,
        width: width ?? double.infinity,
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[800] : Colors.white,
          borderRadius:
              borderRadius ?? BorderRadius.circular(AppSizes.radiusMedium),
        ),
      ),
    );
  }
}
