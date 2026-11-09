import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
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
import '../../../core/network/api_message_modal.dart';
import '../../../core/network/message_codes.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import '../../../core/theme/app_style/app_style.dart';
import '../../../core/theme/app_theme/app_theme.dart';
import '../../../core/utils/date_time_format.dart';
import '../../../core/utils/loading_helper.dart';
import '../../../data/requests/change_wifi_password/change_wifi_password_repository.dart';
import '../../../models/requests/change_password/change_password_model.dart';
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

class _ChangeWifiPasswordPageState
    extends ConsumerState<ChangeWifiPasswordPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      ref.read(profileControllerProvider.notifier).fetchProfile();
      ref.read(changeWifiPasswordControllerProvider.notifier).fetchRequests();
    });
  }

  Future<void> _fetchRequests() async {
    await ref.read(profileControllerProvider.notifier).fetchProfile();
    await ref
        .read(changeWifiPasswordControllerProvider.notifier)
        .fetchRequests();
  }

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

      if (mounted) await _fetchRequests();
    });
  }

  Future<void> _confirmCancel(ChangePasswordRequestModel request) async {
    final confirmed = await showAppConfirmModal(
      context,
      title: 'change_wifi.cancel_title'.tr(),
      body: 'change_wifi.cancel_confirm'.tr(),
      cancelLabel: 'common.no'.tr(),
      confirmLabel: 'change_wifi.yes_cancel'.tr(),
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
        fallbackKey: 'change_wifi.cancel_success',
      ).tr(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = 'change_wifi.title'.tr();
    final requests = ref.watch(changeWifiPasswordControllerProvider).requests;
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
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    final state = ref.watch(changeWifiPasswordControllerProvider);
    final requests = state.requests;

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
          'change_wifi.contact_name'.tr(),
          item.contactName,
        ),
        _buildDetailRow(
          'change_wifi.contact_phone'.tr(),
          item.contactPhone,
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

class __NewRequestFormSheetState extends ConsumerState<_NewRequestFormSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _broadbandAccountController;
  late final TextEditingController _contactNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _wifiNameController;
  late final TextEditingController _passwordController;

  late bool _isChangingWifiName;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileControllerProvider);
    final request = widget.request;
    _broadbandAccountController = TextEditingController(
      text: request?.broadbandAccountNumber ?? profile.accountNumber,
    );
    _contactNameController = TextEditingController(
      text: request?.contactName ??
          (profile.fullName.isNotEmpty ? profile.fullName : 'Customer'),
    );
    _phoneController = TextEditingController(
      text: request?.contactPhone ?? profile.displayPhone,
    );
    _wifiNameController = TextEditingController(text: request?.newWifiName);
    _passwordController = TextEditingController(text: request?.newPassword);
    _isChangingWifiName = request?.newWifiName?.trim().isNotEmpty == true;
  }

  @override
  void dispose() {
    _broadbandAccountController.dispose();
    _contactNameController.dispose();
    _phoneController.dispose();
    _wifiNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final profile = ref.read(profileControllerProvider);
    final inputAccount = _broadbandAccountController.text.trim();
    final boundAccount =
        inputAccount.isNotEmpty ? inputAccount : profile.accountNumber;
    final userId = int.tryParse(profile.id) ?? 0;

    final notifier = ref.read(changeWifiPasswordControllerProvider.notifier);
    final ChangeWifiPasswordSaveResult? savedResult;
    try {
      savedResult = await LoadingHelper.runWithLoading(
        () => widget.request == null
            ? notifier.submitRequest(
                broadbandAccount: boundAccount,
                contactName: _contactNameController.text.trim(),
                contactPhone: _phoneController.text.trim(),
                newPassword: _passwordController.text.trim(),
                newWifiName:
                    _isChangingWifiName ? _wifiNameController.text.trim() : null,
                userId: userId,
              )
            : notifier.updateRequest(
                request: widget.request!,
                broadbandAccount: boundAccount,
                contactName: _contactNameController.text.trim(),
                contactPhone: _phoneController.text.trim(),
                newPassword: _passwordController.text.trim(),
                newWifiName:
                    _isChangingWifiName ? _wifiNameController.text.trim() : null,
              ),
      );
    } catch (error) {
      if (!mounted) return;
      await showApiMessageModal(context, error);
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

    if (profile.accountNumber.isNotEmpty &&
        _broadbandAccountController.text != profile.accountNumber) {
      _broadbandAccountController.text = profile.accountNumber;
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
                            if (profile.accountNumber.isNotEmpty)
                              AccountNumberRow(
                                label: 'change_wifi.broadband_account'.tr(),
                                value: _broadbandAccountController.text,
                              )
                            else
                              AppInput(
                                controller: _broadbandAccountController,
                                label: 'change_wifi.broadband_account'.tr(),
                                prefixIcon: LucideIcons.id_card,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'requests.required'.tr();
                                  }
                                  return null;
                                },
                              ),
                            const SizedBox(height: 16),
                            AppInput(
                              controller: _contactNameController,
                              label: 'change_wifi.contact_name'.tr(),
                              prefixIcon: LucideIcons.user,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'requests.required'.tr();
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppStyle.spaceXs),
                            AppInput(
                              controller: _phoneController,
                              label: 'change_wifi.contact_phone'.tr(),
                              hint: '09 xxx xxx xxx',
                              keyboardType: TextInputType.phone,
                              prefixIcon: LucideIcons.phone,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'requests.required'.tr();
                                }
                                return null;
                              },
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
                              label: 'change_wifi.req_new_password'.tr(),
                              hint: 'change_wifi.new_password_hint'.tr(),
                              obscureText: _obscurePassword,
                              prefixIcon: LucideIcons.lock,
                              maxLength: 30,
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
                                  if (_isChangingWifiName) return null;
                                  return 'requests.required'.tr();
                                }
                                if (password.length < 8) {
                                  return 'change_wifi.password_min_length'.tr();
                                }
                                if (password.length > 30) {
                                  return 'change_wifi.password_max_length'.tr();
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppStyle.spaceXs),
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                setState(() {
                                  _isChangingWifiName = !_isChangingWifiName;
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
                                label: 'change_wifi.req_new_wifi_name'.tr(),
                                hint: 'change_wifi.new_wifi_name_hint'.tr(),
                                prefixIcon: LucideIcons.wifi,
                                validator: (v) {
                                  if (_isChangingWifiName &&
                                      (v == null || v.trim().isEmpty)) {
                                    return 'requests.required'.tr();
                                  }
                                  return null;
                                },
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
