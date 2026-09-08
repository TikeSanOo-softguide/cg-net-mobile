import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChangePasswordController extends StateNotifier<bool> {
  ChangePasswordController() : super(false);

  Future<void> submit() async {
    state = true;
    await Future<void>.delayed(const Duration(milliseconds: 600));
    state = false;
  }
}

final changePasswordControllerProvider =
    StateNotifierProvider<ChangePasswordController, bool>((ref) {
  return ChangePasswordController();
});
