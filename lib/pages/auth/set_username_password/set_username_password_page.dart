import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../components/app_button/app_button.dart';
import '../../../components/app_input/app_input.dart';
import '../../../components/common_auth_card/common_auth_card.dart';
import '../../../core/router/route_names/route_names.dart';
import 'set_username_password_controller.dart';

class SetUsernamePasswordPage extends ConsumerStatefulWidget {
  const SetUsernamePasswordPage({super.key, required this.phone});

  final String phone;

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

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(setUsernamePasswordControllerProvider);
    final controller = ref.read(setUsernamePasswordControllerProvider.notifier);

    return AuthBackgroundScaffold(
      showBack: true,
      compactTop: true,
      topBarTitle: 'set_credentials.title'.tr(),
      card: CommonAuthCard(
        icon: LucideIcons.user_round_plus,
        title: 'set_credentials.title'.tr(),
        description: 'set_credentials.subtitle'.tr(),
        primaryAction: AppButton(
          label: 'set_credentials.create'.tr(),
          height: 42,
          fontSize: 13,
          isLoading: state.isLoading,
          onPressed: () async {
            if (!_formKey.currentState!.validate()) return;
            final ok = await controller.submit(
              username: _username.text.trim(),
              password: _password.text,
              phone: widget.phone,
            );
            if (ok && context.mounted) {
              context.goNamed(RouteNames.home);
            }
          },
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
                validator: (v) =>
                    (v == null || v.trim().length < 3) ? 'Username' : null,
              ),
              const SizedBox(height: 12),
              AppInput(
                controller: _password,
                label: 'set_credentials.password'.tr(),
                hint: 'set_credentials.password'.tr(),
                suffixIcon: LucideIcons.lock,
                obscureText: true,
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    (v == null || v.length < 6) ? 'Password' : null,
              ),
              const SizedBox(height: 12),
              AppInput(
                controller: _confirm,
                label: 'set_credentials.confirm_password'.tr(),
                hint: 'set_credentials.confirm_password'.tr(),
                suffixIcon: LucideIcons.lock,
                obscureText: true,
                textInputAction: TextInputAction.done,
                validator: (v) =>
                    v != _password.text ? 'Password mismatch' : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
