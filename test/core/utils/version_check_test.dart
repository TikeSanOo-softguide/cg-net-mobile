import 'package:cg_net_mobile/core/utils/version_check/version_check.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  test('detects when the installed version is already current', () {
    final check = VersionCheck(_packageInfo('2.1.0'));

    expect(check.isLatestVersion('2.1.0'), isTrue);
    expect(check.isLatestVersion('2.0.9'), isTrue);
    expect(check.isLatestVersion('2.1.1'), isFalse);
  });
}

PackageInfo _packageInfo(String version) {
  return PackageInfo(
    appName: 'Test app',
    packageName: 'test.app',
    version: version,
    buildNumber: '1',
  );
}
