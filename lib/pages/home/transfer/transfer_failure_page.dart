import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names/route_names.dart';
import 'transfer_result.dart';
import 'transfer_result_shell.dart';

class TransferFailurePage extends StatelessWidget {
  const TransferFailurePage({super.key, required this.result});

  final TransferResult result;

  void _leave(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(RouteNames.transfer);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: TransferResultShell(
        result: result,
        onBack: () => _leave(context),
        primaryLabel: 'common.done'.tr(),
        onPrimary: () => _leave(context),
      ),
    );
  }
}
