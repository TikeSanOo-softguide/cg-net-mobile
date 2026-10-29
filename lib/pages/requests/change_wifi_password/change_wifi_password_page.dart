import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../components/app_add_floating_action_button/app_add_floating_action_button.dart';
import '../../../components/app_button/app_button.dart';
import '../../../components/app_card/app_card.dart';
import '../../../components/app_curved_scaffold/app_curved_scaffold.dart';
import '../../../components/app_dialog/app_dialog.dart';
import '../../../components/app_input/app_input.dart';
import '../../../components/quick_action_icon_chip/quick_action_icon_chip.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import '../../../core/theme/app_style/app_style.dart';
import '../../../core/theme/app_theme/app_theme.dart';
import '../../../models/requests/change_password/change_password_model.dart';
import '../../profile/profile/profile_controller.dart';
import 'change_wifi_password_controller.dart';
import 'change_wifi_password_detail_page.dart';

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

  void _openNewRequestPage() {
    Navigator.of(context)
        .push<Object?>(
      MaterialPageRoute<Object?>(
        builder: (_) => const _NewRequestFormSheet(),
      ),
    )
        .then((result) async {
      if (!mounted || result == null || result == false) return;

      if (result is ChangePasswordRequestModel) {
        await showAppSuccessModal(
          context,
          title: 'change_wifi.submitted_title'.tr(),
          body: 'change_wifi.submitted_desc'.tr(),
        );
      }

      if (mounted) await _fetchRequests();
    });
  }

  void _openRequestDetails(ChangePasswordRequestModel request) {
    Navigator.of(context)
        .push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ChangeWifiPasswordDetailPage(request: request),
      ),
    )
        .then((_) {
      if (mounted) _fetchRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = 'home.service_change_wifi'.tr();
    final requests = ref.watch(changeWifiPasswordControllerProvider).requests;
    final hasUnderReviewRequest = requests.any(
      (request) => request.status.toLowerCase().trim() == 'under_review',
    );

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
            padding: const EdgeInsets.symmetric(
              vertical: AppStyle.spaceXxl,
              horizontal: AppStyle.spaceLg,
            ),
            child: Column(
              children: [
                const QuickActionIconChip(
                  asset: 'assets/images/services/change_wifi.png',
                  background: AppColors.primaryLight,
                  tint: Color(0xFFF25912),
                  size: 54,
                  iconSize: 36,
                ),
                const SizedBox(height: AppStyle.spaceMd),
                Text(
                  'change_wifi.no_requests'.tr(),
                  style: AppTheme.english(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppStyle.spaceXs),
                Text(
                  'change_wifi.no_requests_desc'.tr(),
                  textAlign: TextAlign.center,
                  style: AppTheme.body(
                    color: AppColors.textMuted,
                    weight: FontWeight.w400,
                  ).copyWith(fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final underReviewRequests = requests.where((request) {
      final status = request.status.toLowerCase().trim();
      return status == 'under_review' ||
          status == 'under review' ||
          status == 'pending' ||
          status == 'review';
    }).toList();
    final historyRequests = requests.where((request) {
      final status = request.status.toLowerCase().trim();
      return status != 'under_review' &&
          status != 'under review' &&
          status != 'pending' &&
          status != 'review';
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppStyle.spaceLg,
        AppStyle.spaceLg,
        AppStyle.spaceLg,
        80, // Clearance for FAB
      ),
      children: [
        if (underReviewRequests.isNotEmpty) ...[
          _buildSectionTitle('change_wifi.status_under_review'.tr()),
          for (final request in underReviewRequests) ...[
            _RequestItemCard(
              item: request,
              onTap: () => _openRequestDetails(request),
            ),
            const SizedBox(height: AppStyle.spaceMd),
          ],
        ],
        if (historyRequests.isNotEmpty) ...[
          _buildSectionTitle('home.service_history'.tr()),
          for (final request in historyRequests) ...[
            _RequestItemCard(
              item: request,
              onTap: () => _openRequestDetails(request),
            ),
            const SizedBox(height: AppStyle.spaceMd),
          ],
        ],
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppStyle.spaceMd),
      child: Text(
        title,
        style: AppTheme.english(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _RequestItemCard extends StatelessWidget {
  const _RequestItemCard({
    required this.item,
    required this.onTap,
  });

  final ChangePasswordRequestModel item;
  final VoidCallback onTap;

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'under_review':
      case 'pending':
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
    switch (status.toLowerCase()) {
      case 'under_review':
        return 'change_wifi.status_under_review'.tr();
      case 'pending':
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

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(item.status);

    final dateStr = item.createdAt != null
        ? DateFormat('yyyy.MM.dd HH:mm').format(item.createdAt!)
        : null;

    return AppCard(
      elevated: false,
      bordered: false,
      onTap: onTap,
      padding: const EdgeInsets.all(AppStyle.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _statusLabel(item.status),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              if (dateStr != null)
                Text(
                  dateStr,
                  style: AppTheme.english(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (item.broadbandAccountNumber != null &&
              item.broadbandAccountNumber!.isNotEmpty) ...[
            Text(
              'A/C: ${item.broadbandAccountNumber}',
              style: AppTheme.english(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
          ],
          Text(
            '${item.contactName} (${item.contactPhone})',
            style: AppTheme.english(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          if (item.newWifiName != null && item.newWifiName!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '${'change_wifi.new_wifi_name_hint'.tr()}: ${item.newWifiName}',
              style: AppTheme.english(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NewRequestFormSheet extends ConsumerStatefulWidget {
  const _NewRequestFormSheet();

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

  bool _isChangingWifiName = true;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileControllerProvider);
    _broadbandAccountController =
        TextEditingController(text: profile.accountNumber);
    _contactNameController = TextEditingController(
      text: profile.fullName.isNotEmpty ? profile.fullName : 'Customer',
    );
    _phoneController = TextEditingController(text: profile.displayPhone);
    _wifiNameController = TextEditingController();
    _passwordController = TextEditingController();
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

    final savedModel = await ref
        .read(changeWifiPasswordControllerProvider.notifier)
        .submitRequest(
          broadbandAccount: boundAccount,
          contactName: _contactNameController.text.trim(),
          contactPhone: _phoneController.text.trim(),
          newPassword: _passwordController.text.trim(),
          newWifiName:
              _isChangingWifiName ? _wifiNameController.text.trim() : null,
          userId: userId,
        );

    if (!mounted) return;

    if (savedModel != null) {
      Navigator.of(context).pop(savedModel);
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

    final errorMessage = controllerState.errorMessage;

    return AppCurvedScaffold(
      title: Text(
        'home.service_change_wifi'.tr(),
        style: AppTheme.topBarTitle(),
      ),
      showBack: true,
      body: Container(
        color: AppColors.background,
        padding: const EdgeInsets.all(AppStyle.spaceLg),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppCard(
                  elevated: false,
                  bordered: false,
                  padding: const EdgeInsets.all(AppStyle.spaceLg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'change_wifi.form_desc'.tr(),
                        style: AppTheme.body(
                          color: AppColors.textSecondary,
                          weight: FontWeight.w400,
                        ).copyWith(fontSize: 13),
                      ),
                      const SizedBox(height: AppStyle.spaceLg),
                      AppInput(
                        controller: _broadbandAccountController,
                        label: 'change_wifi.broadband_account'.tr(),
                        readOnly: profile.accountNumber.isNotEmpty,
                        enabled: profile.accountNumber.isEmpty,
                        prefixIcon: LucideIcons.id_card,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'requests.required'.tr();
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppStyle.spaceXs),
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
                      const SizedBox(height: AppStyle.spaceXs),
                      Text(
                        'change_wifi.checkbox_desc'.tr(),
                        style: AppTheme.body(
                          color: AppColors.textSecondary,
                          weight: FontWeight.w400,
                        ).copyWith(fontSize: 12),
                      ),
                      const SizedBox(height: AppStyle.spaceSm),
                      InkWell(
                        onTap: () {
                          setState(() {
                            _isChangingWifiName = !_isChangingWifiName;
                          });
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'change_wifi.wifi_name_optional'.tr(),
                                style: AppTheme.body(
                                  color: AppColors.textPrimary,
                                  weight: FontWeight.w500,
                                ).copyWith(fontSize: 13),
                              ),
                              const SizedBox(width: AppStyle.spaceSm),
                              SizedBox(
                                height: 20,
                                width: 20,
                                child: Checkbox(
                                  value: _isChangingWifiName,
                                  activeColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  onChanged: (val) {
                                    setState(() {
                                      _isChangingWifiName = val ?? false;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppStyle.spaceLg),
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
                      AppInput(
                        controller: _passwordController,
                        label: 'change_wifi.req_new_password'.tr(),
                        hint: 'change_wifi.new_password_hint'.tr(),
                        obscureText: _obscurePassword,
                        prefixIcon: LucideIcons.lock,
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
                          if (v == null || v.trim().isEmpty) {
                            return 'requests.required'.tr();
                          }
                          if (v.trim().length < 6) {
                            return 'change_wifi.password_min_length'.tr();
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppStyle.spaceXxl),
                      AppButton(
                        label: 'common.submit'.tr() != 'common.submit'
                            ? 'common.submit'.tr()
                            : 'Submit',
                        isLoading: controllerState.isSubmitting,
                        onPressed: _submitForm,
                      ),
                    ],
                  ),
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: AppStyle.spaceMd),
                  Container(
                    padding: const EdgeInsets.all(AppStyle.spaceMd),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          LucideIcons.circle_alert,
                          color: AppColors.error,
                          size: 18,
                        ),
                        const SizedBox(width: AppStyle.spaceSm),
                        Expanded(
                          child: Text(
                            errorMessage.startsWith('change_wifi.') ||
                                    errorMessage.startsWith('api.') ||
                                    errorMessage.startsWith('common.')
                                ? errorMessage.tr()
                                : errorMessage,
                            style: const TextStyle(
                              color: AppColors.error,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppStyle.spaceMd),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
