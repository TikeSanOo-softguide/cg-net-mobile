import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../components/app_button/app_button.dart';
import '../../../components/app_input/app_input.dart';
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
    final controller =
        ref.read(setUsernamePasswordControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text('set_credentials.title'.tr())),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'set_credentials.subtitle'.tr(),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              AppInput(
                controller: _username,
                label: 'set_credentials.username'.tr(),
                validator: (v) =>
                    (v == null || v.trim().length < 3) ? 'Username' : null,
              ),
              const SizedBox(height: 16),
              AppInput(
                controller: _password,
                label: 'set_credentials.password'.tr(),
                obscureText: true,
                validator: (v) =>
                    (v == null || v.length < 6) ? 'Password' : null,
              ),
              const SizedBox(height: 16),
              AppInput(
                controller: _confirm,
                label: 'set_credentials.confirm_password'.tr(),
                obscureText: true,
                validator: (v) =>
                    v != _password.text ? 'Password mismatch' : null,
              ),
              const SizedBox(height: 32),
              AppButton(
                label: 'set_credentials.create'.tr(),
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
            ],
          ),
        ),
      ),
    );
  }
}
