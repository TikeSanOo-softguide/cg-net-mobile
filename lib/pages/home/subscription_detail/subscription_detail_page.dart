import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../components/app_refresh_indicator/app_refresh_indicator.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../components/app_card/app_card.dart';
import '../../../components/app_curved_scaffold/app_curved_scaffold.dart';
import '../../../components/app_dialog/app_dialog.dart';
import '../../../components/offline_notice_bar/offline_notice_bar.dart';
import '../../../components/page_skeletons/subscription_skeleton.dart';
import '../../../core/network/api_error_text.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/network_recovery_controller.dart';
import '../../../core/network/offline_navigation.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import '../../../core/theme/app_style/app_style.dart';
import '../../../core/theme/app_theme/app_theme.dart';
import '../../../data/profile/profile_repository.dart';

/// Active plans. Each plan keeps its own expiry and WiFi credentials.
class SubscriptionDetailPage extends ConsumerStatefulWidget {
  const SubscriptionDetailPage({super.key});

  @override
  ConsumerState<SubscriptionDetailPage> createState() =>
      _SubscriptionDetailPageState();
}

class _SubscriptionDetailPageState
    extends ConsumerState<SubscriptionDetailPage> {
  static const _recoveryKey = 'subscription-reload';

  final Set<String> _shown = {};
  final Map<int, PackageCredentials> _credentials = {};
  List<_SubscriptionPlan> _plans = const [];
  var _pageLoading = true;
  var _unreachable = false;
  var _serverDown = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  @override
  void dispose() {
    ref.read(networkRecoveryControllerProvider).clear(_recoveryKey);
    super.dispose();
  }

  bool _visible(int id, String field) => _shown.contains('$id:$field');

  Future<void> _load({
    bool rethrowOffline = false,
  }) async {
    if (mounted) setState(() => _pageLoading = _plans.isEmpty);
    try {
      final repository = ref.read(profileRepositoryProvider);
      final ids = await repository.fetchCustomerPackageIds();
      final loaded = await Future.wait(
        ids.map(repository.fetchPackageCredentials),
      );
      if (!mounted) return;
      setState(() {
        _credentials
          ..clear()
          ..addEntries([
            for (final item in loaded)
              if (item.customerPackageId != null)
                MapEntry(item.customerPackageId!, item),
          ]);
        _plans = [
          for (final item in loaded)
            if (item.customerPackageId != null)
              _SubscriptionPlan(
                id: item.customerPackageId!,
                title: (item.productName ?? '').trim().isEmpty
                    ? 'home.my_subscription'.tr()
                    : item.productName!.trim(),
                expiry: _expiryLabel(item.expiresAt),
              ),
        ];
        _pageLoading = false;
        _unreachable = false;
        _serverDown = false;
      });
      ref.read(networkRecoveryControllerProvider).clear(_recoveryKey);
    } on ApiException catch (error) {
      final unreachable = isUnreachableError(error);
      if (!mounted) {
        if (rethrowOffline && unreachable) {
          throw const ApiException(ApiFailure.offline);
        }
        return;
      }
      final serverDown = isServerUnavailableError(error);
      setState(() {
        _pageLoading = false;
        _unreachable = unreachable && _plans.isEmpty;
        _serverDown = serverDown && _plans.isEmpty;
      });
      if (unreachable) {
        if (rethrowOffline) throw const ApiException(ApiFailure.offline);
        ref.read(networkRecoveryControllerProvider).enqueue(
              _recoveryKey,
              () => _load(rethrowOffline: true),
            );
        return;
      }
      if (serverDown) {
        if (_plans.isEmpty || rethrowOffline) return;
        final retry = await showServerUnavailableModal(context);
        if (retry && mounted) await _load();
        return;
      }
      if (!rethrowOffline) {
        await showAppFailureModal(
          context,
          title: 'common.error'.tr(),
          body: apiErrorText(error),
        );
      }
    }
  }

  void _toggle(int id, String field) {
    final key = '$id:$field';
    setState(() {
      if (!_shown.add(key)) _shown.remove(key);
    });
  }

  String _expiryLabel(DateTime? expiry) {
    if (expiry == null) return '—';
    return DateFormat('yyyy.MM.dd HH:mm').format(expiry.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final plans = _plans;
    final loading = _pageLoading && plans.isEmpty;

    return AppCurvedScaffold(
      title: Text('home.my_subscription'.tr()),
      showBack: true,
      onBack: () => context.pop(),
      body: AppRefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => _load(),
        child: loading
            ? _loadingList()
            : plans.isEmpty
                ? _unreachable
                    ? _offlineList()
                    : _serverDown
                        ? ServerUnavailableEmptyState(onRetry: () => _load())
                        : _emptyList()
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
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
                        loading: false,
                        showUsername: _visible(plan.id, 'user'),
                        showPassword: _visible(plan.id, 'pass'),
                        onToggleUsername: () => _toggle(plan.id, 'user'),
                        onTogglePassword: () => _toggle(plan.id, 'pass'),
                      );
                    },
                  ),
      ),
    );
  }

  Widget _offlineList() {
    return OfflineEmptyState(
      onRetry: () {
        armOfflineRetry(
          recovery: ref.read(networkRecoveryControllerProvider),
          key: _recoveryKey,
          reload: () => _load(rethrowOffline: true),
        );
      },
    );
  }

  Widget _loadingList() {
    return const SubscriptionListSkeleton();
  }

  Widget _emptyList() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppStyle.spaceLg),
      children: [
        AppCard(
          elevated: false,
          bordered: false,
          padding: const EdgeInsets.all(AppStyle.spaceXxl),
          child: Column(
            children: [
              ColorFiltered(
                colorFilter: const ColorFilter.mode(
                  AppColors.primary,
                  BlendMode.srcIn,
                ),
                child: Image.asset(
                  'assets/images/services/subscription.png',
                  width: 36,
                  height: 36,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),
              const SizedBox(height: AppStyle.spaceMd),
              Text(
                'home.no_active_plan'.tr(),
                style: AppTheme.sectionTitle(color: AppColors.primary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppStyle.spaceXs),
              Text(
                'home.no_active_plan_body'.tr(),
                textAlign: TextAlign.center,
                style: AppTheme.bodySecondary(),
              ),
            ],
          ),
        ),
      ],
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
    final parts = raw.split(' ').first.split(RegExp(r'[.\-/]'));
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
      borderRadius: AppStyle.borderRadiusListCard,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
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
                child: ColorFiltered(
                  colorFilter: const ColorFilter.mode(
                    AppColors.primary,
                    BlendMode.srcIn,
                  ),
                  child: Image.asset(
                    'assets/images/services/subscription.png',
                    width: 20,
                    height: 20,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
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
                    fontSize: 14,
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
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(AppColors.primaryLight, Colors.white, 0.62)!,
                  Color.lerp(AppColors.primaryLight, Colors.white, 0.34)!,
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
            child: Column(
              children: [
                _DetailLine(
                  label: 'home.valid_until'.tr(),
                  value: plan.expiry,
                ),
                const SizedBox(height: 12),
                _DetailLine(
                  label: 'home.remaining'.tr(),
                  value: remaining,
                  valueColor: active ? AppColors.success : AppColors.error,
                ),
                const SizedBox(height: 12),
                _CredentialField(
                  label: 'home.username'.tr(),
                  value: username,
                  visible: showUsername,
                  loading: loading,
                  onToggleVisibility: onToggleUsername,
                ),
                const SizedBox(height: 12),
                _CredentialField(
                  label: 'home.password'.tr(),
                  value: password,
                  visible: showPassword,
                  loading: loading,
                  onToggleVisibility: onTogglePassword,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: Text(
            label,
            style: AppTheme.english(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted,
              height: 1.35,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 6,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: AppTheme.english(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: valueColor ?? AppColors.textPrimary,
              height: 1.35,
            ),
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

    return Row(
      children: [
        Expanded(
          flex: 5,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.english(
              color: AppColors.textMuted,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 6,
          child: Text(
            display,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: AppTheme.english(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.35,
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
