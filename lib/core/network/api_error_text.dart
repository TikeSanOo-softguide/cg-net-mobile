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
