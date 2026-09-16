import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../components/app_curved_scaffold/app_curved_scaffold.dart';
import '../../../components/empty_state/empty_state.dart';
import '../../../core/theme/app_style/app_style.dart';

/// Shared empty template for all Home services (until real screens exist).
class ServicePlaceholderPage extends StatelessWidget {
  const ServicePlaceholderPage({
    super.key,
    required this.serviceId,
  });

  final String serviceId;

  static String titleForId(String id) {
    switch (id) {
      case 'pay_bill':
        return 'home.service_pay'.tr();
      case 'check_bill':
        return 'home.service_check'.tr();
      case 'history':
        return 'home.service_history'.tr();
      case 'installation':
        return 'home.service_packages'.tr();
      case 'complaint':
        return 'home.service_support'.tr();
      case 'relocation':
        return 'home.service_alerts'.tr();
      case 'check_cpe':
        return 'home.service_check_cpe'.tr();
      case 'change_plan':
        return 'home.service_change_plan'.tr();
      case 'change_wifi':
        return 'home.service_change_wifi'.tr();
      default:
        return 'home.services'.tr();
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = titleForId(serviceId);

    return AppCurvedScaffold(
      title: Text(title),
      showBack: true,
      body: Padding(
        padding: AppStyle.pagePaddingH,
        child: EmptyState(
          icon: LucideIcons.inbox,
          title: title,
          message: 'home.service_placeholder_body'.tr(),
        ),
      ),
    );
  }
}
