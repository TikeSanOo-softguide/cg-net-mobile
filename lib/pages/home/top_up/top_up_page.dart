import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../components/app_button/app_button.dart';
import '../../../components/app_card/app_card.dart';
import '../../../components/app_dialog/app_dialog.dart';
import '../../../components/app_input/app_input.dart';
import '../../../components/app_pill_action_input/app_pill_action_input.dart';
import '../../../components/app_scan_input/app_scan_input.dart';
import '../../../components/quick_action_icon_chip/quick_action_icon_chip.dart';
import '../../../core/network/api_error_text.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/idempotency_key.dart';
import '../../../core/network/offline_navigation.dart';
import '../../../core/router/route_names/route_names.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import '../../../core/theme/app_style/app_style.dart';
import '../../../core/theme/app_theme/app_theme.dart';
import '../../../data/top_up/top_up_repository.dart';
import 'top_up_result.dart';

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

  static const _serialLength = 16;
  static const _fallbackAmount = 0;

  int get _serialLen => _serial.text.trim().length;

  bool get _checkEnabled => _serialLen == 0 || _serialLen == _serialLength;
  bool get _checkActive => _serialLen == _serialLength;

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

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _serialErrorKey = null);
    _serialFieldKey.currentState?.validate();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _submitting = true);
    _showProcessing();

    try {
      final serial = _serial.text.trim();
      final account = _account.text.trim();
      final pin = _pin.text.trim();
      final now = DateTime.now();
      final idempotencyKey = IdempotencyKey.forTopUp(phone: account);
      final response = await ref.read(topUpRepositoryProvider).topUpAccount(
            phone: account,
            pin: pin,
            idempotencyKey: idempotencyKey,
          );
      if (!mounted) return;

      late final TopUpResult result;
      if (!response.isSuccess) {
        result = TopUpResult.failure(
          amountPoints: response.amountPoints ?? _fallbackAmount,
          serialRaw: serial.isEmpty ? '0000000000000000' : serial,
          transactionId: response.transactionNo ?? 'TXN-UNKNOWN',
          occurredAt: now,
          errorTitleKey: 'topup.result_failure_title',
          errorBody: response.message,
        );
      } else {
        result = TopUpResult.success(
          amountPoints: response.amountPoints ?? _fallbackAmount,
          serialRaw: serial.isEmpty ? '0000000000000000' : serial,
          transactionId: response.transactionNo ?? 'TXN-UNKNOWN',
          occurredAt: now,
        );
      }

      _closeProcessingDialog();
      if (!mounted) return;

      switch (result.status) {
        case TopUpTxnStatus.success:
          context.pushReplacementNamed(RouteNames.topUpSuccess, extra: result);
          return;
        case TopUpTxnStatus.failure:
          context.pushReplacementNamed(RouteNames.topUpFailure, extra: result);
          return;
        case TopUpTxnStatus.pending:
          context.pushReplacementNamed(RouteNames.topUpPending, extra: result);
          return;
      }
    } on ApiException catch (error) {
      _closeProcessingDialog();
      if (!mounted) return;
      if (isOfflineError(error)) {
        await openNoInternetPage(context);
        return;
      }
      final serial = _serial.text.trim();
      context.pushNamed(
        RouteNames.topUpFailure,
        extra: TopUpResult.failure(
          amountPoints: _fallbackAmount,
          serialRaw: serial.isEmpty ? '0000000000000000' : serial,
          transactionId: 'TXN-UNKNOWN',
          errorTitleKey: 'topup.result_failure_title',
          errorBody: apiErrorText(error),
        ),
      );
    } catch (_) {
      _closeProcessingDialog();
      if (!mounted) return;
      final serial = _serial.text.trim();
      context.pushNamed(
        RouteNames.topUpFailure,
        extra: TopUpResult.failure(
          amountPoints: _fallbackAmount,
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

  void _closeProcessingDialog() {
    if (mounted && Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  Widget _cardHeader({
    required String index,
    required String title,
    required String body,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            index,
            style: AppTheme.english(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTheme.english(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.2,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                body,
                style: AppTheme.english(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textMuted,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.systemOverlayImmersive,
      child: Scaffold(
        backgroundColor: AppColors.primary,
        resizeToAvoidBottomInset: true,
        body: Column(
          children: [
            _TopUpHeader(onBack: () => context.pop()),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(AppStyle.radiusCurve),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                    children: [
                      AppCard(
                        elevated: false,
                        bordered: false,
                        borderRadius: AppStyle.borderRadiusLg,
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _cardHeader(
                              index: '1',
                              title: 'topup.step_verify_title'.tr(),
                              body: 'topup.step_verify_body'.tr(),
                            ),
                            const SizedBox(height: 16),
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
                                setState(() {
                                  _serialErrorKey = null;
                                });
                                _serialFieldKey.currentState?.validate();
                              },
                              validator: (_) => _serialErrorKey?.tr(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      AppCard(
                        elevated: false,
                        bordered: false,
                        borderRadius: AppStyle.borderRadiusLg,
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _cardHeader(
                              index: '2',
                              title: 'topup.step_details_title'.tr(),
                              body: 'topup.step_details_body'.tr(),
                            ),
                            const SizedBox(height: 16),
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
                            const SizedBox(height: 14),
                            AppScanInput(
                              controller: _pin,
                              label: 'topup.pin_label'.tr(),
                              hint: 'topup.pin_hint'.tr(),
                              obscureText: true,
                              keyboardType: TextInputType.number,
                              maxLength: 12,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _submit(),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'topup.pin_required'.tr();
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            AppButton(
                              label: 'topup.submit'.tr(),
                              onPressed: _submitting ? null : _submit,
                              isLoading: _submitting,
                              height: 42,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Clear primary header — flat brand wash, compact title block.
class _TopUpHeader extends StatelessWidget {
  const _TopUpHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.primary,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onBack,
                  borderRadius: BorderRadius.circular(8),
                  child: Ink(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.18),
                        width: 0.7,
                      ),
                    ),
                    child: const Icon(
                      LucideIcons.chevron_left,
                      size: 18,
                      color: AppColors.onPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  QuickActionIconChip(
                    asset: QuickActionIconChip.topUpAsset,
                    background: Colors.white.withValues(alpha: 0.14),
                    tint: AppColors.onPrimary,
                    size: 40,
                    iconSize: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'topup.hero_title'.tr(),
                          style: AppTheme.english(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onPrimary,
                            letterSpacing: 0.3,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'topup.hero_body'.tr(),
                          style: AppTheme.english(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: AppColors.onPrimary.withValues(alpha: 0.82),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
