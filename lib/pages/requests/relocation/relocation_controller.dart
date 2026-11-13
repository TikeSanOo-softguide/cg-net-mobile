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
  String? _lastFetchAccount;
  bool _hasFetchedAccount = false;

  Future<void> fetchRequestsForAccount(String? accountNumber) async {
    final normalizedAccount = accountNumber?.trim().toUpperCase() ?? '';
    if (_hasFetchedAccount &&
        _lastFetchAccount == normalizedAccount &&
        (state.status == RelocationStatus.loading ||
            state.status == RelocationStatus.success)) {
      return;
    }

    final accountChanged =
        !_hasFetchedAccount || _lastFetchAccount != normalizedAccount;
    _hasFetchedAccount = true;
    _lastFetchAccount = normalizedAccount;
    await _fetchRequests(
      accountNumber,
      clearPrevious: accountChanged,
    );
  }

  Future<void> fetchRequests([String? accountNumber]) async {
    final normalizedAccount = accountNumber?.trim().toUpperCase();
    final accountChanged = normalizedAccount != null &&
        (!_hasFetchedAccount || _lastFetchAccount != normalizedAccount);
    if (normalizedAccount != null) {
      _hasFetchedAccount = true;
      _lastFetchAccount = normalizedAccount;
    }
    await _fetchRequests(
      accountNumber,
      clearPrevious: accountChanged,
    );
  }

  Future<void> _fetchRequests(
    String? accountNumber, {
    bool clearPrevious = false,
  }) async {
    final sequence = ++_fetchSequence;
    state = state.copyWith(
      status: RelocationStatus.loading,
      requests: clearPrevious ? const [] : null,
      clearError: true,
    );
    try {
      final items = await _repository.fetchRequests();
      if (sequence != _fetchSequence) return;

      final normalizedAccount = accountNumber?.trim().toUpperCase();
      final requests = items.where((request) {
        final requestAccount =
            request.broadbandAccountNumber?.trim().toUpperCase();
        if (requestAccount == null || requestAccount.isEmpty) return true;
        return normalizedAccount != null &&
            normalizedAccount.isNotEmpty &&
            requestAccount == normalizedAccount;
      }).toList();

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
      await fetchRequests(request.broadbandAccountNumber);
      return result;
    } catch (_) {
      state = state.copyWith(
        isSubmitting: false,
        clearError: true,
      );
      rethrow;
    }
  }

  Future<String?> cancelRequest(String requestId) async {
    state = state.copyWith(clearError: true);
    try {
      final requestIndex =
          state.requests.indexWhere((item) => item.id == requestId);
      final request = requestIndex == -1 ? null : state.requests[requestIndex];

      final code = await _repository.cancelRequest(requestId);
      await fetchRequests(request?.broadbandAccountNumber);
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
