import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../components/app_button/app_button.dart';
import '../../../components/app_card/app_card.dart';
import '../../../components/app_curved_scaffold/app_curved_scaffold.dart';
import '../../../components/app_dialog/app_dialog.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_endpoints/api_endpoints.dart';
import '../../../core/router/route_names/route_names.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import '../../../core/theme/app_style/app_style.dart';
import '../../../core/theme/app_theme/app_theme.dart';
import '../../../data/requests/failure_report/failure_report_repository.dart';
import '../../../models/requests/failure_report/failure_report_model.dart';
import 'failure_report_controller.dart';

class FailureReportDetailPage extends ConsumerWidget {
  const FailureReportDetailPage({
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

  String _statusLabel(String status) {
    final normalized =
        status.toLowerCase().trim().replaceAll(' ', '_').replaceAll('-', '_');
    switch (normalized) {
      case 'under_review':
      case 'pending':
      case 'review':
      case 'processing':
      case 'in_progress':
      case 'submitted':
        return 'change_wifi.status_under_review'.tr();
      case 'approved':
      case 'completed':
        return 'change_wifi.status_approved'.tr();
      case 'cancelled':
        return 'change_wifi.status_cancelled'.tr();
      case 'rejected':
        return 'change_wifi.status_rejected'.tr();
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = report.status.toLowerCase().trim();
    final reportDetails = ref.watch(failureReportDetailProvider(report.id));
    final canCancel = status.contains('review') ||
        status.contains('pending') ||
        status.contains('process') ||
        status.contains('progress') ||
        status == 'submitted';

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _goBackToHistory(context);
      },
      child: AppCurvedScaffold(
        title: Text(
          context.tr('change_wifi.request_details'),
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
              AppCard(
                elevated: true,
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
                    const Divider(
                      height: 24,
                      thickness: 1,
                      color: AppColors.paperBorder,
                    ),
                    _buildDetailRow(
                      context.tr('change_wifi.status'),
                      _statusLabel(status),
                    ),
                    if (report.createdAt != null) ...[
                      const Divider(
                        height: 24,
                        thickness: 1,
                        color: AppColors.paperBorder,
                      ),
                      _buildDetailRow(
                        context.tr('change_wifi.date'),
                        DateFormat('yyyy.MM.dd HH:mm')
                            .format(report.createdAt!),
                      ),
                    ],
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
              const SizedBox(height: AppStyle.spaceLg),
              _buildPhotosSection(context, reportDetails),
              if (canCancel) ...[
                const SizedBox(height: AppStyle.spaceLg),
                AppButton(
                  label: context.tr('failure_report.cancel_report'),
                  onPressed: () => _cancelReport(context, ref),
                  backgroundColor: AppColors.error,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotosSection(
    BuildContext context,
    AsyncValue<FailureReportModel> reportDetails,
  ) {
    return reportDetails.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(AppStyle.spaceLg),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (error, _) => AppCard(
        elevated: true,
        bordered: false,
        child: Text(
          error is ApiException
              ? (error.detail ?? error.messageKey).tr()
              : error.toString(),
          style: AppTheme.body(color: AppColors.error),
        ),
      ),
      data: (details) {
        if (details.photos.isEmpty) return const SizedBox.shrink();

        return AppCard(
          elevated: true,
          bordered: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('failure_report.upload_photos'),
                style: AppTheme.english(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppStyle.spaceMd),
              Wrap(
                spacing: AppStyle.spaceSm,
                runSpacing: AppStyle.spaceSm,
                children: [
                  for (final photo in details.photos)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        _photoUri(photo.imageUrl),
                        width: 96,
                        height: 96,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 96,
                          height: 96,
                          color: AppColors.background,
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.broken_image_outlined,
                            color: AppColors.textMuted,
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
  }

  String _photoUri(String imageUrl) {
    final uri = Uri.parse(imageUrl);
    if (uri.hasScheme) return imageUrl;

    final baseUri = Uri.parse(ApiEndpoints.baseUrl);
    final origin = Uri(
      scheme: baseUri.scheme,
      host: baseUri.host,
      port: baseUri.hasPort ? baseUri.port : null,
    );
    return origin
        .resolve(imageUrl.startsWith('/') ? imageUrl : '/$imageUrl')
        .toString();
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
