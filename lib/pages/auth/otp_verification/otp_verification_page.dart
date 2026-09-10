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
import 'otp_verification_controller.dart';

class OtpVerificationPage extends ConsumerStatefulWidget {
  const OtpVerificationPage({super.key, required this.phone});

  final String phone;

  @override
  ConsumerState<OtpVerificationPage> createState() =>
      _OtpVerificationPageState();
}

class _OtpVerificationPageState extends ConsumerState<OtpVerificationPage> {
  static const _length = 4;
  static const _gap = 10.0;
  static const _squareSize = 58.0;

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
    // Support paste of full OTP into one box.
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
      card: CommonAuthCard(
        icon: LucideIcons.shield_check,
        title: 'otp.title'.tr(),
        description: 'otp.subtitle'.tr(namedArgs: {'phone': widget.phone}),
        primaryAction: AppButton(
          label: 'otp.verify'.tr(),
          isLoading: state.isLoading,
          onPressed: !_isComplete
              ? null
              : () async {
                  final ok = await controller.verify(_code);
                  if (ok && context.mounted) {
                    context.goNamed(
                      RouteNames.otpSuccess,
                      queryParameters: {'phone': widget.phone},
                    );
                  }
                },
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_length, (index) {
                return Padding(
                  padding: EdgeInsets.only(
                    left: index == 0 ? 0 : _gap / 2,
                    right: index == _length - 1 ? 0 : _gap / 2,
                  ),
                  child: _OtpSquare(
                    size: _squareSize,
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    onChanged: (value) => _onDigitChanged(index, value),
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: state.isLoading ? null : () => controller.resend(),
              child: Text(
                'otp.resend'.tr(),
                style: AppTheme.english(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
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
    widget.focusNode.addListener(_onFocus);
    widget.controller.addListener(_onFocus);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocus);
    widget.controller.removeListener(_onFocus);
    super.dispose();
  }

  void _onFocus() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final focused = widget.focusNode.hasFocus;
    // Soft lavender border like the reference squares.
    const idleBorder = Color(0xFFC5C8E8);
    const fill = Color(0xFFF8F8FC);
    const radius = BorderRadius.all(Radius.circular(12));

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        textAlign: TextAlign.center,
        textAlignVertical: TextAlignVertical.center,
        keyboardType: TextInputType.number,
        maxLength: 4,
        cursorColor: AppColors.primary,
        style: AppTheme.english(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          height: 1.1,
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: fill,
          contentPadding: EdgeInsets.zero,
          isDense: true,
          border: const OutlineInputBorder(
            borderRadius: radius,
            borderSide: BorderSide(color: idleBorder, width: 1),
          ),
          enabledBorder: const OutlineInputBorder(
            borderRadius: radius,
            borderSide: BorderSide(color: idleBorder, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: radius,
            borderSide: BorderSide(
              color: focused ? AppColors.primary : idleBorder,
              width: focused ? 1.5 : 1,
            ),
          ),
        ),
        onChanged: widget.onChanged,
      ),
    );
  }
}

