import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../components/app_button/app_button.dart';
import '../../../components/app_card/app_card.dart';
import '../../../components/app_curved_scaffold/app_curved_scaffold.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import '../../../core/theme/app_theme/app_theme.dart';
import 'transfer_result.dart';

const _successGreen = Color(0xFF499A13);
const _successSoft = Color(0xFFE8F5DC);
const _failureRed = Color(0xFFD90000);
const _failureSoft = Color(0xFFFCE6E6);
const _successIconAsset = 'assets/images/dialogs/success.png';
const _failureIconAsset = 'assets/images/dialogs/failure.png';

class TransferResultShell extends StatelessWidget {
  const TransferResultShell({
    super.key,
    required this.result,
    required this.primaryLabel,
    required this.onPrimary,
    this.onBack,
  });

  final TransferResult result;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final VoidCallback? onBack;

  bool get _isSuccess => result.status == TransferTxnStatus.success;

  @override
  Widget build(BuildContext context) {
    final titleKey = _isSuccess
        ? 'transfer.result_success_title'
        : (result.errorTitleKey ?? 'transfer.result_failure_title');
    final bodyKey = _isSuccess
        ? 'transfer.result_success_body'
        : (result.errorBodyKey ?? 'transfer.result_failure_body');
    final titleColor = _isSuccess ? _successGreen : _failureRed;
    final statusLabel = _isSuccess
        ? 'transfer.status_completed'.tr()
        : 'transfer.status_failed'.tr();
    final when = DateFormat('d MMM yyyy, hh:mm a').format(result.occurredAt);

    final detailRows = <(String, String)>[
      (
        'transfer.detail_type'.tr(),
        'transfer.type_transfer'.tr(),
      ),
      (
        'transfer.detail_account'.tr(),
        result.recipientAccount,
      ),
      (
        'transfer.detail_amount'.tr(),
        '${result.amountPoints} ${'topup.points_unit'.tr()}',
      ),
      (
        'transfer.detail_txn'.tr(),
        result.transactionId,
      ),
      (
        'transfer.detail_datetime'.tr(),
        when,
      ),
      (
        'transfer.detail_status'.tr(),
        statusLabel,
      ),
    ];

    return AppCurvedScaffold(
      title: Text('transfer.detail_page_title'.tr()),
      showBack: true,
      onBack: onBack ?? () => Navigator.of(context).maybePop(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
        child: AppCard(
          elevated: true,
          bordered: false,
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
          child: Column(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _isSuccess ? _successSoft : _failureSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Image.asset(
                  _isSuccess ? _successIconAsset : _failureIconAsset,
                  width: 25,
                  height: 25,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                titleKey.tr(),
                textAlign: TextAlign.center,
                style: AppTheme.english(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: titleColor,
                  height: 1.25,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                bodyKey.tr(),
                textAlign: TextAlign.center,
                style: AppTheme.english(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textMuted,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 22),
              _DetailRows(
                rows: detailRows,
                statusColor: titleColor,
                statusBackground: _isSuccess ? _successSoft : _failureSoft,
              ),
              const SizedBox(height: 20),
              AppButton(
                label: primaryLabel,
                onPressed: onPrimary,
                height: 36,
                fontSize: 12,
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
            const SizedBox(height: 10),
            const Divider(height: 1, color: AppColors.paperBorder),
            const SizedBox(height: 10),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 5,
                child: Text(
                  rows[i].$1,
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
                child: Align(
                  alignment: Alignment.centerRight,
                  child: i == rows.length - 1
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: statusBackground,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            rows[i].$2,
                            style: AppTheme.english(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                        )
                      : Text(
                          rows[i].$2,
                          textAlign: TextAlign.right,
                          style: AppTheme.english(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
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
