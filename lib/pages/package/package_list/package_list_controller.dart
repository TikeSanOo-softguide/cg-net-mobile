import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/offline_navigation.dart';
import '../../../models/package_model/package_model.dart';
import 'package_list_repository.dart';

enum PackageListStatus { loading, empty, data, error }

class PackageListState {
  const PackageListState({
    this.status = PackageListStatus.loading,
    this.packages = const [],
    this.errorMessage,
  });

  final PackageListStatus status;
  final List<PackageModel> packages;
  final String? errorMessage;

  PackageListState copyWith({
    PackageListStatus? status,
    List<PackageModel>? packages,
    String? errorMessage,
  }) {
    return PackageListState(
      status: status ?? this.status,
      packages: packages ?? this.packages,
      errorMessage: errorMessage,
    );
  }
}

class PackageListController extends StateNotifier<PackageListState> {
  PackageListController(this._repository) : super(const PackageListState()) {
    load();
  }

  final PackageListRepository _repository;

  /// Returns true when a refresh kept the current list because the network
  /// could not be reached.
  Future<bool> load({bool silent = false, bool rethrowOffline = false}) async {
    final keep = silent && state.packages.isNotEmpty;
    if (!keep) {
      state = state.copyWith(status: PackageListStatus.loading);
    }
    try {
      final packages = await _repository.fetchPackages();
      if (packages.isEmpty) {
        state = state.copyWith(
          status: PackageListStatus.empty,
          packages: const [],
        );
      } else {
        state = state.copyWith(
          status: PackageListStatus.data,
          packages: packages,
        );
      }
      return false;
    } on ApiException catch (e) {
      final offline = isUnreachableError(e);
      if (keep && offline) {
        if (rethrowOffline) throw const ApiException(ApiFailure.offline);
        return true;
      }
      state = state.copyWith(
        status: PackageListStatus.error,
        errorMessage: storedApiMessage(e, messageKeyOnly: true),
      );
      if (rethrowOffline && offline) {
        throw const ApiException(ApiFailure.offline);
      }
      return false;
    } catch (e) {
      state = state.copyWith(
        status: PackageListStatus.error,
        errorMessage: e.toString(),
      );
      return false;
    }
  }
}

final packageListControllerProvider =
    StateNotifierProvider<PackageListController, PackageListState>((ref) {
  return PackageListController(ref.watch(packageListRepositoryProvider));
});
