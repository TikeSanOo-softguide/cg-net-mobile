import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';

import '../../../components/app_button/app_button.dart';
import '../../../components/app_card/app_card.dart';
import '../../../components/app_curved_scaffold/app_curved_scaffold.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import '../../../core/theme/app_theme/app_theme.dart';
import 'top_up_result.dart';

const _successGreen = Color(0xFF499A13);
const _successSoft = Color(0xFFE8F5DC);
const _failureRed = Color(0xFFD90000);
const _failureSoft = Color(0xFFFCE6E6);
const _successIconAsset = 'assets/images/dialogs/top_up_success.png';

class TopUpResultShell extends StatelessWidget {
  const TopUpResultShell({
    super.key,
    required this.result,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.onBack,
  });

  final TopUpResult result;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
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

    final errorTitle = result.errorTitleKey?.tr() ?? result.errorTitle;
    final errorBody = result.errorBodyKey?.tr() ?? result.errorBody;
    final when = DateFormat('d MMM yyyy, hh:mm a').format(result.occurredAt);

    final detailRows = <(String, String)>[
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

    return AppCurvedScaffold(
      title: Text('topup.detail_page_title'.tr()),
      showBack: true,
      onBack: onBack ?? () => Navigator.of(context).maybePop(),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: AppCard(
                elevated: true,
                bordered: false,
                padding: const EdgeInsets.fromLTRB(16, 22, 16, 18),
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: iconBg,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: iconColor.withValues(alpha: 0.18),
                          width: 1,
                        ),
                      ),
                      child: _isSuccess
                          ? Image.asset(
                              _successIconAsset,
                              width: 40,
                              height: 40,
                              fit: BoxFit.contain,
                            )
                          : Icon(
                              _isPending
                                  ? LucideIcons.loader_circle
                                  : LucideIcons.circle_x,
                              size: 34,
                              color: iconColor,
                            ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      titleKey.tr(),
                      textAlign: TextAlign.center,
                      style: AppTheme.english(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      bodyKey.tr(),
                      textAlign: TextAlign.center,
                      style: AppTheme.english(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMuted,
                        height: 1.45,
                      ),
                    ),
                    if (_isSuccess) ...[
                      const SizedBox(height: 20),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '+${result.amountPoints}',
                              style: AppTheme.english(
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                height: 1.1,
                              ),
                            ),
                            TextSpan(
                              text: ' ${'topup.points_unit'.tr()}',
                              style: AppTheme.english(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    if (!_isSuccess &&
                        (errorTitle != null || errorBody != null)) ...[
                      const SizedBox(height: 18),
                      _ErrorBanner(title: errorTitle, body: errorBody),
                    ],
                    const SizedBox(height: 20),
                    _DetailRows(
                      rows: detailRows,
                      statusColor: statusColor,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              children: [
                AppButton(
                  label: primaryLabel,
                  onPressed: onPrimary,
                ),
                if (secondaryLabel != null && onSecondary != null) ...[
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: onSecondary,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      minimumSize: const Size.fromHeight(42),
                    ),
                    child: Text(
                      secondaryLabel!,
                      style: AppTheme.english(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({this.title, this.body});

  final String? title;
  final String? body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: _failureSoft,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _failureRed.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Text(
              title!,
              style: AppTheme.english(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _failureRed,
              ),
            ),
          if (title != null && body != null) const SizedBox(height: 4),
          if (body != null)
            Text(
              body!,
              style: AppTheme.english(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textMuted,
                height: 1.4,
              ),
            ),
        ],
      ),
    );
  }
}

class _DetailRows extends StatelessWidget {
  const _DetailRows({
    required this.rows,
    required this.statusColor,
  });

  final List<(String, String)> rows;
  final Color statusColor;

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
            crossAxisAlignment: CrossAxisAlignment.start,
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
                child: Text(
                  rows[i].$2,
                  textAlign: TextAlign.right,
                  style: AppTheme.english(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: i == rows.length - 1
                        ? statusColor
                        : AppColors.textPrimary,
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
