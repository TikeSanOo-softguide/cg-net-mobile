import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/storage/local_prefs/local_prefs.dart';
import '../../models/advertisement_model/advertisement_model.dart';

class _BannerFile {
  const _BannerFile({required this.url, required this.fileName});

  final String url;
  final String fileName;
}

/// Saves home-banner photos on this phone so they can open offline.
class HomeBannerCache {
  HomeBannerCache({
    required SharedPreferences preferences,
    required Future<Directory> Function() cacheDirectory,
    Dio? imageClient,
  })  : _preferences = preferences,
        _cacheDirectory = cacheDirectory,
        _images = imageClient ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 8),
                receiveTimeout: const Duration(seconds: 20),
                responseType: ResponseType.bytes,
                headers: const {
                  'Accept': 'image/*,*/*',
                },
              ),
            );

  static const folderName = 'home_banners';

  final SharedPreferences _preferences;
  final Future<Directory> Function() _cacheDirectory;
  final Dio _images;

  String keyFor(String language) =>
      '${LocalPrefs.homeBannersCacheKey}:$language';

  Future<List<BannerModel>> read(String language) async {
    final saved = _decode(_preferences.getString(keyFor(language)));
    if (saved.isEmpty) return const [];
    final folder = await _folder();
    final banners = <BannerModel>[];
    for (final entry in saved) {
      final file = File('${folder.path}/${entry.fileName}');
      if (!await file.exists() || await file.length() <= 0) continue;
      banners.add(BannerModel(image: entry.url, localPath: file.path));
    }
    return banners;
  }

  /// Downloads any missing photo before the new list replaces the saved one.
  /// A failed download leaves the previous list in place.
  Future<List<BannerModel>> write(
    String language,
    List<BannerModel> banners,
  ) async {
    final folder = await _folder();
    final previous = _decode(_preferences.getString(keyFor(language)));
    final saved = <_BannerFile>[];
    final visible = <BannerModel>[];

    for (final banner in banners) {
      final url = banner.image.trim();
      if (url.isEmpty) continue;
      final name = _fileName(url);
      final file = File('${folder.path}/$name');
      final ready = await file.exists() && await file.length() > 0;
      if (ready || await _download(url, file)) {
        saved.add(_BannerFile(url: url, fileName: name));
        visible.add(BannerModel(image: url, localPath: file.path));
      } else {
        visible.add(BannerModel(image: url));
      }
    }

    if (visible.isNotEmpty && saved.isEmpty) {
      final previousFiles = await read(language);
      if (previousFiles.isNotEmpty) return previousFiles;
      return visible;
    }

    await _preferences.setString(
      keyFor(language),
      jsonEncode([
        for (final entry in saved) {'url': entry.url, 'file': entry.fileName},
      ]),
    );
    await _deleteDropped(
      language,
      previous,
      saved.map((entry) => entry.fileName).toSet(),
      folder,
    );
    if (visible.isNotEmpty) return visible;
    return read(language);
  }

  Future<Directory> _folder() async {
    final root = await _cacheDirectory();
    final folder = Directory('${root.path}/$folderName');
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }
    return folder;
  }

  Future<bool> _download(String url, File file) async {
    final part = File('${file.path}.part');
    try {
      final response = await _images.get<List<int>>(url);
      final bytes = response.data;
      final type = response.headers.value(Headers.contentTypeHeader) ?? '';
      if (bytes == null || bytes.isEmpty || !_canStore(bytes, type)) {
        return false;
      }
      await part.writeAsBytes(bytes, flush: true);
      if (await file.exists()) await file.delete();
      await part.rename(file.path);
      return await file.exists() && await file.length() > 0;
    } catch (_) {
      if (await part.exists()) {
        await part.delete();
      }
      return false;
    }
  }

  Future<void> _deleteDropped(
    String language,
    List<_BannerFile> previous,
    Set<String> kept,
    Directory folder,
  ) async {
    final usedElsewhere = <String>{};
    final ownKey = keyFor(language);
    final prefix = '${LocalPrefs.homeBannersCacheKey}:';
    for (final key in _preferences.getKeys()) {
      if (!key.startsWith(prefix) || key == ownKey) continue;
      for (final entry in _decode(_preferences.getString(key))) {
        usedElsewhere.add(entry.fileName);
      }
    }
    for (final entry in previous) {
      if (kept.contains(entry.fileName) ||
          usedElsewhere.contains(entry.fileName)) {
        continue;
      }
      final file = File('${folder.path}/${entry.fileName}');
      if (await file.exists()) await file.delete();
    }
  }

  List<_BannerFile> _decode(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      final entries = <_BannerFile>[];
      for (final item in decoded) {
        if (item is! Map) continue;
        final url = item['url']?.toString().trim() ?? '';
        final fileName = item['file']?.toString().trim() ?? '';
        if (url.isEmpty || fileName.isEmpty || fileName.contains('..')) {
          continue;
        }
        entries.add(_BannerFile(url: url, fileName: fileName));
      }
      return entries;
    } catch (_) {
      return const [];
    }
  }

  bool _canStore(List<int> bytes, String type) {
    final value = type.toLowerCase().split(';').first.trim();
    if (value.startsWith('text/') ||
        value.contains('json') ||
        value.contains('html') ||
        value.contains('xml')) {
      return false;
    }
    if (value.startsWith('image/')) return true;
    return _looksLikeImage(bytes);
  }

  bool _looksLikeImage(List<int> bytes) {
    if (bytes.length < 12) return false;
    final jpeg = bytes[0] == 0xFF && bytes[1] == 0xD8;
    final png = bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E;
    final gif = bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46;
    final webp = bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50;
    return jpeg || png || gif || webp;
  }

  String _fileName(String url) {
    var hash = 0xcbf29ce484222325;
    for (final unit in url.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x100000001b3) & 0xFFFFFFFFFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(16, '0');
  }
}
