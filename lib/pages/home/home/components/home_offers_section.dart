import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router/go_router.dart';

import '../../../../components/app_card/app_card.dart';
import '../../../../core/router/route_names/route_names.dart';
import '../../../../core/theme/app_colors/app_colors.dart';
import '../../../../core/theme/app_style/app_style.dart';
import '../../../../core/theme/app_theme/app_theme.dart';
import 'home_section_header.dart';

class HomeOffersSection extends StatelessWidget {
  const HomeOffersSection({super.key});

  static const _packages = [
    _OfferPackage(
      id: '1m',
      imagePath: 'assets/images/packages/package_1m.png',
      popular: true,
    ),
    _OfferPackage(
      id: '3m',
      imagePath: 'assets/images/packages/package_3m.png',
    ),
    _OfferPackage(
      id: '6m',
      imagePath: 'assets/images/packages/package_6m.png',
    ),
    _OfferPackage(
      id: '1y',
      imagePath: 'assets/images/packages/package_1y.png',
    ),
    _OfferPackage(
      id: '1m_extra',
      imagePath: 'assets/images/packages/package_1m.png',
    ),
  ];

  static const _gap = 8.0;
  static const _buttonHeight = 26.0;
  static const _buttonPadH = 6.0;
  static const _buttonPadV = 6.0;

  @override
  Widget build(BuildContext context) {
    final locale = context.locale.languageCode;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final contentWidth = screenWidth - (AppStyle.pageMarginH * 2);
    // Slightly smaller cards — ~3.05 visible.
    final cardWidth = ((contentWidth - _gap) / 3.05).clamp(84.0, 104.0);
    final imageHeight = cardWidth * 1.32;
    // Image + top button pad + button + bottom button pad.
    final slideHeight =
        imageHeight + _buttonPadV + _buttonHeight + _buttonPadV;

    return Padding(
      key: ValueKey('offers-$locale'),
      padding: AppStyle.pagePaddingH,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HomeSectionHeader(
            title: context.tr('home.special_offers'),
            onSeeAll: () => context.goNamed(RouteNames.packageList),
          ),
          SizedBox(
            width: contentWidth,
            height: slideHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: _packages.length,
              separatorBuilder: (_, __) => const SizedBox(width: _gap),
              itemBuilder: (context, index) {
                final package = _packages[index];
                return _PackageOfferCard(
                  id: package.id,
                  imagePath: package.imagePath,
                  width: cardWidth,
                  imageHeight: imageHeight,
                  popular: package.popular,
                  locale: locale,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _OfferPackage {
  const _OfferPackage({
    required this.id,
    required this.imagePath,
    this.popular = false,
  });

  final String id;
  final String imagePath;
  final bool popular;
}

/// Full-bleed cover image + primary Buy now; no top/side padding on the image.
class _PackageOfferCard extends StatelessWidget {
  const _PackageOfferCard({
    required this.id,
    required this.imagePath,
    required this.width,
    required this.imageHeight,
    required this.popular,
    required this.locale,
  });

  final String id;
  final String imagePath;
  final double width;
  final double imageHeight;
  final bool popular;
  final String locale;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: ValueKey('package-$id-$locale'),
      width: width,
      child: AppCard(
        elevated: false,
        bordered: false,
        borderRadius: AppStyle.borderRadiusSm,
        padding: EdgeInsets.zero,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(AppStyle.radiusSm),
              ),
              child: SizedBox(
                width: double.infinity,
                height: imageHeight,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const ColoredBox(color: AppColors.primarySoft),
                    Image.asset(
                      imagePath,
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                      filterQuality: FilterQuality.high,
                      gaplessPlayback: true,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.primaryLight,
                        alignment: Alignment.center,
                        child: const Icon(
                          LucideIcons.image_off,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                    ),
                    if (popular)
                      const Positioned(
                        top: 0,
                        left: 0,
                        child: _PopularCornerBadge(),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                HomeOffersSection._buttonPadH,
                HomeOffersSection._buttonPadV,
                HomeOffersSection._buttonPadH,
                HomeOffersSection._buttonPadV,
              ),
              child: SizedBox(
                height: HomeOffersSection._buttonHeight,
                child: _BuyNowButton(
                  onTap: () => context.pushNamed(
                    RouteNames.packageDetail,
                    pathParameters: {'id': id},
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PopularCornerBadge extends StatelessWidget {
  const _PopularCornerBadge();

  static const _coral = Color(0xFFFF4D6D);
  static const _coralDeep = Color(0xFFE11D48);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 3, 8, 3),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_coral, _coralDeep],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppStyle.radiusSm),
          bottomRight: Radius.circular(8),
        ),
      ),
      child: Text(
        context.tr('home.popular'),
        style: AppTheme.captionSm(color: Colors.white).copyWith(
          fontWeight: FontWeight.w800,
          fontSize: 8,
          letterSpacing: 0.5,
          height: 1.1,
        ),
      ),
    );
  }
}

class _BuyNowButton extends StatelessWidget {
  const _BuyNowButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(6);
    return Material(
      color: AppColors.primary,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        splashColor: Colors.white.withValues(alpha: 0.18),
        highlightColor: Colors.white.withValues(alpha: 0.08),
        child: SizedBox(
          height: 26,
          width: double.infinity,
          child: Center(
            child: Text(
              context.tr('home.buy_now'),
              style: AppTheme.captionSm(color: AppColors.onPrimary).copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 10,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
