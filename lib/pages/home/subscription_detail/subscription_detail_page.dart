import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../components/app_card/app_card.dart';
import '../../../components/app_curved_scaffold/app_curved_scaffold.dart';
import '../../../components/app_dialog/app_dialog.dart';
import '../../../core/network/api_error_text.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import '../../../core/theme/app_theme/app_theme.dart';
import '../../../data/profile/profile_repository.dart';
import '../../../models/user_model/user_model.dart';
import '../../profile/profile/profile_controller.dart';

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
  final Set<int> _loading = {};
  final Map<int, PackageCredentials> _credentials = {};

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(profileControllerProvider.notifier).fetchProfile();
    });
  }

  bool _visible(int id, String field) => _shown.contains('$id:$field');

  Future<void> _toggle(int id, String field) async {
    final key = '$id:$field';
    if (_shown.contains(key)) {
      setState(() => _shown.remove(key));
      return;
    }
    if (_credentials.containsKey(id)) {
      setState(() => _shown.add(key));
      return;
    }
    if (_loading.contains(id)) return;

    setState(() => _loading.add(id));
    try {
      final credentials = await ref
          .read(profileRepositoryProvider)
          .fetchPackageCredentials(id);
      if (!mounted) return;
      setState(() {
        _credentials[id] = credentials;
        _loading.remove(id);
        _shown.add(key);
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _loading.remove(id));
      await showAppFailureModal(
        context,
        title: 'common.error'.tr(),
        body: apiErrorText(error),
      );
    }
  }

  List<_SubscriptionPlan> _plans(String locale, UserProfileModel profile) {
    return [
      for (final package in profile.packages)
        if (package.customerPackageId != null)
          _SubscriptionPlan(
            id: package.customerPackageId!,
            title: _credentials[package.customerPackageId!]?.productName ??
                _planTitle(package, locale),
            expiry: _expiryLabel(
              _credentials[package.customerPackageId!]?.expiresAt ??
                  package.expiresAt,
            ),
          ),
    ];
  }

  String _planTitle(UserPackageSnapshot package, String locale) {
    final network = package.networkLabel(locale).trim();
    final speed = package.speedMbps?.trim() ?? '';
    final title = [
      if (network.isNotEmpty) network,
      if (speed.isNotEmpty) speed,
    ].join(' · ');
    return title.isEmpty ? 'home.my_subscription'.tr() : title;
  }

  String _expiryLabel(DateTime? expiry) {
    if (expiry == null) return '—';
    return DateFormat('yyyy.MM.dd').format(expiry.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.locale.languageCode;
    final plans = _plans(locale, ref.watch(profileControllerProvider));

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
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: plans.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final plan = plans[index];
                final credentials = _credentials[plan.id];
                return _PlanCard(
                  plan: plan,
                  username: credentials?.account ?? '',
                  password: credentials?.password ?? '',
                  loading: _loading.contains(plan.id),
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

class _SubscriptionPlan {
  const _SubscriptionPlan({
    required this.id,
    required this.title,
    required this.expiry,
  });

  final int id;
  final String title;
  final String expiry;
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.username,
    required this.password,
    required this.loading,
    required this.showUsername,
    required this.showPassword,
    required this.onToggleUsername,
    required this.onTogglePassword,
  });

  final _SubscriptionPlan plan;
  final String username;
  final String password;
  final bool loading;
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
      borderRadius: BorderRadius.circular(12),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const Icon(
                  LucideIcons.box,
                  size: 13,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  plan.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.english(
                    color: AppColors.primary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: AppTheme.lineHeightMyanmarSafe,
                    letterSpacing: 0,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _StatusPill(active: active),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _MetricTile(
                    label: 'home.valid_until'.tr(),
                    value: plan.expiry,
                    valueColor: AppColors.textPrimary,
                  ),
                ),
                Container(
                  width: 1,
                  height: 22,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  color: AppColors.borderLight,
                ),
                Expanded(
                  child: _MetricTile(
                    label: 'home.remaining'.tr(),
                    value: remaining,
                    valueColor: active ? AppColors.success : AppColors.error,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(LucideIcons.wifi, size: 12, color: AppColors.primary),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  'home.wifi_credential'.tr(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.english(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: AppTheme.lineHeightMyanmarSafe,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
          _CredentialField(
            label: 'home.username'.tr(),
            value: username,
            visible: showUsername,
            loading: loading,
            onToggleVisibility: onToggleUsername,
          ),
          const Divider(height: 1, thickness: 0.5, color: AppColors.borderLight),
          _CredentialField(
            label: 'home.password'.tr(),
            value: password,
            visible: showPassword,
            loading: loading,
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
    return Column(
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
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTheme.english(
            color: valueColor,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            height: AppTheme.lineHeightMyanmarSafe,
            letterSpacing: 0,
          ),
        ),
      ],
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
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
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
    required this.loading,
    required this.onToggleVisibility,
  });

  final String label;
  final String value;
  final bool visible;
  final bool loading;
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
    final display = visible && value.isNotEmpty
        ? value
        : '•' * (value.isEmpty ? 8 : value.length.clamp(6, 12));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.english(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: AppTheme.lineHeightMyanmarSafe,
                letterSpacing: 0,
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
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: AppTheme.lineHeightMyanmarSafe,
                letterSpacing: 0,
              ),
            ),
          ),
          if (loading)
            const SizedBox(
              width: 30,
              height: 30,
              child: Padding(
                padding: EdgeInsets.all(8),
                child: CircularProgressIndicator(strokeWidth: 1.6),
              ),
            )
          else
            _IconAction(
              icon: visible ? LucideIcons.eye : LucideIcons.eye_off,
              onTap: onToggleVisibility,
            ),
          _IconAction(
            icon: LucideIcons.copy,
            onTap: value.isEmpty ? () {} : () => _copy(context),
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
          width: 30,
          height: 30,
          child: Icon(icon, size: 15, color: AppColors.primary),
        ),
      ),
    );
  }
}
