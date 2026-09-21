import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names/route_names.dart';
import '../../../../core/theme/app_colors/app_colors.dart';
import '../../../../core/theme/app_style/app_style.dart';
import '../../../../core/theme/app_theme/app_theme.dart';
import 'home_section_header.dart';

/// Active plan — left image, right details + day count; WiFi dropdown full width.
class HomePlanCard extends StatefulWidget {
  const HomePlanCard({
    super.key,
    required this.packageId,
    required this.imagePath,
    required this.titleKey,
    required this.expiry,
    required this.username,
    required this.password,
    this.onTap,
    this.validityDays = 30,
  });

  final String packageId;
  final String imagePath;
  final String titleKey;
  final String expiry;
  final String username;
  final String password;
  final VoidCallback? onTap;
  final int validityDays;

  @override
  State<HomePlanCard> createState() => _HomePlanCardState();
}

class _HomePlanCardState extends State<HomePlanCard> {
  bool _wifiOpen = false;
  bool _showUsername = false;
  bool _showPassword = false;

  static const _imageW = 96.0;
  static const _imageH = 72.0;
  static const _imageRadius = 8.0;

  static DateTime? _parseExpiry(String raw) {
    final parts = raw.split(RegExp(r'[.\-/]'));
    if (parts.length != 3) return null;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) return null;
    return DateTime(year, month, day);
  }

  static int _daysLeft(DateTime expiry) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return expiry.difference(today).inDays;
  }

  @override
  Widget build(BuildContext context) {
    final _ = context.locale;
    final expiryDate = _parseExpiry(widget.expiry);
    final daysLeft = expiryDate == null ? null : _daysLeft(expiryDate);
    final active = daysLeft == null || daysLeft >= 0;
    final count = daysLeft == null ? 0 : (daysLeft < 0 ? 0 : daysLeft);

    return Padding(
      padding: AppStyle.pagePaddingH,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HomeSectionHeader(title: 'home.active_plan'.tr()),
          Material(
            color: AppColors.surface,
            borderRadius: AppStyle.borderRadiusMd,
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left — rounded 4-corner image.
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => context.pushNamed(
                            RouteNames.packageDetail,
                            pathParameters: {'id': widget.packageId},
                          ),
                          borderRadius: BorderRadius.circular(_imageRadius),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(_imageRadius),
                            child: SizedBox(
                              width: _imageW,
                              height: _imageH,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  const ColoredBox(color: AppColors.primarySoft),
                                  Image.asset(
                                    widget.imagePath,
                                    fit: BoxFit.cover,
                                    alignment: Alignment.center,
                                    filterQuality: FilterQuality.high,
                                    gaplessPlayback: true,
                                    errorBuilder: (_, __, ___) =>
                                        const ColoredBox(
                                      color: AppColors.primaryLight,
                                      child: Center(
                                        child: Icon(
                                          LucideIcons.image_off,
                                          color: AppColors.primary,
                                          size: 18,
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
                      const SizedBox(width: 10),
                      // Right — details + count + WiFi toggle.
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.titleKey.tr(),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTheme.english(
                                          color: AppColors.textPrimary,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          height: 1.2,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'home.plan_expires'.tr(
                                          namedArgs: {'date': widget.expiry},
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTheme.english(
                                          color: AppColors.textMuted,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          height: 1.2,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 7,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: active
                                              ? const Color(0xFFDCFCE7)
                                              : AppColors.primarySoft,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          active
                                              ? 'home.in_use'.tr()
                                              : 'home.expired'.tr(),
                                          style: AppTheme.english(
                                            color: active
                                                ? const Color(0xFF15803D)
                                                : AppColors.primary,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                            height: 1.1,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _DaysCountBadge(
                                  count: count,
                                  active: active,
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: () =>
                                  setState(() => _wifiOpen = !_wifiOpen),
                              borderRadius: BorderRadius.circular(6),
                              splashColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 2),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'home.wifi_credential'.tr(),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTheme.english(
                                          color: AppColors.primary,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          height: 1.2,
                                        ),
                                      ),
                                    ),
                                    AnimatedRotation(
                                      turns: _wifiOpen ? 0.5 : 0,
                                      duration:
                                          const Duration(milliseconds: 200),
                                      child: const Icon(
                                        LucideIcons.chevron_down,
                                        size: 15,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Full-card width dropdown under the image row.
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  alignment: Alignment.topCenter,
                  child: _wifiOpen
                      ? Container(
                          width: double.infinity,
                          margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.borderLight,
                              width: 0.8,
                            ),
                          ),
                          child: Column(
                            children: [
                              _CredentialRow(
                                label: 'home.username'.tr(),
                                value: widget.username,
                                visible: _showUsername,
                                onToggleVisibility: () => setState(
                                  () => _showUsername = !_showUsername,
                                ),
                              ),
                              const SizedBox(height: 6),
                              _CredentialRow(
                                label: 'home.password'.tr(),
                                value: widget.password,
                                visible: _showPassword,
                                onToggleVisibility: () => setState(
                                  () => _showPassword = !_showPassword,
                                ),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox(width: double.infinity),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DaysCountBadge extends StatelessWidget {
  const _DaysCountBadge({
    required this.count,
    required this.active,
  });

  final int count;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: active ? AppColors.primarySoft : AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: AppTheme.english(
              color: active ? AppColors.primary : AppColors.textMuted,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            'home.days_unit'.tr(),
            style: AppTheme.english(
              color: active ? AppColors.primary : AppColors.textMuted,
              fontSize: 8,
              fontWeight: FontWeight.w600,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _CredentialRow extends StatelessWidget {
  const _CredentialRow({
    required this.label,
    required this.value,
    required this.visible,
    required this.onToggleVisibility,
  });

  final String label;
  final String value;
  final bool visible;
  final VoidCallback onToggleVisibility;

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('home.copied'.tr()),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final display = visible ? value : '•' * value.length.clamp(6, 12);

    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.english(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              height: 1.2,
            ),
          ),
        ),
        Expanded(
          child: Text(
            display,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.english(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
        ),
        InkWell(
          onTap: onToggleVisibility,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(
              visible ? LucideIcons.eye_off : LucideIcons.eye,
              size: 15,
              color: AppColors.primary,
            ),
          ),
        ),
        InkWell(
          onTap: () => _copy(context),
          borderRadius: BorderRadius.circular(6),
          child: const Padding(
            padding: EdgeInsets.all(4),
            child: Icon(
              LucideIcons.copy,
              size: 15,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}
