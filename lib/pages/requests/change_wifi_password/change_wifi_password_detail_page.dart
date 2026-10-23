import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
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
import '../../../models/requests/change_password/change_password_model.dart';
import 'change_wifi_password_controller.dart';

class ChangeWifiPasswordDetailPage extends ConsumerWidget {
  const ChangeWifiPasswordDetailPage({
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

  Future<void> _cancelRequest(BuildContext context, WidgetRef ref) async {
    final confirmed = await showAppConfirmModal(
      context,
      title: 'change_wifi.cancel_title'.tr(),
      body: 'change_wifi.cancel_confirm'.tr(),
      cancelLabel: 'common.no'.tr(),
      confirmLabel: 'change_wifi.yes_cancel'.tr(),
    );
    if (!confirmed || !context.mounted) return;

    final success = await ref
        .read(changeWifiPasswordControllerProvider.notifier)
        .cancelRequest(request);
    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('change_wifi.cancel_success'.tr()),
          backgroundColor: AppColors.error,
        ),
      );
      _goBackToHistory(context);
      return;
    }

    final errorMessage =
        ref.read(changeWifiPasswordControllerProvider).errorMessage;
    if (errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errorMessage.startsWith('change_wifi.') ||
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = request.status.toLowerCase().trim();
    final canCancel = status == 'under_review' ||
        status == 'under review' ||
        status == 'pending' ||
        status == 'review';

    return AppCurvedScaffold(
      title: Text(
        'change_wifi.request_details'.tr(),
        style: AppTheme.topBarTitle(),
      ),
      showBack: true,
      onBack: () => _goBackToHistory(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppStyle.spaceLg),
        child: Column(
          children: [
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
                  const Divider(
                    height: 24,
                    thickness: 1,
                    color: AppColors.paperBorder,
                  ),
                  _buildDetailRow(
                    'change_wifi.status'.tr(),
                    _statusLabel(status),
                  ),
                  if (request.createdAt != null) ...[
                    const Divider(
                      height: 24,
                      thickness: 1,
                      color: AppColors.paperBorder,
                    ),
                    _buildDetailRow(
                      'change_wifi.date'.tr(),
                      DateFormat('yyyy.MM.dd HH:mm').format(request.createdAt!),
                    ),
                  ],
                ],
              ),
            ),
            if (canCancel) ...[
              const SizedBox(height: AppStyle.spaceLg),
              AppButton(
                label: 'change_wifi.cancel_request'.tr(),
                onPressed: () => _cancelRequest(context, ref),
                backgroundColor: AppColors.error,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'under_review':
      case 'under review':
      case 'pending':
      case 'review':
        return 'change_wifi.status_under_review'.tr();
      case 'approved':
      case 'completed':
      case 'active':
        return 'change_wifi.status_approved'.tr();
      case 'cancelled':
        return 'change_wifi.status_cancelled'.tr();
      case 'rejected':
        return 'change_wifi.status_rejected'.tr();
      default:
        return status;
    }
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
