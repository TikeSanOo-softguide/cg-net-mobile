import 'package:flutter/services.dart';

TextInputFormatter maxLengthLimiter(int maxLength) {
  return TextInputFormatter.withFunction((_, newValue) {
    if (newValue.composing.isValid && !newValue.composing.isCollapsed) {
      return newValue;
    }

    final codePoints = newValue.text.runes;
    if (codePoints.length <= maxLength) return newValue;

    final limitedText = String.fromCharCodes(codePoints.take(maxLength));
    final baseOffset =
        newValue.selection.baseOffset.clamp(0, limitedText.length).toInt();
    final extentOffset =
        newValue.selection.extentOffset.clamp(0, limitedText.length).toInt();
    return newValue.copyWith(
      text: limitedText,
      selection: TextSelection(
        baseOffset: baseOffset,
        extentOffset: extentOffset,
        affinity: newValue.selection.affinity,
        isDirectional: newValue.selection.isDirectional,
      ),
      composing: TextRange.empty,
    );
  });
}
