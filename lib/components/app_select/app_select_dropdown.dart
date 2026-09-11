import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../core/theme/app_colors/app_colors.dart';
import '../../core/theme/app_style/app_style.dart';
import '../../core/theme/app_theme/app_theme.dart';
import '../app_input/app_input.dart';

class AppSelectOption<T> {
  const AppSelectOption({required this.value, required this.label});

  final T value;
  final String label;
}

/// Single-select dropdown styled like [AppInput].
class AppSelectDropdown<T> extends StatelessWidget {
  const AppSelectDropdown({
    super.key,
    required this.options,
    required this.onChanged,
    this.value,
    this.label,
    this.hint,
    this.enabled = true,
  });

  final List<AppSelectOption<T>> options;
  final ValueChanged<T?> onChanged;
  final T? value;
  final String? label;
  final String? hint;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final labelStyle = WidgetStateTextStyle.resolveWith((states) {
      final focused = states.contains(WidgetState.focused);
      return AppTheme.english(
        fontSize: AppStyle.fontSecondary,
        fontWeight: FontWeight.w500,
        color: focused ? AppColors.primary : AppColors.textSecondary,
      );
    });

    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      icon: const SizedBox.shrink(),
      dropdownColor: AppColors.surface,
      borderRadius: AppStyle.borderRadiusMd,
      style: AppTheme.english(
        fontSize: AppStyle.inputFontSize,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        isDense: true,
        labelText: label,
        hintText: hint,
        hintStyle: AppTheme.english(
          fontSize: AppStyle.inputFontSize,
          color: AppColors.textMuted,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: labelStyle,
        floatingLabelStyle: labelStyle,
        filled: true,
        fillColor: enabled ? AppColors.primarySoft : AppColors.backgroundAlt,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        suffixIcon: AppInput.iconChip(
          icon: LucideIcons.chevron_down,
          size: 32,
          iconSize: 15,
        ),
        suffixIconConstraints: const BoxConstraints(
          minWidth: 40,
          minHeight: 48,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
        ),
        errorBorder: AppStyle.inputErrorBorder,
        focusedErrorBorder: AppStyle.inputErrorBorder,
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
      ),
      selectedItemBuilder: (context) {
        return options
            .map(
              (option) => Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  option.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.english(
                    fontSize: AppStyle.inputFontSize,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            )
            .toList();
      },
      items: options
          .map(
            (option) => DropdownMenuItem<T>(
              value: option.value,
              child: Text(
                option.label,
                style: AppTheme.english(
                  fontSize: AppStyle.inputFontSize,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          )
          .toList(),
      onChanged: enabled ? onChanged : null,
    );
  }
}
