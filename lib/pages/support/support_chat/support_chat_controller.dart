import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../data/chat/chat_repository.dart';
import '../../../data/chat/chat_realtime_service.dart';

class ChatMessage {
  const ChatMessage({
    required this.text,
    required this.isMine,
    required this.sentAt,
    this.flowOptions = const [],
    this.selectedOption,
    this.id,
    this.conversationId,
    this.senderType = '',
    this.fileName,
  });

  final String? id;
  final String? conversationId;
  final String senderType;
  final String text;
  final bool isMine;
  final DateTime sentAt;
  final ChatFlowOption? selectedOption;
  final List<ChatFlowOption> flowOptions;
  final String? fileName;
}

int _compareChatMessages(ChatMessage left, ChatMessage right) {
  final timeOrder = left.sentAt.compareTo(right.sentAt);
  if (timeOrder != 0) return timeOrder;
  final leftNumericId = int.tryParse(left.id ?? '');
  final rightNumericId = int.tryParse(right.id ?? '');
  if (leftNumericId != null && rightNumericId != null) {
    return leftNumericId.compareTo(rightNumericId);
  }
  return (left.id ?? '').compareTo(right.id ?? '');
}

class SupportChatState {
  const SupportChatState({
    this.status = ChatConversationStatus.unknown,
    this.conversationId,
    this.flowMessage,
    this.options = const [],
    this.messages = const [],
    this.isLoading = false,
    this.isSubmittingOption = false,
    this.isNavigatingToMainMenu = false,
    this.isStartingChat = false,
    this.isSendingMessage = false,
    this.realtimeReconnectRevision = 0,
    this.errorMessage,
  });

  final ChatConversationStatus status;
  final String? conversationId;
  final String? flowMessage;
  final List<ChatFlowOption> options;
  final List<ChatMessage> messages;
  final bool isLoading;
  final bool isSubmittingOption;
  final bool isNavigatingToMainMenu;
  final bool isStartingChat;
  final bool isSendingMessage;
  final int realtimeReconnectRevision;
  final String? errorMessage;

  bool get hasConversation =>
      conversationId != null || status != ChatConversationStatus.unknown;
  bool get isWaiting => status == ChatConversationStatus.waiting;
  bool get isChatFlow => status == ChatConversationStatus.chatFlow;
  bool get isOpen => status == ChatConversationStatus.open;
  bool get isClosed => status == ChatConversationStatus.closed;
  bool get canStartChat => isClosed || !hasConversation;
  bool get composerEnabled => isOpen && !isLoading && !isSendingMessage;

  SupportChatState copyWith({
    ChatConversationStatus? status,
    String? conversationId,
    String? flowMessage,
    List<ChatFlowOption>? options,
    List<ChatMessage>? messages,
    bool? isLoading,
    bool? isSubmittingOption,
    bool? isNavigatingToMainMenu,
    bool? isStartingChat,
    bool? isSendingMessage,
    int? realtimeReconnectRevision,
    String? errorMessage,
    bool clearConversationId = false,
    bool clearErrorMessage = false,
  }) {
    return SupportChatState(
      status: status ?? this.status,
      conversationId:
          clearConversationId ? null : conversationId ?? this.conversationId,
      flowMessage: flowMessage ?? this.flowMessage,
      options: options ?? this.options,
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isSubmittingOption: isSubmittingOption ?? this.isSubmittingOption,
      isNavigatingToMainMenu:
          isNavigatingToMainMenu ?? this.isNavigatingToMainMenu,
      isStartingChat: isStartingChat ?? this.isStartingChat,
      isSendingMessage: isSendingMessage ?? this.isSendingMessage,
      realtimeReconnectRevision:
          realtimeReconnectRevision ?? this.realtimeReconnectRevision,
      errorMessage:
          clearErrorMessage ? null : errorMessage ?? this.errorMessage,
    );
  }

