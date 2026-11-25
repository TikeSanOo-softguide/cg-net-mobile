import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../core/theme/app_colors/app_colors.dart';
import '../../core/theme/app_theme/app_theme.dart';

/// Opens the compact month calendar used by request forms.
Future<DateTime?> showAppCompactDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) {
  return showDialog<DateTime>(
    context: context,
    barrierColor: AppColors.textPrimary.withValues(alpha: 0.28),
    builder: (context) => AppCompactDatePickerDialog(
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    ),
  );
}

class AppCompactDatePickerDialog extends StatefulWidget {
  const AppCompactDatePickerDialog({
    super.key,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
  });

  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  @override
  State<AppCompactDatePickerDialog> createState() =>
      _AppCompactDatePickerDialogState();
}

class _AppCompactDatePickerDialogState
    extends State<AppCompactDatePickerDialog> {
  late DateTime _visibleMonth;
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    _selected = DateUtils.dateOnly(widget.initialDate);
    _visibleMonth = DateTime(_selected.year, _selected.month);
  }

  bool get _canGoPrev {
    final previous = DateTime(_visibleMonth.year, _visibleMonth.month - 1);
    return !DateTime(previous.year, previous.month + 1, 0)
        .isBefore(widget.firstDate);
  }

  bool get _canGoNext {
    final next = DateTime(_visibleMonth.year, _visibleMonth.month + 1);
    return !next.isAfter(DateTime(widget.lastDate.year, widget.lastDate.month));
  }

  void _shiftMonth(int delta) {
    if (delta < 0 && !_canGoPrev) return;
    if (delta > 0 && !_canGoNext) return;
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    });
  }

  bool _isSelectable(DateTime day) {
    final date = DateUtils.dateOnly(day);
    return !date.isBefore(widget.firstDate) && !date.isAfter(widget.lastDate);
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.locale.toString();
    final today = DateUtils.dateOnly(DateTime.now());
    final firstWeekday = MaterialLocalizations.of(context).firstDayOfWeekIndex;
    final daysInMonth = DateUtils.getDaysInMonth(
      _visibleMonth.year,
      _visibleMonth.month,
    );
    final monthStartWeekday =
        DateTime(_visibleMonth.year, _visibleMonth.month, 1).weekday % 7;
    final leading = (monthStartWeekday - firstWeekday + 7) % 7;
    final weekdayLabels = List.generate(7, (index) {
      final weekday = (firstWeekday + index) % 7;
      final sample = DateTime(2024, 1, weekday == 0 ? 7 : weekday);
      return DateFormat.E(locale).format(sample);
    });

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 300),
        child: Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(color: AppColors.primary),
                child: Row(
                  children: [
                    _MonthNavButton(
                      icon: LucideIcons.chevron_left,
                      enabled: _canGoPrev,
                      onTap: () => _shiftMonth(-1),
                    ),
                    Expanded(
                      child: Text(
                        DateFormat.yMMMM(locale).format(_visibleMonth),
                        textAlign: TextAlign.center,
                        style: AppTheme.english(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onPrimary,
                        ),
                      ),
                    ),
                    _MonthNavButton(
                      icon: LucideIcons.chevron_right,
                      enabled: _canGoNext,
                      onTap: () => _shiftMonth(1),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        for (final label in weekdayLabels)
                          Expanded(
                            child: Text(
                              label,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.english(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: leading + daysInMonth,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        mainAxisSpacing: 2,
                        crossAxisSpacing: 2,
                        childAspectRatio: 1,
                      ),
                      itemBuilder: (context, index) {
                        if (index < leading) return const SizedBox.shrink();
                        final day = index - leading + 1;
                        final date = DateTime(
                          _visibleMonth.year,
                          _visibleMonth.month,
                          day,
                        );
                        final selectable = _isSelectable(date);
                        final selected = DateUtils.isSameDay(date, _selected);
                        final isToday = DateUtils.isSameDay(date, today);
                        return _DayCell(
                          day: day,
                          selected: selected,
                          today: isToday,
                          enabled: selectable,
                          onTap: selectable
                              ? () => setState(
                                    () => _selected = DateUtils.dateOnly(date),
                                  )
                              : null,
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 36,
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(_selected),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.onPrimary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          textStyle: AppTheme.english(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        child: Text('common.confirm'.tr()),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MonthNavButton extends StatelessWidget {
  const _MonthNavButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 28,
      child: Material(
        color: enabled
            ? AppColors.onPrimary.withValues(alpha: 0.14)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(8),
          child: Icon(
            icon,
            size: 16,
            color: enabled
                ? AppColors.onPrimary
                : AppColors.onPrimary.withValues(alpha: 0.35),
          ),
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.selected,
    required this.today,
    required this.enabled,
    this.onTap,
  });

  final int day;
  final bool selected;
  final bool today;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color textColor;
    if (!enabled) {
      textColor = AppColors.border;
    } else if (selected) {
      textColor = AppColors.onPrimary;
    } else {
      textColor = AppColors.textPrimary;
    }

    return Center(
      child: Material(
        color: selected ? AppColors.primary : Colors.transparent,
        shape: CircleBorder(
          side: today && !selected
              ? const BorderSide(color: AppColors.primary, width: 1)
              : BorderSide.none,
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 30,
            height: 30,
            child: Center(
              child: Text(
                '$day',
                style: AppTheme.english(
                  fontSize: 12,
                  fontWeight:
                      selected || today ? FontWeight.w700 : FontWeight.w500,
                  color: textColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
