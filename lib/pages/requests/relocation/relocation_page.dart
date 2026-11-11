import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../components/app_add_floating_action_button/app_add_floating_action_button.dart';
import '../../../components/request_ticket_card/request_ticket_card.dart';
import '../../../components/app_card/app_card.dart';
import '../../../components/app_curved_scaffold/app_curved_scaffold.dart';
import '../../../components/app_dialog/app_dialog.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import '../../../core/theme/app_style/app_style.dart';
import '../../../core/theme/app_theme/app_theme.dart';
import '../../../core/utils/date_time_format.dart';
import '../../../core/network/message_codes.dart';
import '../../../data/requests/relocation/relocation_repository.dart';
import '../../../models/requests/relocation/relocation_request_model.dart';
import '../../profile/profile/profile_controller.dart';
import 'relocation_controller.dart';
import 'relocation_form_page.dart';

class RelocationPage extends ConsumerStatefulWidget {
  const RelocationPage({super.key});

  @override
  ConsumerState<RelocationPage> createState() => _RelocationPageState();
}

class _RelocationPageState extends ConsumerState<RelocationPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(profileControllerProvider.notifier).fetchProfile();
      ref.read(relocationControllerProvider.notifier).fetchRequests();
    });
  }

  Future<void> _refresh() =>
      ref.read(relocationControllerProvider.notifier).fetchRequests();

  Future<void> _openForm([RelocationRequestModel? request]) async {
    final result = await Navigator.of(context).push<RelocationSaveResult>(
      MaterialPageRoute<RelocationSaveResult>(
        builder: (_) => RelocationFormPage(request: request),
      ),
    );

    if (!mounted || result == null) return;

    await showAppSuccessModal(
      context,
      title: 'common.success'.tr(),
      body: MessageCodes.featureReqKey(
        feature: 'relocation',
        code: result.code,
        fallbackKey: request == null
            ? 'relocation.submit_success_body'
            : 'relocation.update_success',
      ).tr(),
    );
  }

  Future<void> _confirmAction({
    required RelocationRequestModel request,
  }) async {
    final confirmed = await showAppConfirmModal(
      context,
      title: 'relocation.cancel_title'.tr(),
      body: 'relocation.cancel_confirm'.tr(),
      confirmLabel: 'common.confirm'.tr(),
      cancelLabel: 'common.no'.tr(),
    );
    if (confirmed != true) return;

    final controller = ref.read(relocationControllerProvider.notifier);
    final code = await controller.cancelRequest(request.id);
    if (!mounted) return;

    if (code == null) {
      final state = ref.read(relocationControllerProvider);
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
      body: MessageCodes.featureReqKey(
        feature: 'relocation',
        code: code,
        fallbackKey: 'relocation.req_cancelled',
      ).tr(),
    );
  }

  String _localizedError(String? message) {
    if (message == null) return 'common.error'.tr();
    if (MessageCodes.isKnown(message)) {
      return MessageCodes.locKey(message).tr();
    }
    if (message.startsWith('relocation.') ||
        message.startsWith('api.') ||
        message.startsWith('common.')) {
      return message.tr();
    }
    return message;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(relocationControllerProvider);
    final canSubmitNewRequest = !state.requests.any(_canManageRequest);

    return AppCurvedScaffold(
      title: Text(
        'home.service_alerts'.tr(),
        style: AppTheme.topBarTitle(),
      ),
      showBack: true,
      floatingActionButton: canSubmitNewRequest
          ? AppAddFloatingActionButton(onPressed: () => _openForm())
          : null,
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _buildBody(state),
      ),
    );
  }

  Widget _buildBody(RelocationState state) {
    if (state.status == RelocationStatus.loading && state.requests.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (state.status == RelocationStatus.error && state.requests.isEmpty) {
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
                    const Color(0xFF1B4EF5),
                    BlendMode.srcIn,
                  ),
                  child: Image.asset(
                    'assets/images/services/relocation.png',
                    width: 36,
                    height: 36,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                ),
                const SizedBox(height: AppStyle.spaceMd),
                Text(
                  'relocation.no_requests'.tr(),
                  style: AppTheme.sectionTitle(color: AppColors.primary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppStyle.spaceXs),
                Text(
                  'relocation.no_requests_desc'.tr(),
                  textAlign: TextAlign.center,
                  style: AppTheme.bodySecondary(),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final hasError =
        state.status == RelocationStatus.error && state.errorMessage != null;
    final underReview = state.requests
        .where((request) =>
            _statusKey(request) == 'pending' ||
            _statusKey(request) == 'under_review')
        .toList();
    final approved = state.requests
        .where((request) => _statusKey(request) == 'approved')
        .toList();
    final closed = state.requests
        .where((request) =>
            _statusKey(request) == 'cancelled' ||
            _statusKey(request) == 'rejected')
        .toList();

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
        ..._relocationCards(
          [...underReview, ...approved, ...closed],
          (request) => _RelocationRequestCard(
            request: request,
            onEdit: () => _openForm(request),
            onCancel: () => _confirmAction(request: request),
          ),
        ),
      ],
    );
  }
}

