import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/auth_api/auth_api.dart';
import '../../../core/push/push_notification_service.dart';
import '../../../core/storage/secure_storage/secure_storage.dart';
import '../../../models/user_model/user_model.dart';

class ProfileController extends StateNotifier<UserProfileModel> {
  ProfileController(this._secureStorage, this._push, this._authApi)
      : super(
          const UserProfileModel(
            id: 'u1',
            fullName: 'CG Net Customer',
            phone: '+959123456789',
            accountNumber: '09970071489',
            email: 'customer@example.com',
            username: 'cguser',
          ),
        );

  final SecureStorage _secureStorage;
  final PushNotificationService _push;
  final AuthApi _authApi;

  void updateProfile(UserProfileModel profile) {
    state = profile;
  }

  Future<void> logout() async {
    try {
      await _authApi.logout();
    } catch (_) {
      // Best-effort revoke; local session cleanup must still continue.
    }
    try {
      await _push.unregister();
    } catch (_) {
      // Push token cleanup is non-blocking for user logout.
    }
    await _secureStorage.clearToken();
  }
}

final profileControllerProvider =
    StateNotifierProvider<ProfileController, UserProfileModel>((ref) {
  return ProfileController(
    ref.watch(secureStorageProvider),
    ref.watch(pushNotificationServiceProvider),
    ref.watch(authApiProvider),
  );
});
