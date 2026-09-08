import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  PackageListController(this._repository)
      : super(const PackageListState()) {
    load();
  }

  final PackageListRepository _repository;

  Future<void> load() async {
    state = state.copyWith(status: PackageListStatus.loading);
    try {
      final packages = await _repository.fetchPackagesMock();
      // To use live API later:
      // final packages = await _repository.fetchPackages();
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
    } catch (e) {
      state = state.copyWith(
        status: PackageListStatus.error,
        errorMessage: e.toString(),
      );
    }
  }
}

final packageListControllerProvider =
    StateNotifierProvider<PackageListController, PackageListState>((ref) {
  return PackageListController(ref.watch(packageListRepositoryProvider));
});
