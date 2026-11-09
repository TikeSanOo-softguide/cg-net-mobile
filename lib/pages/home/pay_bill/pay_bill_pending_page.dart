import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names/route_names.dart';
import 'pay_bill_result.dart';
import 'pay_bill_result_shell.dart';

class PayBillPendingPage extends StatelessWidget {
  const PayBillPendingPage({super.key, required this.result});

  final PayBillResult result;

  @override
  Widget build(BuildContext context) {
    return PayBillResultShell(
      result: result,
      onBack: () => context.goNamed(RouteNames.home),
      primaryLabel: 'common.done'.tr(),
      onPrimary: () => context.goNamed(RouteNames.home),
    );
  }
}
