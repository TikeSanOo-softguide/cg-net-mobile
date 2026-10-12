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

  Future<void> fetchRequests() async {
    state = state.copyWith(status: ChangeWifiPasswordStatus.loading);
    try {
      final items = await _repository.fetchRequests();
      state = state.copyWith(
        status: ChangeWifiPasswordStatus.success,
        requests: items,
        errorMessage: null,
      );
    } catch (_) {
      state = state.copyWith(
        status: ChangeWifiPasswordStatus.initial,
      );
    }
  }

  Future<bool> cancelRequest(ChangePasswordRequestModel item) async {
    try {
      await _repository.cancelRequest(item);
      await fetchRequests();
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(errorMessage: e.detail ?? e.messageKey);
      return false;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<ChangePasswordRequestModel?> submitRequest({
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
      await fetchRequests();
      state = state.copyWith(isSubmitting: false, errorMessage: null);
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

      await fetchRequests();
      state = state.copyWith(isSubmitting: false, errorMessage: null);
      return model;
    } catch (e) {
      await fetchRequests();
      state = state.copyWith(isSubmitting: false, errorMessage: null);
      return model;
    }
  }
}

final changeWifiPasswordControllerProvider = StateNotifierProvider<
    ChangeWifiPasswordController, ChangeWifiPasswordState>((ref) {
  return ChangeWifiPasswordController(
    ref.watch(changeWifiPasswordRepositoryProvider),
  );
});
