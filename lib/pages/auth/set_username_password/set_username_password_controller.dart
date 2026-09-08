import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/secure_storage/secure_storage.dart';

class SetUsernamePasswordState {
  const SetUsernamePasswordState({this.isLoading = false});

  final bool isLoading;

  SetUsernamePasswordState copyWith({bool? isLoading}) {
    return SetUsernamePasswordState(isLoading: isLoading ?? this.isLoading);
  }
}

class SetUsernamePasswordController
    extends StateNotifier<SetUsernamePasswordState> {
  SetUsernamePasswordController(this._secureStorage)
      : super(const SetUsernamePasswordState());

  final SecureStorage _secureStorage;

  Future<bool> submit({
    required String username,
    required String password,
    required String phone,
  }) async {
    state = state.copyWith(isLoading: true);
    await Future<void>.delayed(const Duration(milliseconds: 800));
    // Scaffold: persist a mock token after credentials are set.
    await _secureStorage.writeToken('mock_token_${username}_$phone');
    state = state.copyWith(isLoading: false);
    return true;
  }
}

final setUsernamePasswordControllerProvider = StateNotifierProvider<
    SetUsernamePasswordController, SetUsernamePasswordState>((ref) {
  return SetUsernamePasswordController(ref.watch(secureStorageProvider));
});
