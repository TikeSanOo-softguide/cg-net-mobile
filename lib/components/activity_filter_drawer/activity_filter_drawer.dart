import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../core/theme/app_colors/app_colors.dart';
import '../../core/theme/app_style/app_style.dart';
import '../../core/theme/app_theme/app_theme.dart';

enum ActivityFilterPeriod { day, month, custom }

/// Activity date filter — day / month / custom range.
class ActivityDateFilter {
  const ActivityDateFilter({
    required this.period,
    required this.start,
    required this.end,
  });

  final ActivityFilterPeriod period;
  final DateTime start;
  final DateTime end;

  /// Default: current month (1st → today).
  factory ActivityDateFilter.defaults() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month, now.day);
    return ActivityDateFilter(
      period: ActivityFilterPeriod.month,
      start: start,
      end: end,
    );
  }

  bool matches(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day);
    return !day.isBefore(s) && !day.isAfter(e);
  }

  ActivityDateFilter copyWith({
    ActivityFilterPeriod? period,
    DateTime? start,
    DateTime? end,
  }) {
    return ActivityDateFilter(
      period: period ?? this.period,
      start: start ?? this.start,
      end: end ?? this.end,
    );
  }
}

/// Opens a left settings-style filter drawer. Returns applied filter or null if dismissed.
Future<ActivityDateFilter?> showActivityFilterDrawer(
  BuildContext context, {
  required ActivityDateFilter initial,
}) {
  return showGeneralDialog<ActivityDateFilter>(
    context: context,
    barrierLabel: 'history.filter_title'.tr(),
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (context, animation, secondaryAnimation) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Material(
          color: Colors.transparent,
          child: SizedBox(
            width: (MediaQuery.sizeOf(context).width * 0.82).clamp(280.0, 340.0),
            height: MediaQuery.sizeOf(context).height,
            child: _ActivityFilterDrawer(initial: initial),
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(-1, 0),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      );
    },
  );
}

class _ActivityFilterDrawer extends StatefulWidget {
  const _ActivityFilterDrawer({required this.initial});

  final ActivityDateFilter initial;

  @override
  State<_ActivityFilterDrawer> createState() => _ActivityFilterDrawerState();
}

class _ActivityFilterDrawerState extends State<_ActivityFilterDrawer> {
  late ActivityFilterPeriod _period;
  late DateTime _start;
  late DateTime _end;

  @override
  void initState() {
    super.initState();
    _period = widget.initial.period;
    _start = widget.initial.start;
    _end = widget.initial.end;
  }

  void _applyPeriod(ActivityFilterPeriod period) {
    final now = DateTime.now();
    setState(() {
      _period = period;
      switch (period) {
        case ActivityFilterPeriod.day:
          _start = DateTime(now.year, now.month, now.day);
          _end = _start;
        case ActivityFilterPeriod.month:
          _start = DateTime(now.year, now.month, 1);
          _end = DateTime(now.year, now.month, now.day);
        case ActivityFilterPeriod.custom:
          if (_end.isBefore(_start)) _end = _start;
      }
    });
  }

  Future<void> _pickStart() async {
    if (_period == ActivityFilterPeriod.month) {
      await _pickMonth();
      return;
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime(DateTime.now().year - 2),
      lastDate: DateTime.now(),
      helpText: 'history.filter_start'.tr(),
      builder: _pickerTheme,
    );
    if (picked == null) return;
    setState(() {
      _start = DateTime(picked.year, picked.month, picked.day);
      if (_period == ActivityFilterPeriod.day) {
        _end = _start;
      } else if (_end.isBefore(_start)) {
        _end = _start;
      }
    });
  }

  Future<void> _pickEnd() async {
    if (_period == ActivityFilterPeriod.day) return;
    if (_period == ActivityFilterPeriod.month) {
      await _pickMonth();
      return;
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: _end.isBefore(_start) ? _start : _end,
      firstDate: _start,
      lastDate: DateTime.now(),
      helpText: 'history.filter_end'.tr(),
      builder: _pickerTheme,
    );
    if (picked == null) return;
    setState(() {
      _end = DateTime(picked.year, picked.month, picked.day);
    });
  }

