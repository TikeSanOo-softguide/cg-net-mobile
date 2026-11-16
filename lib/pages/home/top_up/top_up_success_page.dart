import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names/route_names.dart';
import 'top_up_result.dart';
import 'top_up_result_shell.dart';

class TopUpSuccessPage extends StatelessWidget {
  const TopUpSuccessPage({
    super.key,
    required this.result,
    this.showPrimary = true,
  });

  final TopUpResult result;
  final bool showPrimary;

  void _leave(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(RouteNames.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        context.goNamed(RouteNames.home);
      },
      child: TopUpResultShell(
        result: result,
        onBack: () => _leave(context),
        primaryLabel: 'common.done'.tr(),
        onPrimary: () => _leave(context),
        showPrimary: showPrimary,
      ),
    );
  }
}
