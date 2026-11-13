import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../components/app_card/app_card.dart';
import '../../../components/app_input/app_input.dart';
import '../../../components/app_select/app_select_dropdown.dart';
import '../../../core/network/api_message_modal.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import '../../../core/theme/app_style/app_style.dart';
import '../../../core/theme/app_theme/app_theme.dart';
import '../../../core/utils/api_field_error.dart';
import '../../../core/utils/loading_helper.dart';
import '../../../core/utils/max_length_limiter.dart';
import '../../../core/utils/phone_number.dart';
import '../../../models/requests/change_plan/change_plan_request_model.dart';
import '../../../models/requests/installation_application/installation_application_model.dart';
import '../../../models/user_model/user_model.dart';
import '../../home/home/bound_broadband.dart';
import '../../home/home/bound_broadband_provider.dart';
import '../../profile/profile/profile_controller.dart';
import 'change_plan_controller.dart';
import '../installation_application/installation_application_controller.dart';
import '../installation_application/installation_plan_catalog.dart';
import '../installation_application/installation_wizard_scaffold.dart';

class ChangePlanFormPage extends ConsumerStatefulWidget {
  const ChangePlanFormPage({super.key, this.initialRequest});

  final ChangePlanRequestModel? initialRequest;

  @override
  ConsumerState<ChangePlanFormPage> createState() => _ChangePlanFormPageState();
}

