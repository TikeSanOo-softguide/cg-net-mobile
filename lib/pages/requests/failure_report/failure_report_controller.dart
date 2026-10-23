import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../data/requests/failure_report/failure_report_repository.dart';
import '../../../models/requests/failure_report/failure_report_model.dart';

enum FailureReportStatus { initial, loading, success, error }

class FailureReportState {
  const FailureReportState({
    this.status = FailureReportStatus.initial,
    this.reports = const [],
    this.errorMessage,
    this.isSubmitting = false,
  });

  final FailureReportStatus status;
  final List<FailureReportModel> reports;
  final String? errorMessage;
  final bool isSubmitting;

  FailureReportState copyWith({
    FailureReportStatus? status,
    List<FailureReportModel>? reports,
    String? errorMessage,
    bool? isSubmitting,
  }) {
    return FailureReportState(
      status: status ?? this.status,
      reports: reports ?? this.reports,
      errorMessage: errorMessage,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

class FailureReportController extends StateNotifier<FailureReportState> {
  FailureReportController(this._repository) : super(const FailureReportState());

  final FailureReportRepository _repository;

  Future<void> fetchReports() async {
    state = state.copyWith(status: FailureReportStatus.loading);
    try {
      final items = await _repository.fetchReports();
      state = state.copyWith(
        status: FailureReportStatus.success,
        reports: items,
        errorMessage: null,
      );
    } catch (error) {
      state = state.copyWith(
        status: FailureReportStatus.error,
        errorMessage: error is ApiException
            ? error.detail ?? error.messageKey
            : error.toString(),
      );
    }
  }

  Future<bool> cancelReport(FailureReportModel item) async {
    try {
      await _repository.cancelReport(item);
      state = state.copyWith(
        reports: [
          for (final report in state.reports)
            if (report.id == item.id)
              report.copyWith(status: 'cancelled')
            else
              report,
        ],
      );
      await fetchReports();
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(errorMessage: e.detail ?? e.messageKey);
      return false;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<FailureReportModel?> submitReport({
    required String broadbandAccount,
    required String failureType,
    required String description,
    required String contactName,
    required String contactPhone,
    required int userId,
    List<FailurePhotoModel> photos = const [],
  }) async {
    state = state.copyWith(
      isSubmitting: true,
      errorMessage: null,
    );

    final hasPending = state.reports.any((r) {
      final status = r.status.toLowerCase().trim();

      final isPending = status == 'under_review' ||
          status == 'pending' ||
          status == 'under review' ||
          status == 'review';

      final isSameAccount =
          (r.broadbandAccountNumber ?? '').trim() == broadbandAccount.trim();

      return isPending && isSameAccount;
    });

    if (hasPending) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'failure_report.already_exists',
      );
      return null;
    }

    final model = FailureReportModel(
      id: '',
      userId: userId,
      broadbandAccountNumber: broadbandAccount,
      failureType: failureType,
      description: description,
      contactName: contactName,
      contactPhone: contactPhone,
      photos: photos,
    );

    try {
      final savedModel = await _repository.submitReport(model);
      final reports = [...state.reports];
      final savedIndex = reports.indexWhere(
        (report) => report.id.isNotEmpty && report.id == savedModel.id,
      );
      if (savedIndex == -1) {
        reports.insert(0, savedModel);
      } else {
        reports[savedIndex] = savedModel;
      }

      state = state.copyWith(
        isSubmitting: false,
        errorMessage: null,
        reports: reports,
      );
      await fetchReports();

      return savedModel;
    } on ApiException catch (e) {
      final detail = (e.detail ?? e.messageKey).toLowerCase();

      final isDuplicate = detail.contains('already under review') ||
          detail.contains('already exist') ||
          detail.contains('under_review') ||
          detail.contains('under review');

      if (isDuplicate) {
        state = state.copyWith(
          isSubmitting: false,
          errorMessage: 'failure_report.already_exists',
        );
        return null;
      }

      state = state.copyWith(
        isSubmitting: false,
        errorMessage: e.detail ?? e.messageKey,
      );

      return null;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: e.toString(),
      );
      return null;
    }
  }

}

final failureReportControllerProvider =
    StateNotifierProvider<FailureReportController, FailureReportState>((ref) {
  return FailureReportController(
    ref.watch(failureReportRepositoryProvider),
  );
});
