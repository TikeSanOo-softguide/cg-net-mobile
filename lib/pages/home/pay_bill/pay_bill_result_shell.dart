import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../components/app_button/app_button.dart';
import '../../../components/app_card/app_card.dart';
import '../../../components/app_curved_scaffold/app_curved_scaffold.dart';
import '../../../core/network/message_codes.dart';
import '../../../core/utils/date_time_format.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import '../../../core/theme/app_style/app_style.dart';
import '../../../core/theme/app_theme/app_theme.dart';
import 'pay_bill_result.dart';

const _successGreen = Color(0xFF3D7A12);
const _successSoft = Color(0xFFE8F5DC);
const _successIconAsset = 'assets/images/dialogs/check.png';

class PayBillResultShell extends StatelessWidget {
  const PayBillResultShell({
    super.key,
    required this.result,
    required this.primaryLabel,
    required this.onPrimary,
    this.onBack,
    this.showPrimary = true,
  });

  final PayBillResult result;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final VoidCallback? onBack;
  final bool showPrimary;

  bool get _isSuccess => result.status == PayBillTxnStatus.success;
  bool get _isPending => result.status == PayBillTxnStatus.pending;

  @override
  Widget build(BuildContext context) {
    final iconBg = _isPending ? AppColors.primaryLight : _successSoft;
    final iconColor = _isPending ? AppColors.primary : _successGreen;
    final titleKey = _isPending
        ? MessageCodes.locKey(MessageCodes.ftthProcessing)
        : MessageCodes.locKey(MessageCodes.ftthPaid);
    final bodyKey = _isPending
        ? MessageCodes.locKeyBody(MessageCodes.ftthProcessing)
        : 'home.pay_bill_result_success_body';
    final titleColor = _isPending ? AppColors.primary : _successGreen;
    final statusLabel = _isPending
        ? 'home.pay_bill_status_processing'.tr()
        : 'home.pay_bill_status_completed'.tr();
    final titleText = titleKey.tr();
    final bodyText = bodyKey.tr();
    final occurredAt = result.occurredAt;
    final account = result.account.trim();
    final product = result.productLabel.trim();
    final speed = result.speed.trim();
    final transactionId = result.transactionId.trim();
    final remark = result.remark.trim();

    final statusTitle = 'home.pay_bill_status'.tr();
    final detailRows = <(String, String)>[
      if (account.isNotEmpty)
        ('home.pay_bill_account_number'.tr(), account),
      if (occurredAt != null)
        (
          'home.pay_bill_detail_datetime'.tr(),
          formatDateTimeOf(occurredAt),
        ),
      if (transactionId.isNotEmpty)
        ('home.pay_bill_transaction'.tr(), transactionId),
      if (product.isNotEmpty) ('home.pay_bill_product'.tr(), product),
      if (speed.isNotEmpty) ('home.pay_bill_speed'.tr(), speed),
      if (result.amountPoints > 0)
        (
          'home.pay_bill_amount'.tr(),
          '-${NumberFormat('#,##0').format(result.amountPoints)} ${'topup.pts'.tr()}',
        ),
      (statusTitle, statusLabel),
      (
        'home.pay_bill_remark'.tr(),
        remark.isEmpty ? '—' : remark,
      ),
    ];

    final statusIcon = _isPending
        ? Container(
            width: 43,
            height: 43,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              LucideIcons.loader_circle,
              size: 28,
              color: iconColor,
            ),
          )
        : Image.asset(
            _successIconAsset,
            width: 43,
            height: 43,
            fit: BoxFit.contain,
          );

    return AppCurvedScaffold(
      title: Text('home.pay_bill_result_title'.tr()),
      showBack: true,
      onBack: onBack ?? () => Navigator.of(context).maybePop(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
        child: AppCard(
          elevated: false,
          bordered: false,
          borderRadius: AppStyle.borderRadiusLg,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                child: Column(
                  children: [
                    statusIcon,
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
                    if (_isSuccess && result.amountPoints > 0) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '-${NumberFormat('#,##0').format(result.amountPoints)}',
                            style: AppTheme.english(
                              fontSize: 22,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                              height: 1.0,
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
                              height: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ],
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
                  ],
                ),
              ),
              const _TicketPerforation(),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                child: Column(
                  children: [
                    _DetailRows(
                      rows: detailRows,
                      statusTitle: statusTitle,
                      statusColor: titleColor,
                      statusBackground:
                          _isPending ? AppColors.primaryLight : _successSoft,
                    ),
                    if (showPrimary) ...[
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TicketPerforation extends StatelessWidget {
  const _TicketPerforation();

  static const _notch = 8.0;
  static const _gap = 16.0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: _gap),
      child: SizedBox(
        height: _notch * 2,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            const Positioned.fill(
              child: CustomPaint(painter: _DashLinePainter()),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Transform.translate(
                offset: const Offset(-_notch, 0),
                child: const _TicketNotch(),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Transform.translate(
                offset: const Offset(_notch, 0),
                child: const _TicketNotch(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TicketNotch extends StatelessWidget {
  const _TicketNotch();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _TicketPerforation._notch * 2,
      height: _TicketPerforation._notch * 2,
      decoration: const BoxDecoration(
        color: AppColors.background,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _DashLinePainter extends CustomPainter {
  const _DashLinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.paperBorder
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    const dash = 4.0;
    const gap = 3.0;
    const inset = 18.0;
    var x = inset;
    final y = size.height / 2;
    final end = size.width - inset;
    while (x < end) {
      final next = (x + dash).clamp(x, end);
      canvas.drawLine(Offset(x, y), Offset(next, y), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DetailRows extends StatelessWidget {
  const _DetailRows({
    required this.rows,
    required this.statusTitle,
    required this.statusColor,
    required this.statusBackground,
  });

  final List<(String, String)> rows;
  final String statusTitle;
  final Color statusColor;
  final Color statusBackground;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          Builder(
            builder: (context) {
              final isStatus = rows[i].$1 == statusTitle;
              const lineHeight = 1.35;
              return Row(
                crossAxisAlignment: isStatus
                    ? CrossAxisAlignment.center
                    : CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: Text(
                      rows[i].$1,
                      style: AppTheme.english(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMuted,
                        height: lineHeight,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 6,
                    child: isStatus
                        ? Align(
                            alignment: Alignment.centerRight,
                            child: Container(
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
                            ),
                          )
                        : Text(
                            rows[i].$2,
                            textAlign: TextAlign.right,
                            style: AppTheme.english(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                              height: lineHeight,
                            ),
                          ),
                  ),
                ],
              );
            },
          ),
        ],
      ],
    );
  }
}
