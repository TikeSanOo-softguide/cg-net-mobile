import 'package:flutter_riverpod/flutter_riverpod.dart';

class AboutAppController extends StateNotifier<void> {
  AboutAppController() : super(null);
}

final aboutAppControllerProvider =
    StateNotifierProvider<AboutAppController, void>((ref) {
  return AboutAppController();
});
