import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../components/app_button/app_button.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import '../../../core/theme/app_style/app_style.dart';
import '../../../core/theme/app_theme/app_theme.dart';
import '../../../core/ui/bottom_nav_visibility_provider.dart';

/// Confirm package purchase — bottom drawer.
Future<bool> showPackageBuyConfirmDrawer(
  BuildContext context, {
  required String packageTitle,
  required int pricePoints,
  required String speedMbps,
  required bool autoRenew,
}) async {
  final container = ProviderScope.containerOf(context);
  final nav = container.read(bottomNavVisibleProvider.notifier);
  nav.state = false;

  try {
    final result = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppStyle.radiusCurve),
        ),
      ),
      builder: (sheetContext) => _PackageBuyConfirmSheet(
        packageTitle: packageTitle,
        pricePoints: pricePoints,
        speedMbps: speedMbps,
        autoRenew: autoRenew,
      ),
    );
    return result == true;
  } finally {
    nav.state = true;
  }
}

class _PackageBuyConfirmSheet extends StatelessWidget {
  const _PackageBuyConfirmSheet({
    required this.packageTitle,
    required this.pricePoints,
    required this.speedMbps,
    required this.autoRenew,
  });

  final String packageTitle;
  final int pricePoints;
  final String speedMbps;
  final bool autoRenew;

  @override
  Widget build(BuildContext context) {
    final priceLabel =
        '${NumberFormat('#,##0').format(pricePoints)} ${'topup.pts'.tr()}';
    final speedLabel = '$speedMbps Mbps';

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppStyle.spaceLg),
            Text(
              'package.confirm_buy_title'.tr(),
              textAlign: TextAlign.center,
              style: AppTheme.english(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'package.confirm_buy_body'.tr(),
              textAlign: TextAlign.center,
              style: AppTheme.english(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: AppColors.textMuted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppStyle.spaceLg),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                children: [
                  _InfoRow(
                    label: 'package.confirm_package'.tr(),
                    value: packageTitle,
                  ),
                  const SizedBox(height: 10),
                  _InfoRow(
                    label: 'package.internet_speed'.tr(),
                    value: speedLabel,
                  ),
                  const SizedBox(height: 10),
                  _InfoRow(
                    label: 'package.price'.tr(),
                    value: priceLabel,
                  ),
                  const SizedBox(height: 10),
                  _InfoRow(
                    label: 'package.renew'.tr(),
                    value: autoRenew
                        ? 'package.renew_on'.tr()
                        : 'package.renew_off'.tr(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppStyle.spaceXl),
            AppButton(
              label: 'package.confirm_buy'.tr(),
              height: 42,
              fontSize: 13,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: AppStyle.spaceSm),
            SizedBox(
              height: 36,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFF0000),
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFFF0000), width: 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppStyle.radiusButton),
                  ),
                ),
                child: Text(
                  'common.cancel'.tr(),
                  style: AppTheme.english(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFFF0000),
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Text(
            label,
            style: AppTheme.english(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 6,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: AppTheme.english(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
