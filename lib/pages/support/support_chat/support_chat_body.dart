part of 'support_chat_page.dart';

extension _SupportChatPageView on _SupportChatPageState {
  Widget _buildBody(SupportChatState state, bool inputFocused) {
    if (state.isChatFlow) {
      return Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: _MainMenuButton(
                loading: state.isNavigatingToMainMenu,
                enabled: !state.isLoading &&
                    !state.isSubmittingOption &&
                    !state.isNavigatingToMainMenu,
                onTap: () async {
                  final navigated = await ref
                      .read(supportChatControllerProvider.notifier)
                      .navigateToMainMenu(
                        language: context.locale.languageCode,
                      );
                  if (mounted && navigated) _scrollToBottom();
                },
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
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    LucideIcons.headset,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'support.waiting_for_admin'.tr(),
                    textAlign: TextAlign.center,
                    style: AppTheme.english(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                      height: AppTheme.lineHeightMyanmarSafe,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_shownChatError(state.errorMessage) != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                _shownChatError(state.errorMessage)!,
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
                if (_shownChatError(state.errorMessage) != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _shownChatError(state.errorMessage)!,
                    textAlign: TextAlign.center,
                    style: AppTheme.bodySecondary(color: AppColors.error),
                  ),
                ],
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: state.isStartingChat
                          ? null
                          : () async {
                              await ref
                                  .read(supportChatControllerProvider.notifier)
                                  .startConversation(
                                    language: context.locale.languageCode,
                                  );
                              if (mounted) _scrollToBottom(animated: false);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        disabledBackgroundColor:
                            AppColors.primary.withValues(alpha: 0.45),
                        disabledForegroundColor: AppColors.onPrimary,
                        minimumSize: const Size.fromHeight(38),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        state.isStartingChat
                            ? 'support.starting_conversation'.tr()
                            : 'support.start_new_conversation'.tr(),
                        textAlign: TextAlign.center,
                        style: AppTheme.english(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.onPrimary,
                          height: AppStyle.lineHeightCaption,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
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
          if (_shownChatError(state.errorMessage) != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                _shownChatError(state.errorMessage)!,
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
                  if (_pendingImages.isNotEmpty) ...[
                    _buildImagePreviews(),
                  ],
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          curve: Curves.easeOut,
                          constraints: const BoxConstraints(
                            minHeight: 36,
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
                          padding: const EdgeInsets.only(left: 12, right: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                onTap: state.isSendingMessage ||
                                        _isSendingPendingImages
                                    ? null
                                    : _onAttachFile,
                                child: SizedBox(
                                  width: 32,
                                  height: 36,
                                  child: Center(
                                    child: Icon(
                                      LucideIcons.paperclip,
                                      size: 18,
                                      color: state.isSendingMessage ||
                                              _isSendingPendingImages
                                          ? AppColors.textMuted
                                          : AppColors.textMuted,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: TextField(
                                  enabled: !state.isSendingMessage &&
                                      !_isSendingPendingImages,
                                  controller: _input,
                                  focusNode: _inputFocus,
                                  minLines: 1,
                                  maxLines: 4,
                                  textInputAction: TextInputAction.send,
                                  onSubmitted: (_) => _onSendText(),
                                  cursorColor: AppColors.primary,
                                  style: AppTheme.english(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.textPrimary,
                                    height: AppStyle.lineHeightBody,
                                    letterSpacing: 0,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'support.type_message'.tr(),
                                    hintStyle: AppTheme.english(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w400,
                                      color: AppColors.textMuted,
                                      height: AppStyle.lineHeightBody,
                                      letterSpacing: 0,
                                    ),
                                    isDense: true,
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    contentPadding:
                                        const EdgeInsets.symmetric(vertical: 8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: state.composerEnabled && !_isSendingPendingImages
                            ? _onSendText
                            : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          curve: Curves.easeOut,
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            borderRadius: AppStyle.borderRadiusSm,
                            color: state.isSendingMessage
                                ? AppColors.primary
                                : state.composerEnabled
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
                                  size: 14,
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

    if (isUnreachableMessage(state.errorMessage)) {
      return OfflineEmptyState(
        onRetry: () {
          armOfflineRetry(
            recovery: ref.read(networkRecoveryControllerProvider),
            key: 'support-chat-reload',
            reload: () => ref
                .read(supportChatControllerProvider.notifier)
                .loadCurrentConversation(),
            stillOffline: () => isUnreachableMessage(
              ref.read(supportChatControllerProvider).errorMessage,
            ),
          );
        },
      );
    }
    if (isServerUnavailableMessage(state.errorMessage)) {
      return ServerUnavailableEmptyState(
        recoveryKey: 'support-chat',
        onRetry: () => ref
            .read(supportChatControllerProvider.notifier)
            .loadCurrentConversation(),
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

  Widget _buildImagePreviews() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (var index = 0; index < _pendingImages.length; index++)
            _buildImagePreview(_pendingImages[index], index),
        ],
      ),
    );
  }

  Widget _buildImagePreview(PlatformFile image, int index) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.paperBorder,
            ),
            boxShadow: AppStyle.cardShadow,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Image.memory(
              image.bytes!,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: -7,
          right: -7,
          child: Material(
            color: AppColors.textPrimary,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: () {
                _update(() {
                  _pendingImages.removeAt(index);
                });
              },
              customBorder: const CircleBorder(),
              child: const SizedBox(
                width: 24,
                height: 24,
                child: Icon(
                  LucideIcons.x,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
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
    return Stack(
      children: [
        ListView.builder(
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
                    submittingOptionId: _submittingOptionId,
                    errorMessage: _shownChatError(state.errorMessage),
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
                        imageBytes: message.imageBytes,
                        imageUrl: message.imageUrl,
                      )
                    : _BotMessageCard(
                        text: message.text,
                        time: time,
                        imageUrl: message.imageUrl,
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
                submittingOptionId: _submittingOptionId,
                errorMessage: _shownChatError(state.errorMessage),
                onSelectOption: (id) => unawaited(_onSelectOption(id)),
              ),
            );
          },
        ),
        Positioned(
          right: 16,
          bottom: 12,
          child: _JumpToLatestButton(
            visible: _showJumpToLatest,
            count: _unreadCount,
            onTap: () {
              _scrollToBottom();
              _update(() => _unreadCount = 0);
            },
          ),
        ),
      ],
    );
  }
}
