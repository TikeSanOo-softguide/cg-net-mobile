import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../components/app_card/app_card.dart';
import '../../../../core/theme/app_colors/app_colors.dart';
import '../../../../core/theme/app_style/app_style.dart';
import '../../../../core/theme/app_theme/app_theme.dart';
import '../../../../core/ui/bottom_nav_visibility_provider.dart';

/// Home service icons — one main [AppCard] with flat tinted PNG tiles.
class HomeServicesSection extends ConsumerWidget {
  const HomeServicesSection({super.key});

  List<_ServiceItem> get _homeItems => [
        _ServiceItem(
          asset: 'assets/images/services/pay_bill.png',
          label: 'home.service_pay'.tr(),
          iconColor: const Color(0xFF3A38FF),
          backgroundColor: const Color(0xFFE0DFFF),
        ),
        _ServiceItem(
          asset: 'assets/images/services/check_bill.png',
          label: 'home.service_check'.tr(),
          iconColor: const Color(0xFF1AD9A0),
          backgroundColor: const Color(0xFFD4F7EC),
        ),
        _ServiceItem(
          asset: 'assets/images/services/history.png',
          label: 'home.service_history'.tr(),
          iconColor: const Color(0xFFB06BFF),
          backgroundColor: const Color(0xFFE8DBFF),
        ),
        _ServiceItem(
          asset: 'assets/images/services/installation.png',
          label: 'home.service_packages'.tr(),
          iconColor: const Color(0xFFFF9E3D),
          backgroundColor: const Color(0xFFFFE0C7),
        ),
        _ServiceItem(
          asset: 'assets/images/services/complaint.png',
          label: 'home.service_support'.tr(),
          iconColor: const Color(0xFFFF5568),
          backgroundColor: const Color(0xFFFFDCE1),
        ),
        _ServiceItem(
          asset: 'assets/images/services/relocation.png',
          label: 'home.service_alerts'.tr(),
          iconColor: const Color(0xFF3DA0FF),
          backgroundColor: const Color(0xFFD6EBFF),
        ),
      ];

  List<_ServiceItem> get _extraItems => [
        _ServiceItem(
          asset: 'assets/images/services/check_cpe.png',
          label: 'home.service_check_cpe'.tr(),
          iconColor: const Color(0xFF2EC862),
          backgroundColor: const Color(0xFFD8F5E0),
        ),
        _ServiceItem(
          asset: 'assets/images/services/change_plan.png',
          label: 'home.service_change_plan'.tr(),
          iconColor: const Color(0xFFFF5A9C),
          backgroundColor: const Color(0xFFFFD9EA),
        ),
        _ServiceItem(
          asset: 'assets/images/services/change_wifi.png',
          label: 'home.service_change_wifi'.tr(),
          iconColor: const Color(0xFFFFC433),
          backgroundColor: const Color(0xFFFFF0C7),
        ),
      ];

  Future<void> _openServicesDrawer(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final homeItems = _homeItems;
    final extraItems = _extraItems;
    final nav = ref.read(bottomNavVisibleProvider.notifier);
    nav.state = false;

    try {
      await showModalBottomSheet<void>(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppStyle.radiusCurve),
          ),
        ),
        builder: (sheetContext) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppStyle.spaceLg,
                AppStyle.spaceMd,
                AppStyle.spaceLg,
                AppStyle.spaceLg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: AppStyle.spaceMd),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'home.services'.tr(),
                          style: AppTheme.sectionTitle(),
                        ),
                      ),
                      Material(
                        color: AppColors.primarySoft,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          onTap: () => Navigator.of(sheetContext).pop(),
                          child: const SizedBox(
                            width: 36,
                            height: 36,
                            child: Icon(
                              LucideIcons.x,
                              size: 18,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppStyle.spaceLg),
                  _ServiceGrid(items: homeItems.take(3).toList()),
                  const SizedBox(height: 8),
                  _ServiceGrid(items: homeItems.skip(3).take(3).toList()),
                  const SizedBox(height: 8),
                  _ServiceGrid(items: extraItems),
                  const SizedBox(height: AppStyle.spaceSm),
                ],
              ),
            ),
          );
        },
      );
    } finally {
      nav.state = true;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final _ = context.locale;
    final items = _homeItems;

    return Column(
      children: [
        Padding(
          padding: AppStyle.pagePaddingH,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'home.services'.tr(),
                  style: AppTheme.sectionTitle(),
                ),
              ),
              InkWell(
                onTap: () => _openServicesDrawer(context, ref),
                borderRadius: AppStyle.borderRadiusSm,
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppStyle.spaceXs,
                    vertical: AppStyle.spaceXs,
                  ),
                  child: Text(
                    'home.see_all'.tr(),
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
        const SizedBox(height: AppStyle.spaceSm),
        AppCard(
          margin: AppStyle.pagePaddingH,
          elevated: true,
          bordered: false,
          padding: const EdgeInsets.symmetric(
            horizontal: AppStyle.spaceSm,
            vertical: 10,
          ),
          child: Column(
            children: [
              _ServiceGrid(items: items.take(3).toList()),
              const SizedBox(height: 10),
              _ServiceGrid(items: items.skip(3).take(3).toList()),
            ],
          ),
        ),
      ],
    );
  }
}

class _ServiceGrid extends StatelessWidget {
  const _ServiceGrid({required this.items});

  final List<_ServiceItem> items;

  static const double _gap = 8;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: _gap),
          Expanded(child: _ServiceTile(item: items[i])),
        ],
        for (var i = items.length; i < 3; i++) ...[
          const SizedBox(width: _gap),
          const Expanded(child: SizedBox()),
        ],
      ],
    );
  }
}

class _ServiceItem {
  const _ServiceItem({
    required this.label,
    required this.iconColor,
    required this.backgroundColor,
    this.asset,
    this.icon,
  }) : assert(asset != null || icon != null);

  final String? asset;
  final IconData? icon;
  final String label;
  final Color iconColor;
  final Color backgroundColor;
}

/// Flat service tile inside the main [AppCard] (no per-item card).
class _ServiceTile extends StatelessWidget {
  const _ServiceTile({required this.item});

  final _ServiceItem item;

  static const double _boxSize = 48;
  static const double _iconSize = 26;
  static const double _boxRadius = 8;

  @override
  Widget build(BuildContext context) {
    final iconWidget = item.asset != null
        ? ColorFiltered(
            colorFilter: ColorFilter.mode(
              item.iconColor,
              BlendMode.srcIn,
            ),
            child: Image.asset(
              item.asset!,
              width: _iconSize,
              height: _iconSize,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              errorBuilder: (_, __, ___) => Icon(
                item.icon ?? Icons.image_not_supported_outlined,
                size: 18,
                color: item.iconColor,
              ),
            ),
          )
        : Icon(
            item.icon,
            size: 18,
            color: item.iconColor,
          );

    return InkWell(
      onTap: () {},
      borderRadius: AppStyle.borderRadiusSm,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: _boxSize,
              height: _boxSize,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: item.backgroundColor,
                borderRadius: BorderRadius.circular(_boxRadius),
              ),
              child: iconWidget,
            ),
            const SizedBox(height: 6),
            Text(
              item.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.captionSm(color: AppColors.textMuted).copyWith(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
