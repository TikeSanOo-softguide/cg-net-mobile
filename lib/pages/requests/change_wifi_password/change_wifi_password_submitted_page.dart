import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router/go_router.dart';

import '../../../components/app_button/app_button.dart';
import '../../../components/app_card/app_card.dart';
import '../../../components/app_curved_scaffold/app_curved_scaffold.dart';
import '../../../core/router/route_names/route_names.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import '../../../core/theme/app_style/app_style.dart';
import '../../../core/theme/app_theme/app_theme.dart';
import '../../../models/requests/change_password/change_password_model.dart';

class ChangeWifiPasswordSubmittedPage extends StatelessWidget {
  const ChangeWifiPasswordSubmittedPage({
    super.key,
    required this.request,
  });

  final ChangePasswordRequestModel request;

  void _goBackToHistory(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(RouteNames.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _goBackToHistory(context);
      },
      child: AppCurvedScaffold(
        title: Text(
          'change_wifi.submitted_title'.tr(),
          style: AppTheme.topBarTitle(),
        ),
        showBack: true,
        onBack: () => _goBackToHistory(context),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppStyle.spaceLg,
            AppStyle.spaceXxl,
            AppStyle.spaceLg,
            AppStyle.spaceLg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Success Icon
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.circle_check,
                  color: AppColors.success,
                  size: 42,
                ),
              ),
              const SizedBox(height: AppStyle.spaceLg),

              // Title Text
              Text(
                'change_wifi.submitted_title'.tr(),
                style: AppTheme.english(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppStyle.spaceSm),

              // Description Text
              Text(
                'change_wifi.submitted_desc'.tr(),
                textAlign: TextAlign.center,
                style: AppTheme.body(
                  color: AppColors.textMuted,
                  weight: FontWeight.w400,
                ).copyWith(fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: AppStyle.spaceXxl),

              // Details Section
              AppCard(
                elevated: true,
                bordered: false,
                padding: const EdgeInsets.all(AppStyle.spaceLg),
                child: Column(
                  children: [
                    if (request.broadbandAccountNumber != null &&
                        request.broadbandAccountNumber!.isNotEmpty) ...[
                      _buildDetailRow(
                        'change_wifi.broadband_account'.tr(),
                        request.broadbandAccountNumber!,
                      ),
                      const Divider(
                        height: 24,
                        thickness: 1,
                        color: AppColors.paperBorder,
                      ),
                    ],
                    _buildDetailRow(
                      'change_wifi.contact_name'.tr(),
                      request.contactName,
                    ),
                    const Divider(
                      height: 24,
                      thickness: 1,
                      color: AppColors.paperBorder,
                    ),
                    _buildDetailRow(
                      'change_wifi.contact_phone'.tr(),
                      request.contactPhone,
                    ),
                    if (request.newWifiName != null &&
                        request.newWifiName!.isNotEmpty) ...[
                      const Divider(
                        height: 24,
                        thickness: 1,
                        color: AppColors.paperBorder,
                      ),
                      _buildDetailRow(
                        'change_wifi.new_wifi_name_hint'.tr(),
                        request.newWifiName!,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Done / Back Button
              AppButton(
                label: 'common.done'.tr().toUpperCase(),
                onPressed: () => _goBackToHistory(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTheme.body(
            color: AppColors.textMuted,
            weight: FontWeight.w400,
          ).copyWith(fontSize: 13),
        ),
        Text(
          value,
          style: AppTheme.english(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
