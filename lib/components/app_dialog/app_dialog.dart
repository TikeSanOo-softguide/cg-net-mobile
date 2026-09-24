import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors/app_colors.dart';
import '../../core/theme/app_style/app_style.dart';
import '../../core/theme/app_theme/app_theme.dart';

const _cancelRed = Color(0xFFFF0000);
const _alert = Color(0xFFF97A00);
const _successSoft = Color(0xFFE8F5DC); // light of #499A13
const _alertSoft = Color(0xFFFFF0E5); // light of #F97A00
const double _dialogRadius = 16;
const double _modalBtnHeight = 32;
const double _modalBtnFontSize = 11;
const String _successIconAsset = 'assets/images/dialogs/success.png';
const String _confirmIconAsset = 'assets/images/dialogs/confirm.png';
const String _alertIconAsset = 'assets/images/dialogs/alert.png';
const String _failureIconAsset = 'assets/images/dialogs/failure.png';
const Color _failure = Color(0xFFD90000);
const Color _failureSoft = Color(0xFFFCE6E6); // light of #D90000
const double _dialogIconChip = 36;
const double _dialogIconSize = 23;
const double _dialogIconRadius = 8;
const EdgeInsets _dialogPadding = EdgeInsets.fromLTRB(18, 16, 18, 16);
const double _gapIconTitle = 8;
const double _gapTitleBody = 6;
const double _gapBodyButton = 14;
const EdgeInsets _dialogInset = EdgeInsets.symmetric(horizontal: 44);
const Duration _dialogDuration = Duration(milliseconds: 220);
const Color _barrier = Color(0x6B000000); // ~42% black

Widget _dialogPngIcon({
  required String asset,
  required Color background,
}) {
  return Container(
    width: _dialogIconChip,
    height: _dialogIconChip,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(_dialogIconRadius),
    ),
    child: Image.asset(
      asset,
      width: _dialogIconSize,
      height: _dialogIconSize,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    ),
  );
}

ButtonStyle _primaryModalBtnStyle() => FilledButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.onPrimary,
      elevation: 0,
      minimumSize: const Size(0, _modalBtnHeight),
      maximumSize: const Size(double.infinity, _modalBtnHeight),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppStyle.radiusInput),
      ),
    );

ButtonStyle _cancelOutlineModalBtnStyle() => OutlinedButton.styleFrom(
      foregroundColor: _cancelRed,
      backgroundColor: Colors.white,
      elevation: 0,
      minimumSize: const Size(0, _modalBtnHeight),
      maximumSize: const Size(double.infinity, _modalBtnHeight),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      side: const BorderSide(color: _cancelRed, width: 1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppStyle.radiusInput),
      ),
    );

TextStyle _modalBtnText({
  required Color color,
  FontWeight weight = FontWeight.w600,
}) =>
    AppTheme.english(
      fontSize: _modalBtnFontSize,
      fontWeight: weight,
      color: color,
    );

TextStyle _dialogTitleStyle(Color color) => AppTheme.english(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: color,
      height: 1.3,
      letterSpacing: -0.2,
    );

TextStyle _dialogMessageStyle() => AppTheme.english(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: AppColors.textMuted,
      height: 1.45,
      letterSpacing: 0,
    );

/// Soft fade + scale — same on iOS and Android.
Future<T?> _showAppDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: _barrier,
    transitionDuration: _dialogDuration,
    pageBuilder: (ctx, animation, secondaryAnimation) => builder(ctx),
    transitionBuilder: (ctx, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

Widget _appDialogShell({required Widget child}) {
  return Dialog(
    backgroundColor: AppColors.surface,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(_dialogRadius),
    ),
    insetPadding: _dialogInset,
    child: Padding(
      padding: _dialogPadding,
      child: child,
    ),
  );
}

