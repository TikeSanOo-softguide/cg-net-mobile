import 'package:cg_net_mobile/pages/auth/set_username_password/set_username_password_page.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('usernameValidationErrorKey', () {
    test('allows spaces in usernames', () {
      expect(usernameValidationErrorKey('John Doe'), isNull);
    });

    test('requires a non-empty username', () {
      expect(
        usernameValidationErrorKey('   '),
        'set_credentials.username_required',
      );
    });

    test('requires at least four characters', () {
      expect(usernameValidationErrorKey('A B'), 'set_credentials.username_min');
    });

    test('rejects unsupported characters', () {
      expect(
        usernameValidationErrorKey('John-Doe'),
        'set_credentials.username_chars',
      );
    });
  });
}
