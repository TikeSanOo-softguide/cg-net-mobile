import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../components/app_dialog/app_dialog.dart';
import 'api_error_text.dart';
import 'api_exception.dart';
import 'offline_navigation.dart';

/// Shows the common success / warning / failure dialog from backend `level`.
/// Offline errors open the no-internet page instead.
Future<void> showApiMessageModal(
  BuildContext context,
  Object? error, {
  String fallbackKey = 'common.error',
}) async {
  if (error == null) return;
  if (!context.mounted) return;

  if (isOfflineError(error)) {
    await openNoInternetPage(context);
    return;
  }
  if (!context.mounted) return;

  final body = apiErrorOrFallback(error, fallbackKey: fallbackKey);
  final apiError = error is ApiException ? error : null;
  final level = apiError?.level;

  if (level == 'success') {
    await showAppSuccessModal(
      context,
      title: 'common.success'.tr(),
      body: body,
    );
    return;
  }

  if (level == 'warning') {
    await showAppAlertModal(
      context,
      title: 'common.warning'.tr(),
      message: body,
    );
    return;
  }

  await showAppFailureModal(
    context,
    title: 'common.error'.tr(),
    body: body,
    retryAfterSeconds: _retryAfterSeconds(apiError),
  );
}

int? _retryAfterSeconds(ApiException? error) {
  if (error == null || error.failure != ApiFailure.tooManyRequests) {
    return null;
  }
  final data = error.responseData;
  if (data is Map) {
    final raw = data['retry_after'];
    if (raw is int && raw > 0) return raw;
    if (raw is num && raw > 0) return raw.toInt();
    if (raw is String) {
      final parsed = int.tryParse(raw);
      if (parsed != null && parsed > 0) return parsed;
    }
  }
  final fromDetail = int.tryParse(error.detail ?? '');
  if (fromDetail != null && fromDetail > 0) return fromDetail;
  return null;
}
