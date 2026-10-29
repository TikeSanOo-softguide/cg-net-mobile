import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/deactivate_account/deactivate_account_repository.dart';

class DeactivateAccountController extends StateNotifier<bool> {
  DeactivateAccountController(this._repository) : super(false);

  final DeactivateAccountRepository _repository;

  Future<String?> deactivate({required String password}) async {
    state = true;
    try {
      return await _repository.deactivate(password: password);
    } finally {
      state = false;
    }
  }
}

final deactivateAccountControllerProvider =
    StateNotifierProvider<DeactivateAccountController, bool>((ref) {
  return DeactivateAccountController(
    ref.watch(deactivateAccountRepositoryProvider),
  );
});
