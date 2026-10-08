import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors/app_colors.dart';
import '../../core/theme/app_style/app_style.dart';
import '../../core/theme/app_theme/app_theme.dart';

const _cancelRed = Color(0xFFFF0000);
const _alert = Color(0xFFF97A00);
const _successSoft = Color(0xFFE8F5DC); // light of #3D7A12
const _alertSoft = Color(0xFFFFF0E5); // light of #F97A00
const double _dialogRadius = 16;
const double _modalBtnHeight = 32;
const double _modalBtnFontSize = 11;
const String _successIconAsset = 'assets/images/dialogs/success.png';
const String _confirmIconAsset = 'assets/images/dialogs/confirm.png';
const String _alertIconAsset = 'assets/images/dialogs/alert.png';
const String _failureIconAsset = 'assets/images/dialogs/failure.png';
const String _passwordIconAsset = 'assets/images/dialogs/password.png';
const Color _failure = Color(0xFFD90000);
const Color _failureSoft = Color(0xFFFCE6E6); // light of #D90000
const double _dialogIconChip = 36;
const double _dialogIconSize = 23;
const double _dialogIconRadius = 8;
const EdgeInsets _dialogPadding = EdgeInsets.fromLTRB(18, 16, 18, 16);
const double _gapIconTitle = 8;
const double _gapTitleBody = 6;
const double _gapBodyButton = 14;
const EdgeInsets _dialogInset = EdgeInsets.symmetric(horizontal: 44);
const Duration _dialogDuration = Duration(milliseconds: 220);
const Color _barrier = Color(0x6B000000); // ~42% black

Widget _dialogPngIcon({
  required String asset,
  required Color background,
}) {
  return Container(
    width: _dialogIconChip,
    height: _dialogIconChip,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(_dialogIconRadius),
    ),
    child: Image.asset(
      asset,
      width: _dialogIconSize,
      height: _dialogIconSize,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    ),
  );
}

ButtonStyle _primaryModalBtnStyle() => FilledButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.onPrimary,
      elevation: 0,
      minimumSize: const Size(0, _modalBtnHeight),
      maximumSize: const Size(double.infinity, _modalBtnHeight),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppStyle.radiusInput),
      ),
    );

ButtonStyle _cancelOutlineModalBtnStyle() => OutlinedButton.styleFrom(
      foregroundColor: _cancelRed,
      backgroundColor: Colors.white,
      elevation: 0,
      minimumSize: const Size(0, _modalBtnHeight),
      maximumSize: const Size(double.infinity, _modalBtnHeight),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      side: const BorderSide(color: _cancelRed, width: 1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppStyle.radiusInput),
      ),
    );

TextStyle _modalBtnText({
  required Color color,
  FontWeight weight = FontWeight.w600,
}) =>
    AppTheme.english(
      fontSize: _modalBtnFontSize,
      fontWeight: weight,
      color: color,
    );

TextStyle _dialogTitleStyle(Color color) => AppTheme.english(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: color,
      height: 1.3,
      letterSpacing: -0.2,
    );

TextStyle _dialogMessageStyle() => AppTheme.english(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: AppColors.textMuted,
      height: 1.45,
      letterSpacing: 0,
    );

/// Soft fade + scale — same on iOS and Android.
Future<T?> _showAppDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: _barrier,
    transitionDuration: _dialogDuration,
    pageBuilder: (ctx, animation, secondaryAnimation) => builder(ctx),
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

Widget _appDialogShell({required Widget child}) {
  return Dialog(
    backgroundColor: AppColors.surface,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(_dialogRadius),
    ),
    insetPadding: _dialogInset,
    child: Padding(
      padding: _dialogPadding,
      child: child,
    ),
  );
}

