import 'dart:async';

import 'package:cg_net_mobile/core/storage/secure_storage/secure_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemorySecureStorage extends FlutterSecureStorage {
  final values = <String, String>{};
  final secondTokenReadStarted = Completer<void>();
  final releaseSecondTokenRead = Completer<void>();
  int tokenReads = 0;

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (key == 'auth_token') {
      tokenReads++;
      if (tokenReads == 2) {
        secondTokenReadStarted.complete();
        await releaseSecondTokenRead.future;
      }
    }
    return values[key];
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      values.remove(key);
    } else {
      values[key] = value;
    }
  }

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    values.remove(key);
  }
}

void main() {
  test('a new login token survives an overlapping stale-token clear', () async {
    final backend = _MemorySecureStorage()..values['auth_token'] = 'old-token';
    final storage = SecureStorage(storage: backend);

    final clearFuture = storage.clearTokenIfMatches('old-token');
    await backend.secondTokenReadStarted.future;

    var writeCompleted = false;
    final writeFuture = storage.writeToken('new-token').then((_) {
      writeCompleted = true;
    });
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(writeCompleted, isFalse);
    backend.releaseSecondTokenRead.complete();
    await Future.wait([clearFuture, writeFuture]);

    expect(await storage.readToken(), 'new-token');
  });
}
