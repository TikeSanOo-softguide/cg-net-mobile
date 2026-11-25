part of 'support_chat_page.dart';

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
