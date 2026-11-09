import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names/route_names.dart';
import 'pay_bill_result.dart';
import 'pay_bill_result_shell.dart';

class PayBillFailurePage extends StatelessWidget {
  const PayBillFailurePage({super.key, required this.result});

  final PayBillResult result;

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
      child: PayBillResultShell(
        result: result,
        onBack: () => _leave(context),
        primaryLabel: 'common.done'.tr(),
        onPrimary: () => _leave(context),
      ),
    );
  }
}
