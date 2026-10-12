class BannerResponseHelper {
  const BannerResponseHelper._();

  static List<Map> itemsOfType(
    dynamic responseData, {
    required String type,
  }) {
    final List items;
    if (responseData is List) {
      items = responseData;
    } else if (responseData is Map && responseData['data'] is List) {
      items = responseData['data'] as List;
    } else {
      return [];
    }

    return items
        .whereType<Map>()
        .where((item) => item['type'] == type)
        .toList();
  }
}
