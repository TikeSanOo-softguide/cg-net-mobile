import 'dart:async';
import 'dart:typed_data';

import 'package:cg_net_mobile/core/network/api_exception.dart';
import 'package:cg_net_mobile/data/chat/chat_repository.dart';
import 'package:cg_net_mobile/data/chat/chat_realtime_service.dart';
import 'package:cg_net_mobile/pages/support/support_chat/support_chat_controller.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChatRepository', () {
    test('sends the Laravel message request and parses its persisted reply',
        () async {
      late RequestOptions request;
      final dio = _dio((options) {
        request = options;
        return _jsonResponse(
          201,
          '''
          {"success":true,"data":{"conversation_id":12,"message":{"id":43,"conversation_id":12,"client_message_id":"client-1","sender_type":"customer","message":"Hello","created_at":"2026-10-07T01:00:00.000Z"}}}
          ''',
        );
      });

      final message = await ChatRepository(dio).sendMessage(
        conversationId: '12',
        text: ' Hello ',
        clientMessageId: 'client-1',
      );

      expect(request.method, 'POST');
      expect(request.path, '/chat/messages');
      expect(request.data, {
        'conversation_id': 12,
        'message': 'Hello',
        'client_message_id': 'client-1',
      });
      expect(message.id, '43');
      expect(message.text, 'Hello');
      expect(message.role, 'customer');
      expect(message.conversationId, '12');
      expect(message.createdAt, DateTime.parse('2026-10-07T01:00:00.000Z'));
    });

    test('loads persisted history from current in server order and shape',
        () async {
      late RequestOptions request;
      final dio = _dio((options) {
        request = options;
        return _jsonResponse(
          200,
          '''
          {"success":true,"data":{"conversation_id":12,"status":"with_agent","messages":[
            {"id":2,"sender_type":"agent","message":"Reply","created_at":"2026-10-07T01:00:00.000Z"},
              {"id":1,"sender_type":"customer","message":"Question","flow_options":[{"id":4,"label":"Personal"},{"id":5,"label":"Business"}],"created_at":"2026-10-07T01:00:00.000Z"},
            {"id":1,"sender_type":"customer","message":"Question","created_at":"2026-10-07T01:00:00.000Z"}
          ]}}
          ''',
        );
      });

      final conversation = await ChatRepository(dio).fetchCurrentConversation();
      final state = SupportChatState.fromConversation(conversation);

      expect(request.method, 'GET');
      expect(request.path, '/chat/current');
      expect(conversation.status, ChatConversationStatus.open);
      expect(state.messages.map((message) => message.id), ['1', '2']);
      expect(
          state.messages.map((message) => message.text), ['Question', 'Reply']);
      expect(state.messages.map((message) => message.isMine), [true, false]);
      expect(
        state.messages.first.flowOptions.map((option) => option.label),
        ['Personal', 'Business'],
      );
      expect(state.messages.first.sentAt,
          DateTime.parse('2026-10-07T01:00:00.000Z'));
    });

    test('parses historical step metadata and options from flow messages',
        () async {
      final dio = _dio((_) => _jsonResponse(
            200,
            '''
            {"success":true,"data":{"conversation_id":12,"status":"chat_flow","step":{"message":"Please select your issue.","options":[{"id":"30","label":"Connection"},{"id":"31","label":"Speed"}]},"messages":[
              {"id":11,"conversation_id":12,"sender_type":"system","message":"How can we help you?","step":{"id":10,"name":"Category","message":"How can we help you?","options":[{"id":"1","label":"Personal"},{"id":"2","label":"Business"}]},"created_at":"2026-10-07T00:00:00.000Z"},
              {"id":12,"conversation_id":12,"sender_type":"customer","message":"Personal","selected_option":{"id":"1","label":"Personal"},"step":{"id":10,"name":"Category","message":"How can we help you?","options":[{"id":"1","label":"Personal"},{"id":"2","label":"Business"}]},"created_at":"2026-10-07T00:00:01.000Z"},
              {"id":13,"conversation_id":12,"sender_type":"system","message":"Please select your issue.","selected_option":{"id":"1","label":"Personal"},"step":{"id":20,"name":"Issue","message":"Please select your issue.","options":[{"id":"30","label":"Connection"},{"id":"31","label":"Speed"}]},"created_at":"2026-10-07T00:00:02.000Z"}
            ]}}
            ''',
          ));

      final conversation = await ChatRepository(dio).fetchCurrentConversation();
      final state = SupportChatState.fromConversation(conversation);

      expect(state.messages.length, 3);
      expect(state.messages[2].flowOptions.map((option) => option.label),
          ['Connection', 'Speed']);
      expect(state.messages[2].selectedOption?.label, 'Personal');
    });

    test('parses options as List of Strings or List of Maps safely', () async {
      final stringDio = _dio((_) => _jsonResponse(
            200,
            '{"success":true,"data":{"id":"50","status":"chat_flow","message":"Welcome","options":["Personal","Business","Back to main"]}}',
          ));
      final mapDio = _dio((_) => _jsonResponse(
            200,
            '{"success":true,"data":{"id":"50","status":"chat_flow","message":"Welcome","options":[{"id":"1","label":"Personal"},{"id":"2","label":"Business"}]}}',
          ));

      final stringConv =
          await ChatRepository(stringDio).fetchCurrentConversation();
      final mapConv = await ChatRepository(mapDio).fetchCurrentConversation();

      expect(stringConv.options.map((o) => o.label),
          ['Personal', 'Business', 'Back to main']);
      expect(stringConv.options.map((o) => o.id),
          ['Personal', 'Business', 'Back to main']);

      expect(mapConv.options.map((o) => o.label), ['Personal', 'Business']);
      expect(mapConv.options.map((o) => o.id), ['1', '2']);
    });

    test('selects localized option labels for the active Flutter locale', () {
      final option = ChatFlowOption.fromJson({
        'id': '1',
        'label': {'en': 'Personal', 'my': 'ကိုယ်ရေး', 'zh': '个人'},
      });

      expect(option.label, 'Personal');
      expect(option.labelForLocale('en'), 'Personal');
      expect(option.labelForLocale('my'), 'ကိုယ်ရေး');
      expect(option.labelForLocale('zh'), '个人');
    });

    test('selects option labels from locale-suffixed backend fields', () {
      final option = ChatFlowOption.fromJson({
        'id': '1',
        'label': 'Personal',
        'label_my': 'ကိုယ်ရေး',
        'labels': {'zh': '个人'},
      });

      expect(option.labelForLocale('my'), 'ကိုယ်ရေး');
      expect(option.labelForLocale('zh'), '个人');
    });

    test('leaves an empty option label for the localized UI fallback', () {
      const option = ChatFlowOption(id: 'empty', label: '');

      expect(option.labelForLocale('my'), isEmpty);
    });

    // test('maps 404 responses to a not-found API failure', () async {
    //   final error = ApiException.fromDio(
    //     DioException(
    //       requestOptions: RequestOptions(path: '/chat/current'),
    //       response: Response(
    //         requestOptions: RequestOptions(path: '/chat/current'),
    //         statusCode: 404,
    //         data: {'message': 'Not found'},
    //       ),
    //       type: DioExceptionType.badResponse,
    //     ),
    //   );

    //   expect(error.failure, ApiFailure.notFound);
    //   expect(error.messageKey, 'api.not_found');
    // });

    test('refreshes a specified conversation through current', () async {
      late RequestOptions request;
      final dio = _dio((options) {
        request = options;
        return _jsonResponse(
          200,
          '{"success":true,"data":{"conversation_id":12,"status":"closed","messages":[]}}',
        );
      });

      final conversation = await ChatRepository(dio)
          .fetchCurrentConversation(conversationId: '12');

      expect(request.method, 'GET');
      expect(request.path, '/chat/current');
      expect(request.queryParameters, {
        'conversation_id': 12,
        'language': 'en',
      });
      expect(conversation.status, ChatConversationStatus.closed);
    });

    test('navigates an existing conversation to the main menu', () async {
      late RequestOptions request;
      final dio = _dio((options) {
        request = options;
        return _jsonResponse(
          200,
          '''
          {"success":true,"data":{"conversation_id":12,"status":"bot",
            "step":{"id":3,"message":"Choose an option.","options":[{"id":4,"label":"Internet"}]},
            "messages":[{"id":7,"conversation_id":12,"sender_type":"system",
              "message":"Previous step","created_at":"2026-10-07T01:00:00.000Z"}]}}
          ''',
        );
      });

      final conversation = await ChatRepository(dio).navigateToMainMenu(
        conversationId: '12',
        language: 'zh',
      );

      expect(request.method, 'POST');
      expect(request.path, '/chat/navigate');
      expect(request.data, {
        'conversation_id': 12,
        'action': 'main_menu',
        'language': 'zh',
      });
      expect(conversation.status, ChatConversationStatus.chatFlow);
      expect(conversation.message, 'Choose an option.');
      expect(conversation.options.single.label, 'Internet');
      expect(conversation.messages.single.text, 'Previous step');
    });

    test('selects a step option using the scoped integer Laravel payload',
        () async {
      late RequestOptions request;
      final dio = _dio((options) {
        request = options;
        return _jsonResponse(
          200,
          '{"success":true,"data":{"conversation_id":12,"status":"bot","step":{"message":"Next step","options":[{"id":8,"label":"Billing"}]},"messages":[]}}',
        );
      });

      final result = await ChatRepository(dio).selectOption(
        conversationId: '12',
        optionId: '8',
      );

      expect(request.method, 'POST');
      expect(request.path, '/chat/select-option');
      expect(request.data, {
        'conversation_id': 12,
        'option_id': 8,
        'language': 'en',
      });
      expect(result.conversation.id, '12');
      expect(result.conversation.message, 'Next step');
      expect(result.conversation.options.single.label, 'Billing');
      expect(result.action, isNull);
      expect(result.url, isNull);
    });

    test('passes the selected language and preserves a backend URL action',
        () async {
      late RequestOptions request;
      final dio = _dio((options) {
        request = options;
        return _jsonResponse(
          200,
          '''
          {"success":true,"data":{
            "conversation_id":12,
            "status":"bot",
            "action":"go_to_url",
            "url":"https://example.test/details?source=chat",
            "step":{"message":"Choose an option.","options":[]},
            "messages":[
              {"id":89,"conversation_id":12,"sender_type":"customer","message":"View details","created_at":"2026-10-07T01:00:00.000Z"},
              {"id":90,"conversation_id":12,"sender_type":"system","message":"Opening details.","created_at":"2026-10-07T01:00:01.000Z"}
            ]
          }}
          ''',
        );
      });

      final result = await ChatRepository(dio).selectOption(
        conversationId: '12',
        optionId: '8',
        language: 'my',
      );

      expect(request.data, {
        'conversation_id': 12,
        'option_id': 8,
        'language': 'my',
      });
      expect(result.action, ChatFlowOptionAction.goToUrl);
      expect(result.url, 'https://example.test/details?source=chat');
      expect(result.conversation.messages.map((message) => message.text), [
        'View details',
        'Opening details.',
      ]);
      expect(result.conversation.message, 'Choose an option.');
    });

    test('sends the requested locale when starting the Chat Flow', () async {
      late RequestOptions request;
      final dio = _dio((options) {
        request = options;
        return _jsonResponse(
          200,
          '{"success":true,"data":{"conversation_id":12,"status":"bot","step":{"message":"မင်္ဂလာပါ","options":[{"id":1,"label":"ဝန်ထမ်းနှင့် စကားပြောမည်","action":"transfer_agent"}]},"messages":[]}}',
        );
      });

      final conversation =
          await ChatRepository(dio).startConversation(language: 'my');

      expect(request.method, 'POST');
      expect(request.path, '/chat/start');
      expect(request.data, {'language': 'my'});
      expect(conversation.message, 'မင်္ဂလာပါ');
      expect(conversation.options.single.label, 'ဝန်ထမ်းနှင့် စကားပြောမည်');
    });

    test('classifies Laravel conflicts as closed only for closed status',
        () async {
      final waitingDio = _dio((_) => _jsonResponse(
            409,
            '{"success":false,"data":{"status":"waiting_agent"}}',
          ));

      final waitingError = await _sendFailure(waitingDio);

      expect(waitingError.failure, ApiFailure.unknown);
    });
  });

  group('ChatRealtimeEventParser', () {
    test('parses the Laravel conversation status event contract', () {
      final event = ChatRealtimeEventParser.parse(
        eventName: 'chat.conversation.status_changed',
        data: '''
          {"conversation_id":12,"status":"open","previous_status":"waiting_agent",
           "agent":{"id":4,"username":"agent"},"can_send_message":true,
           "can_select_option":false,"is_closed":false,
           "can_start_new_conversation":false}
        ''',
      );

      expect(event, isA<ChatRealtimeConversationEvent>());
      final statusEvent = event! as ChatRealtimeConversationEvent;
      expect(statusEvent.conversationId, '12');
      expect(statusEvent.status, ChatConversationStatus.open);
    });

    test('parses the Laravel ChatMessageResource broadcast payload', () {
      final event = ChatRealtimeEventParser.parse(
        eventName: 'chat.message.created',
        data: '''
          {"message":{"id":101,"conversation_id":12,"client_message_id":null,
           "sender_type":"agent","message":"How can I help?",
           "attachment_path":null,"option_id":null,"flow_options":[],
           "created_at":"2026-10-07T01:00:00.000Z"}}
        ''',
      );

      expect(event, isA<ChatRealtimeMessageEvent>());
      final messageEvent = event! as ChatRealtimeMessageEvent;
      expect(messageEvent.message.id, '101');
      expect(messageEvent.message.conversationId, '12');
      expect(messageEvent.message.role, 'agent');
      expect(messageEvent.message.text, 'How can I help?');
      expect(messageEvent.message.createdAt,
          DateTime.parse('2026-10-07T01:00:00.000Z'));
    });

    test('returns no event for malformed payload without a UI stream error',
        () {
      expect(
        ChatRealtimeEventParser.parse(
          eventName: 'chat.message.created',
          data: '{"message":{"sender_type":"agent"}}',
        ),
        isNull,
      );
    });
  });

  group('SupportChatController', () {
    test(
        'auto-starts conversation on initial load if no active conversation exists',
        () async {
      final noConversation = const ChatConversationModel(
        id: null,
        status: ChatConversationStatus.unknown,
        message: null,
      );
      final repository = _FakeChatRepository(noConversation);
      final controller = await _controller(repository);

      expect(repository.startCount, 1);
      expect(controller.state.status, ChatConversationStatus.chatFlow);
      expect(controller.state.conversationId, '100');
      expect(controller.state.flowMessage, 'Welcome to Support!');
      expect(
        controller.state.options.map((o) => o.label),
        ['Personal', 'Business'],
      );
    });

    test('does not start a conversation when the current request fails',
        () async {
      final repository = _FakeChatRepository(
        _conversation(ChatConversationStatus.unknown),
      );
      repository.onFetchCurrent = () async {
        throw const ApiException(ApiFailure.unknown);
      };
      final controller = await _controller(repository);

      expect(repository.startCount, 0);
      expect(controller.state.errorMessage, 'api.unknown');
    });

    test('finishes loading while Reverb subscription is still pending',
        () async {
      final subscription = Completer<void>();
      final realtime = _FakeRealtimeClient()
        ..onSubscribeConversation = (_) => subscription.future;
      final controller = SupportChatController(
        _FakeChatRepository(
          _conversation(
            ChatConversationStatus.open,
            messages: [
              _message(
                id: '1',
                text: 'Existing reply',
                role: 'agent',
                time: '2026-10-07T01:00:00.000Z',
              ),
            ],
          ),
        ),
        realtime,
      );
      addTearDown(controller.dispose);

      await controller.loadCurrentConversation();

      expect(controller.state.isLoading, isFalse);
      expect(controller.state.messages, isNotEmpty);
      expect(controller.state.errorMessage, isNull);

      subscription.complete();
    });

    test('finishes loading while stale Reverb unsubscribe is still pending',
        () async {
      final noConversation = const ChatConversationModel(
        id: null,
        status: ChatConversationStatus.unknown,
        message: null,
      );
      final repository = _FakeChatRepository(
        _conversation(ChatConversationStatus.open),
      );
      final unsubscribe = Completer<void>();
      final realtime = _FakeRealtimeClient()
        ..onUnsubscribeConversation = (_) => unsubscribe.future;
      final controller = await _controller(repository, realtime: realtime);
      repository.current = noConversation;

      await controller.loadCurrentConversation();

      expect(controller.state.isLoading, isFalse);
      expect(controller.state.isChatFlow, isTrue);
      expect(controller.state.errorMessage, isNull);

      unsubscribe.complete();
    });

    test('shows the current-conversation failure without starting a new chat',
        () async {
      final repository = _FakeChatRepository(
        _conversation(ChatConversationStatus.unknown),
      );
      repository.onFetchCurrent = () async {
        throw const ApiException(ApiFailure.unknown);
      };
      final controller = await _controller(repository);

      expect(controller.state.errorMessage, 'api.unknown');
      expect(repository.startCount, 0);
      expect(controller.state.isLoading, isFalse);
    });

    test(
        'tapping Start New Conversation creates a new conversation and replaces active state',
        () async {
      final closedConversation = _conversation(
        ChatConversationStatus.closed,
        messages: [
          _message(
            id: '1',
            text: 'Old chat msg',
            role: 'customer',
            time: '2026-10-07T01:00:00.000Z',
          )
        ],
      );
      final repository = _FakeChatRepository(closedConversation);
      final controller = await _controller(repository);

      expect(controller.state.isClosed, isTrue);
      expect(controller.state.messages, hasLength(1));

      await controller.startConversation();

      expect(repository.startCount, 1);
      expect(controller.state.isChatFlow, isTrue);
      expect(controller.state.conversationId, '100');
      expect(controller.state.messages.map((message) => message.text), [
        'Old chat msg',
        'Welcome to Support!',
      ]);
      expect(controller.state.flowMessage, 'Welcome to Support!');
    });

    test(
        'rebuilding or re-querying active state does not create duplicate conversations',
        () async {
      final repo = _FakeChatRepository(
        const ChatConversationModel(
          id: '12',
          status: ChatConversationStatus.chatFlow,
          message: 'Active flow',
        ),
      );
      final controller = await _controller(repo);
      expect(repo.startCount, 0);

      await controller.loadCurrentConversation();
      expect(repo.startCount, 0);
    });

    test('keeps active flow options when current refresh omits them', () async {
      final repo = _FakeChatRepository(
        _conversation(
          ChatConversationStatus.chatFlow,
          options: const [
            ChatFlowOption(id: '4', label: 'Personal'),
            ChatFlowOption(id: '5', label: 'Business'),
          ],
        ),
      );
      final controller = await _controller(repo);
      repo.current = const ChatConversationModel(
        id: '12',
        status: ChatConversationStatus.chatFlow,
        message: 'Active step',
      );

      await controller.loadCurrentConversation();

      expect(repo.lastRefreshConversationId, '12');
      expect(
        controller.state.options.map((option) => option.label),
        ['Personal', 'Business'],
      );
    });

    test('restores current options from persisted matching flow history',
        () async {
      final repository = _FakeChatRepository(
        ChatConversationModel(
          id: '12',
          status: ChatConversationStatus.chatFlow,
          message: 'Active step',
          messages: [
            _message(
              id: '22',
              text: 'Active step',
              role: 'system',
              time: '2026-10-07T01:00:00.000Z',
              flowOptions: const [
                ChatFlowOption(id: '4', label: 'Personal'),
                ChatFlowOption(id: '5', label: 'Business'),
              ],
            ),
          ],
        ),
      );
      final controller = await _controller(repository);

      expect(
        controller.state.options.map((option) => option.label),
        ['Personal', 'Business'],
      );
    });

    test('retains the latest flow options as read-only history after flow mode',
        () async {
      const options = [
        ChatFlowOption(id: '4', label: 'Personal'),
        ChatFlowOption(id: '5', label: 'Business'),
      ];
      final repository = _FakeChatRepository(
        _conversation(
          ChatConversationStatus.waiting,
          messages: [
            _message(
              id: '22',
              text: 'You are now waiting for an agent.',
              role: 'system',
              time: '2026-10-07T01:00:00.000Z',
              flowOptions: options,
            ),
          ],
        ),
      );
      final controller = await _controller(repository);

      expect(
        controller.state.messages.single.flowOptions
            .map((option) => option.label),
        ['Personal', 'Business'],
      );
    });

    test('retains each flow selection and bot step from the server response',
        () async {
      final repository = _FakeChatRepository(
        _conversation(
          ChatConversationStatus.chatFlow,
          messages: [
            _message(
              id: '1',
              text: 'How can we help?',
              role: 'system',
              time: '2026-10-07T01:00:00.000Z',
            ),
          ],
          options: const [
            ChatFlowOption(id: '4', label: 'Personal'),
            ChatFlowOption(id: '5', label: 'Business'),
          ],
        ),
      );
      repository.onSelectOption = (_) async => _conversation(
            ChatConversationStatus.chatFlow,
            messages: [
              _message(
                id: '1',
                text: 'How can we help?',
                role: 'system',
                time: '2026-10-07T01:00:00.000Z',
              ),
              _message(
                id: '2',
                text: 'Internet',
                role: 'customer',
                time: '2026-10-07T01:01:00.000Z',
                flowOptions: const [
                  ChatFlowOption(id: '4', label: 'Personal'),
                  ChatFlowOption(id: '5', label: 'Business'),
                ],
              ),
              _message(
                id: '3',
                text: 'Tell us your issue.',
                role: 'system',
                time: '2026-10-07T01:02:00.000Z',
              ),
            ],
            options: const [
              ChatFlowOption(id: '6', label: 'More options'),
            ],
          );
      final controller = await _controller(repository);

      await controller.selectOption('4');

      expect(repository.lastOptionConversationId, '12');
      expect(repository.lastOptionId, '4');
      expect(controller.state.messages.map((message) => message.text), [
        'How can we help?',
        'Internet',
        'Tell us your issue.',
      ]);
      expect(
        controller.state.messages[1].flowOptions.map((option) => option.label),
        ['Personal', 'Business'],
      );
      expect(
        controller.state.options.map((option) => option.label),
        ['More options'],
      );
    });

    test('returns to main menu and merges persisted history without duplicates',
        () async {
      const staleOptions = [ChatFlowOption(id: '8', label: 'Nested option')];
      const mainMenuOptions = [ChatFlowOption(id: '4', label: 'Internet')];
      final firstMessage = _message(
        id: '1',
        text: 'How can we help?',
        role: 'system',
        time: '2026-10-07T01:00:00.000Z',
      );
      final nestedMessage = _message(
        id: '2',
        text: 'Tell us your issue.',
        role: 'system',
        time: '2026-10-07T01:01:00.000Z',
        flowOptions: staleOptions,
      );
      final repository = _FakeChatRepository(
        _conversation(
          ChatConversationStatus.chatFlow,
          message: 'Tell us your issue.',
          messages: [firstMessage, nestedMessage],
          options: staleOptions,
        ),
      );
      repository.current = _conversation(
        ChatConversationStatus.chatFlow,
        message: 'How can we help?',
        messages: [firstMessage, nestedMessage],
        options: mainMenuOptions,
      );
      final navigationResult = Completer<ChatConversationModel>();
      repository.onNavigateToMainMenu = (_, __) => navigationResult.future;
      final controller = await _controller(repository);

      final navigation = controller.navigateToMainMenu(language: 'my');
      expect(controller.state.isNavigatingToMainMenu, isTrue);
      expect(await controller.navigateToMainMenu(language: 'my'), isFalse);
      expect(repository.navigateCount, 1);

      navigationResult.complete(repository.current);
      expect(await navigation, isTrue);

      expect(repository.navigateCount, 1);
      expect(repository.lastNavigateConversationId, '12');
      expect(repository.lastNavigateLanguage, 'my');
      expect(controller.state.flowMessage, 'How can we help?');
      expect(controller.state.options, mainMenuOptions);
      expect(
          controller.state.messages.map((message) => message.id), ['1', '2']);
      expect(controller.state.messages.map((message) => message.text), [
        'How can we help?',
        'Tell us your issue.',
      ]);
      expect(controller.state.isNavigatingToMainMenu, isFalse);
      expect(controller.state.errorMessage, isNull);

      await controller.loadCurrentConversation(language: 'my');
      expect(
          controller.state.messages.map((message) => message.id), ['1', '2']);
      expect(controller.state.options, mainMenuOptions);
    });

    test(
        'preserves chat state and shows an error when main-menu navigation fails',
        () async {
      final repository = _FakeChatRepository(
        _conversation(
          ChatConversationStatus.chatFlow,
          message: 'Nested step',
          options: const [ChatFlowOption(id: '8', label: 'Nested option')],
        ),
      )..onNavigateToMainMenu = (_, __) async {
          throw const ApiException(ApiFailure.offline);
        };
      final controller = await _controller(repository);

      expect(await controller.navigateToMainMenu(), isFalse);
      expect(controller.state.flowMessage, 'Nested step');
      expect(controller.state.options.single.label, 'Nested option');
      expect(controller.state.isNavigatingToMainMenu, isFalse);
      expect(controller.state.errorMessage, 'api.offline');
    });

    test('hides options after a non-step action response', () async {
      const options = [
        ChatFlowOption(id: '4', label: 'Personal'),
        ChatFlowOption(id: '5', label: 'Business'),
      ];
      final repository = _FakeChatRepository(
        _conversation(
          ChatConversationStatus.chatFlow,
          messages: [
            _message(
              id: '1',
              text: 'Choose a category.',
              role: 'system',
              time: '2026-10-07T01:00:00.000Z',
              flowOptions: options,
            ),
          ],
          options: options,
        ),
      );
      repository.selectAction = ChatFlowOptionAction.replyText;
      repository.onSelectOption = (_) async => _conversation(
            ChatConversationStatus.chatFlow,
            message: 'Here is the requested information.',
            options: options,
          );
      final controller = await _controller(repository);

      await controller.selectOption('4');

      expect(controller.state.options, isEmpty);
      expect(controller.state.messages[0].flowOptions, isNotEmpty);
      expect(controller.state.messages.last.text,
          'Here is the requested information.');
      expect(controller.state.messages.last.flowOptions, isEmpty);
    });

    test('keeps the current step and hides URL-action replies', () async {
      const options = [
        ChatFlowOption(id: '4', label: 'View details'),
        ChatFlowOption(id: '5', label: 'Continue'),
      ];
      final repository = _FakeChatRepository(
        _conversation(
          ChatConversationStatus.chatFlow,
          message: 'Choose an option.',
          messages: [
            _message(
              id: '1',
              text: 'Choose an option.',
              role: 'system',
              time: '2026-10-07T01:00:00.000Z',
              flowOptions: options,
            ),
          ],
          options: options,
        ),
      )
        ..selectAction = ChatFlowOptionAction.goToUrl
        ..selectUrl = 'https://example.test/details';
      repository.onSelectOption = (_) async => _conversation(
            ChatConversationStatus.waiting,
            message: 'A reply that should not be shown.',
            messages: [
              _message(
                id: '1',
                text: 'Choose an option.',
                role: 'system',
                time: '2026-10-07T01:00:00.000Z',
              ),
              _message(
                id: '2',
                text: 'View details',
                role: 'customer',
                time: '2026-10-07T01:01:00.000Z',
              ),
              _message(
                id: '3',
                text: 'A reply that should not be shown.',
                role: 'system',
                time: '2026-10-07T01:02:00.000Z',
              ),
            ],
            options: const [
              ChatFlowOption(id: '6', label: 'A different step'),
            ],
          );
      final controller = await _controller(repository);

      final result = await controller.selectOption('4');

      expect(result?.action, ChatFlowOptionAction.goToUrl);
      expect(result?.url, 'https://example.test/details');
      expect(controller.state.status, ChatConversationStatus.chatFlow);
      expect(controller.state.flowMessage, 'Choose an option.');
      expect(controller.state.options.map((option) => option.label), [
        'View details',
        'Continue',
      ]);
      expect(controller.state.messages.map((message) => message.text), [
        'Choose an option.',
        'View details',
      ]);
      expect(controller.state.messages.first.flowOptions, options);
      expect(controller.state.isSubmittingOption, isFalse);
    });

    test('adds the persisted server message only after successful send',
        () async {
      final persisted = _message(
        id: '73',
        text: 'Persisted message',
        role: 'customer',
        time: '2026-10-07T01:00:00.000Z',
      );
      final repository = _FakeChatRepository(
        _conversation(ChatConversationStatus.open),
        onSendMessage: (_) async => persisted,
      );
      final controller = await _controller(repository);

      expect(await controller.sendText('  Hello  '), isTrue);
      expect(repository.sendCount, 1);
      expect(repository.lastText, 'Hello');
      expect(repository.lastConversationId, '12');
      expect(repository.lastClientMessageId, isNotEmpty);
      expect(controller.state.messages, hasLength(1));
      expect(controller.state.messages.single.id, '73');
      expect(controller.state.messages.single.text, 'Persisted message');
      expect(controller.state.messages.single.isMine, isTrue);
      expect(controller.state.messages.single.sentAt, persisted.createdAt);
      expect(controller.state.isSendingMessage, isFalse);
    });

    test('retains no optimistic message after a failed send', () async {
      final repository = _FakeChatRepository(
        _conversation(ChatConversationStatus.open),
        onSendMessage: (_) async {
          throw const ApiException(ApiFailure.offline);
        },
      );
      final controller = await _controller(repository);

      expect(await controller.sendText('Hello'), isFalse);
      expect(controller.state.messages, isEmpty);
      expect(controller.state.errorMessage, 'api.offline');
      expect(controller.state.isSendingMessage, isFalse);
    });

    test('does not send an empty message', () async {
      final repository = _FakeChatRepository(
        _conversation(ChatConversationStatus.open),
      );
      final controller = await _controller(repository);

      expect(await controller.sendText(' \n '), isFalse);
      expect(repository.sendCount, 0);
      expect(controller.state.messages, isEmpty);
    });

    test('disables sending outside OPEN state', () async {
      for (final status in [
        ChatConversationStatus.chatFlow,
        ChatConversationStatus.waiting,
        ChatConversationStatus.closed,
        ChatConversationStatus.unknown,
      ]) {
        final repository = _FakeChatRepository(_conversation(status));
        final controller = await _controller(repository);

        expect(await controller.sendText('Hello'), isFalse, reason: '$status');
        expect(repository.sendCount, 0, reason: '$status');
      }
    });

    test('shows a sending state and rejects a concurrent duplicate', () async {
      final pending = Completer<ChatMessageModel>();
      final repository = _FakeChatRepository(
        _conversation(ChatConversationStatus.open),
        onSendMessage: (_) => pending.future,
      );
      final controller = await _controller(repository);

      final sending = controller.sendText('Hello');
      expect(controller.state.isSendingMessage, isTrue);
      expect(controller.state.composerEnabled, isFalse);
      expect(await controller.sendText('Hello'), isFalse);
      expect(repository.sendCount, 1);

      pending.complete(_message(
        id: '74',
        text: 'Hello',
        role: 'customer',
        time: '2026-10-07T01:00:00.000Z',
      ));
      expect(await sending, isTrue);
      expect(controller.state.isSendingMessage, isFalse);
    });

    test('ignores repeated server message IDs when refreshing history',
        () async {
      final conversation = _conversation(
        ChatConversationStatus.open,
        messages: [
          _message(
            id: '8',
            text: 'First',
            role: 'customer',
            time: '2026-10-07T01:00:00.000Z',
          ),
          _message(
            id: '8',
            text: 'Duplicate',
            role: 'customer',
            time: '2026-10-07T01:00:00.000Z',
          ),
          _message(
            id: '9',
            text: 'Next',
            role: 'agent',
            time: '2026-10-07T01:01:00.000Z',
          ),
        ],
      );
      final repository = _FakeChatRepository(conversation);
      final controller = await _controller(repository);

      await controller.loadCurrentConversation();

      expect(
          controller.state.messages.map((message) => message.id), ['8', '9']);
      expect(controller.state.messages.first.text, 'First');
    });

    test('appends realtime messages and ignores duplicate server IDs',
        () async {
      final realtime = _FakeRealtimeClient();
      final controller = await _controller(
        _FakeChatRepository(_conversation(ChatConversationStatus.open)),
        realtime: realtime,
      );

      realtime.addMessage(_message(
        id: '100',
        text: 'Admin response',
        role: 'agent',
        time: '2026-10-07T01:00:00.000Z',
      ));
      realtime.addMessage(_message(
        id: '100',
        text: 'Duplicate',
        role: 'agent',
        time: '2026-10-07T01:00:00.000Z',
      ));

      expect(controller.state.messages, hasLength(1));
      expect(controller.state.messages.single.text, 'Admin response');
      expect(controller.state.messages.single.isMine, isFalse);
    });

    test('applies status events only to the active conversation', () async {
      final repository = _FakeChatRepository(
        _conversation(
          ChatConversationStatus.waiting,
          options: const [ChatFlowOption(id: '1', label: 'Old option')],
        ),
      );
      final realtime = _FakeRealtimeClient();
      final controller = await _controller(repository, realtime: realtime);

      realtime.addEvent(const ChatRealtimeConversationEvent(
        conversationId: 'another-conversation',
        status: ChatConversationStatus.open,
      ));
      realtime.addEvent(const ChatRealtimeConversationEvent(
        conversationId: '12',
        status: ChatConversationStatus.closed,
      ));

      expect(controller.state.status, ChatConversationStatus.closed);
      expect(controller.state.options, isEmpty);
    });

    test('increments reconnect revision after a dropped connection recovers',
        () async {
      final repository =
          _FakeChatRepository(_conversation(ChatConversationStatus.open));
      final realtime = _FakeRealtimeClient();
      final controller = await _controller(repository, realtime: realtime);

      realtime.addConnectionState(ChatRealtimeConnectionState.connected);
      realtime.addConnectionState(ChatRealtimeConnectionState.disconnected);
      realtime.addConnectionState(ChatRealtimeConnectionState.connected);

      expect(controller.state.realtimeReconnectRevision, 1);
    });

    test('refreshes the transcript and options after a stale option response',
        () async {
      final repository = _FakeChatRepository(
        _conversation(ChatConversationStatus.chatFlow),
      );
      repository.onSelectOption = (_) async {
        throw const ApiException(
          ApiFailure.unknown,
          responseData: {'code': 'stale_chat_option'},
        );
      };
      repository.onFetchCurrent = () async => _conversation(
            ChatConversationStatus.chatFlow,
            messages: [
              _message(
                id: '3',
                text: 'Latest step',
                role: 'system',
                time: '2026-10-07T01:00:00.000Z',
              ),
            ],
          );
      final controller = await _controller(repository);

      await controller.selectOption('4');

      expect(repository.lastRefreshConversationId, '12');
      expect(controller.state.messages.single.text, 'Latest step');
      expect(controller.state.errorMessage, 'support.option_expired');
    });

    test('refreshes and shows CLOSED when Laravel rejects a closed chat',
        () async {
      final repository = _FakeChatRepository(
        _conversation(ChatConversationStatus.open),
      );
      final controller = await _controller(repository);
      repository.current = _conversation(ChatConversationStatus.closed);

      expect(await controller.sendText('Hello'), isFalse);
      expect(repository.lastRefreshConversationId, '12');
      expect(controller.state.isClosed, isTrue);
      expect(controller.state.messages, isEmpty);
      expect(controller.state.isSendingMessage, isFalse);
    });
  });
}

