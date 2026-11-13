import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../components/account_number_row/account_number_row.dart';
import '../../../components/app_add_floating_action_button/app_add_floating_action_button.dart';
import '../../../components/request_ticket_card/request_ticket_card.dart';
import '../../../components/app_button/app_button.dart';
import '../../../components/app_card/app_card.dart';
import '../../../components/app_curved_scaffold/app_curved_scaffold.dart';
import '../../../components/app_dialog/app_dialog.dart';
import '../../../components/app_input/app_input.dart';
import '../../../core/network/message_codes.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import '../../../core/theme/app_style/app_style.dart';
import '../../../core/theme/app_theme/app_theme.dart';
import '../../../core/utils/api_field_error.dart';
import '../../../core/utils/date_time_format.dart';
import '../../../core/utils/loading_helper.dart';
import '../../../core/utils/max_length_limiter.dart';
import '../../../core/utils/phone_number.dart';
import '../../../data/requests/change_wifi_password/change_wifi_password_repository.dart';
import '../../../models/requests/change_password/change_password_model.dart';
import '../../../models/user_model/user_model.dart';
import '../../home/home/bound_broadband.dart';
import '../../home/home/bound_broadband_provider.dart';
import '../../profile/profile/profile_controller.dart';
import 'change_wifi_password_controller.dart';

bool _isUnderReviewStatus(String status) {
  final normalized =
      status.toLowerCase().trim().replaceAll(' ', '_').replaceAll('-', '_');
  return normalized == 'under_review' ||
      normalized == 'pending' ||
      normalized == 'review';
}

String _loadErrorMessage(String? errorMessage) {
  if (errorMessage == null) return 'change_wifi.cancel_error'.tr();
  if (errorMessage.startsWith('change_wifi.') ||
      errorMessage.startsWith('api.') ||
      errorMessage.startsWith('common.')) {
    return errorMessage.tr();
  }
  return errorMessage;
}

class ChangeWifiPasswordPage extends ConsumerStatefulWidget {
  const ChangeWifiPasswordPage({super.key});

  @override
  ConsumerState<ChangeWifiPasswordPage> createState() =>
      _ChangeWifiPasswordPageState();
}

