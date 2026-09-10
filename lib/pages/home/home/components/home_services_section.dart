import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../../core/theme/app_colors/app_colors.dart';
import '../../../../core/theme/app_style/app_style.dart';
import '../../../../core/theme/app_theme/app_theme.dart';

/// Home service icons: Flaticon (srip receipt style + related icons).
/// Attribution: https://www.flaticon.com/free-icons/receipt
class HomeServicesSection extends StatelessWidget {
  const HomeServicesSection({super.key});

  List<_ServiceItem> get _homeItems => [
        _ServiceItem(
          asset: 'assets/images/services/pay_bill.png',
          label: 'home.service_pay'.tr(),
          tint: const Color(0xFFE3F2FD),
        ),
        _ServiceItem(
          asset: 'assets/images/services/check_bill.png',
          label: 'home.service_check'.tr(),
          tint: const Color(0xFFFCE4EC),
        ),
        _ServiceItem(
          asset: 'assets/images/services/history.png',
          label: 'home.service_history'.tr(),
          tint: const Color(0xFFF3E5F5),
        ),
        _ServiceItem(
          asset: 'assets/images/services/installation.png',
          label: 'home.service_packages'.tr(),
          tint: const Color(0xFFE8EAF6),
        ),
        _ServiceItem(
          asset: 'assets/images/services/complaint.png',
          label: 'home.service_support'.tr(),
          tint: const Color(0xFFFFF3E0),
        ),
        _ServiceItem(
          asset: 'assets/images/services/relocation.png',
          label: 'home.service_alerts'.tr(),
          tint: const Color(0xFFE0F7FA),
        ),
      ];

  List<_ServiceItem> get _extraItems => [
        _ServiceItem(
          asset: 'assets/images/services/check_cpe.png',
          label: 'home.service_check_cpe'.tr(),
          tint: const Color(0xFFE8F5E9),
        ),
        _ServiceItem(
          asset: 'assets/images/services/change_plan.png',
          label: 'home.service_change_plan'.tr(),
          tint: const Color(0xFFE3F2FD),
        ),
        _ServiceItem(
          asset: 'assets/images/services/change_wifi.png',
          label: 'home.service_change_wifi'.tr(),
          tint: const Color(0xFFFFF8E1),
        ),
      ];

  Future<void> _openServicesDrawer(BuildContext context) async {
    final homeItems = _homeItems;
    final extraItems = _extraItems;

    await showModalBottomSheet<void>(
      context: context,
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
  }

  @override
  Widget build(BuildContext context) {
    // Depend on locale so labels refresh when language changes.
    final _ = context.locale;
    final items = _homeItems;

    return Padding(
      padding: AppStyle.pagePaddingH,
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
                onTap: () => _openServicesDrawer(context),
                borderRadius: AppStyle.borderRadiusSm,
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

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: AppStyle.spaceMd),
          Expanded(child: _ServiceCard(item: items[i])),
        ],
        // Keep row alignment if fewer than 3 items.
        for (var i = items.length; i < 3; i++) ...[
          const SizedBox(width: AppStyle.spaceMd),
          const Expanded(child: SizedBox()),
        ],
      ],
    );
  }
}

class _ServiceItem {
  const _ServiceItem({
    required this.label,
    required this.tint,
    this.asset,
    this.icon,
    this.iconColor,
  }) : assert(asset != null || icon != null);

  final String? asset;
  final IconData? icon;
  final String label;
  final Color tint;
  final Color? iconColor;
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.item});

  final _ServiceItem item;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      elevation: 0,
      borderRadius: AppStyle.borderRadiusMd,
      child: InkWell(
        onTap: () {},
        borderRadius: AppStyle.borderRadiusMd,
        child: Ink(
          height: 88,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppStyle.borderRadiusMd,
            border: Border.all(color: AppColors.borderLight),
            boxShadow: AppStyle.cardShadow,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: item.tint,
                  borderRadius: AppStyle.borderRadiusSm,
                ),
                alignment: Alignment.center,
                child: item.asset != null
                    ? Image.asset(
                        item.asset!,
                        width: 24,
                        height: 24,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Icon(
                          item.icon ?? Icons.image_not_supported_outlined,
                          size: 20,
                          color: item.iconColor ?? AppColors.textMuted,
                        ),
                      )
                    : Icon(
                        item.icon,
                        size: 20,
                        color: item.iconColor ?? AppColors.primary,
                      ),
              ),
              const SizedBox(height: AppStyle.spaceSm),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  item.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.captionSm(color: AppColors.textPrimary)
                      .copyWith(
                    fontWeight: FontWeight.w400,
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
