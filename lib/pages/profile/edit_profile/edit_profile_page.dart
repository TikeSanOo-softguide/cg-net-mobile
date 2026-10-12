import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../components/app_button/app_button.dart';
import '../../../components/app_input/app_input.dart';
import '../../../core/theme/app_colors/app_colors.dart';
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
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppInput(
              controller: _name,
              label: 'profile.full_name'.tr(),
              prefixIcon: LucideIcons.id_card,
            ),
            const SizedBox(height: 16),
            AppInput(
              controller: _phone,
              label: 'profile.phone'.tr(),
              prefixIcon: LucideIcons.phone,
              keyboardType: TextInputType.phone,
              enabled: false,
            ),
            if (editState.errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                editState.errorMessage!,
                style: const TextStyle(
                  color: AppColors.error,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const Spacer(),
            AppButton(
              label: 'common.save'.tr(),
              isLoading: editState.isLoading,
              onPressed: () async {
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
    );
  }
}
