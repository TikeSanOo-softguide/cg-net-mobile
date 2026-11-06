import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../components/app_add_floating_action_button/app_add_floating_action_button.dart';
import '../../../components/app_card/app_card.dart';
import '../../../components/app_curved_scaffold/app_curved_scaffold.dart';
import '../../../components/app_dialog/app_dialog.dart';
import '../../../core/network/message_codes.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import '../../../core/theme/app_style/app_style.dart';
import '../../../core/theme/app_theme/app_theme.dart';
import '../../../core/utils/date_time_format.dart';
import '../../../data/requests/change_plan/change_plan_repository.dart';
import '../../../models/requests/change_plan/change_plan_request_model.dart';
import '../../profile/profile/profile_controller.dart';
import 'change_plan_controller.dart';
import 'change_plan_form_page.dart';

class ChangePlanPage extends ConsumerStatefulWidget {
  const ChangePlanPage({super.key});

  @override
  ConsumerState<ChangePlanPage> createState() => _ChangePlanPageState();
}

class _ChangePlanPageState extends ConsumerState<ChangePlanPage> {
  static const _serviceTint = Color(0xFF7A0BC0);

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(profileControllerProvider.notifier).fetchProfile();
      ref.read(changePlanControllerProvider.notifier).fetchRequests();
    });
  }

  Future<void> _refresh() async {
    await ref.read(profileControllerProvider.notifier).fetchProfile();
    await ref.read(changePlanControllerProvider.notifier).fetchRequests();
  }

  Future<void> _openForm({ChangePlanRequestModel? request}) async {
    final result = await Navigator.of(context).push<Object?>(
      MaterialPageRoute<Object?>(
        builder: (_) => request == null
            ? const ChangePlanFormPage()
            : ChangePlanFormPage(initialRequest: request),
      ),
    );
    if (!mounted || result == null || result == false) return;
    if (result is ChangePlanSaveResult) {
      await showAppSuccessModal(
        context,
        title: 'common.success'.tr(),
        body: MessageCodes.featureReqKey(
          feature: 'changePlan',
          code: result.code,
          fallbackKey: request == null
              ? 'changePlan.req_submitted'
              : 'changePlan.req_updated',
        ).tr(),
      );
    }

    if (mounted) {
      await ref.read(changePlanControllerProvider.notifier).fetchRequests();
    }
  }

  Future<void> _confirmCancel(ChangePlanRequestModel request) async {
    final confirmed = await showAppConfirmModal(
      context,
      title: 'changePlan.cancel_title'.tr(),
      body: 'changePlan.cancel_confirm'.tr(),
      confirmLabel: 'common.confirm'.tr(),
      cancelLabel: 'common.no'.tr(),
    );
    if (confirmed != true) return;

    final code = await ref
        .read(changePlanControllerProvider.notifier)
        .cancelRequest(request.id);
    if (!mounted) return;
    if (code == null &&
        ref.read(changePlanControllerProvider).errorMessage != null) {
      final state = ref.read(changePlanControllerProvider);
      await showAppFailureModal(
        context,
        title: 'common.error'.tr(),
        body: state.errorMessage ?? 'common.error'.tr(),
      );
      return;
    }
    await showAppSuccessModal(
      context,
      title: 'common.success'.tr(),
      body: MessageCodes.featureReqKey(
        feature: 'changePlan',
        code: code,
        fallbackKey: 'changePlan.req_cancelled',
      ).tr(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(changePlanControllerProvider);
    final hasUnderReview = state.requests.any(_isUnderReview);

    return AppCurvedScaffold(
      title: Text(
        'home.service_change_plan'.tr(),
        style: AppTheme.topBarTitle(),
      ),
      showBack: true,
      floatingActionButton: hasUnderReview
          ? null
          : AppAddFloatingActionButton(onPressed: _openForm),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _buildBody(state),
      ),
    );
  }

  Widget _buildBody(ChangePlanState state) {
    if (state.status == ChangePlanStatus.loading && state.requests.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (state.status == ChangePlanStatus.error && state.requests.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(AppStyle.spaceLg),
        children: [
          AppCard(
            child: Column(
              children: [
                Text(
                  state.errorMessage ?? 'common.error'.tr(),
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
                ColorFiltered(
                  colorFilter: const ColorFilter.mode(
                    _serviceTint,
                    BlendMode.srcIn,
                  ),
                  child: Image.asset(
                    'assets/images/services/change_plan.png',
                    width: 36,
                    height: 36,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                ),
                const SizedBox(height: AppStyle.spaceMd),
                Text(
                  'changePlan.no_requests'.tr(),
                  style: AppTheme.sectionTitle(color: AppColors.primary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppStyle.spaceXs),
                Text(
                  'changePlan.no_requests_desc'.tr(),
                  textAlign: TextAlign.center,
                  style: AppTheme.bodySecondary(),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final items = state.requests;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppStyle.spaceLg,
        AppStyle.spaceLg,
        AppStyle.spaceLg,
        80,
      ),
      children: [
        for (var i = 0; i < items.length; i++) ...[
          _ChangePlanCard(
            request: items[i],
            onEdit: _isUnderReview(items[i])
                ? () => _openForm(request: items[i])
                : null,
            onCancel: _isUnderReview(items[i])
                ? () => _confirmCancel(items[i])
                : null,
          ),
          if (i != items.length - 1) const SizedBox(height: AppStyle.spaceSm),
        ],
      ],
    );
  }
}

bool _isUnderReview(ChangePlanRequestModel request) {
  final status = _statusKey(request);
  return status == 'pending' || status == 'under_review';
}

String _statusKey(ChangePlanRequestModel request) {
  return request.status
      .toLowerCase()
      .trim()
      .replaceAll(' ', '_')
      .replaceAll('-', '_');
}

class _ChangePlanCard extends StatefulWidget {
  const _ChangePlanCard({required this.request, this.onEdit, this.onCancel});

  final ChangePlanRequestModel request;
  final VoidCallback? onEdit;
  final VoidCallback? onCancel;

  @override
  State<_ChangePlanCard> createState() => _ChangePlanCardState();
}

class _ChangePlanCardState extends State<_ChangePlanCard> {
  bool _expanded = false;

  Color get _statusColor {
    switch (_statusKey(widget.request)) {
      case 'under_review':
      case 'pending':
        return AppColors.warning;
      case 'approved':
        return AppColors.success;
      case 'cancelled':
      case 'canceled':
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.textMuted;
    }
  }

  String get _statusLabel {
    switch (_statusKey(widget.request)) {
      case 'under_review':
      case 'pending':
        return 'requests.status_under_review'.tr();
      case 'approved':
        return 'requests.status_approved'.tr();
      case 'cancelled':
      case 'canceled':
        return 'requests.status_cancelled'.tr();
      case 'rejected':
        return 'requests.status_rejected'.tr();
      default:
        return widget.request.status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = widget.request;
    final createdAt = request.createdAt == null
        ? null
        : formatDate(request.createdAt!.toLocal().toIso8601String());
    final preferred = request.preferredDate == null
        ? ''
        : DateFormat('yyyy/MM/dd').format(request.preferredDate!);

    return AppCard(
      elevated: false,
      bordered: false,
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: _statusColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      height: 24,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _statusLabel,
                        style: AppTheme.caption(
                          color: _statusColor,
                          weight: FontWeight.w600,
                        ).copyWith(fontSize: 10, height: 1),
                      ),
                    ),
                    const Spacer(),
                    if (createdAt != null)
                      Text(
                        createdAt,
                        style: AppTheme.caption(color: AppColors.textPrimary)
                            .copyWith(fontSize: 11),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                _DetailRow(
                  label: 'installationApplication.ticket_number'.tr(),
                  value: request.ticketNumber ?? '',
                  ticket: true,
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  alignment: Alignment.topCenter,
                  child: _expanded
                      ? Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Column(
                            children: [
                              _DetailRow(
                                label:
                                    'installationApplication.service_type'.tr(),
                                value: request.serviceType == 'CG'
                                    ? 'installationApplication.cg_router'.tr()
                                    : (request.serviceType ?? ''),
                              ),
                              _DetailRow(
                                label: 'changePlan.current_plan'.tr(),
                                value: _packageLabel(
                                  request.currentPackageDetail,
                                ),
                              ),
                              _DetailRow(
                                label: 'changePlan.detail'.tr(),
                                value: _packageLabel(request.newPackageDetail),
                              ),
                              _DetailRow(
                                label: 'changePlan.preferred_date'.tr(),
                                value: preferred,
                              ),
                              _DetailRow(
                                label: 'changePlan.contact_name'.tr(),
                                value: request.contactName,
                              ),
                              _DetailRow(
                                label: 'changePlan.contact_phone'.tr(),
                                value: request.contactPhone,
                              ),
                              _DetailRow(
                                label: 'changePlan.note'.tr(),
                                value: request.note ?? '',
                              ),
                            ],
                          ),
                        )
                      : const SizedBox(width: double.infinity),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    InkWell(
                      onTap: () => setState(() => _expanded = !_expanded),
                      borderRadius: BorderRadius.circular(8),
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _expanded
                                  ? 'common.see_less'.tr()
                                  : 'common.see_more'.tr(),
                              style: AppTheme.caption(
                                color: AppColors.primary,
                                weight: FontWeight.w600,
                              ).copyWith(fontSize: 10),
                            ),
                            const SizedBox(width: 2),
                            Icon(
                              _expanded
                                  ? LucideIcons.chevron_up
                                  : LucideIcons.chevron_down,
                              size: 12,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (widget.onEdit != null || widget.onCancel != null) ...[
                      const Spacer(),
                      if (widget.onEdit != null)
                        Material(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(6),
                          child: InkWell(
                            onTap: widget.onEdit,
                            borderRadius: BorderRadius.circular(6),
                            splashColor:
                                AppColors.primary.withValues(alpha: 0.08),
                            highlightColor:
                                AppColors.primary.withValues(alpha: 0.04),
                            child: const SizedBox(
                              width: 26,
                              height: 24,
                              child: Center(
                                child: Image(
                                  image: AssetImage(
                                    'assets/images/profile/edit.png',
                                  ),
                                  width: 14,
                                  height: 14,
                                  fit: BoxFit.contain,
                                  filterQuality: FilterQuality.high,
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (widget.onEdit != null && widget.onCancel != null)
                        const SizedBox(width: 8),
                      if (widget.onCancel != null)
                        Material(
                          color: const Color(0xFFF8E8E6),
                          borderRadius: BorderRadius.circular(6),
                          child: InkWell(
                            onTap: widget.onCancel,
                            borderRadius: BorderRadius.circular(6),
                            child: const SizedBox(
                              width: 26,
                              height: 24,
                              child: Icon(
                                LucideIcons.trash,
                                size: 14,
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.ticket = false,
  });

  final String label;
  final String value;
  final bool ticket;

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty && !ticket) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 108, child: Text(label, style: AppTheme.caption())),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: ticket && value.trim().isNotEmpty
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        value,
                        textAlign: TextAlign.right,
                        style: AppTheme.body(
                          weight: FontWeight.w500,
                          color: AppColors.primary,
                        ).copyWith(fontSize: 12),
                      ),
                    )
                  : Text(
                      value.trim().isEmpty ? '—' : value,
                      textAlign: TextAlign.right,
                      style: AppTheme.body(
                        weight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ).copyWith(fontSize: 12),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

String _packageLabel(Map<String, dynamic> detail) {
  final names = detail['network_name'];
  var network = '';
  if (names is Map) {
    network = names['en']?.toString() ??
        names['my']?.toString() ??
        names['zh']?.toString() ??
        '';
  }
  final speed = detail['speed'] is Map
      ? (detail['speed'] as Map)['mbps']?.toString()
      : null;
  final months = detail['term'] is Map
      ? (detail['term'] as Map)['months']?.toString()
      : null;
  final parts = [
    if (network.trim().isNotEmpty) network.trim(),
    if (speed != null && speed.isNotEmpty) '${speed}M',
    if (months != null && months.isNotEmpty) '${months}mo',
  ];
  return parts.join(' · ');
}
