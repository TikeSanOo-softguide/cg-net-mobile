import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/offline_navigation.dart';
import '../../../data/requests/installation_application/installation_application_repository.dart';
import '../../../models/requests/installation_application/installation_application_model.dart';

enum InstallationApplicationStatus { initial, loading, success, error }

class InstallationApplicationState {
  const InstallationApplicationState({
    this.status = InstallationApplicationStatus.initial,
    this.requests = const [],
    this.errorMessage,
    this.isSubmitting = false,
  });

  final InstallationApplicationStatus status;
  final List<InstallationApplicationModel> requests;
  final String? errorMessage;
  final bool isSubmitting;

  InstallationApplicationState copyWith({
    InstallationApplicationStatus? status,
    List<InstallationApplicationModel>? requests,
    String? errorMessage,
    bool clearError = false,
    bool? isSubmitting,
  }) {
    return InstallationApplicationState(
      status: status ?? this.status,
      requests: requests ?? this.requests,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

class InstallationApplicationController
    extends StateNotifier<InstallationApplicationState> {
  InstallationApplicationController(this._repository)
      : super(const InstallationApplicationState());

  final InstallationApplicationRepository _repository;
  int _fetchSequence = 0;

  Future<InstallationApplicationOptions> fetchProducts(String serviceType) =>
      _repository.fetchProducts(serviceType);

  Future<void> fetchRequests() async {
    final sequence = ++_fetchSequence;
    final firstLoad = state.status == InstallationApplicationStatus.initial ||
        (state.status == InstallationApplicationStatus.error &&
            state.requests.isEmpty);
    final cached = _repository.readCachedRequests();
    if (firstLoad && cached != null) {
      state = state.copyWith(
        status: InstallationApplicationStatus.success,
        requests: cached,
        clearError: true,
      );
    } else if (firstLoad) {
      state = state.copyWith(
        status: InstallationApplicationStatus.loading,
        clearError: true,
      );
    }
    try {
      final requests = await _repository.fetchRequests();
      if (sequence != _fetchSequence) return;
      state = state.copyWith(
        status: InstallationApplicationStatus.success,
        requests: requests,
        clearError: true,
      );
    } on ApiException catch (error) {
      if (sequence != _fetchSequence) return;
      state = state.copyWith(
        status: InstallationApplicationStatus.error,
        errorMessage: storedApiMessage(error),
      );
    } catch (error) {
      if (sequence != _fetchSequence) return;
      state = state.copyWith(
        status: InstallationApplicationStatus.error,
        errorMessage: error.toString(),
      );
    }
  }

  Future<InstallationApplicationSaveResult> saveRequest(
    InstallationApplicationModel request,
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
    try {
      final code = await _repository.cancelRequest(requestId);
      await fetchRequests();
      return code;
    } on ApiException catch (error) {
      state = state.copyWith(errorMessage: storedApiMessage(error));
      return null;
    } catch (error) {
      state = state.copyWith(errorMessage: error.toString());
      return null;
    }
  }

  Future<bool> _runMutation(Future<void> Function() mutation) async {
    state = state.copyWith(clearError: true);
    try {
      await mutation();
      await fetchRequests();
      return true;
    } on ApiException catch (error) {
      state = state.copyWith(errorMessage: storedApiMessage(error));
      return false;
    } catch (error) {
      state = state.copyWith(errorMessage: error.toString());
      return false;
    }
  }
}

final installationApplicationControllerProvider = StateNotifierProvider<
    InstallationApplicationController, InstallationApplicationState>((ref) {
  return InstallationApplicationController(
      ref.watch(installationApplicationRepositoryProvider));
});
