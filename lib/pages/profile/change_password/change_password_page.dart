import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../components/app_button/app_button.dart';
import '../../../components/app_card/app_card.dart';
import '../../../components/app_curved_scaffold/app_curved_scaffold.dart';
import '../../../components/app_input/app_input.dart';
import '../../../core/network/api_error_text.dart';
import '../../../core/router/route_names/route_names.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import '../../../core/theme/app_style/app_style.dart';
import '../../../core/theme/app_theme/app_theme.dart';
import '../../../models/change_password_model/change_password_model.dart';
import '../../../models/change_password_model/change_password_otp_session.dart';
import 'change_password_controller.dart';

class ChangePasswordPage extends ConsumerStatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  ConsumerState<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends ConsumerState<ChangePasswordPage> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _newPasswordFieldKey = GlobalKey<FormFieldState<String>>();
  final _confirmFieldKey = GlobalKey<FormFieldState<String>>();
  var _obscureCurrentPassword = true;
  var _obscureNewPassword = true;
  var _obscureConfirmPassword = true;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(changePasswordControllerProvider);

    return AppCurvedScaffold(
      title: Text('profile.password_title'.tr()),
      showBack: true,
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            AppCard(
              padding: const EdgeInsets.all(16),
              borderRadius: AppStyle.borderRadiusLg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Image.asset(
                          'assets/images/profile/change_password.png',
                          width: 20,
                          height: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'profile.password_title'.tr(),
                          style: AppTheme.english(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            height: AppStyle.lineHeightTitle,
                            letterSpacing: -0.15,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AppInput(
                    controller: _current,
                    reserveErrorSpace: false,
                    label: 'profile.current_password'.tr(),
                    prefixIcon: LucideIcons.lock,
                    obscureText: _obscureCurrentPassword,
                    keyboardType: TextInputType.number,
                    suffix: AppInput.iconChip(
                      icon: _obscureCurrentPassword
                          ? LucideIcons.eye_off
                          : LucideIcons.eye,
                      onTap: () => setState(
                        () =>
                            _obscureCurrentPassword = !_obscureCurrentPassword,
                      ),
                    ),
                    onChanged: (_) {
                      if (_newPasswordFieldKey
                              .currentState?.hasInteractedByUser ??
                          false) {
                        _newPasswordFieldKey.currentState?.validate();
                      }
                    },
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'profile.current_password_required'.tr();
                      }
                      if (!RegExp(r'^\d{6}$').hasMatch(value.trim())) {
                        return 'profile.current_password_digits'.tr();
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  AppInput(
                    formFieldKey: _newPasswordFieldKey,
                    reserveErrorSpace: false,
                    controller: _next,
                    label: 'profile.new_password'.tr(),
                    prefixIcon: LucideIcons.lock,
                    obscureText: _obscureNewPassword,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    suffix: AppInput.iconChip(
                      icon: _obscureNewPassword
                          ? LucideIcons.eye_off
                          : LucideIcons.eye,
                      onTap: () => setState(
                        () => _obscureNewPassword = !_obscureNewPassword,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'profile.new_password_required'.tr();
                      }
                      if (!RegExp(r'^\d{6}$').hasMatch(value.trim())) {
                        return 'profile.new_password_digits'.tr();
                      }
                      if (value.trim() == _current.text.trim()) {
                        return 'profile.new_password_different'.tr();
                      }
                      return null;
                    },
                    onChanged: (_) {
                      if (_confirmFieldKey.currentState?.hasInteractedByUser ??
                          false) {
                        _confirmFieldKey.currentState?.validate();
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  AppInput(
                    formFieldKey: _confirmFieldKey,
                    reserveErrorSpace: false,
                    controller: _confirm,
                    label: 'set_credentials.confirm_password'.tr(),
                    prefixIcon: LucideIcons.lock,
                    obscureText: _obscureConfirmPassword,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    suffix: AppInput.iconChip(
                      icon: _obscureConfirmPassword
                          ? LucideIcons.eye_off
                          : LucideIcons.eye,
                      onTap: () => setState(
                        () =>
                            _obscureConfirmPassword = !_obscureConfirmPassword,
                      ),
                    ),
                    validator: (value) {
                      final confirmation = value?.trim() ?? '';
                      if (confirmation.isEmpty) {
                        return 'set_credentials.confirm_required'.tr();
                      }
                      if (confirmation != _next.text.trim()) {
                        return 'set_credentials.password_mismatch'.tr();
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    label: 'common.save'.tr(),
                    isLoading: loading,
                    onPressed: () async {
                      if (!_formKey.currentState!.validate()) return;

                      final model = ChangePasswordModel(
                        currentPassword: _current.text,
                        newPassword: _next.text,
                        newPasswordConfirmation: _confirm.text,
                      );

                      try {
                        final challenge = await ref
                            .read(changePasswordControllerProvider.notifier)
                            .changePassword(password: model);

                        if (!context.mounted) return;

                        _current.clear();
                        _next.clear();
                        _confirm.clear();
                        context.pushNamed(
                          RouteNames.verifyChangePasswordOtp,
                          queryParameters: {
                            'challenge_id': challenge.challengeId,
                          },
                          extra: ChangePasswordOtpSession(
                            challenge: challenge,
                            password: model,
                          ),
                        );
                      } catch (error) {
                        if (!context.mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(apiErrorText(error)),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
