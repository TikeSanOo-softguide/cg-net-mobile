import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../components/app_button/app_button.dart';
import '../../../components/app_card/app_card.dart';
import '../../../components/app_input/app_input.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import '../../../core/theme/app_style/app_style.dart';
import '../../../core/theme/app_theme/app_theme.dart';
import '../../../core/router/route_names/route_names.dart';
import '../profile/profile_controller.dart';
import 'edit_profile_controller.dart';
import '../../../components/app_curved_scaffold/app_curved_scaffold.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileControllerProvider);
    _name = TextEditingController(text: profile.fullName);
    _phone = TextEditingController(text: profile.displayPhone);
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editState = ref.watch(editProfileControllerProvider);

    return AppCurvedScaffold(
      title: Text('profile.account_settings'.tr()),
      showBack: true,
      body: Form(
        key: _formKey,
        child: SafeArea(
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
                            'assets/images/profile/account_settings.png',
                            width: 20,
                            height: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'profile.account_settings'.tr(),
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
                      controller: _name,
                      reserveErrorSpace: false,
                      label: 'profile.full_name'.tr(),
                      prefixIcon: LucideIcons.id_card,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'profile.full_name_required'.tr();
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    AppInput(
                      controller: _phone,
                      reserveErrorSpace: false,
                      label: 'profile.phone'.tr(),
                      prefixIcon: LucideIcons.phone,
                      keyboardType: TextInputType.phone,
                      enabled: false,
                    ),
                    const SizedBox(height: 12),
                    AppButton(
                      label: 'common.save'.tr(),
                      isLoading: editState.isLoading,
                      onPressed: () async {
                        if (!_formKey.currentState!.validate()) return;

                        final success = await ref
                            .read(editProfileControllerProvider.notifier)
                            .save(
                              fullName: _name.text.trim(),
                            );
                        if (success && context.mounted) {
                          context.pop();
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'profile.deactivate_account_title'.tr(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFB42318),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'profile.deactivate_account_message'.tr(),
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: Color(0xFF626262),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => context.pushNamed(
                          RouteNames.deactivateAccount,
                        ),
                        iconAlignment: IconAlignment.end,
                        icon: const Icon(
                          Icons.chevron_right,
                          size: 20,
                        ),
                        label: Text(
                          'profile.deactivate_account'.tr(),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFB42318),
                          textStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 4,
                          ),
                        ),
                      ),
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
