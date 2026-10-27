import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../components/app_button/app_button.dart';
import '../../../components/app_card/app_card.dart';
import '../../../components/app_circle_icon_button/app_circle_icon_button.dart';
import '../../../components/app_curved_scaffold/app_curved_scaffold.dart';
import '../../../components/app_dialog/app_dialog.dart';
import '../../../components/app_input/app_input.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import '../../../core/theme/app_style/app_style.dart';
import '../../../core/theme/app_theme/app_theme.dart';
import '../../../models/requests/installation_application/installation_application_model.dart';
import '../../profile/profile/profile_controller.dart';
import 'installation_application_controller.dart';
import 'installation_application_submitted_page.dart';

class InstallationApplicationPage extends ConsumerStatefulWidget {
  const InstallationApplicationPage({super.key});

  @override
  ConsumerState<InstallationApplicationPage> createState() =>
      _InstallationApplicationPageState();
}

class _InstallationApplicationPageState
    extends ConsumerState<InstallationApplicationPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(profileControllerProvider.notifier).fetchProfile();
      ref
          .read(installationApplicationControllerProvider.notifier)
          .fetchRequests();
    });
  }

  Future<void> _refresh() => ref
      .read(installationApplicationControllerProvider.notifier)
      .fetchRequests();

  Future<void> _openForm([InstallationApplicationModel? request]) async {
    final savedRequest =
        await showModalBottomSheet<InstallationApplicationModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _InstallationApplicationFormSheet(request: request),
    );
    if (!mounted || savedRequest == null) return;
    if (request != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('installationApplication.update_success'.tr())),
      );
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            InstallationApplicationSubmittedPage(request: savedRequest),
      ),
    );
  }

  Future<void> _confirmAction({
    required InstallationApplicationModel request,
  }) async {
    final confirmed = await showAppConfirmModal(
      context,
      title: 'installationApplication.cancel_title'.tr(),
      body: 'installationApplication.cancel_confirm'.tr(),
      confirmLabel: 'installationApplication.cancel_action'.tr(),
      cancelLabel: 'common.no'.tr(),
    );
    if (confirmed != true) return;

    final controller =
        ref.read(installationApplicationControllerProvider.notifier);
    final success = await controller.cancelRequest(request.id);
    if (!mounted) return;

    final state = ref.read(installationApplicationControllerProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'installationApplication.cancel_success'.tr()
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
    final state = ref.watch(installationApplicationControllerProvider);
    final canSubmitNewRequest = !state.requests.any(_canManageRequest);

    return AppCurvedScaffold(
      title: Text(
        'home.service_packages'.tr(),
        style: AppTheme.topBarTitle(),
      ),
      showBack: true,
      floatingActionButton: canSubmitNewRequest
          ? FloatingActionButton(
              onPressed: () => _openForm(),
              backgroundColor: AppColors.primary,
              child: const Icon(
                LucideIcons.plus,
                color: AppColors.onPrimary,
              ),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _buildBody(state),
      ),
    );
  }

  Widget _buildBody(InstallationApplicationState state) {
    if (state.status == InstallationApplicationStatus.loading &&
        state.requests.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (state.status == InstallationApplicationStatus.error &&
        state.requests.isEmpty) {
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
            elevated: false,
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
                  'installationApplication.no_requests'.tr(),
                  style: AppTheme.sectionTitle(),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppStyle.spaceXs),
                Text(
                  'installationApplication.no_requests_desc'.tr(),
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
        return _InstallationApplicationCard(
          request: request,
          onEdit: () => _openForm(request),
          onCancel: () => _confirmAction(request: request),
        );
      },
    );
  }
}

bool _canManageRequest(InstallationApplicationModel request) {
  final status = request.status.toLowerCase().replaceAll(' ', '_');
  return status == 'pending' || status == 'under_review';
}

class _InstallationApplicationCard extends StatelessWidget {
  const _InstallationApplicationCard({
    required this.request,
    required this.onEdit,
    required this.onCancel,
  });

  final InstallationApplicationModel request;
  final VoidCallback onEdit;
  final VoidCallback onCancel;

  Color get _statusColor {
    switch (request.status.toLowerCase().replaceAll(' ', '_')) {
      case 'under_review':
      case 'pending':
        return AppColors.warning;
      case 'approved':
        return AppColors.success;
      case 'cancelled':
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.textMuted;
    }
  }

