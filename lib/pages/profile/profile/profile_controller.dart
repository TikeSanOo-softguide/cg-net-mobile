import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/secure_storage/secure_storage.dart';
import '../../../models/user_model/user_model.dart';

class ProfileController extends StateNotifier<UserProfileModel> {
  ProfileController(this._secureStorage)
      : super(
          const UserProfileModel(
            id: 'u1',
            fullName: 'CG Net Customer',
            phone: '+959123456789',
            email: 'customer@example.com',
            username: 'cguser',
          ),
        );

  final SecureStorage _secureStorage;

  void updateProfile(UserProfileModel profile) {
    state = profile;
  }

  Future<void> logout() async {
    await _secureStorage.clearToken();
  }
}

final profileControllerProvider =
    StateNotifierProvider<ProfileController, UserProfileModel>((ref) {
  return ProfileController(ref.watch(secureStorageProvider));
});
