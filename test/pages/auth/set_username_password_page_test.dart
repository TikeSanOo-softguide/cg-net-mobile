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

    test('allows Myanmar and Chinese letters', () {
      expect(usernameValidationErrorKey('မောင်မောင်'), isNull);
      expect(usernameValidationErrorKey('张伟用户'), isNull);
    });

    test('rejects special characters', () {
      expect(
        usernameValidationErrorKey('John-Doe'),
        'set_credentials.username_chars',
      );
      expect(
        usernameValidationErrorKey('မောင်@net'),
        'set_credentials.username_chars',
      );
    });
  });
}