class _ChangeWifiPasswordPageState extends ConsumerState<ChangeWifiPasswordPage>
    with WidgetsBindingObserver {
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
        final account =
            (next?.account ?? ref.read(profileControllerProvider).accountNumber)
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
    final fetch =
        ref.read(changeWifiPasswordControllerProvider.notifier).fetchRequests(
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

  Future<void> _fetchRequests() => _loadRequests(refreshProfile: true);

  void _openNewRequestPage({ChangePasswordRequestModel? request}) {
    Navigator.of(context)
        .push<Object?>(
      MaterialPageRoute<Object?>(
        builder: (_) => _NewRequestFormSheet(request: request),
      ),
    )
        .then((result) async {
      if (!mounted || result == null || result == false) return;

      if (result is ChangeWifiPasswordSaveResult) {
        await showAppSuccessModal(
          context,
          title: request == null
              ? 'change_wifi.submitted_title'.tr()
              : 'common.success'.tr(),
          body: MessageCodes.featureReqKey(
            feature: 'change_wifi',
            code: result.code,
            fallbackKey: request == null
                ? 'change_wifi.submitted_desc'
                : 'change_wifi.update_success',
          ).tr(),
        );
      }
    });
  }

  Future<void> _confirmCancel(ChangePasswordRequestModel request) async {
    final confirmed = await showAppConfirmModal(
      context,
      title: 'change_wifi.cancel_title'.tr(),
      body: 'change_wifi.cancel_confirm'.tr(),
      confirmLabel: 'common.confirm'.tr(),
      cancelLabel: 'common.no'.tr(),
    );
    if (confirmed != true || !mounted) return;

    final result = await ref
        .read(changeWifiPasswordControllerProvider.notifier)
        .cancelRequest(request);
    if (!mounted) return;

    if (result == null) {
      final errorMessage =
          ref.read(changeWifiPasswordControllerProvider).errorMessage;
      await showAppFailureModal(
        context,
        title: 'common.error'.tr(),
        body: _loadErrorMessage(errorMessage),
      );
      return;
    }

    await showAppSuccessModal(
      context,
      title: 'common.success'.tr(),
      body: MessageCodes.featureReqKey(
        feature: 'change_wifi',
        code: result.code,
        fallbackKey: 'change_wifi.req_cancelled',
      ).tr(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = 'change_wifi.title'.tr();
    final state = ref.watch(changeWifiPasswordControllerProvider);
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
    final hasUnderReviewRequest =
        requests.any((request) => _isUnderReviewStatus(request.status));

    return AppCurvedScaffold(
      title: Text(
        title,
        style: AppTheme.topBarTitle(),
      ),
      showBack: true,
      floatingActionButton: hasUnderReviewRequest
          ? null
          : AppAddFloatingActionButton(
              onPressed: _openNewRequestPage,
            ),
      body: RefreshIndicator(
        onRefresh: _fetchRequests,
        child: _buildBody(state, requests),
      ),
    );
  }

  Widget _buildBody(
    ChangeWifiPasswordState state,
    List<ChangePasswordRequestModel> requests,
  ) {
    if (state.status == ChangeWifiPasswordStatus.loading && requests.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
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
                    Color(0xFFF25912),
                    BlendMode.srcIn,
                  ),
                  child: Image.asset(
                    'assets/images/services/change_wifi.png',
                    width: 36,
                    height: 36,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                ),
                const SizedBox(height: AppStyle.spaceMd),
                Text(
                  'change_wifi.no_requests'.tr(),
                  style: AppTheme.sectionTitle(color: AppColors.primary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppStyle.spaceXs),
                Text(
                  'change_wifi.no_requests_desc'.tr(),
                  textAlign: TextAlign.center,
                  style: AppTheme.bodySecondary(),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppStyle.spaceLg,
        AppStyle.spaceLg,
        AppStyle.spaceLg,
        80,
      ),
      itemCount: requests.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppStyle.spaceSm),
      itemBuilder: (context, index) {
        final request = requests[index];
        return _RequestItemCard(
          item: request,
          onEdit: _isUnderReviewStatus(request.status)
              ? () => _openNewRequestPage(request: request)
              : null,
          onCancel: _isUnderReviewStatus(request.status)
              ? () => _confirmCancel(request)
              : null,
        );
      },
    );
  }
}

class _RequestItemCard extends StatefulWidget {
  const _RequestItemCard({
    required this.item,
    this.onEdit,
    this.onCancel,
  });

  final ChangePasswordRequestModel item;
  final VoidCallback? onEdit;
  final VoidCallback? onCancel;

  @override
  State<_RequestItemCard> createState() => _RequestItemCardState();
}

class _RequestItemCardState extends State<_RequestItemCard> {
  Color _statusColor(String status) {
    switch (_normalizeStatus(status)) {
      case 'under_review':
      case 'review':
      case 'pending':
      case 'processing':
      case 'in_progress':
      case 'submitted':
        return AppColors.warning;
      case 'approved':
      case 'completed':
      case 'active':
        return AppColors.success;
      case 'cancelled':
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.textMuted;
    }
  }

  String _statusLabel(String status) {
    switch (_normalizeStatus(status)) {
      case 'under_review':
      case 'review':
      case 'pending':
      case 'processing':
      case 'in_progress':
      case 'submitted':
        return 'change_wifi.status_under_review'.tr();
      case 'approved':
        return 'change_wifi.status_approved'.tr();
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

  String _normalizeStatus(String status) =>
      status.toLowerCase().trim().replaceAll(' ', '_').replaceAll('-', '_');

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final statusColor = _statusColor(item.status);

    final dateStr = item.createdAt == null
        ? null
        : formatDate(item.createdAt!.toLocal().toIso8601String());

    return RequestTicketCard(
      statusLabel: _statusLabel(item.status),
      statusColor: statusColor,
      ticketNumber: item.ticketNumber,
      createdAt: dateStr,
      onEdit: widget.onEdit,
      onCancel: widget.onCancel,
      details: [
        if (item.broadbandAccountNumber?.isNotEmpty == true)
          _buildDetailRow(
            'change_wifi.account_number'.tr(),
            item.broadbandAccountNumber!,
          ),
        _buildDetailRow(
          'requests.contact_name'.tr(),
          item.contactName,
        ),
        _buildDetailRow(
          'requests.phone'.tr(),
          UserProfileModel.formatLocalPhone(item.contactPhone),
        ),
        if (item.newWifiName?.isNotEmpty == true)
          _buildDetailRow(
            'change_wifi.new_wifi_name_hint'.tr(),
            item.newWifiName!,
          ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
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

class _WifiNameCheck extends StatelessWidget {
  const _WifiNameCheck({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 18,
      height: 18,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : AppColors.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.border,
          width: 1.5,
        ),
      ),
      child: selected
          ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
          : null,
    );
  }
}

class _NewRequestFormSheet extends ConsumerStatefulWidget {
  const _NewRequestFormSheet({this.request});

  final ChangePasswordRequestModel? request;

  @override
  ConsumerState<_NewRequestFormSheet> createState() =>
      __NewRequestFormSheetState();
}

class __NewRequestFormSheetState extends ConsumerState<_NewRequestFormSheet>
    with ApiFieldErrorsMixin<_NewRequestFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _broadbandAccountFieldKey = GlobalKey<FormFieldState<String>>();
  final _contactNameFieldKey = GlobalKey<FormFieldState<String>>();
  final _phoneFieldKey = GlobalKey<FormFieldState<String>>();
  final _passwordFieldKey = GlobalKey<FormFieldState<String>>();
  final _wifiNameFieldKey = GlobalKey<FormFieldState<String>>();

  late final TextEditingController _broadbandAccountController;
  late final TextEditingController _contactNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _wifiNameController;
  late final TextEditingController _passwordController;
  late final ProviderSubscription<BoundBroadband?> _accountSubscription;
  late String _formAccountNumber;

  late bool _isChangingWifiName;
  bool _obscurePassword = true;

  String _requiredMessage(String fieldKey) {
    return 'requests.required_field'.tr(namedArgs: {'field': fieldKey.tr()});
  }

  String? _validateContactPhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return _requiredMessage('requests.phone');
    }
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 8) return 'login.phone_invalid'.tr();

    final normalized = PhoneNumber.normalize(value);
    if (normalized == null || !PhoneNumber.isSupported(normalized)) {
      return 'login.phone_invalid'.tr();
    }
    return apiFieldError('contact_phone');
  }

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileControllerProvider);
    final boundAccount = ref.read(boundBroadbandProvider)?.account;
    final request = widget.request;
    _formAccountNumber = (request?.broadbandAccountNumber ??
            boundAccount ??
            profile.accountNumber)
        .trim();
    _broadbandAccountController = TextEditingController(
      text: request?.broadbandAccountNumber ?? _formAccountNumber,
    );
    _contactNameController = TextEditingController(
      text: request?.contactName ??
          (profile.fullName.isNotEmpty ? profile.fullName : 'Customer'),
    );
    _phoneController = TextEditingController(
      text: request == null
          ? profile.displayPhone
          : UserProfileModel.formatLocalPhone(request.contactPhone),
    );
    _wifiNameController = TextEditingController(text: request?.newWifiName);
    _passwordController = TextEditingController(text: request?.newPassword);
    _isChangingWifiName = request?.newWifiName?.trim().isNotEmpty == true;
    _accountSubscription = ref.listenManual(
      boundBroadbandProvider,
      (_, next) {
        final account =
            (next?.account ?? ref.read(profileControllerProvider).accountNumber)
                .trim();
        if (account == _formAccountNumber) return;
        _formAccountNumber = account;
        if (widget.request != null) {
          Navigator.of(context).maybePop();
          return;
        }
        _clearFormForAccount(account);
      },
    );
  }

  void _clearFormForAccount(String account) {
    clearAllApiFieldErrors();
    _formKey.currentState?.reset();
    _broadbandAccountController.text = account;
    _contactNameController.clear();
    _phoneController.clear();
    _wifiNameController.clear();
    _passwordController.clear();
    setState(() {
      _isChangingWifiName = false;
      _obscurePassword = true;
    });
  }

  @override
  void dispose() {
    _accountSubscription.close();
    _broadbandAccountController.dispose();
    _contactNameController.dispose();
    _phoneController.dispose();
    _wifiNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    clearAllApiFieldErrors();
    if (!_formKey.currentState!.validate()) return;

    final profile = ref.read(profileControllerProvider);
    final inputAccount = _broadbandAccountController.text.trim();
    final boundAccount = inputAccount.isNotEmpty
        ? inputAccount
        : ref.read(boundBroadbandProvider)?.account ?? profile.accountNumber;
    final userId = int.tryParse(profile.id) ?? 0;
    final normalizedPhone = PhoneNumber.normalize(_phoneController.text);
    if (normalizedPhone == null || !PhoneNumber.isSupported(normalizedPhone)) {
      return;
    }

    final notifier = ref.read(changeWifiPasswordControllerProvider.notifier);
    final ChangeWifiPasswordSaveResult? savedResult;
    try {
      savedResult = await LoadingHelper.runWithLoading(
        () => widget.request == null
            ? notifier.submitRequest(
                broadbandAccount: boundAccount,
                contactName: _contactNameController.text.trim(),
                contactPhone: normalizedPhone,
                newPassword: _passwordController.text.trim(),
                newWifiName: _isChangingWifiName
                    ? _wifiNameController.text.trim()
                    : null,
                userId: userId,
              )
            : notifier.updateRequest(
                request: widget.request!,
                broadbandAccount: boundAccount,
                contactName: _contactNameController.text.trim(),
                contactPhone: normalizedPhone,
                newPassword: _passwordController.text.trim(),
                newWifiName: _isChangingWifiName
                    ? _wifiNameController.text.trim()
                    : null,
              ),
      );
    } catch (error) {
      if (!mounted) return;
      final profile = ref.read(profileControllerProvider);
      final handledInline = handleApiError(
        error,
        fields: {
          if (profile.accountNumber.isEmpty)
            'broadband_account_number': _broadbandAccountFieldKey,
          'contact_name': _contactNameFieldKey,
          'contact_phone': _phoneFieldKey,
          'new_password': _passwordFieldKey,
          if (_isChangingWifiName) 'new_wifi_name': _wifiNameFieldKey,
        },
      );
      if (!handledInline) {
        await showApiErrorModal(context, error);
      }
      return;
    }

    if (!mounted) return;

    if (savedResult != null) {
      Navigator.of(context).pop(savedResult);
      return;
    }

    final errorMessage =
        ref.read(changeWifiPasswordControllerProvider).errorMessage;
    if (errorMessage != null) {
      await showAppFailureModal(
        context,
        title: 'common.error'.tr(),
        body: _loadErrorMessage(errorMessage),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileControllerProvider);
    final controllerState = ref.watch(changeWifiPasswordControllerProvider);
    final requestAccount = widget.request?.broadbandAccountNumber?.trim() ?? '';
    final boundAccount =
        ref.watch(boundBroadbandProvider)?.account.trim() ?? '';
    final accountNumber = requestAccount.isNotEmpty
        ? requestAccount
        : boundAccount.isNotEmpty
            ? boundAccount
            : profile.accountNumber.trim();

    if (accountNumber.isNotEmpty &&
        _broadbandAccountController.text != accountNumber) {
      _broadbandAccountController.text = accountNumber;
    }
    if ((_contactNameController.text.isEmpty ||
            _contactNameController.text == 'Customer') &&
        profile.fullName.isNotEmpty) {
      _contactNameController.text = profile.fullName;
    }
    if (_phoneController.text.isEmpty && profile.phone.isNotEmpty) {
      _phoneController.text = profile.displayPhone;
    }

    return AppCurvedScaffold(
      title: Text(
        'change_wifi.title'.tr(),
        style: AppTheme.topBarTitle(),
      ),
      showBack: true,
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: AppColors.background,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppCard(
                        elevated: false,
                        bordered: false,
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Transform.translate(
                                  offset: const Offset(0, -1),
                                  child: Image.asset(
                                    'assets/images/services/info.png',
                                    width: 23,
                                    height: 23,
                                    fit: BoxFit.contain,
                                    filterQuality: FilterQuality.high,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'change_wifi.form_desc'.tr(),
                                    style: AppTheme.body(
                                      weight: FontWeight.w600,
                                    ).copyWith(
                                      fontSize: 13,
                                      height: 22 / 13,
                                      leadingDistribution:
                                          TextLeadingDistribution.even,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (accountNumber.isNotEmpty)
                              AccountNumberRow(
                                label: 'change_wifi.broadband_account'.tr(),
                                value: _broadbandAccountController.text,
                              )
                            else
                              AppInput(
                                controller: _broadbandAccountController,
                                label:
                                    '${'change_wifi.broadband_account'.tr()} *',
                                prefixIcon: LucideIcons.id_card,
                                formFieldKey: _broadbandAccountFieldKey,
                                maxLength: 30,
                                inputFormatters: [maxLengthLimiter(30)],
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return _requiredMessage(
                                      'change_wifi.broadband_account',
                                    );
                                  }
                                  return apiFieldError(
                                    'broadband_account_number',
                                  );
                                },
                                onChanged: (_) => clearApiFieldError(
                                  'broadband_account_number',
                                  key: _broadbandAccountFieldKey,
                                ),
                              ),
                            const SizedBox(height: 16),
                            AppInput(
                              controller: _contactNameController,
                              label: '${'requests.contact_name'.tr()} *',
                              hint: 'requests.contact_name_hint'.tr(),
                              prefixIcon: LucideIcons.user,
                              formFieldKey: _contactNameFieldKey,
                              maxLength: 30,
                              inputFormatters: [maxLengthLimiter(30)],
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return _requiredMessage(
                                    'requests.contact_name',
                                  );
                                }
                                return apiFieldError('contact_name');
                              },
                              onChanged: (_) => clearApiFieldError(
                                'contact_name',
                                key: _contactNameFieldKey,
                              ),
                            ),
                            const SizedBox(height: AppStyle.spaceXs),
                            AppInput(
                              controller: _phoneController,
                              label: '${'requests.phone'.tr()} *',
                              hint: 'requests.phone_hint'.tr(),
                              keyboardType: TextInputType.phone,
                              prefixIcon: LucideIcons.phone,
                              formFieldKey: _phoneFieldKey,
                              maxLength: 16,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                maxLengthLimiter(16),
                              ],
                              validator: _validateContactPhone,
                              onChanged: (_) => clearApiFieldError(
                                'contact_phone',
                                key: _phoneFieldKey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            width: 3,
                            height: 14,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'change_wifi.wifi_title'.tr(),
                              style: AppTheme.body(weight: FontWeight.w700)
                                  .copyWith(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      AppCard(
                        elevated: false,
                        bordered: false,
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AppInput(
                              controller: _passwordController,
                              label: '${'change_wifi.req_new_password'.tr()} *',
                              hint: 'change_wifi.new_password_hint'.tr(),
                              obscureText: _obscurePassword,
                              prefixIcon: LucideIcons.lock,
                              formFieldKey: _passwordFieldKey,
                              maxLength: 30,
                              inputFormatters: [maxLengthLimiter(30)],
                              suffix: AppInput.iconChip(
                                icon: _obscurePassword
                                    ? LucideIcons.eye_off
                                    : LucideIcons.eye,
                                onTap: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              validator: (v) {
                                final password = v?.trim() ?? '';
                                if (password.isEmpty) {
                                  return _requiredMessage(
                                    'change_wifi.new_password_hint',
                                  );
                                }
                                if (password.isNotEmpty &&
                                    password.length < 8) {
                                  return 'change_wifi.password_min_length'.tr();
                                }
                                if (password.length > 30) {
                                  return 'change_wifi.password_max_length'.tr();
                                }
                                return apiFieldError('new_password');
                              },
                              onChanged: (_) => clearApiFieldError(
                                'new_password',
                                key: _passwordFieldKey,
                              ),
                            ),
                            const SizedBox(height: AppStyle.spaceXs),
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                setState(() {
                                  _isChangingWifiName = !_isChangingWifiName;
                                  clearApiFieldError(
                                    'new_wifi_name',
                                    key: _wifiNameFieldKey,
                                  );
                                });
                              },
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  _WifiNameCheck(
                                    selected: _isChangingWifiName,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'change_wifi.wifi_name_optional'.tr(),
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: _isChangingWifiName
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                        height: 1.3,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (_isChangingWifiName) ...[
                              AppInput(
                                controller: _wifiNameController,
                                label:
                                    '${'change_wifi.req_new_wifi_name'.tr()} *',
                                hint: 'change_wifi.new_wifi_name_hint'.tr(),
                                prefixIcon: LucideIcons.wifi,
                                formFieldKey: _wifiNameFieldKey,
                                maxLines: 2,
                                maxLength: 30,
                                inputFormatters: [maxLengthLimiter(30)],
                                validator: (v) {
                                  if (_isChangingWifiName &&
                                      (v == null || v.trim().isEmpty)) {
                                    return _requiredMessage(
                                      'change_wifi.new_wifi_name_hint',
                                    );
                                  }
                                  return apiFieldError('new_wifi_name');
                                },
                                onChanged: (_) => clearApiFieldError(
                                  'new_wifi_name',
                                  key: _wifiNameFieldKey,
                                ),
                              ),
                              const SizedBox(height: AppStyle.spaceXs),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: AppStyle.spaceMd),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Container(
            color: AppColors.background,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: AppButton(
                    label: widget.request != null
                        ? 'common.save'.tr()
                        : 'common.submit'.tr() != 'common.submit'
                            ? 'common.submit'.tr()
                            : 'Submit',
                    isLoading: controllerState.isSubmitting,
                    onPressed:
                        controllerState.isSubmitting ? null : _submitForm,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
