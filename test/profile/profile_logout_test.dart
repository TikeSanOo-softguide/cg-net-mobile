import 'package:cg_net_mobile/core/network/api_exception.dart';
import 'package:cg_net_mobile/core/network/auth_api/auth_api.dart';
import 'package:cg_net_mobile/core/push/push_notification_service.dart';
import 'package:cg_net_mobile/core/storage/secure_storage/secure_storage.dart';
import 'package:cg_net_mobile/data/profile/profile_repository.dart';
import 'package:cg_net_mobile/models/user_model/user_model.dart';
import 'package:cg_net_mobile/pages/home/home/bound_broadband.dart';
import 'package:cg_net_mobile/pages/home/home/bound_broadband_provider.dart';
import 'package:cg_net_mobile/pages/profile/profile/profile_controller.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _TestSecureStorage implements SecureStorage {
  int clearTokenCalls = 0;

  @override
  Future<String?> readCachedProfile() async => null;

  @override
  Future<void> clearToken() async {
    clearTokenCalls++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestAuthApi extends AuthApi {
  _TestAuthApi(this.error) : super(Dio(), () => 'en');

  final Object? error;

  @override
  Future<void> logout() async {
    if (error != null) throw error!;
  }
}

class _TestPushNotificationService implements PushNotificationService {
  int unregisterCalls = 0;

  @override
  Future<void> unregister() async {
    unregisterCalls++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestProfileRepository implements ProfileRepository {
  @override
  Future<UserProfileModel?> readCachedProfile() async => null;

  @override
  Future<UserProfileModel> fetchProfile() async {
    throw const ApiException(ApiFailure.offline);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('keeps the local session when the logout API fails', () async {
    const error = ApiException(ApiFailure.server);
    final storage = _TestSecureStorage();
    final push = _TestPushNotificationService();
    final container = ProviderContainer(
      overrides: [
        secureStorageProvider.overrideWithValue(storage),
        authApiProvider.overrideWithValue(_TestAuthApi(error)),
        pushNotificationServiceProvider.overrideWithValue(push),
        profileRepositoryProvider.overrideWithValue(_TestProfileRepository()),
      ],
    );
    addTearDown(container.dispose);

    final controller = container.read(profileControllerProvider.notifier)
      ..updateProfile(
        const UserProfileModel(
          id: '1',
          fullName: 'Test User',
          phone: '123',
          accountNumber: '456',
          username: 'test',
        ),
      );

    await expectLater(controller.logout(), throwsA(same(error)));

    expect(storage.clearTokenCalls, 0);
    expect(push.unregisterCalls, 0);
    expect(container.read(profileControllerProvider).fullName, 'Test User');
  });

  test('clears the local session after the logout API succeeds', () async {
    final storage = _TestSecureStorage();
    final push = _TestPushNotificationService();
    final container = ProviderContainer(
      overrides: [
        secureStorageProvider.overrideWithValue(storage),
        authApiProvider.overrideWithValue(_TestAuthApi(null)),
        pushNotificationServiceProvider.overrideWithValue(push),
        profileRepositoryProvider.overrideWithValue(_TestProfileRepository()),
      ],
    );
    addTearDown(container.dispose);

    final controller = container.read(profileControllerProvider.notifier)
      ..updateProfile(
        const UserProfileModel(
          id: '1',
          fullName: 'Test User',
          phone: '123',
          accountNumber: '456',
          username: 'test',
        ),
      );
    container.read(boundBroadbandProvider.notifier).state = const BoundBroadband(
      account: '456',
      serviceType: 'CG',
    );

    await controller.logout();

    expect(storage.clearTokenCalls, 1);
    expect(push.unregisterCalls, 1);
    expect(container.read(profileControllerProvider).fullName, isEmpty);
    expect(container.read(boundBroadbandProvider), isNull);
  });
}
