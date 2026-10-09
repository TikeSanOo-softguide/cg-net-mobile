import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/idempotency_key.dart';
import '../../../data/top_up/top_up_repository.dart';

class TopUpState {
  const TopUpState({
    this.isSubmitting = false,
  });

  final bool isSubmitting;

  TopUpState copyWith({
    bool? isSubmitting,
  }) {
    return TopUpState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

class TopUpController extends StateNotifier<TopUpState> {
  TopUpController(this._repository) : super(const TopUpState());

  final TopUpRepository _repository;
  String? _pendingIdempotencyKey;
  String? _pendingPhone;
  String? _pendingPin;

  Future<TopUpSerialCheckResult> checkSerialNo(String serialNo) async {
    return await _repository.checkSerialNo(serialNo);
  }

  Future<TopUpAccountResult?> submit({
    required String phone,
    required String pin,
  }) async {
    if (state.isSubmitting) return null;

    if (_pendingIdempotencyKey == null ||
        _pendingPhone != phone ||
        _pendingPin != pin) {
      _pendingIdempotencyKey = IdempotencyKey.generate();
      _pendingPhone = phone;
      _pendingPin = pin;
    }

    state = state.copyWith(isSubmitting: true);
    try {
      final result = await _repository.topUpAccount(
        phone: phone,
        pin: pin,
        idempotencyKey: _pendingIdempotencyKey!,
      );
      _clearPendingRequest();
      return result;
    } on ApiException catch (error) {
      if (error.statusCode != null && error.statusCode! < 500) {
        _clearPendingRequest();
      }
      rethrow;
    } finally {
      if (mounted) {
        state = state.copyWith(isSubmitting: false);
      }
    }
  }

  void _clearPendingRequest() {
    _pendingIdempotencyKey = null;
    _pendingPhone = null;
    _pendingPin = null;
  }
}

final topUpControllerProvider =
    StateNotifierProvider.autoDispose<TopUpController, TopUpState>((ref) {
  return TopUpController(ref.watch(topUpRepositoryProvider));
});
