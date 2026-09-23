import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names/route_names.dart';
import 'top_up_result.dart';
import 'top_up_result_shell.dart';

/// Shown when transaction status is unknown / still processing.
class TopUpPendingPage extends StatelessWidget {
  const TopUpPendingPage({super.key, required this.result});

  final TopUpResult result;

  @override
  Widget build(BuildContext context) {
    return TopUpResultShell(
      result: result,
      onBack: () => context.goNamed(RouteNames.home),
      primaryLabel: 'topup.back_home'.tr(),
      onPrimary: () => context.goNamed(RouteNames.home),
      secondaryLabel: 'topup.view_history'.tr(),
      onSecondary: () => context.pushNamed(RouteNames.history),
    );
  }
}