  Future<void> _pickMonth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      helpText: 'history.filter_month'.tr(),
      initialDatePickerMode: DatePickerMode.year,
      builder: _pickerTheme,
    );
    if (picked == null) return;
    final start = DateTime(picked.year, picked.month, 1);
    final lastDay = DateTime(picked.year, picked.month + 1, 0).day;
    final today = DateTime(now.year, now.month, now.day);
    var end = DateTime(picked.year, picked.month, lastDay);
    if (end.isAfter(today)) end = today;
    setState(() {
      _start = start;
      _end = end;
    });
  }

  Widget _pickerTheme(BuildContext context, Widget? child) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primary,
              onPrimary: AppColors.onPrimary,
              surface: AppColors.surface,
            ),
        datePickerTheme: DatePickerThemeData(
          backgroundColor: AppColors.surface,
          headerBackgroundColor: AppColors.primary,
          headerForegroundColor: AppColors.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppStyle.radiusLg),
          ),
        ),
      ),
      child: child!,
    );
  }

  String _fmt(DateTime d) =>
      DateFormat.yMMMd(context.locale.toString()).format(d);

  void _reset() {
    final d = ActivityDateFilter.defaults();
    setState(() {
      _period = d.period;
      _start = d.start;
      _end = d.end;
    });
  }

  void _apply() {
    Navigator.of(context).pop(
      ActivityDateFilter(period: _period, start: _start, end: _end),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      elevation: 8,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.list_filter,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'history.filter_title'.tr(),
                      style: AppTheme.english(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      LucideIcons.x,
                      size: 18,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.borderLight),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  Text(
                    'history.filter_period'.tr(),
                    style: AppTheme.english(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _PeriodTile(
                    label: 'history.filter_by_day'.tr(),
                    selected: _period == ActivityFilterPeriod.day,
                    onTap: () => _applyPeriod(ActivityFilterPeriod.day),
                  ),
                  const SizedBox(height: 6),
                  _PeriodTile(
                    label: 'history.filter_by_month'.tr(),
                    selected: _period == ActivityFilterPeriod.month,
                    onTap: () => _applyPeriod(ActivityFilterPeriod.month),
                  ),
                  const SizedBox(height: 6),
                  _PeriodTile(
                    label: 'history.filter_by_range'.tr(),
                    selected: _period == ActivityFilterPeriod.custom,
                    onTap: () => _applyPeriod(ActivityFilterPeriod.custom),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'history.filter_dates'.tr(),
                    style: AppTheme.english(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _SettingRow(
                    label: _period == ActivityFilterPeriod.month
                        ? 'history.filter_month'.tr()
                        : 'history.filter_start'.tr(),
                    value: _period == ActivityFilterPeriod.month
                        ? DateFormat.yMMMM(context.locale.toString())
                            .format(_start)
                        : _fmt(_start),
                    onTap: _pickStart,
                  ),
                  if (_period != ActivityFilterPeriod.day) ...[
                    const SizedBox(height: 8),
                    _SettingRow(
                      label: 'history.filter_end'.tr(),
                      value: _fmt(_end),
                      onTap: _period == ActivityFilterPeriod.month
                          ? null
                          : _pickEnd,
                      enabled: _period == ActivityFilterPeriod.custom,
                    ),
                  ],
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.borderLight),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _reset,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(color: AppColors.border),
                        minimumSize: const Size(0, 40),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppStyle.radiusInput),
                        ),
                      ),
                      child: Text(
                        'history.filter_reset'.tr(),
                        style: AppTheme.english(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: _apply,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        elevation: 0,
                        minimumSize: const Size(0, 40),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppStyle.radiusInput),
                        ),
                      ),
                      child: Text(
                        'history.filter_apply'.tr(),
                        style: AppTheme.english(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onPrimary,
                        ),
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

class _PeriodTile extends StatelessWidget {
  const _PeriodTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primarySoft : AppColors.background,
      borderRadius: AppStyle.borderRadiusSm,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppStyle.borderRadiusSm,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: AppStyle.borderRadiusSm,
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.borderLight,
              width: 0.8,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected ? LucideIcons.circle_check : LucideIcons.circle,
                size: 18,
                color: selected ? AppColors.primary : AppColors.textMuted,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: AppTheme.english(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected
                        ? AppColors.primary
                        : AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.label,
    required this.value,
    required this.onTap,
    this.enabled = true,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Material(
        color: AppColors.background,
        borderRadius: AppStyle.borderRadiusSm,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: AppStyle.borderRadiusSm,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: AppStyle.borderRadiusSm,
              border: Border.all(color: AppColors.borderLight, width: 0.8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: AppTheme.english(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        value,
                        style: AppTheme.english(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (enabled)
                  const Icon(
                    LucideIcons.calendar_days,
                    size: 16,
                    color: AppColors.primary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
