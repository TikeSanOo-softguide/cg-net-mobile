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
  int _fetchSequence = 0;

  Future<void> fetchRequests({String? accountNumber}) async {
    final sequence = ++_fetchSequence;
    state = state.copyWith(
      status: ChangePlanStatus.loading,
      clearError: true,
    );
    try {
      final items = await _repository.fetchRequests();
      if (sequence != _fetchSequence) return;
      final normalizedAccount = accountNumber?.trim().toUpperCase();
      final requests = normalizedAccount == null || normalizedAccount.isEmpty
          ? items
          : items
              .where(
                (request) =>
                    request.broadbandAccountNumber?.trim().toUpperCase() ==
                    normalizedAccount,
              )
              .toList();
      state = state.copyWith(
        status: ChangePlanStatus.success,
        requests: requests,
        clearError: true,
      );
    } on ApiException catch (error) {
      if (sequence != _fetchSequence) return;
      state = state.copyWith(
        status: ChangePlanStatus.error,
        errorMessage: error.detail ?? error.messageKey,
      );
    } catch (error) {
      if (sequence != _fetchSequence) return;
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
      final requests = [...state.requests];
      final savedIndex = requests.indexWhere(
        (item) => item.id.isNotEmpty && item.id == saved.request.id,
      );
      if (savedIndex == -1) {
        requests.insert(0, saved.request);
      } else {
        requests[savedIndex] = saved.request;
      }
      state = state.copyWith(
        isSubmitting: false,
        requests: requests,
        clearError: true,
      );
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
    final requestIndex =
        state.requests.indexWhere((item) => item.id == requestId);
    final request =
        requestIndex == -1 ? null : state.requests[requestIndex];
    try {
      final code = await _repository.cancelRequest(requestId);
      await fetchRequests(
        accountNumber: request?.broadbandAccountNumber,
      );
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
