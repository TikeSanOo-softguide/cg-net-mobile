import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../components/app_button/app_button.dart';
import '../../../components/app_card/app_card.dart';
import '../../../components/app_curved_scaffold/app_curved_scaffold.dart';
import '../../../core/network/api_error_text.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import '../../../core/theme/app_style/app_style.dart';
import '../../../core/theme/app_theme/app_theme.dart';
import 'package_buy_result.dart';

const _successGreen = Color(0xFF499A13);
const _successSoft = Color(0xFFE8F5DC);
const _failureRed = Color(0xFFD90000);
const _failureSoft = Color(0xFFFCE6E6);
const _successIconAsset = 'assets/images/dialogs/success.png';
const _failureIconAsset = 'assets/images/dialogs/failure.png';

class PackageBuyResultShell extends StatelessWidget {
  const PackageBuyResultShell({
    super.key,
    required this.result,
    required this.primaryLabel,
    required this.onPrimary,
    this.onBack,
  });

  final PackageBuyResult result;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final VoidCallback? onBack;

  bool get _isSuccess => result.status == PackageBuyTxnStatus.success;

  @override
  Widget build(BuildContext context) {
    final iconBg = _isSuccess ? _successSoft : _failureSoft;
    final titleKey = _isSuccess
        ? 'package.result_success_title'
        : (result.errorTitleKey ?? 'package.result_failure_title');
    final bodyKey = _isSuccess
        ? 'package.result_success_body'
        : (result.errorBodyKey ?? 'package.result_failure_body');
    final titleColor = _isSuccess ? _successGreen : _failureRed;
    final titleText = _isSuccess
        ? titleKey.tr()
        : result.errorTitleKey?.tr() ??
            apiMessageText(result.errorTitle, fallbackKey: titleKey);
    final bodyText = _isSuccess
        ? bodyKey.tr()
        : result.errorBodyKey?.tr() ??
            apiMessageText(result.errorBody, fallbackKey: bodyKey);
    final statusLabel = _isSuccess
        ? 'package.status_completed'.tr()
        : 'package.status_failed'.tr();

    final when = DateFormat('d MMM yyyy, hh:mm a').format(result.occurredAt);
    final priceLabel =
        '${NumberFormat('#,##0').format(result.pricePoints)} ${'topup.pts'.tr()}';

    final detailRows = <(String, String)>[
      ('package.detail_type'.tr(), 'package.type_purchase'.tr()),
      ('package.confirm_package'.tr(), result.packageTitle),
      if (result.speedMbps != null && result.speedMbps!.isNotEmpty)
        (
          'package.internet_speed'.tr(),
          '${result.speedMbps} Mbps',
        ),
      ('package.price'.tr(), priceLabel),
      (
        'package.renew'.tr(),
        result.autoRenew ? 'package.renew_on'.tr() : 'package.renew_off'.tr(),
      ),
      ('package.detail_txn'.tr(), result.transactionId),
      ('package.detail_datetime'.tr(), when),
      ('package.detail_status'.tr(), statusLabel),
    ];

    return AppCurvedScaffold(
      title: Text('package.detail_page_title'.tr()),
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
                child: Image.asset(
                  _isSuccess ? _successIconAsset : _failureIconAsset,
                  width: 28,
                  height: 28,
                  fit: BoxFit.contain,
                ),
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
                      '-${NumberFormat('#,##0').format(result.pricePoints)}',
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
                      'topup.pts'.tr(),
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
                statusColor: titleColor,
                statusBackground: _isSuccess ? _successSoft : _failureSoft,
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
