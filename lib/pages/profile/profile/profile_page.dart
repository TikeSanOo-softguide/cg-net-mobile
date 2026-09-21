import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../components/app_card/app_card.dart';
import '../../../components/app_curved_scaffold/app_curved_scaffold.dart';
import '../../../components/app_logo/app_logo.dart';
import '../../../core/locale/app_locale_provider.dart';
import '../../../core/router/route_names/route_names.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import '../../../core/theme/app_style/app_style.dart';
import '../../../core/theme/app_theme/app_theme.dart';
import '../../../core/utils/version_check/version_check.dart';
import 'profile_controller.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  String _languageLabel(BuildContext context) {
    switch (context.locale.languageCode) {
      case 'my':
        return context.tr('language.myanmar');
      case 'zh':
        return context.tr('language.chinese');
      default:
        return context.tr('language.english');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileControllerProvider);
    final localeCode = ref.watch(appLocaleProvider);
    final versionAsync = ref.watch(packageInfoProvider);
    final versionText = versionAsync.maybeWhen(
      data: (info) => 'v${info.version}',
      orElse: () => null,
    );

    return AppCurvedScaffold(
      title: Text(
        context.tr('profile.title'),
        style: AppTheme.topBarTitle(),
      ),
      showBack: false,
      body: ListView(
        key: ValueKey('profile-$localeCode'),
        padding: const EdgeInsets.fromLTRB(
          AppStyle.spaceLg,
          AppStyle.spaceLg,
          AppStyle.spaceLg,
          AppStyle.spaceXxl,
        ),
        children: [
          AppCard(
            elevated: true,
            bordered: false,
            padding: const EdgeInsets.all(AppStyle.spaceMd),
            child: Row(
              children: [
                _AccountAvatar(name: profile.fullName),
                const SizedBox(width: AppStyle.spaceMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.cardTitle().copyWith(
                          fontSize: AppStyle.fontCardTitle - 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        profile.phone,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.bodySecondary().copyWith(
                          fontSize: AppStyle.fontSecondary - 1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppStyle.spaceSm),
                Material(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    onTap: () => context.pushNamed(RouteNames.editProfile),
                    borderRadius: BorderRadius.circular(8),
                    splashColor: Colors.white.withValues(alpha: 0.18),
                    highlightColor: Colors.white.withValues(alpha: 0.08),
                    child: const SizedBox(
                      width: 28,
                      height: 28,
                      child: Icon(
                        LucideIcons.square_pen,
                        size: 14,
                        color: AppColors.onPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppStyle.spaceXl),
          Text(
            'profile.general'.tr(),
            style: AppTheme.sectionTitle(color: AppColors.textSecondary)
                .copyWith(fontSize: AppStyle.fontSectionTitle - 1),
          ),
          const SizedBox(height: AppStyle.spaceMd),
          _SettingsCard(
            icon: LucideIcons.languages,
            title: 'profile.language'.tr(),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _languageLabel(context),
                  style: AppTheme.caption(color: AppColors.textMuted).copyWith(
                    fontSize: AppStyle.fontCaption - 1,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  LucideIcons.chevron_down,
                  size: 16,
                  color: AppColors.textMuted,
                ),
              ],
            ),
            onTap: () => context.pushNamed(RouteNames.languageSettings),
          ),
          const SizedBox(height: 5),
          _SettingsCard(
            icon: LucideIcons.smartphone,
            title: 'profile.edit'.tr(),
            onTap: () => context.pushNamed(RouteNames.editProfile),
          ),
          const SizedBox(height: 5),
          _SettingsCard(
            icon: LucideIcons.lock_keyhole,
            title: 'profile.change_password'.tr(),
            onTap: () => context.pushNamed(RouteNames.changePassword),
          ),
          const SizedBox(height: 5),
          _SettingsCard(
            icon: LucideIcons.monitor,
            title: 'profile.devices'.tr(),
            onTap: () => context.pushNamed(RouteNames.deviceSession),
          ),
          const SizedBox(height: 5),
          _SettingsCard(
            icon: LucideIcons.bell,
            title: 'profile.notifications'.tr(),
            onTap: () =>
                context.pushNamed(RouteNames.notificationPreferences),
          ),
          const SizedBox(height: 5),
          _SettingsCard(
            icon: LucideIcons.rotate_ccw_clock,
            title: 'profile.version'.tr(),
            trailingText: versionText,
            onTap: () => context.pushNamed(RouteNames.aboutApp),
          ),
          const SizedBox(height: 5),
          _SettingsCard(
            icon: LucideIcons.info,
            title: 'profile.about'.tr(),
            onTap: () => context.pushNamed(RouteNames.aboutApp),
          ),
          const SizedBox(height: 5),
          _SettingsCard(
            icon: LucideIcons.log_out,
            iconColor: AppColors.error,
            tint: const Color(0xFFFFEBEE),
            title: 'common.logout'.tr(),
            titleColor: AppColors.error,
            chevronColor: AppColors.error,
            onTap: () async {
              await ref.read(profileControllerProvider.notifier).logout();
              if (context.mounted) {
                context.goNamed(RouteNames.login);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _AccountAvatar extends StatelessWidget {
  const _AccountAvatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return const AppLogo(
      size: 38,
      padding: 4,
      borderRadius: 8,
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.icon,
    required this.title,
    required this.onTap,
    this.iconColor = AppColors.onPrimary,
    this.tint = AppColors.primary,
    this.trailing,
    this.trailingText,
    this.titleColor,
    this.chevronColor,
  });

  final IconData icon;
  final Color iconColor;
  final Color tint;
  final String title;
  final VoidCallback onTap;
  final Widget? trailing;
  final String? trailingText;
  final Color? titleColor;
  final Color? chevronColor;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      elevated: true,
      bordered: false,
      padding: EdgeInsets.zero,
      borderRadius: AppStyle.borderRadiusSm,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: tint == AppColors.primary
                    ? AppColors.primaryLight
                    : tint,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 15,
                color: iconColor == AppColors.onPrimary
                    ? AppColors.primary
                    : iconColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: AppTheme.body(
                  color: titleColor ?? AppColors.textPrimary,
                  weight: FontWeight.w500,
                ).copyWith(fontSize: AppStyle.fontBody - 1),
              ),
            ),
            if (trailing != null) ...[
              trailing!,
            ] else ...[
              if (trailingText != null) ...[
                Text(
                  trailingText!,
                  style: AppTheme.caption(color: AppColors.textMuted).copyWith(
                    fontSize: AppStyle.fontCaption - 1,
                  ),
                ),
                const SizedBox(width: AppStyle.spaceXs),
              ],
              Icon(
                LucideIcons.chevron_right,
                size: 18,
                color: chevronColor ?? AppColors.textMuted,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
