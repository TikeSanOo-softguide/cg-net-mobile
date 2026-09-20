import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router/go_router.dart';

import '../../../components/app_circle_icon_button/app_circle_icon_button.dart';
import '../../../components/app_dialog/app_dialog.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import '../../../core/theme/app_style/app_style.dart';
import '../../../core/theme/app_theme/app_theme.dart';
import '../package_catalog.dart';

/// Package detail — full-bleed image (no top bar) + back button + description sheet.
class PackageDetailPage extends StatefulWidget {
  const PackageDetailPage({super.key, required this.packageId});

  final String packageId;

  @override
  State<PackageDetailPage> createState() => _PackageDetailPageState();
}

class _PackageDetailPageState extends State<PackageDetailPage> {
  bool _autoRenew = true;

  static const _sheetRadius = 24.0;

  Future<void> _buyNow() async {
    await showAppSuccessModal(
      context,
      title: _autoRenew
          ? 'package.renew_success_title'.tr()
          : 'package.buy_success_title'.tr(),
      body: _autoRenew
          ? 'package.renew_success_body'.tr()
          : 'package.buy_success_body'.tr(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.locale.languageCode;
    final item = PackageCatalog.byId(widget.packageId);
    final imagePath =
        item?.imagePath ?? 'assets/images/packages/package_1m.png';
    final title = (item?.titleKey ?? 'package.title').tr();
    final body = (item?.descriptionKey ?? 'package.empty_body').tr();
    final topInset = MediaQuery.paddingOf(context).top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.systemOverlayImmersive,
      child: Scaffold(
        key: ValueKey('package-detail-${widget.packageId}-$locale'),
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            AspectRatio(
              aspectRatio: 16 / 10,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    imagePath,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    alignment: Alignment.center,
                    filterQuality: FilterQuality.high,
                    gaplessPlayback: true,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.primaryLight,
                      alignment: Alignment.center,
                      child: const Icon(
                        LucideIcons.image_off,
                        color: AppColors.primary,
                        size: 32,
                      ),
                    ),
                  ),
                  Positioned(
                    top: topInset + 8,
                    left: AppStyle.spaceLg,
                    child: AppCircleIconButton(
                      icon: LucideIcons.chevron_left,
                      backgroundColor: Colors.black.withValues(alpha: 0.35),
                      onPressed: () => context.pop(),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Transform.translate(
                offset: const Offset(0, -20),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(_sheetRadius),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 12,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          title,
                          style: AppTheme.english(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppStyle.spaceSm),
                        Text(
                          body,
                          style:
                              AppTheme.bodySecondary().copyWith(fontSize: 13),
                        ),
                        const SizedBox(height: AppStyle.spaceXl),
                        Row(
                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                LucideIcons.refresh_cw,
                                size: 12,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'package.renew'.tr(),
                                    style: AppTheme.english(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    'package.renew_hint'.tr(),
                                    style: AppTheme.english(
                                      fontSize: 10,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Transform.scale(
                              scale: 0.78,
                              child: Switch.adaptive(
                                value: _autoRenew,
                                activeThumbColor: AppColors.onPrimary,
                                activeTrackColor: AppColors.primary,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                onChanged: (v) =>
                                    setState(() => _autoRenew = v),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppStyle.spaceXl),
                        SizedBox(
                          width: double.infinity,
                          height: 42,
                          child: FilledButton.icon(
                            onPressed: _buyNow,
                            icon: const Icon(
                              LucideIcons.shopping_bag,
                              size: 16,
                            ),
                            label: Text(
                              'home.buy_now'.tr(),
                              style: AppTheme.english(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.onPrimary,
                              ),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.onPrimary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
