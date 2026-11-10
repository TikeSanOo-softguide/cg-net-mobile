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
  int _fetchSequence = 0;

  Future<void> fetchRequests() async {
    final sequence = ++_fetchSequence;
    state = state.copyWith(
      status: RelocationStatus.loading,
      requests: const [],
      clearError: true,
    );
    try {
      final requests = await _repository.fetchRequests();
      if (sequence != _fetchSequence) return;
      state = state.copyWith(
        status: RelocationStatus.success,
        requests: requests,
        clearError: true,
      );
    } on ApiException catch (error) {
      if (sequence != _fetchSequence) return;
      state = state.copyWith(
        status: RelocationStatus.error,
        errorMessage: error.detail ?? error.messageKey,
      );
    } catch (error) {
      if (sequence != _fetchSequence) return;
      state = state.copyWith(
        status: RelocationStatus.error,
        errorMessage: error.toString(),
      );
    }
  }

  Future<RelocationSaveResult?> saveRequest(
    RelocationRequestModel request,
  ) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final result = request.id.isEmpty
          ? await _repository.createRequest(request)
          : await _repository.updateRequest(request);
      state = state.copyWith(isSubmitting: false, clearError: true);
      await fetchRequests();
      return result;
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

final relocationControllerProvider =
    StateNotifierProvider<RelocationController, RelocationState>((ref) {
  return RelocationController(ref.watch(relocationRepositoryProvider));
});
