import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../components/app_button/app_button.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import '../../../core/theme/app_style/app_style.dart';
import '../../../core/theme/app_theme/app_theme.dart';
import '../../../core/ui/bottom_nav_visibility_provider.dart';

Future<bool> showBindBroadbandConfirmDrawer(
  BuildContext context, {
  required String title,
  required List<MapEntry<String, String>> details,
  String? confirmLabel,
  String? cancelLabel,
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
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppStyle.radiusCurve),
        ),
      ),
      builder: (sheetContext) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppStyle.spaceLg,
              AppStyle.spaceMd,
              AppStyle.spaceLg,
              AppStyle.spaceLg,
            ),
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
                Center(
                  child: Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Image.asset(
                      'assets/images/dialogs/confirm.png',
                      width: 23,
                      height: 23,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                ),
                const SizedBox(height: AppStyle.spaceLg),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTheme.english(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                    height: 1.25,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: AppStyle.spaceLg),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppStyle.spaceMd,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      for (var index = 0; index < details.length; index++) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppStyle.spaceMd,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 88,
                                child: Text(
                                  details[index].key,
                                  style: AppTheme.english(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.textSecondary,
                                    height: AppTheme.lineHeightMyanmarSafe,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppStyle.spaceSm),
                              Expanded(
                                child: Text(
                                  details[index].value,
                                  textAlign: TextAlign.end,
                                  style: AppTheme.english(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textPrimary,
                                    height: AppTheme.lineHeightMyanmarSafe,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (index < details.length - 1)
                          const Divider(
                            height: 1,
                            thickness: 1,
                            color: AppColors.borderLight,
                          ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppStyle.spaceXl),
                AppButton(
                  label: confirmLabel ?? 'common.confirm'.tr(),
                  height: 42,
                  fontSize: 13,
                  onPressed: () => Navigator.of(sheetContext).pop(true),
                ),
                const SizedBox(height: AppStyle.spaceSm),
                SizedBox(
                  height: 36,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(sheetContext).pop(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFF0000),
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFFFF0000)),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppStyle.radiusButton),
                      ),
                    ),
                    child: Text(
                      cancelLabel ?? 'common.cancel'.tr(),
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
        ),
      ),
    );
    return result == true;
  } finally {
    nav.state = true;
  }
}
