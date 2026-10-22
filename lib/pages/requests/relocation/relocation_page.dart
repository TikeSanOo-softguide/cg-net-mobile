import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../components/app_button/app_button.dart';
import '../../../components/app_card/app_card.dart';
import '../../../components/app_circle_icon_button/app_circle_icon_button.dart';
import '../../../components/app_curved_scaffold/app_curved_scaffold.dart';
import '../../../components/app_dialog/app_dialog.dart';
import '../../../components/app_input/app_input.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import '../../../core/theme/app_style/app_style.dart';
import '../../../core/theme/app_theme/app_theme.dart';
import '../../../models/requests/relocation/relocation_request_model.dart';
import '../../profile/profile/profile_controller.dart';
import 'relocation_controller.dart';

class RelocationPage extends ConsumerStatefulWidget {
  const RelocationPage({super.key});

  @override
  ConsumerState<RelocationPage> createState() => _RelocationPageState();
}

class _RelocationPageState extends ConsumerState<RelocationPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(profileControllerProvider.notifier).fetchProfile();
      ref.read(relocationControllerProvider.notifier).fetchRequests();
    });
  }

  Future<void> _refresh() =>
      ref.read(relocationControllerProvider.notifier).fetchRequests();

  Future<void> _openForm([RelocationRequestModel? request]) async {
    final savedRequest = await showModalBottomSheet<RelocationRequestModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RelocationFormSheet(request: request),
    );

    if (!mounted || savedRequest == null) return;

    if (request != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('relocation.update_success'.tr())),
      );
      return;
    }

    await showAppSuccessModal(
      context,
      title: 'relocation.submit_success_title'.tr(),
      body: 'relocation.submit_success_body'.tr(),
    );
  }

  Future<void> _confirmAction({
    required RelocationRequestModel request,
  }) async {
    final confirmed = await showAppConfirmModal(
      context,
      title: 'relocation.cancel_title'.tr(),
      body: 'relocation.cancel_confirm'.tr(),
      confirmLabel: 'requests.cancel_action'.tr(),
      cancelLabel: 'common.no'.tr(),
    );
    if (confirmed != true) return;

    final controller = ref.read(relocationControllerProvider.notifier);
    final success = await controller.cancelRequest(request.id);
    if (!mounted) return;

    final state = ref.read(relocationControllerProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'relocation.cancel_success'.tr()
              : _localizedError(state.errorMessage),
        ),
        backgroundColor: success ? null : AppColors.error,
      ),
    );
  }

  String _localizedError(String? message) {
    if (message == null) return 'common.error'.tr();
    if (message.startsWith('api.') || message.startsWith('common.')) {
      return message.tr();
    }
    return message;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(relocationControllerProvider);
    final hasRequestUnderReview = state.requests.any(
      (request) => request.status.toLowerCase().contains('under_review'),
    );

    return AppCurvedScaffold(
      title: Text(
        'home.service_alerts'.tr(),
        style: AppTheme.topBarTitle(),
      ),
      showBack: true,
      floatingActionButton: hasRequestUnderReview
          ? null
          : FloatingActionButton(
              onPressed: () => _openForm(),
              backgroundColor: AppColors.primary,
              child: const Icon(
                LucideIcons.plus,
                color: AppColors.onPrimary,
              ),
            ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _buildBody(state),
      ),
    );
  }

  Widget _buildBody(RelocationState state) {
    if (state.status == RelocationStatus.loading && state.requests.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (state.status == RelocationStatus.error && state.requests.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(AppStyle.spaceLg),
        children: [
          AppCard(
            child: Column(
              children: [
                Text(
                  _localizedError(state.errorMessage),
                  textAlign: TextAlign.center,
                  style: AppTheme.body(color: AppColors.textMuted),
                ),
                const SizedBox(height: AppStyle.spaceMd),
                TextButton(
                  onPressed: _refresh,
                  child: Text('common.retry'.tr()),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (state.requests.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(AppStyle.spaceLg),
        children: [
          AppCard(
            elevated: true,
            bordered: false,
            padding: const EdgeInsets.all(AppStyle.spaceXxl),
            child: Column(
              children: [
                const Icon(
                  LucideIcons.map_pin,
                  color: AppColors.primary,
                  size: AppStyle.iconSizeLg,
                ),
                const SizedBox(height: AppStyle.spaceMd),
                Text(
                  'relocation.no_requests'.tr(),
                  style: AppTheme.sectionTitle(),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppStyle.spaceXs),
                Text(
                  'relocation.no_requests_desc'.tr(),
                  textAlign: TextAlign.center,
                  style: AppTheme.bodySecondary(),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final hasError = state.errorMessage != null;
    return ListView.separated(
      padding: const EdgeInsets.all(AppStyle.spaceLg),
      itemCount: state.requests.length + (hasError ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: AppStyle.spaceMd),
      itemBuilder: (context, index) {
        if (hasError && index == 0) {
          return AppCard(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _localizedError(state.errorMessage),
                    style: AppTheme.body(color: AppColors.error),
                  ),
                ),
                TextButton(
                  onPressed: _refresh,
                  child: Text('common.retry'.tr()),
                ),
              ],
            ),
          );
        }
        final requestIndex = index - (hasError ? 1 : 0);
        final request = state.requests[requestIndex];
        return _RelocationRequestCard(
          request: request,
          onEdit: () => _openForm(request),
          onCancel: () => _confirmAction(request: request),
        );
      },
    );
  }
}

class _RelocationRequestCard extends StatelessWidget {
  const _RelocationRequestCard({
    required this.request,
    required this.onEdit,
    required this.onCancel,
  });

  final RelocationRequestModel request;
  final VoidCallback onEdit;
  final VoidCallback onCancel;

  bool get _canManage {
    final normalized = request.status.toLowerCase().replaceAll(' ', '_');
    return normalized == 'pending' || normalized == 'under_review';
  }

  Color get _statusColor {
    switch (request.status.toLowerCase()) {
      case 'under_review':
        return AppColors.warning;
      case 'approved':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.textMuted;
    }
  }

  String get _statusLabel {
    switch (request.status.toLowerCase()) {
      case 'under_review':
        return 'requests.status_under_review'.tr();
      case 'approved':
        return 'requests.status_approved'.tr();
      case 'cancelled':
        return 'requests.status_cancelled'.tr();
      default:
        return request.status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final createdAt = request.createdAt == null
        ? null
        : DateFormat('yyyy.MM.dd HH:mm').format(request.createdAt!.toLocal());
    final preferredDate = request.preferredDate == null
        ? null
        : DateFormat.yMMMd(context.locale.toString())
            .format(request.preferredDate!.toLocal());

    return AppCard(
      elevated: true,
      bordered: false,
      padding: const EdgeInsets.all(AppStyle.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppStyle.spaceSm,
                  vertical: AppStyle.spaceXs,
                ),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.12),
                  borderRadius: AppStyle.borderRadiusInput,
                ),
                child: Text(
                  _statusLabel,
                  style: AppTheme.caption(
                    color: _statusColor,
                    weight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              if (createdAt != null)
                Text(
                  createdAt,
                  style: AppTheme.caption(),
                ),
            ],
          ),
          const SizedBox(height: AppStyle.spaceMd),
          if (request.broadbandAccountNumber?.isNotEmpty == true)
            _RequestDetail(
              label: 'requests.broadband_account'.tr(),
              value: request.broadbandAccountNumber!,
            ),
          _RequestDetail(
            label: 'relocation.new_address'.tr(),
            value: request.newAddress,
          ),
          if (preferredDate != null)
            _RequestDetail(
              label: 'relocation.preferred_date'.tr(),
              value: preferredDate,
            ),
          if (_canManage || request.id.isNotEmpty) ...[
            Wrap(
              alignment: WrapAlignment.end,
              spacing: AppStyle.spaceXs,
              children: [
                if (_canManage) const Divider(height: AppStyle.spaceXxl),
                if (_canManage)
                  AppCircleIconButton(
                    onPressed: onEdit,
                    icon: LucideIcons.pencil,
                    backgroundColor: AppColors.primary,
                    iconSize: AppStyle.iconSizeSm,
                    borderRadius: AppStyle.radiusButton,
                  ),
                if (_canManage)
                  Tooltip(
                    message: 'relocation.cancel_action'.tr(),
                    child: AppCircleIconButton(
                      onPressed: onCancel,
                      icon: LucideIcons.trash,
                      backgroundColor: AppColors.error,
                      iconSize: AppStyle.iconSizeSm,
                      borderRadius: AppStyle.radiusButton,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _RequestDetail extends StatelessWidget {
  const _RequestDetail({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppStyle.spaceSm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label : ',
            style: AppTheme.caption(),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTheme.body(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RelocationFormSheet extends ConsumerStatefulWidget {
  const _RelocationFormSheet({this.request});

  final RelocationRequestModel? request;

  @override
  ConsumerState<_RelocationFormSheet> createState() =>
      _RelocationFormSheetState();
}

class _RelocationFormSheetState extends ConsumerState<_RelocationFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _accountController;
  late final TextEditingController _currentAddressController;
  late final TextEditingController _newAddressController;
  late final TextEditingController _phoneController;
  late final TextEditingController _detailsController;
  late final TextEditingController _preferredDateController;
  DateTime? _preferredDate;

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
    _currentAddressController =
        TextEditingController(text: request?.currentAddress ?? '');
    _newAddressController =
        TextEditingController(text: request?.newAddress ?? '');
    _phoneController =
        TextEditingController(text: request?.phone ?? profile.displayPhone);
    _detailsController = TextEditingController(text: request?.details ?? '');
    _preferredDate = request?.preferredDate;
    _preferredDateController = TextEditingController(
      text: _preferredDate == null
          ? ''
          : DateFormat.yMMMd(context.locale.toString()).format(_preferredDate!),
    );
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
    if (!_formKey.currentState!.validate()) return;
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

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppStyle.radiusCurve),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        AppStyle.spaceLg,
        AppStyle.spaceLg,
        AppStyle.spaceLg,
        MediaQuery.of(context).viewInsets.bottom + AppStyle.spaceLg,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.request == null
                            ? 'relocation.new_request'.tr()
                            : 'relocation.edit_request'.tr(),
                        style: AppTheme.sectionTitle(),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      icon: const Icon(LucideIcons.x),
                    ),
                  ],
                ),
                const SizedBox(height: AppStyle.spaceSm),
                AppCard(
                  elevated: true,
                  bordered: false,
                  padding: const EdgeInsets.all(AppStyle.spaceMd),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppInput(
                        controller: _accountController,
                        label: 'requests.broadband_account'.tr(),
                        readOnly: profile.accountNumber.isNotEmpty,
                        enabled: profile.accountNumber.isEmpty,
                        prefixIcon: LucideIcons.id_card,
                        validator: _requiredField,
                      ),
                      const SizedBox(height: AppStyle.spaceSm),
                      AppInput(
                        controller: _phoneController,
                        label: 'requests.phone'.tr(),
                        keyboardType: TextInputType.phone,
                        prefixIcon: LucideIcons.phone,
                        maxLength: 16,
                        validator: (value) =>
                            _requiredMaxLengthField(value, 16),
                      ),
                      const SizedBox(height: AppStyle.spaceSm),
                      AppInput(
                        controller: _currentAddressController,
                        label: 'relocation.current_address'.tr(),
                        prefixIcon: LucideIcons.map_pin,
                        maxLines: 2,
                        maxLength: 5000,
                        validator: (value) =>
                            _requiredMaxLengthField(value, 5000),
                      ),
                      const SizedBox(height: AppStyle.spaceSm),
                      AppInput(
                        controller: _newAddressController,
                        label: 'relocation.new_address'.tr(),
                        prefixIcon: LucideIcons.map_pin,
                        maxLines: 2,
                        maxLength: 5000,
                        validator: (value) =>
                            _requiredMaxLengthField(value, 5000),
                      ),
                      const SizedBox(height: AppStyle.spaceSm),
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
                      const SizedBox(height: AppStyle.spaceXxxl),
                      AppInput(
                        controller: _detailsController,
                        label: 'relocation.details'.tr(),
                        prefixIcon: LucideIcons.notebook_pen,
                        maxLines: 2,
                        maxLength: 5000,
                        validator: (value) => _maxLengthField(value, 5000),
                      ),
                    ],
                  ),
                ),
                if (state.errorMessage != null) ...[
                  const SizedBox(height: AppStyle.spaceSm),
                  Text(
                    state.errorMessage!.startsWith('api.')
                        ? state.errorMessage!.tr()
                        : state.errorMessage!,
                    style: AppTheme.body(color: AppColors.error),
                  ),
                ],
                const SizedBox(height: AppStyle.spaceSm),
                AppButton(
                  label: 'common.submit'.tr(),
                  isLoading: state.isSubmitting,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _requiredField(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'requests.required'.tr();
    }
    return null;
  }

  String? _requiredMaxLengthField(String? value, int maxLength) {
    final requiredError = _requiredField(value);
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
