import 'package:cg_net_mobile/core/network/api_error_text.dart';
import 'package:cg_net_mobile/core/network/api_exception.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../components/app_dialog/app_dialog.dart';
import '../network/message_codes.dart';

typedef FieldKey = GlobalKey<FormFieldState<String>>;

mixin ApiFieldErrorsMixin<T extends StatefulWidget> on State<T> {
  final Map<String, String> _apiFieldErrors = {};

  /// Use at the END of a validator: `return localError ?? apiFieldError('x');`
  String? apiFieldError(String field) {
    final message = _apiFieldErrors[field];
    return message == null ? null : apiMessageText(message);
  }

  /// Call from the field's onChanged.
  void clearApiFieldError(String field, {FieldKey? key}) {
    if (_apiFieldErrors.remove(field) != null) {
      key?.currentState?.validate();
    }
  }

  void clearAllApiFieldErrors() => _apiFieldErrors.clear();

  /// Extracts `{field: firstMessage}` from a Laravel-style 422 response.
  Map<String, String> _extractFieldErrors(Object error) {
    if (error is! ApiException || error.failure != ApiFailure.validation) {
      return {};
    }
    final data = error.responseData;
    if (data is! Map) return {};
    final errors = data['errors'];
    if (errors is! Map) return {};

    return {
      for (final entry in errors.entries)
        if (entry.key is String)
          entry.key as String:
              entry.value is List && (entry.value as List).isNotEmpty
                  ? (entry.value as List).first.toString()
                  : entry.value.toString(),
    };
  }

  /// One entry point for every API error.
  /// [fields] maps API field name -> the FormField key to re-validate.
  /// [messageCodeFields] maps backend message codes to form field names.
  /// Returns true if the error was shown inline on a field.
  bool handleApiError(
    Object error, {
    Map<String, FieldKey> fields = const {},
    Map<String, String> messageCodeFields = const {},
  }) {
    if (!mounted) return false;

    // 1) Validation errors -> inline on matching fields
    final fieldErrors = _extractFieldErrors(error);
    final code =
        error is ApiException ? error.code?.trim().toUpperCase() : null;
    final codeField = error is ApiException &&
            error.failure == ApiFailure.validation &&
            code != null
        ? messageCodeFields[code]
        : null;
    final matched = {
      ...fieldErrors.keys.where(fields.containsKey),
      if (codeField != null && fields.containsKey(codeField)) codeField,
    }.toList();
    if (matched.isNotEmpty) {
      final messageCode =
          error is ApiException && MessageCodes.isKnown(error.code)
              ? error.code!
              : null;
      for (final name in matched) {
        _apiFieldErrors[name] = messageCode ?? fieldErrors[name]!;
      }
      for (final name in matched) {
        fields[name]!.currentState?.validate();
      }
      return true;
    }

    showAppFailureModal(
      context,
      title: 'common.error'.tr(),
      body: apiErrorText(error),
    );
    return false;
  }
}
