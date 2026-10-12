import 'dart:math' as math;
import 'dart:ui';
import 'package:cg_net_mobile/models/advertisement_model/advertisement_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../core/theme/app_colors/app_colors.dart';
import '../../core/theme/app_style/app_style.dart';

/// Presents a promotion / notice card as a modal overlay.
Future<void> showPromotionAdsModal(
  BuildContext context, {
  required List<Advertisement> images,
  bool barrierDismissible = true,
  bool useRootNavigator = true,
}) {
  return showGeneralDialog<void>(
    context: context,
    useRootNavigator: useRootNavigator,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withValues(alpha: 0.62),
    transitionDuration: const Duration(milliseconds: 380),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return PromotionAdsModal(
        images: images,
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
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -0.12),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// Centered ad image with close pinned inside the top-right of the image.
class PromotionAdsModal extends StatefulWidget {
  const PromotionAdsModal({
    super.key,
    required this.images,
    required this.onClose,
  });

  final List<Advertisement> images;
  final VoidCallback onClose;

  @override
  State<PromotionAdsModal> createState() => _PromotionAdsModalState();
}

class _PromotionAdsModalState extends State<PromotionAdsModal> {
  int _currentIndex = 0;

  String get imagePath => widget.images[_currentIndex].image;

  void _showNextOrClose() {
    if (_currentIndex < widget.images.length - 1) {
      setState(() => _currentIndex++);
    } else {
      widget.onClose();
    }
  }

  Widget _buildImage() {
    if (imagePath.startsWith('http')) {
      return Image.network(
        imagePath,
        key: ValueKey(imagePath),
        fit: BoxFit.cover,
        alignment: Alignment.center,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) => const _ImageFallback(),
      );
    }

    return Image.asset(
      imagePath,
      key: ValueKey(imagePath),
      fit: BoxFit.cover,
      alignment: Alignment.center,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, __, ___) => const _ImageFallback(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final availableWidth = size.width - 40;
    final availableHeight = size.height - padding.vertical - 24;
    final imageHeight = math.min(
      450.0,
      math.min(availableHeight, availableWidth * 250 / 200),
    );
    final imageWidth = imageHeight * 200 / 250;

    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: SizedBox(
              width: imageWidth,
              height: imageHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: AppStyle.borderRadiusXl,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.32),
                      blurRadius: 28,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: AppStyle.borderRadiusXl,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Transform.scale(
                        scale: 1.02,
                        child: _buildImage(),
                      ),
                      if (widget.images.length > 1)
                        Positioned(
                          bottom: 30,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              widget.images.length,
                              (index) => AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 3),
                                width: index == _currentIndex ? 16 : 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(
                                    alpha: index == _currentIndex ? 1 : 0.55,
                                  ),
                                  borderRadius: BorderRadius.circular(99),
                                ),
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: _CloseButton(onPressed: _showNextOrClose),
                      ),
                    ],
                  ),
                ),
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

  static const double _size = 30;
  static const double _radius = 5;
  static const Color _iconColor = Color(0xFF000000);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(_radius),
        overlayColor: WidgetStateProperty.all(
          Colors.white.withValues(alpha: 0.18),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_radius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              width: _size,
              height: _size,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(_radius),
                color: AppColors.primaryLight.withValues(alpha: 0.42),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.35),
                  width: 0.5,
                ),
              ),
              alignment: Alignment.center,
              child: const Icon(
                LucideIcons.x,
                size: 20,
                color: _iconColor,
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
      child: SizedBox(
        width: 200,
        height: 240,
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
