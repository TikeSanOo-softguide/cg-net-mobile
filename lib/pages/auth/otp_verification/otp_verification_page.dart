import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../components/app_button/app_button.dart';
import '../../../components/common_auth_card/common_auth_card.dart';
import '../../../core/locale/app_locale_provider.dart';
import '../../../core/network/offline_navigation.dart';
import '../../../core/push/push_notification_service.dart';
import '../../../core/router/route_names/route_names.dart';
import '../../../core/storage/secure_storage/secure_storage.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import '../../../core/theme/app_style/app_style.dart';
import '../../../core/theme/app_theme/app_theme.dart';
import 'otp_success_drawer.dart';
import 'otp_verification_controller.dart';

class OtpVerificationPage extends ConsumerStatefulWidget {
  const OtpVerificationPage({
    super.key,
    required this.phone,
    required this.challengeId,
    this.resendAfter = 60,
  });

  final String phone;
  final String challengeId;
  final int resendAfter;

  @override
  ConsumerState<OtpVerificationPage> createState() =>
      _OtpVerificationPageState();
}

class _OtpVerificationPageState extends ConsumerState<OtpVerificationPage> {
  static const _length = 6;
  static const _gap = 12.0;
  static const _errorSlotHeight = AppStyle.errorSlotHeight;

  late String _challengeId;
  late int _secondsLeft;
  Timer? _countdown;
  String? _inlineError;
  bool _submitting = false;

  final _controllers = List.generate(_length, (_) => TextEditingController());
  final _focusNodes = List.generate(_length, (_) => FocusNode());

