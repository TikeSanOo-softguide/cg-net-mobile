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
import '../../../core/utils/max_length_limiter.dart';
import '../../../models/requests/installation_application/installation_application_model.dart';
import 'installation_application_controller.dart';
import 'installation_plan_catalog.dart';
import 'installation_request_draft.dart';
import 'installation_wizard_scaffold.dart';

class InstallationApplicationFormPage extends ConsumerStatefulWidget {
  const InstallationApplicationFormPage({super.key});

  @override
  ConsumerState<InstallationApplicationFormPage> createState() =>
      _InstallationApplicationFormPageState();
}

class _InstallationApplicationFormPageState
    extends ConsumerState<InstallationApplicationFormPage>
    with ApiFieldErrorsMixin<InstallationApplicationFormPage> {
  final _nameFieldKey = GlobalKey<FormFieldState<String>>();
  final _phoneFieldKey = GlobalKey<FormFieldState<String>>();
  final _addressFieldKey = GlobalKey<FormFieldState<String>>();
  final _noteFieldKey = GlobalKey<FormFieldState<String>>();
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _noteController;
  int _step = 1;
  List<InstallationApplicationOption> _packages = const [];
  bool _loadingOptions = true;
  bool _optionsFailed = false;
  String _serviceType = 'FTTH';
  String? _productLine;
  int? _speedMbps;
  int? _monthCycle;
  AutovalidateMode _customerAutovalidate = AutovalidateMode.disabled;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(installationRequestDraftProvider);
    _nameController = TextEditingController(text: draft.fullName);
    _phoneController = TextEditingController(text: draft.phone);
    _addressController = TextEditingController(text: draft.address);
    _noteController = TextEditingController(text: draft.note ?? '');
    Future.microtask(() {
      _loadProducts();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  InstallationApplicationOption? get _matchedProduct => matchedProduct(
        products: _packages,
        productLine: _productLine,
        speedMbps: _speedMbps,
        monthCycle: _monthCycle,
      );

  void _syncDraft() {
    final product = _matchedProduct;
    final notifier = ref.read(installationRequestDraftProvider.notifier);
    if (product == null) {
      notifier.clearProduct();
      return;
    }
    notifier.setProduct(product);
  }

  Future<void> _selectServiceType(String type) async {
    if (_serviceType == type) return;
    ref.read(installationRequestDraftProvider.notifier).setServiceType(type);
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncDraft();
    });
  }

  void _selectSpeed(int speedMbps) {
    setState(() {
      _speedMbps = speedMbps;
      final cycles = availableCycles(
        _packages,
        _productLine ?? '',
        speedMbps,
      );
      if (_monthCycle != null && !cycles.contains(_monthCycle)) {
        _monthCycle = null;
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncDraft();
    });
  }

  void _selectCycle(int monthCycle) {
    setState(() => _monthCycle = monthCycle);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncDraft();
    });
  }

  void _restoreFromDraft() {
    final draft = ref.read(installationRequestDraftProvider);
    final product = _packages.cast<InstallationApplicationOption?>().firstWhere(
          (item) => item?.productId == draft.productId,
          orElse: () => null,
        );
    if (product == null) return;
    _productLine = providerLineOf(product);
    _speedMbps = productSpeedMbps(product);
    _monthCycle = product.monthCycle;
  }

  Future<void> _loadProducts() async {
    final serviceType = ref.read(installationRequestDraftProvider).serviceType;
    _serviceType = serviceType == 'CG' ? 'CG' : 'FTTH';
    setState(() {
      _loadingOptions = true;
      _optionsFailed = false;
    });
    try {
      final options = await ref
          .read(installationApplicationControllerProvider.notifier)
          .fetchProducts(_serviceType);
      if (!mounted) return;
      setState(() {
        _packages = options;
        _loadingOptions = false;
        _optionsFailed = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(_restoreFromDraft);
        _syncDraft();
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _optionsFailed = true;
        _loadingOptions = false;
      });
      await showApiMessageModal(context, error);
    }
  }

  void _goBack() {
    if (_step > 1) {
      setState(() => _step -= 1);
      return;
    }
    Navigator.of(context).maybePop();
  }

  Future<void> _continue() async {
    if (_step == 1) {
      if (_matchedProduct == null) return;
      setState(() => _step = 2);
      return;
    }
    if (_step == 2) {
      final valid = _formKey.currentState?.validate() ?? false;
      if (!valid) {
        setState(
          () => _customerAutovalidate = AutovalidateMode.onUserInteraction,
        );
        return;
      }
      ref.read(installationRequestDraftProvider.notifier)
        ..setFullName(_nameController.text)
        ..setPhone(_phoneController.text)
        ..setAddress(_addressController.text)
        ..setNote(_noteController.text);
      setState(() => _step = 3);
      return;
    }
    final request = ref.read(installationRequestDraftProvider).toRequest();
    try {
      final saved = await ref
          .read(installationApplicationControllerProvider.notifier)
          .saveRequest(request);
      if (!mounted) return;
      Navigator.of(context).pop(saved);
    } catch (error) {
      if (!mounted) return;
      final handledInline = handleApiError(
        error,
        fields: {
          'name': _nameFieldKey,
          'full_name': _nameFieldKey,
          'contact_name': _nameFieldKey,
          'phone': _phoneFieldKey,
          'address': _addressFieldKey,
          'note': _noteFieldKey,
        },
      );
      if (handledInline) {
        setState(() {
          _step = 2;
          _customerAutovalidate = AutovalidateMode.onUserInteraction;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _nameFieldKey.currentState?.validate();
          _phoneFieldKey.currentState?.validate();
          _addressFieldKey.currentState?.validate();
          _noteFieldKey.currentState?.validate();
        });
      } else {
        await showApiErrorModal(context, error);
      }
    }
  }

  String _requiredMessage(String fieldKey) {
    return 'requests.required_field'.tr(namedArgs: {'field': fieldKey.tr()});
  }

  String? _translateError(String? key, {String? fieldKey}) {
    if (key == null) return null;
    if (key == 'requests.required' && fieldKey != null) {
      return _requiredMessage(fieldKey);
    }
    if (key == 'requests.max_length') {
      return 'requests.max_length'.tr(namedArgs: {'max': '30'});
    }
    return key.tr();
  }

  String? _addressError(String? value) {
    final key = installationAddressError(value);
    if (key == null) return null;
    if (key == 'requests.required') {
      return _requiredMessage('requests.address');
    }
    if (key == 'requests.max_length') {
      return 'requests.max_length'.tr(namedArgs: {'max': '255'});
    }
    return key.tr();
  }

  String? _noteError(String? value) {
    final key = installationNoteError(value);
    if (key == null) return null;
    return 'requests.max_length'.tr(namedArgs: {'max': '255'});
  }

  String _serviceLabel(String type) {
    if (type == 'CG') return 'installationApplication.cg_router'.tr();
    return 'FTTH';
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
    final isEditing = ref.watch(
      installationRequestDraftProvider.select((draft) => draft.isEditing),
    );
    final barTitle = isEditing
        ? 'installationApplication.edit_request'.tr()
        : 'installationApplication.new_installation'.tr();
    final product = _matchedProduct;
    final submitting =
        ref.watch(installationApplicationControllerProvider).isSubmitting;
    final title = switch (_step) {
      1 => 'installationApplication.plan_title'.tr(),
      2 => 'installationApplication.customer_info_title'.tr(),
      _ => 'installationApplication.review_title'.tr(),
    };
    final description = switch (_step) {
      1 => 'installationApplication.plan_desc'.tr(),
      2 => 'installationApplication.customer_info_desc'.tr(),
      _ => 'installationApplication.review_desc'.tr(),
    };

    return PopScope(
      canPop: _step <= 1,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || _step <= 1) return;
        setState(() => _step -= 1);
      },
      child: InstallationWizardScaffold(
        step: _step,
        barTitle: barTitle,
        title: title,
        description: description,
        actionLabel: _step == 3 ? 'common.submit'.tr() : 'common.continue'.tr(),
        actionEnabled: switch (_step) {
          1 => !_loadingOptions && product != null,
          2 => true,
          _ => !submitting,
        },
        actionLoading: _step == 3 && submitting,
        onAction: _continue,
        onBack: _goBack,
        onStepSelected: (step) {
          if (step < _step) setState(() => _step = step);
        },
        child: switch (_step) {
          1 => _buildPackageStep(product),
          2 => _buildCustomerStep(),
          _ => _buildReviewStep(product),
        },
      ),
    );
  }

  Widget _buildPackageStep(InstallationApplicationOption? product) {
    final providers = availableProviderLines(_packages);
    final speeds = _productLine == null
        ? const <int>[]
        : availableSpeeds(_packages, _productLine!);
    final cycles = _productLine == null || _speedMbps == null
        ? const <int>[]
        : availableCycles(
            _packages,
            _productLine!,
            _speedMbps!,
          );

    return AppCard(
      elevated: false,
      bordered: false,
      padding: const EdgeInsets.fromLTRB(
        AppStyle.spaceLg,
        AppStyle.spaceLg,
        AppStyle.spaceLg,
        AppStyle.spaceXl,
      ),
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
            _EmptyCatalog(
              message: 'installationApplication.options_unavailable'.tr(),
              onRetry: _loadProducts,
            )
          else ...[
            const SizedBox(height: AppStyle.spaceXl),
            _SectionLabel(
              label: 'installationApplication.network_provider'.tr(),
            ),
            const SizedBox(height: AppStyle.spaceSm),
            if (providers.isEmpty)
              Text(
                'installationApplication.no_matching_packages'.tr(),
                style: AppTheme.body(color: AppColors.textMuted),
              )
            else
              AppSelectDropdown<String>(
                value: _productLine,
                hint: 'installationApplication.select_provider'.tr(),
                options: providers
                    .map(
                      (line) => AppSelectOption(
                        value: line,
                        label: line,
                      ),
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
            else if (speeds.isEmpty)
              Text(
                'installationApplication.no_matching_packages'.tr(),
                style: AppTheme.body(color: AppColors.textMuted),
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
            else if (cycles.isEmpty)
              Text(
                'installationApplication.no_matching_packages'.tr(),
                style: AppTheme.body(color: AppColors.textMuted),
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
                        onTap: () => _selectCycle(cycle),
                      ),
                    )
                    .toList(),
              ),
            if (_monthCycle != null && product != null) ...[
              const SizedBox(height: AppStyle.spaceXl),
              _SectionLabel(
                label: 'installationApplication.selected_package'.tr(),
              ),
              const SizedBox(height: AppStyle.spaceSm),
              _SelectedPackageSummary(
                provider: providerLineOf(product),
                speed: 'installationApplication.speed_mbps'.tr(
                  namedArgs: {
                    'speed': '${productSpeedMbps(product)}',
                  },
                ),
                month: _periodLabel(product.monthCycle, product.monthCycleUnit),
                price: _points(product.productPrice),
                installationFee: _points(product.installationFee),
                total: _points(product.totalInitialPayment),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildCustomerStep() {
    return AppCard(
      elevated: false,
      bordered: false,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Form(
        key: _formKey,
        autovalidateMode: _customerAutovalidate,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppInput(
              controller: _nameController,
              formFieldKey: _nameFieldKey,
              label: '${'requests.contact_name'.tr()} *',
              hint: 'requests.contact_name_hint'.tr(),
              prefixIcon: LucideIcons.user,
              textInputAction: TextInputAction.next,
              maxLength: 30,
              inputFormatters: [maxLengthLimiter(30)],
              validator: (value) =>
                  _translateError(
                    installationFullNameError(value),
                    fieldKey: 'requests.contact_name',
                  ) ??
                  apiFieldError('name') ??
                  apiFieldError('full_name') ??
                  apiFieldError('contact_name'),
              onChanged: (value) {
                clearApiFieldError('name', key: _nameFieldKey);
                clearApiFieldError('full_name', key: _nameFieldKey);
                clearApiFieldError('contact_name', key: _nameFieldKey);
                ref
                    .read(installationRequestDraftProvider.notifier)
                    .setFullName(value);
              },
            ),
            const SizedBox(height: AppStyle.spaceXs),
            AppInput(
              controller: _phoneController,
              formFieldKey: _phoneFieldKey,
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
              validator: (value) =>
                  _translateError(installationPhoneError(value)) ??
                  apiFieldError('phone'),
              onChanged: (value) {
                clearApiFieldError('phone', key: _phoneFieldKey);
                ref
                    .read(installationRequestDraftProvider.notifier)
                    .setPhone(value);
              },
            ),
            const SizedBox(height: AppStyle.spaceXs),
            AppInput(
              controller: _addressController,
              formFieldKey: _addressFieldKey,
              label: '${'requests.address'.tr()} *',
              hint: 'requests.address_hint'.tr(),
              prefixIcon: LucideIcons.map_pin,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.next,
              maxLines: 2,
              maxLength: 255,
              inputFormatters: [maxLengthLimiter(255)],
              validator: (value) =>
                  _addressError(value) ?? apiFieldError('address'),
              onChanged: (value) {
                clearApiFieldError('address', key: _addressFieldKey);
                ref
                    .read(installationRequestDraftProvider.notifier)
                    .setAddress(value);
              },
            ),
            const SizedBox(height: AppStyle.spaceXs),
            AppInput(
              controller: _noteController,
              formFieldKey: _noteFieldKey,
              label: 'requests.note'.tr(),
              hint: 'requests.note_hint'.tr(),
              prefixIcon: LucideIcons.notebook_pen,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.done,
              maxLines: 2,
              maxLength: 255,
              inputFormatters: [maxLengthLimiter(255)],
              validator: (value) => _noteError(value) ?? apiFieldError('note'),
              onChanged: (value) {
                clearApiFieldError('note', key: _noteFieldKey);
                ref
                    .read(installationRequestDraftProvider.notifier)
                    .setNote(value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewStep(InstallationApplicationOption? product) {
    final draft = ref.watch(installationRequestDraftProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ReviewGroup(
          icon: LucideIcons.package,
          title: 'installationApplication.step_package'.tr(),
          children: [
            _ReviewRow(
              label: 'requests.ticket_number'.tr(),
              value: draft.ticketNumber ?? '',
            ),
            _ReviewRow(
              label: 'installationApplication.service_type'.tr(),
              value: _serviceLabel(draft.serviceType),
            ),
            if (product != null) ...[
              _ReviewRow(
                label: 'installationApplication.network_provider'.tr(),
                value: providerLineOf(product),
              ),
              _ReviewRow(
                label: 'installationApplication.internet_speed'.tr(),
                value: 'installationApplication.speed_mbps'.tr(
                  namedArgs: {'speed': '${productSpeedMbps(product)}'},
                ),
              ),
              _ReviewRow(
                label: 'installationApplication.billing_period'.tr(),
                value: _periodLabel(
                  product.monthCycle,
                  product.monthCycleUnit,
                ),
              ),
              _ReviewRow(
                label: 'requests.package_price'.tr(),
                value: _points(product.productPrice),
              ),
              _ReviewRow(
                label: 'installationApplication.installation_fee'.tr(),
                value: _points(product.installationFee),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        _ReviewGroup(
          icon: LucideIcons.user,
          title: 'installationApplication.step_customer'.tr(),
          children: [
            _ReviewRow(
              label: 'requests.contact_name'.tr(),
              value: draft.fullName,
            ),
            _ReviewRow(
              label: 'requests.phone'.tr(),
              value: draft.phone,
            ),
            _ReviewRow(
              label: 'requests.address'.tr(),
              value: draft.address,
            ),
            _ReviewRow(
              label: 'requests.note'.tr(),
              value: draft.note ?? '',
            ),
          ],
        ),
      ],
    );
  }
}

class _ReviewGroup extends StatelessWidget {
  const _ReviewGroup({
    required this.icon,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      elevated: false,
      bordered: false,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 14, color: AppColors.primary),
              ),
              const SizedBox(width: 8),
              Text(title, style: AppTheme.body(weight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                weight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCatalog extends StatelessWidget {
  const _EmptyCatalog({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          message,
          textAlign: TextAlign.center,
          style: AppTheme.body(color: AppColors.textMuted),
        ),
        TextButton(onPressed: onRetry, child: Text('common.retry'.tr())),
      ],
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
        _ServiceTypeTab(
          icon: LucideIcons.wifi,
          label: 'FTTH',
          selected: value == 'FTTH',
          enabled: enabled,
          onTap: () => onChanged('FTTH'),
        ),
        _ServiceTypeTab(
          icon: LucideIcons.router,
          label: 'installationApplication.cg_router'.tr(),
          selected: value == 'CG',
          enabled: enabled,
          onTap: () => onChanged('CG'),
        ),
      ],
    );
  }
}

class _ServiceTypeTab extends StatelessWidget {
  const _ServiceTypeTab({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.enabled,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          width: double.infinity,
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryLight : AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? AppColors.primaryLight : AppColors.borderLight,
              width: 0.5,
            ),
          ),
          child: Row(
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
                    color: selected ? AppColors.primary : AppColors.textMuted,
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

class _ChoiceGrid extends StatelessWidget {
  const _ChoiceGrid({
    required this.children,
    this.columns = 2,
  });

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
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

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
          child: Center(
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
    required this.month,
    required this.installationFee,
    this.total,
  });

  final String provider;
  final String speed;
  final String month;
  final String price;
  final String installationFee;
  final String? total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PriceLine(
            label: 'installationApplication.network_provider'.tr(),
            value: provider,
          ),
          const SizedBox(height: 8),
          _PriceLine(
            label: 'installationApplication.internet_speed'.tr(),
            value: speed,
          ),
          const SizedBox(height: 8),
          _PriceLine(
            label: 'installationApplication.billing_period'.tr(),
            value: month,
          ),
          const SizedBox(height: 8),
          _PriceLine(
            label: 'requests.package_price'.tr(),
            value: price,
          ),
          const SizedBox(height: 8),
          _PriceLine(
            label: 'installationApplication.installation_fee'.tr(),
            value: installationFee,
          ),
          if (total != null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1),
            ),
            _PriceLine(
              label: 'installationApplication.total_initial'.tr(),
              value: total!,
              emphasize: true,
            ),
          ],
        ],
      ),
    );
  }
}

class _PriceLine extends StatelessWidget {
  const _PriceLine({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: emphasize
                ? AppTheme.body(weight: FontWeight.w700)
                : AppTheme.caption(),
          ),
        ),
        Text(
          value,
          style: AppTheme.body(
            weight: FontWeight.w500,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}
