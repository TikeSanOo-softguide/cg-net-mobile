import 'package:flutter_riverpod/flutter_riverpod.dart';

class InAppNotice {
  const InAppNotice({
    required this.id,
    required this.title,
    this.body,
    required this.receivedAt,
  });

  final String id;
  final String title;
  final String? body;
  final DateTime receivedAt;
}

/// The banner currently shown while the app is in the foreground.
final inAppNoticeProvider = StateProvider<InAppNotice?>((ref) => null);