  @override
  void initState() {
    super.initState();
    _challengeId = widget.challengeId;
    _startCountdown(widget.resendAfter);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNodes.first.requestFocus();
    });
  }

  @override
  void dispose() {
    _countdown?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _code => _controllers.map((c) => c.text).join();

  bool get _isComplete => _code.length == _length;

  void _startCountdown(int seconds) {
    _countdown?.cancel();
    final safe = seconds < 1 ? 60 : seconds;
    setState(() => _secondsLeft = safe);
    _countdown = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsLeft <= 1) {
        timer.cancel();
        setState(() => _secondsLeft = 0);
        return;
      }
      setState(() => _secondsLeft -= 1);
    });
  }

  void _clearDigits() {
    for (final c in _controllers) {
      c.clear();
    }
    _focusNodes.first.requestFocus();
  }

  /// SMS autofill / paste — fill boxes only; user taps Verify to submit.
  void _applyDigits(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return;

    for (var i = 0; i < _length; i++) {
      _controllers[i].text = i < digits.length ? digits[i] : '';
    }

    final filled = digits.length.clamp(0, _length);
    final focusIndex =
        (filled >= _length ? _length - 1 : filled).clamp(0, _length - 1);
    _focusNodes[focusIndex].requestFocus();
    setState(() => _inlineError = null);
  }

  void _onDigitChanged(int index, String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');

    // SMS autofill / one-tap paste of the full OTP.
    if (digits.length > 1) {
      _applyDigits(digits);
      return;
    }

    _controllers[index].text = digits;
    if (digits.isNotEmpty && index < _length - 1) {
      _focusNodes[index + 1].requestFocus();
    }
    if (digits.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    setState(() => _inlineError = null);
  }

  KeyEventResult _onKey(int index, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey != LogicalKeyboardKey.backspace) {
      return KeyEventResult.ignored;
    }
    if (_controllers[index].text.isEmpty && index > 0) {
      _controllers[index - 1].clear();
      _focusNodes[index - 1].requestFocus();
      setState(() => _inlineError = null);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Future<void> _verify() async {
    if (_submitting) return;

    final state = ref.read(otpVerificationControllerProvider);
    if (state.isBusy) return;

    if (!_isComplete) {
      setState(() => _inlineError = 'otp.incomplete'.tr());
      _focusNodes.first.requestFocus();
      return;
    }

    setState(() {
      _submitting = true;
      _inlineError = null;
    });

    final controller = ref.read(otpVerificationControllerProvider.notifier);
    final verifyResult = await controller.verify(
      challengeId: _challengeId,
      code: _code,
    );

    if (!mounted) return;

    if (verifyResult == null) {
      final error = ref.read(otpVerificationControllerProvider).error;
      setState(() {
        _submitting = false;
        _inlineError = OtpVerificationController.localizedError(error);
      });
      if (isOfflineError(error)) {
        await openNoInternetPage(context);
      }
      // Keep entered OTP for retry; refocus first box.
      _focusNodes.first.requestFocus();
      return;
    }

    TextInput.finishAutofillContext(shouldSave: false);
    setState(() => _submitting = false);

    if (kDebugMode) {
      debugPrint(
        '[otp] verify next_step=${verifyResult.nextStep} '
        'hasVerificationToken=${verifyResult.verificationToken != null} '
        'hasAccessToken=${verifyResult.accessToken != null}',
      );
    }

    await showOtpSuccessDrawer(
      context,
      onContinue: () => _continueAfterOtpSuccess(verifyResult),
    );
  }

  Future<void> _continueAfterOtpSuccess(OtpVerifyResult result) async {
    if (!mounted) return;

    // Existing session shortcut (password step disabled on server).
    if (result.isAuthenticated) {
      final token = result.accessToken;
      if (token == null || token.isEmpty) {
        if (kDebugMode) {
          debugPrint('[otp] authenticated without token — abort');
        }
        return;
      }
      await ref.read(secureStorageProvider).writeToken(token);
      ref.read(pushNotificationServiceProvider).syncToken();
      if (!mounted) return;
      context.goNamed(RouteNames.home);
      return;
    }

    final verificationToken = result.verificationToken;
    if (verificationToken == null || verificationToken.isEmpty) {
      if (kDebugMode) {
        debugPrint(
          '[otp] next_step=${result.nextStep} missing verification_token',
        );
      }
      return;
    }

    // New account → create username/password, then home.
    if (result.isRegister) {
      context.goNamed(
        RouteNames.setUsernamePassword,
        queryParameters: {
          'phone': widget.phone,
          'verification_token': verificationToken,
        },
      );
      return;
    }

    // Existing account → enter password, then home.
    if (result.isPassword) {
      context.goNamed(
        RouteNames.passwordLogin,
        queryParameters: {
          'phone': widget.phone,
          'verification_token': verificationToken,
        },
      );
      return;
    }

    if (kDebugMode) {
      debugPrint('[otp] unhandled next_step=${result.nextStep}');
    }
  }

  Future<void> _resend() async {
    if (_secondsLeft > 0) return;

    final state = ref.read(otpVerificationControllerProvider);
    if (state.isBusy || _submitting) return;

    setState(() => _inlineError = null);

    final controller = ref.read(otpVerificationControllerProvider.notifier);
    final next = await controller.resend(widget.phone);
    if (!mounted) return;

    if (next != null) {
      _clearDigits();
      setState(() => _challengeId = next.challengeId);
      _startCountdown(next.resendAfter);
      if (kDebugMode && next.debugOtp != null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text('OTP ${next.debugOtp}')),
          );
      }
      return;
    }

    final error = ref.read(otpVerificationControllerProvider).error;
    final retryAfter = OtpVerificationController.retryAfterSeconds(error);
    if (retryAfter != null) {
      _startCountdown(retryAfter);
    }
    setState(() {
      _inlineError = OtpVerificationController.localizedError(error);
    });
    if (isOfflineError(error)) {
      await openNoInternetPage(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(otpVerificationControllerProvider);
    final verifying = state.isVerifying || _submitting;
    final canVerify = _isComplete && !verifying && !state.isBusy;
    final canResend = _secondsLeft <= 0 && !state.isBusy && !_submitting;
    final hasError = _inlineError != null;
    final _ = context.locale;
    final titleSize = authTitleFontSize(context);
    final subtitleSize = authSubtitleFontSize(context);

    return AuthBackgroundScaffold(
      showBack: true,
      compactTop: true,
      overlayKeyboard: true,
      card: CommonAuthCard(
        iconAsset: 'assets/images/auth/otp.png',
        title: 'otp.title'.tr(),
        titleColor: AppColors.primary,
        titleFontSize: titleSize,
        titleFontWeight: FontWeight.w700,
        titleLetterSpacing: 0.2,
        description: 'otp.subtitle'.tr(),
        descriptionWidget: _OtpSubtitle(
          phone: widget.phone,
          fontSize: subtitleSize,
        ),
        lockDescriptionHeight: false,
        titleBottomGap: 16,
        childTopGap: 20,
        actionTopGap: 24,
        primaryAction: AppButton(
          label: 'otp.verify'.tr(),
          height: 44,
          fontSize: 14,
          isLoading: verifying,
          onPressed: canVerify ? _verify : null,
        ),
        secondaryAction: _OtpResendRow(
          canResend: canResend,
          isResending: state.isResending,
          secondsLeft: _secondsLeft,
          onResend: _resend,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AutofillGroup(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final available =
                      constraints.maxWidth - (_gap * (_length - 1));
                  final size = (available / _length).clamp(40.0, 52.0);
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var index = 0; index < _length; index++) ...[
                        if (index > 0) const SizedBox(width: _gap),
                        _OtpSquare(
                          size: size,
                          controller: _controllers[index],
                          focusNode: _focusNodes[index],
                          enabled: !verifying,
                          autofill: index == 0,
                          hasError: hasError,
                          onKeyEvent: (event) => _onKey(index, event),
                          onChanged: (value) => _onDigitChanged(index, value),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
            SizedBox(
              height: _errorSlotHeight,
              width: double.infinity,
              child: hasError
                  ? Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _inlineError!,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.fieldError(),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _OtpSubtitle extends StatelessWidget {
  const _OtpSubtitle({
    required this.phone,
    required this.fontSize,
  });

  final String phone;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final lineStyle = AppTheme.english(
      fontSize: fontSize,
      fontWeight: FontWeight.w500,
      color: AppColors.textMuted,
      letterSpacing: 0.2,
      height: 1.4,
    );
    final phoneStyle = AppTheme.english(
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      color: AppColors.primary,
      letterSpacing: 0.2,
      height: 1.4,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'otp.subtitle'.tr(),
          textAlign: TextAlign.center,
          style: lineStyle,
        ),
        if (phone.trim().isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            phone,
            textAlign: TextAlign.center,
            style: phoneStyle,
          ),
        ],
      ],
    );
  }
}

class _OtpResendRow extends StatelessWidget {
  const _OtpResendRow({
    required this.canResend,
    required this.isResending,
    required this.secondsLeft,
    required this.onResend,
  });

  final bool canResend;
  final bool isResending;
  final int secondsLeft;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    final _ = context.locale;
    final actionLabel = secondsLeft > 0
        ? 'otp.resend_in'.tr(namedArgs: {'seconds': '$secondsLeft'})
        : 'otp.resend'.tr();
    final resendSize = otpResendFontSize(context);

    final promptStyle = AppTheme.english(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: AppColors.textMuted,
      letterSpacing: 0.2,
      height: 1.3,
    );

    final actionStyle = AppTheme.english(
      fontSize: resendSize,
      fontWeight: FontWeight.w500,
      color: canResend ? AppColors.primary : AppColors.textMuted,
      letterSpacing: 0.2,
      height: 1.3,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            'otp.dont_receive'.tr(),
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: promptStyle,
          ),
        ),
        const SizedBox(width: 6),
        if (isResending)
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary.withValues(alpha: 0.7),
            ),
          )
        else
          TextButton(
            onPressed: canResend ? onResend : null,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: AppColors.primary,
            ),
            child: Text(
              actionLabel,
              maxLines: 1,
              style: actionStyle,
            ),
          ),
      ],
    );
  }
}

