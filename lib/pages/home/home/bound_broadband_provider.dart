import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'components/bind_broadband_drawer.dart';

/// Shared bound broadband — Home Header and Services stay in sync.
final boundBroadbandProvider =
    StateProvider<BoundBroadband?>((ref) => null);
