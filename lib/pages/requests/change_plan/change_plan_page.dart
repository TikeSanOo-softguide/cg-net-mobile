import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../components/app_refresh_indicator/app_refresh_indicator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../components/app_add_floating_action_button/app_add_floating_action_button.dart';
import '../../../components/shimmer_loading/shimmer_loading.dart';
import '../../../components/request_ticket_card/request_ticket_card.dart';
import '../../../components/app_card/app_card.dart';
import '../../../components/app_curved_scaffold/app_curved_scaffold.dart';
import '../../../components/app_dialog/app_dialog.dart';
import '../../../core/network/message_codes.dart';
import '../../../core/router/slide_page.dart';
import '../../../core/utils/loading_helper.dart';
import '../request_detail_page.dart';
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
      SlidePageRoute<Object?>(
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
      title: 'common.cancel_ask'.tr(),
      body: 'changePlan.cancel_confirm'.tr(),
      confirmLabel: 'common.confirm'.tr(),
      cancelLabel: 'common.no'.tr(),
    );
    if (confirmed != true) return;

    final code = await LoadingHelper.runWithLoading(
      () => ref.read(changePlanControllerProvider.notifier).cancelRequest(request.id),
    );
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
      body: AppRefreshIndicator(
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
      return const CardListShimmer();
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
        AppStyle.listPaddingAboveFab,
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
          if (i != items.length - 1) const SizedBox(height: 2),
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

class _ChangePlanCard extends StatelessWidget {
  const _ChangePlanCard({required this.request, this.onEdit, this.onCancel});

  final ChangePlanRequestModel request;
  final VoidCallback? onEdit;
  final VoidCallback? onCancel;

  Color get _statusColor {
    switch (_statusKey(request)) {
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
    switch (_statusKey(request)) {
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
        return request.status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final createdAt = request.createdAt == null
        ? null
        : formatDate(request.createdAt!.toUtc().toIso8601String());
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
      onEdit: onEdit,
      onCancel: onCancel,
      onOpen: () => openRequestDetail(
        context,
        title: 'home.service_change_plan'.tr(),
        statusLabel: _statusLabel,
        statusColor: _statusColor,
        ticketNumber: request.ticketNumber,
        createdAt: createdAt,
        lines: [
          RequestDetailLine(
            label: 'installationApplication.service_type'.tr(),
            value: request.serviceType == 'CG'
                ? 'installationApplication.cg_router'.tr()
                : (request.serviceType ?? ''),
          ),
          RequestDetailLine(
            label: 'requests.contact_name'.tr(),
            value: request.contactName,
          ),
          RequestDetailLine(
            label: 'requests.phone'.tr(),
            value: UserProfileModel.formatLocalPhone(request.contactPhone),
          ),
          RequestDetailLine(
            label: 'changePlan.current_plan'.tr(),
            value: _packageLabel(request.currentPackageDetail),
          ),
          RequestDetailLine(
            label: 'changePlan.change_plan'.tr(),
            value: _packageLabel(request.newPackageDetail),
          ),
          RequestDetailLine(
            label: 'changePlan.preferred_date'.tr(),
            value: preferred,
          ),
          RequestDetailLine(
            label: 'requests.note'.tr(),
            value: request.note ?? '',
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
