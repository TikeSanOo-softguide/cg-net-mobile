import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../data/requests/change_wifi_password/change_wifi_password_repository.dart';
import '../../../models/requests/change_password/change_password_model.dart';

enum ChangeWifiPasswordStatus { initial, loading, success, error }

class ChangeWifiPasswordState {
  const ChangeWifiPasswordState({
    this.status = ChangeWifiPasswordStatus.initial,
    this.requests = const [],
    this.errorMessage,
    this.isSubmitting = false,
  });

  final ChangeWifiPasswordStatus status;
  final List<ChangePasswordRequestModel> requests;
  final String? errorMessage;
  final bool isSubmitting;

  ChangeWifiPasswordState copyWith({
    ChangeWifiPasswordStatus? status,
    List<ChangePasswordRequestModel>? requests,
    String? errorMessage,
    bool? isSubmitting,
  }) {
    return ChangeWifiPasswordState(
      status: status ?? this.status,
      requests: requests ?? this.requests,
      errorMessage: errorMessage,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

class ChangeWifiPasswordController
    extends StateNotifier<ChangeWifiPasswordState> {
  ChangeWifiPasswordController(this._repository)
      : super(const ChangeWifiPasswordState()) {
    fetchRequests();
  }

  final ChangeWifiPasswordRepository _repository;
  int _fetchSequence = 0;

  Future<void> fetchRequests() async {
    final sequence = ++_fetchSequence;
    state = state.copyWith(
      status: ChangeWifiPasswordStatus.loading,
      requests: const [],
      errorMessage: null,
    );
    try {
      final items = await _repository.fetchRequests();
      if (sequence != _fetchSequence) return;
      state = state.copyWith(
        status: ChangeWifiPasswordStatus.success,
        requests: items,
        errorMessage: null,
      );
    } catch (_) {
      if (sequence != _fetchSequence) return;
      state = state.copyWith(
        status: ChangeWifiPasswordStatus.initial,
      );
    }
  }

  Future<ChangeWifiPasswordCancelResult?> cancelRequest(
    ChangePasswordRequestModel item,
  ) async {
    try {
      final result = await _repository.cancelRequest(item);
      await fetchRequests();
      return result;
    } on ApiException catch (e) {
      state = state.copyWith(errorMessage: e.detail ?? e.messageKey);
      return null;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return null;
    }
  }

  Future<ChangeWifiPasswordSaveResult?> updateRequest({
    required ChangePasswordRequestModel request,
    required String broadbandAccount,
    required String contactName,
    required String contactPhone,
    required String newPassword,
    String? newWifiName,
  }) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    final updatedRequest = ChangePasswordRequestModel(
      id: request.id,
      userId: request.userId,
      broadbandAccountNumber: broadbandAccount,
      contactName: contactName,
      contactPhone: contactPhone,
      newPassword: newPassword,
      newWifiName: newWifiName,
      ticketNumber: request.ticketNumber,
      status: request.status,
      adminId: request.adminId,
      createdAt: request.createdAt,
      updatedAt: request.updatedAt,
    );

    try {
      final savedRequest = await _repository.updateRequest(updatedRequest);
      final requests = [...state.requests];
      final savedIndex = requests.indexWhere(
        (item) =>
            item.id.isNotEmpty && item.id == savedRequest.request.id,
      );
      if (savedIndex == -1) {
        requests.insert(0, savedRequest.request);
      } else {
        requests[savedIndex] = savedRequest.request;
      }
      state = state.copyWith(
        isSubmitting: false,
        requests: requests,
        errorMessage: null,
      );
      return savedRequest;
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

  Future<ChangeWifiPasswordSaveResult?> submitRequest({
    required String broadbandAccount,
    required String contactName,
    required String contactPhone,
    required String newPassword,
    String? newWifiName,
    int? userId,
  }) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);

    final hasPending = state.requests.any((r) {
      final s = r.status.toLowerCase().trim();
      final isPending = s == 'under_review' ||
          s == 'pending' ||
          s == 'under review' ||
          s == 'review';
      final isSameAccount = r.broadbandAccountNumber == null ||
          r.broadbandAccountNumber!.isEmpty ||
          r.broadbandAccountNumber == broadbandAccount;
      return isPending && isSameAccount;
    });

    if (hasPending) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'change_wifi.already_exists',
      );
      return null;
    }

    final model = ChangePasswordRequestModel(
      id: '',
      userId: userId ?? 0,
      broadbandAccountNumber: broadbandAccount,
      contactName: contactName,
      contactPhone: contactPhone,
      newPassword: newPassword,
      newWifiName: newWifiName,
      createdAt: DateTime.now(),
    );

    try {
      final savedModel = await _repository.submitRequest(model);
      final requests = [...state.requests];
      final savedIndex = requests.indexWhere(
        (item) => item.id.isNotEmpty && item.id == savedModel.request.id,
      );
      if (savedIndex == -1) {
        requests.insert(0, savedModel.request);
      } else {
        requests[savedIndex] = savedModel.request;
      }
      state = state.copyWith(
        isSubmitting: false,
        requests: requests,
        errorMessage: null,
      );
      return savedModel;
    } on ApiException catch (e) {
      final detailRaw = e.detail ?? e.messageKey;
      final detail = detailRaw.toLowerCase();

      final isAlreadyUnderReview = detail.contains('already under review') ||
          detail.contains('already exist') ||
          detail.contains('under_review') ||
          detail.contains('under review');

      if (isAlreadyUnderReview) {
        state = state.copyWith(
          isSubmitting: false,
          errorMessage: 'change_wifi.already_exists',
        );
        return null;
      }

      state = state.copyWith(
        isSubmitting: false,
        errorMessage: e.detail ?? e.messageKey,
      );
      rethrow;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

}

final changeWifiPasswordControllerProvider = StateNotifierProvider<
    ChangeWifiPasswordController, ChangeWifiPasswordState>((ref) {
  return ChangeWifiPasswordController(
    ref.watch(changeWifiPasswordRepositoryProvider),
  );
});
