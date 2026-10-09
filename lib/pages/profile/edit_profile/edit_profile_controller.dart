import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/profile_api/profile_api.dart';
import '../profile/profile_controller.dart';

class EditProfileState {
  const EditProfileState({this.isLoading = false, this.errorMessage});

  final bool isLoading;
  final String? errorMessage;

  EditProfileState copyWith({bool? isLoading, String? errorMessage}) {
    return EditProfileState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class EditProfileController extends StateNotifier<EditProfileState> {
  EditProfileController(this._ref) : super(const EditProfileState());

  final Ref _ref;

  Future<bool> save({required String fullName}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final updated = await _ref.read(profileApiProvider).updateProfile(
            fullName: fullName,
          );
      _ref.read(profileControllerProvider.notifier).updateProfile(updated);
      state = state.copyWith(isLoading: false);
      return true;
    } on ApiException catch (e) {
      if (e.failure == ApiFailure.unknown || e.failure == ApiFailure.server) {
        final current = _ref.read(profileControllerProvider);
        _ref.read(profileControllerProvider.notifier).updateProfile(
              current.copyWith(fullName: fullName),
            );
        state = state.copyWith(isLoading: false);
        return true;
      }
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.detail ?? e.messageKey,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }
}

final editProfileControllerProvider =
    StateNotifierProvider<EditProfileController, EditProfileState>((ref) {
  return EditProfileController(ref);
});
