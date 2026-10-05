import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../components/app_button/app_button.dart';
import '../../../components/app_card/app_card.dart';
import '../../../components/app_curved_scaffold/app_curved_scaffold.dart';
import '../../../core/network/api_error_text.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import '../../../core/theme/app_style/app_style.dart';
import '../../../core/theme/app_theme/app_theme.dart';
import 'top_up_result.dart';

const _successGreen = Color(0xFF499A13);
const _successSoft = Color(0xFFE8F5DC);
const _failureRed = Color(0xFFD90000);
const _failureSoft = Color(0xFFFCE6E6);
const _successIconAsset = 'assets/images/dialogs/success.png';
const _failureIconAsset = 'assets/images/dialogs/failure.png';

class TopUpResultShell extends StatelessWidget {
  const TopUpResultShell({
    super.key,
    required this.result,
    required this.primaryLabel,
    required this.onPrimary,
    this.onBack,
  });

  final TopUpResult result;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final VoidCallback? onBack;

  bool get _isSuccess => result.status == TopUpTxnStatus.success;
  bool get _isPending => result.status == TopUpTxnStatus.pending;

  @override
  Widget build(BuildContext context) {
    final iconBg = _isPending
        ? AppColors.primaryLight
        : _isSuccess
            ? _successSoft
            : _failureSoft;
    final iconColor = _isPending
        ? AppColors.primary
        : _isSuccess
            ? _successGreen
            : _failureRed;
    final titleKey = _isPending
        ? 'topup.result_pending_title'
        : _isSuccess
            ? 'topup.result_success_title'
            : 'topup.result_failure_title';
    final bodyKey = _isPending
        ? 'topup.result_pending_body'
        : _isSuccess
            ? 'topup.result_success_body'
            : 'topup.result_failure_body';
    final titleColor = _isPending
        ? AppColors.primary
        : _isSuccess
            ? _successGreen
            : _failureRed;
    final statusLabel = _isPending
        ? 'topup.status_pending'.tr()
        : _isSuccess
            ? 'topup.status_completed'.tr()
            : 'topup.status_failed'.tr();
    final statusColor = titleColor;
    final titleText = !_isSuccess
        ? result.errorTitleKey?.tr() ??
            apiMessageText(result.errorTitle, fallbackKey: titleKey)
        : titleKey.tr();
    final bodyText = !_isSuccess
        ? result.errorBodyKey?.tr() ??
            apiMessageText(result.errorBody, fallbackKey: bodyKey)
        : bodyKey.tr();

    final when = DateFormat('d MMM yyyy, hh:mm a').format(result.occurredAt);

    final detailRows = <(String, String)>[
      (
        'topup.detail_type'.tr(),
        'topup.type_topup'.tr(),
      ),
      (
        'topup.detail_amount'.tr(),
        '${result.amountPoints} ${'topup.points_unit'.tr()}',
      ),
      (
        'topup.detail_serial'.tr(),
        result.serialMasked,
      ),
      (
        'topup.detail_txn'.tr(),
        result.transactionId,
      ),
      (
        'topup.detail_datetime'.tr(),
        when,
      ),
      (
        'topup.detail_status'.tr(),
        statusLabel,
      ),
    ];

    final statusIcon = _isPending
        ? Icon(
            LucideIcons.loader_circle,
            size: 28,
            color: iconColor,
          )
        : Image.asset(
            _isSuccess ? _successIconAsset : _failureIconAsset,
            width: 28,
            height: 28,
            fit: BoxFit.contain,
          );

    return AppCurvedScaffold(
      title: Text('topup.detail_page_title'.tr()),
      showBack: true,
      onBack: onBack ?? () => Navigator.of(context).maybePop(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
        child: AppCard(
          elevated: true,
          bordered: false,
          borderRadius: AppStyle.borderRadiusLg,
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
          child: Column(
            children: [
              Container(
                width: 43,
                height: 43,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: statusIcon,
              ),
              const SizedBox(height: 16),
              Text(
                titleText,
                textAlign: TextAlign.center,
                style: AppTheme.english(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: titleColor,
                  height: 1.25,
                  letterSpacing: 0.5,
                ),
              ),
              if (_isSuccess) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '+${NumberFormat('#,##0').format(result.amountPoints)}',
                      style: AppTheme.english(
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                        height: 1,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'topup.points_unit'.tr(),
                      style: AppTheme.english(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                        height: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ] else ...[
                const SizedBox(height: 6),
                Text(
                  bodyText,
                  textAlign: TextAlign.center,
                  style: AppTheme.english(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textMuted,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 40),
              ],
              _DetailRows(
                rows: detailRows,
                statusColor: statusColor,
                statusBackground: _isPending
                    ? AppColors.primaryLight
                    : _isSuccess
                        ? _successSoft
                        : _failureSoft,
              ),
              const SizedBox(height: 40),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 150),
                  child: AppButton(
                    label: primaryLabel,
                    onPressed: onPrimary,
                    height: 38,
                    fontSize: 13,
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

class _DetailRows extends StatelessWidget {
  const _DetailRows({
    required this.rows,
    required this.statusColor,
    required this.statusBackground,
  });

  final List<(String, String)> rows;
  final Color statusColor;
  final Color statusBackground;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) ...[
            const SizedBox(height: 11),
            const Divider(
                height: 0.5, thickness: 0.5, color: AppColors.paperBorder),
            const SizedBox(height: 11),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 5,
                child: Text(
                  rows[i].$1,
                  style: AppTheme.english(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 6,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: i == rows.length - 1
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: statusBackground,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            rows[i].$2,
                            style: AppTheme.english(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: statusColor,
                            ),
                          ),
                        )
                      : Text(
                          rows[i].$2,
                          textAlign: TextAlign.right,
                          style: AppTheme.english(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
