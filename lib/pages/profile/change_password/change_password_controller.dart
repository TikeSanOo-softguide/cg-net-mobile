import 'package:cg_net_mobile/core/network/dio_client/dio_client.dart';
import 'package:cg_net_mobile/data/change_password/change_password_repository.dart';
import 'package:cg_net_mobile/models/change_password_model/change_password_model.dart';
import 'package:cg_net_mobile/models/change_password_model/change_password_otp_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChangePasswordController extends StateNotifier<bool> {
  ChangePasswordController(this._repository) : super(false);

  final ChangePasswordRepository _repository;

  Future<ChangePasswordChallenge> changePassword({
    required ChangePasswordModel password,
  }) async {
    state = true;
    try {
      return await _repository.changePassword(password: password);
    } finally {
      state = false;
    }
  }

  Future<void> verifyOtp({
    required String challengeId,
    required String otp,
  }) async {
    state = true;
    try {
      await _repository.verifyOtp(challengeId: challengeId, otp: otp);
    } finally {
      state = false;
    }
  }
}

final changePasswordRepositoryProvider =
    Provider<ChangePasswordRepository>((ref) {
  return ChangePasswordRepository(
    ref.read(dioProvider),
  );
});

final changePasswordControllerProvider =
    StateNotifierProvider<ChangePasswordController, bool>((ref) {
  return ChangePasswordController(
    ref.read(changePasswordRepositoryProvider),
  );
});
