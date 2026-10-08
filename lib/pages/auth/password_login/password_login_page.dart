import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../components/app_button/app_button.dart';
import '../../../components/common_auth_card/common_auth_card.dart';
import '../../../core/locale/app_locale_provider.dart';
import '../../../core/network/offline_navigation.dart';
import '../../../core/router/route_names/route_names.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import '../../../core/theme/app_style/app_style.dart';
import '../../../core/theme/app_theme/app_theme.dart';
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

class _PasswordLoginPageState extends ConsumerState<PasswordLoginPage> {
  static const _length = 6;
  static const _gap = 12.0;
  static const _errorSlotHeight = AppStyle.errorSlotHeight;

  String? _inlineError;
  bool _submitting = false;

  final _controllers = List.generate(_length, (_) => TextEditingController());
  final _focusNodes = List.generate(_length, (_) => FocusNode());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNodes.first.requestFocus();
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _password => _controllers.map((c) => c.text).join();

  bool get _isComplete => _password.length == _length;

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

  Future<void> _signIn() async {
    if (_submitting) return;

    final state = ref.read(passwordLoginControllerProvider);
    if (state.isLoading) return;

    if (!_isComplete) {
      setState(() => _inlineError = 'password_login.incomplete'.tr());
      _focusNodes.first.requestFocus();
      return;
    }

    setState(() {
      _submitting = true;
      _inlineError = null;
    });

    final ok = await ref.read(passwordLoginControllerProvider.notifier).submit(
          verificationToken: widget.verificationToken,
          password: _password,
        );

    if (!mounted) return;

    if (ok) {
      setState(() => _submitting = false);
      context.goNamed(RouteNames.home);
      return;
    }

    final error = ref.read(passwordLoginControllerProvider).error;
    setState(() {
      _submitting = false;
      _inlineError = PasswordLoginController.localizedError(error);
    });
    if (isOfflineError(error)) {
      await openNoInternetPage(context);
    }
    _focusNodes.first.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(passwordLoginControllerProvider);
    final signingIn = state.isLoading || _submitting;
    final canSubmit = _isComplete && !signingIn;
    final hasError = _inlineError != null;
    final _ = context.locale;
    final titleSize = authTitleFontSize(context);
    final subtitleSize = authSubtitleFontSize(context);

    return AuthBackgroundScaffold(
      showBack: true,
      compactTop: true,
      overlayKeyboard: true,
      card: CommonAuthCard(
        iconAsset: 'assets/images/auth/password.png',
        title: 'password_login.title'.tr(),
        titleColor: AppColors.primary,
        titleFontSize: titleSize,
        titleFontWeight: FontWeight.w700,
        titleLetterSpacing: 0.2,
        description: 'password_login.subtitle'.tr(),
        descriptionFontSize: subtitleSize,
        descriptionFontWeight: FontWeight.w500,
        descriptionLetterSpacing: 0.2,
        descriptionHeight: 1.4,
        descriptionLineCount: 2,
        lockDescriptionHeight: false,
        titleBottomGap: 16,
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
            LayoutBuilder(
              builder: (context, constraints) {
                final available =
                    constraints.maxWidth - (_gap * (_length - 1));
                final size = (available / _length).clamp(40.0, 52.0);
                return Row(
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
                        isLast: index == _length - 1,
                        onKeyEvent: (event) => _onKey(index, event),
                        onChanged: (value) => _onDigitChanged(index, value),
                      ),
                    ],
                  ],
                );
              },
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
    this.isLast = false,
  });

  final double size;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final KeyEventResult Function(KeyEvent event) onKeyEvent;
  final bool enabled;
  final bool hasError;
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
                obscureText: true,
                obscuringCharacter: '•',
                textAlign: TextAlign.center,
                textAlignVertical: TextAlignVertical.center,
                keyboardType: TextInputType.number,
                textInputAction:
                    widget.isLast ? TextInputAction.done : TextInputAction.next,
                // Allow multi-digit paste; parent distributes across boxes.
                maxLength: 6,
                showCursor: false,
                enableInteractiveSelection: false,
                style: AppTheme.english(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                  color: filled ? AppColors.textPrimary : AppColors.textMuted,
                  height: 1,
                ),
                strutStyle: StrutStyle(
                  fontSize: fontSize,
                  height: 1,
                  forceStrutHeight: true,
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  isCollapsed: true,
                  isDense: true,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
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
        ),
      ),
    );
  }
}
