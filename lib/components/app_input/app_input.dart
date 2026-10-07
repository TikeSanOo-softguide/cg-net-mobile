import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors/app_colors.dart';
import '../../core/theme/app_style/app_style.dart';
import '../../core/theme/app_theme/app_theme.dart';

/// Common text field. Field icons render plain on the right (no icon background).
class AppInput extends StatefulWidget {
  const AppInput({
    super.key,
    this.formFieldKey,
    this.controller,
    this.label,
    this.hint,
    this.hintLetterSpacing,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.prefixIcon,
    this.suffixIcon,
    this.prefix,
    this.suffix,
    this.maxLength,
    this.maxLines = 1,
    this.enabled = true,
    this.readOnly = false,
    this.inputFormatters,
    this.autofocus = false,
    this.focusNode,
    this.autofillHints,
    this.reserveErrorSpace = true,
  });

  /// Key for the inner [TextFormField] (e.g. call `validate()`).
  final Key? formFieldKey;
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final double? hintLetterSpacing;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  /// Field icon shown on the right (common style).
  final IconData? prefixIcon;

  /// Explicit trailing icon (takes priority over [prefixIcon]).
  final IconData? suffixIcon;

  /// Custom leading widget (rare; left side).
  final Widget? prefix;

  /// Custom trailing widget (overrides icons when set).
  final Widget? suffix;

  final int? maxLength;
  final int maxLines;
  final bool enabled;
  final bool readOnly;
  final List<TextInputFormatter>? inputFormatters;
  final bool autofocus;
  final FocusNode? focusNode;
  final Iterable<String>? autofillHints;

  /// Keep a fixed helper/error slot so the CTA below does not jump when
  /// validation text appears. Only applied when [validator] is set.
  final bool reserveErrorSpace;

  /// Trailing field icon (no background).
  static Widget iconChip({
    required IconData icon,
    double size = 30,
    double iconSize = 17,
    bool focused = false,
    Color? backgroundColor,
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    final fg = iconColor ??
        (focused
            ? AppColors.primary
            : AppColors.primary.withValues(alpha: 0.72));

    final iconWidget = SizedBox(
      width: size,
      height: size,
      child: Icon(icon, size: iconSize, color: fg),
    );

    final child = onTap == null
        ? iconWidget
        : InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(6),
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            child: iconWidget,
          );

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: child,
    );
  }

  /// Compact + / check action used by multi-select (no background).
  static Widget actionButton({
    required IconData icon,
    VoidCallback? onTap,
    bool active = false,
    double size = 30,
    double iconSize = 18,
  }) {
    final child = SizedBox(
      width: size,
      height: size,
      child: Icon(
        icon,
        size: iconSize,
        color: active ? AppColors.primary : AppColors.primary,
      ),
    );

    if (onTap == null) return child;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: child,
    );
  }

  @override
  State<AppInput> createState() => _AppInputState();
}

class _AppInputState extends State<AppInput> {
  FocusNode? _ownedFocus;
  late FocusNode _focusNode;

