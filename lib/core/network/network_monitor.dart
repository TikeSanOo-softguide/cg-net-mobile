import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'backend_probe.dart';
import 'internet_reachability.dart';
import 'network_recovery_controller.dart';
import 'network_status.dart';
import 'server_availability.dart';

abstract class NetworkLinks {
  Stream<List<ConnectivityResult>> get changes;

  Future<List<ConnectivityResult>> current();
}

class PluginNetworkLinks implements NetworkLinks {
  PluginNetworkLinks([Connectivity? connectivity])
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  @override
  Stream<List<ConnectivityResult>> get changes =>
      _connectivity.onConnectivityChanged;

  @override
  Future<List<ConnectivityResult>> current() =>
      _connectivity.checkConnectivity();
}

bool isNetworkDisconnected(List<ConnectivityResult> results) {
  return results.isEmpty ||
      results.every((result) => result == ConnectivityResult.none);
}

class NetworkMonitor extends StateNotifier<NetworkStatus> {
  NetworkMonitor({
    required NetworkLinks links,
    required InternetReachability reachability,
    BackendProbe? backend,
    this.onRecovered,
    this.debounce = const Duration(milliseconds: 300),
  })  : _links = links,
        _reachability = reachability,
        _backend = backend ?? const InactiveBackendProbe(),
        super(NetworkStatus.checking) {
    NetworkStatusSnapshot.update(NetworkStatus.checking);
    BackendStatusSnapshot.update(BackendStatus.unknown);
  }

  final NetworkLinks _links;
  final InternetReachability _reachability;
  final BackendProbe _backend;
  final void Function()? onRecovered;
  final Duration debounce;

  BackendStatus backendStatus = BackendStatus.unknown;

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _debounceTimer;
  int _generation = 0;
  bool _started = false;
  bool _disposed = false;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    _subscription = _links.changes.listen(_onLinks);
    await _apply(_links.current());
  }

  /// Probe again after the app returns to the foreground.
  Future<void> recheck() => _apply(_links.current());

  void _onLinks(List<ConnectivityResult> results) {
    _debounceTimer?.cancel();
    if (isNetworkDisconnected(results)) {
      unawaited(_apply(Future.value(results)));
      return;
    }
    _debounceTimer = Timer(debounce, () {
      unawaited(_apply(Future.value(results)));
    });
  }

  Future<void> _apply(Future<List<ConnectivityResult>> pending) async {
    final generation = ++_generation;
    final results = await pending;
    if (generation != _generation) return;
    if (isNetworkDisconnected(results)) {
      _emit(NetworkStatus.offline);
      _setBackend(BackendStatus.unknown);
      return;
    }
    final reachability = await _reachability.check();
    if (generation != _generation) return;
    if (reachability != Reachability.internet) {
      _emit(NetworkStatus.offline);
      _setBackend(BackendStatus.unknown);
      return;
    }
    _emit(NetworkStatus.online);
    final backend = await _backend.check();
    if (generation != _generation) return;
    _setBackend(backend);
  }

  void _setBackend(BackendStatus next) {
    final previous = BackendStatusSnapshot.current;
    backendStatus = next;
    if (previous == next) return;
    BackendStatusSnapshot.update(next);
    if (next == BackendStatus.unavailable) {
      GlobalServerNotice.showDown();
    } else if (previous == BackendStatus.unavailable &&
        next == BackendStatus.available) {
      GlobalServerNotice.showRestored();
    }
  }

  void _emit(NetworkStatus next) {
    if (state == next) return;
    final previous = state;
    state = next;
    NetworkStatusSnapshot.update(next);
    if (previous == NetworkStatus.offline && next == NetworkStatus.online) {
      onRecovered?.call();
    }
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _generation++;
    _debounceTimer?.cancel();
    _subscription?.cancel();
    super.dispose();
  }
}

final networkMonitorProvider =
    StateNotifierProvider<NetworkMonitor, NetworkStatus>((ref) {
  final monitor = NetworkMonitor(
    links: PluginNetworkLinks(),
    reachability: SocketInternetReachability(
      targets: reachabilityTargets(),
    ),
    backend: SocketBackendProbe(),
    onRecovered: () {
      ref.read(networkRecoveryControllerProvider).checkNow();
    },
  );
  ref.onDispose(monitor.dispose);
  unawaited(monitor.start());
  return monitor;
});