class _ChangePlanFormPageState extends ConsumerState<ChangePlanFormPage>
    with ApiFieldErrorsMixin<ChangePlanFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameFieldKey = GlobalKey<FormFieldState<String>>();
  final _phoneFieldKey = GlobalKey<FormFieldState<String>>();
  final _dateFieldKey = GlobalKey<FormFieldState<String>>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _noteController;
  late final TextEditingController _dateController;
  late final ProviderSubscription<BoundBroadband?> _accountSubscription;
  late String _formAccountNumber;
  DateTime? _preferredDate;
  int _step = 1;
  AutovalidateMode _contactAutovalidate = AutovalidateMode.disabled;
  String _serviceType = 'FTTH';
  String? _productLine;
  int? _speedMbps;
  int? _monthCycle;
  List<InstallationApplicationOption> _packages = const [];
  bool _loadingOptions = true;
  bool _optionsFailed = false;
  int _productLoadSequence = 0;
  int _accountChangeSequence = 0;

  String _requiredMessage(String fieldKey) {
    return 'requests.required_field'.tr(namedArgs: {'field': fieldKey.tr()});
  }

  String? _validateContactPhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return _requiredMessage('requests.phone');
    }
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 8) return 'login.phone_invalid'.tr();

    final normalized = PhoneNumber.normalize(value);
    if (normalized == null || !PhoneNumber.isSupported(normalized)) {
      return 'login.phone_invalid'.tr();
    }
    return apiFieldError('contact_phone');
  }

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileControllerProvider);
    final bound = ref.read(boundBroadbandProvider);
    final initial = widget.initialRequest;
    _formAccountNumber = (initial?.broadbandAccountNumber ??
            bound?.account ??
            profile.accountNumber)
        .trim();
    _nameController =
        TextEditingController(text: initial?.contactName ?? profile.fullName);
    _phoneController = TextEditingController(
      text: initial == null
          ? profile.displayPhone
          : UserProfileModel.formatLocalPhone(initial.contactPhone),
    );
    _noteController = TextEditingController(text: initial?.note ?? '');
    _preferredDate = initial?.preferredDate;
    _dateController = TextEditingController(
      text: _preferredDate == null
          ? ''
          : DateFormat('yyyy/MM/dd').format(_preferredDate!),
    );
    final serviceType =
        initial?.serviceType ?? bound?.serviceType ?? profile.serviceType;
    _serviceType = serviceType == 'CG' ? 'CG' : 'FTTH';
    _accountSubscription = ref.listenManual(
      boundBroadbandProvider,
      (_, next) {
        final account =
            (next?.account ?? ref.read(profileControllerProvider).accountNumber)
                .trim();
        final nextServiceType = next?.serviceType ??
            ref.read(profileControllerProvider).serviceType;
        if (account == _formAccountNumber &&
            (nextServiceType == null || nextServiceType == _serviceType)) {
          return;
        }
        _formAccountNumber = account;
        _accountChangeSequence++;
        if (initial != null) {
          Navigator.of(context).maybePop();
          return;
        }
        _clearFormForAccount(nextServiceType);
      },
    );
    Future.microtask(() async {
      final accountChangeSequence = _accountChangeSequence;
      await ref.read(profileControllerProvider.notifier).fetchProfile();
      if (!mounted) return;
      final profile = ref.read(profileControllerProvider);
      if (initial == null &&
          accountChangeSequence == _accountChangeSequence &&
          _nameController.text.trim().isEmpty &&
          profile.fullName.isNotEmpty) {
        _nameController.text = profile.fullName;
      }
      if (initial == null &&
          accountChangeSequence == _accountChangeSequence &&
          _phoneController.text.trim().isEmpty &&
          profile.phone.isNotEmpty) {
        _phoneController.text = profile.displayPhone;
      }
      final activeServiceType =
          ref.read(boundBroadbandProvider)?.serviceType ?? profile.serviceType;
      if (initial == null &&
          accountChangeSequence == _accountChangeSequence &&
          (activeServiceType == 'CG' || activeServiceType == 'FTTH')) {
        _serviceType = activeServiceType!;
      }
      await _loadProducts();
      if (mounted && initial != null) {
        setState(() => _restoreProductSelection(initial));
      }
    });
  }

  @override
  void dispose() {
    _accountSubscription.close();
    _nameController.dispose();
    _phoneController.dispose();
    _noteController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  void _clearFormForAccount(String? serviceType) {
    clearAllApiFieldErrors();
    _formKey.currentState?.reset();
    _nameController.clear();
    _phoneController.clear();
    _noteController.clear();
    _dateController.clear();
    setState(() {
      _preferredDate = null;
      _step = 1;
      _contactAutovalidate = AutovalidateMode.disabled;
      _serviceType = serviceType == 'CG' ? 'CG' : 'FTTH';
      _productLine = null;
      _speedMbps = null;
      _monthCycle = null;
      _packages = const [];
      _loadingOptions = true;
      _optionsFailed = false;
    });
    _loadProducts();
  }

  InstallationApplicationOption? get _matchedProduct => matchedProduct(
        products: _packages,
        productLine: _productLine,
        speedMbps: _speedMbps,
        monthCycle: _monthCycle,
      );

  void _restoreProductSelection(ChangePlanRequestModel request) {
    final networkName = request.newPackageDetail['network_name'];
    final productLine = networkName is Map
        ? networkName['en']?.toString() ??
            networkName['my']?.toString() ??
            networkName['zh']?.toString()
        : networkName?.toString();
    final speedDetail = request.newPackageDetail['speed'];
    final speed = speedDetail is Map
        ? int.tryParse(speedDetail['mbps']?.toString() ?? '')
        : null;
    final termDetail = request.newPackageDetail['term'];
    final cycle = termDetail is Map
        ? int.tryParse(
            (termDetail['cycle'] ?? termDetail['months'])?.toString() ?? '',
          )
        : null;

    if (productLine == null || speed == null || cycle == null) return;
    final product = matchedProduct(
      products: _packages,
      productLine: productLine,
      speedMbps: speed,
      monthCycle: cycle,
    );
    if (product == null) return;
    _productLine = providerLineOf(product);
    _speedMbps = productSpeedMbps(product);
    _monthCycle = product.monthCycle;
  }

  Future<void> _loadProducts() async {
    final sequence = ++_productLoadSequence;
    setState(() {
      _loadingOptions = true;
      _optionsFailed = false;
    });
    try {
      final options = await ref
          .read(installationApplicationControllerProvider.notifier)
          .fetchProducts(_serviceType);
      if (!mounted || sequence != _productLoadSequence) return;
      setState(() {
        _packages = options;
        _loadingOptions = false;
        _optionsFailed = false;
      });
    } catch (error) {
      if (!mounted || sequence != _productLoadSequence) return;
      setState(() {
        _optionsFailed = true;
        _loadingOptions = false;
      });
      await showApiMessageModal(context, error);
    }
  }

  Future<void> _selectServiceType(String type) async {
    if (_serviceType == type) return;
    setState(() {
      _serviceType = type;
      _productLine = null;
      _speedMbps = null;
      _monthCycle = null;
    });
    await _loadProducts();
  }

  void _selectProvider(String productLine) {
    setState(() {
      _productLine = productLine;
      _speedMbps = null;
      _monthCycle = null;
    });
  }

  void _selectSpeed(int speedMbps) {
    setState(() {
      _speedMbps = speedMbps;
      final cycles = availableCycles(_packages, _productLine ?? '', speedMbps);
      if (_monthCycle != null && !cycles.contains(_monthCycle)) {
        _monthCycle = null;
      }
    });
  }

  Future<void> _selectDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final initial = _preferredDate == null || _preferredDate!.isBefore(today)
        ? today
        : _preferredDate!;
    final picked = await showDialog<DateTime>(
      context: context,
      barrierColor: AppColors.textPrimary.withValues(alpha: 0.28),
      builder: (context) => _CompactDatePickerDialog(
        initialDate: initial,
        firstDate: today,
        lastDate: DateTime(today.year + 5),
      ),
    );
    if (picked == null || !mounted) return;
    setState(() => _preferredDate = picked);
    final formattedDate = DateFormat('yyyy/MM/dd').format(picked);
    _dateController.text = formattedDate;
    clearApiFieldError('preferred_date', key: _dateFieldKey);
    _dateFieldKey.currentState?.didChange(formattedDate);
    _dateFieldKey.currentState?.validate();
  }

  void _goBack() {
    if (_step <= 1) {
      Navigator.of(context).maybePop();
      return;
    }
    setState(() => _step -= 1);
  }

  Future<void> _continue() async {
    if (_step == 1) {
      if (_matchedProduct == null) return;
      setState(() => _step = 2);
      return;
    }
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) {
      setState(() => _contactAutovalidate = AutovalidateMode.onUserInteraction);
      return;
    }
    if (ref.read(changePlanControllerProvider).isSubmitting) return;
    final product = _matchedProduct;
    if (product == null || _preferredDate == null) return;

    final profile = ref.read(profileControllerProvider);
    final initial = widget.initialRequest;
    final normalizedPhone = PhoneNumber.normalize(_phoneController.text);
    if (normalizedPhone == null || !PhoneNumber.isSupported(normalizedPhone)) {
      return;
    }
    final request = ChangePlanRequestModel(
      id: initial?.id ?? '',
      userId: initial?.userId ?? int.tryParse(profile.id) ?? 0,
      broadbandAccountNumber: initial?.broadbandAccountNumber ??
          ref.read(boundBroadbandProvider)?.account ??
          profile.accountNumber,
      serviceType: _serviceType,
      currentPackageDetail: initial?.currentPackageDetail ??
          ChangePlanRequestModel.currentDetailFrom(profile),
      newPackageDetail: ChangePlanRequestModel.newDetailFrom(product),
      preferredDate: _preferredDate,
      contactName: _nameController.text.trim(),
      contactPhone: normalizedPhone,
      note: _noteController.text.trim(),
    );

    try {
      final saved = await LoadingHelper.runWithLoading(
        () => ref
            .read(changePlanControllerProvider.notifier)
            .saveRequest(request),
      );
      if (!mounted) return;
      Navigator.of(context).pop(saved);
    } catch (error) {
      if (!mounted) return;
      final handledInline = handleApiError(
        error,
        fields: {
          'contact_name': _nameFieldKey,
          'contact_phone': _phoneFieldKey,
          'preferred_date': _dateFieldKey,
        },
      );
      if (!handledInline) {
        await showApiErrorModal(context, error);
      }
    }
  }

  String _points(double amount) {
    return '${NumberFormat('#,##0').format(amount)} ${'topup.pts'.tr()}';
  }

  String _periodLabel(int cycle, String unit) {
    final isDay = unit.contains('天');
    if (isDay) {
      return cycle == 1
          ? 'installationApplication.period_day_1'.tr()
          : 'installationApplication.period_day_n'.tr(
              namedArgs: {'count': '$cycle'},
            );
    }
    if (cycle == 1) return 'installationApplication.period_1'.tr();
    return 'installationApplication.period_n'.tr(
      namedArgs: {'count': '$cycle'},
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = _matchedProduct;

    return PopScope(
      canPop: _step <= 1,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || _step <= 1) return;
        setState(() => _step -= 1);
      },
      child: InstallationWizardScaffold(
        step: _step,
        totalSteps: 2,
        barTitle: 'home.service_change_plan'.tr(),
        title: '',
        description: '',
        stepLabels: const [
          'changePlan.current_plan',
          'changePlan.contact',
        ],
        actionLabel: _step == 1 ? 'common.continue'.tr() : 'common.submit'.tr(),
        actionEnabled: _step == 1
            ? !_loadingOptions && product != null
            : !ref.watch(changePlanControllerProvider).isSubmitting,
        onAction: _continue,
        onBack: _goBack,
        onStepSelected: (step) {
          if (step < _step) setState(() => _step = step);
        },
        child:
            _step == 1 ? _buildPlanStep(product) : _buildContactStep(product),
      ),
    );
  }

  Widget _buildPlanStep(InstallationApplicationOption? product) {
    final profile = ref.watch(profileControllerProvider);
    final providers = availableProviderLines(_packages);
    final speeds = _productLine == null
        ? const <int>[]
        : availableSpeeds(_packages, _productLine!);
    final cycles = _productLine == null || _speedMbps == null
        ? const <int>[]
        : availableCycles(_packages, _productLine!, _speedMbps!);

    const cardPadding = EdgeInsets.fromLTRB(
      AppStyle.spaceLg,
      AppStyle.spaceLg,
      AppStyle.spaceLg,
      AppStyle.spaceXl,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          elevated: false,
          bordered: false,
          padding: cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SectionLabel(label: 'changePlan.current_plan'.tr()),
              const SizedBox(height: AppStyle.spaceSm),
              _CurrentPackageSummary(profile: profile),
            ],
          ),
        ),
        const SizedBox(height: AppStyle.spaceXl),
        _SectionLabel(label: 'changePlan.select_plan'.tr()),
        const SizedBox(height: AppStyle.spaceSm),
        AppCard(
          elevated: false,
          bordered: false,
          padding: cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SectionLabel(
                label: 'installationApplication.service_type'.tr(),
              ),
              const SizedBox(height: AppStyle.spaceSm),
              _ServiceTypeSwitch(
                value: _serviceType,
                enabled: !_loadingOptions,
                onChanged: _selectServiceType,
              ),
              if (_loadingOptions)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppStyle.spaceXl),
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                )
              else if (_optionsFailed)
                Center(
                  child: TextButton(
                    onPressed: _loadProducts,
                    child: Text('common.retry'.tr()),
                  ),
                )
              else if (_packages.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    'installationApplication.options_unavailable'.tr(),
                    textAlign: TextAlign.center,
                    style: AppTheme.body(color: AppColors.textMuted),
                  ),
                )
              else ...[
                const SizedBox(height: AppStyle.spaceXl),
                _SectionLabel(
                  label: 'installationApplication.network_provider'.tr(),
                ),
                const SizedBox(height: AppStyle.spaceSm),
                AppSelectDropdown<String>(
                  value: _productLine,
                  hint: 'installationApplication.select_provider'.tr(),
                  options: providers
                      .map(
                        (line) => AppSelectOption(value: line, label: line),
                      )
                      .toList(growable: false),
                  onChanged: (line) {
                    if (line != null) _selectProvider(line);
                  },
                ),
                const SizedBox(height: AppStyle.spaceMd),
                _SectionLabel(
                  label: 'installationApplication.internet_speed'.tr(),
                ),
                const SizedBox(height: AppStyle.spaceSm),
                if (_productLine == null)
                  Text(
                    'installationApplication.choose_provider_first'.tr(),
                    style: AppTheme.caption(),
                  )
                else
                  _ChoiceGrid(
                    columns: 3,
                    children: speeds
                        .map(
                          (speed) => _ChoiceChip(
                            label: 'installationApplication.speed_mbps'.tr(
                              namedArgs: {'speed': '$speed'},
                            ),
                            selected: speed == _speedMbps,
                            onTap: () => _selectSpeed(speed),
                          ),
                        )
                        .toList(),
                  ),
                const SizedBox(height: AppStyle.spaceXl),
                _SectionLabel(
                  label: 'installationApplication.billing_period'.tr(),
                ),
                const SizedBox(height: AppStyle.spaceSm),
                if (_speedMbps == null)
                  Text(
                    'installationApplication.choose_speed_first'.tr(),
                    style: AppTheme.caption(),
                  )
                else
                  _ChoiceGrid(
                    columns: 3,
                    children: cycles
                        .map(
                          (cycle) => _ChoiceChip(
                            label: _periodLabel(
                              cycle,
                              cycleUnitFor(
                                products: _packages,
                                productLine: _productLine!,
                                speedMbps: _speedMbps!,
                                monthCycle: cycle,
                              ),
                            ),
                            selected: cycle == _monthCycle,
                            onTap: () => setState(() => _monthCycle = cycle),
                          ),
                        )
                        .toList(),
                  ),
                if (product != null) ...[
                  const SizedBox(height: AppStyle.spaceXl),
                  _SectionLabel(
                    label: 'installationApplication.selected_package'.tr(),
                  ),
                  const SizedBox(height: AppStyle.spaceSm),
                  _SelectedPackageSummary(
                    provider: providerLineOf(product),
                    speed: 'installationApplication.speed_mbps'.tr(
                      namedArgs: {'speed': '${productSpeedMbps(product)}'},
                    ),
                    price: _points(product.productPrice),
                    period: _periodLabel(
                      product.monthCycle,
                      product.monthCycleUnit,
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactStep(InstallationApplicationOption? product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          elevated: false,
          bordered: false,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Form(
            key: _formKey,
            autovalidateMode: _contactAutovalidate,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppInput(
                  controller: _nameController,
                  label: '${'requests.contact_name'.tr()} *',
                  hint: 'requests.contact_name_hint'.tr(),
                  prefixIcon: LucideIcons.user,
                  textInputAction: TextInputAction.next,
                  maxLength: 30,
                  inputFormatters: [maxLengthLimiter(30)],
                  formFieldKey: _nameFieldKey,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return _requiredMessage('requests.contact_name');
                    }
                    return apiFieldError('contact_name');
                  },
                  onChanged: (_) => clearApiFieldError(
                    'contact_name',
                    key: _nameFieldKey,
                  ),
                ),
                const SizedBox(height: AppStyle.spaceXs),
                AppInput(
                  controller: _phoneController,
                  label: '${'requests.phone'.tr()} *',
                  hint: 'requests.phone_hint'.tr(),
                  prefixIcon: LucideIcons.phone,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  maxLength: 16,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    maxLengthLimiter(16),
                  ],
                  formFieldKey: _phoneFieldKey,
                  validator: _validateContactPhone,
                  onChanged: (_) => clearApiFieldError(
                    'contact_phone',
                    key: _phoneFieldKey,
                  ),
                ),
                const SizedBox(height: AppStyle.spaceXs),
                AppInput(
                  controller: _dateController,
                  label: '${'changePlan.preferred_date'.tr()} *',
                  hint: 'requests.choose_date'.tr(),
                  formFieldKey: _dateFieldKey,
                  readOnly: true,
                  onTap: _selectDate,
                  suffix: AppInput.iconChip(
                    icon: LucideIcons.calendar_days,
                    onTap: _selectDate,
                  ),
                  validator: (_) {
                    if (_preferredDate == null) {
                      return _requiredMessage('changePlan.preferred_date');
                    }
                    return apiFieldError('preferred_date');
                  },
                ),
                const SizedBox(height: AppStyle.spaceXs),
                AppInput(
                  controller: _noteController,
                  label: 'requests.note'.tr(),
                  hint: 'requests.note_hint'.tr(),
                  prefixIcon: LucideIcons.notebook_pen,
                  maxLines: 2,
                  maxLength: 255,
                  inputFormatters: [maxLengthLimiter(255)],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppStyle.spaceXl),
        _SectionLabel(label: 'changePlan.detail'.tr()),
        const SizedBox(height: AppStyle.spaceSm),
        AppCard(
          elevated: false,
          bordered: false,
          padding: const EdgeInsets.fromLTRB(
            AppStyle.spaceLg,
            AppStyle.spaceLg,
            AppStyle.spaceLg,
            AppStyle.spaceXl,
          ),
          child: product == null
              ? Text(
                  'changePlan.select_plan'.tr(),
                  style: AppTheme.body(color: AppColors.textMuted),
                )
              : _SelectedPackageSummary(
                  packageName: product.productName.trim().isEmpty
                      ? null
                      : product.productName,
                  provider: providerLineOf(product),
                  speed: 'installationApplication.speed_mbps'.tr(
                    namedArgs: {'speed': '${productSpeedMbps(product)}'},
                  ),
                  price: _points(product.productPrice),
                  period: _periodLabel(
                    product.monthCycle,
                    product.monthCycleUnit,
                  ),
                ),
        ),
      ],
    );
  }
}

