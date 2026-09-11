import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../components/app_button/app_button.dart';
import '../../../components/common_auth_card/common_auth_card.dart';
import '../../../core/router/route_names/route_names.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import '../../../core/theme/app_theme/app_theme.dart';
import 'otp_success_drawer.dart';
import 'otp_verification_controller.dart';

class OtpVerificationPage extends ConsumerStatefulWidget {
  const OtpVerificationPage({super.key, required this.phone});

  final String phone;

  @override
  ConsumerState<OtpVerificationPage> createState() =>
      _OtpVerificationPageState();
}

class _OtpVerificationPageState extends ConsumerState<OtpVerificationPage> {
  static const _length = 6;
  static const _gap = 12.0;

  final _controllers = List.generate(_length, (_) => TextEditingController());
  final _focusNodes = List.generate(_length, (_) => FocusNode());

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

  String get _code => _controllers.map((c) => c.text).join();

  bool get _isComplete => _code.length == _length;

  void _onDigitChanged(int index, String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 1) {
      for (var i = 0; i < _length; i++) {
        _controllers[i].text = i < digits.length ? digits[i] : '';
      }
      final focusIndex = digits.length.clamp(0, _length) - 1;
      if (focusIndex >= 0) {
        _focusNodes[focusIndex.clamp(0, _length - 1)].requestFocus();
      }
      setState(() {});
      return;
    }

    if (digits.isNotEmpty && index < _length - 1) {
      _focusNodes[index + 1].requestFocus();
    }
    if (digits.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(otpVerificationControllerProvider);
    final controller = ref.read(otpVerificationControllerProvider.notifier);

    return AuthBackgroundScaffold(
      showBack: true,
      compactTop: true,
      topBarTitle: 'otp.title'.tr(),
      card: CommonAuthCard(
        icon: LucideIcons.shield_check,
        title: 'otp.title'.tr(),
        description: 'otp.subtitle'.tr(namedArgs: {'phone': widget.phone}),
        primaryAction: AppButton(
          label: 'otp.verify'.tr(),
          height: 42,
          fontSize: 13,
          isLoading: state.isLoading,
          onPressed: !_isComplete
              ? null
              : () async {
                  final ok = await controller.verify(_code);
                  if (!ok || !context.mounted) return;
                  await showOtpSuccessDrawer(
                    context,
                    onContinue: () {
                      if (!context.mounted) return;
                      context.pushNamed(
                        RouteNames.setUsernamePassword,
                        queryParameters: {'phone': widget.phone},
                      );
                    },
                  );
                },
        ),
        secondaryAction: TextButton(
          onPressed: state.isLoading ? null : () => controller.resend(),
          child: Text(
            'otp.resend'.tr(),
            style: AppTheme.english(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final available =
                constraints.maxWidth - (_gap * (_length - 1));
            // Keep true squares that fit the row (no overflow from min clamp).
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
                    onChanged: (value) => _onDigitChanged(index, value),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _OtpSquare extends StatefulWidget {
  const _OtpSquare({
    required this.size,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  final double size;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  @override
  State<_OtpSquare> createState() => _OtpSquareState();
}

class _OtpSquareState extends State<_OtpSquare> {
  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant _OtpSquare oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_onFocusChange);
      widget.focusNode.addListener(_onFocusChange);
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onFocusChange() {
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
    final size = widget.size;
    final fontSize = size >= 48 ? 22.0 : 20.0;

    return SizedBox(
      width: size,
      height: size,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: focused ? AppColors.primary : AppColors.border,
            width: focused ? 1.6 : 1.2,
          ),
        ),
        child: SizedBox(
          width: size,
          height: size,
          child: Center(
            child: TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              textAlign: TextAlign.center,
              textAlignVertical: TextAlignVertical.center,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              maxLength: 1,
              showCursor: true,
              cursorColor: AppColors.primary,
              cursorWidth: 2,
              cursorHeight: fontSize,
              enableInteractiveSelection: true,
              style: AppTheme.english(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
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
                counterText: '',
                contentPadding: EdgeInsets.zero,
              ),
              onTap: _selectAll,
              onChanged: (value) {
                // Keep a single digit and allow replace-on-edit.
                final digits = value.replaceAll(RegExp(r'\D'), '');
                final digit = digits.isEmpty ? '' : digits[digits.length - 1];
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
    );
  }
}
