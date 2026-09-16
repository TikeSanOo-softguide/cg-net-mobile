import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names/route_names.dart';
import '../../../../core/theme/app_colors/app_colors.dart';
import '../../../../core/theme/app_style/app_style.dart';
import '../../../../core/theme/app_theme/app_theme.dart';

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

  /// Tighter gap between package images.
  static const _gap = 4.0;

  @override
  Widget build(BuildContext context) {
    final locale = context.locale.languageCode;
    final screenWidth = MediaQuery.sizeOf(context).width;
    // Same content width as Services [AppCard] (pagePaddingH both sides).
    final contentWidth = screenWidth - (AppStyle.spaceLg * 2);
    // Slightly smaller cards; ~2 visible inside content width.
    final cardWidth = ((contentWidth - _gap) / 2.35).clamp(100.0, 148.0);
    final imageHeight = cardWidth * 1.12;
    final slideHeight = imageHeight + 40;

    return Padding(
      key: ValueKey('offers-$locale'),
      padding: AppStyle.pagePaddingH,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.tr('home.special_offers'),
                  style: AppTheme.sectionTitle(),
                ),
              ),
              InkWell(
                onTap: () => context.goNamed(RouteNames.packageList),
                borderRadius: AppStyle.borderRadiusSm,
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
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
          const SizedBox(height: AppStyle.spaceSm),
          // Clip sides — radius 14.
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
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
                  return _PackageImageCard(
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

class _PackageImageCard extends StatelessWidget {
  const _PackageImageCard({
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: width,
            height: imageHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFE8E8FF),
                  Color(0xFFF7F8FF),
                  Color(0xFFFFF8E8),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            padding: const EdgeInsets.all(3),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const ColoredBox(color: AppColors.primarySoft),
                  Image.asset(
                    imagePath,
                    fit: BoxFit.cover,
                    alignment: const Alignment(0, -0.12),
                    filterQuality: FilterQuality.high,
                    gaplessPlayback: true,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.primaryLight,
                      alignment: Alignment.center,
                      child: const Icon(
                        LucideIcons.image_off,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x00000000),
                          Color(0x00000000),
                          Color(0x220100CA),
                        ],
                        stops: [0.0, 0.55, 1.0],
                      ),
                    ),
                  ),
                  const Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 36,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0x33FFFFFF),
                            Color(0x00FFFFFF),
                          ],
                        ),
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
          const SizedBox(height: AppStyle.spaceSm),
          _BuyNowButton(
            onTap: () => context.pushNamed(
              RouteNames.packageDetail,
              pathParameters: {'id': id},
            ),
          ),
        ],
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
      padding: const EdgeInsets.fromLTRB(8, 5, 10, 5),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_coral, _coralDeep],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(11),
          bottomRight: Radius.circular(10),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        context.tr('home.popular'),
        style: AppTheme.captionSm(color: Colors.white).copyWith(
          fontWeight: FontWeight.w800,
          fontSize: 9,
          letterSpacing: 0.6,
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
    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        splashColor: Colors.white.withValues(alpha: 0.15),
        highlightColor: Colors.white.withValues(alpha: 0.06),
        child: SizedBox(
          height: 28,
          width: double.infinity,
          child: Center(
            child: Text(
              context.tr('home.buy_now'),
              style: AppTheme.captionSm(color: AppColors.onPrimary).copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 11,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
