import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../components/app_add_floating_action_button/app_add_floating_action_button.dart';
import '../../../components/app_card/app_card.dart';
import '../../../components/app_circle_icon_button/app_circle_icon_button.dart';
import '../../../components/app_curved_scaffold/app_curved_scaffold.dart';
import '../../../components/app_dialog/app_dialog.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import '../../../core/theme/app_style/app_style.dart';
import '../../../core/theme/app_theme/app_theme.dart';
import '../../../models/requests/installation_application/installation_application_model.dart';
import '../../profile/profile/profile_controller.dart';
import 'installation_application_controller.dart';
import 'installation_application_submitted_page.dart';
import 'installation_application_form_page.dart';
import 'installation_request_draft.dart';

class InstallationApplicationPage extends ConsumerStatefulWidget {
  const InstallationApplicationPage({super.key});

  @override
  ConsumerState<InstallationApplicationPage> createState() =>
      _InstallationApplicationPageState();
}

class _InstallationApplicationPageState
    extends ConsumerState<InstallationApplicationPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(profileControllerProvider.notifier).fetchProfile();
      ref
          .read(installationApplicationControllerProvider.notifier)
          .fetchRequests();
    });
  }

  Future<void> _refresh() => ref
      .read(installationApplicationControllerProvider.notifier)
      .fetchRequests();

  Future<void> _openForm([InstallationApplicationModel? request]) async {
    final profile = ref.read(profileControllerProvider);
    ref.read(installationRequestDraftProvider.notifier).begin(
          request: request,
          profile: profile,
        );
    final savedRequest =
        await Navigator.of(context).push<InstallationApplicationModel>(
      MaterialPageRoute(
        builder: (_) => const InstallationApplicationFormPage(),
      ),
    );
    ref.read(installationRequestDraftProvider.notifier).reset();
    if (!mounted || savedRequest == null) return;
    if (request != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('installationApplication.update_success'.tr())),
      );
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            InstallationApplicationSubmittedPage(request: savedRequest),
      ),
    );
  }

  Future<void> _confirmAction({
    required InstallationApplicationModel request,
  }) async {
    final confirmed = await showAppConfirmModal(
      context,
      title: 'installationApplication.cancel_title'.tr(),
      body: 'installationApplication.cancel_confirm'.tr(),
      confirmLabel: 'installationApplication.cancel_action'.tr(),
      cancelLabel: 'common.no'.tr(),
    );
    if (confirmed != true) return;

    final controller =
        ref.read(installationApplicationControllerProvider.notifier);
    final success = await controller.cancelRequest(request.id);
    if (!mounted) return;

    final state = ref.read(installationApplicationControllerProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'installationApplication.cancel_success'.tr()
              : _localizedError(state.errorMessage),
        ),
        backgroundColor: success ? null : AppColors.error,
      ),
    );
  }

  String _localizedError(String? message) {
    if (message == null) return 'common.error'.tr();
    if (message.startsWith('api.') || message.startsWith('common.')) {
      return message.tr();
    }
    return message;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(installationApplicationControllerProvider);
    final canSubmitNewRequest = !state.requests.any(_canManageRequest);

    return AppCurvedScaffold(
      title: Text(
        'home.service_packages'.tr(),
        style: AppTheme.topBarTitle(),
      ),
      showBack: true,
      floatingActionButton: canSubmitNewRequest
          ? AppAddFloatingActionButton(
              onPressed: () => _openForm(),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _buildBody(state),
      ),
    );
  }

  Widget _buildBody(InstallationApplicationState state) {
    if (state.status == InstallationApplicationStatus.loading &&
        state.requests.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (state.status == InstallationApplicationStatus.error &&
        state.requests.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(AppStyle.spaceLg),
        children: [
          AppCard(
            child: Column(
              children: [
                Text(
                  _localizedError(state.errorMessage),
                  textAlign: TextAlign.center,
                  style: AppTheme.body(color: AppColors.textMuted),
                ),
                const SizedBox(height: AppStyle.spaceMd),
                TextButton(
                  onPressed: _refresh,
                  child: Text('common.retry'.tr()),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (state.requests.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(AppStyle.spaceLg),
        children: [
          AppCard(
            elevated: false,
            bordered: false,
            padding: const EdgeInsets.all(AppStyle.spaceXxl),
            child: Column(
              children: [
                const Icon(
                  LucideIcons.map_pin,
                  color: AppColors.primary,
                  size: AppStyle.iconSizeLg,
                ),
                const SizedBox(height: AppStyle.spaceMd),
                Text(
                  'installationApplication.no_requests'.tr(),
                  style: AppTheme.sectionTitle(),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppStyle.spaceXs),
                Text(
                  'installationApplication.no_requests_desc'.tr(),
                  textAlign: TextAlign.center,
                  style: AppTheme.bodySecondary(),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final hasError = state.status == InstallationApplicationStatus.error &&
        state.errorMessage != null;
    return ListView.separated(
      padding: const EdgeInsets.all(AppStyle.spaceLg),
      itemCount: state.requests.length + (hasError ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: AppStyle.spaceMd),
      itemBuilder: (context, index) {
        if (hasError && index == 0) {
          return AppCard(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _localizedError(state.errorMessage),
                    style: AppTheme.body(color: AppColors.error),
                  ),
                ),
                TextButton(
                  onPressed: _refresh,
                  child: Text('common.retry'.tr()),
                ),
              ],
            ),
          );
        }
        final requestIndex = index - (hasError ? 1 : 0);
        final request = state.requests[requestIndex];
        return _InstallationApplicationCard(
          request: request,
          onEdit: () => _openForm(request),
          onCancel: () => _confirmAction(request: request),
        );
      },
    );
  }
}

bool _canManageRequest(InstallationApplicationModel request) {
  final status = request.status.toLowerCase().replaceAll(' ', '_');
  return status == 'pending' || status == 'under_review';
}

class _InstallationApplicationCard extends StatelessWidget {
  const _InstallationApplicationCard({
    required this.request,
    required this.onEdit,
    required this.onCancel,
  });

  final InstallationApplicationModel request;
  final VoidCallback onEdit;
  final VoidCallback onCancel;

  Color get _statusColor {
    switch (request.status.toLowerCase().replaceAll(' ', '_')) {
      case 'under_review':
      case 'pending':
        return AppColors.warning;
      case 'approved':
        return AppColors.success;
      case 'cancelled':
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.textMuted;
    }
  }

  String get _statusLabel {
    switch (request.status.toLowerCase().replaceAll(' ', '_')) {
      case 'under_review':
      case 'pending':
        return 'requests.status_under_review'.tr();
      case 'approved':
        return 'requests.status_approved'.tr();
      case 'cancelled':
        return 'requests.status_cancelled'.tr();
      case 'rejected':
        return 'requests.status_rejected'.tr();
      default:
        return request.status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final createdAt = request.createdAt == null
        ? null
        : DateFormat('yyyy.MM.dd HH:mm').format(request.createdAt!.toLocal());
    final canManage = _canManageRequest(request);

    return AppCard(
      elevated: false,
      bordered: false,
      padding: const EdgeInsets.all(AppStyle.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppStyle.spaceSm,
                  vertical: AppStyle.spaceXs,
                ),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.12),
                  borderRadius: AppStyle.borderRadiusInput,
                ),
                child: Text(
                  _statusLabel,
                  style: AppTheme.caption(
                    color: _statusColor,
                    weight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              if (createdAt != null) Text(createdAt, style: AppTheme.caption()),
            ],
          ),
          const SizedBox(height: AppStyle.spaceMd),
          if (request.serviceType != null)
            _RequestDetail(
              label: 'installationApplication.service_type'.tr(),
              value: request.serviceType!,
            ),
          if (request.productId != null || request.productName != null)
            _RequestDetail(
              label: 'installationApplication.package'.tr(),
              value: [
                request.productId,
                request.productName,
              ].whereType<String>().where((part) => part.trim().isNotEmpty).join('  '),
            ),
          _RequestDetail(
            label: 'installationApplication.id_name'.tr(),
            value: request.idName,
          ),
          _RequestDetail(
            label: 'installationApplication.address'.tr(),
            value: request.address ?? '',
          ),
          _RequestDetail(
            label: 'requests.phone'.tr(),
            value: request.phone,
          ),
          if (request.note?.trim().isNotEmpty == true)
            _RequestDetail(
              label: 'installationApplication.note'.tr(),
              value: request.note!,
            ),
          if (canManage) ...[
            const Divider(height: AppStyle.spaceXxl),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: AppStyle.spaceXs,
              children: [
                AppCircleIconButton(
                  onPressed: onEdit,
                  icon: LucideIcons.pencil,
                  backgroundColor: AppColors.primary,
                  iconSize: AppStyle.iconSizeSm,
                  borderRadius: AppStyle.radiusButton,
                ),
                Tooltip(
                  message: 'installationApplication.cancel_action'.tr(),
                  child: AppCircleIconButton(
                    onPressed: onCancel,
                    icon: LucideIcons.trash,
                    backgroundColor: AppColors.error,
                    iconSize: AppStyle.iconSizeSm,
                    borderRadius: AppStyle.radiusButton,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _RequestDetail extends StatelessWidget {
  const _RequestDetail({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppStyle.spaceSm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label : ', style: AppTheme.caption()),
          Expanded(
            child: Text(
              value,
              style: AppTheme.body(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
