import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names/route_names.dart';
import '../../../../core/theme/app_colors/app_colors.dart';
import '../../../../core/theme/app_style/app_style.dart';
import '../../../../core/theme/app_theme/app_theme.dart';

/// Active plan — clear text layout, no package image.
class HomePlanCard extends StatefulWidget {
  const HomePlanCard({
    super.key,
    required this.packageId,
    required this.titleKey,
    required this.expiry,
    required this.username,
    required this.password,
    this.onTap,
    this.validityDays = 30,
  });

  final String packageId;
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

  static const _activeGreen = Color(0xFF499A13);
  static const _activeSoft = Color(0xFFE8F5DC);

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

  void _openDetail() {
    if (widget.onTap != null) {
      widget.onTap!();
      return;
    }
    context.pushNamed(
      RouteNames.packageDetail,
      pathParameters: {'id': widget.packageId},
    );
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
      child: Material(
        color: AppColors.surface,
        borderRadius: AppStyle.borderRadiusSm,
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InkWell(
                onTap: _openDetail,
                borderRadius: BorderRadius.circular(8),
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.titleKey.tr(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.english(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                              letterSpacing: 0.3,
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
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: active
                                ? _activeSoft
                                : AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: active
                                      ? _activeGreen
                                      : AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                active
                                    ? 'home.in_use'.tr()
                                    : 'home.expired'.tr(),
                                style: AppTheme.english(
                                  color: active
                                      ? _activeGreen
                                      : AppColors.primary,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  height: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        _DaysCountBadge(count: count, active: active),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // WiFi credential toggle
              Material(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  onTap: () => setState(() => _wifiOpen = !_wifiOpen),
                  borderRadius: BorderRadius.circular(8),
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          LucideIcons.wifi,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'home.wifi_credential'.tr(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.english(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                            ),
                          ),
                        ),
                        AnimatedRotation(
                          turns: _wifiOpen ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
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
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                alignment: Alignment.topCenter,
                child: _wifiOpen
                    ? Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(8),
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
                        ),
                      )
                    : const SizedBox(width: double.infinity),
              ),
            ],
          ),
        ),
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
    final color = active ? AppColors.primary : AppColors.textMuted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
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
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            'home.days_unit'.tr(),
            textAlign: TextAlign.center,
            style: AppTheme.english(
              color: color,
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
