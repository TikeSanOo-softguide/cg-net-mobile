import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../components/app_button/app_button.dart';
import '../../../../components/app_dialog/app_dialog.dart';
import '../../../../components/app_input/app_input.dart';
import '../../../../core/network/api_error_text.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors/app_colors.dart';
import '../../../../core/theme/app_style/app_style.dart';
import '../../../../core/theme/app_theme/app_theme.dart';
import '../../../../core/ui/bottom_nav_visibility_provider.dart';
import '../../../../data/broadband/broadband_repository.dart';

class BoundBroadband {
  const BoundBroadband({
    required this.account,
    required this.customerName,
  });

  final String account;
  final String customerName;
}

Future<BoundBroadband?> showBindBroadbandDrawer(BuildContext context) async {
  final container = ProviderScope.containerOf(context);
  final nav = container.read(bottomNavVisibleProvider.notifier);
  nav.state = false;

  try {
    return await showModalBottomSheet<BoundBroadband>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppStyle.radiusCurve),
        ),
      ),
      builder: (sheetContext) => const _BindBroadbandSheet(),
    );
  } finally {
    nav.state = true;
  }
}

Future<bool> showBoundAccountDrawer(
  BuildContext context, {
  required BoundBroadband bound,
}) async {
  final container = ProviderScope.containerOf(context);
  final nav = container.read(bottomNavVisibleProvider.notifier);
  nav.state = false;

  try {
    final result = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppStyle.radiusCurve),
        ),
      ),
      builder: (sheetContext) => _BoundAccountSheet(bound: bound),
    );
    return result == true;
  } finally {
    nav.state = true;
  }
}

Future<void> showBindSuccessModal(BuildContext context) {
  return showAppSuccessModal(
    context,
    title: 'home.bind_success_title'.tr(),
    body: 'home.bind_success_body'.tr(),
  );
}

class _BindBroadbandSheet extends StatefulWidget {
  const _BindBroadbandSheet();

  @override
  State<_BindBroadbandSheet> createState() => _BindBroadbandSheetState();
}

class _BindBroadbandSheetState extends State<_BindBroadbandSheet> {
  final _account = TextEditingController();
  final _customerName = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  bool _isFormValid = false;
  String? _accountError;
  String? _customerNameError;

  @override
  void dispose() {
    _account.dispose();
    _customerName.dispose();
    super.dispose();
  }

  void _validateAccount(String value) {
    final text = value.trim();

    String? error;

    if (text.isEmpty) {
      error = 'broadband.validation.account_required'.tr();
    } else if (text.length > 32) {
      error = 'broadband.validation.account_max_length'.tr();
    }

    setState(() {
      _accountError = error;
      _updateFormValidity();
    });
  }

  void _validateCustomerName(String value) {
    final text = value.trim();

    String? error;

    if (text.isEmpty) {
      error = 'broadband.validation.customer_name_required'.tr();
    } else if (text.length > 50) {
      error = 'broadband.validation.customer_name_max_length'.tr();
    }

    setState(() {
      _customerNameError = error;
      _updateFormValidity();
    });
  }

  void _updateFormValidity() {
    _isFormValid = _account.text.trim().isNotEmpty &&
        _account.text.trim().length <= 32 &&
        _customerName.text.trim().isNotEmpty &&
        _customerName.text.trim().length <= 50 &&
        _accountError == null &&
        _customerNameError == null;
  }

