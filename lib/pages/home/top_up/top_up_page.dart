import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../components/app_button/app_button.dart';
import '../../../components/app_curved_scaffold/app_curved_scaffold.dart';
import '../../../components/app_dialog/app_dialog.dart';
import '../../../components/app_input/app_input.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import '../../../core/theme/app_style/app_style.dart';
import '../../../core/theme/app_theme/app_theme.dart';

/// Top-up — normal app form layout (serial check, account, PIN).
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
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'topup.serial_label'.tr(),
              style: AppTheme.english(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AppInput(
                    controller: _serial,
                    hint: 'topup.serial_hint'.tr(),
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
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: AppStyle.controlHeight,
                  child: FilledButton(
                    onPressed: _checkSerial,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppStyle.radiusInput,
                        ),
                      ),
                    ),
                    child: Text(
                      'topup.check'.tr(),
                      style: AppTheme.english(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AppInput(
              controller: _account,
              label: 'topup.account_label'.tr(),
              hint: 'topup.account_hint'.tr(),
              suffixIcon: LucideIcons.qr_code,
              textInputAction: TextInputAction.next,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'topup.account_required'.tr();
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            AppInput(
              controller: _pin,
              label: 'topup.pin_label'.tr(),
              hint: 'topup.pin_hint'.tr(),
              suffixIcon: LucideIcons.qr_code,
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
                if (v.trim().length != 12) {
                  return 'topup.pin_invalid'.tr();
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            AppButton(
              label: 'topup.submit'.tr(),
              height: 44,
              fontSize: 14,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
