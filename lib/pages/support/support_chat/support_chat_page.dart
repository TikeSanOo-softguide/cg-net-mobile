import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../components/app_curved_scaffold/app_curved_scaffold.dart';
import '../../../core/router/route_names/route_names.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import '../../../core/theme/app_style/app_style.dart';
import '../../../core/theme/app_theme/app_theme.dart';
import '../../../data/chat/chat_repository.dart';
import 'support_chat_controller.dart';

class SupportChatPage extends ConsumerStatefulWidget {
  const SupportChatPage({super.key});

  @override
  ConsumerState<SupportChatPage> createState() => _SupportChatPageState();
}

class _SupportChatPageState extends ConsumerState<SupportChatPage>
    with WidgetsBindingObserver {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _inputFocus = FocusNode();
  bool _hasInitializedChat = false;
  String? _pendingFileName;
  String? _localeCode;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    debugPrint('[ChatPage] initState entered');
    _inputFocus.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(ref.read(supportChatControllerProvider.notifier).leaveChat());
    _input.dispose();
    _scroll.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Do not reload the conversation when returning from an external URL.
      // Keep the current flow step and its options unchanged.
      if (kDebugMode) {
        debugPrint(
          '[ChatPage] App resumed; keeping the current chat state.',
        );
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final localeCode = context.locale.languageCode;

    // Initialize the chat only once.
    // Changing the app language must not reload the current step.
    if (_hasInitializedChat) {
      _localeCode = localeCode;
      return;
    }

    _hasInitializedChat = true;
    _localeCode = localeCode;

    if (kDebugMode) {
      debugPrint('[Chat] screen initialization started');
    }

    // Wait until the widget tree has finished building before
    // modifying the Riverpod provider.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      unawaited(
        ref
            .read(supportChatControllerProvider.notifier)
            .loadCurrentConversation(language: localeCode),
      );
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _onSendText() async {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    final state = ref.read(supportChatControllerProvider);
    if (!state.composerEnabled) return;
    final sent =
        await ref.read(supportChatControllerProvider.notifier).sendText(
              text,
              language: context.locale.languageCode,
            );
    if (!mounted || !sent) return;
    _input.clear();
    _scrollToBottom();
  }

  Future<void> _onSelectOption(String optionId) async {
    final result =
        await ref.read(supportChatControllerProvider.notifier).selectOption(
              optionId,
              language: context.locale.languageCode,
            );
    if (!mounted ||
        result == null ||
        result.action != ChatFlowOptionAction.goToUrl) {
      return;
    }

    await _openFlowUrl(result.url);
  }

  Future<void> _openFlowUrl(String? value) async {
    final target = value?.trim() ?? '';
    final uri = target.isEmpty ? null : Uri.tryParse(target);
    if (uri == null) {
      _showFlowUrlError('Invalid Chat Flow URL: $value');
      return;
    }

    if (uri.scheme.isEmpty &&
        uri.authority.isEmpty &&
        uri.path.startsWith('/')) {
      context.go(uri.toString());
      return;
    }

    if ((uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty) {
      try {
        if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          return;
        }
      } catch (error) {
        _showFlowUrlError('Could not open Chat Flow URL: $error');
        return;
      }
      _showFlowUrlError('No handler could open Chat Flow URL: $target');
      return;
    }

    _showFlowUrlError('Unsupported Chat Flow URL: $target');
  }

  void _showFlowUrlError(String diagnostic) {
    if (kDebugMode) {
      debugPrint('[Chat Flow] $diagnostic');
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('api.unknown'.tr()),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatTime(DateTime time) {
    final datetime = time.toUtc().add(
          const Duration(hours: 6, minutes: 30),
        );

    return DateFormat('dd/MM/yy, h:mma').format(datetime);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(
      supportChatControllerProvider.select((state) => state.messages.length),
      (previous, next) {
        if (previous == null || next > previous) _scrollToBottom();
      },
    );
    ref.listen(
      supportChatControllerProvider
          .select((state) => state.realtimeReconnectRevision),
      (previous, next) {
        if (previous != null && next > previous) {
          unawaited(
            ref
                .read(supportChatControllerProvider.notifier)
                .loadCurrentConversation(
                  language: context.locale.languageCode,
                ),
          );
        }
      },
    );
    final state = ref.watch(supportChatControllerProvider);
    final inputFocused = _inputFocus.hasFocus;
    final hasExistingChat = state.hasConversation ||
        state.messages.isNotEmpty ||
        state.flowMessage != null;

    return AppCurvedScaffold(
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('support.chat_title'.tr()),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const DecoratedBox(
                decoration: BoxDecoration(
                  color: Color(0xFF35D07F),
                  shape: BoxShape.circle,
                ),
                child: SizedBox(width: 8, height: 8),
              ),
              const SizedBox(width: 6),
              Text(
                'support.online_status'.tr(),
                style: AppTheme.caption(color: AppColors.onPrimary),
              ),
            ],
          ),
        ],
      ),
      topBarContentHeight: 48,
      showBack: true,
      onBack: () => context.goNamed(RouteNames.home),
      body: ColoredBox(
        color: AppColors.background,
        child: (state.isLoading || state.isStartingChat) && !hasExistingChat
            ? const Center(child: CircularProgressIndicator())
            : _buildBody(state, inputFocused),
      ),
    );
  }

  Widget _buildBody(SupportChatState state, bool inputFocused) {
    if (state.isChatFlow) {
      return Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: TextButton.icon(
                onPressed: state.isLoading ||
                        state.isSubmittingOption ||
                        state.isNavigatingToMainMenu
                    ? null
                    : () async {
                        final navigated = await ref
                            .read(supportChatControllerProvider.notifier)
                            .navigateToMainMenu(
                              language: context.locale.languageCode,
                            );
                        if (mounted && navigated) _scrollToBottom();
                      },
                icon: state.isNavigatingToMainMenu
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(LucideIcons.house, size: 16),
                label: Text('support.main_menu'.tr()),
              ),
            ),
          ),
          Expanded(
            child: _buildHistoryList(state, showCurrentOptions: true),
          ),
        ],
      );
    }

    if (state.isWaiting) {
      return Column(
        children: [
          Expanded(child: _buildHistoryList(state)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.access_time_outlined,
                  size: 20,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'support.waiting_for_admin'.tr(),
                    style: AppTheme.bodySecondary(),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          if (state.errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                state.errorMessage!.tr(),
                style: AppTheme.bodySecondary(color: AppColors.error),
              ),
            ),
        ],
      );
    }

    if (state.isClosed) {
      return Column(
        children: [
          Expanded(child: _buildHistoryList(state)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.borderLight.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        LucideIcons.lock,
                        size: 14,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'support.conversation_closed'.tr(),
                        style: AppTheme.captionSm(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                if (state.errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    state.errorMessage!.tr(),
                    textAlign: TextAlign.center,
                    style: AppTheme.bodySecondary(color: AppColors.error),
                  ),
                ],
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: state.isStartingChat
                      ? null
                      : () => ref
                          .read(supportChatControllerProvider.notifier)
                          .startConversation(
                            language: context.locale.languageCode,
                          ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    state.isStartingChat
                        ? 'support.starting_conversation'.tr()
                        : 'support.start_new_conversation'.tr(),
                    style: AppTheme.body(color: AppColors.onPrimary),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (state.isOpen) {
      return Column(
        children: [
          Expanded(child: _buildHistoryList(state)),
          if (state.errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                state.errorMessage!.tr(),
                style: AppTheme.bodySecondary(color: AppColors.error),
              ),
            ),
          SafeArea(
            top: false,
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_pendingFileName != null) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.paperclip,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _pendingFileName!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.english(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () =>
                                setState(() => _pendingFileName = null),
                            borderRadius: BorderRadius.circular(8),
                            splashColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(
                                LucideIcons.x,
                                size: 14,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          curve: Curves.easeOut,
                          constraints: const BoxConstraints(
                            minHeight: 44,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: AppStyle.borderRadiusInput,
                            border: Border.all(
                              color: inputFocused
                                  ? AppColors.primary
                                  : AppColors.paperBorder,
                              width: inputFocused ? 1.4 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: inputFocused
                                    ? AppColors.primary.withValues(alpha: 0.10)
                                    : Colors.black.withValues(alpha: 0.04),
                                blurRadius: inputFocused ? 10 : 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.only(left: 4, right: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: TextField(
                                  enabled: !state.isSendingMessage,
                                  controller: _input,
                                  focusNode: _inputFocus,
                                  minLines: 1,
                                  maxLines: 4,
                                  textInputAction: TextInputAction.send,
                                  onSubmitted: (_) => _onSendText(),
                                  cursorColor: AppColors.primary,
                                  style: AppTheme.body(),
                                  decoration: InputDecoration(
                                    hintText: 'support.type_message'.tr(),
                                    hintStyle: AppTheme.bodySecondary(),
                                    isDense: true,
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: state.composerEnabled ? _onSendText : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          curve: Curves.easeOut,
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            borderRadius: AppStyle.borderRadiusInput,
                            color: state.composerEnabled
                                ? AppColors.primary
                                : AppColors.textMuted,
                            boxShadow: [
                              BoxShadow(
                                color:
                                    AppColors.primary.withValues(alpha: 0.22),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: state.isSendingMessage
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.onPrimary,
                                  ),
                                )
                              : const Icon(
                                  LucideIcons.send,
                                  size: 16,
                                  color: AppColors.onPrimary,
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (state.errorMessage != null) ...[
              const Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: 12),
              Text(
                state.errorMessage!.tr(),
                textAlign: TextAlign.center,
                style: AppTheme.bodySecondary(color: AppColors.error),
              ),
              const SizedBox(height: 16),
            ],
            ElevatedButton(
              onPressed: () => ref
                  .read(supportChatControllerProvider.notifier)
                  .loadCurrentConversation(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'common.retry'.tr(),
                style: AppTheme.body(color: AppColors.onPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList(
    SupportChatState state, {
    bool showCurrentOptions = false,
  }) {
    final activeOptions =
        showCurrentOptions ? state.options : const <ChatFlowOption>[];
    final hasActiveOptions = activeOptions.isNotEmpty ||
        (showCurrentOptions &&
            (state.isSubmittingOption || state.errorMessage != null));

    final lastMsg = state.messages.isNotEmpty ? state.messages.last : null;
    final lastIsBot = lastMsg != null && !lastMsg.isMine;
    final lastMatchesFlowPrompt = lastIsBot &&
        state.flowMessage != null &&
        state.flowMessage!.trim() == lastMsg.text.trim();

    final attachOptionsToLastMsg = hasActiveOptions &&
        lastIsBot &&
        (lastMatchesFlowPrompt || state.flowMessage == null);

    final itemCount = state.messages.length +
        (hasActiveOptions && !attachOptionsToLastMsg ? 1 : 0);

    if (itemCount == 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'support.empty_chat'.tr(),
            textAlign: TextAlign.center,
            style: AppTheme.bodySecondary(),
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index < state.messages.length) {
          final message = state.messages[index];
          final time = _formatTime(message.sentAt);
          final isLast = index == state.messages.length - 1;

          if (isLast && attachOptionsToLastMsg) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _BotFlowCard(
                text: message.text,
                time: time,
                options: activeOptions,
                isSubmitting: state.isSubmittingOption,
                errorMessage: state.errorMessage?.tr(),
                onSelectOption: (id) => unawaited(_onSelectOption(id)),
              ),
            );
          }

          if (!message.isMine && message.flowOptions.isNotEmpty) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _BotFlowCard(
                text: message.text,
                time: time,
                options: message.flowOptions,
                localizeOptions: false,
                isSubmitting: false,
                onSelectOption: null,
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: message.isMine
                ? _UserMessageCard(
                    text: message.text,
                    time: time,
                    fileName: message.fileName,
                  )
                : _BotMessageCard(
                    text: message.text,
                    time: time,
                  ),
          );
        }

        final promptText =
            state.flowMessage ?? 'support.select_option_prompt'.tr();
        final currentTime = _formatTime(DateTime.now());

        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: _BotFlowCard(
            text: promptText,
            time: currentTime,
            options: activeOptions,
            isSubmitting: state.isSubmittingOption,
            errorMessage: state.errorMessage?.tr(),
            onSelectOption: (id) => unawaited(_onSelectOption(id)),
          ),
        );
      },
    );
  }
}

class _SupportRobotIcon extends StatelessWidget {
  const _SupportRobotIcon({this.size = 26});

  static const asset = 'assets/images/support/robot.png';

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, __, ___) => Icon(
        LucideIcons.bot,
        size: size * 0.85,
        color: AppColors.primary,
      ),
    );
  }
}

class _BotAvatar extends StatelessWidget {
  const _BotAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const _SupportRobotIcon(size: 22),
    );
  }
}

class _BotMessageCard extends StatelessWidget {
  const _BotMessageCard({
    required this.text,
    required this.time,
  });

  final String text;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _BotAvatar(),
            const SizedBox(width: 8),
            Flexible(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderLight),
                  boxShadow: AppStyle.cardShadow,
                ),
                child: Text(
                  text,
                  style: AppTheme.body(
                    color: AppColors.textPrimary,
                    weight: FontWeight.w400,
                  ).copyWith(fontSize: 13, height: 1.4),
                ),
              ),
            ),
            const SizedBox(width: 48),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 40, bottom: 4),
          child: Row(
            children: [
              const SizedBox(width: 8),
              Text(
                time,
                style: AppTheme.captionSm(color: AppColors.textMuted).copyWith(
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BotFlowCard extends StatelessWidget {
  const _BotFlowCard({
    required this.text,
    required this.time,
    required this.options,
    this.localizeOptions = true,
    this.isSubmitting = false,
    this.errorMessage,
    this.onSelectOption,
  });

  final String text;
  final String time;
  final List<ChatFlowOption> options;
  final bool localizeOptions;
  final bool isSubmitting;
  final String? errorMessage;
  final ValueChanged<String>? onSelectOption;

  String _optionLabel(BuildContext context, ChatFlowOption option) {
    final label = localizeOptions
        ? option.labelForLocale(context.locale.languageCode)
        : option.label;
    return label.trim().isEmpty ? 'support.option'.tr() : label;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _BotAvatar(),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderLight),
                  boxShadow: AppStyle.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text,
                      style: AppTheme.body(
                        color: AppColors.textPrimary,
                        weight: FontWeight.w500,
                      ).copyWith(fontSize: 14, height: 1.4),
                    ),
                    if (options.isNotEmpty || isSubmitting) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(
                          height: 1,
                          thickness: 1,
                          color: AppColors.borderLight,
                        ),
                      ),
                      for (int i = 0; i < options.length; i++) ...[
                        if (i > 0) const SizedBox(height: 8),
                        _CGNetOptionButton(
                          label: _optionLabel(context, options[i]),
                          onPressed: isSubmitting || onSelectOption == null
                              ? null
                              : () => onSelectOption!(options[i].id),
                        ),
                      ],
                      if (isSubmitting)
                        const Padding(
                          padding: EdgeInsets.only(top: 10),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                    ],
                    if (errorMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        errorMessage!,
                        style: AppTheme.bodySecondary(color: AppColors.error),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 40, bottom: 4),
          child: Row(
            children: [
              const SizedBox(width: 8),
              Text(
                time,
                style: AppTheme.captionSm(color: AppColors.textMuted).copyWith(
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _UserMessageCard extends StatelessWidget {
  const _UserMessageCard({
    required this.text,
    required this.time,
    this.fileName,
  });

  final String text;
  final String time;
  final String? fileName;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(width: 48),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: AppStyle.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (fileName != null && fileName!.isNotEmpty) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            LucideIcons.paperclip,
                            size: 12,
                            color: AppColors.onPrimary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            fileName!,
                            style: AppTheme.bodySecondary(
                                    color: AppColors.onPrimary)
                                .copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                    ],
                    Text(
                      text,
                      style: AppTheme.body(
                        color: AppColors.onPrimary,
                        weight: FontWeight.w400,
                      ).copyWith(fontSize: 13, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                time,
                style: AppTheme.captionSm(color: AppColors.textMuted)
                    .copyWith(fontSize: 10),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CGNetOptionButton extends StatelessWidget {
  const _CGNetOptionButton({
    required this.label,
    this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          alignment: Alignment.center,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTheme.body(
            color: Colors.white,
            weight: FontWeight.w600,
          ).copyWith(fontSize: 13.5),
        ),
      ),
    );
  }
}
