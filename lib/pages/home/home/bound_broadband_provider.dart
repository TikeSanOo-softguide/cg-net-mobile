import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'bound_broadband.dart';

/// Shared bound broadband — Home Header and Services stay in sync.
final boundBroadbandProvider = StateProvider<BoundBroadband?>((ref) => null);
