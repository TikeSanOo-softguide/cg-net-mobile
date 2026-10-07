import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../components/app_button/app_button.dart';
import '../../../components/app_card/app_card.dart';
import '../../../components/app_curved_scaffold/app_curved_scaffold.dart';
import '../../../components/app_dialog/app_dialog.dart';
import '../../../components/app_input/app_input.dart';
import '../../../components/app_pill_action_input/app_pill_action_input.dart';
import '../../../components/app_scan_input/app_scan_input.dart';
import '../../../core/network/api_error_text.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/auth_api/auth_api.dart';
import '../../../core/network/idempotency_key.dart';
import '../../../core/network/offline_navigation.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import '../../../core/theme/app_style/app_style.dart';
import '../../../core/theme/app_theme/app_theme.dart';
import '../../../data/top_up/top_up_repository.dart';

/// Top-up screen with optional serial verification and backend submission flow.
class TopUpPage extends ConsumerStatefulWidget {
  const TopUpPage({super.key});

  @override
  ConsumerState<TopUpPage> createState() => _TopUpPageState();
}

class _TopUpPageState extends ConsumerState<TopUpPage> {
  final _serial = TextEditingController();
  final _account = TextEditingController();
  final _pin = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _serialFieldKey = GlobalKey<FormFieldState<String>>();
  String? _serialErrorKey;
  bool _submitting = false;
  bool _accountEdited = false;

  static const _serialLength = 16;
  static const _fallbackAmount = 0;

