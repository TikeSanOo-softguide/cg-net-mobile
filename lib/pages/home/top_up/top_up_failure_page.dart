import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names/route_names.dart';
import 'top_up_result.dart';
import 'top_up_result_shell.dart';

class TopUpFailurePage extends StatelessWidget {
  const TopUpFailurePage({super.key, required this.result});

  final TopUpResult result;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: TopUpResultShell(
        result: result,
        onBack: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.goNamed(RouteNames.topUp);
          }
        },
        primaryLabel: 'common.done'.tr(),
        onPrimary: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.goNamed(RouteNames.topUp);
          }
        },
      ),
    );
  }
}
