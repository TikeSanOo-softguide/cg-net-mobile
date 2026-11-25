/// Whether the device can reach the public internet.
enum NetworkStatus {
  checking,
  online,
  offline,
}

/// Whether the CG-NET API host itself can accept a connection.
enum BackendStatus {
  unknown,
  available,
  unavailable,
}

/// Latest internet status for code that does not have a Riverpod [Ref].
class NetworkStatusSnapshot {
  NetworkStatusSnapshot._();

  static NetworkStatus current = NetworkStatus.checking;

  static void update(NetworkStatus status) {
    current = status;
  }
}

/// Latest API-host status. Unknown while the internet status is offline.
class BackendStatusSnapshot {
  BackendStatusSnapshot._();

  static BackendStatus current = BackendStatus.unknown;

  static void update(BackendStatus status) {
    current = status;
  }
}