  FocusNode get _effectiveFocus => widget.focusNode ?? _focusNode;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode == null) {
      _ownedFocus = FocusNode();
      _focusNode = _ownedFocus!;
    } else {
      _focusNode = widget.focusNode!;
    }
    _effectiveFocus.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant AppInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      _effectiveFocus.removeListener(_onFocusChange);
      _ownedFocus?.dispose();
      _ownedFocus = null;
      if (widget.focusNode == null) {
        _ownedFocus = FocusNode();
        _focusNode = _ownedFocus!;
      } else {
        _focusNode = widget.focusNode!;
      }
      _effectiveFocus.addListener(_onFocusChange);
    }
  }

  @override
  void dispose() {
    _effectiveFocus.removeListener(_onFocusChange);
    _ownedFocus?.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (mounted) setState(() {});
  }

  static const Color _idleBorder = AppColors.paperBorder;
  static const Color _idleFill = AppColors.surface;

  /// Fixed slot under the field so the CTA never jumps when errors appear.
  static const double _errorSlotHeight = AppStyle.errorSlotHeight;

  TextStyle _labelStyle(Set<WidgetState> states) {
    final focused = states.contains(WidgetState.focused);
    return AppTheme.english(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: focused ? AppColors.primary : AppColors.textSecondary,
      letterSpacing: 0.2,
    );
  }

  @override
  Widget build(BuildContext context) {
    final focused = _effectiveFocus.hasFocus;
    final labelStyle = WidgetStateTextStyle.resolveWith(_labelStyle);
    final fill = !widget.enabled
        ? AppColors.backgroundAlt
        : focused
            ? AppColors.surface
            : _idleFill;
    final reserveError =
        widget.reserveErrorSpace && widget.validator != null;
    final errorTextStyle = AppTheme.fieldError();

    return FormField<String>(
      key: widget.formFieldKey,
      validator: widget.validator == null
          ? null
          : (_) => widget.validator!(widget.controller?.text),
      initialValue: widget.controller?.text ?? '',
      builder: (field) {
        final hasError = field.hasError;
        final errorText = field.errorText;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: widget.controller,
              focusNode: _effectiveFocus,
              obscureText: widget.obscureText,
              keyboardType: widget.keyboardType,
              textInputAction: widget.textInputAction,
              onChanged: (value) {
                field.didChange(value);
                widget.onChanged?.call(value);
              },
              onSubmitted: widget.onSubmitted,
              maxLength: widget.maxLength,
              maxLines: widget.obscureText ? 1 : widget.maxLines,
              enabled: widget.enabled,
              readOnly: widget.readOnly,
              inputFormatters: widget.inputFormatters,
              autofocus: widget.autofocus,
              autofillHints: widget.autofillHints,
              style: AppTheme.english(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                letterSpacing: 0.2,
              ),
              cursorColor: AppColors.primary,
              decoration: InputDecoration(
                isDense: true,
                labelText: widget.label,
                hintText: widget.hint,
                hintStyle: AppTheme.english(
                  fontSize: 14,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                  letterSpacing: widget.hintLetterSpacing ?? 0.2,
                ),
                hintMaxLines: 1,
                labelStyle: labelStyle,
                floatingLabelStyle: labelStyle,
                filled: true,
                fillColor: fill,
                contentPadding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                prefixIcon: widget.prefix,
                suffixIcon: _buildTrailing(focused),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 40,
                  minHeight: 48,
                ),
                suffixIconConstraints: widget.suffix != null
                    ? const BoxConstraints(minWidth: 0, minHeight: 48)
                    : const BoxConstraints(minWidth: 40, minHeight: 48),
                border: hasError
                    ? AppStyle.inputErrorBorder
                    : _border(false),
                enabledBorder: hasError
                    ? AppStyle.inputErrorBorder
                    : _border(false),
                focusedBorder: hasError
                    ? AppStyle.inputErrorBorder
                    : _border(true),
                disabledBorder: _border(false),
                // Error copy is drawn in the fixed slot below (no built-in indent).
                errorText: null,
                counterText: '',
              ),
            ),
            if (reserveError)
              SizedBox(
                height: _errorSlotHeight,
                child: (hasError && errorText != null && errorText.isNotEmpty)
                    ? Align(
                        alignment: Alignment.bottomLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            errorText,
                            textAlign: TextAlign.left,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: errorTextStyle,
                          ),
                        ),
                      )
                    : null,
              )
            else if (hasError && errorText != null && errorText.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2, bottom: 2),
                child: Text(
                  errorText,
                  textAlign: TextAlign.left,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: errorTextStyle,
                ),
              ),
          ],
        );
      },
    );
  }

  OutlineInputBorder _border(bool focused) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(
        color: focused ? AppColors.primary : _idleBorder,
        width: focused ? 1.4 : 1,
      ),
    );
  }

  Widget? _buildTrailing(bool focused) {
    if (widget.suffix != null) return widget.suffix;

    final icon = widget.suffixIcon ?? widget.prefixIcon;
    if (icon == null) return null;

    return AppInput.iconChip(icon: icon, focused: focused);
  }
}
