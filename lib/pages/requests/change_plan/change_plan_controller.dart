import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../data/requests/change_plan/change_plan_repository.dart';
import '../../../models/requests/change_plan/change_plan_request_model.dart';

enum ChangePlanStatus { initial, loading, success, error }

class ChangePlanState {
  const ChangePlanState({
    this.status = ChangePlanStatus.initial,
    this.requests = const [],
    this.errorMessage,
    this.isSubmitting = false,
  });

  final ChangePlanStatus status;
  final List<ChangePlanRequestModel> requests;
  final String? errorMessage;
  final bool isSubmitting;

  ChangePlanState copyWith({
    ChangePlanStatus? status,
    List<ChangePlanRequestModel>? requests,
    String? errorMessage,
    bool clearError = false,
    bool? isSubmitting,
  }) {
    return ChangePlanState(
      status: status ?? this.status,
      requests: requests ?? this.requests,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

class ChangePlanController extends StateNotifier<ChangePlanState> {
  ChangePlanController(this._repository) : super(const ChangePlanState());

  final ChangePlanRepository _repository;

  Future<void> fetchRequests() async {
    state = state.copyWith(status: ChangePlanStatus.loading, clearError: true);
    try {
      final requests = await _repository.fetchRequests();
      state = state.copyWith(
        status: ChangePlanStatus.success,
        requests: requests,
        clearError: true,
      );
    } on ApiException catch (error) {
      state = state.copyWith(
        status: ChangePlanStatus.error,
        errorMessage: error.detail ?? error.messageKey,
      );
    } catch (error) {
      state = state.copyWith(
        status: ChangePlanStatus.error,
        errorMessage: error.toString(),
      );
    }
  }

  Future<ChangePlanSaveResult> saveRequest(
    ChangePlanRequestModel request,
  ) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final saved = request.id.isEmpty
          ? await _repository.createRequest(request)
          : await _repository.updateRequest(request);
      state = state.copyWith(isSubmitting: false, clearError: true);
      await fetchRequests();
      return saved;
    } on ApiException catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: error.detail ?? error.messageKey,
      );
      rethrow;
    } catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: error.toString(),
      );
      rethrow;
    }
  }

  Future<String?> cancelRequest(String requestId) async {
    state = state.copyWith(clearError: true);
    try {
      final code = await _repository.cancelRequest(requestId);
      await fetchRequests();
      return code;
    } on ApiException catch (error) {
      state = state.copyWith(errorMessage: error.detail ?? error.messageKey);
      return null;
    } catch (error) {
      state = state.copyWith(errorMessage: error.toString());
      return null;
    }
  }
}

final changePlanControllerProvider =
    StateNotifierProvider<ChangePlanController, ChangePlanState>((ref) {
  return ChangePlanController(ref.watch(changePlanRepositoryProvider));
});
