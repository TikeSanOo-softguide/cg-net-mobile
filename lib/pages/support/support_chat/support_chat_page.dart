import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../components/app_curved_scaffold/app_curved_scaffold.dart';
import '../../../components/network_status_host/network_status_host.dart';
import '../../../components/app_dialog/app_dialog.dart';
import '../../../components/offline_notice_bar/offline_notice_bar.dart';
import '../../../components/page_skeletons/support_chat_skeleton.dart';
import '../../../core/network/network_recovery_controller.dart';
import '../../../core/network/offline_navigation.dart';
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
  bool _isSendingPendingImages = false;
  String? _submittingOptionId;
  final List<PlatformFile> _pendingImages = [];
  String? _localeCode;
  bool _showJumpToLatest = false;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
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
    _scroll.removeListener(_onScroll);
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

  bool get _isNearBottom {
    if (!_scroll.hasClients) return true;
    final p = _scroll.position;
    return p.maxScrollExtent - p.pixels < 80;
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;

    final near = _isNearBottom;
    final shouldShow = !near;

    if (shouldShow != _showJumpToLatest || (near && _unreadCount > 0)) {
      setState(() {
        _showJumpToLatest = shouldShow;
        if (near) _unreadCount = 0;
      });
    }
  }

  void _scrollToBottom({bool animated = true}) {
    var attempts = 0;

    void tick() {
      if (!mounted) return;

      if (!_scroll.hasClients || !_scroll.position.hasContentDimensions) {
        // ListView အသစ် မတည်ဆောက်ရသေးရင် နောက် frame မှာ ပြန်စမ်း
        if (attempts++ < 10) {
          WidgetsBinding.instance.addPostFrameCallback((_) => tick());
        }
        return;
      }

      final max = _scroll.position.maxScrollExtent;
      final atBottom = (max - _scroll.offset).abs() < 1;

      if (!atBottom) {
        if (animated && attempts == 0) {
          _scroll.animateTo(
            max,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
          );
        } else if (!animated) {
          _scroll.jumpTo(max);
        }
      }

      // extent ပြောင်းနေနိုင်လို့ frame အနည်းငယ် ထပ်စစ်
      if (!animated && attempts++ < 6) {
        WidgetsBinding.instance.addPostFrameCallback((_) => tick());
      } else if (animated) {
        // animation ပြီးရင် နောက်ဆုံး ပြင်ဆင်ချက်
        Future.delayed(const Duration(milliseconds: 400), () {
          if (!mounted || !_scroll.hasClients) return;
          final m = _scroll.position.maxScrollExtent;
          if ((_scroll.offset - m).abs() > 1) _scroll.jumpTo(m);
        });
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => tick());
  }

  Future<void> _onSendText() async {
    final text = _input.text.trim();

    if (text.isEmpty && _pendingImages.isEmpty) return;

    final state = ref.read(supportChatControllerProvider);

    if (!state.composerEnabled ||
        state.isSendingMessage ||
        _isSendingPendingImages) {
      return;
    }

    final controller = ref.read(supportChatControllerProvider.notifier);
    if (_pendingImages.isEmpty) {
      final sent = await controller.sendText(
        text,
        language: context.locale.languageCode,
      );

      if (!mounted || !sent) return;

      _input.clear();
      _scrollToBottom();
      return;
    }

    setState(() => _isSendingPendingImages = true);

    try {
      final images = List<PlatformFile>.of(_pendingImages);
      if (images.length == 1) {
        final image = images.first;

        final sent = await controller.sendText(
          text,
          language: context.locale.languageCode,
          imageBytes: image.bytes!,
          imageFileName: image.name,
        );

        if (!mounted || !sent) return;

        setState(() {
          _pendingImages.remove(image);
          _input.clear();
        });

        _scrollToBottom();
        return;
      }
      for (final image in images) {
        final sent = await controller.sendText(
          '',
          language: context.locale.languageCode,
          imageBytes: image.bytes!,
          imageFileName: image.name,
        );

        if (!mounted || !sent) return;

        setState(() {
          _pendingImages.remove(image);
        });

        _scrollToBottom();
      }
      if (text.isNotEmpty) {
        final sent = await controller.sendText(
          text,
          language: context.locale.languageCode,
        );

        if (!mounted || !sent) return;

        _input.clear();
        _scrollToBottom();
      }
    } finally {
      if (mounted) {
        setState(() => _isSendingPendingImages = false);
      }
    }
  }

  Future<void> _onSelectOption(String optionId) async {
    if (_submittingOptionId != null) return;

    setState(() => _submittingOptionId = optionId);
    try {
      final result =
          await ref.read(supportChatControllerProvider.notifier).selectOption(
                optionId,
                language: context.locale.languageCode,
              );
      if (!mounted) return;
      setState(() => _submittingOptionId = null);
      if (result == null || result.action != ChatFlowOptionAction.goToUrl) {
        return;
      }

      await _openFlowUrl(result.url);
    } finally {
      if (mounted && _submittingOptionId != null) {
        setState(() => _submittingOptionId = null);
      }
    }
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

  Future<void> _onAttachFile() async {
    const maxImages = 4;
    const maxImageSize = 5 * 1024 * 1024;

    final remaining = maxImages - _pendingImages.length;

    if (remaining <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum 4 images allowed per message'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: true,
    );

    if (result == null || !mounted) return;

    final validImages = result.files
        .where((file) {
          final extension = file.extension?.toLowerCase();

          return file.bytes != null &&
              file.size <= maxImageSize &&
              ['jpg', 'jpeg', 'png', 'webp'].contains(extension);
        })
        .take(remaining)
        .toList();

    setState(() {
      _pendingImages.addAll(validImages);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(
      supportChatControllerProvider.select((state) => state.messages.length),
      (previous, next) {
        if (previous == null || next < previous) {
          _scrollToBottom(animated: false);
          return;
        }
        if (next == previous) return;

        final newest = ref.read(supportChatControllerProvider).messages.last;

        if (newest.isMine || _isNearBottom) {
          _scrollToBottom();
        } else {
          setState(() => _unreadCount += next - previous);
        }
      },
    );
    ref.listen(
      supportChatControllerProvider.select((state) => state.status),
      (previous, next) {
        if (previous == next) return;
        if (next == ChatConversationStatus.waiting &&
            previous != ChatConversationStatus.waiting) {
          _scrollToBottom(animated: false);
          return;
        }
        if (next == ChatConversationStatus.waiting) {
          _scrollToBottom(animated: false);
        }
      },
    );
    ref.listen(
      supportChatControllerProvider.select((state) => state.isStartingChat),
      (previous, next) {
        if (previous == true && next == false) {
          _scrollToBottom(animated: false);
        }
      },
    );
    ref.listen(
      supportChatControllerProvider.select((state) => state.errorMessage),
      (previous, next) {
        if (isServerUnavailableMessage(next)) {
          final current = ref.read(supportChatControllerProvider);
          final hasChat = current.hasConversation ||
              current.messages.isNotEmpty ||
              current.flowMessage != null;
          if (hasChat && context.mounted) {
            unawaited(showServerUnavailableModal(context));
          }
          return;
        }
        if (!isUnreachableMessage(next)) return;
        final current = ref.read(supportChatControllerProvider);
        final hasChat = current.hasConversation ||
            current.messages.isNotEmpty ||
            current.flowMessage != null;
        if (hasChat) GlobalOfflineNotice.show();
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
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.28),
                width: 0.6,
              ),
            ),
            child: const _SupportRobotIcon(size: 20),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'support.chat_title'.tr(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.english(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onPrimary,
                    height: 1.2,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        color: Color(0xFF35D07F),
                        shape: BoxShape.circle,
                      ),
                      child: SizedBox(width: 6, height: 6),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'support.online_status'.tr(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.english(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.onPrimary.withValues(alpha: 0.86),
                        height: 1.2,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      trailing: state.isOpen || state.isWaiting
          ? PopupMenuButton<String>(
              icon: const Icon(
                LucideIcons.ellipsis,
                color: AppColors.onPrimary,
                size: 22,
              ),
              tooltip: '',
              color: AppColors.surface,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              offset: const Offset(0, 4),
              position: PopupMenuPosition.under,
              constraints: const BoxConstraints(
                minWidth: 140,
                maxWidth: 180,
              ),
              enabled: !state.isClosingConversation,
              onSelected: (value) async {
                if (value == 'close') {
                  await closeConversation();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem<String>(
                  value: 'close',
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        LucideIcons.lock,
                        color: AppColors.error,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Close conversation',
                        style: AppTheme.english(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : null,
      topBarContentHeight: 48,
      showBack: true,
      onBack: () => context.goNamed(RouteNames.home),
      body: ColoredBox(
        color: AppColors.background,
        child: (state.isLoading || state.isStartingChat) && !hasExistingChat
            ? const SupportChatSkeleton()
            : _buildBody(state, inputFocused),
      ),
    );
  }

  Future<void> closeConversation() async {
    final closed = await ref
        .read(supportChatControllerProvider.notifier)
        .closeConversation();
    if (!mounted || !closed) return;
  }

  String? _shownChatError(String? message) {
    if (message == null || isUnreachableMessage(message)) return null;
    return message.tr();
  }

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
                setState(() {
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
              setState(() => _unreadCount = 0);
            },
          ),
        ),
      ],
    );
  }
}

class _JumpToLatestButton extends StatelessWidget {
  const _JumpToLatestButton({
    required this.visible,
    required this.count,
    required this.onTap,
  });

  final bool visible;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedScale(
        scale: visible ? 1 : 0.6,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: const Duration(milliseconds: 160),
          child: SizedBox(
            width: 52,
            height: 52,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Material(
                  color: AppColors.surface,
                  shape: const CircleBorder(),
                  elevation: 3,
                  shadowColor: Colors.black.withValues(alpha: 0.25),
                  child: InkWell(
                    onTap: onTap,
                    customBorder: const CircleBorder(),
                    child: const SizedBox(
                      width: 40,
                      height: 40,
                      child: Icon(
                        LucideIcons.arrow_down,
                        size: 20,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                if (count > 0)
                  Positioned(
                    top: 0,
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        count > 99 ? '99+' : '$count',
                        style: AppTheme.english(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onPrimary,
                          height: 1.2,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MainMenuButton extends StatelessWidget {
  const _MainMenuButton({
    required this.loading,
    required this.enabled,
    required this.onTap,
  });

  final bool loading;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = enabled ? AppColors.primary : AppColors.textMuted;

    return Material(
      color: AppColors.primaryLight,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (loading)
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.6,
                    color: color,
                  ),
                )
              else
                Icon(LucideIcons.house, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                'support.main_menu'.tr(),
                style: AppTheme.english(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                  height: AppStyle.lineHeightCaption,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
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

Widget _chatNetworkImage(String url) {
  return Image.network(
    url,
    width: 220,
    height: 220,
    fit: BoxFit.cover,
    loadingBuilder: (context, child, loadingProgress) {
      if (loadingProgress == null) return child;
      return const SizedBox(
        width: 220,
        height: 220,
        child: Center(child: CircularProgressIndicator()),
      );
    },
    errorBuilder: (context, error, stackTrace) => Container(
      width: 220,
      height: 220,
      alignment: Alignment.center,
      color: AppColors.surface,
      child: const Icon(Icons.broken_image_outlined),
    ),
  );
}

void _showImageUrlPreview(BuildContext context, String url) {
  showDialog<void>(
    context: context,
    barrierColor: Colors.black87,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(12),
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          InteractiveViewer(
            minScale: 0.5,
            maxScale: 4,
            child: Image.network(
              url,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.broken_image_outlined, color: Colors.white),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    ),
  );
}

class _BotMessageCard extends StatelessWidget {
  const _BotMessageCard({
    required this.text,
    required this.time,
    this.imageUrl,
  });

  final String text;
  final String time;
  final String? imageUrl;

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
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderLight),
                  boxShadow: AppStyle.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (imageUrl != null && imageUrl!.isNotEmpty) ...[
                      GestureDetector(
                        onTap: () => _showImageUrlPreview(context, imageUrl!),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _chatNetworkImage(imageUrl!),
                        ),
                      ),
                      if (text.trim().isNotEmpty) const SizedBox(height: 6),
                    ],
                    if (text.trim().isNotEmpty)
                      Text(
                        text,
                        style: AppTheme.body(
                          color: AppColors.textPrimary,
                          weight: FontWeight.w400,
                        ).copyWith(fontSize: 14, height: 1.4),
                      ),
                  ],
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
    this.submittingOptionId,
    this.errorMessage,
    this.onSelectOption,
  });

  final String text;
  final String time;
  final List<ChatFlowOption> options;
  final bool localizeOptions;
  final bool isSubmitting;
  final String? submittingOptionId;
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
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text,
                      style: AppTheme.english(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textPrimary,
                        height: AppStyle.lineHeightBody,
                        letterSpacing: 0,
                      ),
                    ),
                    if (options.isNotEmpty || isSubmitting) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Divider(
                          height: 1,
                          thickness: 1,
                          color: AppColors.borderLight,
                        ),
                      ),
                      for (int i = 0; i < options.length; i++) ...[
                        if (i > 0) const SizedBox(height: 6),
                        _CGNetOptionButton(
                          label: _optionLabel(context, options[i]),
                          isLoading: isSubmitting &&
                              submittingOptionId == options[i].id,
                          onPressed: isSubmitting || onSelectOption == null
                              ? null
                              : () => onSelectOption!(options[i].id),
                        ),
                      ],
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
    this.imageBytes = const [],
    this.imageUrl,
  });

  final String text;
  final String time;
  final List<Uint8List> imageBytes;
  final String? imageUrl;

  Widget _buildNetworkImage(BuildContext context) {
    final url = imageUrl;
    if (url == null || url.isEmpty) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => _showImageUrlPreview(context, url),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: _chatNetworkImage(url),
      ),
    );
  }

  void _showImagePreview(BuildContext context, int index) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(12),
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              InteractiveViewer(
                minScale: 0.5,
                maxScale: 4,
                child: Image.memory(
                  imageBytes[index],
                  fit: BoxFit.contain,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.close,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImages(BuildContext context) {
    if (imageBytes.isEmpty) return _buildNetworkImage(context);

    // One image: normal chat image layout.
    if (imageBytes.length == 1) {
      return GestureDetector(
        onTap: () => _showImagePreview(context, 0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(
            imageBytes.first,
            width: 220,
            height: 220,
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    // Multiple images: 2-column grid.
    return SizedBox(
      width: 220,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: imageBytes.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _showImagePreview(context, index),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: Image.memory(
                imageBytes[index],
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasImages =
        imageBytes.isNotEmpty || (imageUrl != null && imageUrl!.isNotEmpty);

    final hasText = text.trim().isNotEmpty;

    final isMultipleImages = imageBytes.length > 1;

    // Multiple images: images and text must be separate.
    if (isMultipleImages) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 48),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildImages(context),
                if (hasText) ...[
                  const SizedBox(height: 6),
                  _buildTextBubble(),
                ],
                const SizedBox(height: 4),
                _buildTimestamp(),
              ],
            ),
          ),
        ],
      );
    }

    // Single image without text: no background.
    if (hasImages && !hasText) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const SizedBox(width: 48),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildImages(context),
                const SizedBox(height: 4),
                _buildTimestamp(),
              ],
            ),
          ),
        ],
      );
    }

    // Single image + text OR text only.
    // Keep them inside one background bubble.
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
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: AppStyle.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasImages) _buildImages(context),
                    if (hasText) ...[
                      if (hasImages) const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Text(
                          text,
                          style: AppTheme.body(
                            color: AppColors.onPrimary,
                            weight: FontWeight.w400,
                          ).copyWith(fontSize: 13, height: 1.4),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 4),
              _buildTimestamp(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextBubble() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(10),
        boxShadow: AppStyle.cardShadow,
      ),
      child: Text(
        text,
        style: AppTheme.body(
          color: AppColors.onPrimary,
          weight: FontWeight.w400,
        ).copyWith(fontSize: 13, height: 1.4),
      ),
    );
  }

  Widget _buildTimestamp() {
    return Text(
      time,
      style: AppTheme.captionSm(
        color: AppColors.textMuted,
      ).copyWith(fontSize: 10),
    );
  }
}

class _CGNetOptionButton extends StatelessWidget {
  const _CGNetOptionButton({
    required this.label,
    this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final labelText = Text(
      label,
      textAlign: TextAlign.center,
      style: AppTheme.english(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: onPressed == null ? AppColors.textMuted : AppColors.primary,
        height: AppStyle.lineHeightCaption,
        letterSpacing: 0,
      ),
    );

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryLight,
          foregroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.primarySoft,
          disabledForegroundColor: AppColors.textMuted,
          minimumSize: const Size.fromHeight(38),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          alignment: Alignment.center,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: isLoading
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.6,
                      color: onPressed == null
                          ? AppColors.textMuted
                          : AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  labelText,
                ],
              )
            : labelText,
      ),
    );
  }
}
