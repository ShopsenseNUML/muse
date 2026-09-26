import 'package:flutter/material.dart';
import 'package:shopsense/core/constants/sizes.dart';
import 'package:shopsense/core/theme/app_theme.dart';
import 'package:shopsense/core/widgets/primary_button.dart';

class UploadCard extends StatelessWidget {
  final VoidCallback? onCameraTap;
  final VoidCallback? onGalleryTap;
  final String? imagePath;

  const UploadCard({
    super.key,
    this.onCameraTap,
    this.onGalleryTap,
    this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingLarge),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          if (imagePath != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
              child: Image.asset(
                imagePath!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: AppSizes.paddingMedium),
          ] else ...[
            Container(
              height: 120,
              width: 120,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.photo_camera,
                size: 48,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: AppSizes.paddingMedium),
            Text(
              'Upload Product Image',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppSizes.paddingSmall),
            Text(
              'Take a photo or choose from gallery',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).hintColor,
                  ),
            ),
          ],
          const SizedBox(height: AppSizes.paddingLarge),
          Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  text: 'Camera',
                  icon: Icons.camera_alt,
                  onPressed: onCameraTap,
                  isOutlined: true,
                ),
              ),
              const SizedBox(width: AppSizes.paddingMedium),
              Expanded(
                child: PrimaryButton(
                  text: 'Gallery',
                  icon: Icons.photo_library,
                  onPressed: onGalleryTap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
