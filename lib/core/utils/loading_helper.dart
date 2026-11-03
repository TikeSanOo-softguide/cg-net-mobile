import 'package:flutter_easyloading/flutter_easyloading.dart';

import '../theme/app_colors/app_colors.dart';

class LoadingHelper {
  const LoadingHelper._();

  static Future<T> runWithLoading<T>(
    Future<T> Function() task, {
    String? loadingMessage,
    String? successMessage,
    String? errorMessage,
  }) async {
    try {
      await EasyLoading.show(
        status: loadingMessage,
        maskType: EasyLoadingMaskType.custom,
        dismissOnTap: false,
        options: EasyLoadingOptions(
          loadingStyle: EasyLoadingStyle.custom,
          indicatorColor: AppColors.primary,
          backgroundColor: AppColors.primaryLight.withValues(alpha: 0.42),
          textColor: AppColors.primary,
          maskColor: AppColors.primaryLight.withValues(alpha: 0.42),
          userInteractions: false,
        ),
      );

      final result = await task();
      if (successMessage != null) {
        await EasyLoading.showSuccess(successMessage);
      }
      return result;
    } catch (_) {
      if (errorMessage != null) {
        await EasyLoading.showError(errorMessage);
      }
      rethrow;
    } finally {
      await EasyLoading.dismiss();
    }
  }
}