  String get _statusLabel {
    switch (request.status.toLowerCase().replaceAll(' ', '_')) {
      case 'under_review':
      case 'pending':
        return 'requests.status_under_review'.tr();
      case 'approved':
        return 'requests.status_approved'.tr();
      case 'cancelled':
        return 'requests.status_cancelled'.tr();
      case 'rejected':
        return 'requests.status_rejected'.tr();
      default:
        return request.status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final createdAt = request.createdAt == null
        ? null
        : DateFormat('yyyy.MM.dd HH:mm').format(request.createdAt!.toLocal());
    final canManage = _canManageRequest(request);

    return AppCard(
      elevated: false,
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
              if (createdAt != null) Text(createdAt, style: AppTheme.caption()),
            ],
          ),
          const SizedBox(height: AppStyle.spaceMd),
          _RequestDetail(
            label: 'installationApplication.id_name'.tr(),
            value: request.idName,
          ),
          _RequestDetail(
            label: 'installationApplication.id_type'.tr(),
            value: request.idType,
          ),
          _RequestDetail(
            label: 'installationApplication.address'.tr(),
            value: request.address ?? '',
          ),
          _RequestDetail(
            label: 'requests.phone'.tr(),
            value: request.phone,
          ),
          if (request.idNumber?.trim().isNotEmpty == true)
            _RequestDetail(
              label: 'installationApplication.id_number'.tr(),
              value: request.idNumber!,
            ),
          if (request.note?.trim().isNotEmpty == true)
            _RequestDetail(
              label: 'installationApplication.note'.tr(),
              value: request.note!,
            ),
          if (canManage) ...[
            const Divider(height: AppStyle.spaceXxl),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: AppStyle.spaceXs,
              children: [
                AppCircleIconButton(
                  onPressed: onEdit,
                  icon: LucideIcons.pencil,
                  backgroundColor: AppColors.primary,
                  iconSize: AppStyle.iconSizeSm,
                  borderRadius: AppStyle.radiusButton,
                ),
                Tooltip(
                  message: 'installationApplication.cancel_action'.tr(),
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
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppStyle.spaceSm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label : ', style: AppTheme.caption()),
          Expanded(
            child: Text(
              value,
              style: AppTheme.body(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _InstallationApplicationFormSheet extends ConsumerStatefulWidget {
  const _InstallationApplicationFormSheet({this.request});

  final InstallationApplicationModel? request;

  @override
  ConsumerState<_InstallationApplicationFormSheet> createState() =>
      _InstallationApplicationFormSheetState();
}

class _InstallationApplicationFormSheetState
    extends ConsumerState<_InstallationApplicationFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _idTypeController;
  late final TextEditingController _nameController;
  late final TextEditingController _idNumberController;
  late final TextEditingController _addressController;
  late final TextEditingController _phoneController;
  late final TextEditingController _noteController;
  final List<XFile> _photos = [];
  int? _packageId;
  int? _areaId;
  List<InstallationApplicationOption> _packages = const [];
  List<InstallationApplicationOption> _areas = const [];
  bool _loadingOptions = true;
  String? _optionsError;

  static const _maxPhotoBytes = 2 * 1024 * 1024;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileControllerProvider);
    final request = widget.request;
    _packageId = request?.packageId;
    _areaId = request?.areaId;
    _idTypeController = TextEditingController(text: request?.idType ?? '');
    _nameController =
        TextEditingController(text: request?.idName ?? profile.fullName);
    _idNumberController = TextEditingController(text: request?.idNumber ?? '');
    _addressController = TextEditingController(text: request?.address ?? '');
    _phoneController =
        TextEditingController(text: request?.phone ?? profile.displayPhone);
    _noteController = TextEditingController(text: request?.note ?? '');
    _loadRequestOptions();
  }

  Future<void> _loadRequestOptions() async {
    setState(() {
      _loadingOptions = true;
      _optionsError = null;
    });
    try {
      final options = await ref
          .read(installationApplicationControllerProvider.notifier)
          .fetchRequestOptions();
      if (!mounted) return;
      setState(() {
        _packages = options.packages;
        _areas = options.areas;
        if (!_packages.any((option) => option.id == _packageId)) {
          _packageId = null;
        }
        if (!_areas.any((option) => option.id == _areaId)) {
          _areaId = null;
        }
        _loadingOptions = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _optionsError = error is ApiException
            ? error.detail ?? error.messageKey
            : error.toString();
        _loadingOptions = false;
      });
    }
  }

  @override
  void dispose() {
    _idTypeController.dispose();
    _nameController.dispose();
    _idNumberController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.request == null && _photos.length != 2) return;

    final profile = ref.read(profileControllerProvider);

    final request = InstallationApplicationModel(
      id: widget.request?.id ?? '',
      userId: widget.request?.userId ?? int.tryParse(profile.id) ?? 0,
      packageId: _packageId,
      areaId: _areaId,
      idType: _idTypeController.text.trim(),
      idName: _nameController.text.trim(),
      idNumber: _idNumberController.text.trim(),
      address: _addressController.text.trim(),
      phone: _phoneController.text.trim(),
      photos: widget.request?.photos ?? const [],
      note: _optionalValue(_noteController.text),
      status: widget.request?.status ?? 'under_review',
    );
    final savedRequest = await ref
        .read(installationApplicationControllerProvider.notifier)
        .saveRequest(request, photos: _photos);
    if (savedRequest != null && mounted) {
      Navigator.of(context).pop(savedRequest);
    }
  }

  Future<void> _pickPhotos(FormFieldState<int> field) async {
    final remaining = 2 - _photos.length;
    if (remaining <= 0) return;
    final List<XFile> picked;
    try {
      picked = await ImagePicker().pickMultiImage(
        limit: remaining,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );
    } catch (error) {
      if (mounted) {
        _showPhotoError(
          'installationApplication.photo_pick_error'.tr(
            namedArgs: {'error': error.toString()},
          ),
        );
      }
      return;
    }
    if (!mounted || picked.isEmpty) return;

    for (final photo in picked) {
      final extension = photo.name.split('.').last.toLowerCase();
      if (!{'jpg', 'jpeg', 'png', 'webp'}.contains(extension)) {
        _showPhotoError('installationApplication.photo_type_error'.tr());
        return;
      }
      final size = await photo.length();
      if (!mounted) return;
      if (size > _maxPhotoBytes) {
        _showPhotoError('installationApplication.photo_size_error'.tr());
        return;
      }
    }

    setState(() => _photos.addAll(picked.take(remaining)));
    field.didChange(_photos.length);
  }

  void _removePhoto(int index, FormFieldState<int> field) {
    setState(() => _photos.removeAt(index));
    field.didChange(_photos.length);
  }

  void _showPhotoError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String? _requiredOption(int? value) {
    if (value == null) return 'requests.required'.tr();
    return null;
  }

  String? _optionalValue(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(installationApplicationControllerProvider);

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
                            ? 'installationApplication.new_request'.tr()
                            : 'installationApplication.edit_request'.tr(),
                        style: AppTheme.sectionTitle(),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(LucideIcons.x),
                    ),
                  ],
                ),
                const SizedBox(height: AppStyle.spaceSm),
                if (_loadingOptions)
                  const Padding(
                    padding: EdgeInsets.all(AppStyle.spaceMd),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  )
                else if (_optionsError != null)
                  AppCard(
                    child: Column(
                      children: [
                        Text(
                          _optionsError!.startsWith('api.') ||
                                  _optionsError!.startsWith('common.')
                              ? _optionsError!.tr()
                              : _optionsError!,
                          textAlign: TextAlign.center,
                          style: AppTheme.body(color: AppColors.error),
                        ),
                        TextButton(
                          onPressed: _loadRequestOptions,
                          child: Text('common.retry'.tr()),
                        ),
                      ],
                    ),
                  )
                else if (_packages.isEmpty || _areas.isEmpty)
                  AppCard(
                    child: Column(
                      children: [
                        Text(
                          'installationApplication.options_unavailable'.tr(),
                          textAlign: TextAlign.center,
                          style: AppTheme.body(color: AppColors.textMuted),
                        ),
                        TextButton(
                          onPressed: _loadRequestOptions,
                          child: Text('common.retry'.tr()),
                        ),
                      ],
                    ),
                  )
                else
                  AppCard(
                    elevated: false,
                    bordered: false,
                    padding: const EdgeInsets.all(AppStyle.spaceMd),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<int>(
                          initialValue: _packageId,
                          decoration: InputDecoration(
                            labelText: 'installationApplication.package'.tr(),
                          ),
                          items: _packages
                              .map(
                                (option) => DropdownMenuItem(
                                  value: option.id,
                                  child: Text(
                                    option.localizedName(
                                      context.locale.languageCode,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          validator: (value) => _requiredOption(value),
                          onChanged: (value) =>
                              setState(() => _packageId = value),
                        ),
                        const SizedBox(height: AppStyle.spaceSm),
                        DropdownButtonFormField<int>(
                          initialValue: _areaId,
                          decoration: InputDecoration(
                            labelText: 'installationApplication.area'.tr(),
                          ),
                          items: _areas
                              .map(
                                (option) => DropdownMenuItem(
                                  value: option.id,
                                  child: Text(
                                    option.localizedName(
                                      context.locale.languageCode,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          validator: (value) => _requiredOption(value),
                          onChanged: (value) => setState(() => _areaId = value),
                        ),
                        const SizedBox(height: AppStyle.spaceSm),
                        AppInput(
                          controller: _nameController,
                          label: 'installationApplication.id_name'.tr(),
                          prefixIcon: LucideIcons.user,
                          maxLength: 255,
                          validator: (value) =>
                              _requiredMaxLengthField(value, 255),
                        ),
                        const SizedBox(height: AppStyle.spaceSm),
                        AppInput(
                          controller: _idTypeController,
                          label: 'installationApplication.id_type'.tr(),
                          prefixIcon: LucideIcons.id_card,
                          maxLength: 16,
                          validator: (value) =>
                              _requiredMaxLengthField(value, 16),
                        ),
                        const SizedBox(height: AppStyle.spaceSm),
                        AppInput(
                          controller: _idNumberController,
                          label: 'installationApplication.id_number'.tr(),
                          prefixIcon: LucideIcons.id_card,
                          maxLength: 100,
                          validator: (value) =>
                              _requiredMaxLengthField(value, 100),
                        ),
                        const SizedBox(height: AppStyle.spaceSm),
                        AppInput(
                          controller: _addressController,
                          label: 'installationApplication.address'.tr(),
                          prefixIcon: LucideIcons.map_pin,
                          maxLines: 2,
                          maxLength: 5000,
                          validator: (value) =>
                              _requiredMaxLengthField(value, 5000),
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
                          controller: _noteController,
                          label: 'installationApplication.note'.tr(),
                          prefixIcon: LucideIcons.notebook_pen,
                          maxLines: 2,
                          maxLength: 5000,
                          validator: (value) => _maxLengthField(value, 5000),
                        ),
                        if (widget.request == null) ...[
                          const SizedBox(height: AppStyle.spaceSm),
                          FormField<int>(
                            initialValue: _photos.length,
                            validator: (_) => _photos.length == 2
                                ? null
                                : 'installationApplication.photos_required'
                                    .tr(),
                            builder: (field) => Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'installationApplication.photos'.tr(),
                                  style: AppTheme.caption(),
                                ),
                                const SizedBox(height: AppStyle.spaceXs),
                                Wrap(
                                  spacing: AppStyle.spaceSm,
                                  runSpacing: AppStyle.spaceSm,
                                  children: [
                                    for (var index = 0;
                                        index < _photos.length;
                                        index++)
                                      Chip(
                                        avatar: const Icon(
                                          LucideIcons.image,
                                          size: 18,
                                        ),
                                        label: SizedBox(
                                          width: 120,
                                          child: Text(
                                            _photos[index].name,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        onDeleted: () =>
                                            _removePhoto(index, field),
                                      ),
                                    if (_photos.length < 2)
                                      OutlinedButton.icon(
                                        onPressed: () => _pickPhotos(field),
                                        icon:
                                            const Icon(LucideIcons.image_plus),
                                        label: Text(
                                          'installationApplication.add_photos'
                                              .tr(),
                                        ),
                                      ),
                                  ],
                                ),
                                if (field.errorText != null) ...[
                                  const SizedBox(height: AppStyle.spaceXs),
                                  Text(
                                    field.errorText!,
                                    style: AppTheme.fieldError(),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                if (state.errorMessage != null) ...[
                  const SizedBox(height: AppStyle.spaceSm),
                  Text(
                    state.errorMessage!.startsWith('api.') ||
                            state.errorMessage!.startsWith('common.')
                        ? state.errorMessage!.tr()
                        : state.errorMessage!,
                    style: AppTheme.body(color: AppColors.error),
                  ),
                ],
                const SizedBox(height: AppStyle.spaceSm),
                AppButton(
                  label: 'common.submit'.tr(),
                  isLoading: state.isSubmitting || _loadingOptions,
                  onPressed: _optionsError != null ||
                          _packages.isEmpty ||
                          _areas.isEmpty
                      ? null
                      : _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
