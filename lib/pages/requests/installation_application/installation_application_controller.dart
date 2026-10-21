import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_exception.dart';
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

  Future<InstallationApplicationOptions> fetchRequestOptions() =>
      _repository.fetchRequestOptions();

  Future<void> fetchRequests() async {
    state = state.copyWith(
      status: InstallationApplicationStatus.loading,
      clearError: true,
    );
    try {
      final requests = await _repository.fetchRequests();
      state = state.copyWith(
        status: InstallationApplicationStatus.success,
        requests: requests,
        clearError: true,
      );
    } on ApiException catch (error) {
      state = state.copyWith(
        status: InstallationApplicationStatus.error,
        errorMessage: error.detail ?? error.messageKey,
      );
    } catch (error) {
      state = state.copyWith(
        status: InstallationApplicationStatus.error,
        errorMessage: error.toString(),
      );
    }
  }

  Future<InstallationApplicationModel?> saveRequest(
    InstallationApplicationModel request,
    {List<XFile> photos = const []}
  ) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final savedRequest = request.id.isEmpty
          ? await _repository.createRequest(request, photos: photos)
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

final installationApplicationControllerProvider = StateNotifierProvider<
    InstallationApplicationController, InstallationApplicationState>((ref) {
  return InstallationApplicationController(
      ref.watch(installationApplicationRepositoryProvider));
});