Future<ApiException> _sendFailure(Dio dio) async {
  try {
    await ChatRepository(dio).sendMessage(
      conversationId: '12',
      text: 'Hello',
      clientMessageId: 'client-1',
    );
  } on ApiException catch (error) {
    return error;
  }
  throw StateError('Expected the Laravel request to fail.');
}

ChatConversationModel _conversation(
  ChatConversationStatus status, {
  String? message,
  List<ChatMessageModel> messages = const [],
  List<ChatFlowOption> options = const [],
}) {
  return ChatConversationModel(
    id: '12',
    status: status,
    message: message,
    messages: messages,
    options: options,
  );
}

ChatMessageModel _message({
  required String id,
  required String text,
  required String role,
  required String time,
  String conversationId = '12',
  List<ChatFlowOption> flowOptions = const [],
}) {
  return ChatMessageModel(
    id: id,
    text: text,
    role: role,
    createdAt: DateTime.parse(time),
    conversationId: conversationId,
    flowOptions: flowOptions,
  );
}

Future<SupportChatController> _controller(
  _FakeChatRepository repository, {
  _FakeRealtimeClient? realtime,
}) async {
  final controller = SupportChatController(
    repository,
    realtime ?? _FakeRealtimeClient(),
  );
  addTearDown(controller.dispose);
  await controller.loadCurrentConversation();
  await Future<void>.delayed(Duration.zero);
  return controller;
}

