import 'dart:async';
import 'dart:io';

import 'internet_reachability.dart';
import 'network_status.dart';

/// Checks whether the Chen Guang API host accepts a connection.
/// This result is not an internet status.
abstract class BackendProbe {
  Future<BackendStatus> check();
}

class InactiveBackendProbe implements BackendProbe {
  const InactiveBackendProbe();

  @override
  Future<BackendStatus> check() async => BackendStatus.unknown;
}

class SocketBackendProbe implements BackendProbe {
  SocketBackendProbe({
    ReachabilityTarget? target,
    this.timeout = const Duration(seconds: 4),
    SocketConnector? connector,
  })  : _target = target,
        _connector = connector ?? connectSocket;

  final ReachabilityTarget? _target;
  final Duration timeout;
  final SocketConnector _connector;

  @override
  Future<BackendStatus> check() async {
    final target = _target ?? apiHostTarget();
    if (target == null) return BackendStatus.unknown;
    try {
      final socket = await _connector(target.host, target.port, timeout);
      await socket.close();
      return BackendStatus.available;
    } on SocketException {
      return BackendStatus.unavailable;
    } on TimeoutException {
      return BackendStatus.unavailable;
    }
  }
}
