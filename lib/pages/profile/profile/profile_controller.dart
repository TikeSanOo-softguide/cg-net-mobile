import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/auth_api/auth_api.dart';
import '../../../core/push/push_notification_service.dart';
import '../../../core/storage/secure_storage/secure_storage.dart';
import '../../../data/profile/profile_repository.dart';
import '../../../models/user_model/user_model.dart';

final profileHeaderLoadingProvider = StateProvider<bool>((ref) => false);

class ProfileController extends StateNotifier<UserProfileModel> {
  ProfileController({
    required Ref ref,
    required SecureStorage secureStorage,
    required PushNotificationService push,
    required ProfileRepository profileRepository,
    required AuthApi authApi,
  })  : _ref = ref,
        _secureStorage = secureStorage,
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
    _restoreCachedProfile();
  }

  final Ref _ref;
  final SecureStorage _secureStorage;
  final PushNotificationService _push;
  final ProfileRepository _profileRepository;
  final AuthApi _authApi;
  int _fetchSeq = 0;

  static bool _hasIdentity(UserProfileModel profile) {
    return profile.fullName.isNotEmpty ||
        profile.phone.isNotEmpty ||
        profile.accountNumber.isNotEmpty;
  }

  Future<void> _restoreCachedProfile() async {
    try {
      final cachedProfile = await _profileRepository.readCachedProfile();
      if (cachedProfile != null && !_hasIdentity(state)) {
        state = cachedProfile;
      }
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'profile controller',
          context: ErrorDescription('while restoring the cached profile'),
        ),
      );
    }

    await fetchProfile();
  }

  Future<void> fetchProfile() async {
    final seq = ++_fetchSeq;
    final firstLoad = !_hasIdentity(state);
    if (firstLoad) {
      Future.microtask(() {
        if (!mounted) return;
        _ref.read(profileHeaderLoadingProvider.notifier).state = true;
      });
    }
    try {
      final user = await _profileRepository.fetchProfile();
      if (seq != _fetchSeq) return;
      state = user;
    } catch (_) {
      // Best-effort fetch; keep existing state on network error.
    } finally {
      if (seq == _fetchSeq) {
        Future.microtask(() {
          if (!mounted) return;
          _ref.read(profileHeaderLoadingProvider.notifier).state = false;
        });
      }
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
    ref: ref,
    secureStorage: ref.watch(secureStorageProvider),
    push: ref.watch(pushNotificationServiceProvider),
    profileRepository: ref.watch(profileRepositoryProvider),
    authApi: ref.watch(authApiProvider),
  );
});
