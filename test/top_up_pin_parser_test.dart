import 'package:cg_net_mobile/pages/home/top_up/top_up_pin_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('extracts PIN rather than serial from labeled QR contents', () {
    expect(
      extractPinFromQr('Serial: 1234567890123456, PIN: 6543210987654321'),
      '6543210987654321',
    );
  });

  test('extracts PIN from JSON and query-string QR contents', () {
    expect(
      extractPinFromQr(
        '{"serial_number":"1234567890123456","pin_code":"6543210987654321"}',
      ),
      '6543210987654321',
    );
    expect(
      extractPinFromQr('https://example.test/card?serial=123456&pin=654321'),
      '654321',
    );
  });

  test('accepts a PIN-only QR and rejects a serial-only QR', () {
    expect(extractPinFromQr('6543210987654321'), '6543210987654321');
    expect(extractPinFromQr('Serial: 1234567890123456'), isNull);
  });
}
