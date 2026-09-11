import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Lightweight file picker via Android MethodChannel (avoids file_picker AGP 9 bug).
class ChatFilePicker {
  ChatFilePicker._();

  static const _channel = MethodChannel('cg_net/file_picker');

  /// Returns the selected file display name, or null if cancelled / unsupported.
  static Future<String?> pickFileName() async {
    if (kIsWeb) return null;
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      // Desktop/web can be wired later; Android is the primary target.
      return null;
    }

    try {
      final result = await _channel.invokeMethod<dynamic>('pickFile');
      if (result is Map) {
        final name = result['name'];
        if (name is String && name.trim().isNotEmpty) return name.trim();
      }
      return null;
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }
}
