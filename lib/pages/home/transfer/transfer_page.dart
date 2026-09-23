import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../components/activity_list_card/activity_list_card.dart';
import '../../../components/app_card/app_card.dart';
import '../../../components/app_curved_scaffold/app_curved_scaffold.dart';
import '../../../components/app_input/app_input.dart';
import '../../../components/quick_action_icon_chip/quick_action_icon_chip.dart';
import '../../../core/router/route_names/route_names.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import '../../../core/theme/app_theme/app_theme.dart';
import '../home/home_controller.dart';
import 'transfer_confirm_drawer.dart';
import 'transfer_password_modal.dart';
import 'transfer_result.dart';

/// Demo password accepted by mock transfer API.
const _demoTransferPassword = '123456';

/// Transfer points to another account.
class TransferPage extends ConsumerStatefulWidget {
  const TransferPage({super.key});

  @override
  ConsumerState<TransferPage> createState() => _TransferPageState();
}

class _TransferPageState extends ConsumerState<TransferPage> {
  static const _amounts = [50, 100, 250, 500, 1000];

  final _account = TextEditingController();
  final _amount = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  int? _selectedAmount;
  bool _submitting = false;

  List<ActivityItem> get _recent => [
        ActivityItem(
          id: 't1',
          kind: ActivityKind.transfer,
          title: '09970071489',
          subtitleKey: 'transfer.recent_sent',
          amount: 500,
          createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        ),
        ActivityItem(
          id: 't2',
          kind: ActivityKind.transfer,
          title: '09791234567',
          subtitleKey: 'transfer.recent_sent',
          amount: 100,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        ActivityItem(
          id: 't3',
          kind: ActivityKind.transfer,
          title: '09420111222',
          subtitleKey: 'transfer.recent_sent',
          amount: 250,
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
        ),
      ];

  int get _availablePoints {
    final raw = ref.read(homeControllerProvider).balanceAmount.replaceAll(',', '');
    return int.tryParse(raw) ?? 0;
  }

  @override
  void dispose() {
    _account.dispose();
    _amount.dispose();
    super.dispose();
  }

  void _selectAmount(int value) {
    setState(() {
      _selectedAmount = value;
      _amount.text = value.toString();
    });
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final account = _account.text.trim();
    final amount = int.parse(_amount.text.trim());
    final available = _availablePoints;

    // Block before confirm if balance is not enough.
    if (amount > available) {
      _formKey.currentState?.validate();
      return;
    }

    final confirmed = await showTransferConfirmDrawer(
      context,
      account: account,
      amountPoints: amount,
    );
    if (!confirmed || !mounted) return;

    final password = await showTransferPasswordModal(context);
    if (password == null || !mounted) return;

    setState(() => _submitting = true);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => PopScope(
        canPop: false,
        child: Center(
          child: Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            child: const Padding(
              padding: EdgeInsets.all(22),
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              ),
            ),
          ),
        ),
      ),
    );

    try {
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;

      final txnId =
          'TRF-${DateFormat('yyyyMMdd').format(DateTime.now())}-${DateTime.now().millisecond.toString().padLeft(3, '0')}';
      final now = DateTime.now();

      late final TransferResult result;
      if (amount > available) {
        result = TransferResult.failure(
          amountPoints: amount,
          recipientAccount: account,
          transactionId: txnId,
          occurredAt: now,
          failureReason: TransferFailureReason.insufficientPoints,
          errorTitleKey: 'transfer.result_failure_title',
          errorBodyKey: 'transfer.insufficient_points_body',
        );
      } else if (password != _demoTransferPassword) {
        result = TransferResult.failure(
          amountPoints: amount,
          recipientAccount: account,
          transactionId: txnId,
          occurredAt: now,
          failureReason: TransferFailureReason.wrongPassword,
          errorTitleKey: 'transfer.result_failure_title',
          errorBodyKey: 'transfer.wrong_password_body',
        );
      } else {
        result = TransferResult.success(
          amountPoints: amount,
          recipientAccount: account,
          transactionId: txnId,
          occurredAt: now,
        );
      }

      Navigator.of(context, rootNavigator: true).pop(); // loading
      if (!mounted) return;

      switch (result.status) {
        case TransferTxnStatus.success:
          context.pushReplacementNamed(
            RouteNames.transferSuccess,
            extra: result,
          );
        case TransferTxnStatus.failure:
          context.pushReplacementNamed(
            RouteNames.transferFailure,
            extra: result,
          );
      }
    } catch (_) {
      if (mounted && Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final available = _availablePoints;

    return AppCurvedScaffold(
      title: Text('transfer.title'.tr()),
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
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const QuickActionIconChip(
                        asset: QuickActionIconChip.transferAsset,
                        background: QuickActionIconChip.transferSoft,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'transfer.form_title'.tr(),
                          style: AppTheme.english(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'transfer.available_points'.tr(
                      namedArgs: {
                        'amount': NumberFormat('#,##0').format(available),
                      },
                    ),
                    style: AppTheme.english(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 14),
                  AppInput(
                    controller: _account,
                    label: 'transfer.account_label'.tr(),
                    hint: 'transfer.account_hint'.tr(),
                    prefixIcon: LucideIcons.hash,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'transfer.account_required'.tr();
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  AppInput(
                    controller: _amount,
                    label: 'transfer.amount_label'.tr(),
                    hint: 'transfer.amount_hint'.tr(),
                    prefixIcon: LucideIcons.coins,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    textInputAction: TextInputAction.done,
                    onChanged: (v) {
                      final n = int.tryParse(v);
                      setState(() {
                        _selectedAmount = _amounts.contains(n) ? n : null;
                      });
                    },
                    onSubmitted: (_) => _submit(),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'transfer.amount_required'.tr();
                      }
                      final n = int.tryParse(v.trim());
                      if (n == null || n <= 0) {
                        return 'transfer.amount_invalid'.tr();
                      }
                      if (n > available) {
                        return 'transfer.amount_insufficient'.tr();
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final amount in _amounts)
                        _AmountChip(
                          amount: amount,
                          selected: _selectedAmount == amount,
                          onTap: () => _selectAmount(amount),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
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
                          'transfer.submit'.tr(),
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
              'transfer.recent_title'.tr(),
              style: AppTheme.sectionTitle(),
            ),
            const SizedBox(height: 10),
            for (var i = 0; i < _recent.length; i++) ...[
              if (i > 0) const SizedBox(height: 5),
              ActivityListCard(
                item: _recent[i],
                index: i,
                onTap: () => context.pushNamed(
                  RouteNames.transferSuccess,
                  extra: TransferResult.fromActivity(
                    amountPoints: _recent[i].amount,
                    recipientAccount: _recent[i].title ??
                        _recent[i].displayTitle(context),
                    transactionId: 'TRF-${_recent[i].id.toUpperCase()}',
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

class _AmountChip extends StatelessWidget {
  const _AmountChip({
    required this.amount,
    required this.selected,
    required this.onTap,
  });

  final int amount;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: selected ? AppColors.primary : AppColors.primaryLight,
          ),
          child: Text(
            NumberFormat('#,##0').format(amount),
            style: AppTheme.english(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}
