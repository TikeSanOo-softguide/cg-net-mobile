import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../components/app_button/app_button.dart';
import '../../../components/common_auth_card/common_auth_card.dart';
import '../../../core/locale/app_locale_provider.dart';
import '../../../core/network/api_error_text.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import '../../../core/theme/app_style/app_style.dart';
import '../../../core/theme/app_theme/app_theme.dart';
import '../../../models/change_password_model/change_password_otp_session.dart';
import 'change_password_controller.dart';

class VerifyChangePasswordOtpPage extends ConsumerStatefulWidget {
  const VerifyChangePasswordOtpPage({
    required this.session,
    super.key,
  });

  final ChangePasswordOtpSession session;

  @override
  ConsumerState<VerifyChangePasswordOtpPage> createState() =>
      _VerifyChangePasswordOtpPageState();
}

class _VerifyChangePasswordOtpPageState
    extends ConsumerState<VerifyChangePasswordOtpPage> {
  static const _length = 6;
  static const _gap = 12.0;

  late ChangePasswordChallenge _challenge;
  late int _secondsLeft;
  Timer? _countdown;
  final _controllers = List.generate(_length, (_) => TextEditingController());
  final _focusNodes = List.generate(_length, (_) => FocusNode());
  String? _inlineError;
  bool _submitting = false;
  bool _resending = false;

  String get _code => _controllers.map((controller) => controller.text).join();
  bool get _isComplete => _code.length == _length;
  bool get _isBusy => _submitting || _resending;

  @override
  void initState() {
    super.initState();
    _challenge = widget.session.challenge;
    _secondsLeft = _positiveSeconds(_challenge.resendAfter);
    _startCountdownTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focusNodes.first.requestFocus();
      _showDebugOtp(_challenge.debugOtp);
    });
  }

  @override
  void dispose() {
    _countdown?.cancel();
    widget.session.clearPassword();
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _applyDigits(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return;

    for (var index = 0; index < _length; index++) {
      _controllers[index].text = index < digits.length ? digits[index] : '';
    }

    final focusIndex = digits.length.clamp(1, _length) - 1;
    _focusNodes[focusIndex].requestFocus();
    setState(() => _inlineError = null);
  }

  void _onDigitChanged(int index, String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 1) {
      _applyDigits(digits);
      return;
    }

    final digit = digits.isEmpty ? '' : digits;
    if (_controllers[index].text != digit) {
      _controllers[index].value = TextEditingValue(
        text: digit,
        selection: TextSelection.collapsed(offset: digit.length),
      );
    }

    if (digit.isNotEmpty && index < _length - 1) {
      _focusNodes[index + 1].requestFocus();
    } else if (digit.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    setState(() => _inlineError = null);
  }

  KeyEventResult _onKey(int index, KeyEvent event) {
    if (event is! KeyDownEvent ||
        event.logicalKey != LogicalKeyboardKey.backspace) {
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

  static int _positiveSeconds(int seconds) => seconds > 0 ? seconds : 60;

  void _startCountdown(int seconds) {
    _countdown?.cancel();
    setState(() => _secondsLeft = _positiveSeconds(seconds));
    _startCountdownTimer();
  }

  void _startCountdownTimer() {
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
    for (final controller in _controllers) {
      controller.clear();
    }
    _focusNodes.first.requestFocus();
  }

  void _showDebugOtp(String? otp) {
    if (!kDebugMode || otp == null || otp.isEmpty || !mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('OTP $otp')));
  }

  int? _retryAfterSeconds(Object error) {
    if (error is! ApiException) return null;
    final seconds = int.tryParse(error.detail ?? '');
    return seconds != null && seconds > 0 ? seconds : null;
  }

  Future<void> _resend() async {
    final password = widget.session.password;
    if (_secondsLeft > 0 || _isBusy || password == null) return;

    setState(() {
      _inlineError = null;
      _resending = true;
    });

    try {
      final nextChallenge = await ref
          .read(changePasswordControllerProvider.notifier)
          .changePassword(password: password);
      if (!mounted) return;

      _clearDigits();
      setState(() {
        _challenge = nextChallenge;
        _resending = false;
      });
      _startCountdown(nextChallenge.resendAfter);
      _showDebugOtp(nextChallenge.debugOtp);
    } catch (error) {
      if (!mounted) return;

      final retryAfter = _retryAfterSeconds(error);
      if (retryAfter != null) _startCountdown(retryAfter);
      setState(() {
        _resending = false;
        _inlineError = apiErrorText(error);
      });
    }
  }

  Future<void> _verifyOtp() async {
    if (_isBusy) return;
    if (!_isComplete) {
      setState(() => _inlineError = 'otp.incomplete'.tr());
      _focusNodes.first.requestFocus();
      return;
    }

    setState(() {
      _submitting = true;
      _inlineError = null;
    });

    try {
      await ref.read(changePasswordControllerProvider.notifier).verifyOtp(
            challengeId: _challenge.challengeId,
            otp: _code,
          );
      if (!mounted) return;

      setState(() => _submitting = false);
      widget.session.clearPassword();
      TextInput.finishAutofillContext(shouldSave: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('profile.password_changed'.tr())),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _submitting = false;
        _inlineError = apiErrorText(error);
      });
      _focusNodes.first.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(changePasswordControllerProvider);
    final verifying = loading || _isBusy;
    final hasError = _inlineError != null;
    final _ = context.locale;

    return AuthBackgroundScaffold(
      showBack: true,
      compactTop: true,
      overlayKeyboard: true,
      card: CommonAuthCard(
        iconAsset: 'assets/images/auth/otp.png',
        title: 'profile.password_otp_title'.tr(),
        titleColor: AppColors.primary,
        titleFontSize: authTitleFontSize(context),
        titleFontWeight: FontWeight.w600,
        titleLetterSpacing: 0.2,
        description: 'profile.password_otp_subtitle'.tr(),
        descriptionFontSize: authSubtitleFontSize(context),
        lockDescriptionHeight: false,
        titleBottomGap: 10,
        childTopGap: 20,
        actionTopGap: 20,
        primaryAction: AppButton(
          label: 'otp.verify'.tr(),
          height: 44,
          fontSize: 14,
          isLoading: verifying,
          onPressed: _isComplete && !verifying ? _verifyOtp : null,
        ),
        secondaryAction: _ChangePasswordOtpResendRow(
          canResend: _secondsLeft <= 0 &&
              !verifying &&
              widget.session.password != null,
          isResending: _resending,
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
                        _PasswordOtpSquare(
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
              height: AppStyle.errorSlotHeight,
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

class _ChangePasswordOtpResendRow extends StatelessWidget {
  const _ChangePasswordOtpResendRow({
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
    final promptSize = usesCompactAuthType(context) ? 13.0 : 14.0;
    final promptStyle = AppTheme.english(
      fontSize: promptSize,
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

class _PasswordOtpSquare extends StatefulWidget {
  const _PasswordOtpSquare({
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
  State<_PasswordOtpSquare> createState() => _PasswordOtpSquareState();
}

class _PasswordOtpSquareState extends State<_PasswordOtpSquare> {
  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_refresh);
    widget.controller.addListener(_refresh);
  }

  @override
  void didUpdateWidget(covariant _PasswordOtpSquare oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_refresh);
      widget.focusNode.addListener(_refresh);
    }
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_refresh);
      widget.controller.addListener(_refresh);
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_refresh);
    widget.controller.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _selectAll() {
    widget.controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: widget.controller.text.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    final focused = widget.focusNode.hasFocus;
    final filled = widget.controller.text.isNotEmpty;
    final fontSize = widget.size >= 48 ? 22.0 : 20.0;
    final borderColor = widget.hasError
        ? AppColors.error
        : focused
            ? AppColors.primary
            : filled
                ? AppColors.primary.withValues(alpha: 0.4)
                : AppColors.border;

    return SizedBox(
      width: widget.size,
      height: widget.size,
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
            textInputAction:
                widget.autofill ? TextInputAction.done : TextInputAction.next,
            maxLength: 6,
            showCursor: true,
            cursorColor: AppColors.primary,
            cursorWidth: 2,
            cursorHeight: fontSize,
            enableInteractiveSelection: true,
            autofillHints:
                widget.autofill ? const [AutofillHints.oneTimeCode] : null,
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
            onChanged: widget.onChanged,
          ),
        ),
      ),
    );
  }
}
