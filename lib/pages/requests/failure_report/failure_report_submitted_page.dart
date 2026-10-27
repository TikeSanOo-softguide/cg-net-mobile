import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../components/app_button/app_button.dart';
import '../../../components/app_card/app_card.dart';
import '../../../components/app_curved_scaffold/app_curved_scaffold.dart';
import '../../../components/app_dialog/app_dialog.dart';
import '../../../core/router/route_names/route_names.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import '../../../core/theme/app_style/app_style.dart';
import '../../../core/theme/app_theme/app_theme.dart';
import '../../../models/requests/failure_report/failure_report_model.dart';
import 'failure_report_controller.dart';

class FailureReportSubmittedPage extends ConsumerWidget {
  const FailureReportSubmittedPage({
    super.key,
    required this.report,
  });

  final FailureReportModel report;

  void _goBackToHistory(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(RouteNames.home);
    }
  }

  Future<void> _cancelReport(BuildContext context, WidgetRef ref) async {
    final confirmed = await showAppConfirmModal(
      context,
      title: 'failure_report.cancel_title'.tr(),
      body: 'failure_report.cancel_confirm'.tr(),
      cancelLabel: 'common.no'.tr(),
      confirmLabel: 'failure_report.cancel_report'.tr(),
    );
    if (!confirmed || !context.mounted) return;

    final success = await ref
        .read(failureReportControllerProvider.notifier)
        .cancelReport(report);
    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('failure_report.cancel_success'.tr()),
          backgroundColor: AppColors.error,
        ),
      );
      _goBackToHistory(context);
      return;
    }

    final errorMessage = ref.read(failureReportControllerProvider).errorMessage;
    if (errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errorMessage.startsWith('failure_report.') ||
                    errorMessage.startsWith('api.') ||
                    errorMessage.startsWith('common.')
                ? errorMessage.tr()
                : errorMessage,
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  String _failureTypeLabel(BuildContext context, String type) {
    switch (type.toLowerCase().trim()) {
      case 'no_internet':
        return context.tr('failure_report.type_no_internet');
      case 'slow_speed':
        return context.tr('failure_report.type_slow_speed');
      case 'unstable_connection':
        return context.tr('failure_report.type_unstable_connection');
      case 'wifi_coverage':
        return context.tr('failure_report.type_wifi_coverage');
      case 'equipment_failure':
        return context.tr('failure_report.type_equipment_failure');
      case 'cable_damage':
      case 'cable_break':
        return context.tr('failure_report.type_cable_damage');
      case 'password_issue':
        return context.tr('failure_report.type_password_issue');
      default:
        return context.tr('failure_report.type_other');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canCancel = report.status.toLowerCase().trim() == 'under_review' ||
        report.status.toLowerCase().trim() == 'pending';

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _goBackToHistory(context);
      },
      child: AppCurvedScaffold(
        title: Text(
          context.tr('failure_report.submitted_title'),
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
                context.tr('failure_report.submitted_title'),
                style: AppTheme.english(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppStyle.spaceSm),
              Text(
                context.tr('failure_report.submitted_desc'),
                textAlign: TextAlign.center,
                style: AppTheme.body(
                  color: AppColors.textMuted,
                  weight: FontWeight.w400,
                ).copyWith(fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: AppStyle.spaceXxl),
              AppCard(
                elevated: false,
                bordered: false,
                padding: const EdgeInsets.all(AppStyle.spaceLg),
                child: Column(
                  children: [
                    if (report.broadbandAccountNumber != null &&
                        report.broadbandAccountNumber!.isNotEmpty) ...[
                      _buildDetailRow(
                        context.tr('failure_report.broadband_account'),
                        report.broadbandAccountNumber!,
                      ),
                      const Divider(
                        height: 24,
                        thickness: 1,
                        color: AppColors.paperBorder,
                      ),
                    ],
                    _buildDetailRow(
                      context.tr('failure_report.failure_type'),
                      _failureTypeLabel(context, report.failureType),
                    ),
                    const Divider(
                      height: 24,
                      thickness: 1,
                      color: AppColors.paperBorder,
                    ),
                    _buildDetailRow(
                      context.tr('failure_report.contact_name'),
                      report.contactName,
                    ),
                    const Divider(
                      height: 24,
                      thickness: 1,
                      color: AppColors.paperBorder,
                    ),
                    _buildDetailRow(
                      context.tr('failure_report.contact_phone'),
                      report.contactPhone,
                    ),
                    if (report.description.isNotEmpty) ...[
                      const Divider(
                        height: 24,
                        thickness: 1,
                        color: AppColors.paperBorder,
                      ),
                      _buildDetailRow(
                        context.tr('failure_report.description'),
                        report.description,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 40),
              AppButton(
                label: context.tr('common.done').toUpperCase(),
                onPressed: () => _goBackToHistory(context),
              ),
              if (canCancel) ...[
                const SizedBox(height: AppStyle.spaceMd),
                AppButton(
                  label: context.tr('failure_report.cancel_report'),
                  onPressed: () => _cancelReport(context, ref),
                ),
              ],
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
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: AppTheme.english(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
