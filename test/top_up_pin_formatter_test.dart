import 'package:cg_net_mobile/pages/home/top_up/top_up_page.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final formatter = PinSpaceFormatter();

  test('groups a 16-digit PIN into four-digit blocks', () {
    final result = formatter.formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(
        text: '4444444444444444',
        selection: TextSelection.collapsed(offset: 16),
      ),
    );

    expect(result.text, '4444 4444 4444 4444');
    expect(result.selection, const TextSelection.collapsed(offset: 19));
  });

  test('limits PIN input to 16 digits', () {
    final result = formatter.formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(
        text: '44444444444444445',
        selection: TextSelection.collapsed(offset: 17),
      ),
    );

    expect(result.text, '4444 4444 4444 4444');
  });

  test('keeps the cursor near the edited digit', () {
    final result = formatter.formatEditUpdate(
      const TextEditingValue(
        text: '4444 4444',
        selection: TextSelection.collapsed(offset: 6),
      ),
      const TextEditingValue(
        text: '4444 9444',
        selection: TextSelection.collapsed(offset: 6),
      ),
    );

    expect(result.selection, const TextSelection.collapsed(offset: 6));
  });
}
