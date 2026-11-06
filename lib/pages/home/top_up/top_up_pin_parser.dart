import 'dart:convert';

String? extractPinFromQr(String raw) {
  final value = raw.trim();
  if (value.isEmpty) return null;

  final decoded = _decodeJson(value);
  if (decoded != null) {
    final pin = _findPin(decoded);
    if (pin != null) return pin;
  }

  final query = Uri.tryParse(value)?.queryParameters;
  if (query != null) {
    final pin = _findPin(query);
    if (pin != null) return pin;
  }

  final labeledPin = RegExp(
    r'''(?:^|[\s,;&|])(?:pin|pin[_ -]?(?:code|number|no)|card[_ -]?pin)\s*[:=]\s*["']?([0-9][0-9 -]{5,})''',
    caseSensitive: false,
  ).firstMatch(value);
  if (labeledPin != null) {
    return labeledPin.group(1)?.replaceAll(RegExp(r'\D'), '');
  }

  if (RegExp(r'^[0-9][0-9 -]*$').hasMatch(value)) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 16) return digits;
  }
  return null;
}

Object? _decodeJson(String value) {
  try {
    return jsonDecode(value);
  } on FormatException {
    return null;
  }
}

String? _findPin(Object? value) {
  if (value is Map) {
    for (final entry in value.entries) {
      if (_isPinKey(entry.key.toString())) {
        final pin = entry.value?.toString().trim();
        if (pin != null && pin.isNotEmpty) return pin;
      }
    }
    for (final entry in value.entries) {
      final pin = _findPin(entry.value);
      if (pin != null) return pin;
    }
  } else if (value is List) {
    for (final item in value) {
      final pin = _findPin(item);
      if (pin != null) return pin;
    }
  }
  return null;
}

bool _isPinKey(String key) {
  final normalized = key.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
  return const {
    'pin',
    'pincode',
    'pinnumber',
    'pinno',
    'cardpin',
    'rechargepin',
  }.contains(normalized);
}
