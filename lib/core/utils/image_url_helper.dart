import '../network/api_endpoints/api_endpoints.dart';

class ImageUrlHelper {
  ImageUrlHelper._();

  static String? resolve(
      Map item, {
        String language = 'en',
      }) {
    final languageKey = switch (language) {
      'my' => 'my',
      'zh' => 'zh',
      _ => 'en',
    };

    final raw = [
      item['image_url_$languageKey'],
      item['image_url_en'],
      item['image_url_zh'],
      item['image_url_my'],
      item['image_url'],
    ].map((value) => value?.toString().trim()).firstWhere(
          (value) => value != null && value.isNotEmpty,
      orElse: () => null,
    );

    if (raw == null) {
      return null;
    }

    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return raw;
    }

    try {
      final baseUri = Uri.parse(ApiEndpoints.baseUrl);
      final origin = baseUri.origin;

      var path = raw.startsWith('/') ? raw : '/$raw';

      if (!path.startsWith('/storage/')) {
        path = '/storage$path';
      }

      return '$origin$path';
    } catch (_) {
      return raw;
    }
  }
}