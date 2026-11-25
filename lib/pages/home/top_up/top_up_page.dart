import 'dart:async';

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
import '../../../components/processing_status/processing_status.dart';
import '../../../core/network/api_error_text.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/message_codes.dart';
import '../../../core/network/offline_navigation.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import '../../../core/theme/app_style/app_style.dart';
import '../../../core/theme/app_theme/app_theme.dart';
import '../../../core/utils/api_field_error.dart';
import '../../../core/utils/loading_helper.dart';
import '../../../data/top_up/top_up_repository.dart';
import '../../profile/profile/profile_controller.dart';
import 'top_up_controller.dart';
import 'top_up_pin_parser.dart';

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
  bool _checkingSerial = false;
  bool _processingOpen = false;

  static const _serialLength = 16;
  static const _accountMaxLength = 15;

  bool get _canCheckSerial => _serial.text.trim().length == _serialLength;

  String get _pinDigits => _pin.text.replaceAll(RegExp(r'\D'), '');

  bool get _canSubmit =>
      _account.text.trim().length >= 9 &&
      _account.text.trim().length <= _accountMaxLength &&
      _pinDigits.length == 16;

  bool _hasPhoneFieldError(ApiException error) {
    final data = error.responseData;
    final errors = data is Map ? data['errors'] : null;
    return errors is Map && errors.containsKey('phone');
  }

  void _prefillAccount(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    final value = digits.length > _accountMaxLength
        ? digits.substring(0, _accountMaxLength)
        : digits;
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
    if (_checkingSerial) return;
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

    setState(() {
      _serialErrorKey = null;
      _checkingSerial = true;
    });
    try {
      while (true) {
        try {
          final result = await LoadingHelper.runWithLoading(
            () => ref.read(topUpControllerProvider.notifier).checkSerialNo(
                  value,
                ),
            dismissAnimation: false,
          );
          if (!mounted) return;

          _unfocusInputs();
          setState(() => _serial.clear());
          if (result.isValid) {
            await showAppSuccessModal(
              context,
              title: 'topup.serial_valid_title'.tr(),
              body: apiMessageText(result.message ?? MessageCodes.topupValid),
            );
          } else {
            final alreadyUsed =
                result.status == TopUpSerialCheckStatus.alreadyUsed;
            await showAppFailureModal(
              context,
              title: alreadyUsed
                  ? 'topup.serial_invalid_title'.tr()
                  : 'topup.serial_invalid_card_title'.tr(),
              body: apiMessageText(
                result.message ??
                    (alreadyUsed
                        ? MessageCodes.topupAlreadyUsed
                        : MessageCodes.topupInvalid),
              ),
            );
          }
          return;
        } on ApiException catch (error) {
          if (isServerUnavailableError(error)) {
            if (!mounted) return;
            final shouldRetry = await showServerUnavailableModal(context);
            if (!mounted || !shouldRetry) return;
            continue;
          }
          if (!isUnreachableError(error)) rethrow;
          if (!mounted) return;
          final shouldRetry = await showOfflineModal(context);
          if (!mounted || !shouldRetry) return;
        }
      }
    } on ApiException catch (error) {
      debugPrint('Top-up error: $error');
      if (!mounted) return;
      _unfocusInputs();
      await showApiErrorModal(context, error);
    } catch (_) {
      if (!mounted) return;
      _unfocusInputs();
      await showAppFailureModal(
        context,
        title: 'topup.verify_fail_title'.tr(),
        body: 'topup.verify_fail_body'.tr(),
      );
    } finally {
      if (mounted) setState(() => _checkingSerial = false);
    }
  }

  Future<void> _showProcessing() async {
    if (_processingOpen) return;
    _processingOpen = true;
    final opened = Completer<void>();
    unawaited(
      showGeneralDialog<void>(
        context: context,
        barrierDismissible: false,
        barrierLabel:
            MaterialLocalizations.of(context).modalBarrierDismissLabel,
        barrierColor: const Color(0x6B000000),
        transitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (ctx, animation, secondaryAnimation) {
          if (!opened.isCompleted) opened.complete();
          return Center(
            child: ProcessingStatus(
              label: 'common.processing'.tr(),
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
      ).whenComplete(() {
        _processingOpen = false;
      }),
    );
    await opened.future;
  }

  void _closeProcessingDialog() {
    if (!_processingOpen) return;
    _processingOpen = false;
    if (mounted && Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  Future<void> _submit() async {
    if (ref.read(topUpControllerProvider).isSubmitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    try {
      final account = _account.text.trim();
      final pin = _pinDigits;
      late final TopUpAccountResult response;
      while (true) {
        try {
          await _showProcessing();
          final result =
              await ref.read(topUpControllerProvider.notifier).submit(
                    phone: account,
                    pin: pin,
                  );
          if (result == null) {
            _closeProcessingDialog();
            return;
          }
          response = result;
          break;
        } on ApiException catch (error) {
          if (isServerUnavailableError(error)) {
            if (!mounted) return;
            _closeProcessingDialog();
            final shouldRetry = await showServerUnavailableModal(context);
            if (!mounted || !shouldRetry) return;
            continue;
          }
          if (!isUnreachableError(error)) rethrow;
          if (!mounted) return;
          _closeProcessingDialog();
          final shouldRetry = await showOfflineModal(context);
          if (!mounted || !shouldRetry) return;
        }
      }
      if (!mounted) return;
      _closeProcessingDialog();

      if (!response.isSuccess) {
        _unfocusInputs();
        if (response.message == MessageCodes.topupAccountNotFound) {
          await _showAccountNotFoundModal();
          return;
        }
        await showAppFailureModal(
          context,
          title: 'topup.redeem_failure_title'.tr(),
          body: apiMessageText(
            response.message ?? MessageCodes.topupActionIncomplete,
          ),
        );
        return;
      }

      _unfocusInputs();
      final profileRefresh =
          ref.read(profileControllerProvider.notifier).fetchProfile();
      await showAppSuccessModal(
        context,
        title: 'topup.redeem_success_title'.tr(),
        body: apiMessageText(response.message ?? MessageCodes.topupSuccess),
      );
      if (!mounted) return;
      await profileRefresh;
      _pin.clear();
      setState(() {});
    } on ApiException catch (error) {
      if (!mounted) return;
      _closeProcessingDialog();
      _unfocusInputs();
      if (_hasPhoneFieldError(error)) {
        await showAppFailureModal(
          context,
          title: 'topup.account_invalid_title'.tr(),
          body: 'topup.account_invalid_body'.tr(),
        );
        return;
      }
      if (error.code == MessageCodes.topupAccountNotFound) {
        await _showAccountNotFoundModal();
        return;
      }
      if (error.code == MessageCodes.topupCardInvalid) {
        await showAppFailureModal(
          context,
          title: 'topup.serial_invalid_card_title'.tr(),
          body: apiErrorText(error),
        );
        return;
      }
      await showApiErrorModal(context, error);
    } catch (_) {
      if (!mounted) return;
      _closeProcessingDialog();
      _unfocusInputs();
      await showAppFailureModal(
        context,
        title: 'topup.result_failure_title'.tr(),
        body: 'topup.result_failure_body'.tr(),
      );
    }
  }

  Future<void> _showAccountNotFoundModal() {
    return showAppFailureModal(
      context,
      title: apiMessageText(MessageCodes.topupAccountNotFound),
      body: 'topup.invalid_user_account_body'.tr(),
    );
  }

  void _unfocusInputs() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final topUpState = ref.watch(topUpControllerProvider);
    final profile = ref.watch(profileControllerProvider);
    _prefillAccount(profile.phone);

    return AppCurvedScaffold(
      title: Text('topup.form_title'.tr()),
      showBack: true,
      onBack: () => context.pop(),
      body: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(overscroll: false),
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Form(
            key: _formKey,
            child: AppCard(
              padding: const EdgeInsets.all(16),
              borderRadius: AppStyle.borderRadiusLg,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Image.asset(
                          'assets/images/quick_actions/top_up.png',
                          width: 20,
                          height: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'topup.card_title'.tr(),
                          style: AppTheme.english(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                            height: AppStyle.lineHeightTitle,
                            letterSpacing: -0.15,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AppPillActionInput(
                    controller: _serial,
                    label: 'topup.serial_label'.tr(),
                    hint: 'topup.serial_hint'.tr(),
                    actionLabel: 'topup.check'.tr(),
                    actionEnabled: !_checkingSerial && _canCheckSerial,
                    actionActive: !_checkingSerial && _canCheckSerial,
                    onAction: _checkSerial,
                    maxLength: _serialLength,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    textInputAction: TextInputAction.done,
                    onChanged: (_) => setState(() => _serialErrorKey = null),
                  ),
                  SizedBox(
                    height: AppStyle.errorSlotHeight,
                    child: _serialErrorKey == null
                        ? null
                        : Align(
                            alignment: Alignment.bottomLeft,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                _serialErrorKey!.tr(),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTheme.fieldError(),
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(height: 4),
                  AppInput(
                    controller: _account,
                    label: 'topup.account_label'.tr(),
                    hint: 'topup.account_hint'.tr(),
                    suffixIcon: LucideIcons.user,
                    keyboardType: TextInputType.phone,
                    maxLength: _accountMaxLength,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => setState(() {}),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'topup.account_required'.tr();
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 2),
                  AppScanInput(
                    controller: _pin,
                    label: 'topup.pin_label'.tr(),
                    hint: 'topup.pin_hint'.tr(),
                    obscureText: false,
                    keyboardType: TextInputType.number,
                    maxLength: 19,
                    inputFormatters: [
                      PinSpaceFormatter(),
                    ],
                    scanValueParser: extractPinFromQr,
                    scanInvalidMessage: 'topup.scan_pin_not_found'.tr(),
                    textInputAction: TextInputAction.done,
                    onChanged: (_) => setState(() {}),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'topup.pin_required'.tr();
                      }
                      if (_pinDigits.length != 16) {
                        return 'topup.pin_invalid'.tr();
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  AppButton(
                    label: 'topup.submit'.tr(),
                    height: 44,
                    fontSize: 14,
                    onPressed:
                        _canSubmit && !topUpState.isSubmitting ? _submit : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PinSpaceFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limitedDigits = digits.length > 16 ? digits.substring(0, 16) : digits;
    final formatted = limitedDigits
        .replaceAllMapped(
          RegExp(r'.{4}'),
          (match) => '${match.group(0)} ',
        )
        .trimRight();

    int formattedOffset(int inputOffset) {
      final safeOffset = inputOffset.clamp(0, newValue.text.length).toInt();
      var digitsBefore = newValue.text
          .substring(0, safeOffset)
          .replaceAll(RegExp(r'\D'), '')
          .length;
      if (digitsBefore > limitedDigits.length) {
        digitsBefore = limitedDigits.length;
      }
      final spacesBefore = digitsBefore == 0 ? 0 : (digitsBefore - 1) ~/ 4;
      return digitsBefore + spacesBefore;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection(
        baseOffset: formattedOffset(newValue.selection.baseOffset),
        extentOffset: formattedOffset(newValue.selection.extentOffset),
        affinity: newValue.selection.affinity,
        isDirectional: newValue.selection.isDirectional,
      ),
    );
  }
}
