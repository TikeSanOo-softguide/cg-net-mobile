import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router/go_router.dart';

import '../../../components/app_button/app_button.dart';
import '../../../components/common_auth_card/common_auth_card.dart';
import '../../../core/router/route_names/route_names.dart';

class OtpSuccessPage extends StatelessWidget {
  const OtpSuccessPage({super.key, required this.phone});

  final String phone;

  @override
  Widget build(BuildContext context) {
    return AuthBackgroundScaffold(
      card: CommonAuthCard(
        icon: LucideIcons.circle_check,
        title: 'otp.success_title'.tr(),
        description: 'otp.success_body'.tr(),
        primaryAction: AppButton(
          label: 'otp.continue_setup'.tr(),
          onPressed: () {
            context.goNamed(
              RouteNames.setUsernamePassword,
              queryParameters: {'phone': phone},
            );
          },
        ),
      ),
    );
  }
}
