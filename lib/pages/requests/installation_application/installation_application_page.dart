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
import '../../../models/requests/installation_application/installation_application_model.dart';
import '../../profile/profile/profile_controller.dart';
import 'installation_application_controller.dart';
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
    await Navigator.of(context).push<InstallationApplicationModel>(
      MaterialPageRoute(
        builder: (_) => const InstallationApplicationFormPage(),
      ),
    );
    ref.read(installationRequestDraftProvider.notifier).reset();
  }

  Future<void> _confirmAction({
    required InstallationApplicationModel request,
  }) async {
    final confirmed = await showAppConfirmModal(
      context,
      title: 'installationApplication.cancel_title'.tr(),
      body: 'installationApplication.cancel_confirm'.tr(),
      confirmLabel: 'common.confirm'.tr(),
      cancelLabel: 'common.no'.tr(),
    );
    if (confirmed != true) return;

    final controller =
        ref.read(installationApplicationControllerProvider.notifier);
    final code = await controller.cancelRequest(request.id);
    if (!mounted) return;

    if (code == null) {
      final state = ref.read(installationApplicationControllerProvider);
      await showAppFailureModal(
        context,
        title: 'common.error'.tr(),
        body: _localizedError(state.errorMessage),
      );
      return;
    }

    await showAppSuccessModal(
      context,
      title: 'common.success'.tr(),
      body: MessageCodes.isKnown(code)
          ? MessageCodes.locKey(code).tr()
          : 'installationApplication.cancel_success'.tr(),
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
                ColorFiltered(
                  colorFilter: const ColorFilter.mode(
                    Color(0xFFDA0C81),
                    BlendMode.srcIn,
                  ),
                  child: Image.asset(
                    'assets/images/services/installation.png',
                    width: 36,
                    height: 36,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                ),
                const SizedBox(height: AppStyle.spaceMd),
                Text(
                  'installationApplication.no_requests'.tr(),
                  style: AppTheme.sectionTitle(color: AppColors.primary),
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
    final underReview = state.requests
        .where((item) => _statusKey(item) == 'pending' || _statusKey(item) == 'under_review')
        .toList();
    final approved = state.requests
        .where((item) => _statusKey(item) == 'approved')
        .toList();
    final cancelled = state.requests
        .where((item) =>
            _statusKey(item) == 'cancelled' || _statusKey(item) == 'rejected')
        .toList();

    Widget cardFor(InstallationApplicationModel request) {
      return _InstallationApplicationCard(
        request: request,
        onEdit: () => _openForm(request),
        onCancel: () => _confirmAction(request: request),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppStyle.spaceLg,
        AppStyle.spaceLg,
        AppStyle.spaceLg,
        80,
      ),
      children: [
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(bottom: AppStyle.spaceMd),
            child: AppCard(
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
            ),
          ),
        ..._requestCards(
          [...underReview, ...approved, ...cancelled],
          cardFor,
        ),
      ],
    );
  }
}

String _statusKey(InstallationApplicationModel request) {
  return request.status.toLowerCase().replaceAll(' ', '_');
}

List<Widget> _requestCards(
  List<InstallationApplicationModel> requests,
  Widget Function(InstallationApplicationModel request) cardFor,
) {
  return [
    for (var i = 0; i < requests.length; i++) ...[
      cardFor(requests[i]),
      if (i != requests.length - 1) const SizedBox(height: AppStyle.spaceSm),
    ],
  ];
}

bool _canManageRequest(InstallationApplicationModel request) {
  final status = _statusKey(request);
  return status == 'pending' || status == 'under_review';
}

class _InstallationApplicationCard extends StatefulWidget {
  const _InstallationApplicationCard({
    required this.request,
    required this.onEdit,
    required this.onCancel,
  });

  final InstallationApplicationModel request;
  final VoidCallback onEdit;
  final VoidCallback onCancel;

  @override
  State<_InstallationApplicationCard> createState() =>
      _InstallationApplicationCardState();
}

class _InstallationApplicationCardState
    extends State<_InstallationApplicationCard> {
  bool _expanded = false;

  Color get _statusColor {
    switch (widget.request.status.toLowerCase().replaceAll(' ', '_')) {
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
    switch (widget.request.status.toLowerCase().replaceAll(' ', '_')) {
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
        return widget.request.status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = widget.request;
    final createdAt = request.createdAt == null
        ? null
        : DateFormat('yyyy.MM.dd HH:mm').format(request.createdAt!.toLocal());
    final canManage = _canManageRequest(request);
    final detail = request.packageDetail;

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
                        textHeightBehavior: const TextHeightBehavior(
                          applyHeightToFirstAscent: false,
                          applyHeightToLastDescent: false,
                        ),
                        style: AppTheme.caption(
                          color: _statusColor,
                          weight: FontWeight.w600,
                        ).copyWith(
                          fontSize: 10,
                          height: 1,
                          leadingDistribution: TextLeadingDistribution.even,
                        ),
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
                _TicketRow(ticketNumber: request.ticketNumber),
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  alignment: Alignment.topCenter,
                  child: _expanded
                      ? Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Column(
                            children: [
                              _RequestDetail(
                                label: 'installationApplication.service_type'.tr(),
                                value: _serviceLabel(request.serviceType),
                              ),
                              _RequestDetail(
                                label: 'installationApplication.package'.tr(),
                                value: request.productName ?? '',
                              ),
                              _RequestDetail(
                                label:
                                    'installationApplication.internet_speed'.tr(),
                                value: _speedLabel(detail?['product_speed']),
                              ),
                              if (request.note?.trim().isNotEmpty == true)
                                _RequestDetail(
                                  label: 'installationApplication.note'.tr(),
                                  value: request.note!,
                                ),
                              _RequestDetail(
                                label:
                                    'installationApplication.billing_period'.tr(),
                                value: _periodLabel(detail),
                              ),
                              _RequestDetail(
                                label: 'installationApplication.network_provider'
                                    .tr(),
                                value: detail?['product_line']?.toString() ?? '',
                              ),
                              _RequestDetail(
                                label:
                                    'installationApplication.package_price'.tr(),
                                value: _pointsLabel(detail?['product_price']),
                              ),
                              _RequestDetail(
                                label: 'installationApplication.installation_fee'
                                    .tr(),
                                value: _pointsLabel(detail?['installation_fee']),
                              ),
                              _RequestDetail(
                                label: 'installationApplication.id_name'.tr(),
                                value: request.name,
                              ),
                              _RequestDetail(
                                label: 'installationApplication.address'.tr(),
                                value: request.address ?? '',
                              ),
                              _RequestDetail(
                                label: 'installationApplication.phone'.tr(),
                                value: request.phone,
                              ),
                            ],
                          ),
                        )
                      : const SizedBox(width: double.infinity),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
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
                    if (canManage) ...[
                      const Spacer(),
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
                      const SizedBox(width: 8),
                      Tooltip(
                        message: 'installationApplication.cancel_action'.tr(),
                        child: _CardActionButton(
                          onPressed: widget.onCancel,
                          icon: LucideIcons.trash,
                          color: AppColors.error,
                          background: const Color(0xFFF8E8E6),
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

String _serviceLabel(String? type) {
  if (type == null || type.trim().isEmpty) return '';
  if (type == 'CG') return 'installationApplication.cg_router'.tr();
  return type;
}

String _periodLabel(Map<String, dynamic>? detail) {
  final cycle = int.tryParse('${detail?['month_cycle']}') ?? 0;
  if (cycle <= 0) return '';
  final unit = detail?['month_cycle_unit']?.toString() ?? '';
  final isDay = unit.contains('天');
  if (isDay) {
    return cycle == 1
        ? 'installationApplication.period_day_1'.tr()
        : 'installationApplication.period_day_n'.tr(
            namedArgs: {'count': '$cycle'},
          );
  }
  if (cycle == 1) return 'installationApplication.period_1'.tr();
  return 'installationApplication.period_n'.tr(
    namedArgs: {'count': '$cycle'},
  );
}

String _speedLabel(Object? speed) {
  final match = RegExp(r'\d+').firstMatch(speed?.toString() ?? '');
  final mbps = match?.group(0);
  if (mbps == null || mbps.isEmpty) return '';
  return 'installationApplication.speed_mbps'.tr(namedArgs: {'speed': mbps});
}

String _pointsLabel(Object? value) {
  if (value == null) return '';
  final amount = value is num ? value.toDouble() : double.tryParse('$value');
  if (amount == null) return '';
  return '${NumberFormat('#,##0').format(amount)} ${'topup.pts'.tr()}';
}

class _CardActionButton extends StatelessWidget {
  const _CardActionButton({
    required this.icon,
    required this.onPressed,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          width: 26,
          height: 24,
          child: Icon(icon, size: 14, color: color),
        ),
      ),
    );
  }
}

class _TicketRow extends StatelessWidget {
  const _TicketRow({required this.ticketNumber});

  final String? ticketNumber;

  @override
  Widget build(BuildContext context) {
    final ticket = ticketNumber?.trim() ?? '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 108,
            child: Text(
              'installationApplication.ticket_number'.tr(),
              style: AppTheme.caption(),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: ticket.isEmpty
                  ? Text(
                      '—',
                      style: AppTheme.body(
                        weight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ).copyWith(fontSize: 12),
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        ticket,
                        textAlign: TextAlign.right,
                        style: AppTheme.body(
                          weight: FontWeight.w500,
                          color: AppColors.primary,
                        ).copyWith(fontSize: 12),
                      ),
                    ),
            ),
          ),
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 108,
            child: Text(label, style: AppTheme.caption()),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTheme.body(
                weight: FontWeight.w500,
                color: AppColors.textPrimary,
              ).copyWith(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
