import 'dart:async';
import 'dart:io';

import 'api_endpoints/api_endpoints.dart';

enum Reachability { internet, noInternet }

class ReachabilityTarget {
  const ReachabilityTarget(this.host, this.port);

  final String host;
  final int port;
}

/// Opens a short socket to a public host. This does not call the Chen Guang API.
abstract class InternetReachability {
  Future<Reachability> check();
}

typedef SocketConnector = Future<Socket> Function(
  String host,
  int port,
  Duration timeout,
);

Future<Socket> connectSocket(String host, int port, Duration timeout) {
  return Socket.connect(host, port, timeout: timeout);
}

/// A socket that connects, or is refused, means a path to that public host exists.
enum SocketPath { reachable, noInternet, unknown }

SocketPath classifySocketException(SocketException error) {
  final text = '${error.message} ${error.osError?.message ?? ''}'.toLowerCase();
  if (text.contains('connection refused') ||
      text.contains('connection reset') ||
      text.contains('broken pipe') ||
      text.contains('connection aborted')) {
    return SocketPath.reachable;
  }
  if (text.contains('failed host lookup') ||
      text.contains('network is unreachable') ||
      text.contains('network unreachable') ||
      text.contains('no address associated') ||
      text.contains('no route to host') ||
      text.contains('network is down')) {
    return SocketPath.noInternet;
  }
  return SocketPath.unknown;
}

/// Public internet targets. One failure does not mean the device is offline.
const List<ReachabilityTarget> publicReachabilityTargets = [
  ReachabilityTarget('1.1.1.1', 443),
  ReachabilityTarget('8.8.8.8', 443),
  ReachabilityTarget('9.9.9.9', 443),
];

List<ReachabilityTarget> reachabilityTargets() {
  final configured = const String.fromEnvironment('REACHABILITY_HOSTS');
  if (configured.trim().isNotEmpty) {
    return [
      for (final part in configured.split(','))
        if (_target(part.trim()) != null) _target(part.trim())!,
    ];
  }
  return publicReachabilityTargets;
}

/// Chen Guang API host. Used only for backend availability, never for internet.
ReachabilityTarget? apiHostTarget() {
  final uri = Uri.tryParse(ApiEndpoints.baseUrl);
  if (uri == null || uri.host.isEmpty) return null;
  final port = uri.hasPort
      ? uri.port
      : uri.scheme == 'https'
          ? 443
          : 80;
  return ReachabilityTarget(uri.host, port);
}

ReachabilityTarget? _target(String value) {
  if (value.isEmpty) return null;
  final uri = Uri.tryParse(value.contains('://') ? value : 'tcp://$value');
  if (uri == null || uri.host.isEmpty) return null;
  final port = uri.hasPort ? uri.port : 443;
  return ReachabilityTarget(uri.host, port);
}

class SocketInternetReachability implements InternetReachability {
  SocketInternetReachability({
    required this.targets,
    this.timeout = const Duration(seconds: 4),
    SocketConnector? connector,
  }) : _connector = connector ?? connectSocket;

  final List<ReachabilityTarget> targets;
  final Duration timeout;
  final SocketConnector _connector;

  /// Returns as soon as any public target accepts or refuses the socket.
  /// Offline only after every target has failed.
  @override
  Future<Reachability> check() async {
    if (targets.isEmpty) return Reachability.noInternet;
    final pending = Completer<Reachability>();
    var remaining = targets.length;
    for (final target in targets) {
      unawaited(() async {
        final path = await _probe(target);
        if (pending.isCompleted) return;
        if (path == SocketPath.reachable) {
          pending.complete(Reachability.internet);
          return;
        }
        remaining--;
        if (remaining == 0) pending.complete(Reachability.noInternet);
      }());
    }
    return pending.future;
  }

  Future<SocketPath> _probe(ReachabilityTarget target) async {
    try {
      final socket = await _connector(target.host, target.port, timeout);
      await socket.close();
      return SocketPath.reachable;
    } on SocketException catch (error) {
      return classifySocketException(error);
    } on TimeoutException {
      return SocketPath.unknown;
    }
  }
}
