import 'package:cg_net_mobile/pages/auth/login/login_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CountryDial.fromPhoneNumber', () {
    test('detects supported prefixes from raw API phone numbers', () {
      expect(
        CountryDial.fromPhoneNumber('8613800138001'),
        CountryDial.china,
      );
      expect(
        CountryDial.fromPhoneNumber('95977745544445'),
        CountryDial.myanmar,
      );
      expect(
        CountryDial.fromPhoneNumber('66923456789'),
        CountryDial.thailand,
      );
    });

    test('also detects formatted numbers and rejects unsupported prefixes', () {
      expect(
        CountryDial.fromPhoneNumber('+86 138 0013 8001'),
        CountryDial.china,
      );
      expect(CountryDial.fromPhoneNumber('14155550123'), isNull);
    });
  });
}
