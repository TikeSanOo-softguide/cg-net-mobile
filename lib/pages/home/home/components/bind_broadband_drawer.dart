import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../components/app_button/app_button.dart';
import '../../../../components/app_dialog/app_dialog.dart';
import '../../../../components/app_input/app_input.dart';
import '../../../../core/theme/app_colors/app_colors.dart';
import '../../../../core/theme/app_style/app_style.dart';
import '../../../../core/theme/app_theme/app_theme.dart';
import '../../../../core/ui/bottom_nav_visibility_provider.dart';

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

  @override
  void dispose() {
    _account.dispose();
    _customerName.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(
      BoundBroadband(
        account: _account.text.trim(),
        customerName: _customerName.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottomInset),
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
                'home.bind_now'.tr(),
                textAlign: TextAlign.center,
                style: AppTheme.english(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppStyle.spaceLg),
              AppInput(
                controller: _account,
                label: 'home.broadband_account'.tr(),
                hint: 'home.broadband_account_hint'.tr(),
                prefixIcon: LucideIcons.router,
                textInputAction: TextInputAction.next,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'home.broadband_account_required'.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppStyle.spaceMd),
              AppInput(
                controller: _customerName,
                label: 'home.customer_name'.tr(),
                hint: 'home.customer_name_hint'.tr(),
                prefixIcon: LucideIcons.user,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'home.customer_name_required'.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppStyle.spaceXl),
              AppButton(
                label: 'home.bind'.tr(),
                height: 42,
                fontSize: 13,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BoundAccountSheet extends StatelessWidget {
  const _BoundAccountSheet({required this.bound});

  final BoundBroadband bound;

  Future<void> _onRemove(BuildContext context) async {
    final confirmed = await showAppConfirmModal(
      context,
      title: 'home.remove_broadband_confirm_title'.tr(),
      body: 'home.remove_broadband_confirm_body'.tr(),
    );
    if (!context.mounted) return;
    if (confirmed) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
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
                onPressed: () => _onRemove(context),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppStyle.radiusButton),
                  ),
                ),
                child: Text(
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
                  foregroundColor: const Color(0xFFF44336),
                  backgroundColor: Color.alphaBlend(
                    const Color(0xFFF44336).withValues(alpha: 0.12),
                    Colors.white,
                  ),
                  side: const BorderSide(color: Color(0xFFF44336), width: 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppStyle.radiusButton),
                  ),
                ),
                child: Text(
                  'common.cancel'.tr(),
                  style: AppTheme.english(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFF44336),
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
