import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../components/app_button/app_button.dart';
import '../../../components/app_card/app_card.dart';
import '../../../components/app_curved_scaffold/app_curved_scaffold.dart';
import '../../../components/app_input/app_input.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import '../../../core/theme/app_style/app_style.dart';
import '../../../core/theme/app_theme/app_theme.dart';
import '../../../models/requests/relocation/relocation_request_model.dart';
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
          DateFormat.yMMMd(context.locale.toString()).format(preferredDate);
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
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: today,
      lastDate: DateTime(today.year + 5),
    );
    if (picked != null && mounted) {
      setState(() => _preferredDate = picked);
      _preferredDateController.text =
          DateFormat.yMMMd(context.locale.toString()).format(picked);
    }
  }

  void _clearPreferredDate() {
    setState(() {
      _preferredDate = null;
      _preferredDateController.clear();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      setState(() => _autovalidateMode = AutovalidateMode.onUserInteraction);
      return;
    }
    final profile = ref.read(profileControllerProvider);
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
    final savedRequest = await ref
        .read(relocationControllerProvider.notifier)
        .saveRequest(request);
    if (savedRequest != null && mounted) {
      Navigator.of(context).pop(savedRequest);
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
    return AppCurvedScaffold(
      title: Text(
        widget.request == null
            ? 'relocation.new_request'.tr()
            : 'relocation.edit_request'.tr(),
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
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              padding: const EdgeInsets.fromLTRB(8, 6, 10, 6),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 22,
                                    height: 22,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(
                                      LucideIcons.circle_alert,
                                      size: 13,
                                      color: AppColors.onPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'relocation.form_desc'.tr(),
                                      style: AppTheme.caption().copyWith(
                                        height: 1.3,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            AppInput(
                              controller: _accountController,
                              label: '${'requests.broadband_account'.tr()} *',
                              readOnly: profile.accountNumber.isNotEmpty,
                              enabled: profile.accountNumber.isEmpty,
                              prefixIcon: LucideIcons.id_card,
                              validator: _accountError,
                            ),
                            const SizedBox(height: AppStyle.spaceXs),
                            AppInput(
                              controller: _currentAddressController,
                              fillColor: AppColors.primaryLight,
                              textColor: AppColors.primary,
                              label: '${'relocation.current_address'.tr()} *',
                              readOnly: profile.address.isNotEmpty,
                              enabled: profile.address.isEmpty,
                              prefixIcon: LucideIcons.map_pin,
                              validator: _currentAddressError,
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
                    isLoading: state.isSubmitting,
                    onPressed: state.isSubmitting ? null : _submit,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
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