class _FakeChatRepository extends ChatRepository {
  _FakeChatRepository(
    this.current, {
    this.onSendMessage,
  }) : super(Dio());

  ChatConversationModel current;
  final Future<ChatMessageModel> Function(String text)? onSendMessage;
  Future<ChatConversationModel> Function()? onStartConversation;
  Future<ChatConversationModel> Function(String optionId)? onSelectOption;
  Future<ChatConversationModel> Function()? onFetchCurrent;
  Future<ChatConversationModel> Function(
    String conversationId,
    String language,
  )? onNavigateToMainMenu;
  ChatFlowOptionAction? selectAction = ChatFlowOptionAction.goToStep;

  int sendCount = 0;
  int startCount = 0;
  int selectCount = 0;
  int navigateCount = 0;
  String? lastText;
  String? lastConversationId;
  String? lastClientMessageId;
  String? lastRefreshConversationId;
  String? lastOptionConversationId;
  String? lastOptionId;
  String? lastNavigateConversationId;
  String? lastNavigateLanguage;
  String? selectUrl;

  @override
  Future<ChatConversationModel> fetchCurrentConversation({
    String? conversationId,
    String language = 'en',
  }) async {
    lastRefreshConversationId = conversationId;
    if (onFetchCurrent != null) {
      return onFetchCurrent!();
    }
    return current;
  }

