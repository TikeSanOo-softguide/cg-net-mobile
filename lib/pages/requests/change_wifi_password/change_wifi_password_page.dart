import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../components/app_button/app_button.dart';
import '../../../components/app_card/app_card.dart';
import '../../../components/app_curved_scaffold/app_curved_scaffold.dart';
import '../../../components/app_input/app_input.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/requests/change_wifi_password/change_wifi_password_api.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import '../../../core/theme/app_style/app_style.dart';
import '../../../core/theme/app_theme/app_theme.dart';
import '../../../models/requests/change_password/change_password_model.dart';
import '../../profile/profile/profile_controller.dart';
import 'change_wifi_password_submitted_page.dart';

class ChangeWifiPasswordPage extends ConsumerStatefulWidget {
  const ChangeWifiPasswordPage({super.key});

  @override
  ConsumerState<ChangeWifiPasswordPage> createState() =>
      _ChangeWifiPasswordPageState();
}

class _ChangeWifiPasswordPageState
    extends ConsumerState<ChangeWifiPasswordPage> {
  List<ChangePasswordRequestModel> _requests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final items =
          await ref.read(changeWifiPasswordApiProvider).fetchRequests();
      if (mounted) {
        setState(() {
          _requests = items;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _cancelRequest(ChangePasswordRequestModel item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('change_wifi.cancel_title'.tr()),
        content: Text('change_wifi.cancel_confirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('common.no'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text('change_wifi.yes_cancel'.tr()),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ref
          .read(changeWifiPasswordApiProvider)
          .cancelRequest(item);

      await _fetchRequests();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('change_wifi.cancel_success'.tr()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.detail ?? e.messageKey),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _openNewRequestModal() {
    showModalBottomSheet<Object?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: const _NewRequestFormSheet(),
      ),
    ).then((result) async {
      if (!mounted || result == null || result == false) return;

      await _fetchRequests();

      final requestModel = result is ChangePasswordRequestModel
          ? result
          : (_requests.isNotEmpty ? _requests.first : null);

      if (requestModel != null && mounted) {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ChangeWifiPasswordSubmittedPage(
              request: requestModel,
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = 'home.service_change_wifi'.tr();

    return AppCurvedScaffold(
      title: Text(
        title,
        style: AppTheme.topBarTitle(),
      ),
      showBack: true,
      floatingActionButton: FloatingActionButton(
        onPressed: _openNewRequestModal,
        backgroundColor: AppColors.primary,
        elevation: 4,
        child: const Icon(
          LucideIcons.plus,
          color: Colors.white,
          size: 26,
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchRequests,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _requests.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_requests.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(AppStyle.spaceLg),
        children: [
          AppCard(
            elevated: true,
            bordered: false,
            padding: const EdgeInsets.symmetric(
              vertical: AppStyle.spaceXxl,
              horizontal: AppStyle.spaceLg,
            ),
            child: Column(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.wifi,
                    color: AppColors.primary,
                    size: 28,
                  ),
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

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppStyle.spaceLg,
        AppStyle.spaceLg,
        AppStyle.spaceLg,
        80, // Clearance for FAB
      ),
      itemCount: _requests.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppStyle.spaceMd),
      itemBuilder: (context, index) {
        final item = _requests[index];
        return _RequestItemCard(
          item: item,
          onCancel: () => _cancelRequest(item),
        );
      },
    );
  }
}

class _RequestItemCard extends StatelessWidget {
  const _RequestItemCard({
    required this.item,
    required this.onCancel,
  });

  final ChangePasswordRequestModel item;
  final VoidCallback onCancel;

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
    final canCancel = item.status.toLowerCase() == 'under_review' ||
        item.status.toLowerCase() == 'pending';

    final dateStr = item.createdAt != null
        ? DateFormat('yyyy.MM.dd HH:mm').format(item.createdAt!)
        : null;

    return AppCard(
      elevated: true,
      bordered: false,
      padding: const EdgeInsets.all(AppStyle.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
          if (canCancel) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.paperBorder),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onCancel,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.error,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(LucideIcons.trash, size: 14),
                label: Text(
                  'change_wifi.cancel_request'.tr(),
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600),
                ),
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

class __NewRequestFormSheetState
    extends ConsumerState<_NewRequestFormSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _broadbandAccountController;
  late final TextEditingController _contactNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _wifiNameController;
  late final TextEditingController _passwordController;

  bool _isChangingWifiName = true;
  bool _obscurePassword = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileControllerProvider);
    _broadbandAccountController =
        TextEditingController(text: profile.accountNumber);
    _contactNameController = TextEditingController(
      text: profile.fullName.isNotEmpty ? profile.fullName : 'Customer',
    );
    _phoneController = TextEditingController(text: profile.phone);
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

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final broadbandAccount = _broadbandAccountController.text.trim();
    final parentState =
        context.findAncestorStateOfType<_ChangeWifiPasswordPageState>();

    final hasPending = parentState?._requests.any((r) {
          final s = r.status.toLowerCase().trim();
          final isPending = s == 'under_review' ||
              s == 'pending' ||
              s == 'under review' ||
              s == 'review';
          final isSameAccount = r.broadbandAccountNumber == null ||
              r.broadbandAccountNumber!.isEmpty ||
              r.broadbandAccountNumber == broadbandAccount;
          return isPending && isSameAccount;
        }) ??
        false;

    if (hasPending) {
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'change_wifi.already_exists';
      });
      return;
    }

    final profile = ref.read(profileControllerProvider);
    final userId = int.tryParse(profile.id);

    final model = ChangePasswordRequestModel(
      id: '',
      userId: userId ?? 1,
      broadbandAccountNumber: broadbandAccount,
      contactName: _contactNameController.text.trim(),
      contactPhone: _phoneController.text.trim(),
      newPassword: _passwordController.text.trim(),
      newWifiName:
          _isChangingWifiName ? _wifiNameController.text.trim() : null,
      createdAt: DateTime.now(),
    );

    try {
      final savedModel =
          await ref.read(changeWifiPasswordApiProvider).submitRequest(model);

      if (!mounted) return;

      setState(() => _isSubmitting = false);
      Navigator.of(context).pop(savedModel);
    } on ApiException catch (e) {
      if (!mounted) return;

      final detailRaw = e.detail ?? e.messageKey;
      final detail = detailRaw.toLowerCase();

      final isAlreadyUnderReview = detail.contains('already under review') ||
          detail.contains('already exist') ||
          detail.contains('under_review') ||
          detail.contains('under review');

      if (isAlreadyUnderReview) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = 'change_wifi.already_exists';
        });
        return;
      }

      if (e.failure == ApiFailure.server ||
          e.failure == ApiFailure.unknown ||
          detail.contains('pusher') ||
          detail.contains('reverb') ||
          detail.contains('curl error') ||
          detail.contains('could not resolve host')) {
        setState(() => _isSubmitting = false);
        Navigator.of(context).pop(model);
        return;
      }

      setState(() {
        _isSubmitting = false;
        _errorMessage = detailRaw;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        Navigator.of(context).pop(model);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileControllerProvider);

    if (_broadbandAccountController.text.isEmpty &&
        profile.accountNumber.isNotEmpty) {
      _broadbandAccountController.text = profile.accountNumber;
    }
    if ((_contactNameController.text.isEmpty ||
            _contactNameController.text == 'Customer') &&
        profile.fullName.isNotEmpty) {
      _contactNameController.text = profile.fullName;
    }
    if (_phoneController.text.isEmpty && profile.phone.isNotEmpty) {
      _phoneController.text = profile.phone;
    }

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(AppStyle.spaceLg),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(
                    'home.service_change_wifi'.tr(),
                    style: AppTheme.english(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    icon: const Icon(LucideIcons.x, color: AppColors.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: AppStyle.spaceSm),
              AppCard(
                elevated: true,
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
                      readOnly: true,
                      enabled: false,
                      prefixIcon: LucideIcons.id_card,
                    ),
                    const SizedBox(height: AppStyle.spaceLg),

                    AppInput(
                      controller: _contactNameController,
                      label: 'change_wifi.contact_name'.tr(),
                      prefixIcon: LucideIcons.user,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'This field is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppStyle.spaceLg),

                    AppInput(
                      controller: _phoneController,
                      label: 'change_wifi.contact_phone'.tr(),
                      hint: '09 xxx xxx xxx',
                      keyboardType: TextInputType.phone,
                      prefixIcon: LucideIcons.phone,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'This field is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppStyle.spaceLg),

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
                            return 'This field is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppStyle.spaceLg),
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
                          return 'This field is required';
                        }
                        if (v.trim().length < 8) {
                          return 'Password must be at least 8 characters';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),

              if (_errorMessage != null) ...[
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
                          _errorMessage!.startsWith('change_wifi.') ||
                                  _errorMessage!.startsWith('api.') ||
                                  _errorMessage!.startsWith('common.')
                              ? _errorMessage!.tr()
                              : _errorMessage!,
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

              const SizedBox(height: AppStyle.spaceLg),

              AppButton(
                label: 'common.submit'.tr() != 'common.submit'
                    ? 'common.submit'.tr()
                    : 'Submit',
                isLoading: _isSubmitting,
                onPressed: _submitForm,
              ),
              const SizedBox(height: AppStyle.spaceMd),
            ],
          ),
        ),
      ),
    );
  }
}
