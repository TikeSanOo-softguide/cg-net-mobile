import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_endpoints/api_endpoints.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/dio_client/dio_client.dart';

enum ChatConversationStatus {
  unknown,
  chatFlow,
  waiting,
  open,
  closed,
}

enum ChatFlowOptionAction {
  goToStep,
  goToUrl,
  replyText,
  transferAgent,
  closeChat;

  static ChatFlowOptionAction? parse(Object? value) {
    return switch (value?.toString()) {
      'go_to_step' => ChatFlowOptionAction.goToStep,
      'go_to_url' => ChatFlowOptionAction.goToUrl,
      'reply_text' => ChatFlowOptionAction.replyText,
      'transfer_agent' => ChatFlowOptionAction.transferAgent,
      'close_chat' => ChatFlowOptionAction.closeChat,
      _ => null,
    };
  }
}

class ChatOptionSelectionResult {
  const ChatOptionSelectionResult({
    required this.conversation,
    required this.action,
    required this.url,
  });

  final ChatConversationModel conversation;
  final ChatFlowOptionAction? action;
  final String? url;

  factory ChatOptionSelectionResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : json;
    final rawUrl = data['url']?.toString().trim();
    return ChatOptionSelectionResult(
      conversation: ChatConversationModel.fromJson(json),
      action: ChatFlowOptionAction.parse(data['action']),
      url: rawUrl == null || rawUrl.isEmpty ? null : rawUrl,
    );
  }
}

class ChatFlowOption {
  const ChatFlowOption({
    required this.id,
    required this.label,
    this.value,
    Map<String, String>? translations,
  }) : translations = translations ?? const <String, String>{};

  final String id;
  final String label;
  final String? value;
  final Map<String, String> translations;

  String labelForLocale(String? localeCode) {
    final normalized = localeCode ?? '';
    final candidates = <String>{
      normalized.toLowerCase(),
      normalized.split('_').first.toLowerCase(),
      if (normalized.toLowerCase() == 'my') 'mm',
      if (normalized.toLowerCase() == 'zh') 'cn',
    }.where((code) => code.isNotEmpty).toList();

    final preferredOrder = <String>[
      ...candidates,
      'en',
      'my',
      'mm',
      'zh',
      'cn',
    ];

    for (final code in preferredOrder) {
      final text = translations[code];
      if (text != null && text.trim().isNotEmpty) {
        return text.trim();
      }
      final direct = translations[code.toLowerCase()];
      if (direct != null && direct.trim().isNotEmpty) {
        return direct.trim();
      }
    }

    if (label.trim().isNotEmpty) return label.trim();
    return '';
  }

  factory ChatFlowOption.fromJson(dynamic json) {
    if (json is String) {
      final text = json.trim();
      return ChatFlowOption(
        id: text,
        label: text,
        value: text,
      );
    }
    if (json is Map) {
      final map = Map<String, dynamic>.from(json);
      final translations = _translationsFromMap(map);
      final id = _stringValue(
        map['id'] ??
            map['option_id'] ??
            map['value'] ??
            map['key'] ??
            map['slug'] ??
            map['code'],
      );
      final directLabel = _stringValue(
        map['label'] ??
            map['text'] ??
            map['name'] ??
            map['title'] ??
            map['value'] ??
            map['option'],
      );
      final localizedLabel = _preferredText(translations, directLabel);
      final value = _stringValue(
        map['value'] ?? map['option'] ?? map['slug'] ?? map['key'] ?? map['id'],
      );
      final finalLabel = localizedLabel.isNotEmpty
          ? localizedLabel
          : (id.isNotEmpty ? id : 'Option');
      final finalId = id.isNotEmpty ? id : finalLabel;
      return ChatFlowOption(
        id: finalId,
        label: finalLabel,
        value: value.isNotEmpty ? value : null,
        translations: translations,
      );
    }
    final text = json?.toString().trim() ?? '';
    return ChatFlowOption(
      id: text,
      label: text.isNotEmpty ? text : 'Option',
      value: text.isNotEmpty ? text : null,
    );
  }

