import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../components/app_card/app_card.dart';
import '../../../components/app_curved_scaffold/app_curved_scaffold.dart';
import '../../../core/locale/app_locale_provider.dart';
import '../../../core/network/api_error_text.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import '../../../core/theme/app_style/app_style.dart';
import '../../../core/utils/version_check/version_check.dart';
import 'version_controller.dart';

class VersionPage extends ConsumerWidget {
  const VersionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appVersion = ref.watch(versionControllerProvider);
    final installedVersion = ref.watch(packageInfoProvider);
    final languageCode = ref.watch(appLocaleProvider);

    return AppCurvedScaffold(
      title: Text('profile.version'.tr()),
      showBack: true,
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          appVersion.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
            error: (error, _) => _LoadError(
              message: error is ApiException
                  ? apiErrorOrFallback(error)
                  : 'profile.version_load_failed'.tr(),
              onRetry: () => ref.refresh(versionControllerProvider),
            ),
            data: (info) => _VersionContent(
              info: info,
              installedVersion: installedVersion.valueOrNull?.version,
              languageCode: languageCode,
            ),
          ),
        ],
      ),
    );
  }
}

class _VersionContent extends StatelessWidget {
  const _VersionContent({
    required this.info,
    required this.installedVersion,
    required this.languageCode,
  });

  final AppVersionInfo info;
  final String? installedVersion;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final releaseDate = info.createdAt == null
        ? null
        : DateFormat.yMMMd(languageCode).format(info.createdAt!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          padding: const EdgeInsets.all(20),
          borderRadius: AppStyle.borderRadiusLg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'profile.latest_version'.tr(),
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: AppColors.textSecondary,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  if (info.forceUpdate)
                    _StatusBadge(
                      label: 'profile.force_update'.tr(),
                      color: AppColors.error,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                info.version,
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (installedVersion != null) ...[
                const SizedBox(height: 4),
                Text(
                  '${'profile.installed_version'.tr()}: $installedVersion',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              _InfoLine(
                label: 'profile.platform'.tr(),
                value: info.platform == 'ios'
                    ? 'profile.platform_ios'.tr()
                    : 'profile.platform_android'.tr(),
              ),
              const SizedBox(height: 6),
              _InfoLine(
                label: 'profile.minimum_version'.tr(),
                value: info.minimumVersion,
              ),
              if (releaseDate != null) ...[
                const SizedBox(height: 6),
                _InfoLine(
                  label: 'profile.release_date'.tr(),
                  value: releaseDate,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        AppCard(
          padding: const EdgeInsets.all(20),
          borderRadius: AppStyle.borderRadiusLg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'profile.release_notes'.tr(),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                info.releaseNotes(languageCode),
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      borderRadius: AppStyle.borderRadiusLg,
      child: Column(
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: Text('common.retry'.tr()),
          ),
        ],
      ),
    );
  }
}
