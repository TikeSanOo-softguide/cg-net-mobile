import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pusher_reverb_flutter/pusher_reverb_flutter.dart' as reverb;

import '../../core/network/api_endpoints/api_endpoints.dart';
import '../../core/storage/secure_storage/secure_storage.dart';
import 'chat_repository.dart';

enum ChatRealtimeConnectionState {
  connecting,
  connected,
  disconnected,
  reconnecting,
  error,
}

sealed class ChatRealtimeEvent {
  const ChatRealtimeEvent();
}

class ChatRealtimeMessageEvent extends ChatRealtimeEvent {
  const ChatRealtimeMessageEvent(this.message);

  final ChatMessageModel message;
}

class ChatRealtimeConversationEvent extends ChatRealtimeEvent {
  const ChatRealtimeConversationEvent({
    required this.conversationId,
    required this.status,
  });

  final String conversationId;
  final ChatConversationStatus status;
}

abstract interface class ChatRealtimeClient {
  Stream<ChatRealtimeEvent> get events;
  Stream<ChatRealtimeConnectionState> get connectionStates;

  Future<void> subscribeConversation(String conversationId);
  Future<void> unsubscribeConversation(String conversationId);
}

class ChatRealtimeEventParser {
  const ChatRealtimeEventParser._();

  static ChatRealtimeEvent? parse({
    required String eventName,
    required Object? data,
  }) {
    final normalizedEventName = eventName.replaceFirst(RegExp(r'^\.'), '');
    if (normalizedEventName != 'chat.message.created' &&
        normalizedEventName != 'chat.conversation.status_changed') {
      return null;
    }

    try {
      final decoded = data is String ? jsonDecode(data) : data;
      if (decoded is! Map) {
        throw const FormatException('Expected an object event payload.');
      }
      final payload = Map<String, dynamic>.from(decoded);

      if (normalizedEventName == 'chat.message.created') {
        final rawMessage = payload['message'] is Map
            ? Map<String, dynamic>.from(payload['message'] as Map)
            : payload;
        final message = ChatMessageModel.fromJson(rawMessage);
        if (message.id == null || message.conversationId == null) {
          throw const FormatException(
            'Message event is missing id or conversation_id.',
          );
        }
        return ChatRealtimeMessageEvent(message);
      }

      final conversationId = _stringValue(payload['conversation_id']);
      final status = _normalizeStatus(_stringValue(payload['status']));
      if (conversationId.isEmpty || status == ChatConversationStatus.unknown) {
        throw const FormatException(
          'Status event is missing conversation_id or a supported status.',
        );
      }
      return ChatRealtimeConversationEvent(
        conversationId: conversationId,
        status: status,
      );
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          '[Chat realtime] Could not parse $normalizedEventName: $error; payload=$data',
        );
        debugPrintStack(stackTrace: stackTrace);
      }
      return null;
    }
  }

  static String _stringValue(Object? value) => value?.toString().trim() ?? '';

  static ChatConversationStatus _normalizeStatus(String value) {
    switch (value.toLowerCase()) {
      case 'bot':
        return ChatConversationStatus.chatFlow;
      case 'waiting_agent':
        return ChatConversationStatus.waiting;
      case 'open':
      case 'with_agent':
        return ChatConversationStatus.open;
      case 'closed':
        return ChatConversationStatus.closed;
      default:
        return ChatConversationStatus.unknown;
    }
  }
}

class ChatRealtimeService implements ChatRealtimeClient {
  ChatRealtimeService(this._secureStorage);

  final SecureStorage _secureStorage;
  final StreamController<ChatRealtimeEvent> _events =
      StreamController<ChatRealtimeEvent>.broadcast();
  reverb.ReverbClient? _client;
  StreamSubscription<reverb.ChannelEvent>? _channelSubscription;
  String? _channelName;
  Future<void>? _connecting;

  @override
  Stream<ChatRealtimeEvent> get events => _events.stream;

  reverb.ReverbClient get _reverb {
    return _client ??= reverb.ReverbClient.instance(
      host: ApiEndpoints.reverbHost.isNotEmpty
          ? ApiEndpoints.reverbHost
          : Uri.parse(ApiEndpoints.baseUrl).host,
      port: ApiEndpoints.reverbPort,
      appKey: ApiEndpoints.reverbAppKey,
      authEndpoint:
          '${ApiEndpoints.baseUrl.replaceFirst(RegExp(r'/+$'), '')}/broadcasting/auth',
      authorizer: (channelName, socketId) async {
        final token = await _secureStorage.readToken();
        if (token == null || token.isEmpty) {
          throw StateError('Cannot authorize chat channel without a session.');
        }
        return {'Authorization': 'Bearer $token'};
      },
      // useTLS: ApiEndpoints.reverbScheme == 'https',
      onError: (error) {
        if (kDebugMode) {
          debugPrint('[Chat realtime] Reverb client error: $error');
        }
      },
    );
  }

  @override
  Stream<ChatRealtimeConnectionState> get connectionStates {
    return _reverb.onConnectionStateChange.map((state) {
      final mappedState = _mapConnectionState(state);
      if (kDebugMode) {
        debugPrint('[Chat realtime] Connection: ${mappedState.name}');
      }
      return mappedState;
    });
  }

