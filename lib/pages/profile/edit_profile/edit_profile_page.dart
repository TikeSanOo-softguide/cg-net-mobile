import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../components/app_button/app_button.dart';
import '../../../components/app_input/app_input.dart';
import '../profile/profile_controller.dart';
import 'edit_profile_controller.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  late final TextEditingController _name;
  late final TextEditingController _email;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileControllerProvider);
    _name = TextEditingController(text: profile.fullName);
    _email = TextEditingController(text: profile.email ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final saving = ref.watch(editProfileControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text('profile.edit_title'.tr())),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            AppInput(
              controller: _name,
              label: 'profile.full_name'.tr(),
            ),
            const SizedBox(height: 16),
            AppInput(
              controller: _email,
              label: 'profile.email'.tr(),
              keyboardType: TextInputType.emailAddress,
            ),
            const Spacer(),
            AppButton(
              label: 'common.save'.tr(),
              isLoading: saving,
              onPressed: () async {
                await ref
                    .read(editProfileControllerProvider.notifier)
                    .save(fullName: _name.text.trim(), email: _email.text.trim());
                if (context.mounted) context.pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}