  static String _preferredText(
      Map<String, String> translations, String fallback) {
    if (translations['en'] != null && translations['en']!.trim().isNotEmpty) {
      return translations['en']!.trim();
    }
    if (translations['my'] != null && translations['my']!.trim().isNotEmpty) {
      return translations['my']!.trim();
    }
    if (translations['mm'] != null && translations['mm']!.trim().isNotEmpty) {
      return translations['mm']!.trim();
    }
    if (translations['zh'] != null && translations['zh']!.trim().isNotEmpty) {
      return translations['zh']!.trim();
    }
    if (translations['cn'] != null && translations['cn']!.trim().isNotEmpty) {
      return translations['cn']!.trim();
    }
    return fallback.trim();
  }

  static Map<String, String> _translationsFromMap(Map<String, dynamic> map) {
    final result = <String, String>{};

    void addIfPresent(String key, Object? value) {
      final text = _stringValue(value);
      if (text.isNotEmpty) {
        final normalizedKey = key.toLowerCase().replaceAll('-', '_');
        final locale = _localeFromKey(normalizedKey);
        if (locale != null) {
          result[locale] = text;
        }
      }
    }

    for (final entry in map.entries) {
      final key = entry.key.toString().toLowerCase();
      if (key == 'label' ||
          key == 'text' ||
          key == 'name' ||
          key == 'title' ||
          key == 'value' ||
          key == 'option') {
        continue;
      }
      addIfPresent(key, entry.value);
    }

    for (final key in ['translations', 'labels', 'label_translations']) {
      final nestedMap = map[key];
      if (nestedMap is Map) {
        for (final entry in Map<String, dynamic>.from(nestedMap).entries) {
          addIfPresent(entry.key, entry.value);
        }
      }
    }

    final labelMap = map['label'];
    if (labelMap is Map) {
      for (final entry in Map<String, dynamic>.from(labelMap).entries) {
        addIfPresent(entry.key, entry.value);
      }
    }

    return result;
  }

  static String? _localeFromKey(String key) {
    final normalized = key.replaceAll('-', '_');
    final localeKey = normalized
        .replaceFirst(RegExp(r'^(label|text|name|title|value)_'), '')
        .replaceFirst(RegExp(r'_(label|text|name|title|value)$'), '');
    final locale = localeKey.split('_').first;
    return switch (locale) {
      'en' => 'en',
      'my' || 'mm' => 'my',
      'zh' || 'cn' => 'zh',
      _ => null,
    };
  }

  static String _stringValue(Object? value) {
    if (value == null) return '';
    if (value is Map) {
      final text = value['text'] ?? value['label'] ?? value['value'];
      return text == null ? '' : _stringValue(text);
    }
    return value.toString().trim();
  }
}

class ChatMessageModel {
  const ChatMessageModel({
    required this.id,
    required this.text,
    required this.role,
    this.createdAt,
    this.conversationId,
    this.selectedOption,
    this.flowOptions = const [],
  });

  final String? id;
  final String text;
  final String role;
  final DateTime? createdAt;
  final String? conversationId;
  final ChatFlowOption? selectedOption;
  final List<ChatFlowOption> flowOptions;

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    final text = _stringValue(
      json['text'] ??
          json['message'] ??
          json['body'] ??
          json['content'] ??
          json['value'],
    );
    final sender = json['sender'];
    final senderType = sender is Map
        ? _stringValue(
            sender['type'] ??
                sender['role'] ??
                sender['sender_type'] ??
                sender['name'],
          )
        : null;
    final role = _stringValue(
      json['role'] ??
          senderType ??
          (sender is String ? sender : null) ??
          json['sender_type'] ??
          json['author'] ??
          json['type'] ??
          'support',
    );
    final createdAt = json['created_at'] != null ||
            json['sent_at'] != null ||
            json['createdAt'] != null
        ? DateTime.tryParse(
            _stringValue(
              json['created_at'] ?? json['sent_at'] ?? json['createdAt'],
            ),
          )
        : null;

