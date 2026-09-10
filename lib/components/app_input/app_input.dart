import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors/app_colors.dart';
import '../../core/theme/app_style/app_style.dart';
import '../../core/theme/app_theme/app_theme.dart';

/// Common text field. Field icons render on the **right** by default.
class AppInput extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      maxLength: maxLength,
      maxLines: obscureText ? 1 : maxLines,
      enabled: enabled,
      readOnly: readOnly,
      inputFormatters: inputFormatters,
      autofocus: autofocus,
      style: AppTheme.english(
        fontSize: AppStyle.inputFontSize,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      ),
      cursorColor: AppColors.primary,
      decoration: InputDecoration(
        isDense: true,
        labelText: label,
        hintText: hint,
        hintStyle: AppTheme.english(
          fontSize: AppStyle.inputFontSize,
          color: AppColors.textMuted,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: AppTheme.bodySecondary(
          color: AppColors.textSecondary,
        ).copyWith(fontWeight: FontWeight.w500),
        filled: true,
        fillColor: enabled ? AppColors.surface : AppColors.backgroundAlt,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppStyle.spaceMd,
          vertical: AppStyle.spaceMd,
        ),
        prefixIcon: prefix,
        suffixIcon: _buildTrailing(),
        prefixIconConstraints: const BoxConstraints(
          minWidth: AppStyle.iconBox,
          minHeight: AppStyle.controlHeight,
        ),
        suffixIconConstraints: const BoxConstraints(
          minWidth: AppStyle.iconBox,
          minHeight: AppStyle.controlHeight,
        ),
        border: AppStyle.inputBorder,
        enabledBorder: AppStyle.inputBorder,
        focusedBorder: AppStyle.inputFocusedBorder,
        errorBorder: AppStyle.inputErrorBorder,
        focusedErrorBorder: AppStyle.inputErrorBorder,
        disabledBorder: AppStyle.inputBorder,
        counterText: '',
      ),
    );
  }

  Widget? _buildTrailing() {
    if (suffix != null) return suffix;

    final icon = suffixIcon ?? prefixIcon;
    if (icon == null) return null;

    return Icon(
      icon,
      size: AppStyle.iconSizeSm,
      color: AppColors.primary,
    );
  }
}
