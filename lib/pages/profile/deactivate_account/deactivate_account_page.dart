import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router/go_router.dart';

import '../../../components/app_button/app_button.dart';
import '../../../components/app_card/app_card.dart';
import '../../../components/app_curved_scaffold/app_curved_scaffold.dart';
import '../../../components/app_dialog/app_dialog.dart';
import '../../../components/app_input/app_input.dart';
import '../../../core/network/api_error_text.dart';
import '../../../core/router/route_names/route_names.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import '../../../core/theme/app_style/app_style.dart';
import '../../../core/theme/app_theme/app_theme.dart';
import '../profile/profile_controller.dart';
import 'deactivate_account_controller.dart';

class DeactivateAccountPage extends ConsumerStatefulWidget {
  const DeactivateAccountPage({super.key});

  @override
  ConsumerState<DeactivateAccountPage> createState() =>
      _DeactivateAccountPageState();
}

class _DeactivateAccountPageState extends ConsumerState<DeactivateAccountPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _confirmDeactivation() async {
    if (ref.read(deactivateAccountControllerProvider)) return;
    if (!_formKey.currentState!.validate()) return;

    final confirmed = await showAppConfirmModal(
      context,
      title: 'profile.deactivate_account_title'.tr(),
      body: 'profile.deactivate_account_confirm_message'.tr(),
      confirmLabel: 'profile.deactivate_account_confirm'.tr(),
      cancelLabel: 'common.cancel'.tr(),
    );

    if (confirmed != true || !mounted) return;

    try {
      final message = await ref
          .read(deactivateAccountControllerProvider.notifier)
          .deactivate(password: _passwordController.text);
      if (!mounted) return;

      _passwordController.clear();
      await ref.read(profileControllerProvider.notifier).logout();
      if (!mounted) return;
      context.goNamed(
        RouteNames.login,
        queryParameters: {
          if (message != null) 'message': message,
        },
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(apiErrorText(error)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(deactivateAccountControllerProvider);

    return AppCurvedScaffold(
      title: Text('profile.deactivate_account_title'.tr()),
      showBack: true,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              AppCard(
                padding: const EdgeInsets.all(16),
                borderRadius: AppStyle.borderRadiusLg,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppColors.error,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'profile.deactivate_account_message'.tr(),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AppCard(
                padding: const EdgeInsets.all(16),
                borderRadius: AppStyle.borderRadiusLg,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'profile.confirm_password'.tr(),
                      style: AppTheme.english(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    AppInput(
                      controller: _passwordController,
                      label: 'profile.enter_password'.tr(),
                      prefixIcon: LucideIcons.lock,
                      obscureText: _obscurePassword,
                      autofillHints: const [AutofillHints.password],
                      textInputAction: TextInputAction.done,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      maxLength: 6,
                      reserveErrorSpace: false,
                      suffix: AppInput.iconChip(
                        icon: _obscurePassword
                            ? LucideIcons.eye_off
                            : LucideIcons.eye,
                        onTap: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'profile.password_required'.tr();
                        }
                        if (!RegExp(r'^\d{6}$').hasMatch(value.trim())) {
                          return 'profile.current_password_digits'.tr();
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    AppButton(
                      label: 'profile.deactivate_account_confirm'.tr(),
                      isLoading: isLoading,
                      backgroundColor: AppColors.error,
                      onPressed: isLoading ? null : _confirmDeactivation,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
