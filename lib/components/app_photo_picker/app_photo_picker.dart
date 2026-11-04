import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/utils/image_url_helper.dart';
import '../../core/theme/app_colors/app_colors.dart';
import '../../core/theme/app_theme/app_theme.dart';

/// Reusable photo picker component supporting camera/gallery picking,
/// image previews, deletion badges, and max limit.
class AppPhotoPicker extends StatelessWidget {
  const AppPhotoPicker({
    super.key,
    required this.selectedPhotos,
    required this.onPickImage,
    required this.onRemovePhoto,
    required this.label,
    this.maxPhotos = 3,
  });

  final List<XFile> selectedPhotos;
  final VoidCallback onPickImage;
  final ValueChanged<int> onRemovePhoto;
  final String label;
  final int maxPhotos;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.english(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (int i = 0; i < maxPhotos; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(child: _slot(i)),
            ],
          ],
        ),
      ],
    );
  }

  Widget _slot(int index) {
    const radius = BorderRadius.all(Radius.circular(12));
    if (index < selectedPhotos.length) {
      final path = selectedPhotos[index].path;
      final imageUrl = ImageUrlHelper.resolve({'image_url': path});
      final ImageProvider<Object> image = path.startsWith('http')
          ? NetworkImage(path)
          : path.startsWith('/')
              ? FileImage(File(path))
              : NetworkImage(imageUrl ?? path);
      return SizedBox(
        height: 100,
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: radius,
                child: Image(
                  image: image,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const ColoredBox(
                    color: AppColors.primaryLight,
                    child: Center(
                      child: Icon(
                        LucideIcons.image,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 6,
              right: 6,
              child: Material(
                color: AppColors.surface,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => onRemovePhoto(index),
                  child: const SizedBox(
                    width: 22,
                    height: 22,
                    child: Icon(
                      LucideIcons.x,
                      size: 12,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Material(
      color: AppColors.primarySoft,
      borderRadius: radius,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPickImage,
        child: Container(
          height: 100,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: AppColors.primaryLight),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.camera,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${index + 1}/$maxPhotos',
                style: AppTheme.captionSm(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
