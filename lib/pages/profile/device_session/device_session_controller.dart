import 'package:flutter_riverpod/flutter_riverpod.dart';

class DeviceSession {
  const DeviceSession({
    required this.id,
    required this.name,
    required this.lastActive,
    this.isCurrent = false,
  });

  final String id;
  final String name;
  final String lastActive;
  final bool isCurrent;
}

class DeviceSessionController extends StateNotifier<List<DeviceSession>> {
  DeviceSessionController()
      : super(const [
          DeviceSession(
            id: 'd1',
            name: 'This device',
            lastActive: 'Active now',
            isCurrent: true,
          ),
          DeviceSession(
            id: 'd2',
            name: 'iPhone 14',
            lastActive: '2 days ago',
          ),
        ]);

  void revoke(String id) {
    state = state.where((d) => d.id != id).toList();
  }
}

final deviceSessionControllerProvider =
    StateNotifierProvider<DeviceSessionController, List<DeviceSession>>((ref) {
  return DeviceSessionController();
});
