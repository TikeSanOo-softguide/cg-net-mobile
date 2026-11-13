import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_exception.dart';
import '../../../data/requests/complaint/complaint_repository.dart';
import '../../../models/requests/complaint/complaint_model.dart';

enum ComplaintStatus { initial, loading, success, error }

class ComplaintState {
  const ComplaintState({
    this.status = ComplaintStatus.initial,
    this.reports = const [],
    this.errorMessage,
    this.isSubmitting = false,
  });

  final ComplaintStatus status;
  final List<ComplaintModel> reports;
  final String? errorMessage;
  final bool isSubmitting;

  ComplaintState copyWith({
    ComplaintStatus? status,
    List<ComplaintModel>? reports,
    String? errorMessage,
    bool? isSubmitting,
  }) {
    return ComplaintState(
      status: status ?? this.status,
      reports: reports ?? this.reports,
      errorMessage: errorMessage,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

class ComplaintController extends StateNotifier<ComplaintState> {
  ComplaintController(this._repository) : super(const ComplaintState());

  final ComplaintRepository _repository;
  int _fetchSequence = 0;

  Future<void> fetchComplaints({String? accountNumber}) async {
    final sequence = ++_fetchSequence;
    state = state.copyWith(
      status: ComplaintStatus.loading,
      errorMessage: null,
    );
    try {
      final items = await _repository.fetchComplaints();
      if (sequence != _fetchSequence) return;
      final normalizedAccount = accountNumber?.trim().toUpperCase();
      final reports = normalizedAccount == null || normalizedAccount.isEmpty
          ? items
          : items
              .where(
                (report) =>
                    report.broadbandAccountNumber?.trim().toUpperCase() ==
                    normalizedAccount,
              )
              .toList();
      state = state.copyWith(
        status: ComplaintStatus.success,
        reports: reports,
        errorMessage: null,
      );
    } catch (error) {
      if (sequence != _fetchSequence) return;
      state = state.copyWith(
        status: ComplaintStatus.error,
        errorMessage: error is ApiException
            ? error.detail ?? error.messageKey
            : error.toString(),
      );
    }
  }

  Future<ComplaintCancelResult?> cancelComplaint(
    ComplaintModel item,
  ) async {
    try {
      final result = await _repository.cancelComplaint(item);
      state = state.copyWith(
        reports: [
          for (final report in state.reports)
            if (report.id == item.id)
              report.copyWith(status: 'cancelled')
            else
              report,
        ],
      );
      await fetchComplaints(
        accountNumber: item.broadbandAccountNumber,
      );
      return result;
    } on ApiException catch (error) {
      state = state.copyWith(
        errorMessage: error.detail ?? error.messageKey,
      );
      return null;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return null;
    }
  }

  Future<ComplaintSaveResult?> submitComplaint({
    required String broadbandAccount,
    required String complaintType,
    required String description,
    required String contactName,
    required String contactPhone,
    required int userId,
    List<ComplaintPhotoModel> photos = const [],
    String? reportId,
  }) async {
    state = state.copyWith(
      isSubmitting: true,
      errorMessage: null,
    );

    final editing = reportId != null && reportId.isNotEmpty;
    final hasPending = !editing &&
        state.reports.any((r) {
          final status = r.status.toLowerCase().trim();

          final isPending = status == 'under_review' ||
              status == 'pending' ||
              status == 'under review' ||
              status == 'review';

          final isSameAccount = (r.broadbandAccountNumber ?? '').trim() ==
              broadbandAccount.trim();

          return isPending && isSameAccount;
        });

    if (hasPending) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'complaint.already_exists',
      );
      return null;
    }

    final model = ComplaintModel(
      id: reportId ?? '',
      userId: userId,
      broadbandAccountNumber: broadbandAccount,
      complaintType: complaintType,
      description: description,
      contactName: contactName,
      contactPhone: contactPhone,
      photos: photos,
    );

    try {
      final saved = editing
          ? await _repository.updateComplaint(model)
          : await _repository.submitComplaint(model);
      final savedModel = saved.report;
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

      return saved;
    } on ApiException catch (e) {
      final detail = (e.detail ?? e.code ?? e.messageKey).toLowerCase();

      final isDuplicate = detail.contains('already under review') ||
          detail.contains('already exist') ||
          detail.contains('under_review') ||
          detail.contains('under review');

      if (isDuplicate) {
        state = state.copyWith(
          isSubmitting: false,
          errorMessage: 'complaint.already_exists',
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

final complaintControllerProvider =
    StateNotifierProvider<ComplaintController, ComplaintState>((ref) {
  return ComplaintController(
    ref.watch(complaintRepositoryProvider),
  );
});