class _CurrentPackageSummary extends StatelessWidget {
  const _CurrentPackageSummary({required this.profile});

  final UserProfileModel profile;

  @override
  Widget build(BuildContext context) {
    final locale = context.locale.languageCode;
    final snapshot = profile.currentPackage;
    final network = snapshot?.networkLabel(locale).trim().isNotEmpty == true
        ? snapshot!.networkLabel(locale)
        : (profile.productLine.isNotEmpty
            ? profile.productLine
            : profile.productName);
    final speedRaw = snapshot?.speedMbps ?? profile.productSpeed;
    final speed = RegExp(r'\d+').firstMatch(speedRaw)?.group(0) ?? '';
    final price = snapshot?.price ?? num.tryParse(profile.productPrice);
    final term = profile.currentPackageTermMonths;
    final hasPlan = profile.productName.trim().isNotEmpty ||
        network.isNotEmpty ||
        speed.isNotEmpty ||
        price != null ||
        term != null;

    if (!hasPlan) {
      return Text(
        'changePlan.no_current_plan'.tr(),
        style: AppTheme.body(color: AppColors.textMuted),
      );
    }

    return _SelectedPackageSummary(
      packageName:
          profile.productName.trim().isEmpty ? '—' : profile.productName,
      provider: network.isEmpty ? '—' : network,
      speed: speed.isEmpty
          ? '—'
          : 'installationApplication.speed_mbps'.tr(
              namedArgs: {'speed': speed},
            ),
      price: price == null
          ? '—'
          : '${NumberFormat('#,##0').format(price)} ${'topup.pts'.tr()}',
      period: term == null
          ? '—'
          : (term == 1
              ? 'installationApplication.period_1'.tr()
              : 'installationApplication.period_n'.tr(
                  namedArgs: {'count': '$term'},
                )),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
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
        Text(
          label,
          style: AppTheme.body(weight: FontWeight.w700).copyWith(fontSize: 13),
        ),
      ],
    );
  }
}