  Future<void> _submit() async {
    if (_isSubmitting || !(_formKey.currentState?.validate() ?? false)) return;

    final bound = BoundBroadband(
      account: _account.text.trim(),
      customerName: _customerName.text.trim(),
    );
    setState(() => _isSubmitting = true);

    try {
      final container = ProviderScope.containerOf(context);
      final response =
          await container.read(broadbandRepositoryProvider).connect(
                accountNumber: bound.account,
                customerName: bound.customerName,
              );

      debugPrint('BROADBAND CONNECT RESPONSE: $response');

      if (!mounted) return;

      Navigator.of(context).pop(bound);
    } on ApiException catch (error) {
      if (!mounted) return;
      final errorKey = error.detail?.trim();

      final message = errorKey != null && errorKey.isNotEmpty
          ? 'broadband.validation.$errorKey'.tr()
          : apiErrorText(error);

      await showAppFailureModal(
        context,
        title: 'broadband.validation.bind_fail_title'.tr(),
        body: message,
      );
    } catch (_) {
      if (!mounted) return;
      await showAppFailureModal(
        context,
        title: 'broadband.validation.bind_fail_title'.tr(),
        body: 'broadband.validation.bind_fail_body'.tr(),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 30, 20, 20 + bottomInset),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppStyle.spaceLg),
              Text(
                'broadband.bind_now'.tr(),
                textAlign: TextAlign.center,
                style: AppTheme.english(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppStyle.spaceXxl),
              AppInput(
                controller: _account,
                label: 'home.broadband_account'.tr(),
                hint: 'home.broadband_account_hint'.tr(),
                prefixIcon: LucideIcons.router,
                textInputAction: TextInputAction.next,
                reserveErrorSpace: false,
                onChanged: _validateAccount,
                validator: (v) {
                  final value = v?.trim() ?? '';
                  if (value.isEmpty) {
                    return 'Broadband account is required';
                  }
                  if (value.length > 32) {
                    return 'Broadband account must not exceed 32 characters';
                  }
                  return null;
                },
              ),
              SizedBox(
                height: 30,
                child: _accountError != null
                    ? Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Text(
                          _accountError!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      )
                    : null,
              ),
              AppInput(
                controller: _customerName,
                label: 'home.customer_name'.tr(),
                hint: 'home.customer_name_hint'.tr(),
                prefixIcon: LucideIcons.user,
                textInputAction: TextInputAction.done,
                reserveErrorSpace: false,
                onChanged: _validateCustomerName,
                onSubmitted: (_) => _submit(),
                validator: (v) {
                  final value = v?.trim() ?? '';
                  if (value.isEmpty) {
                    return 'Customer name is required';
                  }
                  if (value.length > 50) {
                    return 'Customer name must not exceed 50 characters';
                  }
                  return null;
                },
              ),
              SizedBox(
                height: 30,
                child: _customerNameError != null
                    ? Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Text(
                          _customerNameError!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      )
                    : null,
              ),
              AppButton(
                label: 'home.bind'.tr(),
                height: 40,
                fontSize: 13,
                isLoading: _isSubmitting,
                onPressed: _isFormValid && !_isSubmitting ? _submit : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BoundAccountSheet extends StatefulWidget {
  const _BoundAccountSheet({required this.bound});

  final BoundBroadband bound;

  @override
  State<_BoundAccountSheet> createState() => _BoundAccountSheetState();
}

class _BoundAccountSheetState extends State<_BoundAccountSheet> {
  bool _isSubmitting = false;

  Future<void> _onRemove() async {
    if (_isSubmitting) return;

    final container = ProviderScope.containerOf(context);
    final repository = container.read(broadbandRepositoryProvider);

    final confirmed = await showAppConfirmModal(
      context,
      title: 'home.remove_broadband_confirm_title'.tr(),
      body: 'home.remove_broadband_confirm_body'.tr(),
    );

    if (!mounted) return;
    if (!confirmed) return;

    setState(() => _isSubmitting = true);

    try {
      await repository.unbindAccount(
        accountNumber: widget.bound.account,
      );

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (!mounted) return;

      final backendMessage = error.detail?.trim();

      await showAppFailureModal(
        context,
        title: 'broadband.validation.unbind_fail_title'.tr(),
        body: backendMessage != null && backendMessage.isNotEmpty
            ? backendMessage
            : apiErrorText(error),
      );
    } catch (_) {
      if (!mounted) return;

      await showAppFailureModal(
        context,
        title: 'broadband.validation.unbind_fail_title'.tr(),
        body: 'broadband.validation.unbind_fail_body'.tr(),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bound = widget.bound;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppStyle.spaceLg),
            Text(
              'home.broadband_account'.tr(),
              textAlign: TextAlign.center,
              style: AppTheme.english(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppStyle.spaceMd),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow(
                    label: 'home.broadband_account'.tr(),
                    value: bound.account,
                  ),
                  const SizedBox(height: 10),
                  _InfoRow(
                    label: 'home.customer_name'.tr(),
                    value: bound.customerName,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppStyle.spaceXl),
            SizedBox(
              height: 36,
              child: FilledButton(
                onPressed: _isSubmitting ? null : _onRemove,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppStyle.radiusButton),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.onPrimary,
                        ),
                      )
                    : Text(
                        'home.remove_broadband'.tr(),
                        style: AppTheme.english(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onPrimary,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: AppStyle.spaceSm),
            SizedBox(
              height: 36,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFF0000),
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFFF0000), width: 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppStyle.radiusButton),
                  ),
                ),
                child: Text(
                  'common.cancel'.tr(),
                  style: AppTheme.english(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFFF0000),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$label : ',
            style: AppTheme.english(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          TextSpan(
            text: value,
            style: AppTheme.english(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