    final rawStep = json['step'];
    final stepOptions = <ChatFlowOption>[];
    if (rawStep is Map) {
      for (final option
          in _asList(Map<String, dynamic>.from(rawStep)['options'])) {
        final parsed = ChatFlowOption.fromJson(option);
        if (parsed.id.isNotEmpty || parsed.label.isNotEmpty) {
          stepOptions.add(parsed);
        }
      }
    }

    final selectedOptionJson = json['selected_option'];
    final selectedOption = selectedOptionJson is Map
        ? ChatFlowOption.fromJson(selectedOptionJson)
        : null;

    final flowOptions = stepOptions.isNotEmpty
        ? stepOptions
        : _asList(json['flow_options'])
            .map(ChatFlowOption.fromJson)
            .where((option) => option.id.isNotEmpty)
            .toList();

    return ChatMessageModel(
      id: _nullableString(json['id'] ?? json['message_id']),
      text: text,
      role: role,
      createdAt: createdAt,
      conversationId: _nullableString(
        json['conversation_id'] ?? json['conversationId'],
      ),
      selectedOption: selectedOption,
      flowOptions: flowOptions,
    );
  }

  static List<dynamic> _asList(Object? value) {
    return value is List ? value : const [];
  }

  static String? _nullableString(Object? value) {
    final result = _stringValue(value);
    return result.isEmpty ? null : result;
  }

  static String _stringValue(Object? value) {
    if (value == null) return '';
    return value.toString().trim();
  }
}

class ChatConversationModel {
  const ChatConversationModel({
    required this.id,
    required this.status,
    required this.message,
    this.options = const [],
    this.messages = const [],
  });

  final String? id;
  final ChatConversationStatus status;
  final String? message;
  final List<ChatFlowOption> options;
  final List<ChatMessageModel> messages;

  bool get isClosed => status == ChatConversationStatus.closed;
  bool get isActive =>
      status == ChatConversationStatus.chatFlow ||
      status == ChatConversationStatus.waiting ||
      status == ChatConversationStatus.open;

  factory ChatConversationModel.fromJson(Map<String, dynamic> json) {
    final payload = _rootData(json);
    final statusValue = _stringValue(
      payload['status'] ??
          payload['state'] ??
          payload['conversation_status'] ??
          payload['current_status'] ??
          (payload['conversation'] is Map
              ? payload['conversation']['status'] ??
                  payload['conversation']['state']
              : null) ??
          (payload['step'] is Map
              ? payload['step']['status'] ?? payload['step']['state']
              : null),
    );
    final message = _localizedText(
      (payload['step'] is Map ? payload['step']['message'] : null) ??
          payload['message'] ??
          payload['chat_flow_message'] ??
          payload['prompt'] ??
          payload['question'] ??
          payload['summary'] ??
          payload['text'] ??
          payload['body'] ??
          payload['content'] ??
          payload['title'] ??
          (payload['step'] is Map
              ? payload['step']['message'] ??
                  payload['step']['prompt'] ??
                  payload['step']['question'] ??
                  payload['step']['text'] ??
                  payload['step']['title']
              : null) ??
          (payload['current_step'] is Map
              ? payload['current_step']['message'] ??
                  payload['current_step']['prompt'] ??
                  payload['current_step']['question'] ??
                  payload['current_step']['text'] ??
                  payload['current_step']['title']
              : null) ??
          (payload['flow'] is Map
              ? payload['flow']['message'] ??
                  payload['flow']['prompt'] ??
                  payload['flow']['question'] ??
                  payload['flow']['text']
              : null) ??
          (payload['conversation'] is Map
              ? payload['conversation']['message'] ??
                  payload['conversation']['prompt']
              : null),
    );

    final optionsRaw = payload['options'] ??
        payload['chat_flow_options'] ??
        payload['available_options'] ??
        payload['choices'] ??
        payload['buttons'] ??
        payload['items'] ??
        (payload['step'] is Map
            ? payload['step']['options'] ??
                payload['step']['choices'] ??
                payload['step']['buttons']
            : null) ??
        (payload['current_step'] is Map
            ? payload['current_step']['options'] ??
                payload['current_step']['choices'] ??
                payload['current_step']['buttons']
            : null) ??
        (payload['flow'] is Map
            ? payload['flow']['options'] ??
                payload['flow']['choices'] ??
                payload['flow']['buttons']
            : null);

    final options = _asList(optionsRaw)
        .map((item) => ChatFlowOption.fromJson(item))
        .where((opt) => opt.id.isNotEmpty || opt.label.isNotEmpty)
        .toList();

    final messages = _asList(
      payload['messages'] ??
          payload['history'] ??
          json['messages'] ??
          json['history'],
    )
        .map((item) =>
            ChatMessageModel.fromJson(Map<String, dynamic>.from(item)))
        .toList()
      ..sort(_compareMessages);

    final id = _stringValue(
      payload['id'] ??
          payload['conversation_id'] ??
          payload['conversationId'] ??
          payload['uuid'] ??
          (payload['conversation'] is Map
              ? payload['conversation']['id'] ??
                  payload['conversation']['conversation_id']
              : null),
    );

    var status = _normalizeStatus(statusValue);
    if (status == ChatConversationStatus.unknown) {
      if (options.isNotEmpty || message.isNotEmpty) {
        status = ChatConversationStatus.chatFlow;
      }
    }

    return ChatConversationModel(
      id: id.isNotEmpty ? id : null,
      status: status,
      message: message.isNotEmpty ? message : null,
      options: options,
      messages: messages,
    );
  }

