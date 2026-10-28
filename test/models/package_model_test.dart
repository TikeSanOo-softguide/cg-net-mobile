import 'dart:convert';

import 'package:cg_net_mobile/models/package_model/package_model.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PackageModel', () {
    test('fromJson parses assets/mock/packages.json', () async {
      final raw = await rootBundle.loadString('assets/mock/packages.json');
      final packages = (jsonDecode(raw) as List<dynamic>)
          .map((e) => PackageModel.fromJson(e as Map<String, dynamic>))
          .toList();

      expect(packages, hasLength(4));

      final current = packages.first;
      expect(current.id, 'pkg_home_50');
      expect(current.name, 'Home Fiber 50');
      expect(current.speed, '50 Mbps');
      expect(current.price, 25000);
      expect(current.currency, 'MMK');
      expect(current.billingCycle, 'monthly');
      expect(current.dataLimit, 'Unlimited');
      expect(current.isCurrent, isTrue);
      expect(current.features, [
        'Unlimited data',
        'Free Wi-Fi router',
        '24/7 support',
        'No contract lock-in',
      ]);
      expect(current.formattedPrice, 'MMK 25000');

      expect(
        packages.map((p) => p.id),
        ['pkg_home_50', 'pkg_home_100', 'pkg_biz_200', 'pkg_ultra_500'],
      );
      expect(packages.map((p) => p.price), [25000, 45000, 98000, 165000]);
      expect(packages.skip(1).every((p) => !p.isCurrent), isTrue);
      expect(packages[1].formattedPrice, 'MMK 45000');
      expect(packages[3].name, 'Ultra Fiber 500');
      expect(packages[3].speed, '500 Mbps');
    });

    test('fromJson defaults isCurrent and features when omitted', () {
      final model = PackageModel.fromJson(<String, dynamic>{
        'id': 'pkg_edge',
        'name': 'Edge',
        'speed': '10 Mbps',
        'price': 10.2,
        'currency': 'MMK',
        'billing_cycle': 'yearly',
        'data_limit': '100 GB',
      });

      expect(model.isCurrent, isFalse);
      expect(model.features, isEmpty);
      expect(model.formattedPrice, 'MMK 10');
    });

    test('fromJson stringifies non-string feature entries', () {
      final model = PackageModel.fromJson(<String, dynamic>{
        'id': 'pkg_mixed',
        'name': 'Mixed',
        'speed': '1 Mbps',
        'price': 10.8,
        'currency': 'THB',
        'billing_cycle': 'monthly',
        'data_limit': 'Unlimited',
        'is_current': true,
        'features': <dynamic>['router', 2, true],
      });

      expect(model.features, ['router', '2', 'true']);
      expect(model.formattedPrice, 'THB 11');
    });

    test('fromJson throws when a required field is missing', () {
      expect(
        () => PackageModel.fromJson(<String, dynamic>{
          'name': 'Home Fiber 50',
          'speed': '50 Mbps',
          'price': 25000,
          'currency': 'MMK',
          'billing_cycle': 'monthly',
          'data_limit': 'Unlimited',
        }),
        throwsA(isA<TypeError>()),
      );
    });

    test('toJson round-trips the mock-shaped fields', () {
      const model = PackageModel(
        id: 'pkg_home_50',
        name: 'Home Fiber 50',
        speed: '50 Mbps',
        price: 25000,
        currency: 'MMK',
        billingCycle: 'monthly',
        dataLimit: 'Unlimited',
        isCurrent: true,
        features: ['Unlimited data', 'Free Wi-Fi router'],
      );

      final json = model.toJson();
      expect(json, {
        'id': 'pkg_home_50',
        'name': 'Home Fiber 50',
        'speed': '50 Mbps',
        'price': 25000,
        'currency': 'MMK',
        'billing_cycle': 'monthly',
        'data_limit': 'Unlimited',
        'is_current': true,
        'features': ['Unlimited data', 'Free Wi-Fi router'],
      });

      final again = PackageModel.fromJson(
        jsonDecode(jsonEncode(json)) as Map<String, dynamic>,
      );
      expect(again.id, model.id);
      expect(again.name, model.name);
      expect(again.speed, model.speed);
      expect(again.price, model.price);
      expect(again.currency, model.currency);
      expect(again.billingCycle, model.billingCycle);
      expect(again.dataLimit, model.dataLimit);
      expect(again.isCurrent, model.isCurrent);
      expect(again.features, model.features);
      expect(again.formattedPrice, 'MMK 25000');
    });
  });
}
