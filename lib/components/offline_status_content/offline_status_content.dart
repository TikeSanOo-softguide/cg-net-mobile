import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors/app_colors.dart';
import '../../core/theme/app_theme/app_theme.dart';

/// Icon, title, and description shared by the offline modal and page empty state.
class OfflineStatusContent extends StatelessWidget {
  const OfflineStatusContent({super.key, this.prominent = false});

  /// Larger icon and type for a full page. The modal keeps the compact size.
  final bool prominent;

  static const wifiOffIconAsset = 'assets/images/dialogs/wifi-off-icon.png';
  static const failure = Color(0xFFD90000);
  static const failureSoft = Color(0xFFFCE6E6);

  @override
  Widget build(BuildContext context) {
    final chip = prominent ? 40.0 : 36.0;
    final icon = prominent ? 24.0 : 23.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: chip,
          height: chip,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: failureSoft,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Image.asset(
            wifiOffIconAsset,
            width: icon,
            height: icon,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),
        SizedBox(height: prominent ? 10 : 8),
        Text(
          'shared.no_internet_title'.tr(),
          textAlign: TextAlign.center,
          style: AppTheme.english(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: failure,
            height: AppTheme.lineHeightMyanmarSafe,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'shared.offline_notice'.tr(),
          textAlign: TextAlign.center,
          style: AppTheme.english(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.textMuted,
            height: AppTheme.lineHeightMyanmarSafe,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

/// Icon, title, and description for a reached internet with an unreachable API.
class ServerUnavailableContent extends StatelessWidget {
  const ServerUnavailableContent({super.key, this.prominent = false});

  final bool prominent;

  static const iconAsset = 'assets/images/dialogs/server-unavailable.png';

  @override
  Widget build(BuildContext context) {
    final chip = prominent ? 40.0 : 36.0;
    final icon = prominent ? 18.0 : 16.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: chip,
          height: chip,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: OfflineStatusContent.failureSoft,
            borderRadius: BorderRadius.circular(8),
          ),
          child: ColorFiltered(
            colorFilter: const ColorFilter.mode(
              OfflineStatusContent.failure,
              BlendMode.srcIn,
            ),
            child: Image.asset(
              iconAsset,
              width: icon,
              height: icon,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
        ),
        SizedBox(height: prominent ? 10 : 8),
        Text(
          'shared.server_unavailable_title'.tr(),
          textAlign: TextAlign.center,
          style: AppTheme.english(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: OfflineStatusContent.failure,
            height: AppTheme.lineHeightMyanmarSafe,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'shared.server_unavailable_body'.tr(),
          textAlign: TextAlign.center,
          style: AppTheme.english(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.textMuted,
            height: AppTheme.lineHeightMyanmarSafe,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}
