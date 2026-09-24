import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../core/theme/app_colors/app_colors.dart';
import '../../core/theme/app_theme/app_theme.dart';

/// Serial field + Check CTA — borders meet at the join (button not inside the field).
class AppPillActionInput extends StatefulWidget {
  const AppPillActionInput({
    super.key,
    this.fieldKey,
    required this.controller,
    required this.hint,
    required this.actionLabel,
    required this.onAction,
    this.label,
    this.actionEnabled = true,
    this.actionActive = false,
    this.maxLength,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.onChanged,
    this.validator,
  });

  final Key? fieldKey;
  final TextEditingController controller;
  final String? label;
  final String hint;
  final String actionLabel;
  final VoidCallback? onAction;
  final bool actionEnabled;
  final bool actionActive;
  final int? maxLength;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;

  @override
  State<AppPillActionInput> createState() => _AppPillActionInputState();
}

class _AppPillActionInputState extends State<AppPillActionInput> {
  final FocusNode _focus = FocusNode();

  static const _fieldRadius = BorderRadius.only(
    topLeft: Radius.circular(8),
    bottomLeft: Radius.circular(8),
  );
  static const _actionRadius = BorderRadius.only(
    topRight: Radius.circular(8),
    bottomRight: Radius.circular(8),
  );

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  OutlineInputBorder _fieldBorder({
    required bool focused,
    required bool error,
  }) {
    final color = error
        ? AppColors.error
        : focused
            ? AppColors.primary
            : AppColors.paperBorder;
    return OutlineInputBorder(
      borderRadius: _fieldRadius,
      borderSide: BorderSide(
        color: color,
        width: focused || error ? 1.4 : 1,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canTap = widget.actionEnabled && widget.onAction != null;
    final fg = widget.actionActive ? AppColors.onPrimary : AppColors.primary;
    final bg =
        widget.actionActive ? AppColors.primary : AppColors.primaryLight;
    final focused = _focus.hasFocus;

    return FormField<String>(
      key: widget.fieldKey,
      initialValue: widget.controller.text,
      validator: (_) => widget.validator?.call(widget.controller.text),
      builder: (field) {
        final hasError = field.hasError;
        final labelColor = hasError
            ? AppColors.error
            : focused
                ? AppColors.primary
                : AppColors.textSecondary;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: TextField(
                      controller: widget.controller,
                      focusNode: _focus,
                      maxLength: widget.maxLength,
                      keyboardType: widget.keyboardType,
                      textInputAction: widget.textInputAction,
                      inputFormatters: widget.inputFormatters,
                      onChanged: (v) {
                        field.didChange(v);
                        widget.onChanged?.call(v);
                      },
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
                        labelStyle: AppTheme.english(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: labelColor,
                        ),
                        floatingLabelStyle: AppTheme.english(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: labelColor,
                        ),
                        filled: true,
                        fillColor: AppColors.surface,
                        contentPadding:
                            const EdgeInsets.fromLTRB(12, 12, 12, 12),
                        counterText: '',
                        border: _fieldBorder(focused: false, error: hasError),
                        enabledBorder:
                            _fieldBorder(focused: false, error: hasError),
                        focusedBorder:
                            _fieldBorder(focused: true, error: hasError),
                        errorBorder:
                            _fieldBorder(focused: false, error: true),
                        focusedErrorBorder:
                            _fieldBorder(focused: true, error: true),
                        errorText: null,
                        errorStyle: const TextStyle(height: 0, fontSize: 0),
                      ),
                    ),
                  ),
                  Transform.translate(
                    offset: Offset(
                      focused || hasError || widget.actionActive ? -1.4 : -1,
                      0,
                    ),
                    child: Material(
                      color: bg,
                      shape: RoundedRectangleBorder(
                        borderRadius: _actionRadius,
                        side: BorderSide(
                          color: hasError
                              ? AppColors.error
                              : widget.actionActive
                                  ? AppColors.primary
                                  : (focused
                                      ? AppColors.primary
                                      : AppColors.paperBorder),
                          width: focused || hasError || widget.actionActive
                              ? 1.4
                              : 1,
                        ),
                      ),
                      child: InkWell(
                        onTap: canTap ? widget.onAction : null,
                        borderRadius: _actionRadius,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                LucideIcons.badge_check,
                                size: 13,
                                color: fg,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.actionLabel,
                                style: AppTheme.button(color: fg).copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  height: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (hasError)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 12),
                child: Text(
                  field.errorText ?? '',
                  style: AppTheme.english(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.error,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