  @override
  Future<ChatConversationModel> startConversation({
    String language = 'en',
  }) async {
    startCount++;
    if (onStartConversation != null) {
      return onStartConversation!();
    }
    return ChatConversationModel(
      id: '100',
      status: ChatConversationStatus.chatFlow,
      message: 'Welcome to Support!',
      messages: [
        ChatMessageModel(
          id: '101',
          conversationId: '100',
          text: 'Welcome to Support!',
          role: 'system',
          createdAt: DateTime.parse('2026-10-07T01:00:00.000Z'),
        ),
      ],
      options: [
        const ChatFlowOption(id: '1', label: 'Personal'),
        const ChatFlowOption(id: '2', label: 'Business'),
      ],
    );
  }

  @override
  Future<ChatOptionSelectionResult> selectOption({
    required String conversationId,
    required String optionId,
    String language = 'en',
  }) async {
    selectCount++;
    lastOptionConversationId = conversationId;
    lastOptionId = optionId;
    final selectedConversation = onSelectOption != null
        ? await onSelectOption!(optionId)
        : ChatConversationModel(
            id: '100',
            status: ChatConversationStatus.chatFlow,
            message: 'Selected: $optionId',
            options: const [ChatFlowOption(id: '3', label: 'More options')],
          );
    return ChatOptionSelectionResult(
      conversation: selectedConversation,
      action: selectAction,
      url: selectUrl,
    );
  }

