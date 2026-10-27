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
import '../../../models/requests/installation_application/installation_application_model.dart';

class InstallationApplicationSubmittedPage extends StatelessWidget {
  const InstallationApplicationSubmittedPage({
    super.key,
    required this.request,
  });

  final InstallationApplicationModel request;

  void _goBackToRequests(BuildContext context) {
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
        _goBackToRequests(context);
      },
      child: AppCurvedScaffold(
        title: Text(
          'requests.submitted_title'.tr(),
          style: AppTheme.topBarTitle(),
        ),
        showBack: true,
        onBack: () => _goBackToRequests(context),
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
              Text(
                'requests.submitted_title'.tr(),
                textAlign: TextAlign.center,
                style: AppTheme.pageTitle(),
              ),
              const SizedBox(height: AppStyle.spaceSm),
              Text(
                'installationApplication.submitted_desc'.tr(),
                textAlign: TextAlign.center,
                style: AppTheme.body(color: AppColors.textMuted),
              ),
              const SizedBox(height: AppStyle.spaceXxl),
              AppCard(
                elevated: false,
                bordered: false,
                padding: AppStyle.cardPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (request.idName.trim().isNotEmpty)
                      _detailRow(
                        'installationApplication.id_name'.tr(),
                        request.idName,
                      ),
                    if (request.idType.trim().isNotEmpty)
                      _detailRow(
                        'installationApplication.id_type'.tr(),
                        request.idType,
                      ),
                    if (request.idNumber?.trim().isNotEmpty == true)
                      _detailRow(
                        'installationApplication.id_number'.tr(),
                        request.idNumber!,
                      ),
                    if (request.address?.trim().isNotEmpty == true)
                      _detailRow(
                        'installationApplication.address'.tr(),
                        request.address!,
                      ),
                    _detailRow('requests.phone'.tr(), request.phone),
                    if (request.note?.trim().isNotEmpty == true)
                      _detailRow(
                        'installationApplication.note'.tr(),
                        request.note!,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppStyle.spaceXxxl),
              AppButton(
                label: 'common.done'.tr().toUpperCase(),
                onPressed: () => _goBackToRequests(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppStyle.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTheme.caption()),
          const SizedBox(height: AppStyle.spaceXs),
          Text(
            value,
            style: AppTheme.body(
              color: AppColors.textPrimary,
              weight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
