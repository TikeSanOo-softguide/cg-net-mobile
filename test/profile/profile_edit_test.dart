import 'dart:convert';
import 'dart:typed_data';

import 'package:cg_net_mobile/core/storage/secure_storage/secure_storage.dart';
import 'package:cg_net_mobile/data/profile/profile_repository.dart';
import 'package:cg_net_mobile/models/user_model/user_model.dart';
import 'package:cg_net_mobile/pages/profile/edit_profile/edit_profile_controller.dart';
import 'package:cg_net_mobile/pages/profile/profile/profile_controller.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _MockSecureStorage implements SecureStorage {
  String? _cachedProfile;

  @override
  Future<String?> readCachedProfile() async => _cachedProfile;

  @override
  Future<void> writeCachedProfile(String value) async {
    _cachedProfile = value;
  }

  @override
  Future<void> clearCachedProfile() async {
    _cachedProfile = null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ProfileAdapter implements HttpClientAdapter {
  _ProfileAdapter({this.statusCode = 200, this.responseBody});

  final int statusCode;
  final String? responseBody;
  final requests = <({String method, String path, Object? data})>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add((
      method: options.method,
      path: options.path,
      data: options.data,
    ));

    if (statusCode >= 400) {
      return ResponseBody.fromString(
        responseBody ?? '{"message":"Server error"}',
        statusCode,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }

    final body = responseBody ??
        jsonEncode({
          'data': {
            'user': {
              'id': 57,
              'name': 'Sophia',
              'phone': '959757943906',
              'broadband_account': 'CG0000011',
            },
            'wallet': {'balance': 15000},
          },
        });

    return ResponseBody.fromString(
      body,
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('UserProfileModel Tests', () {
    test('UserProfileModel.fromJson parses profile correctly', () {
      final json = {
        'data': {
          'user': {
            'id': 57,
            'name': 'Sophia Aung',
            'phone': '959757943906',
            'broadband_account': 'CG0000011',
          },
          'wallet': {'balance': 25000},
        },
      };

      final profile = UserProfileModel.fromJson(json);

      expect(profile.id, '57');
      expect(profile.fullName, 'Sophia Aung');
      expect(profile.phone, '09757943906');
      expect(profile.displayPhone, '09757943906');
      expect(profile.accountNumber, 'CG0000011');
      expect(profile.walletBalance, '25000');
    });

    test('UserProfileModel.displayPhone converts 959... to 09...', () {
      const p1 = UserProfileModel(
        id: '1',
        fullName: 'A',
        phone: '959757943906',
        accountNumber: '',
      );
      expect(p1.displayPhone, '09757943906');

      const p2 = UserProfileModel(
        id: '2',
        fullName: 'B',
        phone: '+959757943906',
        accountNumber: '',
      );
      expect(p2.displayPhone, '09757943906');

      const p3 = UserProfileModel(
        id: '3',
        fullName: 'C',
        phone: '09757943906',
        accountNumber: '',
      );
      expect(p3.displayPhone, '09757943906');
    });

    test('UserProfileModel.copyWith modifies full name', () {
      const original = UserProfileModel(
        id: '57',
        fullName: 'Original Name',
        phone: '09757943906',
        accountNumber: 'CG0000011',
      );

      final updated = original.copyWith(fullName: 'Updated Name');

      expect(updated.fullName, 'Updated Name');
      expect(updated.id, '57');
      expect(updated.phone, '09757943906');
    });
  });

  group('ProfileRepository Tests', () {
    test('fetchProfile sends GET request and returns model', () async {
      final adapter = _ProfileAdapter();
      final dio = Dio()..httpClientAdapter = adapter;
      final storage = _MockSecureStorage();
      final repo = ProfileRepository(dio, storage);

      final profile = await repo.fetchProfile();

      expect(profile.id, '57');
      expect(profile.fullName, 'Sophia');
      expect(adapter.requests.first.method, 'GET');
      expect(adapter.requests.first.path, '/customer/profile');
    });

    test('updateProfile sends PATCH request with name payload', () async {
      final adapter = _ProfileAdapter(
        responseBody: jsonEncode({
          'data': {
            'user': {
              'id': 57,
              'name': 'Sophia Updated',
              'phone': '959757943906',
              'broadband_account': 'CG0000011',
            },
          },
        }),
      );
      final dio = Dio()..httpClientAdapter = adapter;
      final storage = _MockSecureStorage();
      final repo = ProfileRepository(dio, storage);

      final updated = await repo.updateProfile(fullName: 'Sophia Updated');

      expect(updated.fullName, 'Sophia Updated');
      expect(adapter.requests.first.method, 'PATCH');
      expect(adapter.requests.first.path, '/customer/profile');
      expect(adapter.requests.first.data, {
        'name': 'Sophia Updated',
        'full_name': 'Sophia Updated',
      });
    });
  });

  group('EditProfileController Tests', () {
    test('save updates profile state on success', () async {
      final adapter = _ProfileAdapter(
        responseBody: jsonEncode({
          'data': {
            'user': {
              'id': 57,
              'name': 'New Profile Name',
              'phone': '959757943906',
            },
          },
        }),
      );
      final dio = Dio()..httpClientAdapter = adapter;
      final storage = _MockSecureStorage();

      final container = ProviderContainer(
        overrides: [
          profileRepositoryProvider.overrideWithValue(
            ProfileRepository(dio, storage),
          ),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(editProfileControllerProvider.notifier);
      final success = await controller.save(fullName: 'New Profile Name');

      expect(success, isTrue);

      final profile = container.read(profileControllerProvider);
      expect(profile.fullName, 'New Profile Name');
    });

    test('save optimistically updates profile on server error', () async {
      final adapter = _ProfileAdapter(statusCode: 500);
      final dio = Dio()..httpClientAdapter = adapter;
      final storage = _MockSecureStorage();

      final container = ProviderContainer(
        overrides: [
          profileRepositoryProvider.overrideWithValue(
            ProfileRepository(dio, storage),
          ),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(editProfileControllerProvider.notifier);
      final success = await controller.save(fullName: 'Optimistic Name');

      expect(success, isTrue);

      final profile = container.read(profileControllerProvider);
      expect(profile.fullName, 'Optimistic Name');
    });
  });
}
