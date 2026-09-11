import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors/app_colors.dart';
import '../../../../core/theme/app_style/app_style.dart';
import '../../../../core/theme/app_theme/app_theme.dart';
import '../../../../core/ui/bottom_nav_visibility_provider.dart';

/// Home service icons — Flaticon assets recolored to primary `#0100CA` gradient.
class HomeServicesSection extends ConsumerWidget {
  const HomeServicesSection({super.key});

  List<_ServiceItem> get _homeItems => [
        _ServiceItem(
          asset: 'assets/images/services/pay_bill.png',
          label: 'home.service_pay'.tr(),
        ),
        _ServiceItem(
          asset: 'assets/images/services/check_bill.png',
          label: 'home.service_check'.tr(),
        ),
        _ServiceItem(
          asset: 'assets/images/services/history.png',
          label: 'home.service_history'.tr(),
        ),
        _ServiceItem(
          asset: 'assets/images/services/installation.png',
          label: 'home.service_packages'.tr(),
        ),
        _ServiceItem(
          asset: 'assets/images/services/complaint.png',
          label: 'home.service_support'.tr(),
        ),
        _ServiceItem(
          asset: 'assets/images/services/relocation.png',
          label: 'home.service_alerts'.tr(),
        ),
      ];

  List<_ServiceItem> get _extraItems => [
        _ServiceItem(
          asset: 'assets/images/services/check_cpe.png',
          label: 'home.service_check_cpe'.tr(),
        ),
        _ServiceItem(
          asset: 'assets/images/services/change_plan.png',
          label: 'home.service_change_plan'.tr(),
        ),
        _ServiceItem(
          asset: 'assets/images/services/change_wifi.png',
          label: 'home.service_change_wifi'.tr(),
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
                  const SizedBox(height: AppStyle.spaceMd),
                  _ServiceGrid(items: homeItems.skip(3).take(3).toList()),
                  const SizedBox(height: AppStyle.spaceMd),
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppStyle.spaceMd),
      child: Column(
        children: [
          Row(
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
          const SizedBox(height: AppStyle.spaceMd),
          _ServiceGrid(items: items.take(3).toList()),
          const SizedBox(height: AppStyle.spaceMd),
          _ServiceGrid(items: items.skip(3).take(3).toList()),
        ],
      ),
    );
  }
}

class _ServiceGrid extends StatelessWidget {
  const _ServiceGrid({required this.items});

  final List<_ServiceItem> items;

  static const double _gap = AppStyle.spaceSm;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: _gap),
          Expanded(child: _ServiceCard(item: items[i])),
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
    this.asset,
    this.icon,
  }) : assert(asset != null || icon != null);

  final String? asset;
  final IconData? icon;
  final String label;
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.item});

  final _ServiceItem item;

  static const double _iconSize = 32;
  static final BorderRadius _radius = AppStyle.borderRadiusMd;

  @override
  Widget build(BuildContext context) {
    final iconWidget = item.asset != null
        ? Image.asset(
            item.asset!,
            width: _iconSize,
            height: _iconSize,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            errorBuilder: (_, __, ___) => Icon(
              item.icon ?? Icons.image_not_supported_outlined,
              size: 22,
              color: AppColors.primary,
            ),
          )
        : Icon(
            item.icon,
            size: 22,
            color: AppColors.primary,
          );

    return Material(
      color: AppColors.surface,
      elevation: 0,
      borderRadius: _radius,
      child: InkWell(
        onTap: () {},
        borderRadius: _radius,
        splashColor: Colors.black.withValues(alpha: 0.06),
        highlightColor: Colors.black.withValues(alpha: 0.04),
        child: Ink(
          height: 88,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: _radius,
            boxShadow: AppStyle.cardShadow,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: iconWidget,
              ),
              const SizedBox(height: AppStyle.spaceSm),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  item.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.captionSm(color: AppColors.primary).copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                    height: 1.15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
