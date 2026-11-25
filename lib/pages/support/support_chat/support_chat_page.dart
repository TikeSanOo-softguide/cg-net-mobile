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

part 'support_chat_body.dart';
part 'support_chat_widgets.dart';

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

  void _update(VoidCallback change) => setState(change);
}
