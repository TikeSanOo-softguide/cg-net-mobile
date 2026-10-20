import 'dart:typed_data';

import 'package:cg_net_mobile/core/network/api_endpoints/api_endpoints.dart';
import 'package:cg_net_mobile/core/network/api_exception.dart';
import 'package:cg_net_mobile/core/network/dio_client/dio_client.dart';
import 'package:cg_net_mobile/data/settings/general_setting_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GeneralSettingRepository', () {
    test('loads localized terms and conditions', () async {
      late RequestOptions request;
      final dio = _dio((options) {
        request = options;
        return _jsonResponse(
          200,
          '''
          {"data":[{"id":1,"title":{"en":"Terms","zh":"条款","my":"စည်းကမ်း"},"description":{"en":"Terms body","zh":"条款内容","my":"စည်းကမ်းအကြောင်း"}}]}
          ''',
        );
      });

      final terms =
          await GeneralSettingRepository(dio).fetchTermAndConditions();

      expect(request.method, 'GET');
      expect(request.path, ApiEndpoints.termAndCondition);
      expect(terms, hasLength(1));
      expect(terms.single.id, '1');
      expect(terms.single.titleFor('my'), 'စည်းကမ်း');
      expect(terms.single.descriptionFor('zh'), '条款内容');
      expect(terms.single.titleFor('fr'), 'Terms');
    });

    test('loads FAQs and selects localized content', () async {
      late RequestOptions request;
      final dio = _dio((options) {
        request = options;
        return _jsonResponse(
          200,
          '''
          {"data":[{"id":2,"title":{"en":"Question","my":"မေးခွန်း"},"description":{"en":"Answer","my":"အဖြေ"}}]}
          ''',
        );
      });

      final faqs = await GeneralSettingRepository(dio).fetchFaqs();

      expect(request.method, 'GET');
      expect(request.path, ApiEndpoints.faq);
      expect(faqs, hasLength(1));
      expect(faqs.single.id, '2');
      expect(faqs.single.titleFor('my'), 'မေးခွန်း');
      expect(faqs.single.descriptionFor('my'), 'အဖြေ');
    });

    test('loads support contacts and preserves phone numbers', () async {
      late RequestOptions request;
      final dio = _dio((options) {
        request = options;
        return _jsonResponse(
          200,
          '[{"id":3,"phone":"+95 9 123 456 789"}]',
        );
      });

      final contacts =
          await GeneralSettingRepository(dio).fetchSupportContacts();

      expect(request.method, 'GET');
      expect(request.path, ApiEndpoints.supportContact);
      expect(contacts, hasLength(1));
      expect(contacts.single.id, '3');
      expect(contacts.single.phone, '+95 9 123 456 789');
    });

    test('wraps a single data object as a list item', () async {
      final dio = _dio((_) => _jsonResponse(
            200,
            '{"data":{"id":4,"title":{"en":"Question"},"description":{"en":"Answer"}}}',
          ));

      final faqs = await GeneralSettingRepository(dio).fetchFaqs();

      expect(faqs, hasLength(1));
      expect(faqs.single.titleFor('en'), 'Question');
    });

    test('converts Dio failures to ApiException', () async {
      final dio = _dio((options) {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        );
      });

      await expectLater(
        GeneralSettingRepository(dio).fetchFaqs(),
        throwsA(
          isA<ApiException>().having(
            (error) => error.failure,
            'failure',
            ApiFailure.offline,
          ),
        ),
      );
    });
  });

  group('general setting providers', () {
    test('loads FAQs through the repository provider', () async {
      final dio = _dio((_) => _jsonResponse(
            200,
            '{"data":[{"id":5,"title":{"en":"Question"},"description":{"en":"Answer"}}]}',
          ));
      final container = ProviderContainer(
        overrides: [dioProvider.overrideWithValue(dio)],
      );
      addTearDown(container.dispose);

      final faqs = await container.read(faqProvider.future);

      expect(faqs.single.id, '5');
      expect(faqs.single.descriptionFor('en'), 'Answer');
    });
  });
}

Dio _dio(ResponseBody Function(RequestOptions options) respond) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test/api'));
  dio.httpClientAdapter = _ResponseAdapter(respond);
  return dio;
}

ResponseBody _jsonResponse(int statusCode, String body) {
  return ResponseBody.fromString(
    body,
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

class _ResponseAdapter implements HttpClientAdapter {
  _ResponseAdapter(this.respond);

  final ResponseBody Function(RequestOptions options) respond;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return respond(options);
  }

  @override
  void close({bool force = false}) {}
}
