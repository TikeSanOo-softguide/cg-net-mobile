import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router/go_router.dart';

import '../../../components/app_card/app_card.dart';
import '../../../components/app_curved_scaffold/app_curved_scaffold.dart';
import '../../../core/router/route_names/route_names.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import '../../../core/theme/app_style/app_style.dart';
import '../../../core/theme/app_theme/app_theme.dart';
import '../package_catalog.dart';

/// Packages tab — 3×2 grid; image/button style matches home offers.
class PackageListPage extends StatelessWidget {
  const PackageListPage({super.key});

  static const _hGap = 8.0;
  static const _vGap = 12.0;

  static final _packages =
      PackageCatalog.items.where((e) => e.id != '1m_extra').toList();

  @override
  Widget build(BuildContext context) {
    final locale = context.locale.languageCode;

    return AppCurvedScaffold(
      title: Text('package.title'.tr()),
      showBack: false,
      body: GridView.builder(
        key: ValueKey('package-grid-$locale'),
        padding: const EdgeInsets.fromLTRB(
          AppStyle.spaceLg,
          14,
          AppStyle.spaceLg,
          AppStyle.spaceXxl,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: _hGap,
          mainAxisSpacing: _vGap,
          childAspectRatio: 0.68,
        ),
        itemCount: _packages.length,
        itemBuilder: (context, index) {
          final package = _packages[index];
          return _PackageGridCard(
            id: package.id,
            imagePath: package.imagePath,
            popular: package.popular,
            locale: locale,
          );
        },
      ),
    );
  }
}

/// Same look as home offer cards: full-bleed image + primary Buy now.
class _PackageGridCard extends StatelessWidget {
  const _PackageGridCard({
    required this.id,
    required this.imagePath,
    required this.popular,
    required this.locale,
  });

  final String id;
  final String imagePath;
  final bool popular;
  final String locale;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      key: ValueKey('package-grid-$id-$locale'),
      elevated: false,
      bordered: false,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(AppStyle.radiusSm),
              ),
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
            padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
            child: _BuyNowButton(
              onTap: () => context.pushNamed(
                RouteNames.packageDetail,
                pathParameters: {'id': id},
              ),
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
