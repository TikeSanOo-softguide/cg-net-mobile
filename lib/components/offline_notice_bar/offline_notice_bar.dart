import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../core/theme/app_colors/app_colors.dart';
import '../../core/theme/app_style/app_style.dart';
import '../../core/theme/app_theme/app_theme.dart';
import '../offline_status_content/offline_status_content.dart';

/// In-page empty state used when a list has never loaded because the server
/// could not be reached.
class OfflineEmptyState extends StatelessWidget {
  const OfflineEmptyState({
    super.key,
    required this.onRetry,
    this.scrollable = true,
  });

  final VoidCallback onRetry;

  /// When the page already provides a scroll view, keep only the content.
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final content = Center(
      child: Padding(
        padding: AppStyle.pagePaddingH,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: AppStyle.borderRadiusListCard,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const OfflineStatusContent(prominent: true),
                const SizedBox(height: 12),
                OfflineRetryButton(onPressed: onRetry),
              ],
            ),
          ),
        ),
      ),
    );
    if (!scrollable) return content;
    return _fillScroll(content);
  }
}

/// In-page empty state when the internet is up but the API host is not.
class ServerUnavailableEmptyState extends StatelessWidget {
  const ServerUnavailableEmptyState({
    super.key,
    required this.onRetry,
    this.scrollable = true,
  });

  final VoidCallback onRetry;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final content = Center(
      child: Padding(
        padding: AppStyle.pagePaddingH,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: AppStyle.borderRadiusListCard,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ServerUnavailableContent(prominent: true),
                const SizedBox(height: 12),
                OfflineRetryButton(onPressed: onRetry),
              ],
            ),
          ),
        ),
      ),
    );
    if (!scrollable) return content;
    return _fillScroll(content);
  }
}

Widget _fillScroll(Widget content) {
  return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: constraints.maxHeight,
            child: content,
          ),
        );
      },
  );
}

class OfflineRetryButton extends StatelessWidget {
  const OfflineRetryButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      borderRadius: AppStyle.borderRadiusButton,
      child: InkWell(
        onTap: onPressed,
        borderRadius: AppStyle.borderRadiusButton,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                LucideIcons.refresh_cw,
                size: 12,
                color: AppColors.onPrimary,
              ),
              const SizedBox(width: 6),
              Text(
                'common.retry'.tr(),
                style: AppTheme.caption(
                  color: AppColors.onPrimary,
                  weight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
