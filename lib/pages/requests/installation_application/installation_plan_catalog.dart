import '../../../models/requests/installation_application/installation_application_model.dart';

int productSpeedMbps(InstallationApplicationOption product) {
  final match = RegExp(r'\d+').firstMatch(product.productSpeed ?? '');
  return int.tryParse(match?.group(0) ?? '') ?? 0;
}

String providerLineOf(InstallationApplicationOption product) {
  return product.productLine.trim();
}

List<String> availableProviderLines(
  List<InstallationApplicationOption> products,
) {
  return _unique(products.map(providerLineOf))
      .where((line) => line.isNotEmpty)
      .toList(growable: false);
}

List<int> availableSpeeds(
  List<InstallationApplicationOption> products,
  String productLine,
) {
  return _uniqueInts(
    products
        .where((product) => providerLineOf(product) == productLine)
        .map(productSpeedMbps)
        .where((speed) => speed > 0),
  );
}

List<int> availableCycles(
  List<InstallationApplicationOption> products,
  String productLine,
  int speedMbps,
) {
  return _uniqueInts(
    products
        .where((product) => providerLineOf(product) == productLine)
        .where((product) => productSpeedMbps(product) == speedMbps)
        .map((product) => product.monthCycle)
        .where((cycle) => cycle > 0),
  );
}

String cycleUnitFor({
  required List<InstallationApplicationOption> products,
  required String productLine,
  required int speedMbps,
  required int monthCycle,
}) {
  for (final product in products) {
    if (providerLineOf(product) == productLine &&
        productSpeedMbps(product) == speedMbps &&
        product.monthCycle == monthCycle) {
      return product.monthCycleUnit;
    }
  }
  return '';
}

InstallationApplicationOption? matchedProduct({
  required List<InstallationApplicationOption> products,
  required String? productLine,
  required int? speedMbps,
  required int? monthCycle,
}) {
  if (productLine == null ||
      productLine.isEmpty ||
      speedMbps == null ||
      monthCycle == null) {
    return null;
  }
  final matches = products
      .where((product) => providerLineOf(product) == productLine)
      .where((product) => productSpeedMbps(product) == speedMbps)
      .where((product) => product.monthCycle == monthCycle)
      .toList(growable: false);
  if (matches.isEmpty) return null;
  return matches.first;
}

List<T> _unique<T>(Iterable<T> values) {
  final seen = <T>{};
  final result = <T>[];
  for (final value in values) {
    if (seen.add(value)) result.add(value);
  }
  return result;
}

List<int> _uniqueInts(Iterable<int> values) {
  final valuesList = _unique(values);
  valuesList.sort();
  return valuesList;
}
