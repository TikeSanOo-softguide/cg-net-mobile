import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router/go_router.dart';

import '../../../components/activity_list_card/activity_list_card.dart';
import '../../../components/app_card/app_card.dart';
import '../../../components/app_curved_scaffold/app_curved_scaffold.dart';
import '../../../components/app_dialog/app_dialog.dart';
import '../../../components/app_input/app_input.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import '../../../core/theme/app_theme/app_theme.dart';

/// Transfer points to another account.
class TransferPage extends StatefulWidget {
  const TransferPage({super.key});

  @override
  State<TransferPage> createState() => _TransferPageState();
}

class _TransferPageState extends State<TransferPage> {
  static const _amounts = [50, 100, 250, 500, 1000];

  final _account = TextEditingController();
  final _amount = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  int? _selectedAmount;

  List<ActivityItem> get _recent => [
        ActivityItem(
          id: 't1',
          kind: ActivityKind.transfer,
          title: '09970071489',
          subtitle: 'transfer.recent_sent'.tr(),
          amount: 500,
          createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        ),
        ActivityItem(
          id: 't2',
          kind: ActivityKind.transfer,
          title: '09791234567',
          subtitle: 'transfer.recent_sent'.tr(),
          amount: 100,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        ActivityItem(
          id: 't3',
          kind: ActivityKind.transfer,
          title: '09420111222',
          subtitle: 'transfer.recent_sent'.tr(),
          amount: 250,
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
        ),
      ];

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
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await showAppSuccessModal(
      context,
      title: 'transfer.success_title'.tr(),
      body: 'transfer.success_body'.tr(),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          LucideIcons.arrow_left_right,
                          size: 16,
                          color: AppColors.primary,
                        ),
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
                      child: FilledButton.icon(
                        onPressed: _submit,
                        icon: const Icon(LucideIcons.send, size: 14),
                        label: Text(
                          'transfer.submit'.tr(),
                          style: AppTheme.english(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onPrimary,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.onPrimary,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
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
              if (i > 0) const SizedBox(height: 10),
              ActivityListCard(
                item: _recent[i],
                index: i,
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
