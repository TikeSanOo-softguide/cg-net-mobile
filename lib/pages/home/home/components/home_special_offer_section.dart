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

  static const _cardWidth = 240.0;
  static const _listHeight = 236.0;

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
        return Padding(
          padding: AppStyle.pagePaddingH.add(
            const EdgeInsets.only(top: HomeSectionHeader.sectionGap),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HomeSectionHeader(title: 'home.special_offer'.tr()),
              SizedBox(
                height: _listHeight,
                child: ListView.separated(
                  key: ValueKey('special-offers-$locale'),
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.zero,
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    return SizedBox(
                      width: _cardWidth,
                      height: _listHeight,
                      child: _OfferCard(
                        item: items[index],
                        locale: locale,
                        onReadMore: () {
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
    required this.onReadMore,
  });

  final HomePromotion item;
  final String locale;
  final VoidCallback onReadMore;

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
              height: 118,
              width: double.infinity,
              child: imageUrl == null || imageUrl.isEmpty
                  ? const _ImageFallback()
                  : Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
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
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.isEmpty ? 'home.special_offer'.tr() : title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.english(
                      color: AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: AppTheme.lineHeightMyanmarSafe,
                      letterSpacing: 0,
                    ),
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.english(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: onReadMore,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'home.read_more'.tr(),
                          style: AppTheme.english(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
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
          size: 18,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
