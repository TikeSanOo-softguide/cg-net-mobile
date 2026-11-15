import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../theme/app_colors/app_colors.dart';

class LoadingHelper {
  const LoadingHelper._();
  static Future<void> hide() => EasyLoading.dismiss(animation: false);

  static Future<T> runWithLoading<T>(
    Future<T> Function() task, {
    String? loadingMessage,
    String? successMessage,
    String? errorMessage,
    bool dismissAnimation = true,
    FutureOr<void> Function()? onBeforeDismiss,
  }) async {
    try {
      await EasyLoading.showCustom(
        _GlassSpinnerChip(message: loadingMessage),
        maskType: EasyLoadingMaskType.custom,
        dismissOnTap: false,
        options: EasyLoadingOptions(
          maskColor: Colors.black.withValues(alpha: 0.18),
          userInteractions: false,
        ),
      );

      final result = await task();
      return result;
    } finally {
      await onBeforeDismiss?.call();
      await EasyLoading.dismiss(animation: dismissAnimation);
    }
  }
}

class _GlassSpinnerChip extends StatelessWidget {
  const _GlassSpinnerChip({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final label = message?.trim() ?? '';
    return Material(
      type: MaterialType.transparency,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(8)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.50),
                  borderRadius: const BorderRadius.all(Radius.circular(8)),
                ),
                child: const SizedBox(
                  width: 52,
                  height: 52,
                  child: Center(
                    child: SpinKitFadingCircle(
                      color: AppColors.primary,
                      size: 32,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (label.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ],
      ),
    );
  }
}