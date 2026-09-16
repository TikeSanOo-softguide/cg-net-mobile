import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router/go_router.dart';

import '../../../components/app_curved_scaffold/app_curved_scaffold.dart';
import '../../../core/router/route_names/route_names.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import '../../../core/theme/app_style/app_style.dart';
import '../../../core/theme/app_theme/app_theme.dart';
import '../package_catalog.dart';

/// Packages tab — 3×2 grid, same image/button style as home offers.
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

/// Matches home [_PackageImageCard] look (gradient frame + Buy Now).
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
    return Column(
      key: ValueKey('package-grid-$id-$locale'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Container(
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
                  color: AppColors.primary.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
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
        ),
        const SizedBox(height: AppStyle.spaceSm),
        _BuyNowButton(
          onTap: () => context.pushNamed(
            RouteNames.packageDetail,
            pathParameters: {'id': id},
          ),
        ),
      ],
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
