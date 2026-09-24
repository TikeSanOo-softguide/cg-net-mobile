import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../components/app_button/app_button.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import '../../../core/theme/app_style/app_style.dart';
import '../../../core/theme/app_theme/app_theme.dart';

const _dialogRadius = 16.0;
const _pinLength = 6;

/// Modern 6-digit transfer password modal. Returns the PIN or null if cancelled.
Future<String?> showTransferPasswordModal(BuildContext context) {
  return showGeneralDialog<String>(
    context: context,
    barrierDismissible: false,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: const Color(0x6B000000),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (ctx, animation, secondaryAnimation) =>
        const _TransferPasswordDialog(),
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

class _TransferPasswordDialog extends StatefulWidget {
  const _TransferPasswordDialog();

  @override
  State<_TransferPasswordDialog> createState() =>
      _TransferPasswordDialogState();
}

class _TransferPasswordDialogState extends State<_TransferPasswordDialog> {
  final _controllers =
      List.generate(_pinLength, (_) => TextEditingController());
  final _focusNodes = List.generate(_pinLength, (_) => FocusNode());
  String? _error;

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

  String get _pin => _controllers.map((c) => c.text).join();

  void _onDigitChanged(int index, String value) {
    setState(() => _error = null);
    final digits = value.replaceAll(RegExp(r'\D'), '');

    if (digits.length > 1) {
      for (var i = 0; i < _pinLength; i++) {
        _controllers[i].text = i < digits.length ? digits[i] : '';
      }
      final focusIndex = digits.length.clamp(0, _pinLength) - 1;
      if (focusIndex >= 0) {
        _focusNodes[focusIndex.clamp(0, _pinLength - 1)].requestFocus();
      }
      return;
    }

    if (digits.isNotEmpty && index < _pinLength - 1) {
      _focusNodes[index + 1].requestFocus();
    }
    if (digits.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  void _submit() {
    final pin = _pin;
    if (pin.length != _pinLength) {
      setState(() => _error = 'transfer.password_invalid'.tr());
      return;
    }
    Navigator.of(context).pop(pin);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_dialogRadius),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(6),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.38),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.glassBorder,
                            width: 0.6,
                          ),
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: AppColors.textMuted.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Text(
              'transfer.password_title'.tr(),
              textAlign: TextAlign.center,
              style: AppTheme.english(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'transfer.password_body'.tr(),
              textAlign: TextAlign.center,
              style: AppTheme.english(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textMuted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _pinLength; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  _PinBox(
                    controller: _controllers[i],
                    focusNode: _focusNodes[i],
                    hasError: _error != null,
                    onChanged: (v) => _onDigitChanged(i, v),
                    onSubmitted: i == _pinLength - 1 ? _submit : null,
                  ),
                ],
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: AppTheme.english(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFD90000),
                ),
              ),
            ],
            const SizedBox(height: 18),
            AppButton(
              label: 'transfer.password_submit'.tr(),
              height: 40,
              fontSize: 13,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _PinBox extends StatelessWidget {
  const _PinBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.hasError,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final bool hasError;
  final VoidCallback? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: focusNode,
      builder: (context, _) {
        final focused = focusNode.hasFocus;
        final borderColor = hasError
            ? const Color(0xFFD90000)
            : focused
                ? AppColors.primary
                : AppColors.paperBorder;

        // Outer box owns the square size. Theme InputDecoration min-height
        // would otherwise stretch OutlineInputBorder into a rectangle.
        return SizedBox(
          width: 32,
          height: 32,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppStyle.radiusInput),
              border: Border.all(
                color: borderColor,
                width: focused || hasError ? 1.5 : 1,
              ),
            ),
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              textAlign: TextAlign.center,
              textAlignVertical: TextAlignVertical.center,
              keyboardType: TextInputType.number,
              obscureText: true,
              obscuringCharacter: '•',
              maxLength: 1,
              style: AppTheme.english(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                height: 1,
              ),
              strutStyle: const StrutStyle(
                fontSize: 15,
                height: 1,
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
                filled: false,
              ),
              onChanged: onChanged,
              onSubmitted: (_) => onSubmitted?.call(),
            ),
          ),
        );
      },
    );
  }
}
