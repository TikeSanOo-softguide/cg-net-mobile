import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../components/app_card/app_card.dart';
import '../../../components/app_curved_scaffold/app_curved_scaffold.dart';
import '../../../components/app_logo/app_logo.dart';
import '../../../core/locale/app_locale_provider.dart';
import '../../../core/theme/app_theme/app_theme.dart';
import '../../../core/network/api_error_text.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import '../../../core/theme/app_style/app_style.dart';
import '../../../core/utils/version_check/version_check.dart';
import 'about_app_controller.dart';

class AboutAppPage extends ConsumerWidget {
  const AboutAppPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appVersion = ref.watch(aboutAppVersionProvider);
    final installedVersion = ref.watch(packageInfoProvider);
    final languageCode = ref.watch(appLocaleProvider);

    return AppCurvedScaffold(
      title: Text('profile.about_title'.tr()),
      showBack: true,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        children: [
          const _AboutLogo(),
          const SizedBox(height: 20),
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
              onRetry: () => ref.refresh(aboutAppVersionProvider),
            ),
            data: (info) => _VersionContent(
              info: info,
              installedVersion: installedVersion.valueOrNull?.version,
              languageCode: languageCode,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'profile.icon_credits'.tr(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 6),
          Center(
            child: InkWell(
              onTap: () async {
                final uri = Uri.parse('https://www.flaticon.com/legal');
                await launchUrl(
                  uri,
                  mode: LaunchMode.externalApplication,
                );
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        'Flaticon - Receipt icons',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              decoration: TextDecoration.underline,
                            ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.open_in_new,
                      size: 14,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutLogo extends StatelessWidget {
  const _AboutLogo();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: AppLogo(size: 56),
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
    final releaseDate = info.createdAt == null
        ? null
        : DateFormat.yMMMd(languageCode).format(info.createdAt!);
    final notes = info
        .releaseNotes(languageCode)
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          borderRadius: AppStyle.borderRadiusLg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'profile.latest_version'.tr(),
                      style: AppTheme.english(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                        height: AppStyle.lineHeightCaption,
                        letterSpacing: 0.1,
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
              const SizedBox(height: 12),
              Text(
                info.version,
                style: AppTheme.english(
                  fontSize: AppStyle.fontAmount,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  height: AppStyle.lineHeightTitle,
                  letterSpacing: -0.3,
                ),
              ),
              if (installedVersion != null) ...[
                const SizedBox(height: 12),
                Text(
                  '${'profile.installed_version'.tr()}: $installedVersion',
                  style: AppTheme.english(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                    height: AppStyle.lineHeightBody,
                    letterSpacing: 0,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              const Divider(height: 1, color: AppColors.borderLight),
              const SizedBox(height: 4),
              _InfoLine(
                label: 'profile.platform'.tr(),
                value: info.platform == 'ios'
                    ? 'profile.platform_ios'.tr()
                    : 'profile.platform_android'.tr(),
              ),
              _InfoLine(
                label: 'profile.minimum_version'.tr(),
                value: info.minimumVersion,
              ),
              if (releaseDate != null)
                _InfoLine(
                  label: 'profile.release_date'.tr(),
                  value: releaseDate,
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          padding: const EdgeInsets.all(16),
          borderRadius: AppStyle.borderRadiusLg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'profile.release_notes'.tr(),
                style: AppTheme.english(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  height: AppStyle.lineHeightTitle,
                  letterSpacing: -0.15,
                ),
              ),
              const SizedBox(height: 12),
              for (var i = 0; i < notes.length; i++) ...[
                if (i > 0) const SizedBox(height: 10),
                Text(
                  notes[i],
                  style: AppTheme.english(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                    height: AppStyle.lineHeightBody,
                    letterSpacing: 0,
                  ),
                ),
              ],
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTheme.english(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
                height: AppStyle.lineHeightBody,
                letterSpacing: 0,
              ),
            ),
          ),
          Text(
            value,
            style: AppTheme.english(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
              height: AppStyle.lineHeightBody,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
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
          fontWeight: FontWeight.w600,
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
