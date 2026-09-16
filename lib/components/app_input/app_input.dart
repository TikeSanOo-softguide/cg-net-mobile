import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors/app_colors.dart';
import '../../core/theme/app_style/app_style.dart';
import '../../core/theme/app_theme/app_theme.dart';

/// Common text field. Field icons render plain on the right (no icon background).
class AppInput extends StatefulWidget {
  const AppInput({
    super.key,
    this.controller,
    this.label,
    this.hint,
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
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
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

  /// Trailing field icon (no background).
  static Widget iconChip({
    required IconData icon,
    double size = 28,
    double iconSize = 15,
    bool focused = false,
    Color? backgroundColor,
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    final fg = iconColor ??
        (focused ? AppColors.primary : AppColors.primary.withValues(alpha: 0.72));

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

  static const Color _idleBorder = AppColors.textMuted;
  static const Color _idleFill = AppColors.surface;

  TextStyle _labelStyle(Set<WidgetState> states) {
    final focused = states.contains(WidgetState.focused);
    return AppTheme.english(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: focused ? AppColors.primary : AppColors.textSecondary,
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

    return TextFormField(
      controller: widget.controller,
      focusNode: _effectiveFocus,
      obscureText: widget.obscureText,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      validator: widget.validator,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onSubmitted,
      maxLength: widget.maxLength,
      maxLines: widget.obscureText ? 1 : widget.maxLines,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      inputFormatters: widget.inputFormatters,
      autofocus: widget.autofocus,
      style: AppTheme.english(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      ),
      cursorColor: AppColors.primary,
      decoration: InputDecoration(
        isDense: true,
        labelText: widget.label,
        hintText: widget.hint,
        hintStyle: AppTheme.english(
          fontSize: 12,
          color: AppColors.textMuted,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: labelStyle,
        floatingLabelStyle: labelStyle,
        filled: true,
        fillColor: fill,
        contentPadding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        prefixIcon: widget.prefix,
        suffixIcon: _buildTrailing(focused),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 36,
          minHeight: 44,
        ),
        suffixIconConstraints: const BoxConstraints(
          minWidth: 36,
          minHeight: 44,
        ),
        border: _border(false),
        enabledBorder: _border(false),
        focusedBorder: _border(true),
        errorBorder: AppStyle.inputErrorBorder,
        focusedErrorBorder: AppStyle.inputErrorBorder,
        disabledBorder: _border(false),
        counterText: '',
      ),
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