class _OtpSquare extends StatefulWidget {
  const _OtpSquare({
    required this.size,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onKeyEvent,
    this.autofill = false,
    this.enabled = true,
    this.hasError = false,
  });

  final double size;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final KeyEventResult Function(KeyEvent event) onKeyEvent;
  final bool autofill;
  final bool enabled;
  final bool hasError;

  @override
  State<_OtpSquare> createState() => _OtpSquareState();
}

class _OtpSquareState extends State<_OtpSquare> {
  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
    widget.controller.addListener(_onTextChange);
  }

  @override
  void didUpdateWidget(covariant _OtpSquare oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_onFocusChange);
      widget.focusNode.addListener(_onFocusChange);
    }
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onTextChange);
      widget.controller.addListener(_onTextChange);
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    widget.controller.removeListener(_onTextChange);
    super.dispose();
  }

  void _onFocusChange() {
    if (mounted) setState(() {});
  }

  void _onTextChange() {
    if (mounted) setState(() {});
  }

  void _selectAll() {
    final text = widget.controller.text;
    widget.controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: text.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    final focused = widget.focusNode.hasFocus;
    final filled = widget.controller.text.isNotEmpty;
    final size = widget.size;
    final fontSize = size >= 48 ? 22.0 : 20.0;

    final borderColor = widget.hasError
        ? AppColors.error
        : focused
            ? AppColors.primary
            : filled
                ? AppColors.primary.withValues(alpha: 0.4)
                : AppColors.border;

    return SizedBox(
      width: size,
      height: size,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppStyle.borderRadiusInput,
          border: Border.all(
            color: borderColor,
            width: focused || widget.hasError ? 1.5 : 1.2,
          ),
        ),
        child: SizedBox(
          width: size,
          height: size,
          child: Center(
            child: Focus(
              canRequestFocus: false,
              skipTraversal: true,
              onKeyEvent: (node, event) => widget.onKeyEvent(event),
              child: TextField(
                controller: widget.controller,
                focusNode: widget.focusNode,
                enabled: widget.enabled,
                textAlign: TextAlign.center,
                textAlignVertical: TextAlignVertical.center,
                keyboardType: TextInputType.number,
                textInputAction: widget.autofill
                    ? TextInputAction.done
                    : TextInputAction.next,
                // Allow multi-digit paste / SMS autofill; parent distributes.
                maxLength: 6,
                showCursor: true,
                cursorColor: AppColors.primary,
                cursorWidth: 2,
                cursorHeight: fontSize,
                enableInteractiveSelection: true,
                autofillHints: widget.autofill
                    ? const [AutofillHints.oneTimeCode]
                    : null,
                style: AppTheme.english(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                  color: filled ? AppColors.textPrimary : AppColors.textMuted,
                  height: 1.2,
                ),
                strutStyle: StrutStyle(
                  fontSize: fontSize,
                  height: 1.2,
                  forceStrutHeight: true,
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  counterText: '',
                  contentPadding: EdgeInsets.zero,
                ),
                onTap: widget.enabled ? _selectAll : null,
                onChanged: (value) {
                  final digits = value.replaceAll(RegExp(r'\D'), '');
                  if (digits.length > 1) {
                    widget.onChanged(digits);
                    return;
                  }
                  final digit = digits.isEmpty ? '' : digits;
                  if (widget.controller.text != digit) {
                    widget.controller.value = TextEditingValue(
                      text: digit,
                      selection: TextSelection.collapsed(offset: digit.length),
                    );
                  }
                  widget.onChanged(digit);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
