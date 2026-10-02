import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names/route_names.dart';
import 'package_buy_result.dart';
import 'package_buy_result_shell.dart';

class PackageBuySuccessPage extends StatelessWidget {
  const PackageBuySuccessPage({super.key, required this.result});

  final PackageBuyResult result;

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
      child: PackageBuyResultShell(
        result: result,
        onBack: () => _leave(context),
        primaryLabel: 'common.done'.tr(),
        onPrimary: () => _leave(context),
      ),
    );
  }
}