class _ServiceTypeSwitch extends StatelessWidget {
  const _ServiceTypeSwitch({
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return _ChoiceGrid(
      children: [
        _ChoiceChip(
          icon: LucideIcons.wifi,
          label: 'FTTH',
          selected: value == 'FTTH',
          onTap: enabled ? () => onChanged('FTTH') : () {},
        ),
        _ChoiceChip(
          icon: LucideIcons.router,
          label: 'installationApplication.cg_router'.tr(),
          selected: value == 'CG',
          onTap: enabled ? () => onChanged('CG') : () {},
        ),
      ],
    );
  }
}

class _ChoiceGrid extends StatelessWidget {
  const _ChoiceGrid({required this.children, this.columns = 2});

  final List<Widget> children;
  final int columns;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = AppStyle.spaceSm;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final child in children) SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          width: double.infinity,
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryLight : AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? AppColors.primaryLight : AppColors.borderLight,
              width: 0.5,
            ),
          ),
          child: icon == null
              ? Center(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.english(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.15,
                      color: selected ? AppColors.primary : AppColors.textMuted,
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 13,
                      color: selected ? AppColors.primary : AppColors.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.english(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.15,
                          color: selected
                              ? AppColors.primary
                              : AppColors.textMuted,
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

class _SelectedPackageSummary extends StatelessWidget {
  const _SelectedPackageSummary({
    required this.provider,
    required this.speed,
    required this.price,
    required this.period,
    this.packageName,
  });

  final String provider;
  final String speed;
  final String price;
  final String period;
  final String? packageName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          _SummaryRow(
            label: 'installationApplication.network_provider'.tr(),
            value: provider,
          ),
          const SizedBox(height: 8),
          _SummaryRow(
            label: 'installationApplication.internet_speed'.tr(),
            value: speed,
          ),
          const SizedBox(height: 8),
          _SummaryRow(
            label: 'installationApplication.billing_period'.tr(),
            value: period,
          ),
          const SizedBox(height: 8),
          _SummaryRow(
            label: 'installationApplication.package_price'.tr(),
            value: price,
          ),
          if (packageName != null && packageName!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            _SummaryRow(
              label: 'installationApplication.package'.tr(),
              value: packageName!,
            ),
          ],
        ],
      ),
    );
  }
}

