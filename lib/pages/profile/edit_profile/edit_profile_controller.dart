import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/user_model/user_model.dart';
import '../profile/profile_controller.dart';

class EditProfileController extends StateNotifier<bool> {
  EditProfileController(this._ref) : super(false);

  final Ref _ref;

  Future<void> save({required String fullName, required String email}) async {
    state = true;
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final current = _ref.read(profileControllerProvider);
    _ref.read(profileControllerProvider.notifier).updateProfile(
          UserProfileModel(
            id: current.id,
            fullName: fullName,
            phone: current.phone,
            email: email,
            username: current.username,
          ),
        );
    state = false;
  }
}

final editProfileControllerProvider =
    StateNotifierProvider<EditProfileController, bool>((ref) {
  return EditProfileController(ref);
});
