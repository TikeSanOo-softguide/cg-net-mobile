import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../components/app_button/app_button.dart';
import '../../../components/app_circle_icon_button/app_circle_icon_button.dart';
import '../../../components/app_input/app_input.dart';
import '../../../components/app_logo/app_logo.dart';
import '../../../components/common_auth_card/common_auth_card.dart';
import '../../../core/router/route_names/route_names.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import '../../../core/theme/app_style/app_style.dart';
import '../../../core/theme/app_theme/app_theme.dart';
import '../../profile/language_settings/language_settings_controller.dart';
import 'login_controller.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  late final TapGestureRecognizer _termsTap;

  @override
  void initState() {
    super.initState();
    _termsTap = TapGestureRecognizer()
      ..onTap = () {
        context.pushNamed(RouteNames.terms);
      };
  }

  @override
  void dispose() {
    _termsTap.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _showLanguagePicker() async {
    final selected = ref.read(languageSettingsControllerProvider);
    final controller = ref.read(languageSettingsControllerProvider.notifier);

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppStyle.radiusCurve),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'profile.language_title'.tr(),
                  style: AppTheme.english(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                _LanguageOption(
                  label: 'language.english'.tr(),
                  selected: selected == 'en',
                  onTap: () async {
                    await controller.change(context, 'en');
                    if (sheetContext.mounted) Navigator.pop(sheetContext);
                  },
                ),
                _LanguageOption(
                  label: 'language.myanmar'.tr(),
                  selected: selected == 'my',
                  onTap: () async {
                    await controller.change(context, 'my');
                    if (sheetContext.mounted) Navigator.pop(sheetContext);
                  },
                ),
                _LanguageOption(
                  label: 'language.chinese'.tr(),
                  selected: selected == 'zh',
                  onTap: () async {
                    await controller.change(context, 'zh');
                    if (sheetContext.mounted) Navigator.pop(sheetContext);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loginControllerProvider);
    final controller = ref.read(loginControllerProvider.notifier);

    return AuthBackgroundScaffold(
      trailing: AppCircleIconButton(
        icon: LucideIcons.languages,
        onPressed: _showLanguagePicker,
      ),
      header: const AppLogo(
        size: 120,
        padding: 0,
        borderRadius: 0,
        backgroundColor: Colors.transparent,
        showShadow: false,
      ),
      headerTitle: 'login.title'.tr().toUpperCase(),
      headerTitleGap: 2,
      compactTop: true,
      card: CommonAuthCard(
        description: 'login.subtitle'.tr(),
        primaryAction: AppButton(
          label: 'login.send_otp'.tr(),
          height: 42,
          fontSize: 13,
          isLoading: state.isLoading,
          onPressed: !state.acceptedTerms
              ? null
              : () async {
                  if (!_formKey.currentState!.validate()) return;
                  final phone = await controller.submit(_phoneController.text);
                  if (phone != null && context.mounted) {
                    context.pushNamed(
                      RouteNames.otpVerification,
                      queryParameters: {'phone': phone},
                    );
                  }
                },
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppInput(
                controller: _phoneController,
                hint: 'login.phone_hint'.tr(),
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(12),
                ],
                prefix: Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<CountryDial>(
                      value: state.country,
                      isDense: true,
                      borderRadius: AppStyle.borderRadiusInput,
                      icon: const Icon(
                        LucideIcons.chevron_down,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      items: CountryDial.values
                          .map(
                            (c) => DropdownMenuItem(
                              value: c,
                              child: Text(
                                '${c.flag} ${c.dialCode}',
                                style: AppTheme.english(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) controller.setCountry(value);
                      },
                    ),
                  ),
                ),
                suffixIcon: LucideIcons.phone,
                validator: (value) {
                  if (value == null || value.trim().length < 8) {
                    return 'login.phone_label'.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _LoginCheckbox(
                    value: state.acceptedTerms,
                    onChanged: controller.setAcceptedTerms,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text.rich(
                        TextSpan(
                          style: AppTheme.english(
                            fontSize: 12,
                            color: AppColors.textMuted,
                            height: 1.4,
                          ),
                          children: [
                            TextSpan(text: 'login.terms_prefix'.tr()),
                            TextSpan(
                              text: 'login.terms_link'.tr(),
                              style: AppTheme.english(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                              recognizer: _termsTap,
                            ),
                            TextSpan(text: 'login.terms_suffix'.tr()),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginCheckbox extends StatelessWidget {
  const _LoginCheckbox({
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 22,
        height: 22,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: value ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: value ? AppColors.primary : AppColors.border,
            width: 1.4,
          ),
        ),
        child: value
            ? const Icon(
                LucideIcons.check,
                size: 14,
                color: AppColors.onPrimary,
              )
            : null,
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      title: Text(
        label,
        style: AppTheme.english(
          fontSize: 14,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
      trailing: selected
          ? const Icon(
              LucideIcons.circle_check,
              color: AppColors.primary,
              size: 20,
            )
          : null,
    );
  }
}
