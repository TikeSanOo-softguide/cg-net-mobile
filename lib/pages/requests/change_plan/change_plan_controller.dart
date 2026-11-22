import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/offline_navigation.dart';
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
  String? _lastFetchAccount;
  bool _hasFetchedAccount = false;

  Future<void> fetchRequests({String? accountNumber}) async {
    final sequence = ++_fetchSequence;
    final accountKey = _accountKey(accountNumber);
    final accountChanged =
        _hasFetchedAccount && _lastFetchAccount != accountKey;
    _hasFetchedAccount = true;
    _lastFetchAccount = accountKey;
    final showLoading = accountChanged ||
        state.status == ChangePlanStatus.initial ||
        (state.status == ChangePlanStatus.error && state.requests.isEmpty);
    final cached = _repository.readCachedRequests();
    final cachedRequests =
        cached == null ? null : _forAccount(cached, accountNumber);
    if (showLoading && cachedRequests != null) {
      state = state.copyWith(
        status: ChangePlanStatus.success,
        requests: cachedRequests,
        clearError: true,
      );
    } else if (showLoading) {
      state = state.copyWith(
        status: ChangePlanStatus.loading,
        requests: accountChanged ? const [] : null,
        clearError: true,
      );
    }
    try {
      final items = await _repository.fetchRequests();
      if (sequence != _fetchSequence) return;
      final requests = _forAccount(items, accountNumber);
      state = state.copyWith(
        status: ChangePlanStatus.success,
        requests: requests,
        clearError: true,
      );
    } on ApiException catch (error) {
      if (sequence != _fetchSequence) return;
      state = state.copyWith(
        status: ChangePlanStatus.error,
        errorMessage: storedApiMessage(error),
      );
    } catch (error) {
      if (sequence != _fetchSequence) return;
      state = state.copyWith(
        status: ChangePlanStatus.error,
        errorMessage: error.toString(),
      );
    }
  }

  List<ChangePlanRequestModel> _forAccount(
    List<ChangePlanRequestModel> items,
    String? accountNumber,
  ) {
    final normalizedAccount = accountNumber?.trim().toUpperCase();
    if (normalizedAccount == null || normalizedAccount.isEmpty) return items;
    return items
        .where(
          (request) =>
              request.broadbandAccountNumber?.trim().toUpperCase() ==
              normalizedAccount,
        )
        .toList();
  }

  String? _accountKey(String? accountNumber) {
    final normalized = accountNumber?.trim().toUpperCase();
    if (normalized == null || normalized.isEmpty) return null;
    return normalized;
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
        errorMessage: storedApiMessage(error),
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
      state = state.copyWith(errorMessage: storedApiMessage(error));
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
