import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../../core/theme/app_colors/app_colors.dart';
import '../../../../core/theme/app_style/app_style.dart';
import '../../../../core/theme/app_theme/app_theme.dart';
import 'home_section_header.dart';

/// Active plan — title outside, login dropdown inside (previous expand style).
class HomePlanCard extends StatefulWidget {
  const HomePlanCard({
    super.key,
    required this.title,
    required this.expiry,
    required this.username,
    required this.password,
    this.onTap,
    this.validityDays = 30,
  });

  final String title;
  final String expiry;
  final String username;
  final String password;
  final VoidCallback? onTap;
  final int validityDays;

  @override
  State<HomePlanCard> createState() => _HomePlanCardState();
}

class _HomePlanCardState extends State<HomePlanCard> {
  bool _loginOpen = false;

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
    final progress = daysLeft == null
        ? 0.0
        : (daysLeft / widget.validityDays).clamp(0.0, 1.0);

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.english(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: active ? AppColors.accent : AppColors.surface,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                active ? 'home.in_use'.tr() : 'home.expired'.tr(),
                style: AppTheme.english(
                  color: active ? AppColors.onAccent : AppColors.primary,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _PlanStatusBar(progress: progress, active: active),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                'home.plan_expires'.tr(namedArgs: {'date': widget.expiry}),
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
            if (daysLeft != null)
              Text(
                daysLeft >= 0
                    ? 'home.days_left'.tr(namedArgs: {'count': '$daysLeft'})
                    : 'home.expired'.tr(),
                style: AppTheme.english(
                  color: daysLeft >= 0
                      ? AppColors.primary
                      : AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => setState(() => _loginOpen = !_loginOpen),
          borderRadius: BorderRadius.circular(8),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'home.login_info'.tr(),
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
                  turns: _loginOpen ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(
                    LucideIcons.chevron_down,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: _loginOpen
              ? Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Column(
                    children: [
                      _CredentialRow(
                        label: 'home.username'.tr(),
                        value: widget.username,
                      ),
                      const SizedBox(height: 4),
                      _CredentialRow(
                        label: 'home.password'.tr(),
                        value: widget.password,
                      ),
                    ],
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );

    return Padding(
      padding: AppStyle.pagePaddingH,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HomeSectionHeader(title: 'home.active_plan'.tr()),
          Material(
            color: AppColors.surface,
            borderRadius: AppStyle.borderRadiusMd,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: widget.onTap == null
                  ? content
                  : GestureDetector(
                      onTap: widget.onTap,
                      behavior: HitTestBehavior.opaque,
                      child: content,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanStatusBar extends StatelessWidget {
  const _PlanStatusBar({
    required this.progress,
    required this.active,
  });

  final double progress;
  final bool active;

  static const double _height = 8;
  static const double _inset = 1.5;
  static const double _thumb = 7;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final inner = (constraints.maxWidth - _inset * 2).clamp(0.0, double.infinity);
          final fill = progress <= 0
              ? 0.0
              : (inner * progress).clamp(_thumb, inner);

          return Container(
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(999),
            ),
            padding: const EdgeInsets.all(_inset),
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 420),
                  curve: Curves.easeOut,
                  width: fill,
                  height: _height - _inset * 2,
                  decoration: BoxDecoration(
                    color: active ? AppColors.primary : AppColors.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                if (fill > 0)
                  Positioned(
                    left: (fill - _thumb).clamp(0.0, inner - _thumb),
                    child: Container(
                      width: _thumb,
                      height: _thumb,
                      decoration: BoxDecoration(
                        color: active ? AppColors.accent : AppColors.surface,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CredentialRow extends StatelessWidget {
  const _CredentialRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 78,
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
            value,
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
      ],
    );
  }
}
