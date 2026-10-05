import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../components/app_button/app_button.dart';
import '../../../core/router/route_names/route_names.dart';
import '../../../core/theme/app_colors/app_colors.dart';

class ErrorNoInternetPage extends StatelessWidget {
  const ErrorNoInternetPage({
    super.key,
    this.returnToPath,
  });

  final String? returnToPath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                LucideIcons.wifi_off,
                size: 72,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 16),
              Text(
                'shared.no_internet_title'.tr(),
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'shared.no_internet_body'.tr(),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              AppButton(
                label: 'common.retry'.tr(),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop(true);
                  } else {
                    final target = returnToPath?.trim();
                    if (target != null && target.isNotEmpty) {
                      context.go(target);
                    } else {
                      context.go(RoutePaths.home);
                    }
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
