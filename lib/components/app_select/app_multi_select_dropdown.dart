import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../core/theme/app_colors/app_colors.dart';
import '../../core/theme/app_style/app_style.dart';
import '../../core/theme/app_theme/app_theme.dart';
import '../app_button/app_button.dart';
import '../app_input/app_input.dart';
import 'app_select_dropdown.dart';

/// Multi-select field: selected chips + compact `+` action (no checkboxes).
class AppMultiSelectDropdown<T> extends StatefulWidget {
  const AppMultiSelectDropdown({
    super.key,
    required this.options,
    required this.onChanged,
    this.values = const [],
    this.label,
    this.hint,
    this.enabled = true,
  });

  final List<AppSelectOption<T>> options;
  final ValueChanged<List<T>> onChanged;
  final List<T> values;
  final String? label;
  final String? hint;
  final bool enabled;

  @override
  State<AppMultiSelectDropdown<T>> createState() =>
      _AppMultiSelectDropdownState<T>();
}

class _AppMultiSelectDropdownState<T> extends State<AppMultiSelectDropdown<T>> {
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  List<AppSelectOption<T>> get _selectedOptions => widget.options
      .where((o) => widget.values.contains(o.value))
      .toList(growable: false);

  void _remove(T value) {
    final next = List<T>.from(widget.values)..remove(value);
    widget.onChanged(next);
  }

  Future<void> _openSheet() async {
    if (!widget.enabled) return;
    _focusNode.requestFocus();

    final selected = Set<T>.from(widget.values);

    final result = await showModalBottomSheet<List<T>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppStyle.spaceLg,
                  AppStyle.spaceMd,
                  AppStyle.spaceLg,
                  AppStyle.spaceLg,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppStyle.spaceMd),
                    Text(
                      widget.label ?? widget.hint ?? '',
                      style: AppTheme.sectionTitle(),
                    ),
                    const SizedBox(height: AppStyle.spaceSm),
                    Text(
                      'package.multi_select_sheet_hint'.tr(),
                      style: AppTheme.bodySecondary(),
                    ),
                    const SizedBox(height: AppStyle.spaceMd),
                    if (selected.isNotEmpty) ...[
                      Wrap(
                        spacing: AppStyle.spaceSm,
                        runSpacing: AppStyle.spaceSm,
                        children: widget.options
                            .where((o) => selected.contains(o.value))
                            .map(
                              (o) => _SelectedChip(
                                label: o.label,
                                onRemove: () => setModalState(
                                  () => selected.remove(o.value),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: AppStyle.spaceMd),
                    ],
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.sizeOf(ctx).height * 0.42,
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: widget.options.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppStyle.spaceSm),
                        itemBuilder: (_, i) {
                          final option = widget.options[i];
                          final isSelected = selected.contains(option.value);
                          return Material(
                            color: isSelected
                                ? AppColors.primarySoft
                                : AppColors.backgroundAlt,
                            borderRadius: AppStyle.borderRadiusMd,
                            child: InkWell(
                              borderRadius: AppStyle.borderRadiusMd,
                              splashColor: Colors.black.withValues(alpha: 0.06),
                              highlightColor:
                                  Colors.black.withValues(alpha: 0.04),
                              onTap: () {
                                setModalState(() {
                                  if (isSelected) {
                                    selected.remove(option.value);
                                  } else {
                                    selected.add(option.value);
                                  }
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppStyle.spaceMd,
                                  vertical: AppStyle.spaceMd,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        option.label,
                                        style: AppTheme.english(
                                          fontSize: AppStyle.inputFontSize,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    AppInput.actionButton(
                                      icon: isSelected
                                          ? LucideIcons.check
                                          : LucideIcons.plus,
                                      active: isSelected,
                                      onTap: () {
                                        setModalState(() {
                                          if (isSelected) {
                                            selected.remove(option.value);
                                          } else {
                                            selected.add(option.value);
                                          }
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: AppStyle.spaceMd),
                    AppButton(
                      label: 'common.done'.tr(),
                      onPressed: () =>
                          Navigator.pop(ctx, selected.toList(growable: false)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (!mounted) return;
    _focusNode.unfocus();
    if (result != null) widget.onChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    final focused = _focusNode.hasFocus;
    final labelColor = focused ? AppColors.primary : AppColors.textSecondary;
    final selected = _selectedOptions;

    return Focus(
      focusNode: _focusNode,
      child: GestureDetector(
        onTap: widget.enabled && selected.isEmpty ? _openSheet : null,
        child: InputDecorator(
          isFocused: focused,
          isEmpty: selected.isEmpty,
          decoration: InputDecoration(
            isDense: true,
            labelText: widget.label,
            hintText: selected.isEmpty ? widget.hint : null,
            hintStyle: AppTheme.english(
              fontSize: AppStyle.inputFontSize,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w400,
            ),
            labelStyle: AppTheme.english(
              fontSize: AppStyle.fontSecondary,
              fontWeight: FontWeight.w600,
              color: labelColor,
            ),
            floatingLabelStyle: AppTheme.english(
              fontSize: AppStyle.fontSecondary,
              fontWeight: FontWeight.w600,
              color: labelColor,
            ),
            filled: true,
            fillColor: !widget.enabled
                ? AppColors.backgroundAlt
                : focused
                    ? AppColors.surface
                    : AppColors.primarySoft,
            contentPadding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
            suffixIcon: Padding(
              padding: const EdgeInsets.only(right: 10),
              child: AppInput.actionButton(
                icon: LucideIcons.plus,
                onTap: widget.enabled ? _openSheet : null,
              ),
            ),
            suffixIconConstraints: const BoxConstraints(
              minWidth: 44,
              minHeight: 48,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.paperBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.paperBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.4),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.paperBorder),
            ),
          ),
          child: selected.isEmpty
              ? Text(
                  widget.hint ?? '',
                  style: AppTheme.english(
                    fontSize: AppStyle.inputFontSize,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textMuted,
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.only(right: AppStyle.spaceSm),
                  child: Wrap(
                    spacing: AppStyle.spaceSm,
                    runSpacing: AppStyle.spaceSm,
                    children: selected
                        .map(
                          (o) => _SelectedChip(
                            label: o.label,
                            onRemove:
                                widget.enabled ? () => _remove(o.value) : null,
                          ),
                        )
                        .toList(),
                  ),
                ),
        ),
      ),
    );
  }
}

class _SelectedChip extends StatelessWidget {
  const _SelectedChip({required this.label, this.onRemove});

  final String label;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 10, right: 4, top: 5, bottom: 5),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTheme.english(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          if (onRemove != null) ...[
            const SizedBox(width: 2),
            InkWell(
              onTap: onRemove,
              customBorder: const CircleBorder(),
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(
                  LucideIcons.x,
                  size: 12,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