  @override
  Future<void> subscribeConversation(String conversationId) async {
    try {
      final nextChannelName = 'private-chat.conversation.$conversationId';
      if (_channelName == nextChannelName &&
          _reverb.connectionState == reverb.ConnectionState.connected) {
        return;
      }

      if (_channelName != nextChannelName) {
        await _channelSubscription?.cancel();
        if (_channelName != null) {
          try {
            _reverb.unsubscribeFromChannel(_channelName!);
          } catch (_) {}
        }
        _channelName = null;
      }

      final setupTimer = Stopwatch()..start();
      if (kDebugMode) {
        debugPrint('[Reverb] subscription setup started: $nextChannelName');
      }

      await _connect();
      if (_reverb.connectionState != reverb.ConnectionState.connected) {
        if (kDebugMode) {
          debugPrint(
            '[Chat realtime] Realtime disconnected; skipping channel subscription $nextChannelName',
          );
        }
        return;
      }
      if (_channelName == nextChannelName) return;

      final channel = _reverb.subscribeToPrivateChannel(nextChannelName);
      _channelName = nextChannelName;
      _channelSubscription = channel.stream.listen(
        _handleChannelEvent,
        onError: (Object error, StackTrace stackTrace) {
          if (kDebugMode) {
            debugPrint('[Chat realtime] Channel stream error: $error');
          }
        },
      );
      if (kDebugMode) {
        debugPrint(
          '[Reverb] subscription setup completed: ${setupTimer.elapsedMilliseconds} ms',
        );
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint(
          '[Chat realtime] Could not subscribe to conversation $conversationId: $error',
        );
      }
    }
  }

  @override
  Future<void> unsubscribeConversation(String conversationId) async {
    try {
      final channelName = 'private-chat.conversation.$conversationId';
      if (_channelName != channelName) return;

      await _channelSubscription?.cancel();
      _channelSubscription = null;
      try {
        _reverb.unsubscribeFromChannel(channelName);
      } catch (_) {}
      _channelName = null;
      if (kDebugMode) {
        debugPrint('[Chat realtime] Unsubscribed: $channelName');
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint(
          '[Chat realtime] Could not unsubscribe conversation $conversationId: $error',
        );
      }
    }
  }

  Future<void> _connect() async {
    if (_reverb.connectionState == reverb.ConnectionState.connected) return;
    if (_connecting != null) return _connecting!;

    final connectionTimer = Stopwatch()..start();
    if (kDebugMode) {
      debugPrint('[Reverb] connection started');
    }

    Future<void> connectAttempt() async {
      try {
        if (_reverb.connectionState == reverb.ConnectionState.disconnected ||
            _reverb.connectionState == reverb.ConnectionState.error) {
          await _reverb.connect();
        }

        if (_reverb.connectionState == reverb.ConnectionState.connected) {
          return;
        }

        await _reverb.onConnectionStateChange
            .firstWhere(
              (state) => state == reverb.ConnectionState.connected,
              orElse: () => reverb.ConnectionState.disconnected,
            )
            .timeout(const Duration(seconds: 8));
      } catch (error) {
        if (kDebugMode) {
          debugPrint(
            '[Reverb] connection failed after ${connectionTimer.elapsedMilliseconds} ms: $error',
          );
        }
      }
    }

    _connecting = connectAttempt();
    try {
      await _connecting;
      if (kDebugMode &&
          _reverb.connectionState == reverb.ConnectionState.connected) {
        debugPrint(
          '[Reverb] connected: ${connectionTimer.elapsedMilliseconds} ms',
        );
      }
    } finally {
      _connecting = null;
    }
  }

  void _handleChannelEvent(reverb.ChannelEvent event) {
    if (event.channelName != _channelName) return;
    if (kDebugMode) {
      debugPrint(
        '[Chat realtime] Event received: ${event.eventName} on ${event.channelName}',
      );
    }

    final parsedEvent = ChatRealtimeEventParser.parse(
      eventName: event.eventName,
      data: event.data,
    );
    if (parsedEvent == null) return;

    if (kDebugMode) {
      switch (parsedEvent) {
        case ChatRealtimeMessageEvent(:final message):
          debugPrint(
            '[Chat realtime] Parsed message ${message.id} for conversation ${message.conversationId}',
          );
        case ChatRealtimeConversationEvent(
            :final conversationId,
            :final status
          ):
          debugPrint(
            '[Chat realtime] Parsed conversation $conversationId status ${status.name}',
          );
      }
    }
    _events.add(parsedEvent);
  }

  ChatRealtimeConnectionState _mapConnectionState(
    reverb.ConnectionState state,
  ) {
    return switch (state) {
      reverb.ConnectionState.connecting =>
        ChatRealtimeConnectionState.connecting,
      reverb.ConnectionState.connected => ChatRealtimeConnectionState.connected,
      reverb.ConnectionState.disconnected =>
        ChatRealtimeConnectionState.disconnected,
      reverb.ConnectionState.reconnecting =>
        ChatRealtimeConnectionState.reconnecting,
      reverb.ConnectionState.error => ChatRealtimeConnectionState.error,
    };
  }

  Future<void> dispose() async {
    if (_channelName != null) {
      final conversationId =
          _channelName!.replaceFirst('private-chat.conversation.', '');
      await unsubscribeConversation(conversationId);
    }
    _reverb.disconnect();
    await _events.close();
  }
}

final chatRealtimeClientProvider = Provider<ChatRealtimeClient>((ref) {
  final service = ChatRealtimeService(ref.watch(secureStorageProvider));
  ref.onDispose(() {
    unawaited(service.dispose());
  });
  return service;
});
