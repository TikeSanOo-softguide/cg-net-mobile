import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names/route_names.dart';
import 'package_buy_result.dart';
import 'package_buy_result_shell.dart';

class PackageBuyFailurePage extends StatelessWidget {
  const PackageBuyFailurePage({super.key, required this.result});

  final PackageBuyResult result;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: PackageBuyResultShell(
        result: result,
        onBack: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.goNamed(RouteNames.packageList);
          }
        },
        primaryLabel: 'common.done'.tr(),
        onPrimary: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.goNamed(RouteNames.packageList);
          }
        },
      ),
    );
  }
}
