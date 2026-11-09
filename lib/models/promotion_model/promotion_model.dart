import '../../core/utils/image_url_helper.dart';
import '../user_model/user_model.dart';

class HomePromotion {
  const HomePromotion({
    required this.id,
    required this.titles,
    required this.descriptions,
    this.slug,
    this.imageUrl,
    this.createdAt,
  });

  final String id;
  final String? slug;
  final Map<String, String> titles;
  final Map<String, String> descriptions;
  final String? imageUrl;
  final DateTime? createdAt;

  bool get hasContent =>
      (imageUrl != null && imageUrl!.isNotEmpty) ||
      titles.values.any((value) => value.trim().isNotEmpty) ||
      descriptions.values.any((value) => value.trim().isNotEmpty);

  String titleFor(String locale) => _pick(titles, locale);

  String descriptionFor(String locale) => _pick(descriptions, locale);

  InboxMessageModel toInboxMessage() {
    final catalogId = id.trim();
    return InboxMessageModel(
      id: catalogId.startsWith('promotion-')
          ? catalogId
          : 'promotion-$catalogId',
      titleKey: titleFor('en'),
      bodyKey: descriptionFor('en'),
      titles: titles,
      bodies: descriptions,
      imageUrl: imageUrl,
      createdAt: createdAt ?? DateTime.now(),
      category: InboxCategory.promotion,
      isRead: true,
    );
  }

  factory HomePromotion.fromJson(Map<String, dynamic> json) {
    final imageRaw = json['imageUrl'] ?? json['image_url'];
    final slug = json['slug']?.toString().trim();
    return HomePromotion(
      id: '${json['id'] ?? json['slug'] ?? ''}',
      slug: slug == null || slug.isEmpty ? null : slug,
      titles: _stringMap(json['title']),
      descriptions: _stringMap(json['description']),
      imageUrl: ImageUrlHelper.resolve({'image_url': imageRaw}),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }

  static Map<String, String> _stringMap(Object? value) {
    if (value is! Map) return {};
    return value.map(
      (key, item) => MapEntry(key.toString(), item?.toString() ?? ''),
    );
  }

  static String _pick(Map<String, String> values, String locale) {
    final code = locale == 'mm' ? 'my' : locale;
    for (final key in [code, 'en', 'my', 'zh']) {
      final value = values[key]?.trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return '';
  }
}
