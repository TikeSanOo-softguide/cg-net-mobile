import 'package:cg_net_mobile/pages/package/package_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PackageCatalog.byId', () {
    test('returns the matching catalog row', () {
      final item = PackageCatalog.byId('1m');

      expect(item, isNotNull);
      expect(item!.id, '1m');
      expect(item.imagePath, 'assets/images/packages/package_1m.png');
      expect(item.titleKey, 'package.item_1m_title');
      expect(item.descriptionKey, 'package.item_1m_body');
      expect(item.popular, isTrue);
    });

    test('distinguishes ids that share an image and title', () {
      final primary = PackageCatalog.byId('1m');
      final extra = PackageCatalog.byId('1m_extra');

      expect(extra, isNotNull);
      expect(extra!.id, '1m_extra');
      expect(extra.imagePath, primary!.imagePath);
      expect(extra.titleKey, primary.titleKey);
      expect(extra.popular, isFalse);
    });

    test('returns null when the id is unknown', () {
      expect(PackageCatalog.byId('missing'), isNull);
      expect(PackageCatalog.byId('1M'), isNull);
      expect(PackageCatalog.byId(''), isNull);
    });

    test('lists each catalog id once', () {
      final ids = PackageCatalog.items.map((item) => item.id).toList();

      expect(ids, ['1m', '3m', '6m', '1y', '1m_b', '3m_b', '1m_extra']);
      expect(ids.toSet(), hasLength(ids.length));
      final popularIds = PackageCatalog.items
          .where((item) => item.popular)
          .map((item) => item.id);
      expect(popularIds, ['1m']);
    });
  });
}
