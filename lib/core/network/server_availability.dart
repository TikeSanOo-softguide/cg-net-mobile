import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_exception.dart';
import 'network_status.dart';
import 'offline_navigation.dart';

enum ServerNotice { down, restored }

/// Short server notices. Down is shown on purpose. Restored follows a real
/// successful request or probe, not the phone network coming back.
class GlobalServerNotice {
  GlobalServerNotice._();

  static final List<void Function(ServerNotice notice)> _listeners = [];

  static void showDown() => _emit(ServerNotice.down);

  static void showRestored() => _emit(ServerNotice.restored);

  static void register(void Function(ServerNotice notice) listener) {
    _listeners.add(listener);
  }

  static void unregister(void Function(ServerNotice notice) listener) {
    _listeners.remove(listener);
  }

  static void _emit(ServerNotice notice) {
    for (final listener in List.of(_listeners)) {
      listener(notice);
    }
  }
}

/// List reloads that failed because the API host could not be reached.
/// Payments are not registered here.
class ServerListRecovery extends ChangeNotifier {
  final Map<String, Future<void> Function()> _pending = {};
  bool _flushing = false;

  void arm(String key, Future<void> Function() reload) {
    _pending[key] = reload;
  }

  void clear(String key) {
    _pending.remove(key);
  }

  Future<void> flush() async {
    if (_flushing) return;
    _flushing = true;
    try {
      final entries = _pending.entries.toList();
      for (final entry in entries) {
        if (!_pending.containsKey(entry.key)) continue;
        try {
          await entry.value();
        } catch (_) {}
      }
    } finally {
      _flushing = false;
    }
  }
}

final serverListRecoveryProvider =
    ChangeNotifierProvider<ServerListRecovery>((ref) {
  final recovery = ServerListRecovery();
  void onNotice(ServerNotice notice) {
    if (notice == ServerNotice.restored) {
      unawaited(recovery.flush());
    }
  }

  GlobalServerNotice.register(onNotice);
  ref.onDispose(() => GlobalServerNotice.unregister(onNotice));
  return recovery;
});

/// Marks the API host down or back from real HTTP traffic.
class ServerAvailabilityInterceptor extends Interceptor {
  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    if (BackendStatusSnapshot.current == BackendStatus.unavailable) {
      BackendStatusSnapshot.update(BackendStatus.available);
      GlobalServerNotice.showRestored();
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (isServerUnavailableError(ApiException.fromDio(err))) {
      BackendStatusSnapshot.update(BackendStatus.unavailable);
    }
    handler.next(err);
  }
}
