import 'package:cg_net_mobile/core/utils/device_id_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('returns and caches the Android device ID', () async {
    var reads = 0;
    final service = DeviceIdService(
      isAndroid: true,
      androidIdReader: () async {
        reads++;
        return 'hardware-id';
      },
    );

    final first = await service.getDeviceId();
    final second = await service.getDeviceId();

    expect(first, 'android:hardware-id');
    expect(second, first);
    expect(reads, 1);
  });

  test('keeps the Android ID stable across service instances', () async {
    final firstService = DeviceIdService(
      isAndroid: true,
      androidIdReader: () async => 'hardware-id',
    );
    final secondService = DeviceIdService(
      isAndroid: true,
      androidIdReader: () async => 'hardware-id',
    );

    expect(await firstService.getDeviceId(), 'android:hardware-id');
    expect(await secondService.getDeviceId(), 'android:hardware-id');
  });

  test('freezes the first Android ID in secure storage', () async {
    final storage = _MemorySecureStorage({});
    final firstService = DeviceIdService(
      storage: storage,
      isAndroid: true,
      androidIdReader: () async => 'hardware-id',
    );
    final secondService = DeviceIdService(
      storage: storage,
      isAndroid: true,
      androidIdReader: () async => 'different-id',
    );

    expect(await firstService.getDeviceId(), 'android:hardware-id');
    expect(await secondService.getDeviceId(), 'android:hardware-id');
    expect(storage.values['auth_device_id'], 'android:hardware-id');
  });

  test('recreates the same Android ID after secure storage is cleared',
      () async {
    final storage = _MemorySecureStorage({});
    final firstService = DeviceIdService(
      storage: storage,
      isAndroid: true,
      androidIdReader: () async => 'hardware-id',
    );
    final firstId = await firstService.getDeviceId();
    storage.values.clear();
    final secondService = DeviceIdService(
      storage: storage,
      isAndroid: true,
      androidIdReader: () async => 'hardware-id',
    );

    expect(firstId, 'android:hardware-id');
    expect(await secondService.getDeviceId(), firstId);
  });

  test('prefers Android ID to a stored fallback UUID', () async {
    final storage = _MemorySecureStorage({
      'auth_device_uuid': 'old-fallback-id',
    });
    final service = DeviceIdService(
      storage: storage,
      isAndroid: true,
      androidIdReader: () async => 'hardware-id',
    );

    expect(await service.getDeviceId(), 'android:hardware-id');
  });

  test('persists and reuses the UUID when Android ID is unavailable', () async {
    final storage = _MemorySecureStorage({});
    final firstService = DeviceIdService(
      storage: storage,
      isAndroid: true,
      androidIdReader: () async => null,
      uuidGenerator: () => 'fallback-id',
    );
    final secondService = DeviceIdService(
      storage: storage,
      isAndroid: true,
      androidIdReader: () async => null,
      uuidGenerator: () => 'different-id',
    );

    expect(await firstService.getDeviceId(), 'ios:fallback-id');
    expect(await secondService.getDeviceId(), 'ios:fallback-id');
  });
}

class _MemorySecureStorage extends FlutterSecureStorage {
  _MemorySecureStorage(this.values);

  final Map<String, String> values;

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
}
