import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SessionClock extends ChangeNotifier {
  void expire() => notifyListeners();
}

final sessionClockProvider = ChangeNotifierProvider<SessionClock>((ref) {
  return SessionClock();
});
