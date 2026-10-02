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
                        profile.accountNumber,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.english(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        profile.phone,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.english(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppStyle.spaceSm),
                Material(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    onTap: () => context.pushNamed(RouteNames.editProfile),
                    borderRadius: BorderRadius.circular(8),
                    splashColor: AppColors.primary.withValues(alpha: 0.08),
                    highlightColor: AppColors.primary.withValues(alpha: 0.04),
                    child: SizedBox(
                      width: 32,
                      height: 32,
                      child: Center(
                        child: Image.asset(
                          'assets/images/profile/edit.png',
                          width: 16,
                          height: 16,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                        ),
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
            asset: 'assets/images/profile/language.png',
            title: 'profile.language'.tr(),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _languageLabel(context),
                  style: AppTheme.caption(color: AppColors.textMuted).copyWith(
                    fontSize: AppStyle.fontCaption,
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
            asset: 'assets/images/profile/account_settings.png',
            title: 'profile.account_settings'.tr(),
            onTap: () => context.pushNamed(RouteNames.editProfile),
          ),
          const SizedBox(height: 5),
          _SettingsCard(
            asset: 'assets/images/profile/change_password.png',
            title: 'profile.change_password'.tr(),
            onTap: () => context.pushNamed(RouteNames.changePassword),
          ),
          const SizedBox(height: 5),
          _SettingsCard(
            asset: 'assets/images/profile/device.png',
            title: 'profile.devices'.tr(),
            onTap: () => context.pushNamed(RouteNames.deviceSession),
          ),
          const SizedBox(height: 5),
          _SettingsCard(
            asset: 'assets/images/profile/notification.png',
            title: 'profile.notifications'.tr(),
            onTap: () =>
                context.pushNamed(RouteNames.notificationPreferences),
          ),
          const SizedBox(height: 5),
          _SettingsCard(
            asset: 'assets/images/profile/version.png',
            title: 'profile.version'.tr(),
            trailingText: versionText,
            onTap: () => context.pushNamed(RouteNames.aboutApp),
          ),
          const SizedBox(height: 5),
          _SettingsCard(
            asset: 'assets/images/profile/logout.png',
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
    required this.asset,
    required this.title,
    required this.onTap,
    this.tint = AppColors.primary,
    this.trailing,
    this.trailingText,
    this.titleColor,
    this.chevronColor,
  });

  final String asset;
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
              width: 35,
              height: 35,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: tint == AppColors.primary
                    ? AppColors.primaryLight
                    : tint,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Image.asset(
                asset,
                width: 18,
                height: 18,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: AppTheme.body(
                  color: titleColor ?? AppColors.textPrimary,
                  weight: FontWeight.w500,
                ).copyWith(fontSize: AppStyle.fontBody),
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
