import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../components/app_button/app_button.dart';
import '../../../components/app_input/app_input.dart';
import 'change_password_controller.dart';
import '../../../components/app_curved_scaffold/app_curved_scaffold.dart';

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
          padding: const EdgeInsets.all(24),
          children: [
            AppInput(
              controller: _current,
              label: 'profile.current_password'.tr(),
              prefixIcon: LucideIcons.lock,
              obscureText: true,
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            AppInput(
              controller: _next,
              label: 'profile.new_password'.tr(),
              prefixIcon: LucideIcons.lock,
              obscureText: true,
              validator: (v) => (v == null || v.length < 6) ? 'Min 6' : null,
            ),
            const SizedBox(height: 16),
            AppInput(
              controller: _confirm,
              label: 'set_credentials.confirm_password'.tr(),
              prefixIcon: LucideIcons.lock,
              obscureText: true,
              validator: (v) => v != _next.text ? 'Mismatch' : null,
            ),
            const SizedBox(height: 32),
            AppButton(
              label: 'common.save'.tr(),
              isLoading: loading,
              onPressed: () async {
                if (!_formKey.currentState!.validate()) return;
                await ref
                    .read(changePasswordControllerProvider.notifier)
                    .submit();
                if (context.mounted) context.pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}
