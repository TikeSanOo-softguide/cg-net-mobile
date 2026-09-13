import 'dart:ui';

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

/// Centered promotion card — image framed + floating glass close.
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
        alignment: Alignment.center,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) => const _ImageFallback(),
      );
    }
    return Image.asset(
      imagePath,
      fit: BoxFit.contain,
      alignment: Alignment.center,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, __, ___) => const _ImageFallback(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final maxWidth = (size.width - 48).clamp(260.0, 400.0);
    final maxHeight =
        (size.height - padding.vertical - 72).clamp(280.0, 560.0);

    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        child: Center(
          child: Padding(
            // Keep card visually centered; leave room for floating close.
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: maxWidth,
                maxHeight: maxHeight,
              ),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // Ads image — centered, rounded, soft glow.
                  DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: AppStyle.borderRadiusXl,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.32),
                          blurRadius: 32,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: AppStyle.borderRadiusXl,
                      child: ColoredBox(
                        color: AppColors.surface,
                        child: _buildImage(),
                      ),
                    ),
                  ),
                  // Close — floating top-right outside the card.
                  Positioned(
                    top: -14,
                    right: -10,
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
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        overlayColor: WidgetStateProperty.all(
          Colors.white.withValues(alpha: 0.14),
        ),
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.22),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.55),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const Icon(
                LucideIcons.x,
                size: 16,
                color: Colors.white,
              ),
            ),
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
    return const ColoredBox(
      color: AppColors.primarySoft,
      child: Center(
        child: Icon(
          LucideIcons.image_off,
          color: AppColors.primary,
          size: 28,
        ),
      ),
    );
  }
}
