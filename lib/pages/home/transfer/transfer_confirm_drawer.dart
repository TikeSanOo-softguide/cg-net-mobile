import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../components/app_button/app_button.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import '../../../core/theme/app_style/app_style.dart';
import '../../../core/theme/app_theme/app_theme.dart';

const _cancelRed = Color(0xFFFF0000);

/// Confirm transfer as a bottom drawer (Cancel / Confirm).
Future<bool> showTransferConfirmDrawer(
  BuildContext context, {
  required String account,
  required int amountPoints,
}) async {
  final amountLabel =
      '${NumberFormat('#,##0').format(amountPoints)} ${'topup.points_unit'.tr()}';
  final when = DateFormat('d MMM yyyy, hh:mm a').format(DateTime.now());

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
    builder: (sheetContext) {
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
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
              const SizedBox(height: 18),
              Text(
                'transfer.confirm_title'.tr(),
                textAlign: TextAlign.center,
                style: AppTheme.english(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'transfer.confirm_body'.tr(
                  namedArgs: {
                    'amount': NumberFormat('#,##0').format(amountPoints),
                    'account': account,
                  },
                ),
                textAlign: TextAlign.center,
                style: AppTheme.english(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMuted,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              _ConfirmDetailRow(
                label: 'transfer.detail_type'.tr(),
                value: 'transfer.type_transfer'.tr(),
              ),
              const Divider(height: 20, color: AppColors.paperBorder),
              _ConfirmDetailRow(
                label: 'transfer.detail_account'.tr(),
                value: account,
              ),
              const Divider(height: 20, color: AppColors.paperBorder),
              _ConfirmDetailRow(
                label: 'transfer.detail_amount'.tr(),
                value: amountLabel,
                valueColor: AppColors.primary,
              ),
              const Divider(height: 20, color: AppColors.paperBorder),
              _ConfirmDetailRow(
                label: 'transfer.detail_datetime'.tr(),
                value: when,
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 42,
                      child: OutlinedButton(
                        onPressed: () =>
                            Navigator.of(sheetContext).pop(false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _cancelRed,
                          backgroundColor: Colors.white,
                          elevation: 0,
                          side: const BorderSide(
                            color: _cancelRed,
                            width: 1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppStyle.radiusButton,
                            ),
                          ),
                        ),
                        child: Text(
                          'common.cancel'.tr(),
                          style: AppTheme.english(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _cancelRed,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppButton(
                      label: 'common.confirm'.tr(),
                      height: 42,
                      fontSize: 13,
                      onPressed: () =>
                          Navigator.of(sheetContext).pop(true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
  return result == true;
}

class _ConfirmDetailRow extends StatelessWidget {
  const _ConfirmDetailRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

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
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 6,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: AppTheme.english(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
