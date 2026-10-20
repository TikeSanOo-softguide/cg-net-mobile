import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../data/requests/relocation/relocation_repository.dart';
import '../../../models/requests/relocation/relocation_request_model.dart';

enum RelocationStatus { initial, loading, success, error }

class RelocationState {
  const RelocationState({
    this.status = RelocationStatus.initial,
    this.requests = const [],
    this.errorMessage,
    this.isSubmitting = false,
  });

  final RelocationStatus status;
  final List<RelocationRequestModel> requests;
  final String? errorMessage;
  final bool isSubmitting;

  RelocationState copyWith({
    RelocationStatus? status,
    List<RelocationRequestModel>? requests,
    String? errorMessage,
    bool clearError = false,
    bool? isSubmitting,
  }) {
    return RelocationState(
      status: status ?? this.status,
      requests: requests ?? this.requests,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

class RelocationController extends StateNotifier<RelocationState> {
  RelocationController(this._repository) : super(const RelocationState());

  final RelocationRepository _repository;

  Future<void> fetchRequests() async {
    state = state.copyWith(
      status: RelocationStatus.loading,
      clearError: true,
    );
    try {
      final requests = await _repository.fetchRequests();
      state = state.copyWith(
        status: RelocationStatus.success,
        requests: requests,
        clearError: true,
      );
    } on ApiException catch (error) {
      state = state.copyWith(
        status: RelocationStatus.error,
        errorMessage: error.detail ?? error.messageKey,
      );
    } catch (error) {
      state = state.copyWith(
        status: RelocationStatus.error,
        errorMessage: error.toString(),
      );
    }
  }

  Future<RelocationRequestModel?> saveRequest(
    RelocationRequestModel request,
  ) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final savedRequest = request.id.isEmpty
          ? await _repository.createRequest(request)
          : await _repository.updateRequest(request);
      state = state.copyWith(isSubmitting: false, clearError: true);
      await fetchRequests();
      return savedRequest;
    } on ApiException catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: error.detail ?? error.messageKey,
      );
      return null;
    } catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: error.toString(),
      );
      return null;
    }
  }

  Future<bool> cancelRequest(String requestId) async {
    return _runMutation(() => _repository.cancelRequest(requestId));
  }

  Future<bool> _runMutation(Future<void> Function() mutation) async {
    state = state.copyWith(clearError: true);
    try {
      await mutation();
      await fetchRequests();
      return true;
    } on ApiException catch (error) {
      state = state.copyWith(errorMessage: error.detail ?? error.messageKey);
      return false;
    } catch (error) {
      state = state.copyWith(errorMessage: error.toString());
      return false;
    }
  }
}

final relocationControllerProvider =
    StateNotifierProvider<RelocationController, RelocationState>((ref) {
  return RelocationController(ref.watch(relocationRepositoryProvider));
});