  static Map<String, dynamic> _rootData(Map<String, dynamic> json) {
    if (json['data'] is Map) {
      return Map<String, dynamic>.from(json['data'] as Map);
    }
    if (json['conversation'] is Map) {
      return Map<String, dynamic>.from(json['conversation'] as Map);
    }
    if (json['chat'] is Map) {
      return Map<String, dynamic>.from(json['chat'] as Map);
    }
    return json;
  }

  static String _localizedText(Object? value) {
    if (value == null) return '';
    if (value is Map) {
      final map = Map<String, dynamic>.from(value);
      for (final key in [
        'text',
        'message',
        'content',
        'body',
        'title',
        'prompt'
      ]) {
        final item = map[key];
        if (item is String && item.trim().isNotEmpty) {
          return item.trim();
        }
      }
      for (final key in ['en', 'my', 'mm', 'zh', 'cn']) {
        final item = map[key];
        if (item is String && item.trim().isNotEmpty) {
          return item.trim();
        }
      }
      final nested = map['translations'];
      if (nested is Map) {
        final nestedMap = Map<String, dynamic>.from(nested);
        for (final key in ['en', 'my', 'mm', 'zh', 'cn']) {
          final item = nestedMap[key];
          if (item is String && item.trim().isNotEmpty) {
            return item.trim();
          }
        }
      }
      return _stringValue(map['label'] ?? map['value']);
    }
    return value.toString().trim();
  }

  static List<dynamic> _asList(Object? value) {
    if (value is List) return value;
    return const [];
  }

  static ChatConversationStatus _normalizeStatus(String value) {
    switch (value.toUpperCase()) {
      case 'CHAT_FLOW':
      case 'FLOW':
      case 'CHATFLOW':
      case 'BOT':
        return ChatConversationStatus.chatFlow;
      case 'WAITING':
      case 'WAITING_AGENT':
        return ChatConversationStatus.waiting;
      case 'OPEN':
      case 'LIVE_CHAT':
      case 'ACTIVE':
      case 'WITH_AGENT':
      case 'ADMIN':
        return ChatConversationStatus.open;
      case 'CLOSED':
      case 'CLOSE':
        return ChatConversationStatus.closed;
      default:
        return ChatConversationStatus.unknown;
    }
  }

  static String _stringValue(Object? value) {
    if (value == null) return '';
    return value.toString().trim();
  }

