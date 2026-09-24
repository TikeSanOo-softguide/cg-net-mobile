import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../components/app_card/app_card.dart';
import '../../../components/app_dialog/app_dialog.dart';
import '../../../components/app_input/app_input.dart';
import '../../../components/app_pill_action_input/app_pill_action_input.dart';
import '../../../components/app_scan_input/app_scan_input.dart';
import '../../../components/quick_action_icon_chip/quick_action_icon_chip.dart';
import '../../../core/router/route_names/route_names.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import '../../../core/theme/app_style/app_style.dart';
import '../../../core/theme/app_theme/app_theme.dart';
import 'top_up_result.dart';

/// Top-up — luxury banner (no top nav) + steps + two cards. Logic unchanged.
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
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _submitting = true);
    _showProcessing();

    try {
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      if (!mounted) return;

      final serial = _serial.text.trim();
      final pin = _pin.text.trim();
      final txnId =
          'TXN-${DateFormat('yyyyMMdd').format(DateTime.now())}-${DateTime.now().millisecond.toString().padLeft(3, '0')}';
      final now = DateTime.now();

      late final TopUpResult result;
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

      Navigator.of(context, rootNavigator: true).pop();
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

  Widget _cardHeader({required String index, required String title, required String body}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            index,
            style: AppTheme.english(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTheme.english(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.25,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                body,
                style: AppTheme.english(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
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
            _LuxuryBanner(onBack: () => context.pop()),
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
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    children: [
                      const _PrimaryStepRail(),
                      const SizedBox(height: 16),
                      AppCard(
                        elevated: false,
                        bordered: false,
                        borderRadius: AppStyle.borderRadiusLg,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _cardHeader(
                              index: '1',
                              title: 'topup.step_verify_title'.tr(),
                              body: 'topup.step_verify_body'.tr(),
                            ),
                            const SizedBox(height: 14),
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
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      AppCard(
                        elevated: false,
                        bordered: false,
                        borderRadius: AppStyle.borderRadiusLg,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _cardHeader(
                              index: '2',
                              title: 'topup.step_details_title'.tr(),
                              body: 'topup.step_details_body'.tr(),
                            ),
                            const SizedBox(height: 14),
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
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                  ),
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

/// Luxury full-bleed banner — refined icon + title scale for iOS/Android.
class _LuxuryBanner extends StatelessWidget {
  const _LuxuryBanner({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            Color(0xFF1A18D4),
            Color(0xFF3D3BE8),
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 18, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onBack,
                  borderRadius: BorderRadius.circular(6),
                  child: Ink(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      LucideIcons.chevron_left,
                      size: 16,
                      color: AppColors.onPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.26),
                        width: 0.9,
                      ),
                    ),
                    child: Image.asset(
                      QuickActionIconChip.topUpAsset,
                      width: 24,
                      height: 24,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                      color: Colors.white,
                      colorBlendMode: BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'topup.hero_eyebrow'.tr().toUpperCase(),
                          style: AppTheme.english(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.72),
                            letterSpacing: 1.2,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'topup.hero_title'.tr(),
                          style: AppTheme.english(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.6,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'topup.hero_body'.tr(),
                          style: AppTheme.english(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.88),
                            height: 1.4,
                            letterSpacing: -0.1,
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

class _PrimaryStepRail extends StatelessWidget {
  const _PrimaryStepRail();

  static const _circle = 28.0;

  @override
  Widget build(BuildContext context) {
    final labels = [
      'topup.step_rail_verify'.tr(),
      'topup.step_rail_details'.tr(),
      'topup.step_rail_done'.tr(),
    ];

    return Column(
      children: [
        SizedBox(
          height: _circle,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                left: _circle / 2,
                right: _circle / 2,
                child: Container(
                  height: 2.5,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var i = 0; i < 3; i++)
                    Container(
                      width: _circle,
                      height: _circle,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${i + 1}',
                        style: AppTheme.english(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onPrimary,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final label in labels)
              Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: AppTheme.english(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
