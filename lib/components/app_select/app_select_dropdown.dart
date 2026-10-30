import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../core/theme/app_colors/app_colors.dart';
import '../../core/theme/app_style/app_style.dart';
import '../../core/theme/app_theme/app_theme.dart';

class AppSelectOption<T> {
  const AppSelectOption({required this.value, required this.label});

  final T value;
  final String label;
}

/// Compact overlay select, aligned with [AppInput].
class AppSelectDropdown<T> extends StatefulWidget {
  const AppSelectDropdown({
    super.key,
    required this.options,
    required this.onChanged,
    this.value,
    this.label,
    this.hint,
    this.enabled = true,
    this.validator,
    this.reserveErrorSpace = true,
  });

  final List<AppSelectOption<T>> options;
  final ValueChanged<T?> onChanged;
  final T? value;
  final String? label;
  final String? hint;
  final bool enabled;
  final String? Function(T?)? validator;
  final bool reserveErrorSpace;

  @override
  State<AppSelectDropdown<T>> createState() => _AppSelectDropdownState<T>();
}

class _AppSelectDropdownState<T> extends State<AppSelectDropdown<T>> {
  final _focusNode = FocusNode();
  final _layerLink = LayerLink();
  final _triggerKey = GlobalKey();
  OverlayEntry? _overlay;
  bool _open = false;
  bool _openUpward = false;
  double _menuWidth = 0;
  double _menuMaxHeight = 200;