  factory SupportChatState.fromConversation(
      ChatConversationModel? conversation) {
    final messages = <ChatMessage>[];
    final messageIds = <String>{};
    for (final message
        in conversation?.messages ?? const <ChatMessageModel>[]) {
      final id = message.id?.isNotEmpty == true ? message.id : null;
      if (id != null && !messageIds.add(id)) continue;
      final isMine = (message.role).toLowerCase() == 'user' ||
          (message.role).toLowerCase() == 'customer';
      messages.add(ChatMessage(
        id: id,
        conversationId: message.conversationId,
        text: message.text,
        isMine: isMine,
        senderType: message.role,
        sentAt: message.createdAt ?? DateTime.now(),
        selectedOption: message.selectedOption,
        flowOptions: message.flowOptions,
      ));
    }
    messages.sort(_compareChatMessages);

    return SupportChatState(
      status: conversation?.status ?? ChatConversationStatus.unknown,
      conversationId: conversation?.id,
      flowMessage: conversation?.message,
      options: conversation?.options ?? const [],
      messages: messages,
      isLoading: false,
      isSubmittingOption: false,
      isStartingChat: false,
      isSendingMessage: false,
    );
  }
}

class SupportChatController extends StateNotifier<SupportChatState> {
  SupportChatController(this._repository, this._realtime)
      : super(const SupportChatState()) {
    _realtimeEventsSubscription = _realtime.events.listen(
      _handleRealtimeEvent,
      onError: (Object error, StackTrace stackTrace) {
        if (kDebugMode) {
          debugPrint('[Chat realtime] Event stream error: $error');
          debugPrintStack(stackTrace: stackTrace);
        }
      },
    );
    _realtimeConnectionSubscription = _realtime.connectionStates.listen(
      (connectionState) {
        if (connectionState != ChatRealtimeConnectionState.connected) return;
        if (!_hasConnectedRealtime) {
          _hasConnectedRealtime = true;
          return;
        }
        state = state.copyWith(
          realtimeReconnectRevision: state.realtimeReconnectRevision + 1,
        );
      },
    );
  }

  final ChatRepository _repository;
  final ChatRealtimeClient _realtime;
  int _clientMessageSequence = 0;
  int _activeRequestId = 0;
  String? _retryMessageText;
  String? _retryClientMessageId;
  String? _realtimeConversationId;
  bool _hasConnectedRealtime = false;
  late final StreamSubscription<ChatRealtimeEvent> _realtimeEventsSubscription;
  late final StreamSubscription<ChatRealtimeConnectionState>
      _realtimeConnectionSubscription;

