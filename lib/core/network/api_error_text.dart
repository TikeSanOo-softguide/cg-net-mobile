import 'package:easy_localization/easy_localization.dart';

import 'api_exception.dart';

String apiErrorText(Object error) {
  if (error is ApiException) {
    final detail = error.detail;
    if (error.failure == ApiFailure.validation &&
        detail != null &&
        detail.isNotEmpty) {
      return detail;
    }
    return error.messageKey.tr();
  }
  return 'api.unknown'.tr();
}

String apiErrorOrFallback(
  Object? error, {
  String fallbackKey = 'common.error',
}) {
  if (error == null) return fallbackKey.tr();
  return apiErrorText(error);
}

String apiMessageText(
  String? message, {
  String fallbackKey = 'common.error',
}) {
  final value = message?.trim();
  if (value == null || value.isEmpty) {
    return fallbackKey.tr();
  }
  if (value.startsWith('api.')) {
    return value.tr();
  }
  return value;
}