  static const _itemHeight = 40.0;
  static const _menuRadius = 10.0;
  static const _fieldRadius = 8.0;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant AppSelectDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_open) _rebuildOverlay();
  }

  @override
  void dispose() {
    _removeOverlay();
    _focusNode.dispose();
    super.dispose();
  }

  AppSelectOption<T>? get _selected {
    for (final option in widget.options) {
      if (option.value == widget.value) return option;
    }
    return null;
  }

  InputBorder _border({required bool focused, required bool hasError}) {
    if (hasError) return AppStyle.inputErrorBorder;
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(_fieldRadius),
      borderSide: BorderSide(
        color: focused ? AppColors.primary : AppColors.paperBorder,
        width: focused ? 1.4 : 1,
      ),
    );
  }

  void _rebuildOverlay() => _overlay?.markNeedsBuild();

  void _removeOverlay() {
    _overlay?.remove();
    _overlay = null;
  }

  void _closeMenu() {
    if (!_open) return;
    _removeOverlay();
    _focusNode.unfocus();
    setState(() => _open = false);
  }

  double _menuHeightFor(int itemCount, double available) {
    final wanted = math.max(itemCount, 1) * _itemHeight + 8;
    final maxHeight = available.isFinite && available > 0 ? available : wanted;
    return math.max(72.0, math.min(wanted, maxHeight));
  }

  Future<void> _toggleMenu(FormFieldState<T> field) async {
    if (!widget.enabled || widget.options.isEmpty) return;
    if (_open) {
      _closeMenu();
      return;
    }

    final box = _triggerKey.currentContext?.findRenderObject() as RenderBox?;
    final overlay = Overlay.of(context, debugRequiredFor: widget);
    final overlayBox = overlay.context.findRenderObject() as RenderBox?;
    if (box == null || overlayBox == null) return;

    final triggerSize = box.size;
    final triggerOffset = box.localToGlobal(Offset.zero, ancestor: overlayBox);
    final spaceBelow = math.max(
      0.0,
      overlayBox.size.height - triggerOffset.dy - triggerSize.height - 8,
    );
    final spaceAbove = math.max(0.0, triggerOffset.dy - 8);
    _openUpward = spaceBelow < 140 && spaceAbove > spaceBelow;
    final available = math.max(
      72.0,
      _openUpward ? spaceAbove : spaceBelow,
    );
    _menuMaxHeight = _menuHeightFor(widget.options.length, available);
    _menuWidth = math.max(triggerSize.width, 140);

    _focusNode.requestFocus();
    setState(() => _open = true);
    _overlay = OverlayEntry(
      builder: (context) => _buildOverlay(field, triggerSize.height),
    );
    overlay.insert(_overlay!);
  }

  Widget _buildOverlay(FormFieldState<T> field, double triggerHeight) {
    final options = widget.options;
    final height = _menuHeightFor(
      options.isEmpty ? 1 : options.length,
      _menuMaxHeight,
    );
    final offset = _openUpward
        ? Offset(0, -height - 6)
        : Offset(0, triggerHeight + 6);

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _closeMenu,
          ),
        ),
        CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: offset,
          child: Material(
            color: Colors.transparent,
            child: SizedBox(
              width: _menuWidth,
              height: height,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(_menuRadius),
                  border: Border.all(color: AppColors.paperBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(_menuRadius),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options[index];
                      final isSelected = option.value == widget.value;
                      return InkWell(
                        onTap: () {
                          field.didChange(option.value);
                          widget.onChanged(option.value);
                          _closeMenu();
                        },
                        child: Container(
                          height: _itemHeight,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          color: isSelected
                              ? AppColors.primarySoft
                              : Colors.transparent,
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  option.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTheme.english(
                                    fontSize: 13,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  LucideIcons.check,
                                  size: 14,
                                  color: AppColors.primary,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final focused = _focusNode.hasFocus || _open;
    final selected = _selected;
    final labelColor = focused ? AppColors.primary : AppColors.textSecondary;

    return FormField<T>(
      validator: (_) => widget.validator?.call(widget.value),
      initialValue: widget.value,
      builder: (field) {
        final hasError = field.hasError;
        final errorText = field.errorText;
        final border = _border(focused: focused, hasError: hasError);
        final reserveError =
            widget.reserveErrorSpace && widget.validator != null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            CompositedTransformTarget(
              link: _layerLink,
              child: Material(
                key: _triggerKey,
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.enabled ? () => _toggleMenu(field) : null,
                  borderRadius: BorderRadius.circular(_fieldRadius),
                  child: InputDecorator(
                    isFocused: focused,
                    isEmpty: selected == null,
                    decoration: InputDecoration(
                      isDense: true,
                      labelText: widget.label,
                      hintText: selected == null ? widget.hint : null,
                      errorStyle: const TextStyle(height: 0, fontSize: 0),
                      errorText: hasError ? '' : null,
                      hintStyle: AppTheme.english(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMuted,
                        letterSpacing: 0.2,
                      ),
                      labelStyle: AppTheme.english(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: labelColor,
                        letterSpacing: 0.2,
                      ),
                      floatingLabelStyle: AppTheme.english(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: labelColor,
                        letterSpacing: 0.2,
                      ),
                      filled: true,
                      fillColor: !widget.enabled
                          ? AppColors.backgroundAlt
                          : AppColors.surface,
                      contentPadding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
                      suffixIcon: Icon(
                        _open
                            ? LucideIcons.chevron_up
                            : LucideIcons.chevron_down,
                        size: 16,
                        color: focused
                            ? AppColors.primary
                            : AppColors.textMuted,
                      ),
                      suffixIconConstraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 40,
                      ),
                      border: border,
                      enabledBorder: border,
                      focusedBorder: border,
                      errorBorder: AppStyle.inputErrorBorder,
                      focusedErrorBorder: AppStyle.inputErrorBorder,
                      disabledBorder: _border(
                        focused: false,
                        hasError: false,
                      ),
                    ),
                    child: Focus(
                      focusNode: _focusNode,
                      child: Text(
                        selected?.label ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.english(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (reserveError)
              SizedBox(
                height: AppStyle.errorSlotHeight,
                child: (hasError && errorText != null && errorText.isNotEmpty)
                    ? Align(
                        alignment: Alignment.bottomLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            errorText,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.fieldError(),
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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.fieldError(),
                ),
              ),
          ],
        );
      },
    );
  }
}
