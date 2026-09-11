import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../core/theme/app_colors/app_colors.dart';
import '../../core/theme/app_style/app_style.dart';

/// Presents a premium promotion card as a modal overlay.
///
/// Reusable for any local asset or network promotion image.
Future<void> showPromotionAdsModal(
  BuildContext context, {
  required String imagePath,
  bool barrierDismissible = true,
  bool useRootNavigator = true,
}) {
  return showGeneralDialog<void>(
    context: context,
    useRootNavigator: useRootNavigator,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withValues(alpha: 0.62),
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return PromotionAdsModal(
        imagePath: imagePath,
        onClose: () => Navigator.of(dialogContext).pop(),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.92, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// Centered promotion card — image only + minimal close control.
class PromotionAdsModal extends StatelessWidget {
  const PromotionAdsModal({
    super.key,
    required this.imagePath,
    required this.onClose,
  });

  final String imagePath;
  final VoidCallback onClose;

  bool get _isNetwork => imagePath.startsWith('http');

  Widget _buildImage() {
    if (_isNetwork) {
      return Image.network(
        imagePath,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) => const _ImageFallback(),
      );
    }
    return Image.asset(
      imagePath,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, __, ___) => const _ImageFallback(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final maxWidth = (size.width - 40).clamp(260.0, 440.0);
    final maxHeight = (size.height - padding.vertical - 48).clamp(280.0, 640.0);

    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: maxWidth,
                maxHeight: maxHeight,
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Promotion card
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppStyle.borderRadiusXl,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.28),
                          blurRadius: 28,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: AppStyle.borderRadiusXl,
                      child: _buildImage(),
                    ),
                  ),
                  // Close — elegant, visible, no CTA buttons
                  Positioned(
                    top: 10,
                    right: 10,
                    child: _CloseButton(onPressed: onClose),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.42),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        overlayColor: WidgetStateProperty.all(
          Colors.white.withValues(alpha: 0.12),
        ),
        child: const SizedBox(
          width: 32,
          height: 32,
          child: Icon(
            LucideIcons.x,
            size: 16,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 280,
      height: 160,
      child: ColoredBox(
        color: AppColors.primarySoft,
        child: Center(
          child: Icon(
            LucideIcons.image_off,
            color: AppColors.primary,
            size: 28,
          ),
        ),
      ),
    );
  }
}