  @override
  Future<ChatConversationModel> navigateToMainMenu({
    required String conversationId,
    String language = 'en',
  }) async {
    navigateCount++;
    lastNavigateConversationId = conversationId;
    lastNavigateLanguage = language;
    return onNavigateToMainMenu?.call(conversationId, language) ?? current;
  }

  @override
  Future<ChatMessageModel> sendMessage({
    required String conversationId,
    required String text,
    required String clientMessageId,
  }) async {
    sendCount++;
    lastConversationId = conversationId;
    lastText = text;
    lastClientMessageId = clientMessageId;
    return onSendMessage?.call(text) ??
        _message(
          id: '1',
          text: text,
          role: 'customer',
          time: '2026-10-07T01:00:00.000Z',
        );
  }
}

class _FakeRealtimeClient implements ChatRealtimeClient {
  final StreamController<ChatRealtimeEvent> _events =
      StreamController<ChatRealtimeEvent>.broadcast(sync: true);
  final StreamController<ChatRealtimeConnectionState> _connectionStates =
      StreamController<ChatRealtimeConnectionState>.broadcast(sync: true);

  @override
  Stream<ChatRealtimeEvent> get events => _events.stream;

  @override
  Stream<ChatRealtimeConnectionState> get connectionStates =>
      _connectionStates.stream;

  Future<void> Function(String conversationId)? onSubscribeConversation;
  Future<void> Function(String conversationId)? onUnsubscribeConversation;

  @override
  Future<void> subscribeConversation(String conversationId) async {
    await onSubscribeConversation?.call(conversationId);
  }

  @override
  Future<void> unsubscribeConversation(String conversationId) async {
    await onUnsubscribeConversation?.call(conversationId);
  }

  void addMessage(ChatMessageModel message) {
    _events.add(ChatRealtimeMessageEvent(message));
  }

  void addEvent(ChatRealtimeEvent event) {
    _events.add(event);
  }

  void addConnectionState(ChatRealtimeConnectionState state) {
    _connectionStates.add(state);
  }
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
