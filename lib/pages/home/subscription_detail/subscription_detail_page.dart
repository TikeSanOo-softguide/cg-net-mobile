import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../components/app_card/app_card.dart';
import '../../../components/app_curved_scaffold/app_curved_scaffold.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import '../../../core/theme/app_style/app_style.dart';
import '../../../core/theme/app_theme/app_theme.dart';
import '../home/home_controller.dart';

/// Active plans. Each plan keeps its own expiry and WiFi credentials.
class SubscriptionDetailPage extends ConsumerStatefulWidget {
  const SubscriptionDetailPage({super.key});

  @override
  ConsumerState<SubscriptionDetailPage> createState() =>
      _SubscriptionDetailPageState();
}

class _SubscriptionDetailPageState
    extends ConsumerState<SubscriptionDetailPage> {
  final Set<String> _shown = {};

  bool _visible(String id, String field) => _shown.contains('$id:$field');

  void _toggle(String id, String field) {
    final key = '$id:$field';
    setState(() {
      if (!_shown.add(key)) _shown.remove(key);
    });
  }

  @override
  Widget build(BuildContext context) {
    final _ = context.locale;
    final plans = ref.watch(homeControllerProvider).plans;

    return AppCurvedScaffold(
      title: Text('home.my_subscription'.tr()),
      showBack: true,
      onBack: () => context.pop(),
      body: plans.isEmpty
          ? Center(
              child: Text(
                'home.no_active_plan'.tr(),
                style: AppTheme.english(
                  color: AppColors.textMuted,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: AppTheme.lineHeightMyanmarSafe,
                  letterSpacing: 0,
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              itemCount: plans.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Text(
                    'home.active_packages'.tr(
                      namedArgs: {'count': '${plans.length}'},
                    ),
                    style: AppTheme.english(
                      color: AppColors.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: AppTheme.lineHeightMyanmarSafe,
                      letterSpacing: 0,
                    ),
                  );
                }
                final plan = plans[index - 1];
                return _PlanCard(
                  plan: plan,
                  showUsername: _visible(plan.id, 'user'),
                  showPassword: _visible(plan.id, 'pass'),
                  onToggleUsername: () => _toggle(plan.id, 'user'),
                  onTogglePassword: () => _toggle(plan.id, 'pass'),
                );
              },
            ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.showUsername,
    required this.showPassword,
    required this.onToggleUsername,
    required this.onTogglePassword,
  });

  final ActivePlan plan;
  final bool showUsername;
  final bool showPassword;
  final VoidCallback onToggleUsername;
  final VoidCallback onTogglePassword;

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
    final expiryDate = _parseExpiry(plan.expiry);
    final daysLeft = expiryDate == null ? null : _daysLeft(expiryDate);
    final active = daysLeft == null || daysLeft >= 0;
    final remaining = !active
        ? 'home.expired'.tr()
        : daysLeft == null
            ? '—'
            : 'home.days_left'.tr(namedArgs: {'count': '$daysLeft'});

    return AppCard(
      elevated: false,
      bordered: false,
      borderRadius: AppStyle.borderRadiusMd,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  LucideIcons.box,
                  size: 16,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    plan.titleKey.tr(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.english(
                      color: AppColors.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      height: AppTheme.lineHeightMyanmarSafe,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _StatusPill(active: active),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: 'home.valid_until'.tr(),
                  value: plan.expiry,
                  valueColor: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricTile(
                  label: 'home.remaining'.tr(),
                  value: remaining,
                  valueColor: active ? AppColors.success : AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(
              height: 1, thickness: 0.5, color: AppColors.borderLight),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(LucideIcons.wifi, size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'home.wifi_credential'.tr(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.english(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: AppTheme.lineHeightMyanmarSafe,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _CredentialField(
            label: 'home.username'.tr(),
            value: plan.username,
            visible: showUsername,
            onToggleVisibility: onToggleUsername,
          ),
          const SizedBox(height: 8),
          _CredentialField(
            label: 'home.password'.tr(),
            value: plan.password,
            visible: showPassword,
            onToggleVisibility: onTogglePassword,
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundAlt,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.english(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              height: AppTheme.lineHeightMyanmarSafe,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.english(
              color: valueColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: AppTheme.lineHeightMyanmarSafe,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.success : AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            active ? 'home.in_use'.tr() : 'home.expired'.tr(),
            style: AppTheme.english(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: AppTheme.lineHeightMyanmarSafe,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _CredentialField extends StatelessWidget {
  const _CredentialField({
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

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
      decoration: BoxDecoration(
        color: AppColors.backgroundAlt,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.english(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    height: AppTheme.lineHeightMyanmarSafe,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  display,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.english(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: AppTheme.lineHeightMyanmarSafe,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
          _IconAction(
            icon: visible ? LucideIcons.eye : LucideIcons.eye_off,
            onTap: onToggleVisibility,
          ),
          _IconAction(
            icon: LucideIcons.copy,
            onTap: () => _copy(context),
          ),
        ],
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
      ),
    );
  }
}
