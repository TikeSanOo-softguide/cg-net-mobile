import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:smart_auth/smart_auth.dart';

/// Android SMS User Consent. One message, after the user allows it.
/// Keyboard autofill stays in place for iOS and when consent is dismissed.
class OtpSmsConsent {
  OtpSmsConsent._();

  static final instance = OtpSmsConsent._();

  static final _codePattern = RegExp(r'\d{6}');

  int _session = 0;
  bool _listening = false;
  String? _pending;
  void Function(String code)? _onCode;

  bool get _supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Start before the server sends the SMS. Returns once listening has begun.
  Future<void> arm() async {
    if (!_supported || _listening) return;
    final session = ++_session;
    _listening = true;
    final pending = SmartAuth.instance.getSmsWithUserConsentApi(
      matcher: r'\d{6}',
    );
    unawaited(_consume(session, pending));
  }

  /// OTP screen receives a code that arrived early, then any later one.
  void bind(void Function(String code) onCode) {
    _onCode = onCode;
    final pending = _pending;
    if (pending != null) {
      _pending = null;
      onCode(pending);
    }
    if (!_listening) {
      unawaited(arm());
    }
  }

  /// Resend replaces the wait so the new SMS can be read.
  Future<void> restart() async {
    _pending = null;
    await _cancel(keepHandler: true);
    await arm();
  }

  Future<void> stop() => _cancel(keepHandler: false);

  Future<void> _cancel({required bool keepHandler}) async {
    _session++;
    _listening = false;
    if (!keepHandler) {
      _onCode = null;
      _pending = null;
    }
    if (!_supported) return;
    try {
      await SmartAuth.instance.removeUserConsentApiListener();
    } catch (_) {}
  }

  Future<void> _consume(
    int session,
    Future<SmartAuthResult<SmartAuthSms>> pending,
  ) async {
    try {
      final result = await pending;
      if (session != _session) return;
      _listening = false;
      if (!result.hasData) return;
      final raw = result.data?.code;
      if (raw == null) return;
      final code = _codePattern.firstMatch(raw)?.group(0);
      if (code == null) return;
      _deliver(code);
    } catch (_) {
      if (session == _session) _listening = false;
    }
  }

  void _deliver(String code) {
    final handler = _onCode;
    if (handler == null) {
      _pending = code;
      return;
    }
    handler(code);
  }
}
