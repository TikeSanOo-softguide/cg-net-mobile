import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
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
import '../../../core/locale/app_locale_provider.dart';
import '../../../core/network/api_error_text.dart';
import '../../../core/network/offline_navigation.dart';
import '../../../core/router/route_names/route_names.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import '../../../core/theme/app_style/app_style.dart';
import '../../../core/theme/app_theme/app_theme.dart';
import '../../../core/utils/phone_number.dart';
import '../../profile/language_settings/language_settings_controller.dart';
import 'components/login_help_footer.dart';
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
  bool _sessionExpiredNoticeShown = false;
  bool _autovalidate = false;

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
                  flagAsset: 'assets/images/flags/en.png',
                  label: 'language.english'.tr(),
                  selected: selected == 'en',
                  onTap: () async {
                    await controller.change(context, 'en');
                    if (sheetContext.mounted) Navigator.pop(sheetContext);
                  },
                ),
                _LanguageOption(
                  flagAsset: 'assets/images/flags/my.png',
                  label: 'language.myanmar'.tr(),
                  selected: selected == 'my',
                  onTap: () async {
                    await controller.change(context, 'my');
                    if (sheetContext.mounted) Navigator.pop(sheetContext);
                  },
                ),
                _LanguageOption(
                  flagAsset: 'assets/images/flags/zh.png',
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
    final reason = GoRouterState.of(context).uri.queryParameters['reason'];
    if (!_sessionExpiredNoticeShown && reason == 'session_expired') {
      _sessionExpiredNoticeShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text('api.unauthorized'.tr())),
          );
      });
    }

    final state = ref.watch(loginControllerProvider);
    final controller = ref.read(loginControllerProvider.notifier);
    final localeCode = ref.watch(appLocaleProvider);
    final _ = context.locale;

    // Refresh cached FormField errors into the active language.
    ref.listen<String>(appLocaleProvider, (_, __) {
      if (!_autovalidate || !mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _formKey.currentState?.validate();
      });
    });

    return AuthBackgroundScaffold(
      trailing: AppCircleIconButton(
        icon: LucideIcons.languages,
        backgroundColor: Colors.white.withValues(alpha: 0.18),
        onPressed: _showLanguagePicker,
      ),
      header: const AppLogo(
        width: 84,
        height: 47,
        padding: 0,
        borderRadius: 0,
        backgroundColor: Colors.transparent,
        showShadow: false,
      ),
      headerTitle: 'login.title'.tr().toUpperCase(),
      headerTitleGap: 4,
      // Keep logo near sheet; avoid large gap that overflows small screens.
      headerBodyTopGap: 48,
      compactTop: true,
      headerTopPadding: 10,
      headerBottomPadding: 16,
      sheetRadius: 24,
      sheetMiddle: LoginHelpFooter(
        key: ValueKey('login-help-$localeCode'),
      ),
      sheetBottom: _LoginContinueNotice(termsTap: _termsTap),
      card: CommonAuthCard(
        description: 'login.subtitle'.tr(),
        descriptionFontSize: 16,
        descriptionFontWeight: FontWeight.w500,
        descriptionHeight: 1.5,
        descriptionLetterSpacing: 0.2,
        descriptionLineCount: 1,
        childTopGap: 15,
        actionTopGap: 0,
        primaryAction: AppButton(
          label: 'login.send_otp'.tr(),
          height: 44,
          fontSize: 14,
          isLoading: state.isLoading,
          onPressed: () async {
            setState(() => _autovalidate = true);
            if (!_formKey.currentState!.validate()) return;
            final phone = await controller.submit(_phoneController.text);
            if (!context.mounted) return;
            final challengeId = controller.challengeId;
            if (phone != null && challengeId != null) {
              final debugOtp = controller.debugOtp;
              if (kDebugMode && debugOtp != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('OTP $debugOtp')),
                );
              }
              context.pushNamed(
                RouteNames.otpVerification,
                queryParameters: {
                  'phone': phone,
                  'challenge_id': challengeId,
                  'resend_after': '${controller.resendAfter}',
                },
              );
              return;
            }
            final error = ref.read(loginControllerProvider).error;
            if (isOfflineError(error)) {
              await openNoInternetPage(context);
              return;
            }
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(content: Text(apiErrorOrFallback(error))),
              );
          },
        ),
        child: Form(
          key: _formKey,
          autovalidateMode: _autovalidate
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled,
          child: AppInput(
            controller: _phoneController,
            hint: 'login.phone_hint'.tr(),
            hintLetterSpacing: 1,
            keyboardType: TextInputType.phone,
            autofillHints: const [AutofillHints.telephoneNumber],
            textInputAction: TextInputAction.done,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(12),
            ],
            prefix: Padding(
              padding: const EdgeInsets.only(left: 12, right: 6),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<CountryDial>(
                  value: state.country,
                  isDense: true,
                  borderRadius: AppStyle.borderRadiusInput,
                  icon: const Icon(
                    LucideIcons.chevron_down,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  items: CountryDial.values
                      .map(
                        (c) => DropdownMenuItem(
                          value: c,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                c.flag,
                                style: const TextStyle(fontSize: 18),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                c.dialCode,
                                style: AppTheme.english(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                  selectedItemBuilder: (context) {
                    return CountryDial.values
                        .map(
                          (c) => Align(
                            alignment: Alignment.centerLeft,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  c.flag,
                                  style: const TextStyle(fontSize: 18),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  c.dialCode,
                                  style: AppTheme.english(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList();
                  },
                  onChanged: (value) {
                    if (value != null) {
                      controller.setCountry(value);
                      if (_autovalidate) {
                        _formKey.currentState?.validate();
                      }
                    }
                  },
                ),
              ),
            ),
            suffixIcon: LucideIcons.phone,
            validator: (value) {
              final errorKey = PhoneNumber.validationErrorKey(
                dialCode: state.country.dialCode,
                localInput: value,
              );
              if (errorKey == null) return null;
              // Bind to current locale so EN / MY / ZH messages stay correct.
              return context.tr(errorKey);
            },
          ),
        ),
      ),
    );
  }
}

/// Compact legal notice pinned near the bottom of the login sheet.
class _LoginContinueNotice extends StatelessWidget {
  const _LoginContinueNotice({required this.termsTap});

  final TapGestureRecognizer termsTap;

  TextStyle get _bodyStyle => AppTheme.english(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.textMuted,
        height: 1.5,
        letterSpacing: 0.3,
      );

  TextStyle get _linkStyle => AppTheme.english(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.primary,
        height: 1.5,
        letterSpacing: 0.3,
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 14,
              height: 14,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(3),
              ),
              child: const Icon(
                LucideIcons.check,
                size: 9,
                color: AppColors.onPrimary,
              ),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                'login.continue_prefix'.tr().trim(),
                textAlign: TextAlign.center,
                style: _bodyStyle,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text.rich(
          TextSpan(
            text:
                '${'login.continue_terms'.tr()}${'login.continue_suffix'.tr()}',
            style: _linkStyle,
            recognizer: termsTap,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.flagAsset,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String flagAsset;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 36,
        height: 24,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderLight),
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.asset(
          flagAsset,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const ColoredBox(
            color: AppColors.primaryLight,
            child: Icon(
              LucideIcons.globe,
              size: 12,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
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
