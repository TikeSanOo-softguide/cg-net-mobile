import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_endpoints/api_endpoints.dart';
import 'api_exception.dart';
import 'dio_client/dio_client.dart';
import 'get_retry_interceptor.dart';

typedef RecoveryAction = Future<void> Function();

class NetworkRecoveryController extends ChangeNotifier {
  NetworkRecoveryController(this._dio);

  final Dio _dio;
  final Map<String, RecoveryAction> _pending = {};

  Timer? _poller;
  bool _checking = false;
  int _backoffSeconds = 4;
  static const _maxBackoffSeconds = 60;
  DateTime? _nextCheckAt;
  DateTime? _lastProbeAt;
  bool? _lastProbeOnline;
  int _queuedTotal = 0;
  int _replayedTotal = 0;
  int _requeuedTotal = 0;

  int get pendingCount => _pending.length;
  int get queuedTotal => _queuedTotal;
  int get replayedTotal => _replayedTotal;
  int get requeuedTotal => _requeuedTotal;
  int get backoffSeconds => _backoffSeconds;
  DateTime? get nextCheckAt => _nextCheckAt;
  DateTime? get lastProbeAt => _lastProbeAt;
  bool? get lastProbeOnline => _lastProbeOnline;

  void enqueue(String key, RecoveryAction action) {
    final isNew = !_pending.containsKey(key);
    _pending[key] = action;
    if (isNew) _queuedTotal++;
    _scheduleCheck(const Duration(milliseconds: 250));
    unawaited(checkNow());
    notifyListeners();
  }

  void clear(String key) {
    if (_pending.remove(key) == null) return;
    if (_pending.isEmpty) {
      _poller?.cancel();
      _poller = null;
    }
    notifyListeners();
  }

  Future<void> checkNow() async {
    if (_checking || _pending.isEmpty) return;
    _checking = true;
    try {
      final online = await _probeOnline();
      if (!online) {
        _increaseBackoff();
        _scheduleCheck(Duration(seconds: _backoffSeconds));
        return;
      }
      _resetBackoff();
      await _flushPending();
    } finally {
      _checking = false;
      if (_pending.isEmpty) {
        _poller?.cancel();
        _poller = null;
        _nextCheckAt = null;
      } else if (_nextCheckAt == null) {
        _scheduleCheck(Duration(seconds: _backoffSeconds));
      }
    }
  }

  void _scheduleCheck(Duration delay) {
    _poller?.cancel();
    _nextCheckAt = DateTime.now().add(delay);
    _poller = Timer(delay, () {
      _nextCheckAt = null;
      unawaited(checkNow());
    });
  }

  Future<bool> _probeOnline() async {
    _lastProbeAt = DateTime.now();
    try {
      await _dio.get<dynamic>(
        ApiEndpoints.healthCheckPath,
        options: Options(
          connectTimeout: const Duration(seconds: 4),
          sendTimeout: const Duration(seconds: 4),
          receiveTimeout: const Duration(seconds: 4),
          extra: {GetRetryInterceptor.skipKey: true},
        ),
      );
      _lastProbeOnline = true;
      _debugLog('online probe success via ${ApiEndpoints.healthCheckPath}');
      return true;
    } on DioException catch (error) {
      final connectionIssue = _isConnectionIssue(error);
      _lastProbeOnline = !connectionIssue;
      if (connectionIssue) {
        _debugLog('online probe failed (${error.type})');
      }
      return !connectionIssue;
    } catch (_) {
      _lastProbeOnline = true;
      return true;
    }
  }

  Future<void> _flushPending() async {
    final entries = _pending.entries.toList();
    _pending.clear();

    for (final entry in entries) {
      try {
        await entry.value();
        _replayedTotal++;
      } on ApiException catch (error) {
        if (error.failure == ApiFailure.offline) {
          _pending[entry.key] = entry.value;
          _requeuedTotal++;
        }
      } on DioException catch (error) {
        if (_isConnectionIssue(error)) {
          _pending[entry.key] = entry.value;
          _requeuedTotal++;
        }
      }
    }
    notifyListeners();
  }

  void _increaseBackoff() {
    final next = (_backoffSeconds * 2).clamp(4, _maxBackoffSeconds);
    _backoffSeconds = next;
  }

  void _resetBackoff() {
    _backoffSeconds = 4;
  }

  bool _isConnectionIssue(DioException error) {
    return error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout;
  }

  void _debugLog(String message) {
    if (!kDebugMode) return;
    debugPrint('[network_recovery] $message');
  }

  @override
  void dispose() {
    _poller?.cancel();
    super.dispose();
  }
}

final networkRecoveryControllerProvider =
    ChangeNotifierProvider<NetworkRecoveryController>((ref) {
  return NetworkRecoveryController(ref.watch(dioProvider));
});
