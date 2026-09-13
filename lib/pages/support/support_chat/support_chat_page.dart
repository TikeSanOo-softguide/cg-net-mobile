import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../components/app_curved_scaffold/app_curved_scaffold.dart';
import '../../../components/app_input/app_input.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import '../../../core/theme/app_style/app_style.dart';
import '../../../core/theme/app_theme/app_theme.dart';
import '../../../core/utils/chat_file_picker.dart';
import 'support_chat_controller.dart';

/// One-page direct Support AI chat (Help tab root).
class SupportChatPage extends ConsumerStatefulWidget {
  const SupportChatPage({super.key});

  @override
  ConsumerState<SupportChatPage> createState() => _SupportChatPageState();
}

class _SupportChatPageState extends ConsumerState<SupportChatPage> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  String? _pendingFileName;

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  void _send() {
    final text = _input.text.trim();
    final fileName = _pendingFileName;
    if (text.isEmpty && fileName == null) return;

    ref.read(supportChatControllerProvider.notifier).send(
          text,
          fileName: fileName,
        );
    _input.clear();
    setState(() => _pendingFileName = null);
    _scrollToBottom();
  }

  Future<void> _pickFile() async {
    try {
      final name = await ChatFilePicker.pickFileName();
      if (!mounted) return;
      if (name == null || name.isEmpty) return;
      setState(() => _pendingFileName = name);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('support.file_pick_failed'.tr()),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _formatTime(DateTime time) {
    return DateFormat.jm().format(time);
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(supportChatControllerProvider);

    return AppCurvedScaffold(
      title: Text('support.chat_title'.tr()),
      showBack: false,
      body: ColoredBox(
        color: AppColors.background,
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  final time = _formatTime(msg.sentAt);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: msg.isMine
                        ? _UserMessageCard(
                            text: msg.text,
                            time: time,
                            fileName: msg.fileName,
                          )
                        : _BotMessageCard(text: msg.text, time: time),
                  );
                },
              ),
            ),
            SafeArea(
              top: false,
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
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.border),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.only(left: 6, right: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: 8,
                                    top: 8,
                                  ),
                                  child: AppInput.iconChip(
                                    icon: LucideIcons.paperclip,
                                    size: 32,
                                    iconSize: 15,
                                    onTap: _pickFile,
                                  ),
                                ),
                                Expanded(
                                  child: TextField(
                                    controller: _input,
                                    minLines: 1,
                                    maxLines: 4,
                                    textInputAction: TextInputAction.send,
                                    onSubmitted: (_) => _send(),
                                    style: AppTheme.body(),
                                    decoration: InputDecoration(
                                      hintText: 'support.type_message'.tr(),
                                      hintStyle: AppTheme.bodySecondary(),
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: _send,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: AppColors.primary,
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
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
        ),
      ),
    );
  }
}

class _BotAvatar extends StatelessWidget {
  const _BotAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: const Icon(
        LucideIcons.bot,
        size: 18,
        color: AppColors.onPrimary,
      ),
    );
  }
}

class _BotMessageCard extends StatelessWidget {
  const _BotMessageCard({required this.text, required this.time});

  final String text;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _BotAvatar(),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
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
              const SizedBox(height: 4),
              Text(
                time,
                style: AppTheme.captionSm(color: AppColors.textMuted)
                    .copyWith(fontSize: 10),
              ),
            ],
          ),
        ),
        const SizedBox(width: 48),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: AppStyle.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (fileName != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.onPrimary,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              LucideIcons.file,
                              size: 14,
                              color: AppColors.onPrimary,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                fileName!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTheme.english(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.onPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (text.trim().isNotEmpty) const SizedBox(height: 8),
                    ],
                    if (text.trim().isNotEmpty)
                      Text(
                        text,
                        style: AppTheme.body(
                          color: AppColors.onPrimary,
                          weight: FontWeight.w500,
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
