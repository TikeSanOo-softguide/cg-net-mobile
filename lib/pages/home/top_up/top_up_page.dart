import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../components/activity_list_card/activity_list_card.dart';
import '../../../components/app_card/app_card.dart';
import '../../../components/app_curved_scaffold/app_curved_scaffold.dart';
import '../../../components/app_dialog/app_dialog.dart';
import '../../../components/app_input/app_input.dart';
import '../../../components/app_pill_action_input/app_pill_action_input.dart';
import '../../../components/app_scan_input/app_scan_input.dart';
import '../../../components/quick_action_icon_chip/quick_action_icon_chip.dart';
import '../../../core/router/route_names/route_names.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import '../../../core/theme/app_theme/app_theme.dart';
import 'top_up_result.dart';

/// Top-up — card layout matching Transfer page style.
class TopUpPage extends StatefulWidget {
  const TopUpPage({super.key});

  @override
  State<TopUpPage> createState() => _TopUpPageState();
}

class _TopUpPageState extends State<TopUpPage> {
  final _serial = TextEditingController();
  final _account = TextEditingController();
  final _pin = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _serialFieldKey = GlobalKey<FormFieldState<String>>();
  String? _serialErrorKey;
  bool _submitting = false;

  static const _serialLength = 16;
  static const _validSerial = '1234567890123456';
  static const _mockAmount = 500;

  int get _serialLen => _serial.text.trim().length;

  /// Empty → tappable light. Incomplete → disabled light. Exact 16 → primary.
  bool get _checkEnabled => _serialLen == 0 || _serialLen == _serialLength;
  bool get _checkActive => _serialLen == _serialLength;

  List<ActivityItem> get _recent => [
        ActivityItem(
          id: 'tu1',
          kind: ActivityKind.topUp,
          titleKey: 'history.item_topup_title',
          subtitleKey: 'topup.recent_added',
          amount: 2500,
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          isCredit: true,
        ),
        ActivityItem(
          id: 'tu2',
          kind: ActivityKind.topUp,
          titleKey: 'history.item_topup_title',
          subtitleKey: 'topup.recent_added',
          amount: 500,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          isCredit: true,
        ),
        ActivityItem(
          id: 'tu3',
          kind: ActivityKind.topUp,
          titleKey: 'history.item_topup_title',
          subtitleKey: 'topup.recent_added',
          amount: 100,
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
          isCredit: true,
        ),
      ];

  @override
  void dispose() {
    _serial.dispose();
    _account.dispose();
    _pin.dispose();
    super.dispose();
  }

