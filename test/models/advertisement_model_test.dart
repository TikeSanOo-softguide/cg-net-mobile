import 'package:cg_net_mobile/models/advertisement_model/advertisement_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Advertisement.fromJson', () {
    test('reads duration, active flag, and date window', () {
      final start = DateTime(2020, 1, 1);
      final end = DateTime(2099, 12, 31, 23, 59, 59);
      final ad = Advertisement.fromJson(<String, dynamic>{
        'id': 42,
        'image': 'assets/images/launch/advertisement.png',
        'title': 'December Promotion',
        'description': 'Seasonal broadband offer',
        'duration': 8,
        'duration_seconds': 12,
        'is_active': true,
        'start_date': start,
        'end_date': end.toIso8601String(),
        'action_url': 'https://example.com/promo',
        'action_type': 'url',
      });

      expect(ad.id, '42');
      expect(ad.image, 'assets/images/launch/advertisement.png');
      expect(ad.title, 'December Promotion');
      expect(ad.description, 'Seasonal broadband offer');
      expect(ad.durationSeconds, 8);
      expect(ad.isActive, isTrue);
      expect(ad.startDate, start);
      expect(ad.endDate, end);
      expect(ad.actionUrl, 'https://example.com/promo');
      expect(ad.actionType, 'url');
      expect(ad.isCurrentlyValid, isTrue);
    });

    test('falls back to duration_seconds, then 5', () {
      final fromAlias = Advertisement.fromJson(<String, dynamic>{
        'image': 'ad.png',
        'duration_seconds': 12,
        'is_active': 1,
      });
      final fromDefault = Advertisement.fromJson(<String, dynamic>{
        'image': 'ad.png',
      });

      expect(fromAlias.id, isEmpty);
      expect(fromAlias.durationSeconds, 12);
      expect(fromAlias.isActive, isTrue);
      expect(fromAlias.title, isNull);
      expect(fromDefault.durationSeconds, 5);
      expect(fromDefault.isActive, isFalse);
    });

    test('ignores inactive values other than true or 1', () {
      for (final flag in [0, 'true', '1', false, null]) {
        final ad = Advertisement.fromJson(<String, dynamic>{
          'image': 'ad.png',
          'is_active': flag,
        });
        expect(ad.isActive, isFalse, reason: 'is_active=$flag');
      }
    });

    test('drops unparseable dates', () {
      final ad = Advertisement.fromJson(<String, dynamic>{
        'id': 'bad-dates',
        'image': 'ad.png',
        'is_active': true,
        'start_date': 'not-a-date',
        'end_date': '',
      });

      expect(ad.startDate, isNull);
      expect(ad.endDate, isNull);
      expect(ad.isCurrentlyValid, isTrue);
    });

    test('toJson writes the API field names', () {
      final start = DateTime(2025, 12, 1);
      final end = DateTime(2026, 12, 31, 23, 59, 59);
      final ad = Advertisement(
        id: 'local_december_promo',
        image: 'assets/images/launch/advertisement.png',
        title: 'December Promotion',
        description: 'Seasonal broadband offer',
        durationSeconds: 5,
        isActive: true,
        startDate: start,
        endDate: end,
        actionType: 'none',
      );

      expect(ad.toJson(), {
        'id': 'local_december_promo',
        'image': 'assets/images/launch/advertisement.png',
        'title': 'December Promotion',
        'description': 'Seasonal broadband offer',
        'duration': 5,
        'is_active': true,
        'start_date': start.toIso8601String(),
        'end_date': end.toIso8601String(),
        'action_url': null,
        'action_type': 'none',
      });
    });
  });

  group('Advertisement.isCurrentlyValid', () {
    Advertisement ad({
      bool isActive = true,
      String image = 'ad.png',
      DateTime? startDate,
      DateTime? endDate,
    }) {
      return Advertisement(
        id: 'ad',
        image: image,
        durationSeconds: 5,
        isActive: isActive,
        startDate: startDate,
        endDate: endDate,
      );
    }

    test('requires an active flag and a non-blank image inside the window', () {
      expect(ad().isCurrentlyValid, isTrue);
      expect(ad(isActive: false).isCurrentlyValid, isFalse);
      expect(ad(image: '   ').isCurrentlyValid, isFalse);
      expect(ad(image: '').isCurrentlyValid, isFalse);
      expect(
        ad(startDate: DateTime(2099)).isCurrentlyValid,
        isFalse,
      );
      expect(
        ad(endDate: DateTime(2000)).isCurrentlyValid,
        isFalse,
      );
      expect(
        ad(
          startDate: DateTime(2000),
          endDate: DateTime(2099),
        ).isCurrentlyValid,
        isTrue,
      );
    });
  });
}
