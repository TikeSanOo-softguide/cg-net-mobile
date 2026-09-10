import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../../core/theme/app_colors/app_colors.dart';
import '../../../../core/theme/app_style/app_style.dart';
import '../../../../core/theme/app_theme/app_theme.dart';

class HomeOffersSection extends StatelessWidget {
  const HomeOffersSection({super.key});

  static const _packages = [
    _OfferPackage(
      imagePath: 'assets/images/packages/package_1m.png',
      popular: true,
    ),
    _OfferPackage(
      imagePath: 'assets/images/packages/package_3m.png',
    ),
    _OfferPackage(
      imagePath: 'assets/images/packages/package_6m.png',
      popular: true,
    ),
    _OfferPackage(
      imagePath: 'assets/images/packages/package_1y.png',
    ),
  ];

  // Native package art size (260 x 360).
  static const _imageAspect = 260 / 360;

  @override
  Widget build(BuildContext context) {
    final locale = context.locale.languageCode;
    const gap = AppStyle.spaceMd;
    const cardWidth = 118.0;
    final imageHeight = cardWidth / _imageAspect;
    final slideHeight = imageHeight + 36;

    return Column(
      key: ValueKey('offers-$locale'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: AppStyle.pagePaddingH,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  context.tr('home.special_offers'),
                  style: AppTheme.sectionTitle(),
                ),
              ),
              InkWell(
                onTap: () {},
                borderRadius: AppStyle.borderRadiusSm,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppStyle.spaceXs,
                    vertical: AppStyle.spaceXs,
                  ),
                  child: Text(
                    context.tr('home.see_all'),
                    style: AppTheme.caption(
                      color: AppColors.primary,
                      weight: FontWeight.w500,
                    ).copyWith(fontSize: 10),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppStyle.spaceMd),
        Padding(
          padding: AppStyle.pagePaddingH,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppStyle.borderRadiusLg,
              border: Border.all(color: AppColors.borderLight),
              boxShadow: AppStyle.cardShadow,
            ),
            padding: const EdgeInsets.symmetric(
              vertical: AppStyle.spaceMd,
            ),
            child: SizedBox(
              height: slideHeight,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppStyle.spaceMd,
                ),
                scrollDirection: Axis.horizontal,
                itemCount: _packages.length,
                separatorBuilder: (_, __) => const SizedBox(width: gap),
                itemBuilder: (context, index) {
                  final package = _packages[index];
                  return _PackageImageCard(
                    imagePath: package.imagePath,
                    width: cardWidth,
                    imageHeight: imageHeight,
                    popular: package.popular,
                    locale: locale,
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _OfferPackage {
  const _OfferPackage({
    required this.imagePath,
    this.popular = false,
  });

  final String imagePath;
  final bool popular;
}

class _PackageImageCard extends StatelessWidget {
  const _PackageImageCard({
    required this.imagePath,
    required this.width,
    required this.imageHeight,
    required this.popular,
    required this.locale,
  });

  final String imagePath;
  final double width;
  final double imageHeight;
  final bool popular;
  final String locale;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: ValueKey('package-$imagePath-$locale'),
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: width,
            height: imageHeight,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: AppStyle.borderRadiusMd,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.primaryLight,
                    alignment: Alignment.center,
                    child: const Icon(
                      LucideIcons.image_off,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                if (popular)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.accent,
                            Color(0xFFFFD54F),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        context.tr('home.popular'),
                        style: AppTheme.captionSm(
                          color: AppColors.onAccent,
                        ).copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 9,
                          letterSpacing: 0.2,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppStyle.spaceSm),
          SizedBox(
            width: double.infinity,
            height: 28,
            child: Material(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(8),
                child: Center(
                  child: Text(
                    context.tr('home.buy_now'),
                    style: AppTheme.captionSm(color: AppColors.onPrimary)
                        .copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
