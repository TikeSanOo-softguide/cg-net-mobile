import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_endpoints/api_endpoints.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/dio_client/dio_client.dart';

class TermAndConditionModel {
  const TermAndConditionModel({
    required this.id,
    required this.title,
    required this.description,
  });

  final String id;
  final Map<String, String> title;
  final Map<String, String> description;

  factory TermAndConditionModel.fromJson(Map<String, dynamic> json) {
    final title = _stringMap(json['title']);
    final description = _stringMap(json['description']);

    return TermAndConditionModel(
      id: json['id']?.toString() ?? '',
      title: title,
      description: description,
    );
  }

  String titleFor(String locale) => _pick(title, locale);
  String descriptionFor(String locale) => _pick(description, locale);

  static Map<String, String> _stringMap(Object? value) {
    if (value is! Map) return {};
    return value.map(
      (key, item) => MapEntry(key.toString(), item?.toString() ?? ''),
    );
  }

  static String _pick(Map<String, String> values, String locale) {
    if (values.isEmpty) return '';
    return values[locale] ?? values['en'] ?? values.values.first;
  }
}

class FaqModel {
  const FaqModel({
    required this.id,
    required this.title,
    required this.description,
  });

  final String id;
  final Map<String, String> title;
  final Map<String, String> description;

  factory FaqModel.fromJson(Map<String, dynamic> json) {
    final title = _stringMap(json['title']);
    final description = _stringMap(json['description']);

    return FaqModel(
      id: json['id']?.toString() ?? '',
      title: title,
      description: description,
    );
  }

  String titleFor(String locale) => _pick(title, locale);
  String descriptionFor(String locale) => _pick(description, locale);

  static Map<String, String> _stringMap(Object? value) {
    if (value is! Map) return {};
    return value.map(
      (key, item) => MapEntry(key.toString(), item?.toString() ?? ''),
    );
  }

  static String _pick(Map<String, String> values, String locale) {
    if (values.isEmpty) return '';
    return values[locale] ?? values['en'] ?? values.values.first;
  }
}

class SupportContactModel {
  const SupportContactModel({
    required this.id,
    required this.phone,
  });

  final String id;
  final String phone;

  factory SupportContactModel.fromJson(Map<String, dynamic> json) {
    return SupportContactModel(
      id: json['id']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
    );
  }
}

class GeneralSettingRepository {
  GeneralSettingRepository(this._dio);

  final Dio _dio;

  Future<List<TermAndConditionModel>> fetchTermAndConditions() async {
    try {
      final response = await _dio.get<dynamic>(ApiEndpoints.termAndCondition);
      return _decodeList(response.data)
          .map(
            (item) => TermAndConditionModel.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<List<TermAndConditionModel>> fetchTermAndCondition() async {
    return fetchTermAndConditions();
  }

  Future<List<FaqModel>> fetchFaqs() async {
    try {
      final response = await _dio.get<dynamic>(ApiEndpoints.faq);
      return _decodeList(response.data)
          .map(
            (item) => FaqModel.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<List<FaqModel>> fetchFaq() async {
    return fetchFaqs();
  }

  Future<List<SupportContactModel>> fetchSupportContacts() async {
    try {
      final response = await _dio.get<dynamic>(ApiEndpoints.supportContact);
      return _decodeList(response.data)
          .map(
            (item) => SupportContactModel.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<List<SupportContactModel>> fetchSupportContact() async {
    return fetchSupportContacts();
  }

  static List<dynamic> _decodeList(dynamic data) {
    if (data is List) {
      return data;
    }

    if (data is Map) {
      final nested = data['data'] ?? data['items'] ?? data['results'];
      if (nested is List) {
        return nested;
      }
      if (nested is Map) {
        return [nested];
      }
      return [data];
    }

    return const [];
  }
}

final generalSettingRepositoryProvider =
    Provider<GeneralSettingRepository>((ref) {
  return GeneralSettingRepository(ref.watch(dioProvider));
});

final termAndConditionProvider =
    FutureProvider<List<TermAndConditionModel>>((ref) {
  final repository = ref.watch(generalSettingRepositoryProvider);
  return repository.fetchTermAndConditions();
});

final faqProvider = FutureProvider<List<FaqModel>>((ref) {
  final repository = ref.watch(generalSettingRepositoryProvider);
  return repository.fetchFaqs();
});

final supportContactProvider = FutureProvider<List<SupportContactModel>>((ref) {
  final repository = ref.watch(generalSettingRepositoryProvider);
  return repository.fetchSupportContacts();
});