/// Shared success dialog — Flaticon success badge + success title.
Future<void> showAppSuccessModal(
  BuildContext context, {
  required String title,
  required String body,
  String? buttonLabel,
}) {
  return _showAppDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return _appDialogShell(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dialogPngIcon(
              asset: _successIconAsset,
              background: _successSoft,
            ),
            const SizedBox(height: _gapIconTitle),
            Text(
              title,
              textAlign: TextAlign.center,
              style: _dialogTitleStyle(AppColors.success),
            ),
            const SizedBox(height: _gapTitleBody),
            Text(
              body,
              textAlign: TextAlign.center,
              style: _dialogMessageStyle(),
            ),
            const SizedBox(height: _gapBodyButton),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 120),
              child: SizedBox(
                height: _modalBtnHeight,
                child: FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  style: _primaryModalBtnStyle(),
                  child: Text(
                    buttonLabel ?? 'common.done'.tr(),
                    style: _modalBtnText(color: AppColors.onPrimary),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// Shared failure dialog — Flaticon error badge + error title.
Future<void> showAppFailureModal(
  BuildContext context, {
  required String title,
  required String body,
  String? buttonLabel,
}) {
  return _showAppDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return _appDialogShell(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dialogPngIcon(
              asset: _failureIconAsset,
              background: _failureSoft,
            ),
            const SizedBox(height: _gapIconTitle),
            Text(
              title,
              textAlign: TextAlign.center,
              style: _dialogTitleStyle(_failure),
            ),
            const SizedBox(height: _gapTitleBody),
            Text(
              body,
              textAlign: TextAlign.center,
              style: _dialogMessageStyle(),
            ),
            const SizedBox(height: _gapBodyButton),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 120),
              child: SizedBox(
                height: _modalBtnHeight,
                child: FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  style: _primaryModalBtnStyle(),
                  child: Text(
                    buttonLabel ?? 'common.ok'.tr(),
                    style: _modalBtnText(color: AppColors.onPrimary),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// Simple alert — Flaticon warning badge + alert title.
Future<void> showAppAlertModal(
  BuildContext context, {
  required String message,
  String? buttonLabel,
  String? title,
}) {
  return _showAppDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      return _appDialogShell(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dialogPngIcon(
              asset: _alertIconAsset,
              background: _alertSoft,
            ),
            if (title != null) ...[
              const SizedBox(height: _gapIconTitle),
              Text(
                title,
                textAlign: TextAlign.center,
                style: _dialogTitleStyle(_alert),
              ),
              const SizedBox(height: _gapTitleBody),
            ] else
              const SizedBox(height: _gapIconTitle),
            Text(
              message,
              textAlign: TextAlign.center,
              style: _dialogMessageStyle(),
            ),
            const SizedBox(height: _gapBodyButton),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 120),
              child: SizedBox(
                height: _modalBtnHeight,
                child: FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  style: _primaryModalBtnStyle(),
                  child: Text(
                    buttonLabel ?? 'common.ok'.tr(),
                    style: _modalBtnText(color: AppColors.onPrimary),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// Shared confirm dialog — primary title + Flaticon info badge.
Future<bool> showAppConfirmModal(
  BuildContext context, {
  required String title,
  required String body,
  String? confirmLabel,
  String? cancelLabel,
}) async {
  final result = await _showAppDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      return _appDialogShell(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dialogPngIcon(
              asset: _confirmIconAsset,
              background: AppColors.primaryLight,
            ),
            const SizedBox(height: _gapIconTitle),
            Text(
              title,
              textAlign: TextAlign.center,
              style: _dialogTitleStyle(AppColors.primary),
            ),
            const SizedBox(height: _gapTitleBody),
            Text(
              body,
              textAlign: TextAlign.center,
              style: _dialogMessageStyle(),
            ),
            const SizedBox(height: _gapBodyButton),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: _modalBtnHeight,
                    child: OutlinedButton(
                      onPressed: () =>
                          Navigator.of(dialogContext).pop(false),
                      style: _cancelOutlineModalBtnStyle(),
                      child: Text(
                        cancelLabel ?? 'common.cancel'.tr(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _modalBtnText(
                          color: _cancelRed,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: _modalBtnHeight,
                    child: FilledButton(
                      onPressed: () =>
                          Navigator.of(dialogContext).pop(true),
                      style: _primaryModalBtnStyle(),
                      child: Text(
                        confirmLabel ?? 'common.confirm'.tr(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _modalBtnText(
                          color: AppColors.onPrimary,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
  return result == true;
}
