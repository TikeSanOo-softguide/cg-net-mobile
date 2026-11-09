import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../components/app_button/app_button.dart';
import '../../../components/common_auth_card/common_auth_card.dart';
import '../../../core/locale/app_locale_provider.dart';
import '../../../core/network/api_error_text.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/auth_api/auth_api.dart';
import '../../../core/router/route_names/route_names.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import '../../../core/theme/app_style/app_style.dart';
import '../../../core/theme/app_theme/app_theme.dart';
import '../../../core/utils/api_field_error.dart';
import '../../../core/utils/loading_helper.dart';
import 'password_login_controller.dart';

class PasswordLoginPage extends ConsumerStatefulWidget {
  const PasswordLoginPage({
    super.key,
    required this.phone,
    required this.verificationToken,
  });

  final String phone;
  final String verificationToken;

  @override
  ConsumerState<PasswordLoginPage> createState() => _PasswordLoginPageState();
}

class _PasswordLoginPageState extends ConsumerState<PasswordLoginPage>
    with SingleTickerProviderStateMixin {
  static const _length = 6;
  static const _gap = 12.0;
  static const _errorSlotHeight = AppStyle.errorSlotHeight;

  String? _inlineError;
  bool _submitting = false;
  bool _handlingPasswordInput = false;
  bool _wasComplete = false;

  final _controllers = List.generate(_length, (_) => TextEditingController());
  final _focusNodes = List.generate(_length, (_) => FocusNode());
  late final AnimationController _shake;
  late final Animation<double> _shakeX;

  @override
  void initState() {
    super.initState();
    _shake = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _shakeX = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -7), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -7, end: 7), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 7, end: -5), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -5, end: 5), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 5, end: -3), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -3, end: 0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shake, curve: Curves.easeOut));
    for (final controller in _controllers) {
      controller.addListener(_syncSubmitEnabled);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNodes.first.requestFocus();
    });
  }

  void _syncSubmitEnabled() {
    final complete = _isComplete;
    if (complete == _wasComplete) return;
    _wasComplete = complete;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _shake.dispose();
    for (final c in _controllers) {
      c.removeListener(_syncSubmitEnabled);
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _playErrorFeedback() {
    HapticFeedback.mediumImpact();
    HapticFeedback.vibrate();
    _shake.forward(from: 0);
  }

  void _clearInlineError() {
    if (_inlineError == null) return;
    setState(() => _inlineError = null);
  }

  String get _password => _controllers.map((c) => c.text).join();

  bool get _isComplete => _password.length == _length;

  void _writeBox(int index, String digit) {
    final value = TextEditingValue(
      text: digit,
      selection: TextSelection.collapsed(offset: digit.length),
    );
    if (_controllers[index].value != value) {
      _controllers[index].value = value;
    }
  }

  void _focusBox(int index) {
    final node = _focusNodes[index];
    if (!node.hasFocus) node.requestFocus();
    final text = _controllers[index].text;
    _controllers[index].selection =
        TextSelection.collapsed(offset: text.length);
  }

  /// iOS keychain / paste — fill boxes the same way as OTP.
  void _applyDigits(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return;

    for (var i = 0; i < _length; i++) {
      _writeBox(i, i < digits.length ? digits[i] : '');
    }

    final focusIndex = (digits.length.clamp(1, _length) - 1);
    _focusBox(focusIndex);
    setState(() => _inlineError = null);
  }

  void _onDigitChanged(int index, String value) {
    if (_handlingPasswordInput) return;
    final digits = value.replaceAll(RegExp(r'\D'), '');

    _handlingPasswordInput = true;
    try {
      if (digits.isEmpty) {
        final hadText = _controllers[index].text.isNotEmpty;
        if (hadText) {
          _writeBox(index, '');
        }
        if (index > 0) _focusBox(index - 1);
        if (hadText) _clearInlineError();
        return;
      }

      if (digits.length == 1) {
        final unchanged = _controllers[index].text == digits;
        _writeBox(index, digits);
        if (unchanged) return;
        if (index < _length - 1) _focusBox(index + 1);
        _clearInlineError();
        return;
      }

      if (digits.length < _length) {
        var last = index;
        for (var i = 0; i < digits.length && index + i < _length; i++) {
          last = index + i;
          _writeBox(last, digits[i]);
        }
        _focusBox(last);
        _clearInlineError();
        return;
      }

      _applyDigits(digits);
    } finally {
      _handlingPasswordInput = false;
    }
  }

  KeyEventResult _onKey(int index, KeyEvent event) {
    if (_handlingPasswordInput) return KeyEventResult.ignored;
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey != LogicalKeyboardKey.backspace) {
      return KeyEventResult.ignored;
    }
    if (_controllers[index].text.isEmpty && index > 0) {
      _handlingPasswordInput = true;
      _writeBox(index - 1, '');
      _focusBox(index - 1);
      _handlingPasswordInput = false;
      setState(() => _inlineError = null);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Future<void> _signIn() async {
    if (_submitting) return;

    final state = ref.read(passwordLoginControllerProvider);
    if (state.isLoading) return;

    if (!_isComplete) {
      setState(() => _inlineError = 'password_login.incomplete'.tr());
      _playErrorFeedback();
      return;
    }

    setState(() {
      _submitting = true;
      _inlineError = null;
    });

    var navigated = false;
    ApiException? submitError;
    try {
      await LoadingHelper.runWithLoading<void>(
        () async {
          final success = await ref
              .read(passwordLoginControllerProvider.notifier)
              .submit(
                verificationToken: widget.verificationToken,
                password: _password,
              );
          if (!success) return;

          await ref.read(authApiProvider).syncCurrentLanguage();
          if (!mounted) return;
          TextInput.finishAutofillContext();
          context.goNamed(RouteNames.home);
          navigated = true;
          await Future.delayed(const Duration(milliseconds: 350));
        },
        dismissAnimation: false,
        onBeforeDismiss: () async {
          if (!navigated && mounted && _submitting) {
            setState(() => _submitting = false);
            await WidgetsBinding.instance.endOfFrame;
          }
        },
      );
    } on ApiException catch (error) {
      submitError = error;
    }
    if (navigated) return;

    if (mounted && _submitting) {
      setState(() => _submitting = false);
    }
    if (!mounted) return;

    if (submitError != null) {
      await _showSignInError(submitError);
      return;
    }

    final error = ref.read(passwordLoginControllerProvider).error;
    if (error != null) {
      await _showSignInError(error);
    }
  }

  Future<void> _showSignInError(Object error) async {
    if (isAuthInputError(error)) {
      setState(() {
        _submitting = false;
        _inlineError = apiErrorText(error);
      });
      _playErrorFeedback();
      return;
    }
    await showApiErrorModal(context, error);
  }

  @override
  Widget build(BuildContext context) {
    final signingIn = _submitting;
    final canSubmit = _isComplete && !signingIn;
    final hasError = _inlineError != null;
    final _ = context.locale;
    final titleSize = authTitleFontSize(context);
    final subtitleSize = authSubtitleFontSize(context);

    return AuthBackgroundScaffold(
      // showBack: true,
      compactTop: true,
      overlayKeyboard: true,
      card: CommonAuthCard(
        iconAsset: 'assets/images/auth/password.png',
        title: 'password_login.title'.tr(),
        titleColor: AppColors.primary,
        titleFontSize: titleSize,
        titleFontWeight: FontWeight.w600,
        titleLetterSpacing: 0.2,
        description: 'password_login.subtitle'.tr(),
        descriptionFontSize: subtitleSize,
        descriptionFontWeight: FontWeight.w500,
        descriptionLetterSpacing: 0.2,
        descriptionHeight: 1.4,
        descriptionLineCount: 2,
        lockDescriptionHeight: false,
        titleBottomGap: 10,
        childTopGap: 20,
        actionTopGap: 24,
        primaryAction: AppButton(
          label: 'password_login.sign_in'.tr(),
          height: 44,
          fontSize: 14,
          isLoading: signingIn,
          onPressed: canSubmit ? _signIn : null,
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
                  return AnimatedBuilder(
                    animation: _shakeX,
                    builder: (context, child) => Transform.translate(
                      offset: Offset(_shakeX.value, 0),
                      child: child,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var index = 0; index < _length; index++) ...[
                          if (index > 0) const SizedBox(width: _gap),
                          _PasswordDigit(
                            size: size,
                            controller: _controllers[index],
                            focusNode: _focusNodes[index],
                            enabled: !signingIn,
                            hasError: hasError,
                            autofill: index == 0,
                            isLast: index == _length - 1,
                            onKeyEvent: (event) => _onKey(index, event),
                            onChanged: (value) => _onDigitChanged(index, value),
                          ),
                        ],
                      ],
                    ),
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

class _PasswordDigit extends StatefulWidget {
  const _PasswordDigit({
    required this.size,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onKeyEvent,
    this.enabled = true,
    this.hasError = false,
    this.autofill = false,
    this.isLast = false,
  });

  final double size;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final KeyEventResult Function(KeyEvent event) onKeyEvent;
  final bool enabled;
  final bool hasError;
  final bool autofill;
  final bool isLast;

  @override
  State<_PasswordDigit> createState() => _PasswordDigitState();
}

class _PasswordDigitState extends State<_PasswordDigit> {
  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
    widget.controller.addListener(_onTextChange);
  }

  @override
  void didUpdateWidget(covariant _PasswordDigit oldWidget) {
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
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppStyle.borderRadiusInput,
          border: Border.all(
            color: borderColor,
            width: focused || widget.hasError ? 1.5 : 1.2,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Opacity(
              opacity: 0,
              child: Focus(
                canRequestFocus: false,
                skipTraversal: true,
                onKeyEvent: (node, event) => widget.onKeyEvent(event),
                child: TextField(
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                  enabled: widget.enabled,
                  obscureText: true,
                  obscuringCharacter: '•',
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  textInputAction: widget.autofill
                      ? TextInputAction.done
                      : TextInputAction.next,
                  maxLength: 6,
                  showCursor: false,
                  enableInteractiveSelection: false,
                  autofillHints: widget.autofill
                      ? const [AutofillHints.password]
                      : null,
                  style: AppTheme.english(
                    fontSize: 1,
                    height: 1,
                    color: Colors.transparent,
                  ),
                  onTapOutside: (_) {
                    if (widget.focusNode.hasFocus) {
                      widget.focusNode.unfocus();
                    }
                  },
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    isCollapsed: true,
                    isDense: true,
                    border: InputBorder.none,
                    counterText: '',
                    contentPadding: EdgeInsets.zero,
                  ),
                  onSubmitted: widget.isLast ? (_) {} : null,
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
            if (filled)
              IgnorePointer(
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: AppColors.textPrimary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
