import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../components/app_button/app_button.dart';
import '../../../components/app_curved_scaffold/app_curved_scaffold.dart';
import '../../../components/app_input/app_input.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import '../../../core/theme/app_style/app_style.dart';
import '../../../core/theme/app_theme/app_theme.dart';

/// Packages tab — common `AppInput` field examples.
class PackageListPage extends StatefulWidget {
  const PackageListPage({super.key});

  @override
  State<PackageListPage> createState() => _PackageListPageState();
}

class _PackageListPageState extends State<PackageListPage> {
  final _formKey = GlobalKey<FormState>();
  final _search = TextEditingController();
  final _account = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _note = TextEditingController();
  bool _obscurePin = true;

  final _pin = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    _account.dispose();
    _phone.dispose();
    _email.dispose();
    _note.dispose();
    _pin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppCurvedScaffold(
      title: Text('package.title'.tr()),
      showBack: false,
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppStyle.pagePadding,
          children: [
            Text(
              'package.input_example_title'.tr(),
              style: AppTheme.sectionTitle(),
            ),
            const SizedBox(height: AppStyle.spaceXs),
            Text(
              'package.input_example_body'.tr(),
              style: AppTheme.bodySecondary(),
            ),
            const SizedBox(height: AppStyle.spaceXl),
            AppInput(
              controller: _search,
              label: 'package.search_label'.tr(),
              hint: 'package.search_hint'.tr(),
              prefixIcon: LucideIcons.search,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppStyle.spaceMd),
            AppInput(
              controller: _account,
              label: 'package.account_label'.tr(),
              hint: 'package.account_hint'.tr(),
              prefixIcon: LucideIcons.hash,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(12),
              ],
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppStyle.spaceMd),
            AppInput(
              controller: _phone,
              label: 'profile.phone'.tr(),
              hint: 'login.phone_hint'.tr(),
              prefixIcon: LucideIcons.phone,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(12),
              ],
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppStyle.spaceMd),
            AppInput(
              controller: _email,
              label: 'profile.email'.tr(),
              hint: 'package.email_hint'.tr(),
              prefixIcon: LucideIcons.mail,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppStyle.spaceMd),
            AppInput(
              controller: _pin,
              label: 'package.pin_label'.tr(),
              hint: 'package.pin_hint'.tr(),
              obscureText: _obscurePin,
              prefixIcon: LucideIcons.lock,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              suffix: IconButton(
                onPressed: () => setState(() => _obscurePin = !_obscurePin),
                icon: Icon(
                  _obscurePin ? LucideIcons.eye_off : LucideIcons.eye,
                  size: AppStyle.iconSizeSm,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: AppStyle.spaceMd),
            AppInput(
              controller: _note,
              label: 'package.note_label'.tr(),
              hint: 'package.note_hint'.tr(),
              prefixIcon: LucideIcons.file_text,
              maxLines: 3,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: AppStyle.spaceXxl),
            AppButton(
              label: 'common.save'.tr(),
              icon: LucideIcons.check,
              onPressed: () {
                FocusScope.of(context).unfocus();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('package.input_saved'.tr()),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
