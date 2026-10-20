import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_endpoints/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client/dio_client.dart';

class AppVersionInfo {
  const AppVersionInfo({
    required this.platform,
    required this.version,
    required this.minimumVersion,
    required this.downloadUrl,
    required this.releaseNotesEn,
    required this.releaseNotesZh,
    required this.releaseNotesMy,
    required this.forceUpdate,
    required this.createdAt,
  });

  final String platform;
  final String version;
  final String minimumVersion;
  final String downloadUrl;
  final String releaseNotesEn;
  final String releaseNotesZh;
  final String releaseNotesMy;
  final bool forceUpdate;
  final DateTime? createdAt;

  String releaseNotes(String languageCode) {
    final localized = switch (languageCode) {
      'zh' => releaseNotesZh,
      'my' => releaseNotesMy,
      _ => releaseNotesEn,
    };
    return localized.trim().isEmpty ? releaseNotesEn : localized;
  }

  factory AppVersionInfo.fromJson(Map<String, dynamic> json) {
    final createdAtValue = json['created_at']?.toString();
    final releaseNotes = json['release_notes'];
    if (releaseNotes != null && releaseNotes is! Map) {
      throw const FormatException(
          'App version release_notes must be an object');
    }
    return AppVersionInfo(
      platform: _requiredString(json, 'platform').toLowerCase(),
      version: _requiredString(json, 'version'),
      minimumVersion: _requiredString(json, 'minimum_version'),
      downloadUrl: _requiredString(json, 'download_url'),
      releaseNotesEn: _localizedReleaseNote(json, releaseNotes, 'en'),
      releaseNotesZh: _localizedReleaseNote(json, releaseNotes, 'zh'),
      releaseNotesMy: _localizedReleaseNote(json, releaseNotes, 'my'),
      forceUpdate: json['force_update'] == true ||
          json['force_update'] == 1 ||
          const {'true', '1'}.contains(
            json['force_update']?.toString().toLowerCase(),
          ),
      createdAt: createdAtValue == null || createdAtValue.isEmpty
          ? null
          : DateTime.tryParse(createdAtValue),
    );
  }

  static String _requiredString(
    Map<String, dynamic> json,
    String key, {
    bool allowEmpty = false,
  }) {
    final value = json[key]?.toString();
    if (value == null || (!allowEmpty && value.trim().isEmpty)) {
      throw FormatException('App version response is missing $key');
    }
    return value;
  }

  static String _localizedReleaseNote(
    Map<String, dynamic> json,
    Object? releaseNotes,
    String languageCode,
  ) {
    final localizedNotes = releaseNotes is Map
        ? releaseNotes[languageCode]
        : json['release_notes_$languageCode'];
    return localizedNotes?.toString() ?? '';
  }
}

class VersionRepository {
  VersionRepository(this._dio);

  final Dio _dio;

  Future<AppVersionInfo> fetchForPlatform(String platform) async {
    try {
      final response = await _dio.get<dynamic>(ApiEndpoints.appVersion);
      final records = _readRecords(response.data);
      final matching = records
          .where(
            (record) =>
                record['platform']?.toString().trim().toLowerCase() ==
                    platform &&
                (record['status'] == null ||
                    record['status'].toString().toLowerCase() == 'active'),
          )
          .map((record) => AppVersionInfo.fromJson(record))
          .toList()
        ..sort((a, b) {
          final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bDate.compareTo(aDate);
        });

      if (matching.isEmpty) {
        throw FormatException('No active app version found for $platform');
      }
      return matching.first;
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  List<Map<String, dynamic>> _readRecords(Object? response) {
    Object? resource = response;
    if (resource is Map && resource.containsKey('data')) {
      resource = resource['data'];
    }

    if (resource is Map) {
      return [Map<String, dynamic>.from(resource)];
    }
    if (resource is List) {
      return resource
          .whereType<Map>()
          .map((record) => Map<String, dynamic>.from(record))
          .toList();
    }
    throw const FormatException('Invalid app version resource response');
  }
}

final versionRepositoryProvider = Provider<VersionRepository>((ref) {
  return VersionRepository(ref.watch(dioProvider));
});

final versionControllerProvider = FutureProvider<AppVersionInfo>((ref) {
  final platform =
      defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';

  debugPrint('[app-version] Provider initialized: $platform');

  return ref.watch(versionRepositoryProvider).fetchForPlatform(platform);
});
