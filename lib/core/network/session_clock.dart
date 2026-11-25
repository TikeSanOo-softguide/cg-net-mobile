import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SessionClock extends ChangeNotifier {
  bool _expiredByUnauthorized = false;
  bool _authenticated = false;

  bool get expiredByUnauthorized => _expiredByUnauthorized;
  bool get authenticated => _authenticated;

  void authenticate() {
    if (_authenticated) return;
    _expiredByUnauthorized = false;
    _authenticated = true;
    notifyListeners();
  }

  void expire() {
    _expiredByUnauthorized = true;
    _authenticated = false;
    notifyListeners();
  }

  void clearAuthentication() {
    if (!_authenticated) return;
    _authenticated = false;
    notifyListeners();
  }

  bool consumeUnauthorizedExpiration() {
    if (!_expiredByUnauthorized) return false;
    _expiredByUnauthorized = false;
    return true;
  }
}

final sessionClockProvider = ChangeNotifierProvider<SessionClock>((ref) {
  return SessionClock();
});
