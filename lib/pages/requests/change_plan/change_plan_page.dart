import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../components/app_add_floating_action_button/app_add_floating_action_button.dart';
import '../../../components/request_ticket_card/request_ticket_card.dart';
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
import '../../../models/user_model/user_model.dart';
import '../../home/home/bound_broadband.dart';
import '../../home/home/bound_broadband_provider.dart';
import '../../profile/profile/profile_controller.dart';
import 'change_plan_controller.dart';
import 'change_plan_form_page.dart';

class ChangePlanPage extends ConsumerStatefulWidget {
  const ChangePlanPage({super.key});

  @override
  ConsumerState<ChangePlanPage> createState() => _ChangePlanPageState();
}

class _ChangePlanPageState extends ConsumerState<ChangePlanPage>
    with WidgetsBindingObserver {
  static const _serviceTint = Color(0xFF7A0BC0);
  late final ProviderSubscription<BoundBroadband?> _accountSubscription;
  String _lastActiveAccount = '';
  String? _pendingFetchAccount;
  Future<void>? _pendingFetch;
  bool _initialFetchComplete = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lastActiveAccount = _activeAccountNumber();
    _accountSubscription = ref.listenManual(
      boundBroadbandProvider,
      (previous, next) {
        final account = (next?.account ??
                ref.read(profileControllerProvider).accountNumber)
            .trim();
        final serviceChanged = previous?.serviceType != next?.serviceType;
        if (account == _lastActiveAccount && !serviceChanged) return;
        _lastActiveAccount = account;
        if (!_initialFetchComplete) return;
        _fetchRequestsForAccount(account);
      },
    );
    Future.microtask(() {
      if (!mounted) return;
      _loadRequests(refreshProfile: true, completeInitialFetch: true);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _accountSubscription.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadRequests(refreshProfile: true);
    }
  }

  String _activeAccountNumber() {
    final boundAccount = ref.read(boundBroadbandProvider)?.account;
    return (boundAccount ?? ref.read(profileControllerProvider).accountNumber)
        .trim();
  }

  Future<void> _loadRequests({
    bool refreshProfile = false,
    bool completeInitialFetch = false,
  }) async {
    if (refreshProfile && ref.read(boundBroadbandProvider) == null) {
      await ref.read(profileControllerProvider.notifier).fetchProfile();
    }
    if (!mounted) return;
    final account = _activeAccountNumber();
    await _fetchRequestsForAccount(account);
    if (!mounted) return;
    _lastActiveAccount = account;
    if (completeInitialFetch) _initialFetchComplete = true;
  }

  Future<void> _fetchRequestsForAccount(String accountNumber) {
    if (_pendingFetchAccount == accountNumber && _pendingFetch != null) {
      return _pendingFetch!;
    }

    _pendingFetchAccount = accountNumber;
    final fetch = ref
        .read(changePlanControllerProvider.notifier)
        .fetchRequests(
          accountNumber: accountNumber.isEmpty ? null : accountNumber,
        );
    _pendingFetch = fetch;
    return fetch.whenComplete(() {
      if (identical(_pendingFetch, fetch)) {
        _pendingFetch = null;
        _pendingFetchAccount = null;
      }
    });
  }

  Future<void> _refresh() => _loadRequests(refreshProfile: true);

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
    final accountNumber = ref.watch(boundBroadbandProvider)?.account.trim() ??
        ref.watch(profileControllerProvider).accountNumber.trim();
    final requests = accountNumber.isEmpty
        ? state.requests
        : state.requests
            .where(
              (request) =>
                  request.broadbandAccountNumber?.trim().toUpperCase() ==
                  accountNumber.toUpperCase(),
            )
            .toList();
    final hasUnderReview = requests.any(_isUnderReview);

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
        child: _buildBody(state, requests),
      ),
    );
  }

  Widget _buildBody(
    ChangePlanState state,
    List<ChangePlanRequestModel> requests,
  ) {
    if (state.status == ChangePlanStatus.loading && requests.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (state.status == ChangePlanStatus.error && requests.isEmpty) {
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

    if (requests.isEmpty) {
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

    final items = requests;

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
        : formatDate(
            request.preferredDate!.toIso8601String().split('T').first,
          );

    return RequestTicketCard(
      statusLabel: _statusLabel,
      statusColor: _statusColor,
      ticketNumber: request.ticketNumber,
      createdAt: createdAt,
      onEdit: widget.onEdit,
      onCancel: widget.onCancel,
      details: [
        _DetailRow(
          label: 'installationApplication.service_type'.tr(),
          value: request.serviceType == 'CG'
              ? 'installationApplication.cg_router'.tr()
              : (request.serviceType ?? ''),
        ),
        _DetailRow(
          label: 'requests.contact_name'.tr(),
          value: request.contactName,
        ),
        _DetailRow(
          label: 'requests.phone'.tr(),
          value: UserProfileModel.formatLocalPhone(request.contactPhone),
        ),
        _DetailRow(
          label: 'changePlan.current_plan'.tr(),
          value: _packageLabel(request.currentPackageDetail),
        ),
        _DetailRow(
          label: 'changePlan.change_plan'.tr(),
          value: _packageLabel(request.newPackageDetail),
        ),
        _DetailRow(
          label: 'changePlan.preferred_date'.tr(),
          value: preferred,
        ),
        _DetailRow(
          label: 'requests.note'.tr(),
          value: request.note ?? '',
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
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
