import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../components/activity_list_card/activity_list_card.dart';
import '../../../components/app_card/app_card.dart';
import '../../../components/app_curved_scaffold/app_curved_scaffold.dart';
import '../../../components/app_refresh_indicator/app_refresh_indicator.dart';
import '../../../core/network/message_codes.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import '../../../core/theme/app_theme/app_theme.dart';
import '../../../data/history/history_repository.dart';
import '../../../models/history_model/history_model.dart';

/// Full activity detail — same card language as inbox detail.
class ActivityDetailPage extends ConsumerStatefulWidget {
  const ActivityDetailPage({super.key, required this.item});

  final ActivityItem item;

  @override
  ConsumerState<ActivityDetailPage> createState() => _ActivityDetailPageState();
}

class _ActivityDetailPageState extends ConsumerState<ActivityDetailPage> {
  late ActivityItem _item;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
  }

  @override
  void didUpdateWidget(covariant ActivityDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.id != widget.item.id) _item = widget.item;
  }

  Future<void> _refresh() async {
    try {
      final detail =
          await ref.read(historyRepositoryProvider).fetchById(_item.id);
      if (!mounted) return;
      setState(() => _item = _activityFromHistory(detail, _item));
    } catch (_) {}
  }

  static const _creditGreen = Color(0xFF3D7A12);
  static const _debitRed = Color(0xFFD90000);

  String get _kindLabel {
    switch (_item.kind) {
      case ActivityKind.topUp:
        return 'history.tab_topup'.tr();
      case ActivityKind.bill:
        return 'history.tab_bill'.tr();
      case ActivityKind.package:
        return 'history.tab_package'.tr();
    }
  }

  Color get _amountColor {
    if (!_item.isSuccess) return _debitRed;
    if (_item.kind == ActivityKind.topUp || _item.isCredit) {
      return _creditGreen;
    }
    return _debitRed;
  }

  @override
  Widget build(BuildContext context) {
    final item = _item;
    final locale = context.locale.toString();
    final dateText = DateFormat.yMMMd(locale).add_jm().format(item.createdAt);
    final amountText =
        '${item.isCredit ? '+' : '-'}${NumberFormat('#,##0').format(item.amount)} Pts';

    return AppCurvedScaffold(
      title: Text('history.detail_title'.tr()),
      showBack: true,
      onBack: () => context.pop(),
      body: AppRefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            AppCard(
              elevated: false,
              bordered: false,
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ActivityListCard.kindIcon(item.kind),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.displayTitle(context),
                              style: AppTheme.english(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primarySoft,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _kindLabel,
                                style: AppTheme.english(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.calendar_clock,
                        size: 14,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          dateText,
                          style: AppTheme.english(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: AppColors.borderLight),
                  const SizedBox(height: 14),
                  Text(
                    'history.detail_body_label'.tr(),
                    style: AppTheme.english(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.displaySubtitle(context),
                    style: AppTheme.english(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      amountText,
                      style: AppTheme.english(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _amountColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

ActivityItem _activityFromHistory(HistoryModel detail, ActivityItem previous) {
  final type = detail.type.toLowerCase();
  final status = detail.status.toLowerCase();
  final known = type == 'topup' ||
      type == 'refund' ||
      type == 'wifi_package' ||
      type == 'ftth_bill' ||
      type == 'cg_bill';
  final kind = switch (type) {
    'topup' || 'refund' => ActivityKind.topUp,
    'wifi_package' => ActivityKind.package,
    'ftth_bill' || 'cg_bill' => ActivityKind.bill,
    _ => previous.kind,
  };
  final titleKey = detail.titleCode.isNotEmpty
      ? MessageCodes.locKey(detail.titleCode)
      : known
          ? _fallbackTitleKey(kind, status)
          : previous.titleKey;
  final subtitleKey = detail.descriptionCode.isNotEmpty
      ? MessageCodes.locKeyBody(detail.descriptionCode)
      : known
          ? _fallbackBodyKey(kind, status)
          : previous.subtitleKey;
  final hasDirection = detail.direction.isNotEmpty;

  return ActivityItem(
    id: detail.id.isEmpty ? previous.id : detail.id,
    kind: kind,
    amount: detail.amount?.round() ?? previous.amount,
    createdAt: detail.createdAt.millisecondsSinceEpoch == 0
        ? previous.createdAt
        : detail.createdAt,
    title: titleKey == null ? (previous.title ?? detail.description) : null,
    titleKey: titleKey,
    subtitle:
        subtitleKey == null ? (previous.subtitle ?? detail.description) : null,
    subtitleKey: subtitleKey,
    isCredit: hasDirection
        ? detail.isCredit
        : type == 'topup' || type == 'refund' || previous.isCredit,
    isSuccess: status.isEmpty ? previous.isSuccess : status != 'failed',
  );
}

String _fallbackTitleKey(ActivityKind kind, String status) {
  return switch (kind) {
    ActivityKind.topUp => 'history.item_topup_title',
    ActivityKind.package => status == 'failed'
        ? 'history.item_package_fail_title'
        : 'history.item_package_success_title',
    ActivityKind.bill => 'history.item_bill_title',
  };
}

String _fallbackBodyKey(ActivityKind kind, String status) {
  return switch (kind) {
    ActivityKind.topUp => 'history.item_topup_body',
    ActivityKind.package => status == 'failed'
        ? 'history.item_package_fail_body'
        : 'history.item_package_success_body',
    ActivityKind.bill => 'history.item_bill_body',
  };
}