  static int _compareMessages(ChatMessageModel left, ChatMessageModel right) {
    final leftTime = left.createdAt;
    final rightTime = right.createdAt;
    if (leftTime == null && rightTime != null) return -1;
    if (leftTime != null && rightTime == null) return 1;
    if (leftTime != null && rightTime != null) {
      final timeOrder = leftTime.compareTo(rightTime);
      if (timeOrder != 0) return timeOrder;
    }

    final leftId = left.id ?? '';
    final rightId = right.id ?? '';
    final leftNumericId = int.tryParse(leftId);
    final rightNumericId = int.tryParse(rightId);
    if (leftNumericId != null && rightNumericId != null) {
      return leftNumericId.compareTo(rightNumericId);
    }
    return leftId.compareTo(rightId);
  }
}

class ChatRepository {
  ChatRepository(this._dio);

  final Dio _dio;

  Future<ChatConversationModel> startConversation({
    String language = 'en',
  }) async {
    try {
      debugPrint('[ChatRepository] startConversation entered');
      final response = await _dio.post<dynamic>(
        ApiEndpoints.chatStart,
        data: {'language': language},
      );
      return _parseConversationResponse(response.data);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<ChatConversationModel> fetchCurrentConversation({
    String? conversationId,
    String language = 'en',
  }) async {
    try {
      debugPrint('[ChatRepository] fetchCurrentConversation entered');
      final response = await _dio.get<dynamic>(
        ApiEndpoints.chatCurrent,
        queryParameters: {
          if (conversationId != null)
            'conversation_id': int.parse(conversationId),
          'language': language,
        },
      );
      return _parseConversationResponse(response.data);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<ChatMessageModel> sendMessage({
    required String conversationId,
    required String text,
    required String clientMessageId,
  }) async {
    final trimmed = text.trim();
    final parsedConversationId = int.tryParse(conversationId);
    if (trimmed.isEmpty || parsedConversationId == null) {
      throw const ApiException(ApiFailure.validation, detail: 'validation');
    }

    try {
      final response = await _dio.post<dynamic>(
        ApiEndpoints.chatSendMessage,
        data: {
          'conversation_id': parsedConversationId,
          'message': trimmed,
          'client_message_id': clientMessageId,
        },
      );
      final root = response.data;
      final data = root is Map ? root['data'] : null;
      final message = data is Map ? data['message'] : null;
      if (message is! Map) {
        throw const ApiException(ApiFailure.unknown);
      }
      final parsed = ChatMessageModel.fromJson(
        Map<String, dynamic>.from(message),
      );
      if (parsed.id == null || parsed.createdAt == null) {
        throw const ApiException(ApiFailure.unknown);
      }
      return parsed;
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<ChatOptionSelectionResult> selectOption({
    required String conversationId,
    required String optionId,
    String language = 'en',
  }) async {
    final trimmed = optionId.trim();
    final parsedConversationId = int.tryParse(conversationId);
    final parsedOptionId = int.tryParse(trimmed);
    if (trimmed.isEmpty ||
        parsedConversationId == null ||
        parsedOptionId == null) {
      throw const ApiException(ApiFailure.validation, detail: 'validation');
    }

    try {
      final response = await _dio.post<dynamic>(
        ApiEndpoints.chatSelectOption,
        data: {
          'conversation_id': parsedConversationId,
          'option_id': parsedOptionId,
          'language': language,
        },
      );
      final root = response.data is Map
          ? Map<String, dynamic>.from(response.data as Map)
          : <String, dynamic>{};
      return ChatOptionSelectionResult.fromJson(root);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<ChatConversationModel> navigateToMainMenu({
    required String conversationId,
    String language = 'en',
  }) async {
    final parsedConversationId = int.tryParse(conversationId);
    if (parsedConversationId == null) {
      throw const ApiException(ApiFailure.validation, detail: 'validation');
    }

    try {
      final response = await _dio.post<dynamic>(
        ApiEndpoints.chatNavigate,
        data: {
          'conversation_id': parsedConversationId,
          'action': 'main_menu',
          'language': language,
        },
      );
      return _parseConversationResponse(response.data);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  ChatConversationModel _parseConversationResponse(dynamic data) {
    final Map<String, dynamic> root =
        data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
    return ChatConversationModel.fromJson(root);
  }
}

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(ref.watch(dioProvider));
});
