import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../components/account_number_row/account_number_row.dart';
import '../../../components/app_button/app_button.dart';
import '../../../components/app_card/app_card.dart';
import '../../../components/app_curved_scaffold/app_curved_scaffold.dart';
import '../../../components/app_input/app_input.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import '../../../core/theme/app_style/app_style.dart';
import '../../../core/theme/app_theme/app_theme.dart';
import '../../../data/requests/relocation/relocation_repository.dart';
import '../../../models/requests/relocation/relocation_request_model.dart';
import '../../../models/user_model/user_model.dart';
import '../../profile/profile/profile_controller.dart';
import 'relocation_controller.dart';

class RelocationFormPage extends ConsumerStatefulWidget {
  const RelocationFormPage({super.key, this.request});

  final RelocationRequestModel? request;

  @override
  ConsumerState<RelocationFormPage> createState() => _RelocationFormPageState();
}

class _RelocationFormPageState extends ConsumerState<RelocationFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _accountController;
  late final TextEditingController _currentAddressController;
  late final TextEditingController _newAddressController;
  late final TextEditingController _phoneController;
  late final TextEditingController _detailsController;
  late final TextEditingController _preferredDateController;
  DateTime? _preferredDate;
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;
  bool _submitting = false;
  String? _accountGapError;
  String? _addressGapError;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileControllerProvider);
    final request = widget.request;
    _accountController = TextEditingController(
      text: request == null
          ? profile.accountNumber
          : request.broadbandAccountNumber ?? '',
    );
    _currentAddressController = TextEditingController(
      text: request == null ? profile.address : request.currentAddress ?? '',
    );
    _newAddressController =
        TextEditingController(text: request?.newAddress ?? '');
    _phoneController =
        TextEditingController(text: request?.phone ?? profile.displayPhone);
    _detailsController = TextEditingController(text: request?.details ?? '');
    _preferredDate = request?.preferredDate;
    _preferredDateController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final preferredDate = _preferredDate;
    if (preferredDate != null) {
      _preferredDateController.text =
          DateFormat('yyyy/MM/dd').format(preferredDate);
    }
  }

  @override
  void dispose() {
    _accountController.dispose();
    _currentAddressController.dispose();
    _newAddressController.dispose();
    _phoneController.dispose();
    _detailsController.dispose();
    _preferredDateController.dispose();
    super.dispose();
  }

  Future<void> _selectPreferredDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final initialDate =
        _preferredDate == null || _preferredDate!.isBefore(today)
            ? today
            : _preferredDate!;
    final picked = await showDialog<DateTime>(
      context: context,
      barrierColor: AppColors.textPrimary.withValues(alpha: 0.28),
      builder: (context) => _RelocationCompactDatePickerDialog(
        initialDate: initialDate,
        firstDate: today,
        lastDate: DateTime(today.year + 5),
      ),
    );

    if (picked != null && mounted) {
      setState(() => _preferredDate = picked);
      _preferredDateController.text = DateFormat('yyyy/MM/dd').format(picked);
    }
  }

  void _clearPreferredDate() {
    setState(() {
      _preferredDate = null;
      _preferredDateController.clear();
    });
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final profile = ref.read(profileControllerProvider);
    final accountGap = profile.accountNumber.isNotEmpty
        ? _accountError(_accountController.text)
        : null;
    final addressGap = profile.address.isNotEmpty
        ? _currentAddressError(_currentAddressController.text)
        : null;
    final formOk = _formKey.currentState!.validate();
    if (!formOk || accountGap != null || addressGap != null) {
      setState(() {
        _autovalidateMode = AutovalidateMode.onUserInteraction;
        _accountGapError = accountGap;
        _addressGapError = addressGap;
      });
      return;
    }
    setState(() {
      _submitting = true;
      _accountGapError = null;
      _addressGapError = null;
    });

    final request = RelocationRequestModel(
      id: widget.request?.id ?? '',
      userId: widget.request?.userId ?? int.tryParse(profile.id) ?? 0,
      broadbandAccountNumber: _accountController.text.trim().isEmpty
          ? null
          : _accountController.text.trim(),
      currentAddress: _currentAddressController.text.trim(),
      newAddress: _newAddressController.text.trim(),
      preferredDate: _preferredDate,
      phone: _phoneController.text.trim(),
      details: _detailsController.text.trim().isEmpty
          ? null
          : _detailsController.text.trim(),
      status: widget.request?.status ?? 'under_review',
    );

    try {
      final savedRequest = await ref
          .read(relocationControllerProvider.notifier)
          .saveRequest(request);
      if (savedRequest != null && mounted) {
        Navigator.of(context).pop<RelocationSaveResult>(savedRequest);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileControllerProvider);
    final state = ref.watch(relocationControllerProvider);
    if (profile.accountNumber.isNotEmpty &&
        _accountController.text != profile.accountNumber &&
        widget.request == null) {
      _accountController.text = profile.accountNumber;
    }
    if (profile.address.isNotEmpty &&
        _currentAddressController.text != profile.address &&
        widget.request == null) {
      _currentAddressController.text = profile.address;
    }

    final errorMessage = state.errorMessage;
    final isSubmitting = state.isSubmitting || _submitting;
    return AppCurvedScaffold(
      title: Text(
        'relocation.title'.tr(),
        style: AppTheme.topBarTitle(),
      ),
      showBack: true,
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: AppColors.background,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Form(
                  key: _formKey,
                  autovalidateMode: _autovalidateMode,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppCard(
                        elevated: false,
                        bordered: false,
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Transform.translate(
                                  offset: const Offset(0, -1),
                                  child: Image.asset(
                                    'assets/images/services/info.png',
                                    width: 23,
                                    height: 23,
                                    fit: BoxFit.contain,
                                    filterQuality: FilterQuality.high,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'relocation.form_desc'.tr(),
                                    style: AppTheme.body(
                                      weight: FontWeight.w600,
                                    ).copyWith(
                                      fontSize: 13,
                                      height: 22 / 13,
                                      leadingDistribution:
                                          TextLeadingDistribution.even,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _accountAndAddress(profile),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            width: 3,
                            height: 14,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'relocation.move_title'.tr(),
                              style: AppTheme.body(weight: FontWeight.w700)
                                  .copyWith(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      AppCard(
                        elevated: false,
                        bordered: false,
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AppInput(
                              controller: _phoneController,
                              label: '${'requests.phone'.tr()} *',
                              hint: 'login.phone_hint'.tr(),
                              prefixIcon: LucideIcons.phone,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.next,
                              maxLength: 16,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9+\s-]')),
                              ],
                              validator: _phoneError,
                            ),
                            const SizedBox(height: AppStyle.spaceXs),
                            AppInput(
                              controller: _newAddressController,
                              label: '${'relocation.new_address'.tr()} *',
                              prefixIcon: LucideIcons.map_pin,
                              maxLines: 2,
                              maxLength: 5000,
                              validator: _newAddressError,
                            ),
                            const SizedBox(height: AppStyle.spaceXs),
                            AppInput(
                              controller: _preferredDateController,
                              label: 'relocation.preferred_date'.tr(),
                              hint: 'requests.choose_date'.tr(),
                              readOnly: true,
                              onTap: _selectPreferredDate,
                              suffix: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_preferredDate != null)
                                    AppInput.iconChip(
                                      icon: LucideIcons.x,
                                      onTap: _clearPreferredDate,
                                    ),
                                  AppInput.iconChip(
                                    icon: LucideIcons.calendar_days,
                                    onTap: _selectPreferredDate,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(
                              height:
                                  AppStyle.spaceXs + AppStyle.errorSlotHeight,
                            ),
                            AppInput(
                              controller: _detailsController,
                              label: 'relocation.details'.tr(),
                              prefixIcon: LucideIcons.notebook_pen,
                              maxLines: 3,
                              maxLength: 5000,
                              validator: _detailsError,
                            ),
                            if (errorMessage != null) ...[
                              const SizedBox(height: AppStyle.spaceXs),
                              Text(
                                _localizedError(errorMessage),
                                style: AppTheme.fieldError(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Container(
            color: AppColors.background,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: AppButton(
                    label: 'common.submit'.tr(),
                    isLoading: isSubmitting,
                    onPressed: isSubmitting ? null : _submit,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _accountAndAddress(UserProfileModel profile) {
    final accountLocked = profile.accountNumber.isNotEmpty;
    final addressLocked = profile.address.isNotEmpty;
    final accountLabel = 'requests.broadband_account'.tr();
    final addressLabel = 'relocation.current_address'.tr();

    final accountInput = AppInput(
      controller: _accountController,
      label: '$accountLabel *',
      readOnly: accountLocked,
      enabled: !accountLocked,
      prefixIcon: LucideIcons.id_card,
      validator: _accountError,
    );
    final addressInput = AppInput(
      controller: _currentAddressController,
      label: '$addressLabel *',
      readOnly: addressLocked,
      enabled: !addressLocked,
      prefixIcon: LucideIcons.map_pin,
      validator: _currentAddressError,
    );

    final accountRow = AccountNumberRow(
      label: accountLabel,
      value: _accountController.text,
      error: _accountGapError,
    );

    if (accountLocked && addressLocked) {
      return Column(
        children: [
          accountRow,
          const SizedBox(height: 8),
          _lockedBox(
            _lockedLine(
              LucideIcons.map_pin,
              addressLabel,
              _currentAddressController.text,
              error: _addressGapError,
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        if (accountLocked) accountRow else accountInput,
        const SizedBox(height: AppStyle.spaceXs),
        if (addressLocked)
          _lockedBox(
            _lockedLine(
              LucideIcons.map_pin,
              addressLabel,
              _currentAddressController.text,
              error: _addressGapError,
            ),
          )
        else
          addressInput,
      ],
    );
  }

  Widget _lockedBox(Widget child) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }

  Widget _lockedLine(
    IconData icon,
    String label,
    String value, {
    String? error,
    Color valueColor = AppColors.textPrimary,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  height: 1.3,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                  color: valueColor,
                ),
              ),
              if (error != null && error.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(error, style: AppTheme.fieldError()),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _localizedError(String message) {
    if (message.startsWith('relocation.') ||
        message.startsWith('api.') ||
        message.startsWith('common.')) {
      return message.tr();
    }
    return message;
  }

  String _requiredMessage(String fieldKey) {
    return 'requests.required_field'.tr(namedArgs: {'field': fieldKey.tr()});
  }

  String? _accountError(String? value) =>
      _requiredText(value, 'requests.broadband_account');

  String? _phoneError(String? value) =>
      _requiredMaxLengthField(value, 16, 'requests.phone');

  String? _currentAddressError(String? value) =>
      _requiredMaxLengthField(value, 5000, 'relocation.current_address');

  String? _newAddressError(String? value) =>
      _requiredMaxLengthField(value, 5000, 'relocation.new_address');

  String? _detailsError(String? value) => _maxLengthField(value, 5000);

  String? _requiredText(String? value, String fieldKey) {
    if (value == null || value.trim().isEmpty) {
      return _requiredMessage(fieldKey);
    }
    return null;
  }

  String? _requiredMaxLengthField(
    String? value,
    int maxLength,
    String fieldKey,
  ) {
    final requiredError = _requiredText(value, fieldKey);
    if (requiredError != null) return requiredError;
    return _maxLengthField(value, maxLength);
  }

  String? _maxLengthField(String? value, int maxLength) {
    if (value != null && value.runes.length > maxLength) {
      return 'requests.max_length'.tr(
        namedArgs: {'max': maxLength.toString()},
      );
    }
    return null;
  }
}

class _RelocationCompactDatePickerDialog extends StatefulWidget {
  const _RelocationCompactDatePickerDialog({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
  });

  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  @override
  State<_RelocationCompactDatePickerDialog> createState() =>
      _RelocationCompactDatePickerDialogState();
}

class _RelocationCompactDatePickerDialogState
    extends State<_RelocationCompactDatePickerDialog> {
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
                    _RelocationMonthNavButton(
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
                    _RelocationMonthNavButton(
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
                        return _RelocationDayCell(
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

class _RelocationMonthNavButton extends StatelessWidget {
  const _RelocationMonthNavButton({
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

class _RelocationDayCell extends StatelessWidget {
  const _RelocationDayCell({
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
