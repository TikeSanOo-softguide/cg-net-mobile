import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

class VersionCheck {
  VersionCheck(this._packageInfo);

  final PackageInfo _packageInfo;

  String get currentVersion => _packageInfo.version;
  String get buildNumber => _packageInfo.buildNumber;

  /// Compare semantic versions. Returns true when [minimumRequired] is newer.
  bool isForceUpdateRequired(String minimumRequired) {
    return _compare(currentVersion, minimumRequired) < 0;
  }

  int _compare(String a, String b) {
    final aParts = a.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final bParts = b.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final len = aParts.length > bParts.length ? aParts.length : bParts.length;
    for (var i = 0; i < len; i++) {
      final av = i < aParts.length ? aParts[i] : 0;
      final bv = i < bParts.length ? bParts[i] : 0;
      if (av != bv) return av.compareTo(bv);
    }
    return 0;
  }
}

final packageInfoProvider = FutureProvider<PackageInfo>((ref) {
  return PackageInfo.fromPlatform();
});

final versionCheckProvider = FutureProvider<VersionCheck>((ref) async {
  final info = await ref.watch(packageInfoProvider.future);
  return VersionCheck(info);
});