  int get _serialLen => _serial.text.trim().length;
  bool get _canSubmit =>
      !_submitting &&
      _account.text.trim().isNotEmpty &&
      _pin.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    ref.listenManual(
      customerProfileProvider,
      (previous, next) {
        next.whenData((profile) {
          if (_accountEdited || profile.accountNumber.isEmpty) return;
          _account.value = TextEditingValue(
            text: profile.accountNumber,
            selection: TextSelection.collapsed(
              offset: profile.accountNumber.length,
            ),
          );
          if (mounted) setState(() {});
        });
      },
      fireImmediately: true,
    );
  }

  bool get _checkEnabled => _serialLen == 0 || _serialLen == _serialLength;

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
    if (len != _serialLength) {
      setState(() => _serialErrorKey = 'topup.serial_required');
      _serialFieldKey.currentState?.validate();
      return;
    }

    setState(() => _serialErrorKey = null);
    _serialFieldKey.currentState?.validate();

    try {
      final result =
          await ref.read(topUpRepositoryProvider).checkSerialNo(value);
      if (!mounted) return;

      if (result.isValid) {
        await showAppSuccessModal(
          context,
          title: 'topup.verified'.tr(),
          body: result.message?.trim().isNotEmpty == true
              ? result.message!
              : 'topup.verify_amount'.tr(),
        );
      } else {
        await showAppFailureModal(
          context,
          title: 'topup.verify_fail_title'.tr(),
          body: result.message?.trim().isNotEmpty == true
              ? result.message!
              : 'topup.verify_fail_body'.tr(),
        );
      }
    } on ApiException catch (error) {
      if (!mounted) return;
      if (isOfflineError(error)) {
        final shouldRetry = await openNoInternetPage(context);
        if (shouldRetry == true && mounted) {
          await _checkSerial();
        }
        return;
      }
      await showAppFailureModal(
        context,
        title: 'topup.verify_fail_title'.tr(),
        body: apiErrorText(error),
      );
    } catch (_) {
      if (!mounted) return;
      await showAppFailureModal(
        context,
        title: 'topup.verify_fail_title'.tr(),
        body: 'topup.verify_fail_body'.tr(),
      );
    }
  }

  Future<void> _showProcessing() {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: const Color(0x6B000000),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (ctx, animation, secondaryAnimation) {
        return Center(
          child: Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
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
                      letterSpacing: -0.15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (ctx, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  Future<void> _showTopUpResultModal({
    required bool success,
    required String title,
    required String body,
  }) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: const Color(0x6B000000),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return Dialog(
          backgroundColor: AppColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    tooltip: 'common.close'.tr(),
                    icon: const Icon(
                      LucideIcons.x,
                      size: 20,
                      color: AppColors.textMuted,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTheme.english(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: success ? AppColors.primary : AppColors.error,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: AppTheme.english(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 26),
                SizedBox(
                  width: 92,
                  height: 40,
                  child: FilledButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      elevation: 0,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                    child: Text(
                      'common.ok'.tr(),
                      style: AppTheme.english(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      transitionBuilder: (ctx, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _serialErrorKey = null);
    _serialFieldKey.currentState?.validate();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _submitting = true);
    _showProcessing();

    try {
      final account = _account.text.trim();
      final pin = _pin.text.trim();
      final idempotencyKey = IdempotencyKey.forTopUp(phone: account);
      final response = await ref.read(topUpRepositoryProvider).topUpAccount(
            phone: account,
            pin: pin,
            idempotencyKey: idempotencyKey,
          );
      if (!mounted) return;

      _closeProcessingDialog();
      if (!mounted) return;

      if (response.statusCode == 200 && response.isSuccess) {
        ref.invalidate(customerProfileProvider);
        final amountMessage = 'topup.result_success_body_amount'.tr(
          namedArgs: {
            'points': NumberFormat('#,##0')
                .format(response.amountPoints ?? _fallbackAmount),
          },
        );
        await _showTopUpResultModal(
          success: true,
          title: 'topup.result_success_title'.tr(),
          body: [
            if (response.message?.trim().isNotEmpty == true)
              response.message!.trim(),
            amountMessage,
          ].join('\n'),
        );
      } else {
        await _showTopUpResultModal(
          success: false,
          title: 'topup.result_failure_title'.tr(),
          body: apiMessageText(
            response.message,
            fallbackKey: 'topup.result_failure_body',
          ),
        );
      }
    } on ApiException catch (error) {
      _closeProcessingDialog();
      if (!mounted) return;
      if (isOfflineError(error)) {
        await openNoInternetPage(context);
        return;
      }
      await _showTopUpResultModal(
        success: false,
        title: 'topup.result_failure_title'.tr(),
        body: apiErrorText(error),
      );
    } catch (_) {
      _closeProcessingDialog();
      if (!mounted) return;
      await _showTopUpResultModal(
        success: false,
        title: 'topup.result_failure_title'.tr(),
        body: 'topup.result_failure_body'.tr(),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _closeProcessingDialog() {
    if (mounted && Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  Widget _fieldLabel(String key) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, bottom: 7),
      child: Text(
        key.tr(),
        style: AppTheme.english(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
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
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 32),
          children: [
            AppCard(
              borderRadius: AppStyle.borderRadiusMd,
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _fieldLabel('topup.serial_label'),
                  AppPillActionInput(
                    fieldKey: _serialFieldKey,
                    controller: _serial,
                    hint: 'topup.serial_hint'.tr(),
                    actionLabel: 'topup.check'.tr(),
                    actionEnabled: _checkEnabled,
                    actionActive: true,
                    onAction: _checkSerial,
                    maxLength: _serialLength,
                    textInputAction: TextInputAction.next,
                    showActionIcon: false,
                    actionFontSize: 14,
                    fieldFillColor: AppColors.primarySoft,
                    fieldBorderColor: AppColors.primarySoft,
                    onChanged: (_) {
                      setState(() {
                        _serialErrorKey = null;
                      });
                      _serialFieldKey.currentState?.validate();
                    },
                    validator: (_) => _serialErrorKey?.tr(),
                  ),
                  const SizedBox(height: 20),
                  _fieldLabel('topup.account_label'),
                  AppInput(
                    controller: _account,
                    label: null,
                    hint: 'topup.account_hint'.tr(),
                    suffixIcon: LucideIcons.user,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    fieldFillColor: AppColors.primarySoft,
                    fieldBorderColor: AppColors.primarySoft,
                    onChanged: (_) {
                      _accountEdited = true;
                      setState(() {});
                    },
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'topup.account_required'.tr();
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  _fieldLabel('topup.pin_label'),
                  AppScanInput(
                    controller: _pin,
                    label: null,
                    hint: 'topup.pin_hint'.tr(),
                    obscureText: false,
                    keyboardType: TextInputType.number,
                    maxLength: 16,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    textInputAction: TextInputAction.done,
                    fieldFillColor: AppColors.primarySoft,
                    fieldBorderColor: AppColors.primarySoft,
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _submit(),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'topup.pin_required'.tr();
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 30),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: AppStyle.borderRadiusButton,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(
                            alpha: _canSubmit ? 0.16 : 0,
                          ),
                          blurRadius: _canSubmit ? 6 : 0,
                          offset: _canSubmit ? const Offset(0, 3) : Offset.zero,
                        ),
                      ],
                    ),
                    child: AppButton(
                      label: 'topup.submit'.tr(),
                      onPressed: _canSubmit ? _submit : null,
                      isLoading: _submitting,
                      height: 40,
                      fontSize: 14,
                      disabledColor: AppColors.primary.withValues(alpha: 0.45),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
