import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import '../../../components/app_button/app_button.dart';
import '../../../core/router/route_names/route_names.dart';

class OtpSuccessPage extends StatelessWidget {
  const OtpSuccessPage({super.key, required this.phone});

  final String phone;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Lottie.asset(
                'assets/lottie/success_check.json',
                width: 180,
                height: 180,
                repeat: false,
              ),
              const SizedBox(height: 16),
              Text(
                'otp.success_title'.tr(),
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'otp.success_body'.tr(),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              AppButton(
                label: 'otp.continue_setup'.tr(),
                onPressed: () {
                  context.goNamed(
                    RouteNames.setUsernamePassword,
                    queryParameters: {'phone': phone},
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
