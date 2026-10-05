import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router/route_names/route_names.dart';
import 'api_exception.dart';

bool isOfflineError(Object? error) {
  return error is ApiException && error.failure == ApiFailure.offline;
}

Future<bool?> openNoInternetPage(
  BuildContext context, {
  String? returnToPath,
}) {
  final currentPath = GoRouterState.of(context).matchedLocation;
  if (currentPath == RoutePaths.errorNoInternet) {
    return Future.value(false);
  }

  final target = (returnToPath ?? currentPath).trim();
  final query = <String, String>{};
  if (target.isNotEmpty) {
    query['return_to'] = target;
  }
  return context.pushNamed<bool>(
    RouteNames.errorNoInternet,
    queryParameters: query,
  );
}
