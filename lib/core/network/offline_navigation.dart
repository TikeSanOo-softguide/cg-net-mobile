import 'api_exception.dart';

bool isOfflineError(Object? error) {
  return error is ApiException && error.failure == ApiFailure.offline;
}

bool isUnreachableError(Object? error) {
  return isOfflineError(error);
}

bool isUnreachableMessage(String? message) {
  return message == 'api.offline';
}

/// Internet works, but the API host did not accept a connection.
const serverUnavailableMessage = 'api.server_unavailable';

bool isServerUnavailableError(Object? error) {
  return error is ApiException &&
      error.failure == ApiFailure.server &&
      error.connectionFailed;
}

bool isServerUnavailableMessage(String? message) {
  return message == serverUnavailableMessage;
}

String storedApiMessage(ApiException error, {bool messageKeyOnly = false}) {
  if (isServerUnavailableError(error)) return serverUnavailableMessage;
  if (messageKeyOnly) return error.messageKey;
  final detail = error.detail?.trim();
  if (detail != null && detail.isNotEmpty) return detail;
  return error.messageKey;
}

/// Offline copy is only for a confirmed no-internet failure.
/// A slow response stays a timeout. An API the internet can reach stays a
/// server failure.
bool shouldPresentAsOffline(Object? error) {
  return isOfflineError(error);
}
