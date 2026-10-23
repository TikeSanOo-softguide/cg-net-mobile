import 'package:easy_localization/easy_localization.dart';

import 'api_exception.dart';
import 'message_codes.dart';

String apiErrorText(Object error) {
  if (error is ApiException) {
    if (MessageCodes.isKnown(error.code)) {
      return MessageCodes.locKey(error.code!).tr();
    }

    return switch (error.failure) {
      ApiFailure.offline =>
        MessageCodes.locKey(MessageCodes.apiNetworkFailed).tr(),
      ApiFailure.timeout => MessageCodes.locKey(MessageCodes.apiTimeout).tr(),
      ApiFailure.cancelled =>
        MessageCodes.locKey(MessageCodes.apiCancelled).tr(),
      ApiFailure.unauthorized =>
        MessageCodes.locKey(MessageCodes.authSessionExpired).tr(),
      ApiFailure.tooManyRequests =>
        MessageCodes.locKey(MessageCodes.authTooManyRequests).tr(),
      ApiFailure.server => MessageCodes.locKey(MessageCodes.sysUnexpected).tr(),
      ApiFailure.validation =>
        (error.detail != null && error.detail!.isNotEmpty)
            ? error.detail!
            : MessageCodes.locKey(MessageCodes.sysUnexpected).tr(),
      ApiFailure.unknown => (error.detail != null && error.detail!.isNotEmpty)
          ? error.detail!
          : MessageCodes.locKey(MessageCodes.sysUnexpected).tr(),
    };
  }
  return MessageCodes.locKey(MessageCodes.sysUnexpected).tr();
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
  if (MessageCodes.isKnown(value)) {
    return MessageCodes.locKey(value).tr();
  }
  if (value.startsWith('api.') || value.startsWith('msg.')) {
    return value.tr();
  }
  return value;
}
