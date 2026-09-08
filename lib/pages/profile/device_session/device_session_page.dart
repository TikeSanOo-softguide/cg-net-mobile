import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors/app_colors.dart';
import 'device_session_controller.dart';

class DeviceSessionPage extends ConsumerWidget {
  const DeviceSessionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devices = ref.watch(deviceSessionControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text('profile.devices_title'.tr())),
      body: ListView.separated(
        itemCount: devices.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final device = devices[index];
          return ListTile(
            leading: Icon(
              device.isCurrent ? Icons.smartphone : Icons.devices_other,
              color: AppColors.secondary,
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