  Future<void> loadCurrentConversation({
    String? conversationId,
    String language = 'en',
  }) async {
    debugPrint('[ChatInit] 1. loadCurrentConversation entered');
    final initializationTimer = Stopwatch()..start();
    final requestId = ++_activeRequestId;
    final previousState = state;
    final targetConversationId = conversationId ?? previousState.conversationId;
    state = state.copyWith(isLoading: true, clearErrorMessage: true);
    final conversationsTimer = Stopwatch()..start();
    if (kDebugMode) {
      debugPrint('[Chat] loading conversations started');
    }
    try {
      debugPrint('[ChatInit] 2. calling fetchCurrentConversation');
      var conversation = await _repository.fetchCurrentConversation(
        conversationId: targetConversationId,
        language: language,
      );
      debugPrint('[ChatInit] 3. fetchCurrentConversation completed');
      if (kDebugMode) {
        debugPrint(
          '[Chat] loading conversations completed: ${conversationsTimer.elapsedMilliseconds} ms',
        );
        debugPrint(
          '[Chat] messages loaded with conversation response: ${conversation.messages.length}',
        );
      }
      if (requestId != _activeRequestId) return;

      final noActiveConversation = (conversation.id == null ||
              conversation.status == ChatConversationStatus.unknown) &&
          !conversation.isActive &&
          !conversation.isClosed &&
          conversation.options.isEmpty &&
          conversation.message == null &&
          conversation.messages.isEmpty;

      if (noActiveConversation) {
        _unsubscribeCurrentConversationInBackground();
        state = state.copyWith(
          status: ChatConversationStatus.unknown,
          conversationId: null,
          flowMessage: null,
          options: const [],
          messages: const [],
          isLoading: false,
          isSendingMessage: false,
          clearErrorMessage: true,
        );
        await startConversation(language: language);
        if (kDebugMode) {
          debugPrint(
            '[Chat] screen initialization completed: ${initializationTimer.elapsedMilliseconds} ms',
          );
        }
        return;
      }

      var status = conversation.status;
      if (status == ChatConversationStatus.unknown &&
          (conversation.options.isNotEmpty || conversation.message != null)) {
        status = ChatConversationStatus.chatFlow;
      }

      final loadedState =
          SupportChatState.fromConversation(conversation).copyWith(
        status: status,
      );
      final sameConversation = previousState.conversationId != null &&
          previousState.conversationId == loadedState.conversationId;
      final historyOptions = _mostRecentFlowOptions(
        loadedState.messages,
        prompt: loadedState.flowMessage,
      );
      final restoredOptions = loadedState.options.isNotEmpty
          ? loadedState.options
          : status != ChatConversationStatus.chatFlow
              ? const <ChatFlowOption>[]
              : historyOptions.isNotEmpty
                  ? historyOptions
                  : sameConversation
                      ? previousState.options.isNotEmpty
                          ? previousState.options
                          : _mostRecentFlowOptions(
                              previousState.messages,
                              prompt: loadedState.flowMessage,
                            )
                      : const <ChatFlowOption>[];
      final mergedMessages = sameConversation
          ? _mergeMessages(previousState.messages, loadedState.messages)
          : loadedState.messages;

      state = loadedState.copyWith(
        options: restoredOptions,
        messages: mergedMessages,
        isSendingMessage: sameConversation && previousState.isSendingMessage,
        realtimeReconnectRevision: previousState.realtimeReconnectRevision,
        isLoading: false,
      );
      _subscribeToConversation(loadedState.conversationId);
      if (kDebugMode) {
        debugPrint(
          '[Chat] screen initialization completed: ${initializationTimer.elapsedMilliseconds} ms',
        );
      }
    } on ApiException catch (error) {
      if (requestId != _activeRequestId) return;

      if (kDebugMode) {
        debugPrint(
          '[Chat] loading conversations failed after ${conversationsTimer.elapsedMilliseconds} ms: ${error.messageKey}',
        );
        debugPrint(
          '[Chat] screen initialization failed after ${initializationTimer.elapsedMilliseconds} ms',
        );
      }
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.messageKey,
        isSendingMessage: false,
      );
    } catch (_) {
      if (requestId != _activeRequestId) return;
      if (kDebugMode) {
        debugPrint(
          '[Chat] loading conversations failed after ${conversationsTimer.elapsedMilliseconds} ms',
        );
        debugPrint(
          '[Chat] screen initialization failed after ${initializationTimer.elapsedMilliseconds} ms',
        );
      }
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'api.unknown',
        isSendingMessage: false,
      );
    }
  }

  List<ChatFlowOption> _mostRecentFlowOptions(
    List<ChatMessage> messages, {
    String? prompt,
  }) {
    for (final message in messages.reversed) {
      if (!message.isMine &&
          message.flowOptions.isNotEmpty &&
          (prompt == null || message.text.trim() == prompt.trim())) {
        return message.flowOptions;
      }
    }
    return const [];
  }

  Future<void> _unsubscribeCurrentConversation() async {
    final conversationId = _realtimeConversationId;
    _realtimeConversationId = null;
    if (conversationId != null) {
      try {
        await _realtime.unsubscribeConversation(conversationId);
      } catch (error) {
        if (kDebugMode) {
          debugPrint(
            '[Reverb] unsubscribe failed for conversation $conversationId: $error',
          );
        }
      }
    }
  }

  void _unsubscribeCurrentConversationInBackground() {
    unawaited(_unsubscribeCurrentConversation());
  }

  Future<void> startConversation({String language = 'en'}) async {
    if (state.isStartingChat || state.isSubmittingOption) return;
    final requestId = ++_activeRequestId;
    final startTimer = Stopwatch()..start();
    state = state.copyWith(
      isStartingChat: true,
      isLoading: true,
      clearErrorMessage: true,
    );
    if (kDebugMode) {
      debugPrint('[Chat] starting conversation request started');
    }
    try {
      final conversation = await _repository.startConversation(
        language: language,
      );
      if (kDebugMode) {
        debugPrint(
          '[Chat] starting conversation request completed: ${startTimer.elapsedMilliseconds} ms',
        );
      }
      if (requestId != _activeRequestId) return;

      var status = conversation.status;
      if (status == ChatConversationStatus.unknown) {
        status = ChatConversationStatus.chatFlow;
      }

      final newState = SupportChatState.fromConversation(conversation).copyWith(
        messages: _mergeMessages(state.messages,
            SupportChatState.fromConversation(conversation).messages),
        status: status,
        isStartingChat: false,
        isLoading: false,
      );
      state = newState;
      _subscribeToConversation(newState.conversationId);
    } on ApiException catch (error) {
      if (requestId != _activeRequestId) return;
      if (kDebugMode) {
        debugPrint(
          '[Chat] starting conversation request failed after ${startTimer.elapsedMilliseconds} ms: ${error.messageKey}',
        );
      }
      state = state.copyWith(
        isStartingChat: false,
        isLoading: false,
        errorMessage: error.messageKey,
      );
    } catch (_) {
      if (requestId != _activeRequestId) return;
      if (kDebugMode) {
        debugPrint(
          '[Chat] starting conversation request failed after ${startTimer.elapsedMilliseconds} ms',
        );
      }
      state = state.copyWith(
        isStartingChat: false,
        isLoading: false,
        errorMessage: 'api.unknown',
      );
    }
  }

  Future<ChatOptionSelectionResult?> selectOption(
    String optionId, {
    String language = 'en',
  }) async {
    final conversationId = state.conversationId;
    if (!state.isChatFlow ||
        state.isSubmittingOption ||
        optionId.trim().isEmpty ||
        conversationId == null) {
      return null;
    }
    final requestId = ++_activeRequestId;

    final selectedOption = state.options.firstWhere(
      (opt) =>
          opt.id == optionId || opt.value == optionId || opt.label == optionId,
      orElse: () => ChatFlowOption(id: optionId, label: optionId),
    );

    final currentFlowMsg = state.flowMessage;
    final currentFlowOpts = List<ChatFlowOption>.from(state.options);

    final updatedMessages = List<ChatMessage>.from(state.messages);
    final lastMsg = updatedMessages.isNotEmpty ? updatedMessages.last : null;
    final lastIsBot = lastMsg != null && !lastMsg.isMine;

    if (lastIsBot &&
        (currentFlowMsg == null ||
            lastMsg.text.trim() == currentFlowMsg.trim())) {
      updatedMessages[updatedMessages.length - 1] = ChatMessage(
        id: lastMsg.id,
        conversationId: lastMsg.conversationId,
        senderType: lastMsg.senderType,
        text: lastMsg.text,
        isMine: false,
        sentAt: lastMsg.sentAt,
        flowOptions: currentFlowOpts,
        fileName: lastMsg.fileName,
      );
    } else if (currentFlowMsg != null && currentFlowMsg.isNotEmpty) {
      updatedMessages.add(ChatMessage(
        id: 'flow-bot-${DateTime.now().millisecondsSinceEpoch}',
        text: currentFlowMsg,
        isMine: false,
        sentAt: DateTime.now(),
        flowOptions: currentFlowOpts,
      ));
    }

    updatedMessages.add(ChatMessage(
      id: 'flow-user-${DateTime.now().millisecondsSinceEpoch}',
      text: selectedOption.label,
      isMine: true,
      sentAt: DateTime.now().add(const Duration(milliseconds: 1)),
    ));

    state = state.copyWith(
      messages: updatedMessages,
      isSubmittingOption: true,
      clearErrorMessage: true,
    );

    try {
      final result = await _repository.selectOption(
        conversationId: conversationId,
        optionId: optionId,
        language: language,
      );
      if (requestId != _activeRequestId) return null;

      final conversation = result.conversation;
      var status = conversation.status;
      if (status == ChatConversationStatus.unknown &&
          (conversation.options.isNotEmpty || conversation.message != null)) {
        status = ChatConversationStatus.chatFlow;
      }

      final updatedState = SupportChatState.fromConversation(conversation);
      final isNextStep = result.action == ChatFlowOptionAction.goToStep;
      final shouldKeepCurrentStep = result.action == ChatFlowOptionAction.goToUrl;
      final actionReply = updatedState.flowMessage?.trim() ?? '';
      final mergedMessages = shouldKeepCurrentStep
          ? _mergeMessages(updatedMessages, const <ChatMessage>[])
          : _mergeMessages(updatedMessages, updatedState.messages);
      if (!isNextStep &&
          !shouldKeepCurrentStep &&
          actionReply.isNotEmpty &&
          !mergedMessages.any(
            (message) => !message.isMine && message.text.trim() == actionReply,
          )) {
        mergedMessages.add(ChatMessage(
          id: 'flow-reply-${DateTime.now().millisecondsSinceEpoch}',
          conversationId: updatedState.conversationId,
          senderType: 'system',
          text: actionReply,
          isMine: false,
          sentAt: DateTime.now(),
        ));
      }
      state = updatedState.copyWith(
        flowMessage:
            shouldKeepCurrentStep ? currentFlowMsg : updatedState.flowMessage,
        options: shouldKeepCurrentStep
            ? currentFlowOpts
            : isNextStep
                ? updatedState.options
                : const [],
        messages: mergedMessages,
        status: shouldKeepCurrentStep
            ? ChatConversationStatus.chatFlow
            : status,
        isSubmittingOption: false,
        realtimeReconnectRevision: state.realtimeReconnectRevision,
      );
      _subscribeToConversation(updatedState.conversationId);
      return result;
    } on ApiException catch (error) {
      if (requestId != _activeRequestId) return null;
      if (_isStaleOption(error) && state.conversationId == conversationId) {
        await loadCurrentConversation(
          conversationId: conversationId,
          language: language,
        );
        if (mounted) {
          state = state.copyWith(errorMessage: 'support.option_expired');
        }
        return null;
      }
      state = state.copyWith(
        isSubmittingOption: false,
        errorMessage: error.messageKey,
      );
      return null;
    } catch (_) {
      if (requestId != _activeRequestId) return null;
      state = state.copyWith(
        isSubmittingOption: false,
        errorMessage: 'api.unknown',
      );
      return null;
    }
  }

  bool _isStaleOption(ApiException error) {
    final response = error.responseData;
    return response is Map && response['code'] == 'stale_chat_option';
  }

  Future<bool> navigateToMainMenu({String language = 'en'}) async {
    final conversationId = state.conversationId;
    if (!state.isChatFlow ||
        state.isLoading ||
        state.isSubmittingOption ||
        state.isNavigatingToMainMenu ||
        conversationId == null) {
      return false;
    }

    final requestId = ++_activeRequestId;
    final previousState = state;
    state = state.copyWith(
      isNavigatingToMainMenu: true,
      clearErrorMessage: true,
    );

    try {
      final conversation = await _repository.navigateToMainMenu(
        conversationId: conversationId,
        language: language,
      );
      if (requestId != _activeRequestId) return false;
      if (conversation.id != conversationId ||
          conversation.status != ChatConversationStatus.chatFlow) {
        throw const ApiException(ApiFailure.unknown);
      }

      final updatedState = SupportChatState.fromConversation(conversation);
      state = updatedState.copyWith(
        messages: _mergeMessages(previousState.messages, updatedState.messages),
        isNavigatingToMainMenu: false,
        realtimeReconnectRevision: previousState.realtimeReconnectRevision,
      );
      _subscribeToConversation(updatedState.conversationId);
      return true;
    } on ApiException catch (error) {
      if (requestId != _activeRequestId) return false;
      state = state.copyWith(
        isNavigatingToMainMenu: false,
        errorMessage: error.messageKey,
      );
      return false;
    } catch (_) {
      if (requestId != _activeRequestId) return false;
      state = state.copyWith(
        isNavigatingToMainMenu: false,
        errorMessage: 'api.unknown',
      );
      return false;
    }
  }

  void _subscribeToConversation(String? conversationId) {
    if (conversationId == null || conversationId == _realtimeConversationId) {
      return;
    }
    _realtimeConversationId = conversationId;
    unawaited(_subscribe(conversationId));
  }

  Future<void> _subscribe(String conversationId) async {
    try {
      await _realtime.subscribeConversation(conversationId);
    } catch (_) {
      if (kDebugMode) {
        debugPrint(
          '[Reverb] subscription failed for conversation $conversationId',
        );
      }
    }
  }

  Future<void> leaveChat() => _unsubscribeCurrentConversation();

  void _handleRealtimeEvent(ChatRealtimeEvent event) {
    switch (event) {
      case ChatRealtimeMessageEvent(:final message):
        final conversationId = state.conversationId;
        if (conversationId == null ||
            message.conversationId != conversationId ||
            message.id == null) {
          return;
        }
        final incoming = ChatMessage(
          id: message.id,
          conversationId: message.conversationId,
          text: message.text,
          isMine: _isCustomerMessage(message.role),
          senderType: message.role,
          sentAt: message.createdAt ?? DateTime.now(),
          flowOptions: message.flowOptions,
        );
        state = state.copyWith(
          messages: _mergeMessages(state.messages, [incoming]),
        );
        if (kDebugMode) {
          debugPrint(
            '[Chat controller] Added message ${message.id}; count=${state.messages.length}',
          );
        }
        break;
      case ChatRealtimeConversationEvent(:final conversationId, :final status):
        if (state.conversationId == null ||
            state.conversationId != conversationId) {
          return;
        }
        if (kDebugMode) {
          debugPrint(
            '[Chat controller] Status before update: ${state.status.name}; event=${status.name}; conversation=$conversationId',
          );
        }
        state = state.copyWith(
          status: status,
          isLoading: false,
          isStartingChat: false,
          isSendingMessage: false,
          clearErrorMessage: true,
        );
        if (status == ChatConversationStatus.closed) {
          state = state.copyWith(
            flowMessage: null,
            options: const [],
          );
        }
        if (status == ChatConversationStatus.open && state.messages.isEmpty) {
          unawaited(loadCurrentConversation(conversationId: conversationId));
        }
        if (kDebugMode) {
          debugPrint(
            '[Chat controller] Status after update: ${state.status.name}',
          );
        }
        break;
    }
  }

  Future<bool> sendText(
    String text, {
    String language = 'en',
  }) async {
    final trimmed = text.trim();
    final conversationId = state.conversationId;
    if (state.isSendingMessage ||
        state.isSubmittingOption ||
        trimmed.isEmpty ||
        !state.composerEnabled ||
        conversationId == null) {
      return false;
    }

    state = state.copyWith(
      isSendingMessage: true,
      clearErrorMessage: true,
    );

    try {
      final latestConversation = await _repository.fetchCurrentConversation(
        conversationId: conversationId,
        language: language,
      );
      if (latestConversation.status == ChatConversationStatus.closed) {
        state = state.copyWith(isSendingMessage: false);
        await loadCurrentConversation(
          conversationId: conversationId,
          language: language,
        );
        return false;
      }
    } on ApiException {
    } catch (_) {
    }

    final clientMessageId = _retryMessageText == trimmed &&
            _retryClientMessageId != null
        ? _retryClientMessageId!
        : '${DateTime.now().microsecondsSinceEpoch}-${_clientMessageSequence++}';
    try {
      final message = await _repository.sendMessage(
        conversationId: conversationId,
        text: trimmed,
        clientMessageId: clientMessageId,
      );
      final sentMessage = ChatMessage(
        id: message.id,
        text: message.text,
        isMine: _isCustomerMessage(message.role),
        sentAt: message.createdAt ?? DateTime.now(),
      );
      state = state.copyWith(
        messages: _mergeMessages(state.messages, [sentMessage]),
        isSendingMessage: false,
      );
      _retryMessageText = null;
      _retryClientMessageId = null;
      return true;
    } on ApiException catch (error) {
      if (_isClosedConversation(error)) {
        await loadCurrentConversation(
          conversationId: conversationId,
          language: language,
        );
        return false;
      }
      _retryMessageText = trimmed;
      _retryClientMessageId = clientMessageId;
      state = state.copyWith(
        isSendingMessage: false,
        errorMessage: error.messageKey,
      );
      return false;
    }
  }

  bool _isClosedConversation(ApiException error) {
    final response = error.responseData;
    if (response is! Map) return false;

    final directStatus = response['status'];
    if (directStatus is String &&
        directStatus.toLowerCase() == 'closed') {
      return true;
    }

    final nestedData = response['data'];
    if (nestedData is Map) {
      final nestedStatus = nestedData['status'];
      if (nestedStatus is String &&
          nestedStatus.toLowerCase() == 'closed') {
        return true;
      }
    }

    final message = response['message'];
    if (message is String &&
        message.toLowerCase().contains('closed')) {
      return true;
    }

    return false;
  }

  bool _isCustomerMessage(String role) {
    final normalizedRole = role.toLowerCase();
    return normalizedRole == 'user' || normalizedRole == 'customer';
  }

  List<ChatMessage> _mergeMessages(
    List<ChatMessage> existing,
    List<ChatMessage> incoming,
  ) {
    final result = <ChatMessage>[];
    final indicesById = <String, int>{};
    final hasRealIncoming =
        incoming.any((m) => m.id != null && !m.id!.startsWith('flow-'));

    for (final message in [...existing, ...incoming]) {
      final id = message.id;
      final index = id == null ? null : indicesById[id];
      if (index != null) {
        final previous = result[index];
        if (message.flowOptions.isNotEmpty) {
          result[index] = ChatMessage(
            id: previous.id,
            conversationId: previous.conversationId,
            senderType: previous.senderType,
            text: previous.text,
            isMine: previous.isMine,
            sentAt: previous.sentAt,
            flowOptions: message.flowOptions,
            fileName: previous.fileName,
          );
        }
        continue;
      }
      if (hasRealIncoming && id != null && id.startsWith('flow-user-')) {
        continue;
      }
      if (id != null) indicesById[id] = result.length;
      result.add(message);
    }
    result.sort(_compareChatMessages);
    return result;
  }

  @override
  void dispose() {
    unawaited(_realtimeEventsSubscription.cancel());
    unawaited(_realtimeConnectionSubscription.cancel());
    super.dispose();
  }
}

final supportChatControllerProvider =
    StateNotifierProvider<SupportChatController, SupportChatState>((ref) {
  return SupportChatController(
    ref.watch(chatRepositoryProvider),
    ref.watch(chatRealtimeClientProvider),
  );
});
