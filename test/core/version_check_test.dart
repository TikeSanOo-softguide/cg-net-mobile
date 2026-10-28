import 'package:cg_net_mobile/core/utils/version_check/version_check.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  VersionCheck check(String version, {String buildNumber = '42'}) {
    return VersionCheck(
      PackageInfo(
        appName: 'CG Net',
        packageName: 'cg_net_mobile',
        version: version,
        buildNumber: buildNumber,
      ),
    );
  }

  group('VersionCheck.isForceUpdateRequired', () {
    test('exposes the installed version and build', () {
      final installed = check('1.4.2', buildNumber: '17');

      expect(installed.currentVersion, '1.4.2');
      expect(installed.buildNumber, '17');
    });

    test('is true only when the minimum is newer', () {
      final installed = check('1.2.3');

      expect(installed.isForceUpdateRequired('1.2.4'), isTrue);
      expect(installed.isForceUpdateRequired('1.3.0'), isTrue);
      expect(installed.isForceUpdateRequired('2.0.0'), isTrue);
      expect(installed.isForceUpdateRequired('1.2.3'), isFalse);
      expect(installed.isForceUpdateRequired('1.2.2'), isFalse);
      expect(installed.isForceUpdateRequired('1.1.9'), isFalse);
      expect(installed.isForceUpdateRequired('0.9.9'), isFalse);
    });

    test('treats a missing segment as 0', () {
      expect(check('1.2').isForceUpdateRequired('1.2.0'), isFalse);
      expect(check('1.2').isForceUpdateRequired('1.2.1'), isTrue);
      expect(check('1.2.0').isForceUpdateRequired('1.2'), isFalse);
    });

    test('treats a non-numeric segment as 0', () {
      expect(check('1.0.0').isForceUpdateRequired('1.0.beta'), isFalse);
      expect(check('1.0.beta').isForceUpdateRequired('1.0.1'), isTrue);
    });
  });
}
