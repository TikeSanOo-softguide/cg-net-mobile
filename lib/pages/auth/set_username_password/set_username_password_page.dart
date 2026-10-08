import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../components/app_button/app_button.dart';
import '../../../components/app_input/app_input.dart';
import '../../../components/common_auth_card/common_auth_card.dart';
import '../../../core/locale/app_locale_provider.dart';
import '../../../core/network/api_error_text.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/offline_navigation.dart';
import '../../../core/router/route_names/route_names.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import 'set_username_password_controller.dart';

class SetUsernamePasswordPage extends ConsumerStatefulWidget {
  const SetUsernamePasswordPage({
    super.key,
    required this.phone,
    required this.verificationToken,
  });

  final String phone;
  final String verificationToken;

  @override
  ConsumerState<SetUsernamePasswordPage> createState() =>
      _SetUsernamePasswordPageState();
}

class _SetUsernamePasswordPageState
    extends ConsumerState<SetUsernamePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  String? _usernameServerError;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  String? _validateUsername(String? value) {
    final raw = value ?? '';
    if (raw.trim().isEmpty) {
      return 'set_credentials.username_required'.tr();
    }
    if (raw.contains(' ')) {
      return 'set_credentials.username_spaces'.tr();
    }
    final username = raw.trim();
    if (username.length < 4) {
      return 'set_credentials.username_min'.tr();
    }
    if (!RegExp(r'^[A-Za-z0-9_]+$').hasMatch(username)) {
      return 'set_credentials.username_chars'.tr();
    }
    return _usernameServerError;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) {
      return 'set_credentials.password_required'.tr();
    }
    if (RegExp(r'\D').hasMatch(password)) {
      return 'set_credentials.password_numbers_only'.tr();
    }
    if (password.length != 6) {
      return 'set_credentials.password_digits'.tr();
    }
    return null;
  }

  String? _validateConfirm(String? value) {
    final confirm = value ?? '';
    if (confirm.isEmpty) {
      return 'set_credentials.confirm_required'.tr();
    }
    if (confirm != _password.text) {
      return 'set_credentials.password_mismatch'.tr();
    }
    return null;
  }

  bool _isUsernameTaken(ApiException? error) {
    if (error == null || error.failure != ApiFailure.validation) return false;
    final detail = (error.detail ?? '').toLowerCase();
    return detail.contains('taken') ||
        detail.contains('already') ||
        detail.contains('unique') ||
        (detail.contains('name') && detail.contains('exist'));
  }

  Future<void> _submit() async {
    setState(() => _usernameServerError = null);
    if (!_formKey.currentState!.validate()) return;

    final controller = ref.read(setUsernamePasswordControllerProvider.notifier);
    final ok = await controller.submit(
      verificationToken: widget.verificationToken,
      username: _username.text.trim(),
      password: _password.text,
    );
    if (!mounted) return;
    if (ok) {
      context.goNamed(RouteNames.home);
      return;
    }

    final error = ref.read(setUsernamePasswordControllerProvider).error;
    if (isOfflineError(error)) {
      await openNoInternetPage(context);
      return;
    }
    if (_isUsernameTaken(error)) {
      setState(() {
        _usernameServerError = 'set_credentials.username_taken'.tr();
      });
      _formKey.currentState?.validate();
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(apiErrorOrFallback(error))),
      );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(setUsernamePasswordControllerProvider);
    final _ = context.locale;
    final titleSize = authTitleFontSize(context);
    final subtitleSize = authSubtitleFontSize(context);

    return AuthBackgroundScaffold(
      showBack: true,
      compactTop: true,
      overlayKeyboard: true,
      card: CommonAuthCard(
        iconAsset: 'assets/images/auth/create_account.png',
        title: 'set_credentials.title'.tr(),
        titleColor: AppColors.primary,
        titleFontSize: titleSize,
        titleFontWeight: FontWeight.w700,
        titleLetterSpacing: 0.2,
        description: 'set_credentials.subtitle'.tr(),
        descriptionFontSize: subtitleSize,
        descriptionFontWeight: FontWeight.w500,
        descriptionLetterSpacing: 0.2,
        descriptionHeight: 1.4,
        descriptionLineCount: 2,
        lockDescriptionHeight: false,
        titleBottomGap: 16,
        childTopGap: 20,
        actionTopGap: 24,
        primaryAction: AppButton(
          label: 'set_credentials.create'.tr(),
          height: 44,
          fontSize: 14,
          isLoading: state.isLoading,
          onPressed: state.isLoading ? null : _submit,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppInput(
                controller: _username,
                label: 'set_credentials.username'.tr(),
                hint: 'set_credentials.username'.tr(),
                suffixIcon: LucideIcons.user,
                textInputAction: TextInputAction.next,
                onChanged: (_) {
                  if (_usernameServerError != null) {
                    setState(() => _usernameServerError = null);
                  }
                },
                validator: _validateUsername,
              ),
              const SizedBox(height: 4),
              AppInput(
                controller: _password,
                label: 'set_credentials.password'.tr(),
                hint: 'set_credentials.password_hint'.tr(),
                suffixIcon: LucideIcons.lock,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textInputAction: TextInputAction.next,
                validator: _validatePassword,
              ),
              const SizedBox(height: 4),
              AppInput(
                controller: _confirm,
                label: 'set_credentials.confirm_password'.tr(),
                hint: 'set_credentials.password_hint'.tr(),
                suffixIcon: LucideIcons.lock,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                validator: _validateConfirm,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
