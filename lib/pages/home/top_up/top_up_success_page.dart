import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names/route_names.dart';
import 'top_up_result.dart';
import 'top_up_result_shell.dart';

class TopUpSuccessPage extends StatelessWidget {
  const TopUpSuccessPage({super.key, required this.result});

  final TopUpResult result;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        context.goNamed(RouteNames.home);
      },
      child: TopUpResultShell(
        result: result,
        onBack: () => context.goNamed(RouteNames.home),
        primaryLabel: 'common.done'.tr(),
        onPrimary: () => context.goNamed(RouteNames.home),
        secondaryLabel: 'topup.view_history'.tr(),
        onSecondary: () => context.pushNamed(RouteNames.history),
      ),
    );
  }
}