/// Shared success dialog — Flaticon success badge + success title.
Future<void> showAppSuccessModal(
  BuildContext context, {
  required String title,
  required String body,
  String? buttonLabel,
}) {
  return _showAppDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return _appDialogShell(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dialogPngIcon(
              asset: _successIconAsset,
              background: _successSoft,
            ),
            const SizedBox(height: _gapIconTitle),
            Text(
              title,
              textAlign: TextAlign.center,
              style: _dialogTitleStyle(AppColors.success),
            ),
            const SizedBox(height: _gapTitleBody),
            Text(
              body,
              textAlign: TextAlign.center,
              style: _dialogMessageStyle(),
            ),
            const SizedBox(height: _gapBodyButton),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 120),
              child: SizedBox(
                height: _modalBtnHeight,
                child: FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  style: _primaryModalBtnStyle(),
                  child: Text(
                    buttonLabel ?? 'common.done'.tr(),
                    style: _modalBtnText(color: AppColors.onPrimary),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// Shared failure dialog — Flaticon error badge + error title.
Future<void> showAppFailureModal(
  BuildContext context, {
  required String title,
  required String body,
  String? buttonLabel,
}) {
  return _showAppDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return _appDialogShell(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dialogPngIcon(
              asset: _failureIconAsset,
              background: _failureSoft,
            ),
            const SizedBox(height: _gapIconTitle),
            Text(
              title,
              textAlign: TextAlign.center,
              style: _dialogTitleStyle(_failure),
            ),
            const SizedBox(height: _gapTitleBody),
            Text(
              body,
              textAlign: TextAlign.center,
              style: _dialogMessageStyle(),
            ),
            const SizedBox(height: _gapBodyButton),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 120),
              child: SizedBox(
                height: _modalBtnHeight,
                child: FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  style: _primaryModalBtnStyle(),
                  child: Text(
                    buttonLabel ?? 'common.ok'.tr(),
                    style: _modalBtnText(color: AppColors.onPrimary),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// Simple alert — Flaticon warning badge + alert title.
Future<void> showAppAlertModal(
  BuildContext context, {
  required String message,
  String? buttonLabel,
  String? title,
}) {
  return _showAppDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      return _appDialogShell(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dialogPngIcon(
              asset: _alertIconAsset,
              background: _alertSoft,
            ),
            if (title != null) ...[
              const SizedBox(height: _gapIconTitle),
              Text(
                title,
                textAlign: TextAlign.center,
                style: _dialogTitleStyle(_alert),
              ),
              const SizedBox(height: _gapTitleBody),
            ] else
              const SizedBox(height: _gapIconTitle),
            Text(
              message,
              textAlign: TextAlign.center,
              style: _dialogMessageStyle(),
            ),
            const SizedBox(height: _gapBodyButton),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 120),
              child: SizedBox(
                height: _modalBtnHeight,
                child: FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  style: _primaryModalBtnStyle(),
                  child: Text(
                    buttonLabel ?? 'common.ok'.tr(),
                    style: _modalBtnText(color: AppColors.onPrimary),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// Shared confirm dialog — primary title + Flaticon info badge.
Future<bool> showAppConfirmModal(
  BuildContext context, {
  required String title,
  required String body,
  String? confirmLabel,
  String? cancelLabel,
}) async {
  final result = await _showAppDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      return _appDialogShell(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dialogPngIcon(
              asset: _confirmIconAsset,
              background: AppColors.primaryLight,
            ),
            const SizedBox(height: _gapIconTitle),
            Text(
              title,
              textAlign: TextAlign.center,
              style: _dialogTitleStyle(AppColors.primary),
            ),
            const SizedBox(height: _gapTitleBody),
            Text(
              body,
              textAlign: TextAlign.center,
              style: _dialogMessageStyle(),
            ),
            const SizedBox(height: _gapBodyButton),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: _modalBtnHeight,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      style: _cancelOutlineModalBtnStyle(),
                      child: Text(
                        cancelLabel ?? 'common.cancel'.tr(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _modalBtnText(
                          color: _cancelRed,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: _modalBtnHeight,
                    child: FilledButton(
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      style: _primaryModalBtnStyle(),
                      child: Text(
                        confirmLabel ?? 'common.confirm'.tr(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _modalBtnText(
                          color: AppColors.onPrimary,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
  return result == true;
}

/// Shared password dialog — icon + amount + close + 6-digit boxes.
Future<String?> showAppPasswordModal(
  BuildContext context, {
  required String title,
  required String body,
  int? amountPoints,
}) {
  return _showAppDialog<String>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      return _AppPasswordDialog(
        title: title,
        body: body,
        amountPoints: amountPoints,
      );
    },
  );
}

class _AppPasswordDialog extends StatefulWidget {
  const _AppPasswordDialog({
    required this.title,
    required this.body,
    this.amountPoints,
  });

  final String title;
  final String body;
  final int? amountPoints;

  @override
  State<_AppPasswordDialog> createState() => _AppPasswordDialogState();
}

class _AppPasswordDialogState extends State<_AppPasswordDialog> {
  static const _pinLength = 6;

  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(_pinLength, (_) => TextEditingController());
    _focusNodes = List.generate(_pinLength, (_) => FocusNode());
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

  String get _pin => _controllers.map((c) => c.text).join();

  void _onDigitChanged(int index, String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 1) {
      for (var i = 0; i < _pinLength; i++) {
        _controllers[i].text = i < digits.length ? digits[i] : '';
      }
      final focusIndex = digits.length.clamp(0, _pinLength) - 1;
      if (focusIndex >= 0) {
        _focusNodes[focusIndex.clamp(0, _pinLength - 1)].requestFocus();
      }
      if (digits.length >= _pinLength) _submit();
      return;
    }

    if (digits.isNotEmpty && index < _pinLength - 1) {
      _focusNodes[index + 1].requestFocus();
    }
    if (digits.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    if (_pin.length == _pinLength) _submit();
  }

  void _submit() {
    final pin = _pin;
    if (pin.length != _pinLength) return;
    Navigator.of(context).pop(pin);
  }

  @override
  Widget build(BuildContext context) {
    final amount = widget.amountPoints;

    return _appDialogShell(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogPngIcon(
                asset: _passwordIconAsset,
                background: AppColors.primaryLight,
              ),
              const SizedBox(height: _gapIconTitle),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: AppTheme.english(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                  height: 1.3,
                  letterSpacing: -0.2,
                ),
              ),
              if (amount != null) ...[
                const SizedBox(height: 8),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: NumberFormat('#,##0').format(amount),
                        style: AppTheme.english(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          height: 1.15,
                          letterSpacing: 0.2,
                        ),
                      ),
                      TextSpan(
                        text: ' ${'topup.pts'.tr()}',
                        style: AppTheme.english(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                          height: 1.15,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: _gapTitleBody),
              Text(
                widget.body,
                textAlign: TextAlign.center,
                style: AppTheme.english(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMuted,
                  height: 1.45,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, constraints) {
                  const gap = 6.0;
                  final box = ((constraints.maxWidth - gap * (_pinLength - 1)) /
                          _pinLength)
                      .clamp(32.0, 40.0);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        for (var i = 0; i < _pinLength; i++)
                          _AppPinBox(
                            size: box,
                            controller: _controllers[i],
                            focusNode: _focusNodes[i],
                            onChanged: (v) => _onDigitChanged(i, v),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          Positioned(
            top: -4,
            right: -4,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Navigator.of(context).pop(),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.primaryLight),
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppPinBox extends StatefulWidget {
  const _AppPinBox({
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
  State<_AppPinBox> createState() => _AppPinBoxState();
}

class _AppPinBoxState extends State<_AppPinBox> {
  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocus);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocus);
    super.dispose();
  }

  void _onFocus() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final focused = widget.focusNode.hasFocus;
    final fontSize = widget.size >= 38 ? 17.0 : 15.0;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppStyle.radiusInput),
          border: Border.all(
            color: focused ? AppColors.primary : AppColors.border,
            width: focused ? 1.6 : 1.2,
          ),
        ),
        child: TextField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          textAlign: TextAlign.center,
          textAlignVertical: TextAlignVertical.center,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          obscureText: true,
          obscuringCharacter: '•',
          maxLength: 1,
          showCursor: true,
          cursorColor: AppColors.primary,
          cursorWidth: 2,
          cursorHeight: fontSize,
          style: AppTheme.english(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            height: 1.2,
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
          onChanged: (value) {
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
    );
  }
}
