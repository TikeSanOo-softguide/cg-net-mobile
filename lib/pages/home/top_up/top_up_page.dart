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
import '../../../core/router/route_names/route_names.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import '../../../core/theme/app_theme/app_theme.dart';

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
  bool _serialChecked = false;

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

  void _checkSerial() {
    final value = _serial.text.trim();
    if (value.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('topup.serial_required'.tr()),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _serialChecked = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('topup.serial_ok'.tr()),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_serialChecked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('topup.check_serial_first'.tr()),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    await showAppSuccessModal(
      context,
      title: 'topup.success_title'.tr(),
      body: 'topup.success_body'.tr(),
    );
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
                      Image.asset(
                        'assets/images/quick_actions/top_up.png',
                        width: 25,
                        height: 25,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
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
                      if (_serialChecked)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'topup.verified'.tr(),
                            style: AppTheme.english(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF15803D),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  AppInput(
                    controller: _serial,
                    label: 'topup.serial_label'.tr(),
                    hint: 'topup.serial_hint'.tr(),
                    prefixIcon: LucideIcons.barcode,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) {
                      if (_serialChecked) {
                        setState(() => _serialChecked = false);
                      }
                    },
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'topup.serial_required'.tr();
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: SizedBox(
                      height: 36,
                      child: FilledButton.icon(
                        onPressed: _checkSerial,
                        icon: const Icon(LucideIcons.badge_check, size: 14),
                        label: Text(
                          'topup.check'.tr(),
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
                  AppInput(
                    controller: _pin,
                    label: 'topup.pin_label'.tr(),
                    hint: 'topup.pin_hint'.tr(),
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    maxLength: 12,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                    suffixIcon: LucideIcons.scan_line,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'topup.pin_required'.tr();
                      }
                      if (v.trim().length != 12) {
                        return 'topup.pin_invalid'.tr();
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: SizedBox(
                      height: 36,
                      child: FilledButton.icon(
                        onPressed: _submit,
                        icon: const Icon(LucideIcons.wallet, size: 14),
                        label: Text(
                          'topup.submit'.tr(),
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
                  RouteNames.activityDetail,
                  extra: _recent[i],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
