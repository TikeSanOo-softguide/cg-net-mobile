import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/auth_api/auth_api.dart';
import '../../../core/push/push_notification_service.dart';
import '../../../core/storage/secure_storage/secure_storage.dart';
import '../../../data/profile/profile_repository.dart';
import '../../../models/user_model/user_model.dart';

class ProfileController extends StateNotifier<UserProfileModel> {
  ProfileController({
    required SecureStorage secureStorage,
    required PushNotificationService push,
    required ProfileRepository profileRepository,
    required AuthApi authApi,
  })  : _secureStorage = secureStorage,
        _push = push,
        _profileRepository = profileRepository,
        _authApi = authApi,
        super(
          const UserProfileModel(
            id: '',
            fullName: '',
            phone: '',
            accountNumber: '',
            username: '',
          ),
        ) {
    fetchProfile();
  }

  final SecureStorage _secureStorage;
  final PushNotificationService _push;
  final ProfileRepository _profileRepository;
  final AuthApi _authApi;

  Future<void> fetchProfile() async {
    try {
      final user = await _profileRepository.fetchProfile();
      state = user;
    } catch (_) {
      // Best-effort fetch; keep existing state on network error.
    }
  }

  void updateProfile(UserProfileModel profile) {
    state = profile;
  }

  void clearProfile() {
    state = const UserProfileModel(
      id: '',
      fullName: '',
      phone: '',
      accountNumber: '',
      username: '',
    );
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
    clearProfile();
  }
}

final profileControllerProvider =
    StateNotifierProvider<ProfileController, UserProfileModel>((ref) {
  return ProfileController(
    secureStorage: ref.watch(secureStorageProvider),
    push: ref.watch(pushNotificationServiceProvider),
    profileRepository: ref.watch(profileRepositoryProvider),
    authApi: ref.watch(authApiProvider),
  );
});
