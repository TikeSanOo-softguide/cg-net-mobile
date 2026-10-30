import 'package:intl/intl.dart';

final _dateOnlyPattern = RegExp(r'^\d{4}[-/]\d{2}[-/]\d{2}$');
final _dateTimePrefixPattern = RegExp(r'^\d{4}-\d{2}-\d{2}[T ]');
final _timezonePattern = RegExp(
  r'(?:Z|[+-]\d{2}:?\d{2})$',
  caseSensitive: false,
);

bool _isDateOnly(String value) => _dateOnlyPattern.hasMatch(value);
bool _hasTimezone(String value) => _timezonePattern.hasMatch(value);

DateTime? _parseDate(String value) {
  var normalized = value.replaceAll('/', '-');

  try {
    if (_isDateOnly(normalized)) {
      return DateFormat('yyyy-MM-dd').parseStrict(normalized, true);
    }

    final hasTimezone = _hasTimezone(normalized);

    if (!hasTimezone && _dateTimePrefixPattern.hasMatch(normalized)) {
      normalized = '${normalized.replaceFirst(' ', 'T')}Z';
    }

    return DateTime.tryParse(normalized);
  } on FormatException {
    return null;
  }
}

String formatDate(String? value) {
  if (value == null || value.trim().isEmpty) return '—';

  final trimmed = value.trim();
  final date = _parseDate(trimmed);

  if (date == null) return trimmed;

  final displayDate = _isDateOnly(trimmed) ? date : date.toLocal();

  return DateFormat('d MMM yyyy').format(displayDate);
}

String formatDateTime(String? value, {bool isUTC = false}) {
  if (value == null || value.trim().isEmpty) return '—';

  final trimmed = value.trim();
  final date = _parseDate(trimmed);

  if (date == null) return trimmed;

  final displayDate = _isDateOnly(trimmed)
      ? date
      : isUTC
          ? date.toUtc()
          : date;

  return DateFormat('d MMM yyyy hh:mm:ss a').format(displayDate);
}
