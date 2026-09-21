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

/// Opens a bottom filter drawer. Returns applied filter or null if dismissed.
Future<ActivityDateFilter?> showActivityFilterDrawer(
  BuildContext context, {
  required ActivityDateFilter initial,
}) {
  return showModalBottomSheet<ActivityDateFilter>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppStyle.radiusCurve),
      ),
    ),
    builder: (sheetContext) => _ActivityFilterSheet(initial: initial),
  );
}

class _ActivityFilterSheet extends StatefulWidget {
  const _ActivityFilterSheet({required this.initial});

  final ActivityDateFilter initial;

  @override
  State<_ActivityFilterSheet> createState() => _ActivityFilterSheetState();
}

class _ActivityFilterSheetState extends State<_ActivityFilterSheet> {
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
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppStyle.spaceLg,
          AppStyle.spaceMd,
          AppStyle.spaceLg,
          AppStyle.spaceLg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppStyle.spaceMd),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'history.filter_title'.tr(),
                    style: AppTheme.sectionTitle(),
                  ),
                ),
                Material(
                  color: AppColors.primarySoft,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    onTap: () => Navigator.of(context).pop(),
                    child: const SizedBox(
                      width: 36,
                      height: 36,
                      child: Icon(
                        LucideIcons.x,
                        size: 18,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppStyle.spaceLg),
            Text(
              'history.filter_period'.tr(),
              style: AppTheme.english(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(AppStyle.radiusSm),
              ),
              child: Row(
                children: [
                  _PeriodChip(
                    label: 'history.filter_by_day'.tr(),
                    selected: _period == ActivityFilterPeriod.day,
                    onTap: () => _applyPeriod(ActivityFilterPeriod.day),
                  ),
                  _PeriodChip(
                    label: 'history.filter_by_month'.tr(),
                    selected: _period == ActivityFilterPeriod.month,
                    onTap: () => _applyPeriod(ActivityFilterPeriod.month),
                  ),
                  _PeriodChip(
                    label: 'history.filter_by_range'.tr(),
                    selected: _period == ActivityFilterPeriod.custom,
                    onTap: () => _applyPeriod(ActivityFilterPeriod.custom),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'history.filter_dates'.tr(),
              style: AppTheme.english(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            _DateField(
              label: _period == ActivityFilterPeriod.month
                  ? 'history.filter_month'.tr()
                  : 'history.filter_start'.tr(),
              value: _period == ActivityFilterPeriod.month
                  ? DateFormat.yMMMM(context.locale.toString()).format(_start)
                  : _fmt(_start),
              onTap: _pickStart,
            ),
            if (_period != ActivityFilterPeriod.day) ...[
              const SizedBox(height: 8),
              _DateField(
                label: 'history.filter_end'.tr(),
                value: _fmt(_end),
                onTap: _period == ActivityFilterPeriod.custom ? _pickEnd : null,
                enabled: _period == ActivityFilterPeriod.custom,
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _reset,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: AppColors.primary,
                      elevation: 0,
                      side: const BorderSide(
                        color: AppColors.primary,
                        width: 1,
                      ),
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
                        color: AppColors.primary,
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
          ],
        ),
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: selected ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.english(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? AppColors.onPrimary : AppColors.textPrimary,
                height: 1.1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
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
      opacity: enabled ? 1 : 0.5,
      child: Material(
        color: AppColors.primarySoft,
        borderRadius: AppStyle.borderRadiusSm,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: AppStyle.borderRadiusSm,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
