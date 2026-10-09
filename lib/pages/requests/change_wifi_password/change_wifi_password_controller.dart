import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/requests/change_wifi_password/change_wifi_password_api.dart';
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
  ChangeWifiPasswordController(this._api)
      : super(const ChangeWifiPasswordState()) {
    fetchRequests();
  }

  final ChangeWifiPasswordApi _api;

  Future<void> fetchRequests() async {
    state = state.copyWith(status: ChangeWifiPasswordStatus.loading);
    try {
      final items = await _api.fetchRequests();
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
      await _api.cancelRequest(item);
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
      userId: userId ?? 1,
      broadbandAccountNumber: broadbandAccount,
      contactName: contactName,
      contactPhone: contactPhone,
      newPassword: newPassword,
      newWifiName: newWifiName,
      createdAt: DateTime.now(),
    );

    try {
      final savedModel = await _api.submitRequest(model);
      await fetchRequests();
      state = state.copyWith(isSubmitting: false, errorMessage: null);
      return savedModel;
    } on ApiException catch (e) {
      final detailRaw = e.detail ?? e.messageKey;
      final detail = detailRaw.toLowerCase();

      final isBroadcastingError = detail.contains('pusher') ||
          detail.contains('reverb') ||
          detail.contains('curl error') ||
          detail.contains('could not resolve host');

      if (isBroadcastingError) {
        await fetchRequests();
        state = state.copyWith(isSubmitting: false, errorMessage: null);
        return model;
      }

      final isAlreadyUnderReview = detail.contains('already under review') ||
          detail.contains('already exist') ||
          detail.contains('under_review') ||
          detail.contains('under review');

      state = state.copyWith(
        isSubmitting: false,
        errorMessage:
            isAlreadyUnderReview ? 'change_wifi.already_exists' : detailRaw,
      );
      return null;
    } catch (e) {
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('pusher') ||
          errStr.contains('reverb') ||
          errStr.contains('curl error') ||
          errStr.contains('could not resolve host')) {
        await fetchRequests();
        state = state.copyWith(isSubmitting: false, errorMessage: null);
        return model;
      }

      state = state.copyWith(
        isSubmitting: false,
        errorMessage: e.toString(),
      );
      return null;
    }
  }
}

final changeWifiPasswordControllerProvider = StateNotifierProvider<
    ChangeWifiPasswordController, ChangeWifiPasswordState>((ref) {
  return ChangeWifiPasswordController(
    ref.watch(changeWifiPasswordApiProvider),
  );
});