String _statusKey(RelocationRequestModel request) =>
    request.status.toLowerCase().replaceAll(' ', '_');

bool _canManageRequest(RelocationRequestModel request) {
  final status = _statusKey(request);
  return status == 'pending' || status == 'under_review';
}

List<Widget> _relocationCards(
  List<RelocationRequestModel> requests,
  Widget Function(RelocationRequestModel request) cardFor,
) {
  return [
    for (var index = 0; index < requests.length; index++) ...[
      cardFor(requests[index]),
      if (index != requests.length - 1)
        const SizedBox(height: AppStyle.spaceSm),
    ],
  ];
}

class _RelocationRequestCard extends StatefulWidget {
  const _RelocationRequestCard({
    required this.request,
    required this.onEdit,
    required this.onCancel,
  });

  final RelocationRequestModel request;
  final VoidCallback onEdit;
  final VoidCallback onCancel;

  @override
  State<_RelocationRequestCard> createState() => _RelocationRequestCardState();
}

class _RelocationRequestCardState extends State<_RelocationRequestCard> {
  bool get _canManage {
    return _canManageRequest(widget.request);
  }

  Color get _statusColor {
    switch (_statusKey(widget.request)) {
      case 'pending':
      case 'under_review':
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
    switch (_statusKey(widget.request)) {
      case 'pending':
      case 'under_review':
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
        : formatDate(
            request.createdAt!.toLocal().toIso8601String(),
          );
    final preferredDate = request.preferredDate == null
        ? null
        : formatDate(
            request.preferredDate!.toLocal().toIso8601String(),
          );

    return RequestTicketCard(
      statusLabel: _statusLabel,
      statusColor: _statusColor,
      ticketNumber: request.ticketNumber,
      createdAt: createdAt,
      onEdit: _canManage ? widget.onEdit : null,
      onCancel: _canManage ? widget.onCancel : null,
      cancelTooltip: 'relocation.cancel_action'.tr(),
      details: [
        if (request.broadbandAccountNumber?.trim().isNotEmpty == true)
          _RelocationDetail(
            label: 'requests.broadband_account'.tr(),
            value: request.broadbandAccountNumber!,
          ),
        _RelocationDetail(
          label: 'requests.contact_name'.tr(),
          value: request.contactName,
        ),
        _RelocationDetail(
          label: 'requests.phone'.tr(),
          value: request.phone,
        ),
        _RelocationDetail(
          label: 'relocation.current_address'.tr(),
          value: request.currentAddress,
        ),
        _RelocationDetail(
          label: 'relocation.new_address'.tr(),
          value: request.newAddress,
        ),
        if (preferredDate != null)
          _RelocationDetail(
            label: 'relocation.preferred_date'.tr(),
            value: preferredDate,
          ),
        if (request.details?.trim().isNotEmpty == true)
          _RelocationDetail(
            label: 'requests.note'.tr(),
            value: request.details!,
          ),
      ],
    );
  }
}

class _RelocationDetail extends StatelessWidget {
  const _RelocationDetail({
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
            child: Text(
              label,
              style: AppTheme.caption().copyWith(fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTheme.body(
                weight: FontWeight.w500,
                color: AppColors.textPrimary,
              ).copyWith(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
