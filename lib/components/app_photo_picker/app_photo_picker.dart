import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_colors/app_colors.dart';
import '../../core/theme/app_style/app_style.dart';
import '../../core/theme/app_theme/app_theme.dart';

/// Reusable photo picker component supporting camera/gallery picking,
/// image previews, deletion badges, and max limit.
class AppPhotoPicker extends StatelessWidget {
  const AppPhotoPicker({
    super.key,
    required this.selectedPhotos,
    required this.onPickImage,
    required this.onRemovePhoto,
    this.label,
    this.maxPhotos = 3,
  });

  final List<XFile> selectedPhotos;
  final VoidCallback onPickImage;
  final ValueChanged<int> onRemovePhoto;
  final String? label;
  final int maxPhotos;

  @override
  Widget build(BuildContext context) {
    final titleLabel = label ?? context.tr('failure_report.upload_photos');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titleLabel,
          style: AppTheme.english(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: AppStyle.spaceSm),
        Row(
          children: [
            for (int i = 0; i < maxPhotos; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(
                child: i < selectedPhotos.length
                    ? Stack(
                        clipBehavior: Clip.none,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              height: 72,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.primary),
                              ),
                              child: Image.file(
                                File(selectedPhotos[i].path),
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Center(
                                  child: Icon(
                                    LucideIcons.image,
                                    color: AppColors.primary,
                                    size: 28,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: -6,
                            right: -6,
                            child: InkWell(
                              onTap: () => onRemovePhoto(i),
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  color: AppColors.error,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  LucideIcons.x,
                                  size: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : InkWell(
                        onTap: onPickImage,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          height: 72,
                          decoration: BoxDecoration(
                            color: AppColors.backgroundAlt,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.border,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                LucideIcons.camera,
                                color: AppColors.textMuted,
                                size: 22,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${i + 1}/$maxPhotos',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textMuted,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
