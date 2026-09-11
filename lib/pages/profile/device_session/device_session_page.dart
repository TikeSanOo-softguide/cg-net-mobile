import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../core/theme/app_colors/app_colors.dart';
import 'device_session_controller.dart';
import '../../../components/app_curved_scaffold/app_curved_scaffold.dart';

class DeviceSessionPage extends ConsumerWidget {
  const DeviceSessionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devices = ref.watch(deviceSessionControllerProvider);

    return AppCurvedScaffold(
      title: Text('profile.devices_title'.tr()),
      showBack: true,
      body: ListView.separated(
        itemCount: devices.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final device = devices[index];
          return ListTile(
            leading: Icon(
              device.isCurrent
                  ? LucideIcons.smartphone
                  : LucideIcons.monitor_smartphone,
              color: AppColors.primary,
            ),
            title: Text(device.name),
            subtitle: Text(device.lastActive),
            trailing: device.isCurrent
                ? const Text(
                    'Current',
                    style: TextStyle(color: AppColors.success),
                  )
                : TextButton(
                    onPressed: () => ref
                        .read(deviceSessionControllerProvider.notifier)
                        .revoke(device.id),
                    child: Text('common.cancel'.tr()),
                  ),
          );
        },
      ),
    );
  }
}
