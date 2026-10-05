import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SessionClock extends ChangeNotifier {
  bool _expiredByUnauthorized = false;

  bool get expiredByUnauthorized => _expiredByUnauthorized;

  void expire() {
    _expiredByUnauthorized = true;
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
