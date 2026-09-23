import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../core/theme/app_colors/app_colors.dart';
import '../app_input/app_input.dart';
import 'app_barcode_scanner_page.dart';

/// Common [AppInput] with a real camera scan suffix (no chip background).
class AppScanInput extends StatelessWidget {
  const AppScanInput({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.maxLength,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String? Function(String?)? validator;

  String _normalize(String raw) {
    var next = TextEditingValue(text: raw.trim());
    for (final formatter in inputFormatters ?? const <TextInputFormatter>[]) {
      next = formatter.formatEditUpdate(TextEditingValue.empty, next);
    }
    final max = maxLength;
    if (max != null && next.text.length > max) {
      next = TextEditingValue(text: next.text.substring(0, max));
    }
    return next.text;
  }

  Future<void> _scan(BuildContext context) async {
    final raw = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const AppBarcodeScannerPage(),
      ),
    );
    if (raw == null || !context.mounted) return;
    final value = _normalize(raw);
    controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    onChanged?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    return AppInput(
      controller: controller,
      label: label,
      hint: hint,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      validator: validator,
      suffix: Tooltip(
        message: 'topup.scan'.tr(),
        child: AppInput.iconChip(
          icon: LucideIcons.scan_line,
          iconSize: 18,
          iconColor: AppColors.primary,
          onTap: () => _scan(context),
        ),
      ),
    );
  }
}