class _CompactDatePickerDialog extends StatefulWidget {
  const _CompactDatePickerDialog({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
  });

  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  @override
  State<_CompactDatePickerDialog> createState() =>
      _CompactDatePickerDialogState();
}

class _CompactDatePickerDialogState extends State<_CompactDatePickerDialog> {
  late DateTime _visibleMonth;
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    _selected = DateUtils.dateOnly(widget.initialDate);
    _visibleMonth = DateTime(_selected.year, _selected.month);
  }

  bool get _canGoPrev {
    final prev = DateTime(_visibleMonth.year, _visibleMonth.month - 1);
    return !DateTime(prev.year, prev.month + 1, 0).isBefore(widget.firstDate);
  }

  bool get _canGoNext {
    final next = DateTime(_visibleMonth.year, _visibleMonth.month + 1);
    return !next.isAfter(DateTime(widget.lastDate.year, widget.lastDate.month));
  }

  void _shiftMonth(int delta) {
    final next = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    if (delta < 0 && !_canGoPrev) return;
    if (delta > 0 && !_canGoNext) return;
    setState(() => _visibleMonth = next);
  }

  bool _isSelectable(DateTime day) {
    final date = DateUtils.dateOnly(day);
    return !date.isBefore(widget.firstDate) && !date.isAfter(widget.lastDate);
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.locale.toString();
    final today = DateUtils.dateOnly(DateTime.now());
    final firstWeekday =
        MaterialLocalizations.of(context).firstDayOfWeekIndex; // 0 = Sun
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
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                ),
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

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 108,
          child: Text(label, style: AppTheme.caption()),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: AppTheme.body(
              weight: FontWeight.w600,
              color: AppColors.primary,
            ).copyWith(fontSize: 12),
          ),
        ),
      ],
    );
  }
}
