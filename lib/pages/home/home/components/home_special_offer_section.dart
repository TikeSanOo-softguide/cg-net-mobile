import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../components/app_card/app_card.dart';
import '../../../../core/router/route_names/route_names.dart';
import '../../../../core/theme/app_colors/app_colors.dart';
import '../../../../core/theme/app_style/app_style.dart';
import '../../../../core/theme/app_theme/app_theme.dart';
import '../../../../data/promotion/promotion_repository.dart';
import '../../../../models/promotion_model/promotion_model.dart';
import 'home_section_header.dart';

class HomeSpecialOfferSection extends ConsumerWidget {
  const HomeSpecialOfferSection({super.key});

  static ({double cardWidth, double imageHeight, double listHeight}) layoutFor(
    double screenWidth,
  ) {
    final contentWidth = (screenWidth - AppStyle.pageMarginH * 2).clamp(
      200.0,
      600.0,
    );
    final cardWidth = (contentWidth * 0.72).clamp(196.0, 248.0);
    final imageHeight = (cardWidth * 9 / 16).clamp(110.0, 136.0);
    const bodyHeight = 128.0;
    return (
      cardWidth: cardWidth,
      imageHeight: imageHeight,
      listHeight: imageHeight + bodyHeight,
    );
  }

  static String _inboxId(HomePromotion item) {
    final id = item.id.trim();
    if (id.isEmpty) return '';
    return id.startsWith('promotion-') ? id : 'promotion-$id';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = context.locale.languageCode;
    final promotions = ref.watch(homePromotionsProvider);

    return promotions.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        final layout = layoutFor(MediaQuery.sizeOf(context).width);
        return Padding(
          padding: AppStyle.pagePaddingH.add(
            const EdgeInsets.only(top: HomeSectionHeader.sectionGap),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HomeSectionHeader(title: 'home.special_offer'.tr()),
              SizedBox(
                height: layout.listHeight,
                child: ListView.separated(
                  key: ValueKey('special-offers-$locale'),
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.zero,
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    return SizedBox(
                      width: layout.cardWidth,
                      height: layout.listHeight,
                      child: _OfferCard(
                        item: items[index],
                        locale: locale,
                        imageHeight: layout.imageHeight,
                        onSeeMore: () {
                          final id = _inboxId(items[index]);
                          if (id.isEmpty) return;
                          context.pushNamed(
                            RouteNames.inboxDetail,
                            pathParameters: {'id': id},
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({
    required this.item,
    required this.locale,
    required this.imageHeight,
    required this.onSeeMore,
  });

  final HomePromotion item;
  final String locale;
  final double imageHeight;
  final VoidCallback onSeeMore;

  @override
  Widget build(BuildContext context) {
    final title = item.titleFor(locale);
    final description = item.descriptionFor(locale);
    final imageUrl = item.imageUrl;

    return SizedBox.expand(
      child: AppCard(
        elevated: false,
        bordered: false,
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: SizedBox(
                height: imageHeight,
                width: double.infinity,
                child: imageUrl == null || imageUrl.isEmpty
                    ? const _ImageFallback()
                    : Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                        width: double.infinity,
                        height: double.infinity,
                        filterQuality: FilterQuality.high,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return const _ImageFallback();
                        },
                        errorBuilder: (_, __, ___) => const _ImageFallback(),
                      ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.isEmpty ? 'home.special_offer'.tr() : title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.english(
                        color: AppColors.primary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: AppTheme.lineHeightMyanmarSafe,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (description.isNotEmpty)
                      Expanded(
                        child: Text(
                          description,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.english(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            height: 1.6,
                            letterSpacing: 0,
                          ),
                        ),
                      )
                    else
                      const Spacer(),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: onSeeMore,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            'common.see_more'.tr(),
                            style: AppTheme.english(
                              color: AppColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              height: AppTheme.lineHeightMyanmarSafe,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
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
          LucideIcons.image,
          size: 22,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
