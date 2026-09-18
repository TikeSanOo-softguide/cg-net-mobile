import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../components/app_card/app_card.dart';
import '../../../../components/app_dialog/app_dialog.dart';
import '../../../../core/router/route_names/route_names.dart';
import '../../../../core/theme/app_colors/app_colors.dart';
import '../../../../core/theme/app_style/app_style.dart';
import '../../../../core/theme/app_theme/app_theme.dart';
import '../../../../core/ui/bottom_nav_visibility_provider.dart';
import '../bound_broadband_provider.dart';
import 'home_section_header.dart';

/// Home service icons — one main [AppCard] with flat tinted PNG tiles.
class HomeServicesSection extends ConsumerWidget {
  const HomeServicesSection({super.key});

  List<_ServiceItem> get _homeItems => [
        _ServiceItem(
          id: 'pay_bill',
          asset: 'assets/images/services/pay_bill.png',
          label: 'home.service_pay'.tr(),
          color: const Color(0xFF0100CA),
        ),
        _ServiceItem(
          id: 'check_bill',
          asset: 'assets/images/services/check_bill.png',
          label: 'home.service_check'.tr(),
          color: const Color(0xFF0D9488),
        ),
        _ServiceItem(
          id: 'history',
          asset: 'assets/images/services/history.png',
          label: 'home.service_history'.tr(),
          color: const Color(0xFF7C3AED),
        ),
        _ServiceItem(
          id: 'installation',
          asset: 'assets/images/services/installation.png',
          label: 'home.service_packages'.tr(),
          color: const Color(0xFFEA580C),
        ),
        _ServiceItem(
          id: 'complaint',
          asset: 'assets/images/services/complaint.png',
          label: 'home.service_support'.tr(),
          color: const Color(0xFFDC2626),
        ),
        _ServiceItem(
          id: 'relocation',
          asset: 'assets/images/services/relocation.png',
          label: 'home.service_alerts'.tr(),
          color: const Color(0xFF2563EB),
        ),
      ];

  List<_ServiceItem> get _extraItems => [
        _ServiceItem(
          id: 'check_cpe',
          asset: 'assets/images/services/check_cpe.png',
          label: 'home.service_check_cpe'.tr(),
          color: const Color(0xFF059669),
        ),
        _ServiceItem(
          id: 'change_plan',
          asset: 'assets/images/services/change_plan.png',
          label: 'home.service_change_plan'.tr(),
          color: const Color(0xFFDB2777),
        ),
        _ServiceItem(
          id: 'change_wifi',
          asset: 'assets/images/services/change_wifi.png',
          label: 'home.service_change_wifi'.tr(),
          color: const Color(0xFF0891B2),
          backgroundColor: const Color(0xFFEEF2FF),
        ),
      ];

  Future<void> _onServiceTap(
    BuildContext context,
    WidgetRef ref,
    _ServiceItem item, {
    bool fromSheet = false,
  }) async {
    if (ref.read(boundBroadbandProvider) == null) {
      await showAppAlertModal(
        context,
        message: 'home.service_bind_required'.tr(),
      );
      return;
    }

    final router = GoRouter.of(context);
    if (fromSheet) {
      Navigator.of(context).pop();
    }
    router.pushNamed(
      RouteNames.servicePlaceholder,
      pathParameters: {'id': item.id},
    );
  }

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
                  _ServiceGrid(
                    items: homeItems.take(3).toList(),
                    onTap: (item) => _onServiceTap(
                      sheetContext,
                      ref,
                      item,
                      fromSheet: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _ServiceGrid(
                    items: homeItems.skip(3).take(3).toList(),
                    onTap: (item) => _onServiceTap(
                      sheetContext,
                      ref,
                      item,
                      fromSheet: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _ServiceGrid(
                    items: extraItems,
                    onTap: (item) => _onServiceTap(
                      sheetContext,
                      ref,
                      item,
                      fromSheet: true,
                    ),
                  ),
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
      padding: AppStyle.pagePaddingH,
      child: Column(
        children: [
          HomeSectionHeader(
            title: 'home.services'.tr(),
            onSeeAll: () => _openServicesDrawer(context, ref),
          ),
          AppCard(
            elevated: false,
            bordered: false,
            padding: const EdgeInsets.symmetric(
              horizontal: AppStyle.spaceSm,
              vertical: 10,
            ),
            child: Column(
              children: [
                _ServiceGrid(
                  items: items.take(3).toList(),
                  onTap: (item) => _onServiceTap(context, ref, item),
                ),
                const SizedBox(height: 10),
                _ServiceGrid(
                  items: items.skip(3).take(3).toList(),
                  onTap: (item) => _onServiceTap(context, ref, item),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceGrid extends StatelessWidget {
  const _ServiceGrid({
    required this.items,
    required this.onTap,
  });

  final List<_ServiceItem> items;
  final ValueChanged<_ServiceItem> onTap;

  static const double _gap = 8;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: _gap),
          Expanded(
            child: _ServiceTile(
              item: items[i],
              onTap: () => onTap(items[i]),
            ),
          ),
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
    required this.id,
    required this.label,
    required this.color,
    this.asset,
    this.icon,
    this.backgroundColor,
  }) : assert(asset != null || icon != null);

  final String id;
  final String? asset;
  final IconData? icon;
  final String label;
  final Color color;
  final Color? backgroundColor;

  /// Soft chip fill ≈ color at 14% on white, unless [backgroundColor] is set.
  Color get chipBackground =>
      backgroundColor ??
      Color.alphaBlend(color.withValues(alpha: 0.14), Colors.white);
}

/// Flat service tile inside the main [AppCard] (no per-item card).
class _ServiceTile extends StatelessWidget {
  const _ServiceTile({
    required this.item,
    required this.onTap,
  });

  final _ServiceItem item;
  final VoidCallback onTap;

  static const double _boxSize = 36;
  static const double _iconSize = 22;
  static const double _boxRadius = 8;

  @override
  Widget build(BuildContext context) {
    final color = item.color;
    final iconWidget = item.asset != null
        ? ColorFiltered(
            colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            child: Image.asset(
              item.asset!,
              width: _iconSize,
              height: _iconSize,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              errorBuilder: (_, __, ___) => Icon(
                item.icon ?? Icons.image_not_supported_outlined,
                size: _iconSize,
                color: color,
              ),
            ),
          )
        : Icon(
            item.icon,
            size: _iconSize,
            color: color,
          );

    return InkWell(
      onTap: onTap,
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
                color: item.chipBackground,
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
              style: AppTheme.english(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
