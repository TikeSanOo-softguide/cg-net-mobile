import 'package:cg_net_mobile/models/show_room_model/show_room_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ShowRoom', () {
    final showroom = ShowRoom.fromJson({
      'id': 3,
      'code': '99',
      'name': {
        'en': 'Kyaing Tong Office',
        'my': 'ကျိုင်းတုံရုံး',
        'zh': '景栋办公室',
      },
      'address': {
        'en': 'Kyaing Tong',
        'my': 'ကျိုင်းတုံ',
        'zh': '景栋',
      },
      'phone_numbers': ['09445272854', ' ', '09768937274'],
      'social_links': {
        'telegram': 'https://t.me/example',
        'wechat': 'weixin://example',
        'viber': 'viber://example',
      },
    });

    test('parses and localizes office fields', () {
      expect(showroom.id, 3);
      expect(showroom.code, '99');
      expect(showroom.nameFor('en'), 'Kyaing Tong Office');
      expect(showroom.addressFor('my'), 'ကျိုင်းတုံ');
      expect(showroom.nameFor('mm'), 'ကျိုင်းတုံရုံး');
      expect(showroom.nameFor('fr'), 'Kyaing Tong Office');
    });

    test('parses phone numbers and social links', () {
      expect(showroom.phoneNumbers, ['09445272854', '09768937274']);
      expect(showroom.socialLinks['telegram'], 'https://t.me/example');
      expect(showroom.socialLinks['wechat'], 'weixin://example');
      expect(showroom.socialLinks['viber'], 'viber://example');
    });
  });
}
