import 'package:flutter_test/flutter_test.dart';
import 'package:cg_net_mobile/core/utils/date_time_format.dart';

void main() {
  group('formatDate', () {
    test('formats date-only values without shifting the calendar date', () {
      expect(formatDate('2026-10-29'), '29 Oct 2026');
    });

    test('interprets timezone-less timestamps as UTC', () {
      expect(formatDate('2026-10-29 10:30:45'), '29 Oct 2026');
    });

    test('returns an em dash for missing values', () {
      expect(formatDate(null), '—');
      expect(formatDate(''), '—');
    });

    test('preserves invalid input', () {
      expect(formatDate('not a date'), 'not a date');
    });
  });

  group('formatDateTime', () {
    test('formats timezone-less timestamps as UTC', () {
      expect(
        formatDateTime('2026-10-29 10:30:45'),
        '29 Oct 2026 10:30:45 AM',
      );
    });

    test('can format timezone-aware values in UTC', () {
      expect(
        formatDateTime('2026-10-29T10:30:45+06:30', isUTC: true),
        '29 Oct 2026 04:00:45 AM',
      );
    });

    test('returns an em dash for missing values', () {
      expect(formatDateTime(null), '—');
      expect(formatDateTime(''), '—');
    });

    test('preserves invalid input', () {
      expect(formatDateTime('not a date'), 'not a date');
    });
  });
}
