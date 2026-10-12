import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../components/app_button/app_button.dart';
import '../../../components/app_card/app_card.dart';
import '../../../components/app_curved_scaffold/app_curved_scaffold.dart';
import '../../../components/app_input/app_input.dart';
import '../../../components/app_dialog/app_dialog.dart';
import '../../../components/app_pill_action_input/app_pill_action_input.dart';
import '../../../components/app_scan_input/app_scan_input.dart';
import '../../../core/network/api_error_text.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/offline_navigation.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import '../../../core/theme/app_style/app_style.dart';
import '../../../core/theme/app_theme/app_theme.dart';
import '../../../data/customer_profile/customer_profile_repository.dart';
import 'top_up_controller.dart';

/// Top-up screen with serial verification and backend submission flow.
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
  String? _serialErrorKey;
  bool _accountPrefillAttempted = false;

  static const _serialLength = 16;

  bool get _canSubmit =>
      _account.text.trim().isNotEmpty && _pin.text.trim().length >= 16;

  String _topUpErrorMessage(ApiException error) {
    final backendMessage = error.detail?.trim();
    if (backendMessage != null && backendMessage.isNotEmpty) {
      return backendMessage;
    }

    return apiErrorText(error);
  }

  void _prefillAccount(String phone) {
    final value = phone.trim();
    if (_accountPrefillAttempted || value.isEmpty) return;

    _accountPrefillAttempted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _account.text.trim().isNotEmpty) return;
      _account.text = value;
      setState(() {});
    });
  }

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
      return;
    }
    if (len != _serialLength) {
      setState(() => _serialErrorKey = 'topup.serial_invalid_length');
      return;
    }

    setState(() => _serialErrorKey = null);

    try {
      final result =
          await ref.read(topUpControllerProvider.notifier).checkSerialNo(value);
      if (!mounted) return;

      if (result.isValid) {
        _unfocusInputs();
        await showAppSuccessModal(
          context,
          title: 'topup.verified'.tr(),
          body: result.message?.trim().isNotEmpty == true
              ? result.message!
              : 'topup.verify_amount'.tr(),
        );
      } else {
        _unfocusInputs();
        await showAppFailureModal(
          context,
          title: 'topup.verify_fail_title'.tr(),
          body: result.message?.trim().isNotEmpty == true
              ? result.message!
              : 'topup.verify_fail_body'.tr(),
        );
      }
    } on ApiException catch (error) {
      debugPrint('Top-up error: $error');
      if (!mounted) return;
      if (isOfflineError(error)) {
        final shouldRetry = await openNoInternetPage(context);
        if (shouldRetry == true && mounted) {
          await _checkSerial();
        }
        return;
      }
      _unfocusInputs();
      await showAppFailureModal(
        context,
        title: 'topup.verify_fail_title'.tr(),
        body: _topUpErrorMessage(error),
      );
    } catch (_) {
      if (!mounted) return;
      _unfocusInputs();
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
                  const SizedBox(height: 18),
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

  Future<void> _submit() async {
    if (ref.read(topUpControllerProvider).isSubmitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    _showProcessing();

    try {
      final account = _account.text.trim();
      final pin = _pin.text.trim();
      final response = await ref.read(topUpControllerProvider.notifier).submit(
            phone: account,
            pin: pin,
          );
      if (!mounted) return;
      if (response == null) {
        _closeProcessingDialog();
        return;
      }

      if (!response.isSuccess) {
        _closeProcessingDialog();
        if (!mounted) return;
        _unfocusInputs();
        await showAppFailureModal(
          context,
          title: 'topup.result_failure_title'.tr(),
          body: response.message?.trim().isNotEmpty == true
              ? response.message!
              : 'topup.result_failure_body'.tr(),
        );
        return;
      }

      _closeProcessingDialog();
      if (!mounted) return;
      _unfocusInputs();
      ref.invalidate(customerProfileProvider);
      await showAppSuccessModal(
        context,
        title: 'topup.result_success_title'.tr(),
        body: response.message?.trim().isNotEmpty == true
            ? response.message!
            : 'topup.result_success_body'.tr(),
      );
      if (!mounted) return;
      _pin.clear();
      setState(() {});
    } on ApiException catch (error) {
      _closeProcessingDialog();
      if (!mounted) return;
      if (isOfflineError(error)) {
        await openNoInternetPage(context);
        return;
      }
      _unfocusInputs();
      await showAppFailureModal(
        context,
        title: 'topup.result_failure_title'.tr(),
        body: _topUpErrorMessage(error),
      );
    } catch (_) {
      _closeProcessingDialog();
      if (!mounted) return;
      _unfocusInputs();
      await showAppFailureModal(
        context,
        title: 'topup.result_failure_title'.tr(),
        body: 'topup.result_failure_body'.tr(),
      );
    }
  }

  void _closeProcessingDialog() {
    if (mounted && Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  void _unfocusInputs() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final topUpState = ref.watch(topUpControllerProvider);
    final profile = ref.watch(customerProfileProvider);
    profile.whenData((customer) => _prefillAccount(customer.phone));
    ref.listen(customerProfileProvider, (previous, next) {
      next.whenData((profile) {
        _prefillAccount(profile.phone);
      });
    });

    return AppCurvedScaffold(
      title: Text('topup.form_title'.tr()),
      showBack: true,
      onBack: () => context.pop(),
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(16, 22, 16, 24),
        child: Form(
          key: _formKey,
          child: AppCard(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
            borderRadius: AppStyle.borderRadiusLg,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                AppPillActionInput(
                  controller: _serial,
                  label: 'topup.serial_label'.tr(),
                  hint: 'topup.serial_hint'.tr(),
                  actionLabel: 'topup.check'.tr(),
                  actionEnabled: true,
                  onAction: _checkSerial,
                  maxLength: _serialLength,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => setState(() => _serialErrorKey = null),
                ),
                SizedBox(
                  height: AppStyle.errorSlotHeight,
                  child: _serialErrorKey == null
                      ? null
                      : Align(
                          alignment: Alignment.bottomLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(
                              bottom: 4,
                              left: 12,
                            ),
                            child: Text(
                              _serialErrorKey!.tr(),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.fieldError(),
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 18),
                AppInput(
                  controller: _account,
                  label: 'topup.account_label'.tr(),
                  hint: 'topup.account_hint'.tr(),
                  prefixIcon: LucideIcons.user,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => setState(() {}),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'topup.account_required'.tr();
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),
                AppScanInput(
                  controller: _pin,
                  label: 'topup.pin_label'.tr(),
                  hint: 'topup.pin_hint'.tr(),
                  obscureText: false,
                  keyboardType: TextInputType.number,
                  maxLength: 16,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  textInputAction: TextInputAction.done,
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _submit(),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'topup.pin_required'.tr();
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                AppButton(
                  label: 'topup.submit'.tr(),
                  onPressed:
                      _canSubmit && !topUpState.isSubmitting ? _submit : null,
                  isLoading: topUpState.isSubmitting,
                  height: 42,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