  Future<void> _checkSerial() async {
    final value = _serial.text.trim();
    final len = value.length;
    if (len == 0) {
      setState(() => _serialErrorKey = 'topup.serial_required');
      _serialFieldKey.currentState?.validate();
      return;
    }
    setState(() => _serialErrorKey = null);
    _serialFieldKey.currentState?.validate();
    if (len == _serialLength && value == _validSerial) {
      await showAppSuccessModal(
        context,
        title: 'topup.verified'.tr(),
        body: 'topup.verify_amount'.tr(),
      );
      return;
    }
    if (len == _serialLength) {
      await showAppFailureModal(
        context,
        title: 'topup.verify_fail_title'.tr(),
        body: 'topup.verify_fail_body'.tr(),
      );
    }
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _submitting = true);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: Center(
          child: Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 22, 28, 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'topup.processing'.tr(),
                    style: AppTheme.english(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    try {
      // Mock Top-Up API — never logs or returns PIN.
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      if (!mounted) return;

      final serial = _serial.text.trim();
      final pin = _pin.text.trim();
      final txnId =
          'TXN-${DateFormat('yyyyMMdd').format(DateTime.now())}-${DateTime.now().millisecond.toString().padLeft(3, '0')}';
      final now = DateTime.now();

      late final TopUpResult result;
      // Demo: incomplete PIN (not 12 digits) → failure page.
      if (pin.length != 12) {
        result = TopUpResult.failure(
          amountPoints: _mockAmount,
          serialRaw: serial.isEmpty ? '0000000000000000' : serial,
          transactionId: txnId,
          occurredAt: now,
          errorTitleKey: 'topup.result_failure_title',
          errorBodyKey: 'topup.pin_invalid',
        );
      } else {
        result = TopUpResult.success(
          amountPoints: _mockAmount,
          serialRaw: serial.isEmpty ? '0000000000000000' : serial,
          transactionId: txnId,
          occurredAt: now,
        );
      }

      Navigator.of(context, rootNavigator: true).pop(); // loading
      if (!mounted) return;

      switch (result.status) {
        case TopUpTxnStatus.success:
          context.pushReplacementNamed(RouteNames.topUpSuccess, extra: result);
        case TopUpTxnStatus.failure:
          context.pushReplacementNamed(RouteNames.topUpFailure, extra: result);
        case TopUpTxnStatus.pending:
          context.pushReplacementNamed(RouteNames.topUpPending, extra: result);
      }
    } catch (_) {
      if (mounted && Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      if (!mounted) return;
      final serial = _serial.text.trim();
      context.pushNamed(
        RouteNames.topUpFailure,
        extra: TopUpResult.failure(
          amountPoints: _mockAmount,
          serialRaw: serial.isEmpty ? '0000000000000000' : serial,
          transactionId: 'TXN-UNKNOWN',
          errorTitleKey: 'topup.result_failure_title',
          errorBodyKey: 'topup.result_failure_body',
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCurvedScaffold(
      title: Text('topup.title'.tr()),
      showBack: true,
      onBack: () => context.pop(),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            AppCard(
              elevated: true,
              bordered: false,
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const QuickActionIconChip(
                        asset: QuickActionIconChip.topUpAsset,
                        background: QuickActionIconChip.topUpSoft,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'topup.form_title'.tr(),
                          style: AppTheme.english(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  AppPillActionInput(
                    fieldKey: _serialFieldKey,
                    controller: _serial,
                    label: 'topup.serial_label'.tr(),
                    hint: 'topup.serial_hint'.tr(),
                    actionLabel: 'topup.check'.tr(),
                    actionEnabled: _checkEnabled,
                    actionActive: _checkActive,
                    onAction: _checkSerial,
                    maxLength: _serialLength,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) {
                      setState(() => _serialErrorKey = null);
                      _serialFieldKey.currentState?.validate();
                    },
                    validator: (_) => _serialErrorKey?.tr(),
                  ),
                  const SizedBox(height: 10),
                  AppInput(
                    controller: _account,
                    label: 'topup.account_label'.tr(),
                    hint: 'topup.account_hint'.tr(),
                    prefixIcon: LucideIcons.hash,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'topup.account_required'.tr();
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  AppScanInput(
                    controller: _pin,
                    label: 'topup.pin_label'.tr(),
                    hint: 'topup.pin_hint'.tr(),
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    maxLength: 12,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'topup.pin_required'.tr();
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: SizedBox(
                      height: 36,
                      child: FilledButton(
                        onPressed: _submitting ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.onPrimary,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: Text(
                          'topup.submit'.tr(),
                          style: AppTheme.english(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'topup.recent_title'.tr(),
              style: AppTheme.sectionTitle(),
            ),
            const SizedBox(height: 10),
            for (var i = 0; i < _recent.length; i++) ...[
              if (i > 0) const SizedBox(height: 5),
              ActivityListCard(
                item: _recent[i],
                index: i,
                onTap: () => context.pushNamed(
                  RouteNames.topUpSuccess,
                  extra: TopUpResult.fromActivityAmount(
                    amountPoints: _recent[i].amount,
                    transactionId: 'TXN-${_recent[i].id.toUpperCase()}',
                    occurredAt: _recent[i].createdAt,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
